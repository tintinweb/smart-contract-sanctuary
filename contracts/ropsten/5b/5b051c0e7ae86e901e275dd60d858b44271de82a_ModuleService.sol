pragma solidity ^0.5.0;

/**
 * @title 模块服务接口
 */
contract IModuleService {
    
    function useModule(address _moduleFactoryAddress) external;

    
    function registerModule(address _moduleFactoryAddress) external returns(bool);

   
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[] memory);
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
 * @title Security Token服务接口
 */
contract ISecurityTokenService {

    struct SecurityTokenData {
        string symbol;
        string tokenDetails;
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
     */
    function getSecurityTokenData(address _securityTokenAddress) public view returns (string memory, address, string memory);
    
    /**
     * @notice 判断某个地址是否是SecurityToken
     * @param _securityTokenAddress st地址
     */
    function isSecurityToken(address _securityTokenAddress) public view returns (bool);
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
        serviceStorage = ServiceStorage(_servicesStorageAddress);
    }

    function loadData() public onlyOwner {
        moduleServiceAddress = serviceStorage.get("moduleService");
        securityTokenServiceAddress = serviceStorage.get("securityTokenService");
        tickerServiceAddress = serviceStorage.get("tickerService");
        platformTokenAddress = serviceStorage.get("platformToken");
    }

}

contract ModuleService is IModuleService, ServiceHelper,  Pausable {

    //  服务映射（工厂地址=》工厂类型）
    mapping (address => uint8) public services;

    // 验证模块映射
    mapping (address => bool) public verified;

    // Mapping used to hold the reputation of the factory
    mapping (address => address[]) public reputation;

    // 模块列表映射（工厂类型=》工厂地址）
    mapping (uint8 => address[]) public moduleList;
    
    // Contains the list of the available tags corresponds to the module type
    mapping (uint8 => bytes32[]) public availableTags;
    
    
    

    // Emit when Module been used by the securityToken
    event LogModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
    // Emit when the Module Factory get registered with the ModuleRegistry contract
    event LogModuleRegistered(address indexed _moduleFactory, address indexed _owner);
    // Emit when the module get verified by the Polymath team
    event LogModuleVerified(address indexed _moduleFactory, bool _verified);

    /**
     * @notice 构造函数
     * @param _servicesStorageAddress 服务存储地址
     */
    constructor (address _servicesStorageAddress) public
        ServiceHelper(_servicesStorageAddress)
    {
    }

    /**
     * @notice 使用模块
     * @param _moduleFactoryAddress 模块工厂地址
     */
    function useModule(address _moduleFactoryAddress) external {

        if (ISecurityTokenService(securityTokenServiceAddress).isSecurityToken(msg.sender)) {

            require(services[_moduleFactoryAddress] != 0, "ModuleFactory type should not be 0");

            require(verified[_moduleFactoryAddress] || (IModuleFactory(_moduleFactoryAddress).owner() == ISecurityToken(msg.sender).owner()),"Module factory is not verified as well as not called by the owner");

            reputation[_moduleFactoryAddress].push(msg.sender);

            emit LogModuleUsed (_moduleFactoryAddress, msg.sender);
        }
    }

    /**
     * @notice 注册模块
     */
    function registerModule(address _moduleFactoryAddress) external returns(bool){

        require(services[_moduleFactoryAddress] == 0, "Module factory should not be pre-registered");

        // 所有工厂类都 继承自 IModuleFactory 接口
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactoryAddress);

        // 工厂类型不能为0
        require(moduleFactory.getType() != 0, "Factory type should not equal to 0");

        // 服务映射[工厂地址] = 工厂类型
        services[_moduleFactoryAddress] = moduleFactory.getType();

        // 模块列表映射[工厂类型] = 工厂地址[]
        moduleList[moduleFactory.getType()].push(_moduleFactoryAddress);

        reputation[_moduleFactoryAddress] = new address[](0);

        emit LogModuleRegistered (_moduleFactoryAddress, moduleFactory.owner());

        return true;
    }

    /**
     * @notice 根据模块类型返回tag
     */
    function getTagByModuleType(uint8 _moduleType) public view returns(bytes32[] memory) {
        return availableTags[_moduleType];
    }

    /**
     * @notice 根据模块类型添加tag
     * @param _moduleType 模块类型
     * @param _tag tag列表
     */
    function addTagByModuleType(uint8 _moduleType, bytes32[] memory _tag) public onlyOwner {
        for (uint8 i = 0; i < _tag.length; i++) {
            availableTags[_moduleType].push(_tag[i]);
        }
    }

    /**
     * @notice 根据模块类型移除tag
     * @param _moduleType 模块类型
     * @param _removedTags 将要被移除的tag数组
     */
    function removeTagByModuleType(uint8 _moduleType, bytes32[] memory _removedTags) public onlyOwner {
        for (uint8 i = 0; i < availableTags[_moduleType].length; i++) {
            for (uint8 j = 0; j < _removedTags.length; j++) {
                if (availableTags[_moduleType][i] == _removedTags[j]) {
                    delete availableTags[_moduleType][i];
                }
            }
        }
    }

    /**
     * @notice 验证模块
     * @param _moduleFactoryAddress 模块工厂的地址
     * @param _verified 验证状态（true，已验证，false，未验证）
     */
    function verifyModule(address _moduleFactoryAddress, bool _verified) external onlyOwner returns(bool) {
        // 判断模块工厂是否已经注册
        require(services[_moduleFactoryAddress] != 0, "Module factory should have been already registered");

        // 设置模块的验证状态
        verified[_moduleFactoryAddress] = _verified;

        // 发出模块验证事件
        emit LogModuleVerified(_moduleFactoryAddress, _verified);
        return true;
    }

    function unpause() public onlyOwner  {
        super.unpause();
    }

    function pause() public onlyOwner {
        super.pause();
    }
}