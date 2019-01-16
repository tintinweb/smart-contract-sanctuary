pragma solidity ^0.4.24;

contract ValidationInterface {
  function getValidated(address _address,uint256 _code) external pure returns (bool);
}
contract AcutalMinerInterface{
    //The Price of ETH(0.001USD)
    uint256 public ETHUSD;
    //The Coupon ratio (0.01%)
    uint256 public CouponRatio;
    //The Price of maintenance of each hashrate (0.001USD per mh/s per seconds)
    uint256 public MaintenanceFee;
    //maintenanceDividends
    uint256 public maintenanceDividends;
    //Last time for maintenance
    uint256 public lastMaintenanceTime;
    //The Price of each hashrate (0.001USD)
    uint256 public Price;
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public{
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner,"its only for administration of ActuralMiner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner() {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
/**
 * 
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

//Bug: Transfer ETH to USD in buy through ETH
contract UserInterface is Ownable{
    using SafeMath for uint256;
    
    ValidationInterface public validate;
    AcutalMinerInterface public actualminer;
    address private AcutalMinerInterfaceAddress;
    address private ValidationInterfaceAddress;
    //Total Amounts of Registered Customer
    uint256 public amountPlayer;
    //The Price of Expired Time Limit 2 years usually
    uint256 public ExpiredTime;
    //The last index expired
    uint256 public lastExpiredIndex;
    //Referral Ratio back (0.01%)
    uint256 public ReferralRatio;
    //Validate ReferralCode(0.001mh/s)
    uint256 public ReferralThreshold;
    //Total Amounts of Sold Hashrate(0.001mh/s)
    uint256 public amountSold;
    //Total dividends
    uint256 public totalDividendPoints;
    
    struct Account {
        //bool Existed;
        //bool ReferralActivated;
        //bool Validated;
        bytes8 ReferralCode;
        uint256 ID;
        uint256 Balance;
        uint256 AffiliateBalance;    // affiliate vault
        uint256 AffiliateTimes;    // affiliate vault
        uint256 AffiliateToken;    // affiliate vault
        uint256 AffiliateProfits;    // affiliate vault
        uint256 CostETH;    // affiliate vault
        uint256 CostUSD;    // affiliate vault
        uint256 Tokens;
        uint256 lastDividendPoints;
        uint256 totalProfits;
    }

    struct salesHistory{
        address addr;
        uint256 Tokens;
        uint256 Time;
    }
    
    mapping(address=>Account) accounts;
    //Referral code to origin address
    mapping(bytes8=>address) referralMap;
    salesHistory[] public salesRecord;
    
    event eventRegister(
        address addr,
        uint256 playerID
    );
    event eventReferralActivated(
        address addr,
        bytes8 referralCode
    );
    event eventWithdraw(
        address addr,
        uint256 amount
    );
    
    constructor() public{
        ValidationInterfaceAddress = 0xD46b8Da4DB8AA6BcBd8d168BbA9681425001F1F9;
        AcutalMinerInterfaceAddress = 0x1308F82277CbA53abEa0F959073A92aD29D32BfA;
        validate = ValidationInterface(ValidationInterfaceAddress);
        actualminer = AcutalMinerInterface(AcutalMinerInterfaceAddress);
        //Total Amounts of Registered Customer
        amountPlayer = 0;
        //The Price of Expired Time Limit
        ExpiredTime = 730 days;
        //Referral Ratio back (0.01%)
        ReferralRatio = 250;
        //Validate ReferralCode(0.001mh/s)
        ReferralThreshold = 10000;
        //The last index expired
        lastExpiredIndex = 0;
        //Total Amounts of Sold Hashrate(0.001mh/s)
        //1 to prevent divide 0
        amountSold = 1;
        //Total dividends
        totalDividendPoints = 0;
    }
    
    modifier accountExisted(address addr) {
        require(accounts[addr].ID!=0,"Accounts not existed!");
        _;
    }
    
    modifier isActualMiner() {
        require(msg.sender==AcutalMinerInterfaceAddress,"You are not official!");
        _;
    }

    modifier isValidated(address Address,uint256 inValidationCode) {
        //if(!accounts[Address].Validated){
            bool Vali = validate.getValidated(Address,inValidationCode);
            //if(Vali){
            //    accounts[Address].Validated = true;
            //}
        //}
        //require(accounts[Address].Validated,"Accounts not verified!!");
        require(Vali,"Accounts not verified!!");
        _;
    }
    
    modifier updateAccount(address addr) {
      uint256 balanceToAdd = dividends(addr);
      if(balanceToAdd > 0) {
        accounts[addr].Balance += balanceToAdd;
        accounts[addr].lastDividendPoints = totalDividendPoints;
      }
      _;
    }
    
    function setActualMinerAddress(address addr) external
    onlyOwner()
    {
        AcutalMinerInterfaceAddress = addr;
        actualminer = AcutalMinerInterface(AcutalMinerInterfaceAddress);
    }
    
    function setValidationAddress(address addr) external
    onlyOwner()
    {
        ValidationInterfaceAddress = addr;
        validate = ValidationInterface(ValidationInterfaceAddress);
    }
    
    function getReferralCode(address addr) external view returns(bytes8){
        //require(accounts[addr].ReferralActivated,"You don&#39;t have a ReferralCode until now!");
        //if(accounts[addr].ReferralActivated)
        //  return accounts[addr].ReferralCode;
        return accounts[addr].ReferralCode;
    }

    function getReferralStatus(address addr) external view returns(uint256,uint256,uint256){
        //require(accounts[addr].ReferralActivated,"You don&#39;t have a ReferralCode until now!");
        //if(accounts[addr].ReferralActivated)
        //  return accounts[addr].ReferralCode;
        return (accounts[addr].AffiliateTimes,accounts[addr].AffiliateToken,accounts[addr].AffiliateProfits);
    }

    function getCost(address addr) external view returns(uint256,uint256){
        return (accounts[addr].CostETH,accounts[addr].CostUSD);
    }

    function getUserID(address addr) external view 
    //accountExisted(addr)
    returns(uint256){
        return accounts[addr].ID;
    }
     
    function getTotalProfits(address addr) external view 
    //accountExisted(addr)
    returns(uint256){
        uint256 balanceToAdd = dividends(addr);
        uint256 balanceSum = accounts[addr].Balance;
        if(balanceToAdd > 0) 
            balanceSum = balanceSum.add(balanceToAdd);
        return accounts[addr].totalProfits+balanceSum+accounts[addr].AffiliateBalance;
    } 
    
    function getlastDividendPoints(address addr) external view
    //accountExisted(addr)
    returns(uint256)
    {
        return accounts[addr].lastDividendPoints;
    }
    
    function getToken(address addr) external view
    //accountExisted(addr)
    returns(uint256)
    {
        return accounts[addr].Tokens;
    }
    
    function getBalance(address addr) external view
    //accountExisted(addr)
    returns(uint256,uint256)
    {
        uint256 balanceToAdd = dividends(addr);
        uint256 balanceSum = accounts[addr].Balance;
        if(balanceToAdd > 0) 
            balanceSum = balanceSum.add(balanceToAdd);
        return (balanceSum,accounts[addr].AffiliateBalance);
    }
    
    
    function ReferralActivated(address addr) private
    accountExisted(addr)
    {
        require(accounts[addr].ID!=0,"ReferralCode existed!");
        require(accounts[addr].ReferralCode==bytes8(0),"ReferralCode existed!");
        //Generate ReferralCode
        bytes8 ReferralCode;
        uint8 i = 0;
        do{
            ReferralCode = bytes8(uint256(keccak256(abi.encodePacked(addr))).add(uint256(i)));
            i++;
        }while(referralMap[ReferralCode]!=address(0) || ReferralCode==bytes8(0));
        referralMap[ReferralCode] = addr;
        accounts[addr].ReferralCode = ReferralCode;
        //accounts[addr].ReferralActivated = true;
        emit eventReferralActivated(addr,ReferralCode);
    }
    
    
    function registerCustomer(address addr) private
    {
        require(accounts[addr].ID==0,"Customer existed!");
        amountPlayer++;
        accounts[addr].ID = uint256(amountPlayer);
        //accounts[addr].Existed = true;
        accounts[addr].lastDividendPoints = totalDividendPoints;

        //accounts[addr].Balance = 0;
        //accounts[addr].AffiliateBalance = 0;
        //accounts[addr].Tokens = 0;
        //accounts[addr].Validated = true;
        //accounts[addr].ReferralCode = 0x0000000000000000;
        //referralMap[addr] = customer;
        emit eventRegister(addr,amountPlayer);
    }
    
    
    function dividends(address addr) private view returns(uint256) {
      uint256 newDividend = (totalDividendPoints.sub(accounts[addr].lastDividendPoints)).mul(accounts[addr].Tokens);
      return newDividend;
    }
    
    function buyTokens_ETH(address addr,uint256 ethAmount,uint256 validationCode,bytes8 affCode) external 
    isActualMiner()
    isValidated(addr,validationCode)
    returns(uint256)
    {
        uint256 PriceNow = actualminer.Price();
        //Check CustomerID exist or not
        if(accounts[addr].ID==0)
            registerCustomer(addr);
        //Check Affiailate exist or not
        if(accounts[referralMap[affCode]].ID!=0){
            PriceNow = PriceNow.mul(actualminer.CouponRatio()).div(10000);
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += ethAmount.mul(ReferralRatio).div(uint256(10000));  
            accounts[referralMap[affCode]].AffiliateProfits += ethAmount.mul(ReferralRatio).div(uint256(10000));   
        }

        uint256 token = ethAmount.mul(actualminer.ETHUSD()).div(1e30).div(PriceNow);

        if(ReferralThreshold > accounts[addr].Tokens && ReferralThreshold <= (accounts[addr].Tokens.add(token)))
            ReferralActivated(addr);

        if(accounts[referralMap[affCode]].ID!=0){
            accounts[referralMap[affCode]].AffiliateTimes += 1;
            accounts[referralMap[affCode]].AffiliateToken += token;
        }

        uint256 dividendShift = totalDividendPoints.sub(accounts[addr].lastDividendPoints).mul(accounts[addr].Tokens);
        dividendShift = dividendShift.div(accounts[addr].Tokens.add(token));
        accounts[addr].lastDividendPoints = totalDividendPoints.sub(dividendShift);
        accounts[addr].Tokens += token;
        accounts[addr].CostETH += ethAmount;
        accounts[addr].CostUSD += ethAmount.mul(actualminer.ETHUSD()).div(1e33);
        amountSold += token;
        salesRecord.push(salesHistory(addr,token,now));
        return token;
    }
    
    function buyTokens_Vault(address addr,uint256 ethAmount,bytes8 affCode) external 
    isActualMiner()
    accountExisted(addr)
    updateAccount(addr)
    returns(uint256)
    {
        uint256 totalBalance = accounts[addr].Balance.add(accounts[addr].AffiliateBalance);
        uint256 PriceNow = actualminer.Price();
        //Check Vault enough or not
        require(totalBalance>=ethAmount,"Vault not enought!");
        
        //Check Affiailate exist or not
        if(accounts[referralMap[affCode]].ID!=0){
            PriceNow = PriceNow.mul(actualminer.CouponRatio()).div(10000);
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += ethAmount.mul(ReferralRatio).div(uint256(10000));
            accounts[referralMap[affCode]].AffiliateProfits += ethAmount.mul(ReferralRatio).div(uint256(10000));   
        }

        uint256 token = ethAmount.mul(actualminer.ETHUSD()).div(1e30).div(PriceNow);
        if(ReferralThreshold > accounts[addr].Tokens && ReferralThreshold <= (accounts[addr].Tokens.add(token)))
            ReferralActivated(addr);
        
        if(accounts[referralMap[affCode]].ID!=0){
            accounts[referralMap[affCode]].AffiliateTimes += 1;
            accounts[referralMap[affCode]].AffiliateToken += token;
        }
        
        if(accounts[addr].AffiliateBalance>ethAmount){
            accounts[addr].AffiliateBalance-=ethAmount;
        }
        else{
            accounts[addr].Balance -= (ethAmount.sub(accounts[addr].AffiliateBalance));
            accounts[addr].AffiliateBalance -= 0;
        }
        
        uint256 dividendShift = totalDividendPoints.sub(accounts[addr].lastDividendPoints).mul(accounts[addr].Tokens);
        dividendShift = dividendShift.div(accounts[addr].Tokens.add(token));
        accounts[addr].lastDividendPoints = totalDividendPoints.sub(dividendShift);
        accounts[addr].Tokens += token;
        accounts[addr].CostETH += ethAmount;
        accounts[addr].CostUSD += ethAmount.mul(actualminer.ETHUSD()).div(1e33);
        amountSold += token;

        salesRecord.push(salesHistory(addr,token,now));
        return token;
    }
    //!!!!!!Need to be protected!!!!!!!
    function buyTokens_Address(address addr,uint256 token,bytes8 affCode) external
    isActualMiner()
    returns(bool)
    {
        uint256 PriceNow = actualminer.Price();
        //Check CustomerID exist or not
        if(accounts[addr].ID==0)
            registerCustomer(addr);
        //Check Validated or not
        //if(!accounts[addr].Validated)
        //    accounts[addr].Validated = true;
        //Check Affiailate exist or not
        if(accounts[referralMap[affCode]].ID!=0){
            PriceNow = PriceNow.mul(actualminer.CouponRatio()).div(uint256(10000));
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += token.mul(PriceNow).mul(ReferralRatio).mul(1e18).div(actualminer.ETHUSD()).div(uint256(1e10)); 
            accounts[referralMap[affCode]].AffiliateProfits += token.mul(PriceNow).mul(ReferralRatio).mul(1e18).div(actualminer.ETHUSD()).div(uint256(1e10)); 
            accounts[referralMap[affCode]].AffiliateTimes += 1;
            accounts[referralMap[affCode]].AffiliateToken += token;
        }
        
        if(ReferralThreshold > accounts[addr].Tokens && ReferralThreshold <= (accounts[addr].Tokens.add(token)))
            ReferralActivated(addr);
            
        uint256 dividendShift = totalDividendPoints.sub(accounts[addr].lastDividendPoints).mul(accounts[addr].Tokens);
        dividendShift = dividendShift.div(accounts[addr].Tokens.add(token));
        accounts[addr].lastDividendPoints = totalDividendPoints.sub(dividendShift);
        accounts[addr].Tokens += token;
        accounts[addr].CostETH += token.mul(PriceNow).mul(1e18).div(actualminer.ETHUSD()).div(uint256(1e6));
        accounts[addr].CostUSD += token.mul(PriceNow).div(1e3);
        amountSold += token;
        salesRecord.push(salesHistory(addr,token,now));
        
        return true;
    }
    
    function checkExpired() external{
        uint256 arrayLength = salesRecord.length;
        uint256 timeNow = now;
        uint256 i = lastExpiredIndex;
        for (; i<arrayLength; i++) {
          if((timeNow-salesRecord[i].Time)>ExpiredTime){
            //Bug!!! Remember to change the last dividend time!!
            accounts[salesRecord[i].addr].lastDividendPoints = totalDividendPoints.sub((totalDividendPoints.sub(accounts[salesRecord[i].addr].lastDividendPoints)).mul(accounts[salesRecord[i].addr].Tokens).div(accounts[salesRecord[i].addr].Tokens.sub(salesRecord[i].Tokens)));
            accounts[salesRecord[i].addr].Tokens -= salesRecord[i].Tokens;
          }
          else
            break;
        }
        lastExpiredIndex = i;
    }
    
    function withdraw(address addr) external 
    isActualMiner()
    accountExisted(addr)
    updateAccount(addr)
    returns(uint256){
        uint256 BalanceWithdraw = accounts[addr].Balance.add(accounts[addr].AffiliateBalance);
        accounts[addr].Balance = 0;
        accounts[addr].AffiliateBalance = 0;
        accounts[addr].lastDividendPoints =  totalDividendPoints;
        accounts[addr].totalProfits = accounts[addr].totalProfits.add(BalanceWithdraw);
        emit eventWithdraw(addr,BalanceWithdraw);
        return BalanceWithdraw;
    }
    

    function addTotalDividendPoints(uint256 tdp) external
    isActualMiner(){
        totalDividendPoints = totalDividendPoints.add(tdp);
    }

    function kill() external 
    onlyOwner(){
        selfdestruct(owner);
    }
    
    function () payable public{
    }
}