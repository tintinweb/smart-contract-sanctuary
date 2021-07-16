//SourceUnit: leaderBoardPool.sol

pragma solidity 0.4.25; /*


  _______ _____   ____  _   _ _              _           _____                          _       
 |__   __|  __ \ / __ \| \ | | |            (_)         |  __ \                        | |      
    | |  | |__) | |  | |  \| | |_ ___  _ __  _  __ _    | |__) | __ ___  ___  ___ _ __ | |_ ___ 
    | |  |  _  /| |  | | . ` | __/ _ \| '_ \| |/ _` |   |  ___/ '__/ _ \/ __|/ _ \ '_ \| __/ __|
    | |  | | \ \| |__| | |\  | || (_) | |_) | | (_| |   | |   | | |  __/\__ \  __/ | | | |_\__ \
    |_|  |_|  \_\\____/|_| \_|\__\___/| .__/|_|\__,_|   |_|   |_|  \___||___/\___|_| |_|\__|___/
                                      | |                                                       
                                      |_|                                                       
        
    ██╗     ███████╗ █████╗ ██████╗ ███████╗██████╗     ██████╗  ██████╗  █████╗ ██████╗ ██████╗     ██████╗  ██████╗  ██████╗ ██╗     
    ██║     ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██╔═══██╗██╔═══██╗██║     
    ██║     █████╗  ███████║██║  ██║█████╗  ██████╔╝    ██████╔╝██║   ██║███████║██████╔╝██║  ██║    ██████╔╝██║   ██║██║   ██║██║     
    ██║     ██╔══╝  ██╔══██║██║  ██║██╔══╝  ██╔══██╗    ██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║    ██╔═══╝ ██║   ██║██║   ██║██║     
    ███████╗███████╗██║  ██║██████╔╝███████╗██║  ██║    ██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝     ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝
                                                                                                                                       
                                                                                                                                       

----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Fund gets transferred into this contract while dividend distribution from dividend contracts
    => Dividend contracts get fund from game contracts while dividend distribution
    => This is global leader board pool for all games.
    => Higher degree of control by contract owner



------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed with ❤ by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/ 



//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    

contract owned {
    address internal owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.
        Signer calls following four functions:
            => request fund from game contract
    */
    address internal signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer);
        _;
    }

    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}




    
//**************************************************************************//
//---------------------  REF POOL MAIN CODE STARTS HERE --------------------//
//**************************************************************************//

contract TRONtopia_LeaderBoard_Pool is owned{

    /* Public variables of the contract */
    uint256 public leaderBoardPool;             //this will get 1% of the div distribution to pay for the referrers.
    

    // Events to track ether transfer to leaders
    event DividendPaidKindTopian(address indexed user, uint256 rank, uint256 amount, uint256 timestamp);
    event DividendPaidSidebetEmperor(address indexed user, uint256 rank, uint256 amount, uint256 timestamp);

    /*========================================
    =           STANDARD FUNCTIONS           =
    =========================================*/

    /**
        Fallback function. It accepts incoming TRX and add that into referral pool
        This is the only way for TRX to enter into the leaderBoardPool contract
    */
    function () payable external {
        leaderBoardPool += msg.value;
    }


    /**
        * Owner can claim any left-over TRX from this contract 
        * leaderBoardPool variable is reset to zero after every distribute
        * so, there are some case, when there are left-over TRX, which owner can withdraw
    */
    function claimOwnerRake(uint256 amount) public onlyOwner returns (string){
        address(owner).transfer(amount);
        return "TRX withdrawn to owner wallet";
    }



     /**
        Distribute the dividend to all leaderboard leaders1
        This function must always be called prior to distributeLeaders2
    */
    function distributeLeaders1(address[] luckyWinners) public onlySigner {

        uint256 totalLuckyWinners = luckyWinners.length;
        uint256 confirmedDividendForLeaderBoard = leaderBoardPool;

        require(totalLuckyWinners <= 10, 'Array size too large');
        require(confirmedDividendForLeaderBoard > 100, 'Insufficient trx balance' ); //there should be atleast 100 SUN of TRX to carryout this call

        uint256 currentTime = now;
        //please maintain the order of the winners/losers in the array as that is how it will be looped
        //loop for lucky winners
        for(uint256 i=0; i < totalLuckyWinners; i++){
            //allocating different dividends for different levels
            //we want to send TRX actively. So no passive Distribution.
            if(i==0){ //level 1
                uint256 winner1 = confirmedDividendForLeaderBoard / 2 * 500 / 1000;  //50% for level 1
                luckyWinners[i].transfer(winner1);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner1, currentTime);
            }
            else if(i==1){ //level 2
                uint256 winner2 = confirmedDividendForLeaderBoard / 2 * 200 / 1000;  //20% for level 2
                luckyWinners[i].transfer(winner2);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner2, currentTime);
            }
            else if(i==2){ //level 3
                uint256 winner3 = confirmedDividendForLeaderBoard / 2 * 100 / 1000;  //10% for level 3
                luckyWinners[i].transfer(winner3);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner3, currentTime);
            }
            else if(i==3 || i==4){ //level 4 and 5
                uint256 winner34 = confirmedDividendForLeaderBoard / 2 * 50 / 1000;  //5% for level 4 and 5
                luckyWinners[i].transfer(winner34);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner34, currentTime);
            }
            else if(i==5 || i==6){ //level 6 and 7
                uint256 winner56 = confirmedDividendForLeaderBoard / 2 * 30 / 1000;  //3% for level 6 and 7
                luckyWinners[i].transfer(winner56);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner56, currentTime);
            }
            else if(i==7){ //level 8
                uint256 winner8 = confirmedDividendForLeaderBoard / 2 * 20 / 1000;  //2% for level 8
                luckyWinners[i].transfer(winner8);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner8, currentTime);
            }
            else{ //level 9 and 10
                uint256 winner910 = confirmedDividendForLeaderBoard / 2 * 10 / 1000;  //1% for level 9 and 10
                luckyWinners[i].transfer(winner910);
                emit DividendPaidKindTopian(luckyWinners[i], i+1, winner910, currentTime);
            }
        }

    }


    /**
        Distribute the dividend to all leaderboard leaders2
        This function always must be called after distributeLeaders1, 
        because this function sets confirmedDividendForLeaderBoard = 0 at end
    */
    function distributeLeaders2(address[] unluckyLosers) public onlySigner {

        uint256 totalUnluckyLoosers = unluckyLosers.length;
        uint256 confirmedDividendForLeaderBoard = leaderBoardPool;

        require(totalUnluckyLoosers <= 10, 'Array size too large');
        require(confirmedDividendForLeaderBoard > 100, 'Insufficient trx balance' ); //there should be atleast 100 Gwei of TRX to carryout this call

        uint256 currentTime = now;
        //loop for side bet emperors
        for(uint256 j=0; j < totalUnluckyLoosers; j++){
            //allocating different dividends for different levels
            if(j==0){ //level 1
                uint256 loser1 = confirmedDividendForLeaderBoard / 2 * 500 / 1000;  //50% for level 1
                unluckyLosers[j].transfer(loser1);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else if(j==1){ //level 2
                uint256 loser2 = confirmedDividendForLeaderBoard / 2 * 200 / 1000;  //20% for level 2
                unluckyLosers[j].transfer(loser2);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else if(j==2){ //level 3
                uint256 loser3 = confirmedDividendForLeaderBoard / 2 * 100 / 1000;  //10% for level 3
                unluckyLosers[j].transfer(loser3);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else if(j==3 || j==4){ //level 4 and 5
                uint256 loser34 = confirmedDividendForLeaderBoard / 2 * 50 / 1000;  //5% for level 4 and 5
                unluckyLosers[j].transfer(loser34);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else if(j==5 || j==6){ //level 6 and 7
                uint256 loser56 = confirmedDividendForLeaderBoard / 2 * 30 / 1000;  //3% for level 6 and 7
                unluckyLosers[j].transfer(loser56);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else if(j==7){ //level 8
                uint256 loser8 = confirmedDividendForLeaderBoard / 2 * 20 / 1000;  //2% for level 8
                unluckyLosers[j].transfer(loser8);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
            else{ //level 9 and 10
                uint256 loser910 = confirmedDividendForLeaderBoard / 2 * 10 / 1000;  //1% for level 9 and 10
                unluckyLosers[j].transfer(loser910);
                emit DividendPaidSidebetEmperor(unluckyLosers[j], j+1, loser1, currentTime);
            }
        }

        //updating the leaderBoardPool variable
        leaderBoardPool = 0;
    
    }



  
    


}