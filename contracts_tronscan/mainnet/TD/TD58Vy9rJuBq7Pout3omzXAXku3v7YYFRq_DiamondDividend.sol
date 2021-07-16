//SourceUnit: diamondDividend.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_ 




████████╗ ██████╗ ██████╗ ██╗ █████╗     ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
   ██║   ██║   ██║██████╔╝██║███████║    ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
   ██║   ██║   ██║██╔═══╝ ██║██╔══██║    ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
   ██║   ╚██████╔╝██║     ██║██║  ██║    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
                                                                                                       


=== 'Diamond Dividend' contract with following features ===
    => Higher degree of control by owner
    => All frozen diamonds will get dividend
    => SafeMath implementation 



-------------------------------------------------------------------
 Copyright (c) 2019 onwards Topia Network Inc. ( https://topia.network )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
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
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}



//**************************************************************************//
//---------------------    GAMES CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceGAMES {
    function getAvailableDiamondRake() external returns (uint256);
    function requestDiamondRakePayment() external returns(bool);
} 


//**************************************************************************//
//---------------------  DIAMOND CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceDIAMOND {
    function frozenDiamondsGlobal() external returns (uint256);
    function usersDiamondFrozen(address user) external returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    function frozenAccount(address user) external returns(bool);
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
        require(msg.sender == owner, 'caller must be owner');
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
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
        require(msg.sender == newOwner, 'caller must be new owner');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

    

    
//********************************************************************************//
//---------------------    DIAMOND DIVIDEND CODE STARTS HERE  --------------------//
//********************************************************************************//
    
contract DiamondDividend is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    
    address public voucherContractAddress;
    address public diamondContractAddress;
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!

    uint256 public dividendAccumulated;
    uint256 public dividendRemainder;
    uint256 public divPercentageSUN = 100000000;  //100% of dividend distributed 
    uint256 public diamondsFrozenAtDivDistribution; //this tracks current total frozen token when dividend is distributed 
    uint256 public totalDividendsPaidNumber;    //total number of dividends distributed. Mainly used with diamondsFrozenAtDivDistribution
    uint256 public dividendPaidLastTime;
    uint256 public divPaidAllTimeTrx;  //tracks total number of div paid in trx
    uint256 public blacklistedDiamondAtDivDistribution; //incremental value of globalBlacklistedDiamonds at div distribution



    // This creates a mapping with all data storage
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;

    //dividend trackers    
    mapping (address => uint256) public previousDivAmountWithdrawal;    //keeps track of dividend pool amount for user => token at time of div withdrawal
    mapping(address => uint256) public totalFrozenDiamondTracker;       //tracks totalFrozen diamonds at the time of user freeze token
    mapping(address => uint256) public noOfDivPaidAfterFreeze;          //tracks number of dividend distribution attempted after user froze
    mapping(address => uint256) public blacklistedDiamondTracker;       //tracks blacklisted diamond frozen incremental.
 
    mapping(address => uint256) public blacklistedDiamondIndividual; 
    uint256 public globalBlacklistedDiamonds;    
    mapping (address => bool) public frozenAccount;
    

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    
    //DividendPaid by admin
    event DividendPaidTRX(uint256 indexed totalDividendPaidTRX);

    //user withdraw dividend
    event DividendWithdrawTRX(address indexed user, uint256 indexed tokenID, uint256 indexed amount);

     // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address indexed target, bool frozen, uint256 frozenDiamonds);
   

    
    
    /*=====================================
    =      CUSTOM DIVIDEND FUNCTIONS      =
    ======================================*/


    /**
        Constructor function. nothing happens
    */
    constructor() public {
        
        //dividendPaidLastTime is set to deploy time as first dividend paid, so it works properly in distribute function
        dividendPaidLastTime = now;


    }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}

     /**
        This function displays all the dividend of all the game contracts
    */
    function getDividendPotential() public view returns(uint256){

        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableDiamondRake();
            if(amount > 0){
                totalDividend += amount;
            }
        }

        if(totalDividend > 0 || dividendAccumulated > 0 ){
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            uint256 newAmount = totalDividend * divPercentageSUN / 100 / 1000000; 

            return newAmount + dividendAccumulated;
            
        }
        
        //by default it returns zero
        
    }
    

    function distributeMainDividend() public  onlySigner returns(string, uint256, uint256, uint256){
        
        uint256 frozenDiamondsGlobal = InterfaceDIAMOND(diamondContractAddress).frozenDiamondsGlobal();

        require(frozenDiamondsGlobal > 0, 'none has frozen diamonds');
        require(!globalHalt, 'Global Halt is on');

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }


        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            address gameAddress = whitelistCallerArray[i];
            uint256 amount = InterfaceGAMES(gameAddress).getAvailableDiamondRake();
            if(amount > 0){
                //if status is true, which means particular game has positive dividend available
                totalDividend += amount;

                //we will request that dividend TRX from game contract to this token contract
                require(InterfaceGAMES(gameAddress).requestDiamondRakePayment(), 'could not transfer trx');
            }
        }

        uint256 dividendAccumulatedLocal = dividendAccumulated;
        if(totalDividend > 0 || dividendAccumulatedLocal > 0 ){            
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            uint256 newAmount =  totalDividend * divPercentageSUN / 100 / 1000000; 
            
            //if dividend % is less than 100%, then track that remainder in another variable
            if(divPercentageSUN < 100000000){
                dividendRemainder +=  totalDividend * (100000000 - divPercentageSUN) / 100 / 1000000;
            }

            uint256 payableAmount = newAmount + dividendAccumulatedLocal;


            //trackers to determine total dividend share for particular user who frozen token for specific period of time
            divPaidAllTimeTrx += payableAmount;  
            diamondsFrozenAtDivDistribution += frozenDiamondsGlobal;
            totalDividendsPaidNumber++;   
            blacklistedDiamondAtDivDistribution += globalBlacklistedDiamonds;
            
            dividendPaidLastTime = now;
            dividendAccumulated = 0;
            
            emit DividendPaidTRX(payableAmount);
            
            return ("Distro Success: (1) Total Fetched (2) Accumulated Dividend (3) Final Payable amount:", totalDividend, dividendAccumulatedLocal, payableAmount );

        }

        
    }

    /**
     * This function also used to invest any TRX into dividend pool.
     */
    function reInvestDividendRemainder() public payable onlyOwner returns(string){
        
        require(dividendRemainder > 0 || msg.value > 0, 'Invalid amount');
        require(!globalHalt, 'Global Halt is on');

        dividendAccumulated += dividendRemainder + msg.value;
        dividendRemainder=0;
        return "dividendRemainder is sent to div pool";
    }
    
    

    /**
        users can see how much dividend is confirmed available to him to withdraw
    */
    function userConfirmedDividendTRX(address user) public view returns(uint256){
        if( ! InterfaceDIAMOND(diamondContractAddress).frozenAccount(user) )
        {
            //if there are more dividend distribution after user has frozen token
            //user is eligible to receive more dividends from all the distributions done after his last withdrawal
            uint256 previousDivAmountWithdrawalLocal = previousDivAmountWithdrawal[user];
            uint256 usersDiamondFrozen = InterfaceDIAMOND(diamondContractAddress).usersDiamondFrozen(user);

            if(divPaidAllTimeTrx > previousDivAmountWithdrawalLocal && usersDiamondFrozen > 0){

                //finding all the subsequent dividends distributed by admin
                //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
                //all three below trackers can never be zero due to above condition
                uint256 blacklistedDiamonds = blacklistedDiamondAtDivDistribution - blacklistedDiamondTracker[user];
                uint256 newDividendPoolAmount = divPaidAllTimeTrx - previousDivAmountWithdrawalLocal;
                uint256 totalFrozenShares = diamondsFrozenAtDivDistribution - totalFrozenDiamondTracker[user];
                uint256 totalNoOfDivPaid = totalDividendsPaidNumber - noOfDivPaidAfterFreeze[user];
                


                //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
                //the reason for the number 1000000, is to have sharePercentage variable have more decimals.
                //so 1000000 is multiplied in sharePercentage,which was then divided in total amount in below equasion.
                //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
                uint256 sharePercentage = usersDiamondFrozen * 100 * 1000000 / (totalFrozenShares / totalNoOfDivPaid) ;
                sharePercentage += sharePercentage * (blacklistedDiamonds * 1000000 / usersDiamondFrozen) / 1000000;

                //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
                if(newDividendPoolAmount * sharePercentage > 0){
                    
                    return newDividendPoolAmount * sharePercentage / 100 / 1000000;

                }

            }
        }
        else
        {
            return 0;
        }
        //by default it will return zero
    }



    /**
        This function will withdraw dividends in TRX
        divTracker variable means whether to update the dividend trackers or not, 
        as freeze token function will require update and unfreeze requires withdraw without updating dividend trackers
    */
    function withdrawDividendsEverythingInternal(address user) internal returns(bool){

        //TRX withdraw
        uint256 outstandingDivTRX = userConfirmedDividendTRX(user);
        if(outstandingDivTRX > 0){
            user.transfer(outstandingDivTRX);
            emit DividendWithdrawTRX(user, 0, outstandingDivTRX);
        }

        return true;
    }


    /**
        This function can be called by user directly or via any other contract
        It will withdraw any outstanding token for any user and ALSO UPDATES dividend trackers
    */
    function withdrawDividendsEverything() public returns(bool){
        require(! InterfaceDIAMOND(diamondContractAddress).frozenAccount(user),"you are blacklisted" );


        require(!globalHalt, 'Global Halt is on');
        
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //second param as true, meaning it will update the dividend tracker
        require(withdrawDividendsEverythingInternal(user), 'withdraw dividend everything function did not work');


        //this will track the total frozen token at the time of freeze
        //which will be used in calculating share percentage of div pool
        totalFrozenDiamondTracker[user] = diamondsFrozenAtDivDistribution;

        //this will track all the dividend distribution attempts.
        noOfDivPaidAfterFreeze[user] = totalDividendsPaidNumber;

        //TRX withdraw
        previousDivAmountWithdrawal[user] = divPaidAllTimeTrx;
        
        //updates the value of globalBlacklistedDiamonds when this action
        blacklistedDiamondTracker[user] = globalBlacklistedDiamonds;
    

        return true;
    } 


 




    /*=====================================
    =          HELPER FUNCTIONS           =
    ======================================*/

    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistGameAddress(address _newAddress) public onlyOwner returns(string){
        
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        return "Whitelisting Address added";
    }

    /**
        * To remove any whilisted address
    */
    function removeWhitelistGameAddress(address _address) public onlyOwner returns(string){
        
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



    function updateContractAddresses(address _voucherContract, address _diamondContract) public onlyOwner returns(string){
        voucherContractAddress = _voucherContract;
        diamondContractAddress = _diamondContract;
        return "voucher and diamond conract address updated successfully";
    }



        
    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawTokens(address token, uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        InterfaceDIAMOND(token).transfer(owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }




    function manualWithdrawTRX(uint256 amount) public onlyOwner returns(string){
        owner.transfer(amount);
        return "TRX withdrawn to owner wallet";
    }

    

    /**
        * If global halt is off, then this funtion will on it. And vice versa
        * This also change safeguard for token movement status
    */
    function changeGlobalHalt() onlyOwner public returns(string) {
        if (globalHalt == false){
            globalHalt = true;
        }
        else{
            globalHalt = false;  
        }
        return "globalHalt status changed";
    }

    

    /**
        * Function to check TRX balance in this contract
    */
    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }
    
    function freezeUnfreezeAccount(address userAddress) onlyOwner public returns (string) 
    {
        bool freeze = InterfaceDIAMOND(diamondContractAddress).frozenAccount(userAddress);      
        uint256 frozenDiamonds = InterfaceDIAMOND(diamondContractAddress).usersDiamondFrozen(userAddress);
        
        if (freeze && !frozenAccount[userAddress] )
        {
            
            blacklistedDiamondIndividual[userAddress] = frozenDiamonds;
            globalBlacklistedDiamonds += frozenDiamonds;
            frozenAccount[userAddress] = true;
            emit  FrozenAccounts(userAddress, freeze , frozenDiamonds);
            return "Accounts frozen successfully";
        }
        else if (!freeze && frozenAccount[userAddress] )
        {
            blacklistedDiamondIndividual[userAddress] = 0;
            globalBlacklistedDiamonds -= frozenDiamonds;
            frozenAccount[userAddress] = false;
            emit  FrozenAccounts(userAddress, freeze, frozenDiamonds);
            return "Accounts un-frozen successfully";
        }
        
        return "Nothing happened as either duplicate transaction or conditions dont met";
    }
 

 
}