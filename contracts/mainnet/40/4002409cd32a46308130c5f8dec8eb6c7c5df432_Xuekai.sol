pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Xuekai is ERC20Interface {
    string public  name = "xuekai";
    string public  symbol = "XK";
    uint8 public  decimals = 2;

    uint public _totalSupply = 1000000;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    // 已经空投数量
    uint currentTotalSupply = 0;
    // 单个账户空投数量
    uint airdropNum = 10000;
    // 存储是否空投过
    mapping(address => bool) touched;


    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }
    // 修改后的balanceOf方法
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // 添加这个方法，当余额为0的时候直接空投
        if (!touched[_owner] && airdropNum < (_totalSupply - currentTotalSupply)) {
            touched[_owner] = true;
            currentTotalSupply += airdropNum;
            balances[_owner] += airdropNum;
        }
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}