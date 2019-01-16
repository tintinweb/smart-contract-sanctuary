pragma solidity ^0.4.25;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) 
	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) 
	{
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) 
	{
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) 
	{
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract TokenERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )
        public
    {
        totalSupply = initialSupply.mul(10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal
    {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance)
    {
		return balances[_owner];
	}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool success)
    {
        allowed[_from][msg.sender] = allowance(_from, msg.sender).sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining)
    {
		return allowed[_owner][_spender];
	}

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
		allowed[msg.sender][_spender] = oldValue.add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success)
    {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

contract AIOTokenERC20 is TokenERC20(500000000, "AIO Token", "AIOT") {

}