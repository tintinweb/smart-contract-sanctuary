//SourceUnit: dividend.sol

pragma solidity 0.4.25; /*


  _______ _____   ____  _   _ _              _           _____                          _       
 |__   __|  __ \ / __ \| \ | | |            (_)         |  __ \                        | |      
    | |  | |__) | |  | |  \| | |_ ___  _ __  _  __ _    | |__) | __ ___  ___  ___ _ __ | |_ ___ 
    | |  |  _  /| |  | | . ` | __/ _ \| '_ \| |/ _` |   |  ___/ '__/ _ \/ __|/ _ \ '_ \| __/ __|
    | |  | | \ \| |__| | |\  | || (_) | |_) | | (_| |   | |   | | |  __/\__ \  __/ | | | |_\__ \
    |_|  |_|  \_\\____/|_| \_|\__\___/| .__/|_|\__,_|   |_|   |_|  \___||___/\___|_| |_|\__|___/
                                      | |                                                       
                                      |_|                                                       


    ██████╗ ██╗██╗   ██╗██╗██████╗ ███████╗███╗   ██╗██████╗     ██████╗  ██████╗  ██████╗ ██╗     
    ██╔══██╗██║██║   ██║██║██╔══██╗██╔════╝████╗  ██║██╔══██╗    ██╔══██╗██╔═══██╗██╔═══██╗██║     
    ██║  ██║██║██║   ██║██║██║  ██║█████╗  ██╔██╗ ██║██║  ██║    ██████╔╝██║   ██║██║   ██║██║     
    ██║  ██║██║╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║╚██╗██║██║  ██║    ██╔═══╝ ██║   ██║██║   ██║██║     
    ██████╔╝██║ ╚████╔╝ ██║██████╔╝███████╗██║ ╚████║██████╔╝    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚═════╝ ╚═╝  ╚═══╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═════╝     ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝
                                                                                                


----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Fund gets transferred into this contract periodically from games contracts
    => fund will be requested by token contract, while dividend distribution

=== Independant Audit of the code ===
    => https://hacken.io
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/ 


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
    }
}



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
//---------------------    GAMES CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceGAMES {
    function displayAvailableDividend() external returns (bool, uint256);
    function requestDividendPayment(uint256 amount) external returns(bool);
    function getAvailableDivRake() external returns (uint256);
    function requestDivRakePayment(uint256 amount) external returns(bool);
}  


//**************************************************************************//
//---------------------  TRONTOPIA CONTRACT INTERFACE  ---------------------//
//**************************************************************************//
 
interface TRONtopiaInterface
{
    function transfer(address recipient, uint amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user, uint256 _refBonus, uint256 _trxAmount ) external returns(bool);
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);

    function totalFrozenTopiaIndividual() external returns(uint256,uint256,uint256);
    function frozenTopiaGlobal() external returns(uint256);
    function withdrawUnfrozenTopia() external returns(bool);
    function userFreezeTierAndAmount(address user) external returns(uint256, uint256);
}

    
//**************************************************************************//
//---------------------  DIV POOL MAIN CODE STARTS HERE --------------------//
//**************************************************************************//

contract TRONtopia_Dividend_Pool is owned{

    /* Public variables of the contract */
    using SafeMath for uint256;
    address public topiaTokenContractAddress;
    address public refPoolContractAddress;
    address public leaderBoardContractAddress;
    uint256 public refPoolPercentSUN = 1000000;   //this is in tron decimal / SUN - default 1%
    uint256 public leaderboardsPercentSUN = 1000000;   //this is in tron decimal / SUN - default 1%
    uint256 public sharesPoolPercentSUN = 1000000;   //this is in tron decimal / SUN - default 1%
    address public sharesPoolAddress;   
    address[] public whitelistCallerArray;
    bool public globalHalt; //when this variabe will be true, it will stop main functionality!
    uint256 private constant tronDecimals = 1e6;
    

    uint256 private confirmedDividendForFreeze;
 
    
    mapping (address => bool) public whitelistCaller;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    mapping(address => uint256) public mainDividendPaid;

    


    //public variables DIV RAKE
    uint256 public dividendPaidLastTimeDivRake = now;
    uint256 public dividendAccumulatedDivRake;
    uint256 public dividendRemainderDivRake;
    
    uint256 public divPaidAllTimeDivRake;
    uint256 public topiaFrozenAtDistributionDivRake;
    uint256 public totalDividendsPaidNumberDivRake;


    mapping (address => uint256) public previousDivAmountWithdrawalDivRake; //keeps track of dividend pool amount for user => token at time of div withdrawal
    mapping(address => uint256) public totalFrozenTopiaTrackerDivRake; //tracks totalFrozen diamonds at the time of user freeze token
    mapping(address => uint256) public noOfDivPaidAfterFreezeDivRake;  //tracks number of dividend distribution attempted after user froze




    //events
    event DividendPaidDivRake(uint256 indexed totalDividend, uint256 indexed payableAmount);
    event UserWithdrawDividend(address indexed user, uint256 availableMainDividend);



    /*========================================
    =       STANDARD DIVIDEND FUNCTIONS       =
    =========================================*/

    /**
        Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    
    
    /**
     * constructor
     */
    constructor() public { }


    /**
        This function only called by token contract.
        This will allows TRX will be sent to token contract for dividend distribution
    */
    function requestDividendPayment(uint256 dividendAmount) public returns(bool) {

        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');
        //dividendPaidAllTime += dividendAmount; //no safemath used as underflow is impossible, and it saves some energy
        msg.sender.transfer(dividendAmount);

        return true;

    }


    /**
        Function allows owner to upate the Topia contract address
    */
    function updateContractAddresses(address _topiaTokenContractAddress, address _refPoolContractAddress, address _leaderBoardContractAddress) public onlyOwner returns(string){
        
        topiaTokenContractAddress = _topiaTokenContractAddress;
        refPoolContractAddress = _refPoolContractAddress;
        leaderBoardContractAddress = _leaderBoardContractAddress;

        return "Topia Token, refPool and leaderBoardPool Contract Addresses Updated";
    }


    /**
        This function will allow signer to request fund from ALL the game contracts
        Game contracts must be whitelisted
    */
    function requestFundFromGameContracts() public onlySigner returns(bool){

        //first finding excesive fund from ALL game contracts
        uint256 totalGameContracts = whitelistCallerArray.length;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableDivRake();
            if(amount > 0){
                //if status is true, which means particular game has positive dividend available
                //we will request that dividend TRX from game contract to this dividend contract
                InterfaceGAMES(whitelistCallerArray[i]).requestDivRakePayment(amount);
                dividendAccumulatedDivRake += amount;
            }
            //else nothing will happen
        }
    }


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistAddress(address _newAddress) public onlyOwner returns(string){
        
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        return "Whitelisting Address added";
    }

    /**
        * To remove any whilisted address
    */
    function removeWhitelistAddress(address _address) public onlyOwner returns(string){
        
        require(_address != address(0), 'Invalid Address');
        require(whitelistCaller[_address], 'This Address does not exist');

        whitelistCaller[_address] = false;
        uint256 arrayIndex = whitelistCallerArrayIndex[_address];
        address lastElement = whitelistCallerArray[whitelistCallerArray.length - 1];
        whitelistCallerArray[arrayIndex] = lastElement;
        whitelistCallerArrayIndex[lastElement] = arrayIndex;
        whitelistCallerArray.length--;

        return "Whitelisting Address removed";
    }


    /**
        Function to change refPool percentage. Amount should be entered in SUN (1e6)
    */
    function updateRefPoolPercent(uint256 _refPoolPercentSUN) public onlyOwner returns(string){
        require(_refPoolPercentSUN < 100000000, 'amount can not be more than 100000000');
        refPoolPercentSUN = _refPoolPercentSUN;
        return ("refPoolPercent updated successfully");
    }
    
    /**
        Function to change leader board pool percentage. Amount should be entered in SUN (1e6)
    */
    function updateLeaderboardPercent(uint256 _leaderBoardPercentSUN) public onlyOwner returns(string){
        require(_leaderBoardPercentSUN < 100000000, 'amount can not be more than 100000000');
        leaderboardsPercentSUN = _leaderBoardPercentSUN;
        return ("leaderboardsPercentSUN updated successfully");
    }
    
    /**
        Function to change shares pool percentage. Amount should be entered in SUN (1e6)
    */
    function updateSharesPoolDetail(uint256 _newPercentSUN, address _newAddress) public onlyOwner returns(string){
        require(_newPercentSUN < 100000000, 'amount can not be more than 100000000');
        sharesPoolPercentSUN = _newPercentSUN;
        sharesPoolAddress = _newAddress;
        return ("leaderboardsPercentSUN updated successfully");
    }
    
    
    


    /*=====================================
    =      CUSTOM DIVIDEND FUNCTIONS      =
    ======================================*/

    
    
    /**
        This function displays all the dividend of all the game contracts
    */
    function displayAvailableDividendALL() public view returns(bool, uint256){
        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableDivRake();
            if(amount > 0){
                totalDividend += amount;
            }
        }

        if(totalDividend > 0){

            uint256 finalAmount = totalDividend + dividendAccumulatedDivRake;
            
            //we deduct 1% of finalAmount from itself for Leaderboard distribution
            uint256 leaderBoardShare = finalAmount * leaderboardsPercentSUN / 100000000;
            //we deduct RefPool share as well
            uint256 refPoolShare = finalAmount * refPoolPercentSUN / 100000000;  //refPoolPercentSUN is in SUN
            // we deduct shares pool %
            uint256 sharesPoolShare = finalAmount * sharesPoolPercentSUN / 100000000;  

            return (true, (finalAmount  - (leaderBoardShare + refPoolShare + sharesPoolShare )));
            
        }
        
    }


    /**
        * This function distributes the main dividend
        * It takes fund dividend fund from all the game contracts
        * And if any game contracts has negative dividend balance, then that would be deducted from the main dividend payout
        * We are also aware that if there would be bug in game contracts, then basically, this function will fail altogether
        * But we can always re-deploy the game contracts fixing any bug and everything would be good :)
    */
    function distributeMainDividend() public  returns(uint256){

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTimeDivRake + 604800 <  now, 'You need to wait 7 days to Do This');
        }
        
        //checking freeze topia for all tiers individually
        (uint256 bronzeTopiaAllUsers, uint256 silverTopiaAllUsers, uint256 goldTopiaAllUsers) = TRONtopiaInterface(topiaTokenContractAddress).totalFrozenTopiaIndividual();

        uint256 totalTopiaFrozen = bronzeTopiaAllUsers + silverTopiaAllUsers + goldTopiaAllUsers;

        require(totalTopiaFrozen > 0, 'No one has frozen anything');

        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableDivRake();
            if(amount > 0){
                //if status is true, which means particular game has positive dividend available
                totalDividend += amount;

                //calculate final amount
                

                //we deduct RefPool share as well - to fix 'stake too deep' warming, we put the value of refPoolShare directly in below equasion
                //uint256 refPoolShare = amount * refPoolPercentSUN / 100000000;  //refPoolPercentSUN is in SUN
                
                //we deduct 1% of finalAmount from itself for Leaderboard distribution plus refPoolShare, which deducted from main amount
                uint256 finalAmount = amount - ((amount * leaderboardsPercentSUN / 100000000) + (amount * sharesPoolPercentSUN / 100000000) + (amount * refPoolPercentSUN / 100000000));
                
                
                
                //now deducting bronze freeze tier difference. 
                uint256 bronzrTierAmount = finalAmount  * 75 / 100 * bronzeTopiaAllUsers / (totalTopiaFrozen);
                //silver tier
                uint256 silverTierAmount = finalAmount  * 85 / 100 * silverTopiaAllUsers / (totalTopiaFrozen);
                //gold tier
                uint256 goldTierAmount = finalAmount  * goldTopiaAllUsers / (totalTopiaFrozen);
                //we will request that dividend TRX from game contract to this token contract
                require(InterfaceGAMES(whitelistCallerArray[i]).requestDivRakePayment(bronzrTierAmount+silverTierAmount+goldTierAmount+((amount * leaderboardsPercentSUN / 100000000) + (amount * sharesPoolPercentSUN / 100000000) + (amount * refPoolPercentSUN / 100000000))), 'could not transfer trx');
                
                
            }

        }

        dividendPaidLastTimeDivRake = now;

        //if total dividend is higher than total reduction amount, then proceed for the div distribution
        uint256 finalDividendAmount;
        if(totalDividend > 0){
            
            //dividendAccumulatedDivRake is the total fund we got from all game contracts, which will be emptied while this div distribution
            finalDividendAmount = totalDividend + dividendAccumulatedDivRake;

            //now lets empty the dividendAccumulatedDivRake
            dividendAccumulatedDivRake = 0;

        }

        else if(dividendAccumulatedDivRake > (totalDividend) ){
            finalDividendAmount = dividendAccumulatedDivRake - (totalDividend);
            dividendAccumulatedDivRake = 0;
        }
        
        if(finalDividendAmount > 0){
            confirmedDividendForFreeze = confirmedDividendForFreeze.add(finalDividendAmount * (100000000 - leaderboardsPercentSUN - refPoolPercentSUN - sharesPoolPercentSUN ) / 100000000); //98% to dividend pool
            //confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard.add(finalDividendAmount * leaderboardsPercentSUN  / 100000000); //1% to leaderboard (king topian and Lord side bet)
            //refPool += finalDividendAmount * refPoolPercentSUN / 100000000;      //1% to refPool. It is in SUN (1e6). It is adjustable by admin

            //transfer the referral and leaderboard pool amount to their contracts.
            //call function usage is safe as recipeint contract is whitelisted by owner only. no reentrency is possible! 
            require( refPoolContractAddress.call.value(finalDividendAmount * refPoolPercentSUN / 100000000).gas(70000)(), 'refPool transfer failed');
            require( leaderBoardContractAddress.call.value(finalDividendAmount * leaderboardsPercentSUN  / 100000000 ).gas(70000)(), 'leaderBoardPool transfer failed');
            sharesPoolAddress.transfer(finalDividendAmount * sharesPoolPercentSUN  / 100000000);
            
            //trackers to determine total dividend share for particular user who frozen topia for specific period of time
            divPaidAllTimeDivRake += finalDividendAmount * (100000000 - leaderboardsPercentSUN - refPoolPercentSUN - sharesPoolPercentSUN ) / 100000000;
            topiaFrozenAtDistributionDivRake += totalTopiaFrozen;
            totalDividendsPaidNumberDivRake++;

            emit DividendPaidDivRake(totalDividend, finalDividendAmount);
            
            return finalDividendAmount;
        }
        //default return zero
    }

 


    /**
        This function is called by only token contract
        It will withdraw any outstanding topia for any user and also updates dividend trackers
    */
    function outstandingDivWithdrawFreeze(address user) public returns(bool){
        
        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');


        //processing divRake outstanding withdraws
        uint256 availableMainDividendDivRake = userConfirmedDividendDivRake(user);
        

        //update divRake div trackers, regardless user has outstanding div or not
        updateDivTrackersDivRake(user);

        if(availableMainDividendDivRake > 0){
            //if user have any outstanding divs, then it will be withdrawn. 
            //so after this freeze, user only can withdraw divs from next subsequent div distributions!
            user.transfer(availableMainDividendDivRake);

            emit UserWithdrawDividend(user,  availableMainDividendDivRake);

        }

        return true;
    } 


    /**
        Function to update dividend trackers variables
    */
    function updateDivTrackers(address user) internal {
        //this will save the mainDiviendPaidAllTime variable, which can be used while calculating div amount at availableMainDividends function
        //this will reset the dividend pool amount in a way that, it will only consider all the div distribution from this point forward :)
        previousDivAmountWithdrawalDivRake[user] =  divPaidAllTimeDivRake;

        //this will track the total frozen topia at the time of freeze
        //which will be used in calculating share percentage of div pool
        totalFrozenTopiaTrackerDivRake[user] = topiaFrozenAtDistributionDivRake;

        //this will track all the dividend distribution attempts.
        noOfDivPaidAfterFreezeDivRake[user] = totalDividendsPaidNumberDivRake;
    }

    /**
        This function is called by only token contract
        It will withdraw any outstanding topia for any user and WILL NOT update dividend trackers
    */
    function outstandingDivWithdrawUnfreeze(address user) public returns(bool){
        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');

        //processing divRake outstanding withdraws
        uint256 availableMainDividendDivRake = userConfirmedDividendDivRake(user);

        if(availableMainDividendDivRake > 0){
            //if user have any outstanding divs, then it will be withdrawn. 
            //so after this freeze, user only can withdraw divs from next subsequent div distributions!
            user.transfer(availableMainDividendDivRake);

            emit UserWithdrawDividend(user,  availableMainDividendDivRake);
        }
        return true;
    }

    /**
        This function is called by only token contract
        It will withdraw any outstanding topia for any user and only updates dividend trackers if there was any outstanding divs
    */
    function outstandingDivWithdrawUpgrade(address user) public returns(bool){
        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');


        //processing divRake outstanding withdraws
        uint256 availableMainDividendDivRake = userConfirmedDividendDivRake(user);
        if(availableMainDividendDivRake > 0){

            //update div rake tracker
            updateDivTrackersDivRake(user);

            //if user have any outstanding divs, then it will be withdrawn. 
            //so after this freeze, user only can withdraw divs from next subsequent div distributions!
            user.transfer(availableMainDividendDivRake);

            emit UserWithdrawDividend(user,  availableMainDividendDivRake);

        }

        return true;
    } 


    /**
        If global halt is off, then this funtion will on it. And vice versa
    */
    function changeGlobalHalt() onlySigner public returns(string) {
        if (globalHalt == false){
            globalHalt = true;
        }
        else{
            globalHalt = false;  
        }
        return "globalHalt status changed";
    }







    /**
     * This function also used to invest any TRX into dividend pool.
     */
    function reInvestDividendRemainderDivRake() public  onlyOwner returns(string){
        
        require(dividendRemainderDivRake > 0, 'Invalid amount');
        require(!globalHalt, 'Global Halt is on');

        dividendAccumulatedDivRake += dividendRemainderDivRake ;
        dividendRemainderDivRake=0;
        return "dividendRemainder is sent to div pool";
    }



    function userConfirmedDividendDivRake(address user) public view returns(uint256){
        //if there are more dividend distribution after user has frozen token
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        uint256 previousDivAmountWithdrawalLocal = previousDivAmountWithdrawalDivRake[user];
        (, uint256 freezeAmount) = TRONtopiaInterface(topiaTokenContractAddress).userFreezeTierAndAmount(user);

        if(divPaidAllTimeDivRake > previousDivAmountWithdrawalLocal && freezeAmount > 0){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            //all three below trackers can never be zero due to above condition
            uint256 newDividendPoolAmount = divPaidAllTimeDivRake - previousDivAmountWithdrawalLocal;
            uint256 totalFrozenTopia = topiaFrozenAtDistributionDivRake - totalFrozenTopiaTrackerDivRake[user];
            uint256 totalNoOfDivPaid = totalDividendsPaidNumberDivRake - noOfDivPaidAfterFreezeDivRake[user];


            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the number 1000000, is to have sharePercentage variable have more decimals.
            //so 1000000 is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
            uint256 sharePercentage = freezeAmount * 100 * 1000000 / (totalFrozenTopia / totalNoOfDivPaid) ;

            
            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(newDividendPoolAmount * sharePercentage > 0){
                
                return newDividendPoolAmount * sharePercentage / 100 / 1000000;
                
            }
            
        }

        //by default it will return zero
    }



    function withdrawDividendDivRake() public returns(bool) {

        //globalHalt will revert this function
        require(!globalHalt, 'Global Halt is on');

        address user = msg.sender;


        //processing divRake dividend
        uint256 availableMainDividend = userConfirmedDividendDivRake(user);
        if(availableMainDividend > 0){

            //update divRake div trackers
            updateDivTrackersDivRake(user);
            
            user.transfer(availableMainDividend);

            emit UserWithdrawDividend(user, availableMainDividend);

            return true;
        }

        // be default return false;

    }


    function updateDivTrackersDivRake(address user) internal{
        //this will save the divPaidAllTimeDivRake variable, which can be used while calculating div amount at userConfirmedDividendDivRake function
        previousDivAmountWithdrawalDivRake[user] =  divPaidAllTimeDivRake;

        //this will track the total frozen topia at the time of freeze
        //which will be used in calculating share percentage of div pool
        totalFrozenTopiaTrackerDivRake[user] = topiaFrozenAtDistributionDivRake;

        //this will track all the dividend distribution attempts, used in calculating share percentage of div pool
        noOfDivPaidAfterFreezeDivRake[user] = totalDividendsPaidNumberDivRake;
    }


    



}