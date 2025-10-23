// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************            
// inherited by each contract that needs to be linked together
// Allows for updating the stored addresses in all linked contracts from a single source
// Interacted with through AddressManager (one AddressManager controls many AddressStorage)
// +
****************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface SheepInterface{
    function burnNFT(address _signer, uint256 _tokenId) external returns(bool);
    function ownerOf(uint256 tokenId)  external view returns (address);
}
 
contract SheepI{
    function burnNFT(address _signer, uint256 _tokenId) external returns(bool){}
}

contract FLCEI{
    function getFLCE(address _account, uint256 _amount) external {}
    function balanceOf(address account) public view virtual  returns (uint256) {}
    function prepFLCE(uint256 _amount) external returns(uint256) {}
    function getClaimableFLCE() public view returns(uint256){}
    function decimals() public view returns (uint8) {}
}

contract TimerI{
    function startWeeklyTimer() external {}
    function isWeeklyTimerExpired() public view returns(bool){}
    function startGameTimer() external{}
    function isGameTimerExpired() public view returns(bool){}
    function isGameStarted() public view returns(bool){}
}

contract WolfI{
    function verifyBeforeFeeding(uint256 _tokenId, address _signer) external  returns(bool){}
    function verifyBeforeEatingSheep(uint256 _tokenId, address _signer) external  returns(bool){}
    function exists(uint256 _tokenId) external returns (bool){}
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {}
    function endMint() external{}
    function claimPot(address _signer) external{}
    function claimPotPie(address _signer, uint256 _cut) external{}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function ownerPaid() public view returns (bool) {}
}

contract GameI{
    function getWolfState(uint256 _tokenId) public view returns(uint8){}
    function initNewWolf(uint256 _tokenId) external{}
    function updateAfterFeedingFLCE(uint256 _tokenId, uint256 _amount) external{}
    function advanceWolf(uint256 _tokenId) public{}
    function currentWeek() public view returns(uint8){}
    function getWolfLastWeekUpdated(uint256 _tokenId) public view returns(uint8){}
    function viewAdvanceWolf(uint256 _tokenId) public view returns(uint8){}
}

contract UtilitiesI{
    function pad(uint256 _n) external pure returns(string memory){}
}


contract AddressStorage is Ownable{

  mapping(string => address) public contractAddress;
  FLCEI FLCEContract;
  TimerI TimerContract;
  SheepI SheepContract;
  WolfI WolfContract;
  SheepInterface sheepInterface;
  UtilitiesI UtilitiesContract;
  GameI GameContract;


	constructor()  {
        // junk addresses
        // must be updated through AddressManager after contracts are deployed
        contractAddress['timer'] = 0x0000000000000000000000000000000000000000;
        contractAddress['FLCE'] = 0x0000000000000000000000000000000000000000;
        contractAddress['wolf'] = 0x0000000000000000000000000000000000000000;
        contractAddress['sheep'] = 0x0000000000000000000000000000000000000000;
        contractAddress['pixel'] = 0x0000000000000000000000000000000000000000;
        contractAddress['utilities'] = 0x0000000000000000000000000000000000000000;
        contractAddress['game'] = 0x0000000000000000000000000000000000000000;

        FLCEContract = FLCEI(contractAddress['FLCE']);
        TimerContract = TimerI(contractAddress['timer']);
        SheepContract = SheepI(contractAddress['sheep']);
        WolfContract = WolfI(contractAddress['wolf']);
        UtilitiesContract = UtilitiesI(contractAddress['utilities']);
        GameContract = GameI(contractAddress['game']);
        sheepInterface = SheepInterface(contractAddress['sheep']);

    }


    // called from AddressManager
    // sets connected contract's address storage
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function setAddress(string memory _name, address _address) external {
      require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['addressManager'])), "am only" );
      contractAddress[_name] = _address;
      resetInterfaceAddress(_name,_address);
    }


    // resets interface/ linked contract to new addess
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function resetInterfaceAddress(string memory _name, address _address) private{
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if(nameHash == keccak256(abi.encodePacked('sheep'))){
            SheepContract = SheepI(_address);
            sheepInterface = SheepInterface(_address);
        }else if(nameHash == keccak256(abi.encodePacked('FLCE'))){
            FLCEContract = FLCEI(_address);
        }else if(nameHash == keccak256(abi.encodePacked('timer'))){
            TimerContract = TimerI(_address);
        }else if(nameHash == keccak256(abi.encodePacked('wolf'))){
            WolfContract = WolfI(_address);
        }else if(nameHash == keccak256(abi.encodePacked('utilities'))){
           UtilitiesContract = UtilitiesI(_address);
        }else if(nameHash == keccak256(abi.encodePacked('game'))){
           GameContract = GameI(_address);
        }
    }


    //sets address manager's contract
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function setAddressManagerAddress(address _address) public onlyOwner{
      contractAddress['addressManager'] = _address;
    }

}