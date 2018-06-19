pragma solidity ^0.4.11;

contract EthTermDeposits{
 mapping(address => uint) public deposits;
 mapping(address => uint) public depositEndTime;
	
	function EthTermDeposits(){

	}
	/*
	 @notice Creates or updates a deposit that is available for withdrawal after the specified number of weeks.
	 @dev
	 @param numberOfWeeks The number of weeks for which the deposit is being locked. After the specified number of weeks the deposit amount is being unlocked and available for withdrawal. If a deposit with the same name exists it appends the numberOfWeeks to current deposit due time.
	 @returns True on successful deposit.
	*/
	function Deposit(uint8 numberOfWeeks) payable returns(bool){
		address owner = msg.sender;
		uint amount = msg.value;
		uint _time = block.timestamp + numberOfWeeks * 1 weeks;

		if(deposits[owner] > 0){
			_time = depositEndTime[owner] + numberOfWeeks * 1 weeks;
		}
		depositEndTime[owner] = _time;
		deposits[owner] += amount;
		return true;
	}

	/*
		@notice Withdraws due deposit.
	*/

	function Withdraw() returns(bool){
		address owner = msg.sender;
		if(depositEndTime[owner] > 0 &&
		   block.timestamp > depositEndTime[owner] &&
		   deposits[owner] > 0){
			uint amount = deposits[owner];
			deposits[owner] = 0;
			msg.sender.transfer(amount);
			return true;
		}else{
			/* deposit unavailable for withdrawal or already withdrawn. */
			return false;
		}
	}
	function () {
		revert();
	}
}