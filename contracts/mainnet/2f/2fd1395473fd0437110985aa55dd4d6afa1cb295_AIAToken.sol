pragma solidity ^0.4.20;

library SafeMath {
	function add(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}

	function sub(uint a, uint b) internal pure returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function mul(uint a, uint b) internal pure returns (uint) {
		if (a == 0 || b == 0) {
			return 0;
		}
		uint c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint) {
		require(b > 0);
		uint c = a / b;
		return c;
	}
}

contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address owner) public view returns (uint);
	function transfer(address to, uint value) public returns (bool);

	event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint;

	mapping(address => uint) balances;

	function transfer(address _to, uint _value) public returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint) {
		return balances[_owner];
	}
}

contract ERC20 is ERC20Basic {
	function allowance(address _owner, address _spender) public view returns (uint);
	function transferFrom(address _from, address _to, uint _value) public returns (bool);
	function approve(address _spender, uint _value) public returns (bool);

	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is ERC20, BasicToken {
	mapping(address => mapping(address => uint)) allowed;

	function transferFrom(address _from, address _to, uint _value) public returns (bool) {
		var _allowance = allowed[_from][msg.sender];

		require(_value <= _allowance);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint _value) public returns (bool) {
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint) {
		return allowed[_owner][_spender];
	}
}

contract Ownable {
	constructor() public {
		owner = msg.sender;
	}

	address public owner;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0x0)) {
			owner = newOwner;
		}
	}
}

contract AIAToken is StandardToken, Ownable {
	string public constant name = &#39;AIAToken&#39;;
	string public constant symbol = &#39;AIA&#39;;
	uint public constant decimals = 18;
	uint public totalSupply = 200000000 * 10e18; //200,000,000

	constructor() public {
		balances[msg.sender] = totalSupply;
		Transfer(address(0x0), msg.sender, totalSupply);
	}

	modifier validateDestination(address _to) {
		require(_to != address(0x0));
		require(_to != address(this));
		_;
	}

	function transfer(address _to, uint _value) validateDestination(_to) public returns (bool) {
		return super.transfer(_to, _value);
	}
}