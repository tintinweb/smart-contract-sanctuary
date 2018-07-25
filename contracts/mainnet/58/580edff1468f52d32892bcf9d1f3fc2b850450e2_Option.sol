pragma solidity ^0.4.18;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20 {
	uint public totalSupply;
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to,uint _value) public returns (bool success);
	function transferFrom(address _from,address _to,uint _value) public returns (bool success);
	function approve(address _spender,uint _value) public returns (bool success);
	function allownce(address _owner,address _spender) public constant returns (uint remaining);
	event Transfer(address indexed _from,address indexed _to,uint _value);
	event Approval(address indexed _owner,address indexed _spender,uint _value);
}

contract Option is ERC20,Ownable {
	using SafeMath for uint8;
	using SafeMath for uint256;
	
	event Burn(address indexed _from,uint256 _value);
	event Increase(address indexed _to, uint256 _value);
	event SetItemOption(address _to, uint256 _amount, uint256 _releaseTime);
	
	struct ItemOption {
		uint256 releaseAmount;
		uint256 releaseTime;
	}

	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public initial_supply;
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) allowed;
	mapping (address => ItemOption[]) toMapOption;
	
	function Option (
		string Name,
		string Symbol,
		uint8 Decimals,
		uint256 initialSupply,
		address initOwner
	) public {
		require(initOwner != address(0));
		owner = initOwner;
		name = Name;
		symbol = Symbol;
		decimals = Decimals;
		initial_supply = initialSupply * (10 ** uint256(decimals));
		totalSupply = initial_supply;
		balances[initOwner] = totalSupply;
	}
	
	function itemBalance(address _to) public constant returns (uint amount) {
		require(_to != address(0));
		amount = 0;
		uint256 nowtime = now;
		for(uint256 i = 0; i < toMapOption[_to].length; i++) {
			require(toMapOption[_to][i].releaseAmount > 0);
			if(nowtime >= toMapOption[_to][i].releaseTime) {
				amount = amount.add(toMapOption[_to][i].releaseAmount);
			}
		}
		return amount;
	}
	
	function balanceOf(address _owner) public constant returns (uint balance) {
		return balances[_owner].add(itemBalance(_owner));
	}
	
	function itemTransfer(address _to) public returns (bool success) {
		require(_to != address(0));
		uint256 nowtime = now;
		for(uint256 i = 0; i < toMapOption[_to].length; i++) {
			require(toMapOption[_to][i].releaseAmount >= 0);
			if(nowtime >= toMapOption[_to][i].releaseTime && balances[_to] + toMapOption[_to][i].releaseAmount > balances[_to]) {
				balances[_to] = balances[_to].add(toMapOption[_to][i].releaseAmount);
				toMapOption[_to][i].releaseAmount = 0;
			}
		}
		return true;
	}
	
	function transfer(address _to,uint _value) public returns (bool success) {
		itemTransfer(_to);
		if(balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]){
			balances[msg.sender] = balances[msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
			Transfer(msg.sender,_to,_value);
			return true;
		} else {
			return false;
		}
	}

	function transferFrom(address _from,address _to,uint _value) public returns (bool success) {
		itemTransfer(_from);
		if(balances[_from] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
			if(_from != msg.sender) {
				require(allowed[_from][msg.sender] > _value);
				allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
			}
			balances[_from] = balances[_from].sub(_value);
			balances[_to] = balances[_to].add(_value);
			Transfer(_from,_to,_value);
			return true;
		} else {
			return false;
		}
	}

	function approve(address _spender, uint _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender,_spender,_value);
		return true;
	}
	
	function allownce(address _owner,address _spender) public constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}
	
	function burn(uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(msg.sender,_value);
		return true;
	}

	function increase(uint256 _value) public onlyOwner returns (bool success) {
		if(balances[msg.sender] + _value > balances[msg.sender]) {
			totalSupply = totalSupply.add(_value);
			balances[msg.sender] = balances[msg.sender].add(_value);
			Increase(msg.sender, _value);
			return true;
		}
	}

	function setItemOption(address _to, uint256 _amount, uint256 _releaseTime) public returns (bool success) {
		require(_to != address(0));
		uint256 nowtime = now;
		if(_amount > 0 && balances[msg.sender].sub(_amount) >= 0 && balances[_to].add(_amount) > balances[_to]) {
			balances[msg.sender] = balances[msg.sender].sub(_amount);
			//Transfer(msg.sender, to, _amount);
			toMapOption[_to].push(ItemOption(_amount, _releaseTime));
			SetItemOption(_to, _amount, _releaseTime);
			return true;
		}
		return false;
	}
	
	function setItemOptions(address _to, uint256 _amount, uint256 _startTime, uint8 _count) public returns (bool success) {
		require(_to != address(0));
		require(_amount > 0);
		require(_count > 0);
		uint256 releaseTime = _startTime;
		for(uint8 i = 0; i < _count; i++) {
			releaseTime = releaseTime.add(1 years);
			setItemOption(_to, _amount, releaseTime);
		}
		return true;
	}
}