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
			emit OwnershipTransferred(owner, newOwner);
			owner = newOwner;
		}
	}

	contract ERC20Basic {
		function totalSupply() public view returns (uint256);
		function balanceOf(address who) public view returns (uint256);
		function transfer(address to, uint256 value) public returns (bool);
		event Transfer(address indexed from, address indexed to, uint256 value);
	}

	contract ERC20 is ERC20Basic {
		function allowance(address owner, address spender) public view returns (uint256);
		function transferFrom(address from, address to, uint256 value) public returns (bool);
		function approve(address spender, uint256 value) public returns (bool);
		event Approval(address indexed owner, address indexed spender, uint256 value);
	}

	contract Rhodium is ERC20, Ownable{

	using SafeMath for uint256;

	string public constant name = "Rhodium"; // solium-disable-line uppercase
	string public constant symbol = "RH45"; // solium-disable-line uppercase
	uint8 public constant decimals = 8; // solium-disable-line uppercase

	uint256 public constant INITIAL_SUPPLY = 45000000e8;
	uint256 totalSupply_;


	uint256 public minAmount = 0.04 ether;

	uint256 public rate =  100000000;
	bool public allowSelling = false; 

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	function Rhodium() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function () public payable {

		require(allowSelling);
		require(msg.sender != address(0));
		require(tx.origin == msg.sender); 
		require(msg.value >= minAmount);

		uint256 ethAmount = msg.value; 
		uint256 numTokensSend = 0;

		numTokensSend = ethAmount.div(rate);

		if (balances[owner] >= numTokensSend) {

			balances[owner] = balances[owner].sub(numTokensSend);
			balances[msg.sender] = balances[msg.sender].add(numTokensSend);

			owner.transfer(ethAmount);
			emit Transfer(owner, msg.sender, numTokensSend);

		}else{
			revert();
		}

			
	}

	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length >= size * 32 + 4);
		_;
	}

	
	function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}


	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}


	function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function multiTransfer(address[] _toAddresses, uint256[] _amounts) public returns (bool) {

		require(_toAddresses.length <= 255);
		require(_toAddresses.length == _amounts.length);

		for (uint8 i = 0; i < _toAddresses.length; i++) {
			transfer(_toAddresses[i], _amounts[i]);
		}

		return true;
	}

	function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {

		uint oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
	
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function sellingEnable(uint256 _rate) onlyOwner public {
		require(_rate > 0);
		allowSelling = true;
		rate = _rate; 
	}

	function sellingDisable() onlyOwner public {
		allowSelling = false;
	}
}