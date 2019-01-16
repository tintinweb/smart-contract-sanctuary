pragma solidity >=0.4.22 <0.6.0;

contract SmartTrust {
	address public enforcer = address(0);
	address public beneficiary = address(0);
	uint public eventTime = 0;
	uint public stipendPeriod = 0;
	uint public stipendAmount = 0;
	uint public withdrawn = 0;

	constructor(
		address _enforcer,
		address _beneficiary,

		uint _stipendPeriod,
		uint _stipendAmount
	) public {
		require(_stipendPeriod > 0);
		require(_stipendAmount > 0);
		require(_enforcer != address(0x0));
		require(_beneficiary != address(0x0));
		enforcer = _enforcer;
		beneficiary = _beneficiary;
		stipendPeriod = _stipendPeriod;
		stipendAmount = _stipendAmount;
	}

	modifier onlyEnforcer() { require(msg.sender == enforcer); _; }
	modifier onlyBeneficiary() { require(msg.sender == beneficiary); _; }
	modifier eventHasOccured() { require(eventTime != 0); _; }
	modifier eventHasNotOccured() { require(eventTime == 0); _; }

	event EventSet(uint occurTime);
	event Withdrawn(uint amount);

	function () payable external {}

	function setEvent(uint _eventTime) onlyEnforcer eventHasNotOccured public {
		require(now > _eventTime);
		eventTime = _eventTime;
		emit EventSet(_eventTime);
	}

	function withdraw() onlyBeneficiary eventHasOccured public {
		uint amount = available();
		if (amount > 0) {
			withdrawn = withdrawn + amount;
			if (msg.sender.send(amount)) {
				emit Withdrawn(amount);
			} else {
				withdrawn = withdrawn - amount;
			}
		}
	}

	function available() view public
		returns (uint availableAmount_) {
		if (eventTime == 0) { return 0; }
		uint pending = (stipendAmount * (1 + ((now - eventTime) / stipendPeriod))) - withdrawn;
		if (pending < address(this).balance) {
			return pending;
		} else {
			return address(this).balance;
		}
	}
}