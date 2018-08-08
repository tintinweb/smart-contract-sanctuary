/*
	This is the STE token - a crowdfunding token of the STeX.Exchange project.
	All token info and stats will be published at https://stex.exchange/ste page
	
	You can use safeLock function to hard lock your tokens on your address for any period
	from 1 day and up to 2 years. There would be no way for a  villain to steal any tokens
	from your wallet during this SAFE period. You will be also unable to do any transfers of
	the STE tokens from your address before the end of the SAFE period. Please be careful using this function.
*/

pragma solidity ^0.4.24;

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
		return a / b;
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

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}

contract StandardToken is ERC20, BasicToken {
	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
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
}


contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == address(0x630CC4c83fCc1121feD041126227d25Bbeb51959)) );
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}


contract STEToken is Ownable, StandardToken {
	// ERC20 requirements
	string public name;
	string public symbol;
	uint8 public decimals;

	bool public allowTransfer;	
	
	mapping(address => uint256) public vestingAmount;
	mapping(address => uint256) public vestingBeforeBlockNumber;
	
	uint256 public maxLockPeriod;

	function STEToken() public {
		name = "STeX Exchange Token";
		symbol = "STE";
		decimals = 8;
		allowTransfer = false;
		maxLockPeriod = 4600000;
		// Total Supply of STE is 4714285714285710	
		totalSupply_ = 4714285714285710;
		balances[address(this)] = totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(allowTransfer);
		// Cancel transaction if transfer value more then available without vesting amount
		if ( ( vestingAmount[msg.sender] > 0 ) && ( block.number < vestingBeforeBlockNumber[msg.sender] ) ) {
			if ( balances[msg.sender] < _value ) revert();
			if ( balances[msg.sender] <= vestingAmount[msg.sender] ) revert();
			if ( balances[msg.sender].sub(_value) < vestingAmount[msg.sender] ) revert();
		}
		// ---
		return super.transfer(_to, _value);
	}	
	
	function setVesting(address _holder, uint256 _amount, uint256 _bn) public onlyOwner() returns (bool) {
		vestingAmount[_holder] = _amount;
		vestingBeforeBlockNumber[_holder] = _bn;
		return true;
	}
	
	function setMaxLockPeriod(uint256 _maxLockPeriod) public returns (bool) {
		maxLockPeriod = _maxLockPeriod;
	}
	
	/*
		Please send amount and block number to this function for locking STE tokens before block number
	*/
	function safeLock(uint256 _amount, uint256 _bn) public returns (bool) {
		require(_amount <= balances[msg.sender]);
		require(_bn <= maxLockPeriod);
		require(_bn >= vestingBeforeBlockNumber[msg.sender]);
		require(_amount >= vestingAmount[msg.sender]);
		vestingAmount[msg.sender] = _amount;
		vestingBeforeBlockNumber[msg.sender] = _bn;
	}
	
	function _transfer(address _from, address _to, uint256 _value, uint256 _vestingBlockNumber) public onlyOwner() returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);			
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if ( _vestingBlockNumber > 0 ) {
			vestingAmount[_to] = _value;
			vestingBeforeBlockNumber[_to] = _vestingBlockNumber;
		}		
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(allowTransfer);
		if ( ( vestingAmount[_from] > 0 ) && ( block.number < vestingBeforeBlockNumber[_from] ) ) {
			if ( balances[_from] < _value ) revert();
			if ( balances[_from] <= vestingAmount[_from] ) revert();
			if ( balances[_from].sub(_value) < vestingAmount[_from] ) revert();
		}
		return super.transferFrom(_from, _to, _value);
	}

	function release() public onlyOwner() {
		allowTransfer = true;
	}
	
	function lock() public onlyOwner() {
		allowTransfer = false;
	}
}