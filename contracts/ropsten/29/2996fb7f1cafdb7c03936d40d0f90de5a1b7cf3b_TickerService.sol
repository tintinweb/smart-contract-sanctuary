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

/**
 * @title 预留token服务实现
 */
contract TickerService is ITickerService, ServiceHelper, Pausable {

    using SafeMath for uint256;
    using StringUtil for string;

    // 过期限制
    uint256 public expiredLimit;
    // 注册费用
    uint256 public registrationFee;    

    struct SymbolDetails {
        address issuer; // 发行者地址
        uint256 registerTimestamp; // 注册时间戳
        uint256 expiredTimestamp; // 过期时间戳
        string tokenName; // token名
        bool status; // 是否校验  true-已校验
    }

    // 已注册Symbol Map
    mapping(string => SymbolDetails) registerSymbols;

    // 事件：注册symbol
    event LogRegisterTicker(address indexed _issuer, string _symbol, string _tokenName, uint256 indexed _registerTimestamp, uint256 indexed _expiredTimestamp );
    // 事件：修改过期时间限制
    event LogChangeExpiredLimit(uint256 _oldExpiredLimit, uint256 _newExpiredLimit);
    // 事件：修改注册费用
    event LogChangeRegistrationFee(uint256 _oldRegistrationFee, uint256 _newRegistrationFee);

    /**
     * @notice 构造器
     * @param _servicesStorageAddress 服务存储地址
     * @param _expiredLimit 过期限制(根据网络id部署时确定)
     * @param _registrationFee 注册费用
     */
    constructor(address _servicesStorageAddress, uint256 _expiredLimit, uint256 _registrationFee) public ServiceHelper(_servicesStorageAddress) {
        expiredLimit = _expiredLimit * 1 days;
        
        registrationFee = _registrationFee;
    }

    /**
     * @notice 注册ticker
     * @param _issuer 发行者地址
     * @param _symbol token符号
     * @param _tokenName token名
     */
    function registerTicker(address _issuer, string memory _symbol, string memory _tokenName) public whenNotPaused {
        // 发行者地址不能为0
        require(_issuer != address(0), "Invalid address");
        // symbol符号限制：0-10字符
        require(_symbol.length() > 0 && _symbol.length() <= 10, "Ticker length should always between 0 & 10");
        // 如果设置了注册费用，进行扣款
        if(registrationFee > 0){
            require((IERC20(platformTokenAddress).transferFrom(msg.sender, address(this), registrationFee)), "Failed transferFrom because of sufficent Allowance is not provided");
        }
        // 将Symbol转为大写
        string memory symbol = _symbol.upper();

        // symbol过期检查（该symbol是否处于可用状态）
        require(expiredCheck(symbol), "Ticker is already reserved");

        // 注册时间戳
        uint256 registerTimestamp = now;

        // 过期时间戳
        uint256 expiredTimestamp = registerTimestamp.add(expiredLimit);
        
        // 设置symbol注册信息
        registerSymbols[symbol] = SymbolDetails(_issuer, registerTimestamp, expiredTimestamp, _tokenName, false);

        emit LogRegisterTicker(_issuer, symbol, _tokenName, registerTimestamp, expiredTimestamp);
    }

    /**
     * @notice 检查ticker是否已经存在
     * @return 如果返回true，则已存在，反之，false表示不存在
     */
    function checkTickerExists(string memory _symbol) public view returns(bool) {
        // 将symbol转为大写
        string memory symbol = _symbol.upper();

        if(registerSymbols[symbol].expiredTimestamp > now  ||  registerSymbols[symbol].status == true){ // 说明已验证过
            return true;
        }else{
            return false;
        }
    }


    /**
     * @notice 过期检查
     * @return 返回true，可用状态，false，不可用状态
     */
    function expiredCheck(string memory _symbol) internal returns(bool) {
        // 该Symbol已经存在
        if (registerSymbols[_symbol].issuer != address(0)) {
            // 判断Symbol是否已经过期
            if (now > registerSymbols[_symbol].expiredTimestamp && registerSymbols[_symbol].status == false) {
                // 重置symbol信息
                registerSymbols[_symbol] = SymbolDetails(address(0), uint256(0), uint256(0), "", false);
                return true;
            }else{
                return false;
            }
        }
        return true;
    }

    /**
     * @notice 生成token时，校验是否与注册时的信息匹配（发行者地址，未过期，token符号）
     * @return 
     */
    function checkValidity(string memory _symbol, address _owner, string memory _tokenName) public returns(bool) {
        // 将symbol转为大写
        string memory symbol = _symbol.upper();
        // 判断调用者
        require(msg.sender == securityTokenServiceAddress, "msg.sender should be SecurityTokenRegistry contract");
        // 校验与之前的预留token是否匹配
        require(registerSymbols[symbol].status != true, "Symbol status should not equal to true");
        require(registerSymbols[symbol].issuer == _owner, "Owner of the symbol should matched with the requested issuer address");
        require(registerSymbols[symbol].expiredTimestamp >= now, "Ticker should not be expired");
        registerSymbols[symbol].tokenName = _tokenName;
        registerSymbols[symbol].status = true;
        return true;
    }

    /**
     * @notice 获取预留ticker详情
     * @param _symbol token符号
     */
    function getTickerDetail(string memory _symbol) public view returns(address _issuer, uint256 _registerTimestamp, uint256 _expiredTimestamp, 
    string memory _tokenName, bool _status) {

        // 将symbol转为大写
        string memory symbol = _symbol.upper();


        if(registerSymbols[symbol].status == true || registerSymbols[symbol].expiredTimestamp > now){
            return (
                registerSymbols[symbol].issuer,
                registerSymbols[symbol].registerTimestamp,
                registerSymbols[symbol].expiredTimestamp,
                registerSymbols[symbol].tokenName,
                registerSymbols[symbol].status
            );
        }else{
            return (address(0), uint256(0),uint256(0), "", false);
        }
    }

    /**
     * @notice 修改过期时间
     * @param _expired 过期时间
     */
    function changeExpiredLimit(uint256 _expired) public onlyOwner {
        require(_expired >= 1 days, "Expiry should greater than or equal to 1 day");
        uint256 oldExpiredLimit = expiredLimit;
        expiredLimit = _expired;
        emit LogChangeExpiredLimit(oldExpiredLimit, _expired);
    }

    /**
     * @notice 修改注册费用
     * @param _registrationFee 注册费用
     */
    function changeRegistrationFee(uint256 _registrationFee) public onlyOwner {
        require(registrationFee != _registrationFee, "Should not equal");
        uint256 newRegistrationFee = _registrationFee * 10 ** uint256(18);
        emit LogChangeRegistrationFee(registrationFee, newRegistrationFee);
        registrationFee = newRegistrationFee;
    }
    
}