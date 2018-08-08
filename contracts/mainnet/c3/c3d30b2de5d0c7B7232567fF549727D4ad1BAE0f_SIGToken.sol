pragma solidity ^0.4.18;

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
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

contract ERC20Basic {
	uint256 public totalSupply;
	uint256 freezeTransferTime;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {

	using SafeMath for uint256;
	mapping(address => uint256) balances;

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
        require(now >= freezeTransferTime);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}
}

contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(now >= freezeTransferTime);

		var _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}

contract MintableToken is StandardToken, Ownable {

	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	bool public mintingFinished = false;

	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
		totalSupply = totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		Mint(_to, _amount);
		return true;
	}

	function finishMinting() public onlyOwner returns (bool) {
		mintingFinished = true;
		MintFinished();
		return true;
	}
}

contract SIGToken is MintableToken {

	string public constant name = "Saxinvest Group Coin";
	string public constant symbol = "SIG";
	uint32 public constant decimals = 18;

	function SIGToken(uint256 _freezeTransferTime) public {
		freezeTransferTime = _freezeTransferTime;
	}
}