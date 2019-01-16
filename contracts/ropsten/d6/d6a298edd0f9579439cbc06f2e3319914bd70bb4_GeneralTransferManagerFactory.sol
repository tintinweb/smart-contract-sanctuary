pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    
    function allowance(address _owner, address _spender) public view returns (uint256);

}

/**
 * @dev 模块工厂接口
 */
contract IModuleFactory is Ownable {

    // 平台Token
    IERC20 public platformToken;
    // 设置花费
    uint256 public setupCost;
    // 使用花费
    uint256 public usageCost;
    // 月订阅花费
    uint256 public monthlySubscriptionCost;

    // 修改工厂设置费用事件
    event LogChangeFactorySetupFee(uint256 _oldSetupcost, uint256 _newSetupCost, address _moduleFactoryAddress);
    // 修改工厂使用费用事件
    event LogChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactoryAddress);
    // 修改工厂订阅费用事件
    event LogChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactoryAddress);
    // 从工厂生成模块事件
    event LogGenerateModuleFromFactory(address _moduleAddress, bytes32 indexed _moduleName, address indexed _moduleFactoryAddress, address _creator, uint256 _timestamp);

   
    /**
     * @dev 构造函数
     * @param _platformTokenAddress 平台token地址
     * @param _setupCost 设置费用
     * @param _usageCost 使用费用
     * @param _subscriptionCost 订阅费用
     */
    constructor (address _platformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public {
        platformToken = IERC20(_platformTokenAddress);
        setupCost = _setupCost;
        usageCost = _usageCost;
        monthlySubscriptionCost = _subscriptionCost;
    }

    function create(bytes calldata _data) external returns(address);

    function getType() public view returns(uint8);

    function getName() public view returns(bytes32);

    function getDescription() public view returns(string memory);

    function getTitle() public view returns(string memory);

    function getInstructions() public view returns (string memory);

    function getTags() public view returns (bytes32[] memory);

    function getSig(bytes memory _data) internal pure returns (bytes32 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes32(uint(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    
    /**
     * @dev 修改设置费用
     * @param _newSetupCost 新的设置费用
     */
    function changeFactorySetupFee(uint256 _newSetupCost) public onlyOwner {
        emit LogChangeFactorySetupFee(setupCost, _newSetupCost, address(this));
        setupCost = _newSetupCost;
    }

    /**
     * @dev 修改使用费用
     * @param _newUsageCost 新的使用费用
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) public onlyOwner {
        emit LogChangeFactoryUsageFee(usageCost, _newUsageCost, address(this));
        usageCost = _newUsageCost;
    }

    /**
     * @dev 修改订阅费用
     * @param _newSubscriptionCost 新的订阅费用
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) public onlyOwner {
        emit LogChangeFactorySubscriptionFee(monthlySubscriptionCost, _newSubscriptionCost, address(this));
        monthlySubscriptionCost = _newSubscriptionCost;
        
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable {

    event Pause(uint256 pauseTime);
    event Unpause(uint256 unpauseTime);

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Should not pause");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Should be pause");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public whenNotPaused {
        paused = true;
        emit Pause(now);
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public whenPaused {
        paused = false;
        emit Unpause(now);
    }
}

contract IERC20Extend is IERC20 {

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);
}

contract IERC20Detail is IERC20 {

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StandardToken is IERC20,IERC20Detail,IERC20Extend {

    using SafeMath for uint256;
    

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address who) public view returns (uint256){
        return balances[who];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool){

        require(to != address(0), "Invalid address");

        require(balances[msg.sender] >= value, "Insufficient tokens transferable");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool){

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0), "Invalid address");
        require(balances[from] >= value, "Insufficient tokens transferable");
        require(allowed[from][msg.sender] >= value, "Insufficient tokens allowable");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    function increaseApproval(address spender, uint256 value) public returns(bool) {

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }

    function decreaseApproval(address spender, uint256 value) public returns(bool){

        uint256 oldApproval = allowed[msg.sender][spender];

        if(oldApproval > value){
            allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(value);
        }else {
            allowed[msg.sender][spender] = 0;
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }
}

/**
 * @title Security Token Exchange Protocol （STEP 1.0）
 */
contract ISTEP is StandardToken {

    string public tokenDetails;

    // 挖矿事件
    event LogMint(address indexed _to, uint256 _amount);

    /**
     * @notice 验证转移
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _amount 金额
     */
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool);

    /**
     * @notice 挖矿
     * @param _investor 投资者地址
     * @param _amount token数量
     */
    function mint(address _investor, uint256 _amount) public returns (bool);

}

contract ISecurityToken is ISTEP, Ownable {
    
    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    
    // 粒度（可分割和不可分割性）
    uint256 public granularity;

    uint256 public investorCount;

    address[] public investors;

    /**
     * @notice 检查权限
     * @param _delegate 委托地址
     * @param _module 模块地址
     * @param _perm 权限符
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);
    
    /**
     * @notice 获取模块
     * @param _moduleType 模块类型
     * @param _moduleIndex 模块索引
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address);

    /**
     * @notice 根据名字获取模块
     * @param _moduleType 模块类型
     * @param _name 模块名
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address);

    /**
     * @notice 获取投资者人数
     */
    function getInvestorsLength() public view returns(uint256);

    
}

/**
 * @title 模块接口
 */
contract IModule {

    // 工厂地址
    address public factoryAddress;

    // ST地址
    address public securityTokenAddress;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    // 平台币
    IERC20 public platformToken;

    /**
     * @notice 构造器
     */
    constructor (address _securityTokenAddress, address _platformTokenAddress) public {
        securityTokenAddress = _securityTokenAddress;
        factoryAddress = msg.sender;
        platformToken = IERC20(_platformTokenAddress);
    }

    function getInitFunction() public pure returns (bytes4);


    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == ISecurityToken(securityTokenAddress).owner();
        bool isFactory = msg.sender == factoryAddress;
        require(isOwner || isFactory || ISecurityToken(securityTokenAddress).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ISecurityToken(securityTokenAddress).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factoryAddress, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == IModuleFactory(factoryAddress).owner(), "Sender is not factory owner");
        _;
    }

    function getPermissions() public view returns(bytes32[] memory);

    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(platformToken.transferFrom(address(this), IModuleFactory(factoryAddress).owner(), _amount), "Unable to take fee");
        return true;
    }
}

/**
 * @dev 交易管理接口
 */
contract ITransferManager is IModule, Pausable {

    //If verifyTransfer returns:
    //  FORCE_VALID, the transaction will always be valid, regardless of other TM results
    //  INVALID, then the transfer should not be allowed regardless of other TM results
    //  VALID, then the transfer is valid for this TM
    //  NA, then the result from this TM is ignored
    enum Result {INVALID, NA, VALID, FORCE_VALID}

    function verifyTransfer(address _from, address _to, uint256 _amount, bool _isTransfer) public returns(Result);

    function unpause() public onlyOwner {
        super.pause();
    }

    function pause() public onlyOwner {
        super.unpause();
    }
}

contract GeneralTransferManager is ITransferManager {

    using SafeMath for uint256;

    // 发行者地址
    address public issuanceAddress = address(0);
    // 签名地址
    address public signingAddress = address(0);

    // 权限标志
    bytes32 public constant WHITELIST = "WHITELIST";
    // 权限标志
    bytes32 public constant FLAGS = "FLAGS";

    struct TimeRestriction {
        uint256 fromTime;
        uint256 toTime;
        uint256 expiryTime;
        bool canBuyFromSTO;
    }


    // 白名单
    mapping (address => TimeRestriction) public whitelist;

    bool public allowAllTransfers = false;
    bool public allowAllWhitelistTransfers = false;
    bool public allowAllWhitelistIssuances = true;
    bool public allowAllBurnTransfers = false;

    event LogChangeIssuanceAddress(address _issuanceAddress);
    event LogAllowAllTransfers(bool _allowAllTransfers);
    event LogAllowAllWhitelistTransfers(bool _allowAllWhitelistTransfers);
    event LogAllowAllWhitelistIssuances(bool _allowAllWhitelistIssuances);
    event LogAllowAllBurnTransfers(bool _allowAllBurnTransfers);
    event LogChangeSigningAddress(address _signingAddress);
    event LogModifyWhitelist(
        address _investor,
        uint256 _dateAdded,
        address _addedBy,
        uint256 _fromTime,
        uint256 _toTime,
        uint256 _expiryTime,
        bool _canBuyFromSTO
    );

    /**
     * @notice 构造函数
     * @param _securityTokenAddress security token地址
     * @param _platformTokenAddress 平台token地址
     */
    constructor (address _securityTokenAddress, address _platformTokenAddress)
    public
    IModule(_securityTokenAddress, _platformTokenAddress)
    {
    }

    /**
     * @notice 返回setData函数的签名
     */
    function getInitFunction() public pure returns (bytes4) {
        return bytes4(0);
    }

    /**
     * @notice 修改发行者的地址
     * @param _issuanceAddress 新的发行者地址
     */
    function changeIssuanceAddress(address _issuanceAddress) public withPerm(FLAGS) {
        issuanceAddress = _issuanceAddress;

        emit LogChangeIssuanceAddress(_issuanceAddress);
    }

    /**
     * @notice 修改签名地址
     * @param _signingAddress 新的签名地址
     */
    function changeSigningAddress(address _signingAddress) public withPerm(FLAGS) {

        signingAddress = _signingAddress;

        emit LogChangeSigningAddress(_signingAddress);
    }

    function changeAllowAllTransfers(bool _allowAllTransfers) public withPerm(FLAGS) {
        allowAllTransfers = _allowAllTransfers;
        emit LogAllowAllTransfers(_allowAllTransfers);
    }

    function changeAllowAllWhitelistTransfers(bool _allowAllWhitelistTransfers) public withPerm(FLAGS) {
        allowAllWhitelistTransfers = _allowAllWhitelistTransfers;
        emit LogAllowAllWhitelistTransfers(_allowAllWhitelistTransfers);
    }

    function changeAllowAllWhitelistIssuances(bool _allowAllWhitelistIssuances) public withPerm(FLAGS) {
        allowAllWhitelistIssuances = _allowAllWhitelistIssuances;

        emit LogAllowAllWhitelistIssuances(_allowAllWhitelistIssuances);
    }

    function changeAllowAllBurnTransfers(bool _allowAllBurnTransfers) public withPerm(FLAGS) {
        allowAllBurnTransfers = _allowAllBurnTransfers;
        emit LogAllowAllBurnTransfers(_allowAllBurnTransfers);
    }

    function verifyTransfer(address _from, address _to, uint256 /*_amount*/, bool /* _isTransfer */) public returns(Result) {
        if (!paused) {
            if (allowAllTransfers) {
                return Result.VALID;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
            }
            if (allowAllBurnTransfers && (_to == address(0))) {
                return Result.VALID;
            }
            if (allowAllWhitelistTransfers) {
                return (onWhitelist(_to) && onWhitelist(_from)) ? Result.VALID : Result.NA;
            }
            if (allowAllWhitelistIssuances && _from == issuanceAddress) {
                if (!whitelist[_to].canBuyFromSTO && isSTOAttached()) {
                    return Result.NA;
                }
                return onWhitelist(_to) ? Result.VALID : Result.NA;
            }
            return ((onWhitelist(_from) && whitelist[_from].fromTime <= now) &&
                (onWhitelist(_to) && whitelist[_to].toTime <= now)) ? Result.VALID : Result.NA;
        }
        return Result.NA;
    }

    /**
     * @notice 修改白名单
     */
    function modifyWhitelist(address _investor, uint256 _fromTime, uint256 _toTime, uint256 _expiryTime, bool _canBuyFromSTO) public withPerm(WHITELIST) {
        whitelist[_investor] = TimeRestriction(_fromTime, _toTime, _expiryTime, _canBuyFromSTO);
        emit LogModifyWhitelist(_investor, now, msg.sender, _fromTime, _toTime, _expiryTime, _canBuyFromSTO);
    }

    /**
     * @notice 批量修改白名单
     */
    function modifyWhitelistMulti(
        address[] memory _investors,
        uint256[] memory _fromTimes,
        uint256[] memory _toTimes,
        uint256[] memory _expiryTimes,
        bool[] memory _canBuyFromSTO
    ) public withPerm(WHITELIST) {
        require(_investors.length == _fromTimes.length, "Mismatched input lengths");
        require(_fromTimes.length == _toTimes.length, "Mismatched input lengths");
        require(_toTimes.length == _expiryTimes.length, "Mismatched input lengths");
        require(_canBuyFromSTO.length == _toTimes.length, "Mismatched input length");
        for (uint256 i = 0; i < _investors.length; i++) {
            modifyWhitelist(_investors[i], _fromTimes[i], _toTimes[i], _expiryTimes[i], _canBuyFromSTO[i]);
        }
    }


    /**
     * @notice 获取到权限标志
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](2);
        allPermissions[0] = WHITELIST;
        allPermissions[1] = FLAGS;
        return allPermissions;
    }

    /**
     * @notice 检查投资人是否在白名单中，以及KYC是否过期
     * @param _investorAddress 投资人的地址
     */
    function onWhitelist(address _investorAddress) internal view returns(bool) {
        return (((whitelist[_investorAddress].fromTime != 0) || (whitelist[_investorAddress].toTime != 0)) &&
            (whitelist[_investorAddress].expiryTime >= now));
    }

    /**
     * @notice SecurityToken是否已附加了STO模块
     */
    function isSTOAttached() internal view returns(bool) {
        address _sto;
        (, _sto) = ISecurityToken(securityTokenAddress).getModule(3, 0);
        if (_sto == address(0))
            return false;
        return true;
    }

}

contract GeneralTransferManagerFactory is IModuleFactory {

    
    constructor (address _platformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public
      IModuleFactory(_platformTokenAddress, _setupCost, _usageCost, _subscriptionCost)
    {

    }

    function create(bytes calldata /* _data */) external returns(address) {

        if (setupCost > 0){
            require(platformToken.transferFrom(msg.sender, owner, setupCost), "Failed transferFrom because of sufficent Allowance is not provided");
        }

        GeneralTransferManager generalTransferManager = new GeneralTransferManager(msg.sender, address(platformToken));

        emit LogGenerateModuleFromFactory(address(generalTransferManager), getName(), address(this), msg.sender, now);

        return address(generalTransferManager);
    }

    function getType() public view returns(uint8) {
        return 2;
    }

    
    function getName() public view returns(bytes32) {
        return "GeneralTransferManager";
    }

    
    function getDescription() public view returns(string memory) {
        return "Manage transfers using a time based whitelist";
    }

    
    function getTitle() public view returns(string memory) {
        return "General Transfer Manager";
    }

    
    function getInstructions() public view returns(string memory) {
        return "Allows an issuer to maintain a time based whitelist of authorised token holders.Addresses are added via modifyWhitelist, and take a fromTime (the time from which they can send tokens) and a toTime (the time from which they can receive tokens). There are additional flags, allowAllWhitelistIssuances, allowAllWhitelistTransfers & allowAllTransfers which allow you to set corresponding contract level behaviour. Init function takes no parameters.";
    }

    
    function getTags() public view returns(bytes32[] memory) {
        bytes32[] memory availableTags = new bytes32[](2);
        availableTags[0] = "General";
        availableTags[1] = "Transfer Restriction";
        return availableTags;
    }


}