// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AddressStorage.sol";

//***********************************
// manages info on wolves state, stats, etc
// facilitates interaction with other contracts through 
// primary public functions for collecting FLCE, eating sheep, ending game
//***************************************/
contract GameFunctions is Ownable, AddressStorage {

    using Strings for uint256;

    // stats fed at constructor modified when sheep is eaten
    uint8[] public wolfStats;
    uint8[] public sheepStats;


    struct Wolfs{
        uint256 tokenId;
        uint256 allottedFLCE;
        uint8 wolfState;
        uint256 needsToEatAmount;
        uint8 stats;
        uint8 lastWeekUpdated;
        uint8 lastWeekClaimed;
        bool immortal;
        bool claimedPot;
    }
    Wolfs[] public wolves;

    // store tokenIds of immortal wolves after game ends
    uint256[] immortals;

    // # of weeks
    uint8 public currentWeek;

    // used to track fed and revived wolves each week to determin hungry wolves the following week
    uint256[] public state3Ids;

    // currentWeek => # of wolves that start the week in state 2 (hungry) 
    // derived from state3Ids at the beginning of each week
    mapping(uint8 => uint256) public hungryWolvesThisWeek;

    // currentWeek => total of all healthy wolve's stats
    // to use in calculation for each wolf's percentage of FLCE
    // a running total is kept as wolves are fed or revived
    // used for following week
    mapping(uint8 => uint32) public totalHealthyWolfStats;

    // FLCE available in current week. Used to calculate allotedFLCE
    uint256 public totalWeeklyFLCEAvailable;

    // game has ended
    bool public ended = false;

    // # of wolfs revived by eating sheep during current week
    // used to determine how many living wolves / endGame()
    uint16 public revivedThisWeek;

    // used in endGame() to determine percentage of pot to each winner
    uint256 public numSurvivors;
 
    
    constructor() {
        currentWeek = 0;
        totalHealthyWolfStats[0] = 0;
    }  


    //debugging
    function getWS3() public view returns(uint32){
        uint32 statTotal;// = 0;
        
        for(uint i=0; i<state3Ids.length; i++){
           statTotal += wolfStats[state3Ids[i]-1];
        }

        return statTotal;
    }
   

    //debugging
    function statTota(uint16 _n) public view returns(uint256){
        uint16 t = 0;
        for(uint i=0; i<_n; i++){
            t += wolfStats[i];
        }
        return(t);
    }

    function gets3Length() public view returns(uint256){
        return state3Ids.length;
    }


//can be private
//public for debugging
    // returns wolf state after making sure it is up to date
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getWolfState(uint256 _tokenId) public view returns(uint8){
        //advanceWolf(_tokenId);
        return viewAdvanceWolf(_tokenId);
    }





    function getWolfLastWeekUpdated(uint256 _tokenId) public view returns(uint8){
        return wolves[_tokenId - 1].lastWeekUpdated;
    }


    //push initial stats for wolves and sheep
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function setWolfStats(uint8[] memory _stats) public onlyOwner{
        for(uint16 i=0; i<_stats.length; i++){
            wolfStats.push(_stats[i]);
        }
    }
    function setSheepStats(uint8[] memory _stats) public onlyOwner{
        for(uint16 i=0; i<_stats.length; i++){
            sheepStats.push(_stats[i]);
        }
    }


    //░██████╗░███████╗████████╗  ███████╗██╗░░░░░░█████╗░███████╗
    //██╔════╝░██╔════╝╚══██╔══╝  ██╔════╝██║░░░░░██╔══██╗██╔════╝
    //██║░░██╗░█████╗░░░░░██║░░░  █████╗░░██║░░░░░██║░░╚═╝█████╗░░
    //██║░░╚██╗██╔══╝░░░░░██║░░░  ██╔══╝░░██║░░░░░██║░░██╗██╔══╝░░
    //╚██████╔╝███████╗░░░██║░░░  ██║░░░░░███████╗╚█████╔╝███████╗
    //░╚═════╝░╚══════╝░░░╚═╝░░░  ╚═╝░░░░░╚══════╝░╚════╝░╚══════╝/
    // called by user to collect FLCE for the current week
    // if called for the first time in current week, 
    // it modifies weekly tracking vars  
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function getMaFLCE(uint256 _tokenId) public{
        require(TimerContract.isGameStarted(), "not started");
        require(TimerContract.isGameTimerExpired() == false, "game over man");
 
 //not getting called???
        // if first run this week
        if(TimerContract.isWeeklyTimerExpired()){
            revivedThisWeek = 0;
            TimerContract.startWeeklyTimer();
   
            currentWeek++;

            totalHealthyWolfStats[currentWeek] = 0;

            // # of fed wolves from week that is ending now (these be will be hungry)
            hungryWolvesThisWeek[currentWeek] = (state3Ids.length);
            delete state3Ids;

            // sets amount of FLCE that can be minted this week
            totalWeeklyFLCEAvailable = FLCEContract.prepFLCE(hungryWolvesThisWeek[currentWeek] * 10);

        }
       
        uint256 allottedFLCETotal;

        require( keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(WolfContract.ownerOf(_tokenId))), "don't own it");    
        if(WolfContract.exists(_tokenId)){
                advanceWolf(_tokenId);

                if(wolves[_tokenId-1].lastWeekClaimed < currentWeek){
                    wolves[_tokenId-1].needsToEatAmount = 10 * 10**uint(FLCEContract.decimals());
                    uint256 allottedFLCETotal = calculateAllottedFLCE(_tokenId);
                    if( allottedFLCETotal > 0){
                        FLCEContract.getFLCE(msg.sender, allottedFLCETotal);
                    }
                    wolves[_tokenId-1].lastWeekClaimed = currentWeek;
                }  
        }
    }


    // returns amount of FLCE claimable by a wolf
    // % based on (it's stats / total stats) * FLCE availble this week
    // totalHealthyWolfStats[currentWeek-1] = total stats from last week's state3 wolves
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function calculateAllottedFLCE(uint256 _tokenId) private returns(uint256){
        if(wolves[_tokenId-1].wolfState >= 2){ //if wolf is healthy
            wolves[_tokenId-1].allottedFLCE = ((totalWeeklyFLCEAvailable)*(wolves[_tokenId-1].stats)) / (totalHealthyWolfStats[currentWeek-1]);
            return wolves[_tokenId-1].allottedFLCE;
        }else{
            wolves[_tokenId-1].allottedFLCE = 0;
            return 0;
        }
    }



    // for front end
    // returns amount of FLCE claimable by a wolf (w/o state change of var)
    // % based on (it's stats / total stats) * FLCE availble this week
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function viewAllottedFLCE(uint256 _tokenId) public view returns(uint256){
        uint8 tempWolfState = viewAdvanceWolf(_tokenId);
        if(tempWolfState >= 2){ //if wolf is healthy
            return ((totalWeeklyFLCEAvailable)*(wolves[_tokenId-1].stats)) / (totalHealthyWolfStats[currentWeek-1]);
        }else{
            
            return 0;
        }
    }


    // returns updated wolf.state without modifying var state 
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function viewAdvanceWolf(uint256 _tokenId) public view returns(uint8){
        uint8 plus;

        if(TimerContract.isWeeklyTimerExpired() && currentWeek > 0){
            plus = 1;
        }

        //require( WolfContract.exists(_tokenId), "no token" );???
        uint8 currentState = wolves[_tokenId - 1].wolfState;
       
        uint8 weeksBehind = currentWeek - getWolfLastWeekUpdated(_tokenId);
        weeksBehind = weeksBehind + plus;
        if( currentState - weeksBehind < 0){
            currentState = 0;
        }else{
            currentState -= weeksBehind;
        }

        return currentState;


        //return wolves[_tokenId-1].wolfState - (currentWeek - wolves[_tokenId-1].lastWeekUpdated) - plus;
    }


    // called by FLCE Contract
    // updates wolf struct and other trackers after a wolf is fed FLCE
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function updateAfterFeedingFLCE(uint256 _tokenId, uint256 _amount) external{
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['FLCE'])), "not wolf" );
        if(wolves[_tokenId-1].needsToEatAmount <= _amount){ // if will be fully fed
            if(wolves[_tokenId-1].wolfState != 3){
                state3Ids.push(_tokenId);

                totalHealthyWolfStats[currentWeek] += wolves[_tokenId-1].stats;
            
                wolves[_tokenId-1].needsToEatAmount = 0;
                wolves[_tokenId-1].wolfState = 3; 
                wolves[_tokenId-1].lastWeekUpdated = currentWeek; //new
            }
        }else{ // if partially fed
            wolves[_tokenId-1].needsToEatAmount -= _amount;
        }
    }

    
                                    
    // █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ █▀█
    // ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ █▀▀
    // Feed sheep to wolf
    // Wolf state change from 1 to 3
    // Sheep is burned from SheepContract
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function eatSheep(uint16 _wolfTokenId, uint256 _sheepTokenId) public{  
        require(TimerContract.isGameStarted(), "not started");
        require(TimerContract.isGameTimerExpired() == false, "game over man");
        
        advanceWolf(_wolfTokenId);

        // check ownership and wolfstate
        WolfContract.verifyBeforeEatingSheep( _wolfTokenId, msg.sender);
        // if dying, make sure that a week has not elapsed without reset        
        require(TimerContract.isWeeklyTimerExpired() == false, "Your wolf is too far gone.");

        // reset the wolf's info and alter stats
        reviveWolf(_wolfTokenId, _sheepTokenId);

        sheepInterface.burnNFT(msg.sender, _sheepTokenId);
    }


                                                    
    // █▀ ▀█▀ ▄▀█ ▀█▀ █▀▀ █▀▀ █░█ ▄▀█ █▄░█ █▀▀ █▀▀ █▀
    // ▄█ ░█░ █▀█ ░█░ ██▄ █▄▄ █▀█ █▀█ █░▀█ █▄█ ██▄ ▄█

    // called by many functions to make sure wolf's state is up to date, since it is 
    // generally calculated lazily
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾    
    function advanceWolf(uint256 _tokenId) public{
         if(WolfContract.exists(_tokenId)){
            while(wolves[_tokenId-1].lastWeekUpdated < currentWeek && wolves[_tokenId-1].wolfState > 0){
                downGradeWolf(wolves[_tokenId-1].tokenId);
                wolves[_tokenId-1].lastWeekUpdated++;
                wolves[_tokenId-1].needsToEatAmount = 10 * 10**uint(FLCEContract.decimals());
            }
        }
    }


    // called from advanceWolf()
    // lowers state of wolf
    // if not healthy, then doesn't need to eat
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function downGradeWolf(uint256 _tokenId) private {
        if(wolves[_tokenId-1].wolfState > 0){  
            wolves[_tokenId-1].wolfState--;
           
            if(wolves[_tokenId-1].wolfState == 1){
                 wolves[_tokenId-1].allottedFLCE = 0;
            }
        }
    }


    // called from eatSheep()
    // set wolf state to fed, add to healthy wolf trackers
    // increment living wolves and state counters
    // call alterStats
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function reviveWolf(uint16 _wolfTokenId, uint256 _sheepTokenId) private{
        wolves[_wolfTokenId-1].wolfState = 3;
        wolves[_wolfTokenId-1].needsToEatAmount = 0; 
        //wolves[_wolfTokenId-1].lastWeekUpdated = currentWeek;//newly added-shouldn't need b/c advance wolf anyway
        state3Ids.push(_wolfTokenId);
        revivedThisWeek++;
        
        alterStats(_wolfTokenId, _sheepTokenId);
        totalHealthyWolfStats[currentWeek] += wolves[_wolfTokenId-1].stats;
        
    }

    // called from reviveWolf()
    // modify wolf stat based on sheep stat
    // subtract/add 1/2 the difference
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function alterStats(uint256 _wolfTokenId, uint256 _sheepTokenId) private{
        if(wolves[_wolfTokenId-1].stats > sheepStats[_sheepTokenId]){
            wolves[_wolfTokenId-1].stats = wolves[_wolfTokenId-1].stats - ( (wolves[_wolfTokenId-1].stats - sheepStats[_sheepTokenId]) /2);
        }else{
            wolves[_wolfTokenId-1].stats = wolves[_wolfTokenId-1].stats + ( (sheepStats[_sheepTokenId] - wolves[_wolfTokenId-1].stats) /2);
        }
    }


    // begin game (start timers)
    // end wolf mint   
    // set hungry tracker
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function startWolfLifeCycle() public onlyOwner{
        TimerContract.startGameTimer();
        WolfContract.endMint();    
        currentWeek = 1;
        hungryWolvesThisWeek[currentWeek] = state3Ids.length;
        delete state3Ids;
        totalWeeklyFLCEAvailable = FLCEContract.prepFLCE(hungryWolvesThisWeek[currentWeek] * 10);
       
    }

//here
    // can only be called after two year timer expires OR there is 1 wolf left
    // if game expired; calculate % of WolfContract's  balance to go to owner, based on 1 / totalAlive
    // if only one wolf left, give them WolfContract's  balance
    // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    function endGame(uint256 _tokenId) public{
        
        require(WolfContract.ownerPaid(), 'owner needs cut');
        require(TimerContract.isGameStarted(), "not started");
        require( keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(WolfContract.ownerOf(_tokenId))), "don't own it");    
        require(wolves[_tokenId-1].claimedPot == false, 'no double dipping');
        advanceWolf(_tokenId);

        uint256 immortalWolf;
        bool weHaveAWinner = false;

        // if timer expired
        if(TimerContract.isGameTimerExpired()){ 
            // if endgame has yet to be called successfully,
            // calc num of surviving wolves = num of state 2 wolves at beginning of week + num revived with sheep
            if(!ended){
                numSurvivors = hungryWolvesThisWeek[currentWeek] + revivedThisWeek;
            }

            // if qualifies, collect alloted portion of pot
            if(wolves[_tokenId-1].wolfState >= 2 && wolves[_tokenId-1].claimedPot == false){
                immortalWolf = _tokenId;
                //WolfContract.claimPotPie(msg.sender, (1 / numSurvivors) * 100);
                WolfContract.claimPotPie(msg.sender, numSurvivors);
                wolves[_tokenId-1].claimedPot = true;
                wolves[_tokenId-1].immortal = true;
                immortals.push(_tokenId);

                ended = true;
            }
           
        //if one wolf left
        }else if(hungryWolvesThisWeek[currentWeek] + revivedThisWeek == 1){
            
            //if this the only 3 wolf (revived or fed)
            if(state3Ids.length == 1 && wolves[_tokenId-1].wolfState == 3){
                immortalWolf = _tokenId;
                weHaveAWinner = true;
                immortals.push(_tokenId);
           
            //elif this only hungry wolf
            }else if(hungryWolvesThisWeek[currentWeek] == 1 && wolves[_tokenId-1].wolfState >= 2){
                    if(wolves[_tokenId-1].wolfState >= 2){
                        immortalWolf = _tokenId;
                        weHaveAWinner = true;
                        immortals.push(_tokenId);
                    }
            }

            //if qualifies, collect entire pot
            if(weHaveAWinner){
                WolfContract.claimPot(msg.sender);
                ended = true;
                numSurvivors = 1;
                wolves[immortalWolf-1].immortal = true;
                wolves[immortalWolf-1].claimedPot = true;
            }
           
        }

        require(immortalWolf > 0, "get the nope out");

   }


   // called from WolfContract when wolf minted
   // adds new wolf to wolfs[] struct, with data required for game
   // adds wolf to a few other things
   // ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
   function initNewWolf(uint256 _tokenId) external{

            require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(contractAddress['wolf'])), "not wolf" );
        
            Wolfs memory newWolf;
            newWolf.tokenId = _tokenId;
            newWolf.allottedFLCE = 0;
            newWolf.wolfState = 3;
            newWolf.needsToEatAmount = 0;
            newWolf.stats = wolfStats[_tokenId-1];
            newWolf.lastWeekUpdated = 0;
            newWolf.immortal = false;
            newWolf.claimedPot = false;
            wolves.push(newWolf);

            totalHealthyWolfStats[0] += newWolf.stats;
            state3Ids.push(_tokenId);
    }

//donot need
    function seePotPie() public view returns(uint256){
   
            uint256 numSurvivors = hungryWolvesThisWeek[currentWeek] + revivedThisWeek; 

            return ((numSurvivors));
    }

}


