pragma solidity ^0.5.0;

/**
 * @title 注册token符号服务
 */
contract ITickerService {

    /**
     * @notice 校验symbol是否合法（生成token时的信息是否匹配注册时的信息）
     * @param _symbol token符号
     * @param _owner 发行者地址
     * @param _tokenName token名
     */
    function checkValidity(string memory _symbol, address _owner, string memory _tokenName) public returns(bool);

    /**
     * @notice 获取已注册token的信息
     * @param _symbol token符号
     * @return _issuer 发行者地址
     * @return _registerTimestamp 注册时间
     * @return _expiredTimestamp 过期时间
     * @return _tokenName token名称
     * @return _status 注册状态
     */
    function getTickerDetail(string memory _symbol) public view returns(address _issuer, uint256 _registerTimestamp, uint256 _expiredTimestamp, string memory _tokenName, bool _status);

    /**
     * @notice 检查token符号是否已经存在
     * @param _symbol token符号
     */
    function checkTickerExists(string memory _symbol) public view returns(bool);
}

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

/**
 * @title 编码工具类
 */
library EncoderUtil {

    /**
     * @notice 将字符串进行编码
     */
    function encode(string memory _str) public pure returns(bytes32) {
        require(bytes(_str).length != 0, "Encode value must not empty");
        return keccak256(abi.encodePacked(_str));
    }

    /**
     * @notice 将地址进行编码
     */
    function encode(address _addr) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }
}

/**
 * @title 服务存储器
 */
contract ServiceStorage is Ownable {

    /**
     * @notice 服务map
     */
    mapping(bytes32 => address) public serviceMap;

    /**
     * @notice 服务存储器修改事件
     */
    event LogServiceStorageUpdate(string _key, address _oldValue, address _newValue);

    /**
     * @notice 根据key值获取到对应的地址
     */
    function get(string memory _key) public view returns(address){
        bytes32 key = EncoderUtil.encode(_key);
        require(serviceMap[key] != address(0), "No result");
        return serviceMap[key];
    }

    /**
     * @notice 以key—value的形式存储到存储器中
     */
    function update(string memory _key, address _value) public onlyOwner {
        bytes32 key = EncoderUtil.encode(_key);
        emit LogServiceStorageUpdate(_key, serviceMap[key], _value);
        serviceMap[key] = _value;
    }

}

/**
 * @title 服务helper：从ServiceStorage加载存储的地址
 */
contract ServiceHelper is Ownable {

    address public servicesStorageAddress;
    address public moduleServiceAddress;
    address public securityTokenServiceAddress;
    address public tickerServiceAddress;
    address public platformTokenAddress;

    ServiceStorage serviceStorage;

    constructor (address _servicesStorageAddress) public {
        require(_servicesStorageAddress != address(0), "Invlid address");
        servicesStorageAddress = _servicesStorageAddress;
        serviceStorage = ServiceStorage(_servicesStorageAddress);
    }

    function loadData() public onlyOwner {
        moduleServiceAddress = serviceStorage.get("moduleService");
        securityTokenServiceAddress = serviceStorage.get("securityTokenService");
        tickerServiceAddress = serviceStorage.get("tickerService");
        platformTokenAddress = serviceStorage.get("platformToken");
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
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    
    function allowance(address _owner, address _spender) public view returns (uint256);

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
    function getModuleByName(uint8 _moduleType, bytes memory _name) public view returns (bytes32, address);

    /**
     * @notice 获取投资者人数
     */
    function getInvestorsLength() public view returns(uint256);

    
}

/**
 * @title 模块服务接口
 */
contract IModuleService {
    
    function useModule(address _moduleFactoryAddress) external;

    
    function registerModule(address _moduleFactoryAddress) external returns(bool);

   
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[] memory);
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

    function getSig(bytes memory _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint32(uint32(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i)))));
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

    /**
     * @notice 暂停模块
     */
    function pause() public onlyOwner {
        super.pause();
    }

    /**
     * @notice 恢复模块
     */
    function unpause() public onlyOwner {
        super.unpause();
    }
}

/**
 * @dev 权限管理接口
 */
contract IPermissionManager {

    /**
     * @dev 检查权限
     */
    function checkPermission(address _delegateAddress, address _moduleAddress, bytes32 _perm) public view returns(bool);

    /**
     * @dev 修改权限
     */
    function changePermission(address _delegateAddress, address _moduleAddress, bytes32 _perm, bool _valid) public returns(bool);

    /**
     * @dev 获取委托详情
     */
    function getDelegateDetails(address _delegateAddress) public view returns(bytes32);

}

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d1a3b4bcb2be91e3">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /**
      * @dev We use a single lock for the whole contract.
      */
    bool private reentrancyLock = false;

    /**
      * @dev Prevents a contract from calling itself, directly or indirectly.
      * @notice If you mark a function `nonReentrant`, you should also
      * mark it `external`. Calling one nonReentrant function from
      * another is not supported. Instead, you can implement a
      * `private` function doing the actual work, and a `external`
      * wrapper marked as `nonReentrant`.
      */
    modifier nonReentrant() {
        require(!reentrancyLock, "Invlid status");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title 字符串工具类
 */
library StringUtil {

    /**
     * @notice 将字符串转为小写
     * @param _base 字符串
     */
    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for(uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x41 && b1 <= 0x5A) {
                b1 = bytes1(uint8(b1)+32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

    /**
     * @notice 将字符串转为大写
     * @param _base 字符串
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1)-32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

    /**
     * @notice 获取字符串的长度
     * @param _base 字符串
     */
    function length(string memory _base) internal pure returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * @notice 比较字符串
     * @param _str1 第一个字符串
     * @param _str2 第二个字符串
     */
    function compare(string memory _str1, string memory _str2) internal pure returns(bool){
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }

    /**
     * @notice Changes the string into bytes32
     * @param _source String that need to convert into bytes32
     */
    /// Notice - Maximum Length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function stringToBytes32(string memory _source) internal pure returns (bytes32) {
        return bytesToBytes32(bytes(_source), 0);
    }

    /**
     * @notice Changes bytes into bytes32
     * @param _b Bytes that need to convert into bytes32
     * @param _offset Offset from which to begin conversion
     */
    /// Notice - Maximum length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function bytesToBytes32(bytes memory _b, uint _offset) internal pure returns (bytes32) {
        bytes32 result;

        for (uint i = 0; i < _b.length; i++) {
            result |= bytes32(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return result;
    }

    /**
     * @notice Changes the bytes32 into string
     * @param _source that need to convert into string
     */
    function bytes32ToString(bytes32 _source) internal pure returns (string memory result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_source) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint8 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function getSig(bytes memory _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint32(uint32(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i)))));
        }
    }

}

/**
 * @dev Security Token实现
 */
contract SecurityToken is ISecurityToken, ReentrancyGuard, ServiceHelper {

    using SafeMath for uint256;

    // 用于中断所有的交易
    bool public freeze = false;

    struct ModuleData {
        bytes32 name; // 模块名
        address moduleAddress; // 模块地址
    }

    // 是否已完成发行者挖矿
    bool public finishedIssuerMinting = false;
    // 是否已完成STO挖矿
    bool public finishedSTOMinting = false;

    mapping (bytes4 => bool) transferFunctions;

    // Map<模块类型，模块数据> 已添加的模块
    mapping (uint8 => ModuleData[]) public modules;

    // 最大附加模块的限制
    uint8 public constant MAX_MODULES = 20;

    mapping (address => bool) public investorListed;

    /**
     * @notice 添加模块事件
     * @param _type 模块的类型
     * @param _moduleName 模块名
     * @param _moduleFactoryAddress 模块工厂地址
     * @param _moduleAddress 模块地址
     * @param _moduleCost 附加模块费用
     * @param _budget 预算
     * @param _timestamp 模块添加时间戳
     */
    event LogModuleAdded(
        uint8 indexed _type,
        bytes32 _moduleName,
        address _moduleFactoryAddress,
        address _moduleAddress,
        uint256 _moduleCost,
        uint256 _budget,
        uint256 _timestamp
    );

    // 事件：修改token详情
    event LogUpdateTokenDetails(string _oldDetails, string _newDetails);
    // 事件：修改粒度
    event LogGranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // 事件：模块移除
    event LogModuleRemoved(uint8 indexed _type, address _module, uint256 _timestamp);
    // 事件：修改分配给模块的预算
    event LogModuleBudgetChanged(uint8 indexed _moduleType, address _module, uint256 _budget);
    // 事件：暂停转移
    event LogFreezeTransfers(bool _freeze, uint256 _timestamp);
    // 事件：
    // Emit when new checkpoint created
    event LogCheckpointCreated(uint256 indexed _checkpointId, uint256 _timestamp);
    // 事件：完成发行者挖矿
    event LogFinishMintingIssuer(uint256 _timestamp);
    // 事件：完成STO挖矿
    event LogFinishMintingSTO(uint256 _timestamp);
    // Change the STR address in the event of a upgrade
    event LogChangeSTRAddress(address indexed _oldAddress, address indexed _newAddress);

    modifier onlyModule(uint8 _moduleType, bool _fallback) {

        bool isModuleType = false;
        for (uint8 i = 0; i < modules[_moduleType].length; i++) {
            isModuleType = isModuleType || (modules[_moduleType][i].moduleAddress == msg.sender);
        }
        if (_fallback && !isModuleType) {
            if (_moduleType == STO_KEY)
                require(modules[_moduleType].length == 0 && msg.sender == owner, "Sender is not owner or STO module is attached");
            else
                require(msg.sender == owner, "Sender is not owner");
        } else {
            require(isModuleType, "Sender is not correct module type");
        }
        _;
    }

    // 检查可分割性
    modifier checkGranularity(uint256 _amount) {
        require(_amount % granularity == 0, "Unable to modify token balances at this granularity");
        _;
    }

    modifier isMintingAllowed() {
        if (msg.sender == owner) {
            require(!finishedIssuerMinting, "Minting is finished for Issuer");
        } else {
            require(!finishedSTOMinting, "Minting is finished for STOs");
        }
        _;
    }

    /**
     * @notice 构造器
     * @param _tokenName token名
     * @param _symbol token符号
     * @param _decimals token小数位
     * @param _granularity token粒度（可分割性）
     * @param _tokenDetails token详情（外部链接）
     * @param _servicesStorageAddress 服务存储地址
     */
    constructor (
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string memory _tokenDetails,
        address _servicesStorageAddress
    )
    public
    IERC20Detail(_tokenName, _symbol, _decimals)
    ServiceHelper(_servicesStorageAddress)
    {
        loadData();
        tokenDetails = _tokenDetails;
        granularity = _granularity;
        transferFunctions[bytes4(keccak256("transfer(address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("transferFrom(address,address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("mint(address,uint256)"))] = true;
        transferFunctions[bytes4(keccak256("burn(uint256)"))] = true;
    }

    function addModule(
        address _moduleFactoryAddress,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget
    ) external onlyOwner nonReentrant {
        _addModule(_moduleFactoryAddress, _data, _maxCost, _budget);
    }

    /**
     * @dev 添加模块内部方法
     * @param _moduleFactoryAddress 模块工厂地址
     * @param _data 模块数据
     * @param _maxCost 模块费用
     * @param _budget 预算
     */
    function _addModule(address _moduleFactoryAddress, bytes memory _data, uint256 _maxCost, uint256 _budget) internal {

        IModuleService(moduleServiceAddress).useModule(_moduleFactoryAddress);

        // 模块工程实例
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactoryAddress);
        // 获取到模块的类型
        uint8 moduleType = moduleFactory.getType();

        // 判断已经添加模块是否达到最大数
        require(modules[moduleType].length < MAX_MODULES, "Limit of MAX MODULES is reached");

        // 获取设置模块费用
        uint256 moduleCost = moduleFactory.setupCost();

        require(moduleCost <= _maxCost, "Max Cost is always be greater than module cost");

        // 授权转账金额
        require(IERC20(platformTokenAddress).approve(_moduleFactoryAddress, moduleCost), "Not able to approve the module cost");
        
        // 创建模块
        address moduleAddress = moduleFactory.create(_data);

        require(IERC20(platformTokenAddress).approve(moduleAddress, _budget), "Not able to approve the budget");
        
        // 获取到工厂名
        bytes32 moduleName = moduleFactory.getName();

        // 添加到模块map中
        modules[moduleType].push(ModuleData(moduleName, moduleAddress));

        // 发出模块添加事件
        emit LogModuleAdded(moduleType, moduleName, _moduleFactoryAddress, moduleAddress, moduleCost, _budget, now);
    }

    /**
     * @dev 移除模块
     * @param _moduleType 模块类型
     * @param _moduleIndex 模块索引
     */
    function removeModule(uint8 _moduleType, uint8 _moduleIndex) external onlyOwner {

        require(_moduleIndex < modules[_moduleType].length,"Module index doesn&#39;t exist as per the choosen module type");
        require(modules[_moduleType][_moduleIndex].moduleAddress != address(0), "Module contract address should not be 0x");
        
        emit LogModuleRemoved(_moduleType, modules[_moduleType][_moduleIndex].moduleAddress, now);
        modules[_moduleType][_moduleIndex] = modules[_moduleType][modules[_moduleType].length - 1];
        modules[_moduleType].length = modules[_moduleType].length - 1;
    }

    /**
     * @dev 获取模块数据
     * @param _moduleType 模块类型
     * @param _moduleIndex 模块索引
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address) {
        if (modules[_moduleType].length > 0) {
            return (
                modules[_moduleType][_moduleIndex].name,
                modules[_moduleType][_moduleIndex].moduleAddress
            );
        } else {
            return ("", address(0));
        }

    }

    /**
     * @dev 根据模块名获取模块数据
     * @param _moduleType 模块类型
     * @param _name 模块名
     */
    function getModuleByName(uint8 _moduleType, bytes memory _name) public view returns (bytes32, address) {
        if (modules[_moduleType].length > 0) {
            for (uint256 i = 0; i < modules[_moduleType].length; i++) {
                if (keccak256(abi.encodePacked((modules[_moduleType][i].name))) == keccak256(abi.encodePacked(_name))) {
                  return (
                      modules[_moduleType][i].name,
                      modules[_moduleType][i].moduleAddress
                  );
                }
            }
            return ("", address(0));
        } else {
            return ("", address(0));
        }
    }

    function withdrawPoly(uint256 _amount) public onlyOwner {
        require(IERC20(platformTokenAddress).transfer(owner, _amount), "In-sufficient balance");
    }

    /**
     * @notice 修改模块的预算
     * @param _moduleType 模块的类型
     * @param _moduleIndex 模块的索引
     * @param _budget 预算
     */
    function changeModuleBudget(uint8 _moduleType, uint8 _moduleIndex, uint256 _budget) public onlyOwner {
        require(_moduleType != 0, "Module type cannot be zero");
        require(_moduleIndex < modules[_moduleType].length, "Incorrrect module index");
        uint256 _currentAllowance = IERC20(platformTokenAddress).allowance(address(this), modules[_moduleType][_moduleIndex].moduleAddress);
        if (_budget < _currentAllowance) {
            require(IERC20Extend(platformTokenAddress).decreaseApproval(modules[_moduleType][_moduleIndex].moduleAddress, _currentAllowance.sub(_budget)), "Insufficient balance to decreaseApproval");
        } else {
            require(IERC20Extend(platformTokenAddress).increaseApproval(modules[_moduleType][_moduleIndex].moduleAddress, _budget.sub(_currentAllowance)), "Insufficient balance to increaseApproval");
        }
        emit LogModuleBudgetChanged(_moduleType, modules[_moduleType][_moduleIndex].moduleAddress, _budget);
    }

    /**
     * @notice 更新token详情（外部链接）
     */
    function updateTokenDetails(string memory _newTokenDetails) public onlyOwner {
        emit LogUpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }

    /**
     * @notice 修改粒度（可分割性）
     */
    function changeGranularity(uint256 _granularity) public onlyOwner {
        require(_granularity != 0, "Granularity can not be 0");
        emit LogGranularityChanged(granularity, _granularity);
        granularity = _granularity;
    }

    /**
     * @notice 追踪token的拥有者
     */
    function adjustInvestorCount(address _from, address _to, uint256 _value) internal {
        if ((_value == 0) || (_from == _to)) {
            return;
        }
        // 检查是否是新的投资者
        if ((balanceOf(_to) == 0) && (_to != address(0))) {
            investorCount = investorCount.add(1);
        }
        // 检查发送者是否发送了全部的token
        if (_value == balanceOf(_from)) {
            investorCount = investorCount.sub(1);
        }
        if (!investorListed[_to] && (_to != address(0))) {
            investors.push(_to);
            investorListed[_to] = true;
        }
    }

    /**
     * @notice 获取投资者人数（包括了STO发行前的股东挖矿）
     */
    function getInvestorsLength() public view returns(uint256) {
        return investors.length;
    }

    /**
     * @notice 冻结所有的交易
     */
    function freezeTransfers() public onlyOwner {
        require(!freeze);
        freeze = true;
        emit LogFreezeTransfers(freeze, now);
    }

    /**
     * @notice 解冻所有的交易
     */
    function unfreezeTransfers() public onlyOwner {
        require(freeze);
        freeze = false;
        emit LogFreezeTransfers(freeze, now);
    }

    /**
     * @notice 重写 transfer 方法
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        adjustInvestorCount(msg.sender, _to, _value);
        require(verifyTransfer(msg.sender, _to, _value), "Transfer is not valid");
        require(super.transfer(_to, _value));
        return true;
    }

    /**
     * @notice 重写 transferFrom 方法
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        adjustInvestorCount(_from, _to, _value);
        require(verifyTransfer(_from, _to, _value), "Transfer is not valid");
        require(super.transferFrom(_from, _to, _value));
        return true;
    }

    /**
     * @notice 验证转移：此ST附加的转移模块
     */
    function verifyTransfer(address _from, address _to, uint256 _amount) public checkGranularity(_amount) returns (bool) {
        // 如果交易未暂停
        if (!freeze) {
            bool isTransfer = false;
            if (transferFunctions[getSig(msg.data)]) {
              isTransfer = true;
            }
            // 判断是否附加了转移模块 TRANSFERMANAGER_KEY = 2
            if (modules[TRANSFERMANAGER_KEY].length == 0) {
                return true;
            }
            bool isInvalid = false;
            bool isValid = false;
            bool isForceValid = false;
            for (uint8 i = 0; i < modules[TRANSFERMANAGER_KEY].length; i++) {
                // 逐个验证转移是否可行
                ITransferManager.Result valid = ITransferManager(modules[TRANSFERMANAGER_KEY][i].moduleAddress).verifyTransfer(_from, _to, _amount, isTransfer);
                if (valid == ITransferManager.Result.INVALID) {
                    isInvalid = true;
                }
                if (valid == ITransferManager.Result.VALID) {
                    isValid = true;
                }
                if (valid == ITransferManager.Result.FORCE_VALID) {
                    isForceValid = true;
                }
            }
            return isForceValid ? true : (isInvalid ? false : isValid);
      }
      return false;
    }

    /**
     * @notice 完成发行者挖矿
     */
    function finishMintingIssuer() public onlyOwner {
        finishedIssuerMinting = true;
        emit LogFinishMintingIssuer(now);
    }

    /**
     * @notice 完成STO挖矿
     */
    function finishMintingSTO() public onlyOwner {
        finishedSTOMinting = true;
        emit LogFinishMintingSTO(now);
    }

    /**
     * @notice 批量挖矿
     */
    function mintMulti(address[] memory _investors, uint256[] memory _amounts) public onlyModule(STO_KEY, true) returns (bool success) {
        require(_investors.length == _amounts.length, "Mis-match in the length of the arrays");
        for (uint256 i = 0; i < _investors.length; i++) {
            mint(_investors[i], _amounts[i]);
        }
        return true;
    }

    /**
     * @notice 挖矿
     * @param _investor 投资者
     * @param _amount 数量
     */
    function mint(address _investor, uint256 _amount) public onlyModule(STO_KEY, true) checkGranularity(_amount) isMintingAllowed() returns (bool success) {
        require(_investor != address(0), "Investor address should not be 0x");
        adjustInvestorCount(address(0), _investor, _amount);

        require(verifyTransfer(address(0), _investor, _amount), "Transfer is not valid");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_investor] = balances[_investor].add(_amount);

        emit LogMint(_investor, _amount);
        emit Transfer(address(0), _investor, _amount);
        return true;
    }

    /**
     * @notice 检查权限
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool) {
        if (modules[PERMISSIONMANAGER_KEY].length == 0) {
            return false;
        }

        for (uint8 i = 0; i < modules[PERMISSIONMANAGER_KEY].length; i++) {
            if (IPermissionManager(modules[PERMISSIONMANAGER_KEY][i].moduleAddress).checkPermission(_delegate, _module, _perm)) {
                return true;
            }
        }
    }

    function getSig(bytes memory _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint32(uint32(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i)))));
        }
    }
}

/**
 * @title Security Token 工厂
 */
contract ISTFactory {

    /**
     * @notice 创建Token
     * @param _tokenName token名
     * @param _symbol token符号
     * @param _decimals 精度
     * @param _tokenDetails token详情（外部链接）
     * @param _issuer 发行者地址
     * @param _divisible 是否可分拨
     * @param _servicesStorageAddress 服务存储地址
     * @return 创建的ST地址
     */
    function createToken(
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals, 
        string memory _tokenDetails, 
        address _issuer, 
        bool _divisible, 
        address _servicesStorageAddress)
        public returns (address);
}

/**
 * @title Security Token服务接口
 */
contract ISecurityTokenService {

    struct SecurityTokenData {
        string symbol; // token符号
        string tokenName; // token名
        uint256 issuanceTimestamp; // 发行时间戳
        string tokenDetails; // token详情链接
    }

    // securityToken映射（securityToken地址 =》 securityTokenData）
    mapping(address => SecurityTokenData) securityTokens;

    // 符号映射（符号 =》 token地址）
    mapping(string => address) symbols;

    /**
     * @notice 生成security token
     * @param _tokenName token名
     * @param _symbol token符号
     * @param _tokenDetails token详情，外部链接地址
     * @param _divisible token是否可分割
     */
    function generateSecurityToken(string memory _tokenName, string memory _symbol, string memory _tokenDetails, bool _divisible) public;

    /**
     * @notice 根据symbol获取到token地址
     * @param _symbol token符号
     */
    function getSecurityTokenAddress(string memory _symbol) public view returns (address);

    /**
     * @notice 根据security token地址获取 security token数据
     * @param _securityTokenAddress st地址
     * @return tokenName token名
     * @return symbol token符号
     * @return issuanceTimestamp 发行时间戳
     * @return tokenDetails token详情链接
     * @return owner 发行者
     */
    function getSecurityTokenData(address _securityTokenAddress) public view returns (string memory, string memory, uint256, string memory, address);
    
    /**
     * @notice 判断某个地址是否是SecurityToken
     * @param _securityTokenAddress st地址
     */
    function isSecurityToken(address _securityTokenAddress) public view returns (bool);
}

/**
 * @notice SecurityToken服务
 */
contract SecurityTokenService is ISecurityTokenService, Pausable, ServiceHelper {

    using StringUtil for string;

    // 注册费用
    uint256 public registrationFee;

    // 创建ST的工厂地址
    address public stFactoryAddress;

    // 事件：修改生成费用
    event LogChangeRegistrationFee(uint256 _oldFee, uint256 _newFee);

    /**
     * @notice 生成token事件
     * @param _tokenName token名
     * @param _tokenSymbol token符号
     * @param _securityTokenAddress token地址
     * @param _issuanceTimestamp 发行时间戳
     * @param _owner 发行者地址
     */
    event LogNewSecurityToken(
        string _tokenName,
        string _tokenSymbol,
        address indexed _securityTokenAddress,
        uint256 _issuanceTimestamp,
        address indexed _owner
    );

    /**
     * @notice 构造函数
     * @param _servicesStorageAddress 服务存储地址
     * @param _registrationFee 生成费用
     */
    constructor (
        address _servicesStorageAddress,
        address _stFactoryAddress,
        uint256 _registrationFee
    )
    public
    ServiceHelper(_servicesStorageAddress)
    {
        stFactoryAddress = _stFactoryAddress;
        registrationFee = _registrationFee;
    }

    /**
     * @notice 生成security token
     * @param _tokenName token名
     * @param _symbol token符号
     * @param _tokenDetails token详情，外部链接地址
     * @param _divisible token是否可分割
     */
    function generateSecurityToken(string memory _tokenName, string memory _symbol, string memory _tokenDetails, bool _divisible) public whenNotPaused {
        
        // 判断token的symbol和name不为空
        require(_tokenName.length() > 0 && _symbol.length() > 0, "Name and Symbol string length should be greater than 0");
        
        // 校验合法性（与注册时的信息比较）
        require(ITickerService(tickerServiceAddress).checkValidity(_symbol, msg.sender, _tokenName), "Trying to use non-valid symbol");

        // 扣除生成费用
        if(registrationFee > 0){
            require(IERC20(platformTokenAddress).transferFrom(msg.sender, address(this), registrationFee), "Failed transferFrom because of sufficent Allowance is not provided");
        }
        // 将symbol转为大写
        string memory symbol = _symbol.upper();
        
        // 通过ST工厂创建token
        address newSecurityTokenAddress = ISTFactory(stFactoryAddress).createToken(
            _tokenName,
            symbol,
            18,
            _tokenDetails,
            msg.sender,
            _divisible,
            servicesStorageAddress
        );

        // 发行时间戳
        // solium-disable-next-line
        uint256 issuanceTimestamp = now;

        // securityTokens  security token address =》 SecurityTokenData
        securityTokens[newSecurityTokenAddress] = SecurityTokenData(symbol, _tokenName, issuanceTimestamp, _tokenDetails);
        // symbols   string =》security token address
        symbols[symbol] = newSecurityTokenAddress;


        // 发出创建Security token事件
        emit LogNewSecurityToken(_tokenName, symbol, newSecurityTokenAddress, issuanceTimestamp, msg.sender);
    }

    /**
     * @notice 设置ST工厂的地址
     */
    function setSTFactory(address _stFactoryAddress) public onlyOwner {
        require(_stFactoryAddress != address(0), "Invalid address!");
        stFactoryAddress = _stFactoryAddress;
    }

    /**
     * @notice 根据symbol获取到token地址
     */
    function getSecurityTokenAddress(string memory _symbol) public view returns (address) {
        string memory symbol = _symbol.upper();
        return symbols[symbol];
    }

    /**
     * @notice 根据security token地址获取 security token数据
     * @param _securityTokenAddress securityToken地址
     * @return tokenName token名
     * @return symbol token符号
     * @return issuanceTimestamp 发行时间戳
     * @return tokenDetails token详情链接
     * @return owner 发行者
     */
    function getSecurityTokenData(address _securityTokenAddress) public view returns (string memory, string memory, uint256, string memory, address) {
        return (
            securityTokens[_securityTokenAddress].tokenName,
            securityTokens[_securityTokenAddress].symbol,
            securityTokens[_securityTokenAddress].issuanceTimestamp,
            securityTokens[_securityTokenAddress].tokenDetails,
            ISecurityToken(_securityTokenAddress).owner()
        );
    }

    /**
     * @notice 判断是否是security token
     */
    function isSecurityToken(address _securityTokenAddress) public view returns (bool) {
        return (keccak256(bytes(securityTokens[_securityTokenAddress].symbol)) != keccak256(""));
    }

    /**
     * @notice 修改注册费用
     */
    function changeRegistrationFee(uint256 _registrationFee) public onlyOwner {
        require(registrationFee != _registrationFee, "Registration fee should not equal to previous");
        emit LogChangeRegistrationFee(registrationFee, _registrationFee);
        registrationFee = _registrationFee;
    }

    function unpause() public onlyOwner  {
        super.pause();
    }

    function pause() public onlyOwner {
        super.unpause();
    }

}