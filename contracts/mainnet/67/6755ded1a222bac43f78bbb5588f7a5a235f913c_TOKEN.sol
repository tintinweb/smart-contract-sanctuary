/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.4.23;

contract IERC20 {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is IERC20 {
    uint256 internal _total_supply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    function totalSupply() public constant returns (uint256 supply) {
        return _total_supply;
    }
}

contract TOKEN is ERC20 {
    string public name;
    uint8 public decimals; 
    string public symbol;
    uint256 public totalSupply;
    address public owner;
    
    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    )
        public
    {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        owner = msg.sender;
    }
    
    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(owner == msg.sender);
        
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
	
	
	 function burn(uint256 amount) public {

        uint256 accountBalance = balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[msg.sender] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

}