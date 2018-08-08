pragma solidity ^0.4.21;

/*
* Contract that is working with ERC223 tokens
*/
 
contract ERC223Receiver {
	struct TKN {
		address sender;
		uint value;
		bytes data;
		bytes4 sig;
	}
	function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

 /* New ERC223 contract interface */
 
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);

// redundant as public accessors are automatically assigned   
//  function name() public view returns (string _name);
//  function symbol() public view returns (string _symbol);
//  function decimals() public view returns (uint8 _decimals);
//  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  //event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CGENToken is ERC223 {

	// standard token metadata
	// implements ERC20/ERC223 interface
	string public constant name = "Cryptanogen"; 
	string public constant symbol = "CGEN" ;
	uint8 public constant decimals = 8;

	// amount of tokens vested
	uint128 public availableSupply;

	// individual vesting data
	struct vesting {
		uint createdAt;
		uint128 amount;
		uint8 releaseRate;
		uint32 releaseIntervalSeconds;
		uint8 nextReleasePeriod;
		bool completed;
	}

	struct tokenAccount {
		uint128 vestedBalance;
		uint128 releasedBalance;
		vesting []vestingIndex; 
	}

	// locked balance per address
	mapping (address => tokenAccount) tokenAccountIndex;

	// contract owner
	address public owner;

	// contract creation time
	uint creationTime;

	// How often vested tokens are released
	//uint32 public defaultReleaseIntervalSeconds = 31536000;

	// Percentage vested amount released each interval
	//uint8 public defaultReleaseRate = 10; 

	function CGENToken(uint _supply) public {
		totalSupply = _supply;
		availableSupply = uint128(totalSupply);
		require(uint(availableSupply) == totalSupply);
		owner = msg.sender;
		creationTime = now;
		emit Transfer(0x0, owner, _supply);
	}

	// creates a new vesting with default parameters for rate and interval	
//	function vestToAddress(address _who, uint128 _amount) public returns(bool) {
//		return vestToAddressEx(_who, _amount, defaultReleaseRate, defaultReleaseIntervalSeconds);
//	}


	// creates a new vesting with explicit parameters for rate and interval
	function vestToAddressEx(address _who, uint128 _amount, uint8 _divisor, uint32 _intervalSeconds) public returns(bool) {

		// uninitialized but all fields will be set below
		vesting memory newVesting;

		// vestings are registered manually by contract owner
		require(msg.sender == owner);

		// duh
		require(_amount > 0);
		require(_divisor <= 100 && _divisor > 0);
		require(_intervalSeconds > 0);

		// rate should divide evenly to 100 (percent)
		require(100 % _divisor == 0);

		// prevent vesting of more tokens than total supply
		require(_amount <= availableSupply);

		newVesting.createdAt = now;
		newVesting.amount = _amount;
		newVesting.releaseRate = 100 / _divisor;
		newVesting.releaseIntervalSeconds = _intervalSeconds;
		newVesting.nextReleasePeriod = 0;
		newVesting.completed = false;
		tokenAccountIndex[_who].vestingIndex.push(newVesting);

		availableSupply -= _amount;
		tokenAccountIndex[_who].vestedBalance += _amount;
		emit Transfer(owner, _who, _amount);
		return true;
	}

	// check the vesting at the particular index for the address for amount eligible for release
	// returns the eligible amount
	function checkRelease(address _who, uint _idx) public view returns(uint128) {
		vesting memory v;
		uint i;
		uint timespan;
		uint timestep;
		uint maxEligibleFactor;
		uint128 releaseStep;
		uint128 eligibleAmount;

		// check if any tokens have been vested to this account
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);
		v = tokenAccountIndex[_who].vestingIndex[_idx];
		if (v.completed) {
			return 0;
		}

		// by dividing timespan (time passed since vesting creation) by the release intervals, we get the maximal rate that is eligible for release so far
		// cap it at 100 percent
		timespan = now - tokenAccountIndex[_who].vestingIndex[_idx].createdAt;
		timestep = tokenAccountIndex[_who].vestingIndex[_idx].releaseIntervalSeconds * 1 seconds;
		maxEligibleFactor = (timespan / timestep) * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate;
		if (maxEligibleFactor > 100) {
			maxEligibleFactor = 100;
		}

		releaseStep = (tokenAccountIndex[_who].vestingIndex[_idx].amount * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate) / 100;
		// iterate from the cursor on the next vesting period that has not yet been released
		for (i = tokenAccountIndex[_who].vestingIndex[_idx].nextReleasePeriod * tokenAccountIndex[_who].vestingIndex[_idx].releaseRate; i < maxEligibleFactor; i += tokenAccountIndex[_who].vestingIndex[_idx].releaseRate) {
			eligibleAmount += releaseStep;
		}

		return eligibleAmount;
	}

	// will release and make transferable any tokens eligible for release
	// to avoid waste of gas, the calling agent should have confirmed with checkRelease that there actually is something to release
	function release(address _who, uint _idx) public returns(uint128) {
		vesting storage v;
		uint8 j;
		uint8 i;
		uint128 total;
		uint timespan;
		uint timestep;
		uint128 releaseStep;
		uint maxEligibleFactor;

		// check if any tokens have been vested to this account
		// don&#39;t burn gas if already completed
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);
		v = tokenAccountIndex[_who].vestingIndex[_idx];
		if (v.completed) {
			revert();
		}

		// by dividing timespan (time passed since vesting creation) by the release intervals, we get the maximal rate that is eligible for release so far
		// cap it at 100 percent
		timespan = now - v.createdAt;
		timestep = v.releaseIntervalSeconds * 1 seconds;
		maxEligibleFactor = (timespan / timestep) * v.releaseRate;
		if (maxEligibleFactor > 100) {
			maxEligibleFactor = 100;
		}

		releaseStep = (v.amount * v.releaseRate) / 100;
		for (i = v.nextReleasePeriod * v.releaseRate; i < maxEligibleFactor; i += v.releaseRate) {
			total += releaseStep;
			j++;
		}
		tokenAccountIndex[_who].vestedBalance -= total;
		tokenAccountIndex[_who].releasedBalance += total;
		if (maxEligibleFactor == 100) {
			v.completed = true;
		} else {
			v.nextReleasePeriod += j;
		}
		return total;
	}

	// vestings state access
	function getVestingAmount(address _who, uint _idx) public view returns (uint128) {
		return tokenAccountIndex[_who].vestingIndex[_idx].amount;
	}

	function getVestingReleaseRate(address _who, uint _idx) public view returns (uint8) {
		return tokenAccountIndex[_who].vestingIndex[_idx].releaseRate;
	}

	function getVestingReleaseInterval(address _who, uint _idx) public view returns(uint32) {
		return tokenAccountIndex[_who].vestingIndex[_idx].releaseIntervalSeconds;
	}

	function getVestingCreatedAt(address _who, uint _idx) public view returns(uint) {
		return tokenAccountIndex[_who].vestingIndex[_idx].createdAt;
	}

	function getVestingsCount(address _who) public view returns(uint) {
		return tokenAccountIndex[_who].vestingIndex.length;
	}

	function vestingIsCompleted(address _who, uint _idx) public view returns(bool) {
		require(tokenAccountIndex[_who].vestingIndex.length > _idx);

		return tokenAccountIndex[_who].vestingIndex[_idx].completed;
	}

	// implements ERC223 interface
	function transfer(address _to, uint256 _value, bytes _data, string _custom_callback_unimplemented) public returns(bool) {
		uint128 shortValue;

		// owner can only vest tokens
		require(_to != owner);
		require(msg.sender != owner);
	
		// we use 128 bit data for values
		// make sure it&#39;s converted correctly
		shortValue = uint128(_value);
		require(uint(shortValue) == _value);

		// check if there is enough in the released balance
		require(tokenAccountIndex[msg.sender].releasedBalance >= shortValue);

		// check if the recipient has an account, if not create it
		tokenAccountIndex[msg.sender].releasedBalance -= shortValue;
		tokenAccountIndex[_to].releasedBalance += shortValue;

		// ERC223 safe token transfer to contract
		if (isContract(_to)) {
			ERC223Receiver receiver = ERC223Receiver(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	// implements ERC20/ERC223 interface
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		return transfer(_to, _value, _data, "");
	}

	// implements ERC20/ERC223 interface
	function transfer(address _to, uint256 _value) public returns (bool) {
		bytes memory empty;
		return transfer(_to, _value, empty, "");
	}

	// not used for this token
	// implements ERC20 interface
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
		return false;
	}

	// not used for this token
	// implements ERC20 interface
	function approve(address _spender, uint256 _value) public returns(bool) {
		return false;
	}

	// not used for this token
	// implements ERC20 interface
	function allowance(address _owner, address _spender) public view returns(uint256) {
		return 0;
	}

	// check the total of vested tokens still locked for a particular address
	function vestedBalanceOf(address _who) public view returns (uint) {
		return uint(tokenAccountIndex[_who].vestedBalance);
	}

	// check the total of vested and released tokens assigned to a particular addresss
	// (this is the actual token balance)
	// implements ERC20/ERC223 interface
	function balanceOf(address _who) public view returns (uint) {
		if (_who == owner) {
			return availableSupply;
		}
		return uint(tokenAccountIndex[_who].vestedBalance + tokenAccountIndex[_who].releasedBalance);
	}

	// external addresses (wallets) will have codesize 0
	function isContract(address _addr) private view returns (bool) {
		uint l;

		// Retrieve the size of the code on target address, this needs assembly .
		assembly {
			l := extcodesize(_addr)
		}
		return (l > 0);
	}
}