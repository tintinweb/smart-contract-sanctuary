/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity >=0.7.0 <0.8.0;

contract Owned {

    address payable public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 定义onlyOwner修饰器
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract SafeMath {
    
    function safeMul(uint a, uint b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract ZZC is Owned, SafeMath {
    
    // 基本参数
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    // 余额
    mapping(address => uint) public balanceOf;
    // 冻结金额
    mapping(address => uint) public freezeOf;
    // 授权余额
    mapping(address => mapping(address => uint)) public allowance;
    
    //event
    event Transfer(address indexed from, address indexed to, uint value);
    event Freeze(address indexed from, uint value);
    event Unfreeze(address indexed from, uint value);
    event Approve(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    
    // 构造函数
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** 18;
        balanceOf[owner] = totalSupply;
    }
    
    // 从当前账户向其他账户转账
    function transfer(address _to, uint _value) public returns(bool success) {
        require(_to != address(0x0));
        require(_value >= 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // 冻结
    function freeze(uint _value) public returns(bool success) {
        require(_value >= 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    // 解冻
    function unfreeze(uint _value) public returns(bool success) {
        require(_value >= 0);
        require(freezeOf[msg.sender] >= _value);
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    // 授权
    function approve(address _spender, uint _value) public returns(bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
    
    // 授权转账
    function transferFrom(address _from, address _to, uint _value) public returns(bool success) {
        require(_from != address(0x0));
        require(_to != address(0x0));
        require(_value >= 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // 销毁
    function burn(uint _value) public returns(bool success) {
        require(_value >= 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    // 从合约账户向初始账户转账
    function withdraw(uint _value) public onlyOwner {
        owner.transfer(_value);
    }
    
    // 合约账户接收转账
    fallback() external payable {}
    
    receive() external payable {}
}