pragma solidity ^0.4.18;



contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function setOwner(address _owner) onlyOwner public {
		owner = _owner;
	}
}

contract Pause is Owned {
	uint8 public pause;

	constructor() public {
		pause = 0;
	}

	function setPause(uint8 _pause) onlyOwner public {
		pause = _pause;
	}
}

contract SafeMath {
	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		assert(c >= _a);
		return c;
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_a >= _b);
		return _a - _b;
	}

	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a * _b;
		assert(_a == 0 || c / _a == _b);
		return c;
	}
}

contract IToken {
	function name() public pure returns (string _name) { _name; }
	function symbol() public pure returns (string _symbol) { _symbol; }
	function decimals() public pure returns (uint8 _decimals) { _decimals; }
	function totalSupply() public pure returns (uint256 _totalSupply) { _totalSupply; }

	function balanceOf(address _owner) public pure returns (uint256 balance) { _owner; balance; }

	function allowance(address _owner, address _spender) public pure returns (uint256 remaining) { _owner; _spender; remaining; }

	function transfer(address _to, uint256 _value) public returns (bool);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	function approve(address _spender, uint256 _value) public returns (bool);
}

contract Token is IToken, SafeMath, Owned, Pause {
	string public constant standard = &#39;0.1&#39;;
	string public name = &#39;&#39;;
	string public symbol = &#39;&#39;;
	uint8 public decimals = 0;
	uint256 public totalSupply = 0;
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
		require(bytes(_name).length > 0 && bytes(_symbol).length > 0);

		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;

		balanceOf[msg.sender] = _totalSupply;
	}

	modifier validAddress(address _address) {
		require(_address != 0x0);
		_;
	}

	function isNotPaused() public constant returns (bool) {
        return pause == 0;
    }

	function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool) {
		require(isNotPaused());
		assert(balanceOf[msg.sender] >= _value && _value > 0);

		balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
		balanceOf[_to] = add(balanceOf[_to], _value);

		emit Transfer(msg.sender, _to, _value);
		
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public validAddress(_from) validAddress(_to) returns (bool) {
		require(isNotPaused());
		assert(balanceOf[_from] >= _value && _value > 0);
		assert(allowance[_from][msg.sender] >= _value);

		allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);

		balanceOf[_from] = sub(balanceOf[_from], _value);
		balanceOf[_to] = add(balanceOf[_to], _value);

		emit Transfer(_from, _to, _value);

		return true;
	}

	function multisend(address[] dests, uint256[] values) public returns (uint256) {
		require(isNotPaused());

        uint256 i = 0;
        while (i < dests.length) {
           transfer(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

	function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool) {
		require(isNotPaused());
		require(_value == 0 || allowance[msg.sender][_spender] == 0);

		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);

		return true;
	}
}