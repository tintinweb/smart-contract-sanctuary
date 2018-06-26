pragma solidity ^0.4.18;

contract EuroGoldTest {


	string public name;
	uint8 public decimals;
	string public symbol;

	bool public mintingFinished;

	uint256 public totalSupply;
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed from, uint256 value);
	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	address public owner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner returns (bool) {
		owner = newOwner;
		return true;
	}

	function EuroGoldTest(uint256 _initialSupply) public {
		name = &quot;EuroGoldTest&quot;;
		decimals = 18;
		symbol = &quot;‎€GE&quot;;
		mintingFinished = false;

		totalSupply = _initialSupply * 10 ** uint256(decimals);
		balances[msg.sender] = totalSupply;

		owner = msg.sender;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		if (balances[msg.sender] >= _value  &&  _value > 0) {
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		} else {
			return false;
		}
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
			balances[_to] += _value;
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);
			return true;
		} else {
			return false;
		}
	}

	function balanceOf(address _owner) public constant returns (uint256) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		if (_subtractedValue > allowed[msg.sender][_spender]) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = allowed[msg.sender][_spender] - _subtractedValue;
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function burn(uint256 _value) public returns (bool){
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		totalSupply -= _value;
		Burn(msg.sender, _value);
		return true;
	}

	function burnFrom(address _from, uint256 _value) public returns (bool){
		require(balances[_from] >= _value);
		require(_value <= allowed[_from][msg.sender]);
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		totalSupply -= _value;
		Burn(_from, _value);
		return true;
	}

	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
		totalSupply += _amount;
		balances[_to] += _amount;
		Mint(_to, _amount);
		return true;
	}

	function finishMinting() public onlyOwner returns (bool) {
		mintingFinished = true;
		MintFinished();
		return true;
	}

}