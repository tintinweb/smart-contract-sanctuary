//SourceUnit: voucherDividend.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_ 



████████╗██████╗  ██████╗ ███╗   ██╗    ████████╗ ██████╗ ██████╗ ██╗ █████╗ 
╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
   ██║   ██████╔╝██║   ██║██╔██╗ ██║       ██║   ██║   ██║██████╔╝██║███████║
   ██║   ██╔══██╗██║   ██║██║╚██╗██║       ██║   ██║   ██║██╔═══╝ ██║██╔══██║
   ██║   ██║  ██║╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝██║     ██║██║  ██║
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
                                                                             


=== 'Voucher Dividend' contract with following features ===
    => TRX and TRC20 tokens dividend distributions
    => works with voucher token contract
    


-------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority ( https://EtherAuthority.io )
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
    function getAvailableVoucherRake() external returns (uint256);
    function requestVoucherRakePayment() external returns(bool);
} 

//**************************************************************************//
//------------------  VOUCHER TOKEN CONTRACT INTERFACE    ------------------//
//**************************************************************************//

interface InterfaceVoucherTOKEN {
    
    //trc20 token contract functions
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function transfer(address to, uint256 amount) external returns(bool);
    function totalSupply() external returns(uint256);
    
    
    //custom voucher token contract functions
    function changeMintingBasePriceWhileDivDistro() external returns (bool);
    function usersVoucherBurnedAmount(address user,uint256 mintShareStatus) external view returns(uint256);
    function totalBurnIn(uint256 status) external view returns(uint256);
    
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

    

    
//****************************************************************************//
//---------------------   VOUCHER MAIN CODE STARTS HERE  ---------------------//
//****************************************************************************//
    
contract VoucherDividend is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    
    
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!
    address public voucherTokenContract;


    uint256 public dividendAccumulated;
    uint256 public divPercentageSUN = 100000000;  //100% of dividend distributed 
    uint256 public dividendRemainder;
    uint256 public lastDividendPaidTime;

    // This creates a mapping with all data storage
    
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    
    
    //Dividend Tracker variables
    mapping (address => uint256) public divPaidAllTime;  //token address => amount. And address 0x0 for TRX
    uint256 public voucherBurnedAtDivDistribution;
    uint256 public totalDividendsPaidNumber; 
    
    mapping (address => uint256) public totalburnedVouchersTracker; //maps to user address => tracking of voucherBurnedAtDivDistribution at voucher burned 
    mapping (address => uint256) public noOfDivPaidAfterBurn;       //maps to user address => tracking of totalDividendsPaidNumber while vouchers burn
    mapping (address => uint256) public divPaidAllTimeUsersTRX;     //maps to user address => trx amount
    mapping (address => mapping(address => uint256)) public divPaidAllTimeUsersTRC20;   //maps to user address => token address => token amount

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    
    //user withdraw dividend TRX
    event DividendWithdrawTRX(address indexed user, uint256 indexed dividendAmountTRX);
    
    //user withdraw TRC20
    event DividendWithdrawTRC20(address user, address tokenAddress, uint256 dividendAmountTRC20);
    
    //DividendPaid by admin in TRX
    event DividendPaidTRX(uint256 indexed amount);
    
    //DividendPaid by admin in TRC20
    event DividendPaidTRC20(address tokenAddress, uint256 indexed amount);




    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    /**
        Constructor function. nothing happens
    */
    constructor() public { }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    function distributeDividendTRX() public  returns(uint256){
        
        uint256 vouchersBurnedTotal = InterfaceVoucherTOKEN(voucherTokenContract).totalBurnIn(0);
        
        require(vouchersBurnedTotal > 0, 'none has burned the vouchers');

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(lastDividendPaidTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }
        
        //calling voucher token contract to update mintingBasePricing
        InterfaceVoucherTOKEN(voucherTokenContract).changeMintingBasePriceWhileDivDistro();

        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            address gameAddress = whitelistCallerArray[i];
            uint256 amount = InterfaceGAMES(gameAddress).getAvailableVoucherRake();
            if(amount > 0){
                //if status is true, which means particular game has positive dividend available
                totalDividend += amount;

                //we will request that dividend TRX from game contract to this token contract
                require(InterfaceGAMES(gameAddress).requestVoucherRakePayment(), 'could not transfer trx');
            }
        }

        lastDividendPaidTime = now;

        if(totalDividend > 0){
            
            //dividendAccumulated is the total fund we got from all game contracts, which will be emptied while this div distribution
            uint256 finalDividendAmount = totalDividend + dividendAccumulated;
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            uint256 payableAmount =  finalDividendAmount * divPercentageSUN / 100 / 1000000; 
            
            //if dividend % is less than 100%, then track that remainder in another variable
            if(divPercentageSUN < 100000000){
                dividendRemainder +=  finalDividendAmount * (100000000 - divPercentageSUN) / 100 / 1000000;
            }

            //update variables
            dividendAccumulated = 0;
            
            
            //update dividend trackers
            dividendTrackerWhileDistribution(address(0), payableAmount, vouchersBurnedTotal);
            
            emit DividendPaidTRX(payableAmount);
            
            return payableAmount;

        }
  
    }
    
    
    function distributeDividendTRC20(address tokenAddress, uint256 dividedAmount) public onlySigner returns(bool){
        
        //distributing trc20 will consider both burned tokens as well as total supply exist
        uint256 currentVoucherSupply = InterfaceVoucherTOKEN(voucherTokenContract).totalSupply();
        uint256 vouchersBurnedAllTime = InterfaceVoucherTOKEN(voucherTokenContract).totalBurnIn(0);

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(lastDividendPaidTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }
        
        require(InterfaceVoucherTOKEN(tokenAddress).transferFrom(owner, address(this), dividedAmount), 'could not transfer tokens');
        require(whitelistCaller[tokenAddress], 'Please add trc20 token contract address first');
        require(dividedAmount > 0, 'dividedAmount cant be zero');
        require((currentVoucherSupply + vouchersBurnedAllTime) > 0, 'There are no vouchers existed');
  
        
        //update dividend trackers
        dividendTrackerWhileDistribution(tokenAddress, dividedAmount, currentVoucherSupply + vouchersBurnedAllTime);
        
        lastDividendPaidTime = now;
        
        emit DividendPaidTRC20(tokenAddress, dividedAmount);
        
        return true;
    }



    
    function dividendTrackerWhileDistribution(address tokenAddress, uint256 dividedAmount, uint256 voucherBurnedCurrently ) internal {
        divPaidAllTime[tokenAddress] += dividedAmount;   //address 0x0 for TRX  
        voucherBurnedAtDivDistribution += voucherBurnedCurrently;
        totalDividendsPaidNumber++;   
    }
    
    
    
    function updateDivPercentageSUN(uint256 newPercentSUN) public onlyOwner returns(string){
        require(divPercentageSUN <= 100000000, 'percentage cant be more than 100%');
        divPercentageSUN = newPercentSUN;
        return "done";
    }

    
    /**
     * This function also used to invest any TRX into dividend pool.
     * This is useful especially while diamond voucher presale.
     */
    function reInvestDividendRemainder() public payable onlyOwner returns(string){
        require(dividendRemainder > 0 || msg.value > 0, 'dividendRemainder cant be zero');
        dividendAccumulated = dividendRemainder + msg.value;
        dividendRemainder=0;
        return "dividendRemainder is sent to div pool";
    }
    
    
    
    
    
    /**
        This function can be called by user directly or via any other contract
        It will withdraw any outstanding topia for any user and ALSO UPDATES dividend trackers
    */
    function withdrawDividendsEverything() public returns(bool){
        
        //tx.origin is because it will take original caller even if user is calling via another contract.
        address user = tx.origin;
        
        require(!globalHalt, 'Global halt is on');




        //withdraw any outstanding trx or trc20 tokens Start ---------------------
        //TRX withdraw
        uint256 outstandingDivTRX = userConfirmedDividendTRX(user);
        if(outstandingDivTRX > 0){
            user.transfer(outstandingDivTRX);
            emit DividendWithdrawTRX(user, outstandingDivTRX);
        }
        //TRC20 withdraw
        uint256 totalTokensTRC20 = whitelistCallerArray.length;
        for(uint64 i=0; i < totalTokensTRC20; i++){
            address tokenAddress = whitelistCallerArray[i];
            uint256 outstandingDivTRC20 = userConfirmedDividendTRC20(user, tokenAddress);
            if(outstandingDivTRC20 > 0){
                InterfaceVoucherTOKEN(tokenAddress).transfer(user, outstandingDivTRC20);
                emit DividendWithdrawTRC20(user, tokenAddress, outstandingDivTRC20);
            }
        }
        //withdraw any outstanding trx or trc20 tokens END ---------------------





        //Updating user's dividend tracker START ---------------------
        //these tracker variables will be used in calculating share percentage of div pool
        totalburnedVouchersTracker[user] = voucherBurnedAtDivDistribution;

        //this will track all the dividend distribution attempts.
        noOfDivPaidAfterBurn[user] = totalDividendsPaidNumber;

        //following will set value for each tokens and TRX at time of this action
        //TRX withdraw tracked
        divPaidAllTimeUsersTRX[user] = divPaidAllTime[address(0)];
        //TRC20 withdraw tracked
        for(i=0; i < totalTokensTRC20; i++){
            divPaidAllTimeUsersTRC20[user][whitelistCallerArray[i]] = divPaidAllTime[whitelistCallerArray[i]];
        }
        //Updating user's dividend tracker END ---------------------




        return true;
    } 


    
    
    function userConfirmedDividendTRX(address user) public view returns(uint256){

        
        uint256 userVouchersBurned = InterfaceVoucherTOKEN(voucherTokenContract).usersVoucherBurnedAmount(user,0);

        //if there are more dividend distribution after user has frozen topia
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        uint256 divPaidAllTimeUsers = divPaidAllTimeUsersTRX[user];
        
        if( divPaidAllTime[address(0)] > divPaidAllTimeUsers && userVouchersBurned > 0){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            //all three below trackers can never be zero due to above condition
            uint256 newDividendPoolAmount = divPaidAllTime[address(0)] - divPaidAllTimeUsers;
            uint256 totalVouchersBurned = voucherBurnedAtDivDistribution - totalburnedVouchersTracker[user];
            uint256 totalNoOfDivPaid = totalDividendsPaidNumber - noOfDivPaidAfterBurn[user];

            
            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the decimals variable is to have sharePercentage variable have more decimals.
            //so decimals is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
            uint256 sharePercentage = userVouchersBurned * 100 * 1000000 / (totalVouchersBurned / totalNoOfDivPaid) ;

            
            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(newDividendPoolAmount * sharePercentage > 0){
                
                return newDividendPoolAmount * sharePercentage / 100 / 1000000;                
                
            }
            
        }

        //by default it will return zero
    }

    
    function userConfirmedDividendTRC20(address user, address tokenAddress) public view returns(uint256){

        uint256 userVouchersBurned = InterfaceVoucherTOKEN(voucherTokenContract).usersVoucherBurnedAmount(user,0);

        //if there are more dividend distribution after user has frozen topia
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        if(divPaidAllTime[tokenAddress] > divPaidAllTimeUsersTRC20[user][tokenAddress] && userVouchersBurned > 0){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            //all three below trackers can never be zero due to above condition
            uint256 newDividendPoolAmount = divPaidAllTime[tokenAddress] - divPaidAllTimeUsersTRC20[user][tokenAddress];
            uint256 totalVouchersBurned = voucherBurnedAtDivDistribution - totalburnedVouchersTracker[user];
            uint256 totalNoOfDivPaid = totalDividendsPaidNumber - noOfDivPaidAfterBurn[user];

            
            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the decimals variable is to have sharePercentage variable have more decimals.
            //so decimals is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //(totalFrozenTopia / totalNoOfDivPaid) at the end is avearage of all topia fronzen at time of div distribution
            uint256 sharePercentage = userVouchersBurned * 100 * 1000000 / (totalVouchersBurned / totalNoOfDivPaid) ;
            

            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(newDividendPoolAmount * sharePercentage > 0){

                return newDividendPoolAmount * sharePercentage / 100 / 1000000;
            }
            
        }

        //by default it will return zero
    }


    
    /**
        This function displays all the dividend of all the game contracts
    */
    function getDividendPotentialTRX() public view returns(uint256){
        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableVoucherRake();
            if(amount > 0){
                totalDividend += amount;
            }
        }

        if(totalDividend > 0 || dividendAccumulated > 0 ){

            return totalDividend + dividendAccumulated;
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            //return (totalAmount * divPercentageSUN / 100 / 1000000);  
            
        }
        
        //by default it returns zero
        
    }
    
    
    
    


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

        
    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawTokens(address tokenAddress, uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        InterfaceVoucherTOKEN(tokenAddress).transfer(owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
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


    
    function updateContractAddresses(address voucherTokenContract_) public onlyOwner returns(string){
        voucherTokenContract = voucherTokenContract_;
        return("contract address updated successfully");
    }
    
    


}