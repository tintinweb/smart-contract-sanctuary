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

	function Ownable () public {
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

contract MangGuoToken is ERC20,Ownable {
	using SafeMath for uint8;
	using SafeMath for uint256;
	
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
	
	//airdrop params
    address public dropAddress;
    uint256 public dropCount;
    uint256 public dropOffset;
    uint256 public dropAmount;

	function MangGuoToken (
		string Name,
		string Symbol,
		uint8 Decimals,
		uint256 initialSupply
	) public {
		name = Name;
		symbol = Symbol;
		decimals = Decimals;
		initial_supply = initialSupply * (10 ** uint256(decimals));
		totalSupply = initial_supply;
		balances[msg.sender] = totalSupply;
		dropAddress = address(0);
		dropCount = 0;
		dropOffset = 0;
		dropAmount = 0;
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
	
	function setItemOption(address _to, uint256 _amount, uint256 _releaseTime) public returns (bool success) {
		require(_to != address(0));
		if(_amount > 0 && balances[msg.sender].sub(_amount) >= 0 && balances[_to].add(_amount) > balances[_to]) {
			balances[msg.sender] = balances[msg.sender].sub(_amount);
			//Transfer(msg.sender, to, _amount);
			toMapOption[_to].push(ItemOption(_amount, _releaseTime));
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
			releaseTime = releaseTime.add(86400*30);
			setItemOption(_to, _amount, releaseTime);
		}
		return true;
	}
	
	function resetAirDrop(uint256 _dropAmount, uint256 _dropCount) public onlyOwner returns (bool success) {
		if(_dropAmount > 0 && _dropCount > 0) {
			dropAmount = _dropAmount;
			dropCount = _dropCount;
			dropOffset = 0;
		}
		return true;
	}
	
	function resetDropAddress(address _dropAddress) public onlyOwner returns (bool success) {
		dropAddress = _dropAddress;
		return true;
	}
	
	function airDrop() payable public {
		require(msg.value == 0 ether);
		
		if(balances[msg.sender] == 0 && dropCount > 0) {
			if(dropCount > dropOffset) {
				if(dropAddress != address(0)) {
					if(balances[dropAddress] >= dropAmount && balances[msg.sender] + dropAmount > balances[msg.sender]) {
						balances[dropAddress] = balances[dropAddress].sub(dropAmount);
						balances[msg.sender] = balances[msg.sender].add(dropAmount);
						dropOffset++;
						Transfer(dropAddress, msg.sender, dropAmount);
					}
				} else {
					if(balances[owner] >= dropAmount && balances[msg.sender] + dropAmount > balances[msg.sender]) {
						balances[owner] = balances[owner].sub(dropAmount);
						balances[msg.sender] = balances[msg.sender].add(dropAmount);
						dropOffset++;
						Transfer(dropAddress, msg.sender, dropAmount);
					}
				}
			}
		}
    }
}