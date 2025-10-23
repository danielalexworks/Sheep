// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/********************
// manages time passed since start of each week
// manages time passed since start of game 
// +
********************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AddressStorage.sol";

contract Timer is Ownable, AddressStorage{

	uint256 public weekStartTime = 0;
  uint256 public gameStartTime;
  bool gameStarted = false;
  uint256 adv = 0;

	constructor()  {
        
  }

    // gets current time and adds fast forwarded time (for debugging)
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function nowish() public view returns(uint256){
      return block.timestamp + adv;
    }


    // checks if game is started
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function isGameStarted() public view returns(bool){
      return gameStarted;
    }


    // allows owner to advance time (for debugging)
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function advTime(uint256 t) public onlyOwner{
      adv = adv + t;
    }


    // called from GameContract
    // starts / resets weeklyTimer
    // if it has been over 1 week since called, then set startTime = (weekStartTime - how far overshot week)
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾    
    function startWeeklyTimer() external{
    	require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Only Wolf Contract can call this function" );

    	if( isWeeklyTimerExpired() && gameStarted ){
        uint256 overage;
        if(nowish()-7 days > weekStartTime){ 
           overage = ( nowish() - 7 days ) - weekStartTime; 
        }
        weekStartTime = nowish() - overage;
      }
    }


    // returns elapsed time since current weekly timer began.
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getWeeklyTimer() public view returns(uint256){
    	return nowish() - weekStartTime;
    }


    // returns elapsed time since 2 year timer began.
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getGameTimer() public view returns(uint256){
      return nowish() - gameStartTime;
    }


    //  check if 1 week has elapsed since weeklytimer began.
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function isWeeklyTimerExpired() public view returns(bool){
    	if( weekStartTime <= (nowish() - 7 days) ){
    		return true;
    	}else{
    		return false;
    	}
    }


    //  check if 2 years has elapsed since weeklytimer began.
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function isGameTimerExpired() public view returns(bool){
      if( gameStartTime <= (nowish() - 730 days) ){
        return true;
      }else{
        return false;
      }
    }


    // called from GameContract
    // start 2 year timer, can only be called once. 
    // start game..ie wolves are now hungry
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function startGameTimer() external{
      require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Only Wolf Contract can call this function" );
      require(gameStarted == false, "Wolves are already feeding");
      gameStartTime = nowish();
      weekStartTime = nowish();
      gameStarted = true;
    }


    /*
    // get modified blockTimestamp ??
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getBlockTimestamp() public view returns(uint256){
        return nowish();
    }
    */

}