pragma solidity^"0.4.19"; // Specify compiler version

// Init splitter contract
contract Splitter {
    address splitAddresses;

    function split(address destinationAddress) public payable {
        splitAddresses = destinationAddress; // Get specified addresses

        sendEth(); // Send ether
    }

    function sendEth() internal {
        splitAddresses.transfer(msg.value); // Send ether
    }
}