pragma solidity ^ 0.4.19;

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20 {
	function balanceOf(address _owner) constant public returns(uint256 balance);
	function transfer(address _to, uint256 _value) public returns(bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
	function approve(address _spender, uint256 _value) public returns(bool success);
	function allowance(address _owner, address _spender) constant public returns(uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed from, uint256 value);
}

contract StandardToken is ERC20 {
	using SafeMath for uint256;

	function transfer(address _to, uint256 _value) public returns(bool success) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) constant public returns(uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns(bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant public returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Burn(_from, _value);
        return true;
    }

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;
}

contract BCT is StandardToken {

	string public name = &#39;BIShiCaiJing Token&#39;;
	string public symbol = &#39;BCT&#39;;
	uint8 public decimals = 18;
	uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals);

	function BCT() public {
		balances[msg.sender] = totalSupply;
	}

	function() public {
		throw;
	}

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		if (!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
			throw;
		}
		return true;
	}
}