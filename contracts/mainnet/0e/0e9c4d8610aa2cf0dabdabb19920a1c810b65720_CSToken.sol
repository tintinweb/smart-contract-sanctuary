pragma solidity ^0.4.2;

contract owned {
	address public owner;

	function owned() {
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

contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}

contract CSToken is owned {
	struct Dividend {
		uint time;
		uint tenThousandth;
		bool isComplete;
	}

	/* Public variables of the token */
	string public standard = &#39;Token 0.1&#39;;

	string public name = &#39;KickCoin&#39;;

	string public symbol = &#39;KC&#39;;

	uint8 public decimals = 8;

	uint256 public totalSupply = 0;

	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public matureBalanceOf;

	mapping (address => mapping (uint => uint256)) public agingBalanceOf;

	uint[] agingTimes;

	Dividend[] dividends;

	mapping (address => mapping (address => uint256)) public allowance;
	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);
	event AgingTransfer(address indexed from, address indexed to, uint256 value, uint agingTime);

	uint countAddressIndexes = 0;

	mapping (uint => address) addressByIndex;

	mapping (address => uint) indexByAddress;

	mapping (address => uint) agingTimesForPools;

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function CSToken() {
		owner = msg.sender;
		dividends.push(Dividend(1509454800, 300, false));
		dividends.push(Dividend(1512046800, 200, false));
		dividends.push(Dividend(1514725200, 100, false));
		dividends.push(Dividend(1517403600, 50, false));
		dividends.push(Dividend(1519822800, 100, false));
		dividends.push(Dividend(1522501200, 200, false));
		dividends.push(Dividend(1525093200, 300, false));
		dividends.push(Dividend(1527771600, 500, false));
		dividends.push(Dividend(1530363600, 300, false));
		dividends.push(Dividend(1533042000, 200, false));
		dividends.push(Dividend(1535720400, 100, false));
		dividends.push(Dividend(1538312400, 50, false));
		dividends.push(Dividend(1540990800, 100, false));
		dividends.push(Dividend(1543582800, 200, false));
		dividends.push(Dividend(1546261200, 300, false));
		dividends.push(Dividend(1548939600, 600, false));
		dividends.push(Dividend(1551358800, 300, false));
		dividends.push(Dividend(1554037200, 200, false));
		dividends.push(Dividend(1556629200, 100, false));
		dividends.push(Dividend(1559307600, 200, false));
		dividends.push(Dividend(1561899600, 300, false));
		dividends.push(Dividend(1564578000, 200, false));
		dividends.push(Dividend(1567256400, 100, false));
		dividends.push(Dividend(1569848400, 50, false));

	}

	function calculateDividends(uint which) {
		require(now >= dividends[which].time && !dividends[which].isComplete);

		for (uint i = 1; i <= countAddressIndexes; i++) {
			balanceOf[addressByIndex[i]] += balanceOf[addressByIndex[i]] * dividends[which].tenThousandth / 10000;
			matureBalanceOf[addressByIndex[i]] += matureBalanceOf[addressByIndex[i]] * dividends[which].tenThousandth / 10000;
		}
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		checkMyAging(msg.sender);
		require(matureBalanceOf[msg.sender] >= _value);

		require(balanceOf[_to] + _value > balanceOf[_to]);
		require(matureBalanceOf[_to] + _value > matureBalanceOf[_to]);
		// Check for overflows

		balanceOf[msg.sender] -= _value;
		matureBalanceOf[msg.sender] -= _value;
		// Subtract from the sender

		if (agingTimesForPools[msg.sender] > 0 && agingTimesForPools[msg.sender] > now) {
			addToAging(msg.sender, _to, agingTimesForPools[msg.sender], _value);
		} else {
			matureBalanceOf[_to] += _value;
		}
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

	function mintToken(address target, uint256 mintedAmount, uint agingTime) onlyOwner {
		if (agingTime > now) {
			addToAging(owner, target, agingTime, mintedAmount);
		} else {
			matureBalanceOf[target] += mintedAmount;
		}

		balanceOf[target] += mintedAmount;

		totalSupply += mintedAmount;
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}

	function addToAging(address from, address target, uint agingTime, uint256 amount) internal {
		if (indexByAddress[target] == 0) {
			indexByAddress[target] = 1;
			countAddressIndexes++;
			addressByIndex[countAddressIndexes] = target;
		}
		bool existTime = false;
		for (uint i = 0; i < agingTimes.length; i++) {
			if (agingTimes[i] == agingTime)
			existTime = true;
		}
		if (!existTime) agingTimes.push(agingTime);
		agingBalanceOf[target][agingTime] += amount;
		AgingTransfer(from, target, amount, agingTime);
	}

	/* Allow another contract to spend some tokens in your behalf */
	function approve(address _spender, uint256 _value) returns (bool success) {
		allowance[msg.sender][_spender] = _value;
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
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		checkMyAging(_from);
		require(matureBalanceOf[_from] >= _value);
		// Check if the sender has enough
		assert(balanceOf[_to] + _value > balanceOf[_to]);
		assert(matureBalanceOf[_to] + _value > matureBalanceOf[_to]);
		// Check for overflows
		require(_value <= allowance[_from][msg.sender]);
		// Check allowance
		balanceOf[_from] -= _value;
		matureBalanceOf[_from] -= _value;
		// Subtract from the sender
		balanceOf[_to] += _value;
		// Add the same to the recipient
		allowance[_from][msg.sender] -= _value;

		if (agingTimesForPools[_from] > 0 && agingTimesForPools[_from] > now) {
			addToAging(_from, _to, agingTimesForPools[_from], _value);
		} else {
			matureBalanceOf[_to] += _value;
		}

		Transfer(_from, _to, _value);
		return true;
	}

	/* This unnamed function is called whenever someone tries to send ether to it */
	function() {
		revert();
		// Prevents accidental sending of ether
	}

	function checkMyAging(address sender) internal {
		for (uint k = 0; k < agingTimes.length; k++) {
			if (agingTimes[k] < now && agingBalanceOf[sender][agingTimes[k]] > 0) {
				for(uint256 i = 0; i < 24; i++) {
					if(now < dividends[i].time) break;
					if(!dividends[i].isComplete) break;
					agingBalanceOf[sender][agingTimes[k]] += agingBalanceOf[sender][agingTimes[k]] * dividends[i].tenThousandth / 10000;
				}
				matureBalanceOf[sender] += agingBalanceOf[sender][agingTimes[k]];
				agingBalanceOf[sender][agingTimes[k]] = 0;
			}
		}
	}

	function addAgingTimesForPool(address poolAddress, uint agingTime) onlyOwner {
		agingTimesForPools[poolAddress] = agingTime;
	}
}