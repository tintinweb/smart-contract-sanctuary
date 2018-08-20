pragma solidity ^0.4.24;
contract ValidationInterface {
  function getValidated(address _address,uint256 _code) public view returns (bool);
}
//https://fiatcontract.com/
contract FiatContract {
  function ETH(uint _id) public view returns (uint256);
  function USD(uint _id) public view returns (uint256);
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
    // *1. allow admin to lower the maintenanceFee
    // 2. dispatch the Profit from Pools !!ok!!
    // 3. calculate the maintenanceFee percentage !!ok!!
    // 4. Add events !!ok!!
    // 5. get eth price !!ok!!
    // 6. delete expired tokens !!ok!!
    // 7. initialize uin256 !!ok!!
    // 8. buy tokens in different time !!ok!!
    // *9. allow admin to transfer Balance after expited
    //10. withdraw bug exist!
    //*11. gas research
    //12. ETHFAN API Alternation(24 Hrs) !!ok!!
    //13. memory or storage? !!ok!!
    //*14. maintenanceFee > profit
    // *checkInventory ro modifier?
    // *PROFIT < maintenanveFee
    // *Use safe math
    // *Validation
    // *Buy through Vault !!ok!!
    // *Self destruct !!ok!!
    // *User data in other contract

    //To test:
    // 1. checkInventory not enough
    // 2. ETH Price API Cracked
    // 3. expired !!ok!!
    // 4. admin withdraw
    // 5. maintenanceFee > profit
    // 
    using SafeMath for uint256;

    event eventByAddress(address,bytes8,uint256,uint256,uint256);
    event eventByETH(bytes8,uint256,uint256,uint256);
    event eventByVault(bytes8,uint256,uint256,uint256);
    event eventWithdraw(uint256,uint256);
    event eventRegister(address,uint256);
    event eventReferralActivated(address,bytes8,uint256);
    event eventDivideProfit(address,uint256,uint256,uint256);

    address public AdminWallet;
    address public Manager;
    FiatContract public price;

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
    //The Price of ETH(0.001USD)
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
        uint32 ID;
        uint256 Balance;
        uint256 AffiliateBalance;    // affiliate vault
        uint256 Tokens;
        uint256 lastDividendPoints;
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
    
    constructor() public{
        
        AdminWallet = msg.sender;
        Manager = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909);
        //price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591) // MAINNET ADDRESS
        
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
        ReferralThreshold = 10000;
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
        require(accounts[addr].ID!=0,"Accounts not existed!");
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
        require(_newCouponRatio > 0 && _newCouponRatio <= 10000);
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

    function getMaintainFee() private view returns(uint256){
        return (now.sub(lastMaintenanceTime)).mul(MaintenanceFee).mul(amountSold);
    }
    
    function getETHUSD() private{
        require((now-lastUpdateETHUSD)>IntervalETHUSD);
        
        ETHUSD = uint256(10e18).div(price.USD(0).mul(100));
        //ETHUSD = 400000;
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
            balanceSum = balanceSum.add(balanceToAdd);
        return (balanceSum,accounts[msg.sender].AffiliateBalance);
    }
    
    // check if intventory enough or not 
    function checkInventory(uint256 amountBuy) private view returns(bool){
        if(amountBuy<=TotalHashRate.sub(amountSold))
            return true;
        else
            return false;
    }
    
    function ReferralActivated(address addr) private{
        require(accounts[addr].ReferralCode==bytes8(0),"ReferralCode Existed!");
        //Generate ReferralCode
        bytes8 ReferralCode;
        uint8 i = 0;
        do{
            ReferralCode = bytes8(uint256(keccak256(abi.encodePacked(addr))).add(uint256(i)));
            i++;
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
        //Check CustomerID exist or not
        if(CustomerID==0)
            registerCustomer(msg.sender);
            
        //Check Affiailate exist or not
        if(referralMap[affCode]!=address(0)){
            priceNow = priceNow.mul(CouponRatio).div(10000);
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += msg.value.div(uint256(10000).div(ReferralRatio)); 
        }

        if(ReferralThreshold > accounts[msg.sender].Tokens && ReferralThreshold <= (accounts[msg.sender].Tokens.add(token)))
            ReferralActivated(msg.sender);
        
        uint256 token = msg.value.div(priceNow);
        accounts[msg.sender].lastDividendPoints = totalDividendPoints.sub((totalDividendPoints.sub(accounts[msg.sender].lastDividendPoints))*(accounts[msg.sender].Tokens.div(accounts[msg.sender].Tokens.add(token))));
        accounts[msg.sender].Tokens += token;
        amountSold += token;


        salesRecord.push(salesHistory(msg.sender,token,now));
        emit eventByETH(affCode,priceNow,token,now);
        //event
    }
    //Buy through Vault
    //Bug!! need to check affCode exist or not in advance
    //Bug!! need to check inventory exist or not in advance
    function buy_Vault(uint256 vaultAmount,bytes8 affCode) public
    {
        getETHUSD();
        address Addr = msg.sender;
        uint256 totalBalance = accounts[Addr].Balance.add(accounts[Addr].AffiliateBalance);
        //Check Vault enough or not
        require(totalBalance>=vaultAmount,"Vault not enought!");

        uint256 priceNow = Price;
        
        //Check Affiailate exist or not
        if(referralMap[affCode]!=address(0)){
            priceNow = priceNow.mul(CouponRatio).div(10000);
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += vaultAmount.div(uint256(10000)).mul(ReferralRatio); 
        }

        if(ReferralThreshold > accounts[Addr].Tokens && ReferralThreshold <= (accounts[Addr].Tokens.add(token)))
            ReferralActivated(Addr);

        uint256 token = vaultAmount.div(priceNow);
        if(accounts[Addr].AffiliateBalance>vaultAmount){
            accounts[Addr].AffiliateBalance-=vaultAmount;
        }
        else{
            accounts[Addr].Balance -= (vaultAmount.sub(accounts[Addr].AffiliateBalance));
            accounts[Addr].AffiliateBalance -= 0;
        }

        accounts[Addr].lastDividendPoints = totalDividendPoints.sub((totalDividendPoints.sub(accounts[Addr].lastDividendPoints))*(accounts[Addr].Tokens.div(accounts[Addr].Tokens.add(token))));
        accounts[Addr].Tokens += token;
        amountSold += token;

        salesRecord.push(salesHistory(Addr,token,now));
        emit eventByVault(affCode,priceNow,token,now);
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
        //uint256 CustomerID = accounts[addr].ID;
        //Check CustomerID exist or not
        if(accounts[addr].ID==0)
            registerCustomer(addr);
        //Check Validated or not
        if(!accounts[addr].Validated)
            accounts[addr].Validated = true;
        //Check Affiailate exist or not
        if(referralMap[affCode]!=address(0)){
            priceNow = priceNow.mul(CouponRatio).div(uint256(10000));
            //Affiailate function
            accounts[referralMap[affCode]].AffiliateBalance += token.mul(priceNow).div(uint256(10000)).mul(ReferralRatio); 
        }
        
        if(ReferralThreshold > accounts[addr].Tokens && ReferralThreshold <= (accounts[addr].Tokens.add(token)))
            ReferralActivated(addr);
        //
        accounts[addr].lastDividendPoints = totalDividendPoints.sub((totalDividendPoints.sub(accounts[addr].lastDividendPoints))*(accounts[addr].Tokens.div(accounts[addr].Tokens.add(token))));
        accounts[addr].Tokens += token;
        amountSold += token;

        salesRecord.push(salesHistory(addr,token,now));
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
            accounts[salesRecord[i].addr].lastDividendPoints = totalDividendPoints.sub((totalDividendPoints.sub(accounts[salesRecord[i].addr].lastDividendPoints)).mul(accounts[salesRecord[i].addr].Tokens).div(accounts[salesRecord[i].addr].Tokens.sub(salesRecord[i].Tokens)));
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
        accounts[customer].ID = uint32(amountPlayer);
        //accounts[customer].Balance = 0;
        //accounts[customer].AffiliateBalance = 0;
        //accounts[customer].Tokens = 0;
        //accounts[customer].Validated = true;
        //accounts[customer].ReferralCode = 0x0000000000000000;
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
    accountExisted(msg.sender)
    isHuman()
    updateAccount(msg.sender)
    {   
        address Addr = msg.sender;
        uint256 BalanceWithdraw = accounts[Addr].Balance.add(accounts[Addr].AffiliateBalance);
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
            totalDividendPoints += (ethReceived.sub(thisTimeMaintainFee));
            unclaimedDividends += (ethReceived.sub(thisTimeMaintainFee));
            lastMaintenanceTime = now;
        }
        else{
            lastMaintenanceTime += ethReceived.div(amountSold).div(MaintenanceFee);
            maintenanceDividends += ethReceived;
        }
        emit eventDivideProfit(msg.sender,ethReceived,thisTimeMaintainFee,now);
    }
      
    uint256 pointMultiplier = 10e18;
    
    function dividends(address addr) private view returns(uint256) {
      uint256 newDividend = (totalDividendPoints.sub(accounts[addr].lastDividendPoints)).mul(accounts[addr].Tokens);
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