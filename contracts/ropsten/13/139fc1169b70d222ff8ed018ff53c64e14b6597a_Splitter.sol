pragma solidity^0.4.24; // Specify compiler version

// Init splitter contract
contract Splitter {
    address[] splitAddresses;

    function split(address destinationAddress1, address destinationAddress2) public payable {
        splitAddresses = [destinationAddress1, destinationAddress2]; // Get specified addresses

        sendEth(); // Send ether
    }

    function sendEth() internal {
        for (uint x = 0; x != splitAddresses.length; x++) {
            require(splitAddresses[x].send(msg.value/splitAddresses.length), "Transaction failed"); // Send ether
        }
    }
}