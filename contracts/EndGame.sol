// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AddressStorage.sol";



contract EndGame is Ownable, AddressStorage{

	

/*
//after two year timer expires or 1 wolf left, allocate LP tokens
    //  if game expired; calculate %of LP tokens go to owner, based on ownedwolves / totalalive
    //  
    function endGame() public{

        //if 2 year time period has expired allow living wolves to collect share of pot
        require(PotContract.getPotBalance() > 0, "pot is not.");

        uint256[] memory wolvesInWallet = walletOfOwner(msg.sender);

        if(TimerContract.isGameTimerExpired()){

            if(!ended){
                wolfContract.setNumSurvivors(wolfContract.livingWolfCount());
            }

            //if wolf in wallet is in healthyWolves
            // add wolf to immortals mapping
            // delete wolf from HealthyWolves so they can't claim twice
//add claimedPot bool to struct?
            
            uint256[] memory immortals;

            for(uint8 i=0; i<wolvesInWallet.length; i++){
                if(wolfContract.wolves(wolvesInWallet[i]).wolfState >= 2){
                   immortals[immortals.length] = wolvesInWallet[i];
                   wolfContract.setClaimedPot(wolvesInWallet[i]); // = true need setter
                   wolfContract.setImmortal(wolvesInWallet[i]);// = true;  //need setter
                }
            }

            //uint256 cut = (immortals.length / numSurvivors) * 100;
            PotContract.claimPotPie(msg.sender, (immortals.length / wolfContract.numSurvivors()) * 100);

            ended = true;

            
        //if only one wolf is left, allow wolf to collect pot
        // consider revived sheep with state 3 
        //and state 2's with hungrywolvesthisweek
        }else if(wolfContract.livingWolfCount() == 1){
            //uint256 s3Num = state3Ids.length; //trying to store this and use

            uint256 s3Length = wolfContract.gets3Length();
            require(s3Length < 2, "not a lone");
            
            uint256 immortalWolf;

//what if  wallet has last living wolves (multiple)?

            //if only 1 state 3 wolf and is in signer's wallet
            //and no other hungry wolves this week
            if(s3Length == 1 && wolfContract.hungryWolvesThisWeek(currentWeek) <= 1){
                for(uint8 i=0; i<wolvesInWallet.length; i++){
                    if(wolvesInWallet[i] == wolfContract.state3Ids(0)){
                        immortalWolf = wolvesInWallet[i];
                    }
                }
            //if only 1 hungry wolf, and no state 3s, and is in signer's wallet
            }else if(s3Length == 0 && wolfContract.hungryWolvesThisWeek(currentWeek) == 1){
                for(uint8 i=0; i<wolvesInWallet.length; i++){
                    if(wolfContract.wolves(wolvesInWallet[i]).wolfState == 2){
                        immortalWolf = wolvesInWallet[i];
                    }
                }
            }


            PotContract.claimPot(msg.sender);
            ended = true;
            numSurvivors = 1;
            wolfContract.setClaimedPot(wolvesInWallet[i]); // = true need setter
            wolfContract.setImmortal(wolvesInWallet[i]);// = true;  //need setter
           
        }
   }
   */

}