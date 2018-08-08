pragma solidity ^0.4.24;

contract Payment {
    event Paid(address, uint);

	struct Deposit {
        uint amount;
		uint8 allowed;  /* 0: not set, 1: allowed, 2: forbidden */
		uint timestamp;
	}
	mapping(address => Deposit) public deposits;

    address public owner;

	constructor () public {
	    owner = msg.sender;
	}

	function withdraw(address buyer) public returns (bool) {
	    require(msg.sender == owner, "You are not allowed to withdraw.");
	    require(deposits[buyer].amount > 0, "There&#39;s no deposit in this address.");
	    require(deposits[buyer].allowed == 1 ||
	    (deposits[buyer].allowed == 0 && deposits[buyer].timestamp + 2 * 7 * 24 * 3600 < block.timestamp),
	    /*(deposits[buyer].allowed == 0 && deposits[buyer].timestamp + 2 * 7 * 10 < block.timestamp),*/
	    "The owner of this deposit hasn&#39;t allowed to withdraw and two weeks hasn&#39;t passed since the deposit.");
        uint deposited = deposits[buyer].amount;
        deposits[buyer].amount = 0;
        deposits[buyer].allowed = 0;
        deposits[buyer].timestamp = 0;
        msg.sender.transfer(deposited);
		return true;
	}

    function () public payable {
        require(msg.value >= 0, "Negative value is not allowed.");
        if (msg.value == 0) {
            deposits[msg.sender].allowed = 0;
        } else if (msg.value == 1) {
            deposits[msg.sender].allowed = 1;
        } else if (msg.value == 2) {
            deposits[msg.sender].allowed = 2;
        } else {
            uint tmpDeposit = deposits[msg.sender].amount + msg.value;
            require(tmpDeposit >= deposits[msg.sender].amount, "You sent too much ether.");
            deposits[msg.sender].amount = tmpDeposit;
            deposits[msg.sender].allowed = 0;
            deposits[msg.sender].timestamp = block.timestamp;
            emit Paid(msg.sender, msg.value);
        }
    }

}