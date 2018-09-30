pragma solidity^0.4.24; // Specify compiler version

// Init Splitter contract
contract Splitter {
    mapping (address => uint256) unspentSplits; // Store pending withdrawals

    event registeredSplit(address sender, address firstDestinationAddress, address secondDestinationAddress, uint amount, uint remainder); // Log split
    event registeredRemainderRefund(address sender, uint amount); // Log remainder
    event attemptedWithdrawal(address withdrawalAddress, uint amount);
    event finishedWithdrawal(address withdrawalAddress, uint amount);

    function split(address destinationAddress1, address destinationAddress2) public payable {
        uint256 splitValue = msg.value / 2; // Calculate split value

        uint remainder = msg.value - 2 * splitValue; // Calculate remainder

        if (remainder > 0) { // Check for existing remainder
            unspentSplits[msg.sender] = remainder; // Set to split

            emit registeredRemainderRefund(msg.sender, remainder);
        }

        unspentSplits[destinationAddress1] = splitValue; // Set to split
        unspentSplits[destinationAddress2] = splitValue; // Set to split

        emit registeredSplit(msg.sender, destinationAddress1, destinationAddress2, splitValue, remainder);
    }

    function withdraw() public {
        sendEth(msg.sender); // Send ether
    }

    function sendEth(address destinationAddress) internal {
        uint withdrawalValue = unspentSplits[destinationAddress];

        emit attemptedWithdrawal(destinationAddress, withdrawalValue);

        unspentSplits[destinationAddress] = 0; // Set address pending split to 0

        destinationAddress.transfer(unspentSplits[destinationAddress]); // Attempt to transfer to specified address

        emit finishedWithdrawal(destinationAddress, withdrawalValue);
    }
}