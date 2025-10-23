// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AddressStorage.sol";

/* 
interface PotInterface{
    function getPotBalance() public view returns(uint256);
}
*/

/*TODO



claim LP
*/
contract Pot is Ownable, AddressStorage{
	//mapping(string => address) private contractAddress;
/*am*/
	address TokeContractAddress = 0x0000000000000000000000000000000000000000;
	IERC20 TokeI; // STAND IN

	address LPTokeContractAddress = 0x0000000000000000000000000000000000000000;
	IERC20 LPTokeI; // LP Token STAND IN

	//accounting variables
	uint256 public balanceAvailable;
	uint256 public lockedLPTokens;
	uint256 public removedLPTokens;

	constructor() public {
        TokeI = IERC20(TokeContractAddress);
        LPTokeI = IERC20(LPTokeContractAddress);
        removedLPTokens = 0;
        
    }

    //..get balance generated from rewards of LP tokens.
    function getPoolBalance() public view returns(uint256){ 
       return TokeI.balanceOf(address(this));
    }

	//function getPoolTokens(uint256 _amount) public returns(uint256){

	//..called from FLCE contract when FLCE is swapped and burnt 
	// transefers specified amount of FLCE from Pool to signer 	
	function removePoolTokens(address _signer, uint256 _amount) external{
		//verify requsting contract
		require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['FLCE'])), "Only FLCE Contract can request Fleece" );

		//transfer FLCE to Wolf Owner
		TokeI.transfer(_signer, _amount);
	}

	//..returns balance of LP tokens locked in contract
	function getPotBalance() public view returns(uint256){ 
       return LPTokeI.balanceOf(address(this));
   }

   //..transfers all LP tokens in contract to signer from WOLF contract
   // callable only by last living wolf. Only callable if one wolf remains
   function claimPot(address _signer) external{
		require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Only Wolves can claim the Pot" );
		LPTokeI.transfer(_signer, getPotBalance());		
		removedLPTokens = getPotBalance();
	}


///MATH THIS
	//..transfers percentage of LP tokens to signer from WOLF contract
	// percentage is based on how many wolves are alive after 2 years.
	// only callable after 2 years from start of hungry wolves.
	function claimPotPie(address _signer, uint256 _cut) external{
		require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['wolf'])), "Only Wolves can claim the Pot" );
		require(getPotBalance() > 0, "pot is empty");
		require(getPotBalance() >= lockedLPTokens / _cut, "not enough in pot"); ///likely needs adjusting for cut and safemath

		uint256 amount = lockedLPTokens / _cut;
		LPTokeI.transferFrom(address(this), _signer, amount);

}

function fillPot(uint256 _amount) public{
		require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['wolf'])), "Only Wolves can fill the Pot" );
		LPTokeI.transferFrom(msg.sender, address(this), _amount);
		lockedLPTokens = _amount;
	}



////NECESSARY FOR SIMULATION

	function fillFakePot(uint256 _amount) public{
		LPTokeI.transferFrom(msg.sender, address(this), _amount);
		lockedLPTokens = _amount;
	}

	function fillPool(uint256 _amount) public{
		TokeI.transferFrom(msg.sender, address(this), _amount);
	}


}
