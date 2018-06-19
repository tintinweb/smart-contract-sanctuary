pragma solidity ^0.4.2;


contract KickOwned {
	address public owner;

	function KickOwned() {
		owner = msg.sender;
	}

	function changeOwner(address newOwner) onlyOwner {
		owner = newOwner;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}




contract KickUtils {
	/**
		constructor
	*/
	function Utils() {
	}

	// validates an address - currently only checks that it isn&#39;t null
	modifier validAddress(address _address) {
		require(_address != 0x0);
		_;
	}

	// verifies that the address is different than this contract address
	modifier notThis(address _address) {
		require(_address != address(this));
		_;
	}

	// Overflow protected math functions

	/**
		@dev returns the sum of _x and _y, asserts if the calculation overflows

		@param _x   value 1
		@param _y   value 2

		@return sum
	*/
	function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
		uint256 z = _x + _y;
		assert(z >= _x);
		return z;
	}

	/**
		@dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

		@param _x   minuend
		@param _y   subtrahend

		@return difference
	*/
	function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
		assert(_x >= _y);
		return _x - _y;
	}
}


interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}

contract KickToken is KickOwned, KickUtils {
	struct Dividend {uint256 time; uint256 tenThousandth; uint256 countComplete;}

	/* Public variables of the token */
	string public standard = &#39;Token 0.1&#39;;

	string public name = &#39;Experimental KickCoin&#39;;

	string public symbol = &#39;EKICK&#39;;

	uint8 public decimals = 8;

	uint256 _totalSupply = 0;

	/* Is allowed to burn tokens */
	bool public allowManuallyBurnTokens = true;

	/* This creates an array with all balances */
	mapping (address => uint256) balances;

	mapping (address => mapping (uint256 => uint256)) public agingBalanceOf;

	uint[] agingTimes;

	Dividend[] dividends;

	mapping (address => mapping (address => uint256)) allowed;
	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);

	event AgingTransfer(address indexed from, address indexed to, uint256 value, uint256 agingTime);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	// triggered when the total supply is increased
	event Issuance(uint256 _amount);
	// triggered when the total supply is decreased
	event Destruction(uint256 _amount);
	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);

	address[] public addressByIndex;

	mapping (address => bool) addressAddedToIndex;

	mapping (address => uint) agingTimesForPools;

	uint16 currentDividendIndex = 1;

	mapping (address => uint) calculatedDividendsIndex;

	bool public transfersEnabled = true;

	event NewSmartToken(address _token);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function KickToken() {
		owner = msg.sender;
		// So that the index starts with 1
		dividends.push(Dividend(0, 0, 0));
		// 31.10.2017 09:00:00
		dividends.push(Dividend(1509440400, 30, 0));
		// 30.11.2017 09:00:00
		dividends.push(Dividend(1512032400, 20, 0));
		// 31.12.2017 09:00:00
		dividends.push(Dividend(1514710800, 10, 0));
		// 31.01.2018 09:00:00
		dividends.push(Dividend(1517389200, 5, 0));
		// 28.02.2018 09:00:00
		dividends.push(Dividend(1519808400, 10, 0));
		// 31.03.2018 09:00:00
		dividends.push(Dividend(1522486800, 20, 0));
		// 30.04.2018 09:00:00
		dividends.push(Dividend(1525078800, 30, 0));
		// 31.05.2018 09:00:00
		dividends.push(Dividend(1527757200, 50, 0));
		// 30.06.2018 09:00:00
		dividends.push(Dividend(1530349200, 30, 0));
		// 31.07.2018 09:00:00
		dividends.push(Dividend(1533027600, 20, 0));
		// 31.08.2018 09:00:00
		dividends.push(Dividend(1535706000, 10, 0));
		// 30.09.2018 09:00:00
		dividends.push(Dividend(1538298000, 5, 0));
		// 31.10.2018 09:00:00
		dividends.push(Dividend(1540976400, 10, 0));
		// 30.11.2018 09:00:00
		dividends.push(Dividend(1543568400, 20, 0));
		// 31.12.2018 09:00:00
		dividends.push(Dividend(1546246800, 30, 0));
		// 31.01.2019 09:00:00
		dividends.push(Dividend(1548925200, 60, 0));
		// 28.02.2019 09:00:00
		dividends.push(Dividend(1551344400, 30, 0));
		// 31.03.2019 09:00:00
		dividends.push(Dividend(1554022800, 20, 0));
		// 30.04.2019 09:00:00
		dividends.push(Dividend(1556614800, 10, 0));
		// 31.05.2019 09:00:00
		dividends.push(Dividend(1559307600, 20, 0));
		// 30.06.2019 09:00:00
		dividends.push(Dividend(1561885200, 30, 0));
		// 31.07.2019 09:00:00
		dividends.push(Dividend(1564563600, 20, 0));
		// 31.08.2019 09:00:00
		dividends.push(Dividend(1567242000, 10, 0));
		// 30.09.2019 09:00:00
		dividends.push(Dividend(1569834000, 5, 0));

		NewSmartToken(address(this));
	}

	modifier transfersAllowed {
		assert(transfersEnabled);
		_;
	}

	function totalSupply() constant returns (uint256 totalSupply) {
		totalSupply = _totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	bool allAgingTimesHasBeenAdded = false;
	function addAgingTime(uint256 time) onlyOwner {
		require(!allAgingTimesHasBeenAdded);
		agingTimes.push(time);
	}

	function allAgingTimesAdded() onlyOwner {
		allAgingTimesHasBeenAdded = true;
	}

	function calculateDividends(uint256 limit) {
		require(now >= dividends[currentDividendIndex].time);
		require(limit > 0);

		limit = safeAdd(dividends[currentDividendIndex].countComplete, limit);

		if (limit > addressByIndex.length) {
			limit = addressByIndex.length;
		}

		for (uint256 i = dividends[currentDividendIndex].countComplete; i < limit; i++) {
			_addDividendsForAddress(addressByIndex[i]);
		}
		if (limit == addressByIndex.length) {
			currentDividendIndex++;
		}
		else {
			dividends[currentDividendIndex].countComplete = limit;
		}
	}

	/* User can himself receive dividends without waiting for a global accruals */
	function receiveDividends() public {
		require(now >= dividends[currentDividendIndex].time);
		assert(_addDividendsForAddress(msg.sender));
	}

	function _addDividendsForAddress(address _address) internal returns (bool success) {
		// skip calculating dividends, if already calculated for this address
		if (calculatedDividendsIndex[_address] >= currentDividendIndex) return false;

		uint256 add = balances[_address] * dividends[currentDividendIndex].tenThousandth / 1000;
		balances[_address] = safeAdd(balances[_address], add);
		Transfer(this, _address, add);
		Issuance(add);
		_totalSupply = safeAdd(_totalSupply, add);

		if (agingBalanceOf[_address][0] > 0) {
			agingBalanceOf[_address][0] = safeAdd(agingBalanceOf[_address][0], agingBalanceOf[_address][0] * dividends[currentDividendIndex].tenThousandth / 1000);
			for (uint256 k = 0; k < agingTimes.length; k++) {
				agingBalanceOf[_address][agingTimes[k]] = safeAdd(agingBalanceOf[_address][agingTimes[k]], agingBalanceOf[_address][agingTimes[k]] * dividends[currentDividendIndex].tenThousandth / 1000);
			}
		}
		calculatedDividendsIndex[_address] = currentDividendIndex;
		return true;
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) transfersAllowed returns (bool success) {
		_checkMyAging(msg.sender);
		if (currentDividendIndex < dividends.length && now >= dividends[currentDividendIndex].time) {
			_addDividendsForAddress(msg.sender);
			_addDividendsForAddress(_to);
		}

		require(accountBalance(msg.sender) >= _value);

		// Subtract from the sender
		balances[msg.sender] = safeSub(balances[msg.sender], _value);

		if (agingTimesForPools[msg.sender] > 0 && agingTimesForPools[msg.sender] > now) {
			_addToAging(msg.sender, _to, agingTimesForPools[msg.sender], _value);
		}

		balances[_to] = safeAdd(balances[_to], _value);

		_addIndex(_to);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function mintToken(address target, uint256 mintedAmount, uint256 agingTime) onlyOwner {
		if (agingTime > now) {
			_addToAging(owner, target, agingTime, mintedAmount);
		}

		balances[target] = safeAdd(balances[target], mintedAmount);

		_totalSupply = safeAdd(_totalSupply, mintedAmount);
		Issuance(mintedAmount);
		_addIndex(target);
		Transfer(this, target, mintedAmount);
	}

	function _addIndex(address _address) internal {
		if (!addressAddedToIndex[_address]) {
			addressAddedToIndex[_address] = true;
			addressByIndex.push(_address);
		}
	}

	function _addToAging(address from, address target, uint256 agingTime, uint256 amount) internal {
		agingBalanceOf[target][0] = safeAdd(agingBalanceOf[target][0], amount);
		agingBalanceOf[target][agingTime] = safeAdd(agingBalanceOf[target][agingTime], amount);
		AgingTransfer(from, target, amount, agingTime);
	}

	/* Allow another contract to spend some tokens in your behalf */
	function approve(address _spender, uint256 _value) returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/* Approve and then communicate the approved contract in a single tx */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) transfersAllowed returns (bool success) {
		_checkMyAging(_from);
		if (currentDividendIndex < dividends.length && now >= dividends[currentDividendIndex].time) {
			_addDividendsForAddress(_from);
			_addDividendsForAddress(_to);
		}
		// Check if the sender has enough
		require(accountBalance(_from) >= _value);

		// Check allowed
		require(_value <= allowed[_from][msg.sender]);

		// Subtract from the sender
		balances[_from] = safeSub(balances[_from], _value);
		// Add the same to the recipient
		balances[_to] = safeAdd(balances[_to], _value);

		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);

		if (agingTimesForPools[_from] > 0 && agingTimesForPools[_from] > now) {
			_addToAging(_from, _to, agingTimesForPools[_from], _value);
		}

		_addIndex(_to);
		Transfer(_from, _to, _value);
		return true;
	}

	/* This unnamed function is called whenever someone tries to send ether to it */
	function() {
		revert();
		// Prevents accidental sending of ether
	}

	function _checkMyAging(address sender) internal {
		if (agingBalanceOf[sender][0] == 0) return;

		for (uint256 k = 0; k < agingTimes.length; k++) {
			if (agingTimes[k] < now) {
				agingBalanceOf[sender][0] = safeSub(agingBalanceOf[sender][0], agingBalanceOf[sender][agingTimes[k]]);
				agingBalanceOf[sender][agingTimes[k]] = 0;
			}
		}
	}

	function addAgingTimesForPool(address poolAddress, uint256 agingTime) onlyOwner {
		agingTimesForPools[poolAddress] = agingTime;
	}

	function countAddresses() constant returns (uint256 length) {
		return addressByIndex.length;
	}

	function accountBalance(address _address) constant returns (uint256 balance) {
		return safeSub(balances[_address], agingBalanceOf[_address][0]);
	}

	function disableTransfers(bool _disable) public onlyOwner {
		transfersEnabled = !_disable;
	}

	function issue(address _to, uint256 _amount) public onlyOwner validAddress(_to) notThis(_to) {
		_totalSupply = safeAdd(_totalSupply, _amount);
		balances[_to] = safeAdd(balances[_to], _amount);

		_addIndex(_to);
		Issuance(_amount);
		Transfer(this, _to, _amount);
	}

	/**
	 * Destroy tokens
	 * Remove `_value` tokens from the system irreversibly
	 * @param _value the amount of money to burn
	 */
	function burn(uint256 _value) returns (bool success) {
		destroy(msg.sender, _value);
		Burn(msg.sender, _value);
		return true;
	}

	/**
	 * Destroy tokens
	 * Remove `_amount` tokens from the system irreversibly
	 * @param _from the address from which tokens will be burnt
	 * @param _amount the amount of money to burn
	 */
	function destroy(address _from, uint256 _amount) public {
		_checkMyAging(_from);
		// validate input
		require((msg.sender == _from && allowManuallyBurnTokens) || msg.sender == owner);
		require(accountBalance(_from) >= _amount);

		balances[_from] = safeSub(balances[_from], _amount);
		_totalSupply = safeSub(_totalSupply, _amount);

		Transfer(_from, this, _amount);
		Destruction(_amount);
	}

	function disableManuallyBurnTokens(bool _disable) public onlyOwner {
		allowManuallyBurnTokens = !_disable;
	}

  function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

}