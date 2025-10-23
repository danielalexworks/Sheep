// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;


/********************
// ERC-721 Wolf NFTs - main contract
// GAME SUMMARY
// Wolves have 4 states (satisfied(3), hungry(2), dying(1), dead(0))
// They have different URIs for different states
// At the start of each week, states are decremented
// State 2 Wolves must eat (burn) 10 FLCE per week to become state 3 
// State 1 Wolves can eat (burn) a sheep NFT(seperate contract) to jump to state 3
// State 0 wolves are dead and can no longer participate
// FLCE is distributed based on Wolves' Stats
// Eating a sheep modifies the wolf's stats
// :end game:
// If one wolf is alive, they can claim the contract balance
// If two years passes, all state >= 2 wolves can claim a portion of the contract balance
********************/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./AddressStorage.sol";

contract Wolf is ERC721Enumerable, Ownable, AddressStorage {
    using Strings for uint256;

    uint256 private ownerAllowed = 66; //premint
    uint8 public ownerMinted = 0; //track premint balance
    bool public ownerPaid = false;  //did owner remove allotted % of fees
    uint8 public percentageToOwner = 45;
  
    bool public paused = true; 
    bool public mintEnded = false;
    bool public onlyWhitelisted = true; 

    uint16 public maxSupply = 6666;
    uint16 public maxMintAmount = 1; 
    uint16 public nftPerAddressLimit = 10; 
    uint256 public cost = 1;
    uint256 public totalRewardPool; //keeps track of initial balance to split up if multiple winners

    mapping(address => uint16) public addressMintedBalance; // # nft minted, used to cap wallet max

    string[4] public wolfBaseURI; // four states of wolf base uri

    //For gasless whitelist
    address private mintPass_publickey;
    struct MintPass {
        address message; //contains whitelisted user's public key + salt
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    event Minted(address addr, string message);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI0, 
        string memory _initBaseURI1,
        string memory _initBaseURI2,
        string memory _initBaseURI3,
        address _mintPass_publickey

    ) ERC721(_name, _symbol) {

        setBaseURI(_initBaseURI0,0);//dead
        setBaseURI(_initBaseURI1,1);//dying
        setBaseURI(_initBaseURI2,2);//hungry
        setBaseURI(_initBaseURI3,3);//satisfied

        setMintPassPublicKey(_mintPass_publickey); //set keypair half to verify mintPass
    }  


    // called from FLCE Contract
    // to verify wolf ownership and wolf.state>=2 prior to feeding FLCE
    // advances wolf state as needed, if not up to date with currentweek
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function verifyBeforeFeeding(uint256 _tokenId, address _signer) external returns(bool){

        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['FLCE'])), "unpermissed" );        
        require( _exists(_tokenId), "fake wolf");
        require( keccak256(abi.encodePacked(_signer)) == keccak256(abi.encodePacked(ownerOf(_tokenId))), "don't own it");    
        
        
        GameContract.advanceWolf(_tokenId);

        
        //GameContract.getWolfState(_tokenId);
        //problem line
        require(GameContract.getWolfState(_tokenId) >= 2, "not healthy");
        
        return true;
    }


    // called from Game Contract
    // to verify wolf ownership and wolf.state==1 prior to feeding sheep
    // advances wolf state if not uo to date with currentweek prior to state check
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function verifyBeforeEatingSheep(uint256 _tokenId, address _signer) external returns(bool){
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "unpermissed .2" );
        require( _exists(_tokenId), "fake wolf" );        
        require( keccak256(abi.encodePacked(_signer)) == keccak256(abi.encodePacked(ownerOf(_tokenId))), "don't own .2");    
        
        GameContract.advanceWolf(_tokenId);
        require(GameContract.getWolfState(_tokenId) == 1, "not dying");
        return true;
    }


    function exists(uint256 _tokenId) external view returns (bool){
        return _exists(_tokenId);
    }
    
                
    // █▀▄▀█ █ █▄░█ ▀█▀
    // █░▀░█ █ █░▀█ ░█░
    // front end passes a predetermined MintPass(json) that contains hash of user's address 
    // signed with an off chain admin keypair to verify whitelist status
    // verify # minting, supply, whitelist, cost and mint
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function mint(MintPass memory _mintPass, uint256 _mintAmount) public payable {
        require(!mintEnded, "mint ended");
        require(!paused, "contract paused");
        require(_mintAmount > 0, "0");
        require(_mintAmount <= maxMintAmount, "max mint" );
        uint256 numAlreadyMinted = totalSupply(); 
        require(numAlreadyMinted + _mintAmount <= maxSupply, "too many");

        if (onlyWhitelisted == true) {
            //hash senders address to validate whitelist status
            bytes32 digest = keccak256(abi.encode(0, msg.sender));
            //verify mintpass
            require(approveSender(digest, _mintPass), "MintPass err" );
        }

        //verify NFTs owned after proposed mint is less than max allowed per wallet
        require(addressMintedBalance[msg.sender] + _mintAmount <= nftPerAddressLimit, "max NFT" );
        
        //check funds and mint
        //initalize wolf stats and add to Game data
        require(msg.value >= cost * _mintAmount, "no funds");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, numAlreadyMinted + i);

            GameContract.initNewWolf(numAlreadyMinted+i);
        }
    }


    // called from GameContract.startWolfLifeCycle() when timers/game begins
    // end's minting 
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function endMint() external{
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "unpermissed" );
        mintEnded = true; //used to end mint session
    }


    // called from GameContract.endGame() if last living wolf owner signs transaction
    // gives entire balance of contract to signer
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function claimPot(address _signer) external{
        require(ownerPaid, "owner needs to claim their part");
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Game only" );
        (bool success, ) = payable(_signer).call{value: address(this).balance}("");
        require(success);
    }


    // called from GameContract.endGame() if timer is expired and called by a living wolf 
    // transfers percentage of contract balance to signer
    // % = (living wolves in wallet) / (total living wolves)
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function claimPotPie(address _signer, uint256 _cut) external{
        require(ownerPaid, "pie not cut");
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Game Only" );
        require(getBalance() > 0, "pot is empty");
        //require(getBalance() >= (totalRewardPool * _cut) /100, "not enough in pot");
        require(getBalance() >= (totalRewardPool / _cut), "not enough in pot");

        //uint256 amount = (totalRewardPool * _cut) /100;
        uint256 amount = (totalRewardPool / _cut) ;
        (bool success, ) = payable(_signer).call{value: amount}("");
        require(success);
    }


    // returns avaialable, max supply for front end display
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function howMany() public view returns (string memory, string memory) {
        uint256 remaining = maxSupply - totalSupply();
        return (Strings.toString(maxSupply), Strings.toString(remaining));
    }


    // return token IDs of current wallet
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }



///FIXING THIS...w did I do???revert??
    // return token correct token URI based on wolf state
    // bring currentState up to date by finding how many weeks since last updated
    // pad filename with 0s
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function tokenURI(uint256 _tokenId) public view override returns (string memory){
        /*
        require( _exists(_tokenId), "no token" );
        uint8 currentState = GameContract.getWolfState(_tokenId);
        uint8 weeksBehind = GameContract.currentWeek() - GameContract.getWolfLastWeekUpdated(_tokenId);
        if( currentState - weeksBehind < 0){
            currentState = 0;
        }
*/
        //uint8 currentState = actualState(_tokenId);
        require( _exists(_tokenId), "no token" );
        uint8 currentState =  GameContract.viewAdvanceWolf(_tokenId);
        return bytes(wolfBaseURI[currentState]).length > 0 ? string( abi.encodePacked( wolfBaseURI[currentState], UtilitiesContract.pad(_tokenId - 1), ".json" ) ) : "";
    }




    function actualState(uint256 _tokenId) public view returns (uint8){
        require( _exists(_tokenId), "no token" );
        return GameContract.viewAdvanceWolf(_tokenId);

    }

    // validate MintPass(off chain transaction signed by admin keypair)
    // check if mintpass is included, message == hash(msg.sender),
    // & recovered signer of message == adminKey
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function approveSender(bytes32 _digest, MintPass memory _mintPass) private view returns (bool) {
        address signer = ecrecover(_digest, _mintPass.v, _mintPass.r, _mintPass.s);
        require(signer == mintPass_publickey, "MintPass err .2");
        bytes32 messageHash = keccak256(abi.encode(0, _mintPass.message));
        require( _digest == messageHash, "MintPass err .3" );

        return true;
    }


    function getBalance() public view returns(uint256){
        return address(this).balance;
    }


    // Premint 66 Wolves (includes giveaway wolves)
    // must be done in multiple transactions due to gas
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function OwnerMint(uint256 _numToMint) public onlyOwner {
        require(ownerMinted < ownerAllowed,"all");
        uint256 numAlreadyMinted = totalSupply(); //0       
        for (uint256 i = 1; i <= _numToMint; i++) {
            if(ownerMinted < ownerAllowed){
                addressMintedBalance[msg.sender]++;
                _safeMint(msg.sender, numAlreadyMinted + i);
                GameContract.initNewWolf(numAlreadyMinted + i);
                ownerMinted++;
            }
        }
    }


    function endWhitelist() public onlyOwner(){
        onlyWhitelisted = false;
    }


    function setCost(uint256 _cost) public onlyOwner(){
        cost = _cost;
    }


    function setmaxMintAmount(uint8 _maxMintAmount) public onlyOwner(){
        maxMintAmount = _maxMintAmount;
    }


    function setBaseURI(string memory _newBaseURI, uint256 _state) public onlyOwner {
        wolfBaseURI[_state] = _newBaseURI;
    }


    function setNftPerAddressLimit(uint16 _limit) public onlyOwner{
        nftPerAddressLimit = _limit;
    }


    function setMintPassPublicKey(address _mintPass_publickey) public onlyOwner{
        mintPass_publickey = _mintPass_publickey;
    } 


    function pause(bool _state) public onlyOwner {
        paused = _state;
    }


    // owner claim portion of minting fees
    // set prize pool total = to remainder
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function withdraw() public payable onlyOwner {
        require(!ownerPaid, "already took cut");
        (bool success, ) = payable(owner()).call{value: (address(this).balance * percentageToOwner) /100}("");
        require(success);
        ownerPaid = true;
        totalRewardPool = address(this).balance;
    }


    //used for testing
    //function getBaseURIByState(uint256 _state) public view returns(string memory) {
    //    return wolfBaseURI[_state];
    //}
}