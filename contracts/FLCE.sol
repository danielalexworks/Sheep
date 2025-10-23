// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/********************
// ERC-20 token claimable by living wolf NFT owners each week
// amount claimable determined by wolf's stats
// Wolves must eat (burn) 10 tokens per week to stay alive
// weekly supply determined by (# of living wolves) * 10
// no max supply 
// +
********************/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AddressStorage.sol";


contract FLCE is ERC20, Ownable, AddressStorage{
    
    uint256 public FLCEOutstanding = 0;
    uint256 public FLCEClaimable = 0;

    constructor() ERC20("Fleece", "FLCE") {
    }

    // called from GameContract getMaFLCE() once a week
    // set the amount of FLCE that can be minted this week
    // amount = (state3 wolves from previous week) * 10
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function prepFLCE(uint256 _amount) external returns(uint256){
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Only Wolves can mint Fleece" );
        FLCEClaimable = (_amount * 10**uint(decimals()));
        return FLCEClaimable;
    }


    // called from GameContract
    // mints alloted FLCE to signers wallet, tracks
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾ 
    function getFLCE(address _account, uint256 _amount) external {
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['game'])), "Only Wolves can request Fleece" );
        //require(FLCEClaimable >= _amount* 10**uint(decimals()), "not enough fleece prepped");
        require(FLCEClaimable >= _amount, "not enough fleece prepped");
        //_mint(_account, _amount* 10**uint(decimals()));
        //FLCEClaimable -= _amount * 10**uint(decimals());
        //FLCEOutstanding += _amount * 10**uint(decimals());
        _mint(_account, _amount );
        FLCEClaimable -= _amount ;
        FLCEOutstanding += _amount ;
    }


    // FLCE is burned and wolf eats it; wolf state changes if fed enough
    // verify wolf ownership, state, wallet FLCE balance via GameContract
    // burn FLCE 
    // update wolf stats in GameContract
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function feedFLCE(uint256 _tokenId, uint256 _amount) public{
        //verify wolf exists, owned by signer, hungry
        GameContract.advanceWolf(_tokenId);

        //prob
        
        require(WolfContract.verifyBeforeFeeding(_tokenId, msg.sender), "you cannot feed this wolf" );   

        require(TimerContract.isWeeklyTimerExpired()==false, "week expired, new week has yet to begin");

        //require FLCE balance
        uint256 amnt = _amount;//* 10**uint(decimals());
        require(balanceOf(msg.sender) >= amnt, "You can't consume FLCE you don't own.");
       
        burnFLCE(msg.sender, amnt);
        GameContract.updateAfterFeedingFLCE(_tokenId, _amount);
       
    }


    // burn FLCE that has been eaten
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function burnFLCE(address _signer, uint256 _amount) private{
        _burn(_signer, _amount);
        FLCEOutstanding -= _amount;
    }


    // return amount of prepped FLCE for the week
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getClaimableFLCE() public view returns(uint256){
        return FLCEClaimable;
    }


}
