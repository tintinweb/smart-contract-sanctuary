pragma solidity ^0.4.24;

contract ValidationInterface {
  function getValidated(address _address,uint256 _code) public view returns (bool);
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

contract ActuralMiner is Ownable{
    // to do:
    // 1. allow admin to lower the maintenanceFee
    // 2. dispatch the Profit from Pools !!ok!!
    // 3. calculate the maintenanceFee percentage
    // 4. Add events
    // 5. get eth price
    // 6. delete expired tokens
    // 7. initialize uin256
    // 8. buy tokens in different time
    // 9. allow admin to transfer Balance after expited
    //10. withdraw bug exist!
    //11. gas research
    //12. ETHFAN API Alternation(24 Hrs)
    //13. memory or storage?
    //14. maintenanceFee > profit
    // checkInventory ro modifier?
    // PROFIT < maintenanveFee

    //To test:
    // 1. checkInventory not enough
    // 2. ETH Price API Cracked
    // 3. expired
    // 4. admin withdraw
    // 5. maintenanceFee > profit
    // 
    
    event eventByAddress(address,bytes8,uint256,uint256,uint256);
    event eventByETH(bytes8,uint256,uint256,uint256);
    event eventByVault();
    event eventWithdraw(uint256,uint256);
    event eventRegister(address,uint256);
    event eventReferralActivated(address,bytes8,uint256);
    event eventDivideProfit(address,uint256,uint256,uint256);
    
    address public AdminWallet;
    address public Manager;

    address ValidationInterfaceAddress = 0x272a43805714624F4c8179f5aFf7b711C0F073c5;
    ValidationInterface ValidationContract = ValidationInterface(ValidationInterfaceAddress);
    //The hashrate supply(0.001mh/s)
    uint256 public TotalHashRate;
    //The Price of each hashrate (0.001USD)
    uint256 public Price;
    //The Price of Expired Time Limit 2 years usually
    uint256 public ExpiredTime;
    //The last index expired
    uint256 public lastExpiredIndex;
    //The Price of ETH
    uint256 public ETHUSD;
    //Last Update ETHUSD Time
    uint256 public lastUpdateETHUSD;
    //Update ETHUSD Time Interval
    uint256 public IntervalETHUSD;
    //Total Amounts of Registered Customer
    uint256 public amountPlayer;
    //Total Amounts of Sold Hashrate(0.001mh/s)
    uint256 public amountSold;
    //The Coupon ratio (0.01%)
    uint256 public CouponRatio;
    //Referral Ratio back (0.01%)
    uint256 public ReferralRatio;
    //Validate ReferralCode(0.001mh/s)
    uint256 public ReferralThreshold;
    //Total dividends
    uint256 public totalDividendPoints;
    //Dividends to be distrubuted
    uint256 public unclaimedDividends;
    //The Price of maintenance of each hashrate (0.001USD per mh/s per seconds)
    uint256 public MaintenanceFee;
    //maintenanceDividends
    uint256 public maintenanceDividends;
    //Last time for maintenance
    uint256 public lastMaintenanceTime;
    
    struct Account {
        bool Validated;
        bytes8 ReferralCode;
        uint256 ID;
        uint256 Balance;
        uint256 AffiliateBalance;    // affiliate vault
        uint256 Tokens;
        uint256 lastDividendPoints;
    }

    struct salesHistory{
        address addr;
        uint8 method;
        bytes8 ReferralCode;
        uint256 Tokens;
        uint256 Time;
    }
    
    mapping(address=>Account) accounts;
    //Referral code to origin address
    mapping(bytes8=>address) referralMap;
    salesHistory[] public salesRecord;
    
    constructor() public{
        
        AdminWallet = msg.sender;
        Manager = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        
        //The hashrate supply(0.001mh/s)
        TotalHashRate = 30000000;
        //The Price of each hashrate (0.001USD)
        Price = 24000;
        //The Price of Expired Time Limit
        ExpiredTime = 730 days;
        //The Coupon ratio (0.01%)
        CouponRatio = 9000;
        //Last Update ETHUSD Time
        lastUpdateETHUSD = 0;
        //Update ETHUSD Time Interval(s)
        IntervalETHUSD = 60;
        //Total Amounts of Registered Customer
        amountPlayer = 1;
        //Total Amounts of Sold Hashrate(0.001mh/s)
        amountSold = 0;
        //Referral Ratio back (0.01%)
        ReferralRatio = 250;
        //Validate ReferralCode(0.001mh/s)
        ReferralThreshold = 40000;
        //Total dividends
        totalDividendPoints = 0;
        //Dividends to be distrubuted
        unclaimedDividends = 0;
        //The Price of maintenance of each hashrate (0.001USD per mh/s per seconds)
        MaintenanceFee = 12;
        //Last time for maintenance
        lastMaintenanceTime = now;
        //The last index expired
        lastExpiredIndex = 0;

        getETHUSD();

    }

    modifier onlyManager(){
        require(msg.sender == Manager, "its only for manager of ActuralMiner");
        _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier accountExisted(address addr) {
        uint256 CustomerID = accounts[addr].ID;
        require(CustomerID!=0,"Accounts not existed!");
        _;
    }

    modifier isValidated(address Address,uint256 inValidationCode) {
        if(!accounts[Address].Validated){
            bool Vali = ValidationContract.getValidated(Address,inValidationCode);
            if(Vali){
                accounts[Address].Validated = true;
            }
        }
        require(accounts[Address].Validated,"Accounts not verified!!");
        _;
    }
    
    //for MaintenanceFee
    function setAdminWallet(address _newAdminWallet) external
    onlyOwner()
    {
        require(_newAdminWallet != 0x0);
        AdminWallet = _newAdminWallet;
    }
    
    
    function setManager(address _newManager) external
    onlyOwner()
    {
        require(_newManager != 0x0);
        Manager = _newManager;
    }
    
    function setPrice(uint32 _newPrice) external
    onlyOwner()
    {
        require(_newPrice > 0);
        Price = _newPrice;
    }
    
    function setCouponRatio(uint32 _newCouponRatio) external
    onlyOwner()
    {
        require(_newCouponRatio > 0);
        CouponRatio = _newCouponRatio;
    }
    
    function setSupply(uint256 _newSupply) external
    onlyOwner()
    {
        require(_newSupply > 0);
        TotalHashRate = _newSupply;
    }
    
    function getReferralCode() public view returns(bytes8){
        require(accounts[msg.sender].ReferralCode!=bytes8(0),"You don&#39;t have a ReferralCode until now!");
        return accounts[msg.sender].ReferralCode;
    }
    
    //uint 0.01%
    function getMaintainFee() private view returns(uint256){
        return (now-lastMaintenanceTime)*MaintenanceFee*amountSold;
    }
    
    function getETHUSD() private{
        require((now-lastUpdateETHUSD)>IntervalETHUSD);
        
        ETHUSD = uint256(400000);
        lastUpdateETHUSD = now;
    }
    
    function getToken() public view
    accountExisted(msg.sender)
    returns(uint256)
    {
        return accounts[msg.sender].Tokens;
    }
    
    function getBalance() public view
    accountExisted(msg.sender)
    returns(uint256,uint256)
    {
        uint256 balanceToAdd = dividends(msg.sender);
        uint256 balanceSum = accounts[msg.sender].Balance;
        if(balanceToAdd > 0) 
            balanceSum += balanceToAdd;
        return (balanceSum,accounts[msg.sender].AffiliateBalance);
    }
    
    function getID() public view
    accountExisted(msg.sender)
    returns(uint256)
    {
        return (accounts[msg.sender].ID);
    }
    
    function getReferral() public view
    returns(bytes8)
    {
        //Generate ReferralCode
        bytes8 ReferralCode;
        do{
            ReferralCode = bytes8(keccak256(abi.encodePacked(msg.sender)));
        }while(referralMap[ReferralCode]!=address(0) || ReferralCode==bytes8(0));
        return ReferralCode;
    }
    
    
    // check if intventory enough or not 
    function checkInventory(uint256 amountBuy) private view returns(bool){
        if(amountBuy<=TotalHashRate-amountSold)
            return true;
        else
            return false;
    }
    
    function ReferralActivated(address addr) private{
        //Generate ReferralCode
        bytes8 ReferralCode;
        do{
            ReferralCode = bytes8(keccak256(abi.encodePacked(addr)));
        }while(referralMap[ReferralCode]!=address(0) || ReferralCode==bytes8(0));
        referralMap[ReferralCode] = addr;
        accounts[addr].ReferralCode = ReferralCode;
        emit eventReferralActivated(addr,ReferralCode,now);
    }
    
    //Buy through ETH
    //Bug!! need to check affCode exist or not in advance
    //Bug!! need to check inventory exist or not in advance
    function buy_ETH(uint256 validationCode,bytes8 affCode) payable public
    isValidated(msg.sender,validationCode)
    {
        getETHUSD();
        uint256 priceNow = Price;
        uint256 CustomerID = accounts[msg.sender].ID;
        uint256 token = msg.value/priceNow;
        //Check CustomerID exist or not
        if(CustomerID==0)
            registerCustomer(msg.sender);
            
        //Check Affiailate exist or not
        if(referralMap[affCode]!=address(0)){
            priceNow = priceNow*CouponRatio/10000;
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += msg.value/(10000/ReferralRatio); 
        }
        if(accounts[msg.sender].ReferralCode==bytes8(0) && ReferralThreshold > accounts[msg.sender].Tokens && ReferralThreshold <= (accounts[msg.sender].Tokens + token))
            ReferralActivated(msg.sender);
        //
        accounts[msg.sender].lastDividendPoints = totalDividendPoints - (totalDividendPoints-accounts[msg.sender].lastDividendPoints)*accounts[msg.sender].Tokens/(accounts[msg.sender].Tokens+token);
        accounts[msg.sender].Tokens += token;
        amountSold += msg.value/priceNow;


        salesRecord.push(salesHistory(msg.sender,1,affCode,token,now));
        emit eventByETH(affCode,priceNow,token,now);
        //event
    }
    
    //Buy through USD, only Manager can do this!
    //Bug!! need to check affCode exist or not in advance
    //Bug!! need to check inventory exist or not in advance
    function buyAddress(address addr,bytes8 affCode,uint256 token) public
    onlyManager()
    //returns(uint32)
    {
        uint256 priceNow = Price;
        uint256 CustomerID = accounts[addr].ID;
        //Check CustomerID exist or not
        if(CustomerID==0)
            registerCustomer(addr);
        //Check Affiailate exist or not
        if(referralMap[affCode]!=address(0)){
            priceNow = priceNow*CouponRatio/10000;
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += token*priceNow/(10000/ReferralRatio); 
        }
        
        if(accounts[addr].ReferralCode!=bytes8(0) && ReferralThreshold > accounts[addr].Tokens && ReferralThreshold <= (accounts[addr].Tokens + token))
            ReferralActivated(addr);
        //
        accounts[addr].lastDividendPoints = totalDividendPoints - (totalDividendPoints-accounts[addr].lastDividendPoints)*accounts[addr].Tokens/(accounts[addr].Tokens+token);
        accounts[addr].Tokens += token;
        amountSold += token;

        salesRecord.push(salesHistory(addr,0,affCode,token,now));
        
        emit eventByAddress(addr,affCode,priceNow,token,now);
        //event
    }
    
    function checkExpired() private{
        uint256 arrayLength = salesRecord.length;
        uint256 timeNow = now;
        uint256 i = lastExpiredIndex;
        for (; i<arrayLength; i++) {
          if((timeNow-salesRecord[i].Time)>ExpiredTime){
            amountSold -= salesRecord[i].Tokens;
            //Bug!!! Remember to change the last dividend time!!
            accounts[salesRecord[i].addr].lastDividendPoints = accounts[salesRecord[i].addr].lastDividendPoints*(accounts[salesRecord[i].addr].Tokens)/(accounts[salesRecord[i].addr].Tokens-salesRecord[i].Tokens);
            accounts[salesRecord[i].addr].Tokens -= salesRecord[i].Tokens;
          }
          else
            break;
        }
        lastExpiredIndex = i;
    }
    
    function registerCustomer(address customer) private
    isHuman()
    {
        uint256 CustomerID = accounts[customer].ID;
        require(CustomerID==0,"Customer existed!");
        accounts[customer].ID = amountPlayer;
        //accounts[customer].Address = customer;
        accounts[customer].Balance = 0;
        accounts[customer].AffiliateBalance = 0;
        accounts[customer].Tokens = 0;
        accounts[customer].Validated = true;
        accounts[customer].ReferralCode = 0x0000000000000000;
        //referralMap[amountPlayer] = customer;
        amountPlayer++;
        emit eventRegister(customer,amountPlayer);
    }
    
    modifier updateAccount(address addr) {
      uint256 balanceToAdd = dividends(addr);
      if(balanceToAdd > 0) {
        //unclaimedDividends -= balanceToAdd;
        accounts[addr].Balance += balanceToAdd;
        accounts[addr].lastDividendPoints = totalDividendPoints;
      }
      _;
    }
    
    //Bug!! Not register Yet
    function withdraw() public
    isHuman()
    updateAccount(msg.sender)
    {   
        address Addr = msg.sender;
        uint256 BalanceWithdraw = accounts[Addr].Balance+accounts[Addr].AffiliateBalance;
        accounts[Addr].Balance = 0;
        accounts[Addr].AffiliateBalance = 0;
        accounts[Addr].lastDividendPoints =  totalDividendPoints;
        unclaimedDividends -= BalanceWithdraw;
        Addr.transfer(BalanceWithdraw);
        emit eventWithdraw(BalanceWithdraw,now);
    }
    
    //Profit from the Pools!
    function () payable public{
        checkExpired();
        uint256 ethReceived = msg.value;
        uint256 thisTimeMaintainFee = getMaintainFee();

        if(thisTimeMaintainFee>ethReceived){
            maintenanceDividends += thisTimeMaintainFee;
            totalDividendPoints += (ethReceived-thisTimeMaintainFee);
            unclaimedDividends += (ethReceived-thisTimeMaintainFee);
            lastMaintenanceTime = now;
        }
        else{
            lastMaintenanceTime += ethReceived/amountSold/MaintenanceFee;
            maintenanceDividends += ethReceived;
        }
        emit eventDivideProfit(msg.sender,ethReceived,thisTimeMaintainFee,now);
    }
      
    uint256 pointMultiplier = 10e18;
    
    function dividends(address addr) private view returns(uint256) {
      uint256 newDividend = (totalDividendPoints-accounts[addr].lastDividendPoints) * accounts[addr].Tokens;
      return newDividend;
    }
    
    function kill() external 
    onlyOwner(){
        selfdestruct(AdminWallet);
    }
}
/**
 * 
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}