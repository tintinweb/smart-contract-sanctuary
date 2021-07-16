//SourceUnit: sharesDividend.sol

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
                                                                                                       


=== 'Shares' dividend contract with following features ===
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => freeze shares for dividends payments in TRX as well as TRC20 and TRC10 tokens
    => unfreeze anytime.. no unfreeze cooldown time
    

================== Shares Quick Stats ==================
    => Name        : Topia Share
    => Symbol      : TSHARE
    => Max supply  : 1,000,000,000 (1 Billion)
    => Decimals    : 6


============= Independant Audit of the code ============
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


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
//------------------    TRC20 TOKEN CONTRACT INTERFACE    ------------------//
//**************************************************************************//

interface InterfaceTRC20 {

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);

    //custom shares functions
    function frozenSharesGlobal() external returns (uint256);
    function usersShareFrozen(address user) external returns(uint256);

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
        require(msg.sender == owner, 'Caller must be owner');
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer, 'Caller must be signer');
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

    

    
//****************************************************************************//
//-------------------    SHARES DIVIDEND CODE STARTS HERE  -------------------//
//****************************************************************************//
    
contract SharesDividend is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;

    bool public globalHalt; //when this variabe will be true, then  it will stop minting, which also stops game contracts!
    address public sharesContractAddress;

    uint256 public sharesFrozenAtDivDistribution; //this tracks current total frozen topia when dividend is distributed 
    uint256 public totalDividendsPaidNumber;      //total number of dividends distributed. Mainly used with topiaFrozenAtDivDistribution
    uint256 public dividendPaidLastTime;


    // This creates a mapping with all data storage
  
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;

    mapping (uint256 => bool) public whitelistCallerTRC10;
    uint256[] public whitelistCallerArrayTRC10;
    mapping (uint256 => uint256) internal whitelistCallerArrayIndexTRC10;

    
    mapping (address => mapping(address => uint256)) public previousDivAmountWithdrawalTRC20; //keeps track of dividend pool amount for user => token at time of div withdrawal
    mapping (address => mapping(uint256 => uint256)) public previousDivAmountWithdrawalTRC10; //keeps track of dividend pool amount for user => token at time of div withdrawal
    mapping(address => uint256) public totalFrozenSharesTracker; //tracks totalFrozenShares at the time of user freeze topia
    mapping(address => uint256) public noOfDivPaidAfterFreeze;  //tracks number of dividend distribution attempted after user froze

    mapping(uint256 => uint256) public divPaidAllTimeTrxAndTrc10;  //tracks total number of div paid in trx and trc10
    mapping(address => uint256) public divPaidAllTimeTRC20;  //tracks total number of div paid in trc20
    
        

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/
    
    //DividendPaid by admin
    event DividendPaidTRX(uint256 indexed totalDividendPaidTRX);
    event DividendPaidTRC10(uint256 indexed tokenID, uint256 indexed totalDividendPaidTRC10);
    event DividendPaidTRC20(address indexed tokenContractAddress, uint256 indexed totalDividendPaidTRC20);
    
    
    //user withdraw dividend
    event DividendWithdrawTRC20(address indexed user, address indexed tokenAddress, uint256 indexed amount);
    event DividendWithdrawTRXandTRC10(address indexed user, uint256 indexed tokenID, uint256 indexed amount);
    


   

    /*=======================================
    =       CUSTOM DIVIDEND FUNCTIONS       =
    ========================================*/

    /**
        Constructor function. nothing happens
    */
    constructor() public {
        
        //dividendPaidLastTime is set to deploy time as first dividend paid, so it works properly in distribute function
        dividendPaidLastTime = now;

        //adding TRX as zero index in the array. so that it does not need to be added. but it present by default
        whitelistCallerTRC10[0] = true;
        whitelistCallerArrayTRC10.push(0);
        whitelistCallerArrayIndexTRC10[0] = 0;

        //doing initial div distribution variable
        divPaidAllTimeTrxAndTrc10[0] = 1;

    }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    



    
    function distributeDividendTRX() public payable onlySigner returns(bool){

        uint256 frozenSharesGlobal = InterfaceTRC20(sharesContractAddress).frozenSharesGlobal();
        uint256 dividedAmount = msg.value;


        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }        
        require(dividedAmount > 0, 'Not enough TRX provided');
        require(frozenSharesGlobal > 0, 'No one has frozen the shares');
        

        //trackers to determine total dividend share for particular user who frozen topia for specific period of time
        divPaidAllTimeTrxAndTrc10[0] += dividedAmount;  // 0 = TRX and Non-zero integer = TRC10 token ID
        sharesFrozenAtDivDistribution += frozenSharesGlobal;
        totalDividendsPaidNumber++;   
        
        dividendPaidLastTime = now;
        
        emit DividendPaidTRX(dividedAmount);
        
        return true;
    }
    
    
    function distributeDividendTRC20(address tokenAddress, uint256 dividedAmount) public onlySigner returns(bool){

        uint256 frozenSharesGlobal = InterfaceTRC20(sharesContractAddress).frozenSharesGlobal();

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }
        
        require(InterfaceTRC20(tokenAddress).transferFrom(owner, address(this), dividedAmount), 'could not transfer tokens');
        require(whitelistCaller[tokenAddress], 'Please add trc20 token contract address first');
        require(dividedAmount > 0, 'dividedAmount cant be zero');
        require(frozenSharesGlobal > 0, 'No one has frozen the shares');
        
        //trackers to determine total dividend share for particular user who frozen topia for specific period of time
        divPaidAllTimeTRC20[tokenAddress] += dividedAmount;  
        sharesFrozenAtDivDistribution += frozenSharesGlobal;
        totalDividendsPaidNumber++;   
        
        dividendPaidLastTime = now;
        
        emit DividendPaidTRC20(tokenAddress, dividedAmount);
        
        return true;
    }

    
    function distributeDividendTRC10() public payable onlySigner returns(bool){

        uint256 frozenSharesGlobal = InterfaceTRC20(sharesContractAddress).frozenSharesGlobal();
        uint256 tokenID = msg.tokenid;
        uint256 dividedAmount = msg.tokenvalue;

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }
        require(dividedAmount > 0, 'Not enough TRX provided');
        require(whitelistCallerTRC10[tokenID], 'Please add trc10 token first');
        require(frozenSharesGlobal > 0, 'No one has frozen the shares');
        
        //trackers to determine total dividend share for particular user who frozen topia for specific period of time
        divPaidAllTimeTrxAndTrc10[tokenID] += dividedAmount;  // 0 = TRX and Non-zero integer = TRC10 token ID
        sharesFrozenAtDivDistribution += frozenSharesGlobal;
        totalDividendsPaidNumber++;   
        
        dividendPaidLastTime = now;
        
        emit DividendPaidTRC10(tokenID, dividedAmount);
        
        return true;
    }

    /**
        tokenID = 0  means TRX
        tokenID = non-zero means TRC10 token
    */
    function userConfirmedDividendTRXandTRC10(address user, uint256 tokenID) public view returns(uint256){

        uint256 usersShareFrozen = InterfaceTRC20(sharesContractAddress).usersShareFrozen(user);

        //if there are more dividend distribution after user has frozen topia
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        uint256 previousDivAmountWithdrawal = previousDivAmountWithdrawalTRC10[user][tokenID];
        if(divPaidAllTimeTrxAndTrc10[tokenID] > previousDivAmountWithdrawal && usersShareFrozen > 0){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            //all three below trackers can never be zero due to above condition
            uint256 newDividendPoolAmount = divPaidAllTimeTrxAndTrc10[tokenID] - previousDivAmountWithdrawal;
            uint256 totalFrozenShares = sharesFrozenAtDivDistribution - totalFrozenSharesTracker[user];
            uint256 totalNoOfDivPaid = totalDividendsPaidNumber - noOfDivPaidAfterFreeze[user];

            
            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the decimals variable is to have sharePercentage variable have more decimals.
            //so decimals is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
            uint256 sharePercentage = usersShareFrozen * 100 * 1000000 / (totalFrozenShares / totalNoOfDivPaid) ;

            
            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(newDividendPoolAmount * sharePercentage > 0){
                
                return newDividendPoolAmount * sharePercentage / 100 / 1000000;                
                
            }
            
        }

        //by default it will return zero
    }


    function userConfirmedDividendTRC20(address user, address tokenAddress) public view returns(uint256){

        uint256 usersShareFrozen = InterfaceTRC20(sharesContractAddress).usersShareFrozen(user);

        //if there are more dividend distribution after user has frozen topia
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        uint256 previousDivAmountWithdrawal = previousDivAmountWithdrawalTRC20[user][tokenAddress];
        if(divPaidAllTimeTRC20[tokenAddress] > previousDivAmountWithdrawal && usersShareFrozen > 0){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            //all three below trackers can never be zero due to above condition
            uint256 newDividendPoolAmount = divPaidAllTimeTRC20[tokenAddress] - previousDivAmountWithdrawal;
            uint256 totalFrozenShares = sharesFrozenAtDivDistribution - totalFrozenSharesTracker[user];
            uint256 totalNoOfDivPaid = totalDividendsPaidNumber - noOfDivPaidAfterFreeze[user];

            
            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the decimals variable is to have sharePercentage variable have more decimals.
            //so decimals is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
            uint256 sharePercentage = usersShareFrozen * 100 * 1000000 / (totalFrozenShares / totalNoOfDivPaid) ;
            

            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(newDividendPoolAmount * sharePercentage > 0){

                return newDividendPoolAmount * sharePercentage / 100 / 1000000;
            }
            
        }

        //by default it will return zero
    }


    /**
        This function will withdraw dividends in TRX, TRC10 and TRC20
        divTracker variable means whether to update the dividend trackers or not, 
        as freeze share function will require update and unfreeze requires withdraw without updating dividend trackers
    */
    function withdrawDividendsEverythingInternal(address user) internal returns(bool){

        //this will halt all withdrawals and thus it will also halt freeze/unfreeze shares in share contract as well
        require(!globalHalt, 'Global halt is on');

        // TRC10 withdraw. we will loop through all those tokens
        uint256 totalTokensTRC10 = whitelistCallerArrayTRC10.length;
        //excluding 0 index for TRX, so we dont have to check for it in every loop iteration
        for(uint256 i=1; i < totalTokensTRC10; i++){
            uint256 tokenID = whitelistCallerArrayTRC10[i];
            uint256 outstandingDiv = userConfirmedDividendTRXandTRC10(user, tokenID);
            if(outstandingDiv > 0){
                user.transferToken(outstandingDiv, tokenID);
                emit DividendWithdrawTRXandTRC10(user, tokenID, outstandingDiv);
            }
        }
    

        //TRX withdraw
        uint256 outstandingDivTRX = userConfirmedDividendTRXandTRC10(user, 0);
        if(outstandingDivTRX > 0){
            user.transfer(outstandingDivTRX);
            emit DividendWithdrawTRXandTRC10(user, 0, outstandingDivTRX);
        }

        //TRC20 withdraw
        uint256 totalTokensTRC20 = whitelistCallerArray.length;
        for(i=0; i < totalTokensTRC20; i++){
            address tokenAddress = whitelistCallerArray[i];
            uint256 outstandingDivTRC20 = userConfirmedDividendTRC20(user, tokenAddress);
            if(outstandingDivTRC20 > 0){
                InterfaceTRC20(tokenAddress).transfer(user, outstandingDivTRC20);
                emit DividendWithdrawTRC20(user, tokenAddress, outstandingDivTRC20);
            }
        }

        return true;
    }


    /**
        This function can be called by user directly or via any other contract
        It will withdraw any outstanding topia for any user and ALSO UPDATES dividend trackers
    */
    function withdrawDividendsEverything() public returns(bool){
        
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //second param as true, meaning it will update the dividend tracker
        require(withdrawDividendsEverythingInternal(user), 'withdraw dividend everything function did not work');


        //this will track the total frozen topia at the time of freeze
        //which will be used in calculating share percentage of div pool
        totalFrozenSharesTracker[user] = sharesFrozenAtDivDistribution;

        //this will track all the dividend distribution attempts.
        noOfDivPaidAfterFreeze[user] = totalDividendsPaidNumber;

        //following will set value for each tokens and TRX at time of this action
        uint256 totalTokensTRC10 = whitelistCallerArrayTRC10.length;
        //excluding 0 index for TRX, so we dont have to check for it in every loop iteration
        for(uint256 i=1; i < totalTokensTRC10; i++){
            uint256 tokenID = whitelistCallerArrayTRC10[i];
            previousDivAmountWithdrawalTRC10[user][tokenID] = divPaidAllTimeTrxAndTrc10[tokenID];
        }
        //TRX withdraw
        previousDivAmountWithdrawalTRC10[user][0] = divPaidAllTimeTrxAndTrc10[0];
        //TRC20 withdraw
        uint256 totalTokensTRC20 = whitelistCallerArray.length;
        for(i=0; i < totalTokensTRC20; i++){
            address tokenAddress = whitelistCallerArray[i];
            previousDivAmountWithdrawalTRC20[user][tokenAddress] = divPaidAllTimeTRC20[tokenAddress];
        }

        return true;
    } 


    /**
        This function can be called by user directly or via any other contract
        It will withdraw any outstanding topia for any user and DOES NOT UPDATES dividend trackers
    */
    function outstandingDivWithdrawUnFreeze() public returns(bool){
        
        require(msg.sender == sharesContractAddress, 'unauthorised caller');

        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //second param as false, meaning it will NOT update the dividend tracker
        require(withdrawDividendsEverythingInternal(user), 'withdraw dividend everything function did not work');

        return true;
    } 


    function withdrawDividendTRXonly() public returns(bool){
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //this will halt all withdrawals 
        require(!globalHalt, 'Global halt is on');

        //TRX withdraw
        uint256 outstandingDivTRX = userConfirmedDividendTRXandTRC10(user, 0);
        if(outstandingDivTRX > 0){
            //update div trackers
            previousDivAmountWithdrawalTRC10[user][0] = divPaidAllTimeTrxAndTrc10[0];
            //this will track the total frozen topia at the time of freeze
            //which will be used in calculating share percentage of div pool
            totalFrozenSharesTracker[user] = sharesFrozenAtDivDistribution;
            //this will track all the dividend distribution attempts.
            noOfDivPaidAfterFreeze[user] = totalDividendsPaidNumber;

            //tranfer TRX
            user.transfer(outstandingDivTRX);

            emit DividendWithdrawTRXandTRC10(user, 0, outstandingDivTRX);
        }

        return true;
    }


    function withdrawDividendTRC10only(uint256 tokenID) public returns(bool){
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //this will halt all withdrawals 
        require(!globalHalt, 'Global halt is on');

        
        uint256 outstandingDiv  = userConfirmedDividendTRXandTRC10(user, tokenID);
        if(outstandingDiv > 0){

            //updating trackers
            previousDivAmountWithdrawalTRC10[user][tokenID] = divPaidAllTimeTrxAndTrc10[tokenID];
            //this will track the total frozen topia at the time of freeze
            //which will be used in calculating share percentage of div pool
            totalFrozenSharesTracker[user] = sharesFrozenAtDivDistribution;
            //this will track all the dividend distribution attempts.
            noOfDivPaidAfterFreeze[user] = totalDividendsPaidNumber;

            //transfer tokens
            user.transferToken(outstandingDiv, tokenID);
            emit DividendWithdrawTRXandTRC10(user, tokenID, outstandingDiv);
        }
        
        return true;
    }


    function withdrawDividendTRC20only(address tokenAddress) public returns(bool){
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;

        //this will halt all withdrawals 
        require(!globalHalt, 'Global halt is on');

        
        uint256 outstandingDivTRC20  = userConfirmedDividendTRC20(user, tokenAddress);
        if(outstandingDivTRC20 > 0){

            //update div tracker
            previousDivAmountWithdrawalTRC20[user][tokenAddress] = divPaidAllTimeTRC20[tokenAddress];
            //this will track the total frozen topia at the time of freeze
            //which will be used in calculating share percentage of div pool
            totalFrozenSharesTracker[user] = sharesFrozenAtDivDistribution;
            //this will track all the dividend distribution attempts.
            noOfDivPaidAfterFreeze[user] = totalDividendsPaidNumber;

            //transfer the tokens
            InterfaceTRC20(tokenAddress).transfer(user, outstandingDivTRC20);
            emit DividendWithdrawTRC20(user, tokenAddress, outstandingDivTRC20);
                        
        }
        
        return true;
    }
    


    /*=====================================
    =          HELPER FUNCTIONS           =
    ======================================*/

    /**
        Update sharesContractAddress
    */
    function updateSharesContractAddress(address _sharesContractAddress) public onlyOwner returns(string){
        sharesContractAddress = _sharesContractAddress;
        return "Shares Contract Address updated successfully";
    }


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addTokenTRC20(address _newAddress) public onlyOwner returns(string){
        
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        //Do fake first dividend distribution. This variable needed non-zero to get proper result in getting confirmed div of user.
        divPaidAllTimeTRC20[_newAddress] = 1;  


        return "TRC20 Token Added Successfully";
    }

    /**
        * To remove any whilisted address
    */
    function removeTokenTRC20(address _address) public onlyOwner returns(string){
        
        require(_address != address(0), 'Invalid Address');
        require(whitelistCaller[_address], 'This Address does not exist');

        whitelistCaller[_address] = false;
        uint256 arrayIndex = whitelistCallerArrayIndex[_address];
        address lastElement = whitelistCallerArray[whitelistCallerArray.length - 1];
        whitelistCallerArray[arrayIndex] = lastElement;
        whitelistCallerArrayIndex[lastElement] = arrayIndex;
        whitelistCallerArray.length--;

        return "TRC20 Token Removed Successfully";
    }


    function addTokenTRC10(uint256 _tokenID) public onlyOwner returns(string){
        
        require(!whitelistCallerTRC10[_tokenID], 'No same token ID again');

        whitelistCallerTRC10[_tokenID] = true;
        whitelistCallerArrayTRC10.push(_tokenID);
        whitelistCallerArrayIndexTRC10[_tokenID] = whitelistCallerArrayTRC10.length - 1;

        //Do fake first dividend distribution. This variable needed non-zero to get proper result in getting confirmed div of user.
        divPaidAllTimeTrxAndTrc10[_tokenID] = 1;

        return "TRC10 Token Added Successfully";
    }


    function removeTokenTRC10(uint256 _tokenID) public onlyOwner returns(string){
        
        require(whitelistCallerTRC10[_tokenID], 'This tokenID does not exist');

        whitelistCallerTRC10[_tokenID] = false;
        uint256 arrayIndex = whitelistCallerArrayIndexTRC10[_tokenID];
        uint256 lastElement = whitelistCallerArrayTRC10[whitelistCallerArrayTRC10.length - 1];
        whitelistCallerArrayTRC10[arrayIndex] = lastElement;
        whitelistCallerArrayIndexTRC10[lastElement] = arrayIndex;
        whitelistCallerArrayTRC10.length--;

        return "TRC10 Token Removed Successfully";
    }
    

    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawTRC20Tokens(address tokenAddress, uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        InterfaceTRC20(tokenAddress).transfer(owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    function manualWithdrawTRC10Tokens(uint256 tokenID, uint256 tokenAmount) public onlyOwner returns(string){
        owner.transferToken(tokenAmount, tokenID);
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
    
    
    
    /*********************************/
    /*    Code for the Air drop      */
    /*********************************/
    
    /**
        * Run an Air-Drop
        *
        * It requires an array of all the addresses and amount of tokens to distribute
        * It will only process first 150 recipients. That limit is fixed to prevent gas limit
        */
    function airdrop(address[] recipients, uint[] tokenAmount) public onlySigner returns(string, uint256, address) {
        uint256 addressCount = recipients.length;
        require(addressCount == tokenAmount.length, 'both arrays must have equal length');
        for(uint i = 0; i < addressCount; i++)
        {
        
        if (gasleft() < 100000)
            {
                break;
            }
            
                //This will loop through all the recipients and send them the specified tokens
                InterfaceTRC20(sharesContractAddress).transfer(recipients[i], tokenAmount[i]);
        }

        return ("successful entries processed upto: ", i, recipients[i]);
    }


 


}