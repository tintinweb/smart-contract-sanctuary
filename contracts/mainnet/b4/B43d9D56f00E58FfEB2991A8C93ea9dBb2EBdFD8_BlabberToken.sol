pragma solidity 0.4.24;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		assert(c / a == b);

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);

		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);

		return c;
	}
}


interface ERC20Interface {
    function totalSupply() public constant returns (uint256 total);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





contract BlabberToken is ERC20Interface {

	using SafeMath for uint256;

	uint public _totalSupply = 1250000000000000000000000000;

	bool public isLocked = true;
	string public constant symbol = "BLA";
	string public constant name = "BLABBER Token";
	uint8 public constant decimals = 18;

	address public tokenHolder = 0xB6ED8e4b27928009c407E298C475F937054AE19D;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	modifier onlyAdmin{
		require(msg.sender == 0x36Aa9a6E0595adfF3C42A23415758a1123381C23);
		_;
	}

	function unlockTokens() public onlyAdmin {
		isLocked = false;
	}

	constructor() public {
		balances[tokenHolder] = _totalSupply;
	}

	function totalSupply() public constant returns (uint256 total) {
		return _totalSupply;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(
			balances[msg.sender] >= _value
			&& _value > 0
		);

		require(!isLocked || (msg.sender == tokenHolder));

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(
			allowed[_from][msg.sender] >= _value
			&& balances[_from] >= _value
			&& _value > 0
		);

		require(!isLocked || (msg.sender == tokenHolder));

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		emit Transfer(_from, _to, _value);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);

		require(msg.sender == tokenHolder);

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		_totalSupply = _totalSupply.sub(_value);
		emit Burn(burner, _value);
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed burner, uint256 value);
}