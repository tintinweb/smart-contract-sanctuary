pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;imChat&#39; token contract
//
// Symbol      : IMC
// Name        : IMC
// Total supply: 1000,000,000.000000000000000000
// Decimals    : 8
//
// imChat Technology Service Limited
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    
    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

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
        assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract IMCToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address public externalContractAddress;


    /**
     * 构造函数
     */
    constructor() public {
        symbol = "IMC";
        name = "IMC";
        decimals = 8;
        _totalSupply = 1000000000 * (10 ** uint(decimals));
        balances[owner] = _totalSupply;
        
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
     * 查询代币总发行量
     * @return unit 余额
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    /**
     * 查询代币余额
     * @param _owner address 查询代币的地址
     * @return balance 余额
     */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param _from address 发送代币的地址
     * @param _to address 接受代币的地址
     * @param _value uint 接受代币的数量
     */
    function _transfer(address _from, address _to, uint _value) internal{
        // 确保目标地址不为0x0，因为0x0地址代表销毁
        require(_to != 0x0);
        // 检查发送者是否拥有足够余额
        require(balances[_from] >= _value);
        // 检查是否溢出
        require(balances[_to] + _value > balances[_to]);

        // 保存数据用于后面的判断
        uint previousBalance = balances[_from].add(balances[_to]);

        // 从发送者减掉发送额
        balances[_from] = balances[_from].sub(_value);
        // 给接收者加上相同的量
        balances[_to] = balances[_to].add(_value);

        // 通知任何监听该交易的客户端
        emit Transfer(_from, _to, _value);

        // 判断发送、接收方的数据是否和转换前一致
        assert(balances[_from].add(balances[_to]) == previousBalance);
    }

    /**
     * 从主帐户合约调用者发送给别人代币
     * @param _to address 接受代币的地址
     * @param _value uint 接受代币的数量
     * @return success 交易成功
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        // _transfer(msg.sender, _to, _value);

        if (msg.sender == owner) {
            // ERC20合约owner调用
            _transfer(msg.sender, _to, _value);

            return true;
        } else {
            // 外部合约调用，需满足合约调用者和代币合约所设置的外部调用合约地址一致性
            require(msg.sender == externalContractAddress);

            _transfer(owner, _to, _value);

            return true;
        }
    }

    /**
     * 账号之间代币交易转移，调用过程，会检查设置的允许最大交易额
     * @param _from address 发送者地址
     * @param _to address 接受者地址
     * @param _value uint 要转移的代币数量
     * @return success 交易成功
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        
        if (_from == msg.sender) {
            // 自己转账时不需要approve，可以直接进行转账
            _transfer(_from, _to, _value);

        } else {
            // 授权给第三方时，需检查发送者是否拥有足够余额
            require(allowed[_from][msg.sender] >= _value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

            _transfer(_from, _to, _value);

        }

        return true;
    }

    /**
    * 允许帐户授权其他帐户代表他们提取代币
    * @param _spender 授权帐户地址
    * @param _value 代币数量
    * @return success 允许成功
    */
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    * 查询被授权帐户的允许提取的代币数
    * @param _owner 授权者帐户地址
    * @param _spender 被授权者帐户地址
    * @return remaining 代币数量
    */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * 设置允许一个地址（合约）以我（创建交易者）的名义可最多花费的代币数。
     * @param _spender 被授权的地址（合约）
     * @param _value 最大可花费代币数
     * @param _extraData 发送给合约的附加数据
     * @return success 设置成功
     */
    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            // 通知合约
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 设置允许外部合约地址调用当前合约
     * @param _contractAddress 合约地址
     * @return success 设置成功
     */
    function approveContractCall(address _contractAddress) public onlyOwner returns (bool){
        externalContractAddress = _contractAddress;
        
        return true;
    }

    /**
     * 不接收 Ether
     */
    function () public payable {
        revert();
    }
}


// ----------------------------------------------------------------------------
// 发行记录合约
// ----------------------------------------------------------------------------
contract IMCIssuingRecord is Owned{
    using SafeMath for uint;

    // 发行记录添加日志
    event IssuingRecordAdd(uint _date, bytes32 _hash, uint _depth, uint _userCount, uint _token, string _fileFormat, uint _stripLen);

    // 定义IMCToken实例
    IMCToken public imcToken;

    // 平台账户地址
    address public platformAddr;

    // 执行者地址
    address public executorAddress;

    // Token发行统计记录
    struct RecordInfo {
        uint date;  // 记录日期（解锁ID）
        bytes32 hash;  // 文件hash
        uint depth; // 深度
        uint userCount; // 用户数
        uint token; // 发行token数量
        string fileFormat; // 上链存证的文件格式
        uint stripLen; // 上链存证的文件分区
    }
    
    // 分配记录
    mapping(uint => RecordInfo) public issuingRecord;
    
    // 用户数
    uint public userCount;
    
    // 发行总币数
    uint public totalIssuingBalance;
    
    /**
     * 构造函数
     * @param _tokenAddr address ERC20合约地址
     * @param _platformAddr address 平台帐户地址
     */
    constructor(address _tokenAddr, address _platformAddr) public{
        // 初始化IMCToken实例
        imcToken = IMCToken(_tokenAddr);

        // 初始化平台账户地址
        platformAddr = _platformAddr;
        
        // 初始化合约执行者
        executorAddress = msg.sender;
    }
    
    /**
     * 修改platformAddr，只有owner能够修改
     * @param _addr address 地址
     */
    function modifyPlatformAddr(address _addr) public onlyOwner {
        platformAddr = _addr;
    }
    
    /**
     * 修改executorAddress，只有owner能够修改
     * @param _addr address 地址
     */
    function modifyExecutorAddr(address _addr) public onlyOwner {
        executorAddress = _addr;
    }

    /**
     * 转账到中间帐户
     * @param _tokens uint 币数量
     * @return success 交易成功
     */
    function sendTokenToPlatform(uint _tokens) internal returns (bool) {

        imcToken.transfer(platformAddr, _tokens);
        
        return true;
    }

    /**
     * 发行记录添加
     * @param _date uint 记录日期（解锁ID）
     * @param _hash bytes32 文件hash
     * @param _depth uint 深度
     * @param _userCount uint 用户数
     * @param _token uint 发行token数量
     * @param _fileFormat string 上链存证的文件格式
     * @param _stripLen uint 上链存证的文件分区
     * @return success 添加成功
     */
    function issuingRecordAdd(uint _date, bytes32 _hash, uint _depth, uint _userCount, uint _token, string _fileFormat, uint _stripLen) public returns (bool) {
        // 调用者需和Owner设置的执行者地址一致
        require(msg.sender == executorAddress);
        // 防止重复记录
        require(issuingRecord[_date].date != _date);

        // 累计用户数
        userCount = userCount.add(_userCount);

        // 累计发行币数
        totalIssuingBalance = totalIssuingBalance.add(_token);
        
        // 记录发行信息
        issuingRecord[_date] = RecordInfo(_date, _hash, _depth, _userCount, _token, _fileFormat, _stripLen);

        // 转账到中间帐户
        sendTokenToPlatform(_token);

        emit IssuingRecordAdd(_date, _hash, _depth, _userCount, _token, _fileFormat, _stripLen);
        
        return true;
        
    }

}