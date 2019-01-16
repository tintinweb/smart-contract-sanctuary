pragma solidity ^0.4.24;
contract UserInterface {
    function getTokens(address) external view returns(uint256);
    function buyTokens_ETH(address,uint256 ,uint256,bytes8) external returns(uint256);
    function buyTokens_Vault(address,uint256,bytes8) external returns(uint256);
    function buyTokens_Address(address,uint256,bytes8) external returns(bool);
    function withdraw(address) external returns(uint256);
}
contract ValidationInterface {
  function getValidated(address _address,uint256 _code) external pure returns (bool);
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
    // checkInventory ro modifier?
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

    event eventByAddress(address,bytes8,uint256,uint256);
    event eventByETH(bytes8,uint256,uint256);
    event eventByVault(bytes8,uint256,uint256);
    event eventWithdraw(uint256,uint256);
    event eventDivideProfit(address,uint256,uint256,uint256);

    address private AdminWallet;
    address private Manager;
    FiatContract public price;
    ValidationInterface public validate;
    UserInterface public user;
    //Validation and Price Contract
    address private ValidationInterfaceAddress;
    address private UserInterfaceAddress;
    address private PriceAddress;
    
    //The hashrate supply(0.001mh/s)
    uint256 public TotalHashRate;
    //The Price of each hashrate (0.001USD)
    uint256 public Price;
    //The Price of ETH(0.001USD)
    uint256 public ETHUSD;
    //Last Update ETHUSD Time
    uint256 public lastUpdateETHUSD;
    //Update ETHUSD Time Interval
    uint256 public IntervalETHUSD;
    //Total Amounts of Sold Hashrate(0.001mh/s)
    uint256 public amountSold;
    //The Coupon ratio (0.01%)
    uint256 public CouponRatio;
    //Total dividends
    uint256 public totalDividendPoints;
    //The Price of maintenance of each hashrate (0.001USD per mh/s per seconds)
    uint256 public MaintenanceFee;
    //maintenanceDividends
    uint256 public maintenanceDividends;
    //Last time for maintenance
    uint256 public lastMaintenanceTime;
    
    
    constructor() public{
        
        AdminWallet = msg.sender;
        Manager = 0x2Af1fFB288e07b3A6EeC0D0478Ff3D46dd6A5663;
        
        ValidationInterfaceAddress = 0xD46b8Da4DB8AA6BcBd8d168BbA9681425001F1F9;
        UserInterfaceAddress = 0x184e689aFc989946D27b2B6b81Ccd9f793605DdE;
        PriceAddress = 0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909;
        //PriceAddress = 0x8055d0504666e2B6942BeB8D6014c964658Ca591; //MainNet
        
        validate = ValidationInterface(ValidationInterfaceAddress);
        price = FiatContract(PriceAddress);
        user = UserInterface(UserInterfaceAddress);
        
        //The hashrate supply(0.001mh/s)
        TotalHashRate = 30000000;
        //The Price of each hashrate (0.001USD)
        Price = 24000;
        //The Coupon ratio (0.01%)
        CouponRatio = 9000;
        //Last Update ETHUSD Time
        lastUpdateETHUSD = 0;
        //Update ETHUSD Time Interval(s)
        IntervalETHUSD = 60;
        //Total Amounts of Sold Hashrate(0.001mh/s)
        amountSold = 0;
        //Total dividends
        totalDividendPoints = 0;
        //The Price of maintenance of each hashrate (0.001USD per mh/s per seconds)
        MaintenanceFee = 12;
        //Last time for maintenance
        lastMaintenanceTime = now;

        getETHUSD();

    }
    

    modifier onlyManager(){
        require(msg.sender == Manager, "its only for manager of ActuralMiner");
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
     

    function getMaintainFee() private view returns(uint256){
        return (now.sub(lastMaintenanceTime)).mul(MaintenanceFee).mul(amountSold).div(ETHUSD);
    }
    
    function getETHUSD() private{
        if((now-lastUpdateETHUSD)>IntervalETHUSD){
            ETHUSD = uint256(10e18).mul(100).div(price.USD(0));
            lastUpdateETHUSD = now;
        }
        //ETHUSD = 400000;
    }
    
    //Buy through ETH
    function buy_ETH(uint256 validationCode,bytes8 affCode) payable public
    {
        getETHUSD();
        uint256 token = user.buyTokens_ETH(msg.sender,msg.value,validationCode,affCode);
        amountSold += token;
        emit eventByETH(affCode,token,now);
    }
    //Buy through Vault
    function buy_Vault(uint256 vaultAmount,bytes8 affCode) public
    {
        getETHUSD();
        uint256 token = user.buyTokens_Vault(msg.sender,vaultAmount,affCode);
        amountSold += token;
        emit eventByVault(affCode,token,now);
        //event
    }
    
    //Buy through USD, only Manager can do this!
    //Bug!! need to check inventory exist or not in advance
    function buyAddress(address addr,bytes8 affCode,uint256 token) public
    onlyManager()
    //returns(uint32)
    {
        getETHUSD();
        user.buyTokens_Address(addr,token,affCode);
        amountSold += token;
        emit eventByAddress(addr,affCode,token,now);
        //event
    }
    
    function withdraw() public
    {   
        address Addr = msg.sender;
        uint256 BalanceWithdraw = user.withdraw(Addr);
        Addr.transfer(BalanceWithdraw);
        emit eventWithdraw(BalanceWithdraw,now);
    }
    
    //Profit from the Pools!
    //issue not enought? what to do
    function () payable public{
        uint256 ethReceived = msg.value;
        uint256 thisTimeMaintainFee = getMaintainFee();
        if(thisTimeMaintainFee<ethReceived){
            maintenanceDividends += thisTimeMaintainFee;
            totalDividendPoints += (ethReceived.sub(thisTimeMaintainFee));
            lastMaintenanceTime = now;
        }
        //Not enough for maintain
        else{
            lastMaintenanceTime += ethReceived.mul(ETHUSD).div(amountSold).div(MaintenanceFee);
            maintenanceDividends += ethReceived;
        }
        emit eventDivideProfit(msg.sender,ethReceived,thisTimeMaintainFee,now);
    }
    
    function kill() external 
    onlyOwner(){
        selfdestruct(AdminWallet);
    }
}