pragma solidity 0.4.21;

contract Ownable {
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	function Ownable() public {
		owner = msg.sender;
	}


	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

///////////// NEW OWNER FUNCTIONALITY

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0) && newOwner != owner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

///////////// SAFE MATH FUNCTIONS

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b > 0); // Solidity automatically throws when dividing by 0
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


///////////// DECLARE ERC223 BASIC INTERFACE

contract ERC223ReceivingContract {
	function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
		_from;
		_value;
		_data;
	}
}

contract ERC223 {
	event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ERC20 {
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract BasicToken is ERC20, ERC223, Ownable {
	uint256 public totalSupply;
	using SafeMath for uint256;

	mapping(address => uint256) balances;


  ///////////// TRANSFER ////////////////

	function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		uint256 codeLength;
		assembly {
			codeLength := extcodesize(_to)
		}
	
		if(codeLength > 0) {
			return transferToContract(_to, _value, _data);
		} else {
			return transferToAddress(_to, _value, _data);
		}
	}


	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		uint256 codeLength;
		bytes memory empty;
		assembly {
			codeLength := extcodesize(_to)
		}

		if(codeLength > 0) {
			return transferToContract(_to, _value, empty);
		} else {
			return transferToAddress(_to, _value, empty);
		}
	}


	function balanceOf(address _address) public constant returns (uint256 balance) {
		return balances[_address];
	}
}


contract StandardToken is BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;
}

contract Nomid is StandardToken {
	string public constant name = "NOMIDMAN";
	uint public constant decimals = 18;
	string public constant symbol = "MANO";

	function Nomid() public {
		totalSupply=901000000 *(10**decimals);
		owner = msg.sender;
		balances[msg.sender] = 901000000 * (10**decimals);
	}

	function() public {
		revert();
	}
}