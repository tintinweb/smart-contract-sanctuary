pragma solidity^"0.4.19"; // Specify compiler version

// Init splitter contract
contract Splitter {
    address[] splitAddresses;

    function split(address[] destinationAddresses) public payable {
        splitAddresses = destinationAddresses; // Get specified addresses

        sendEth(); // Send ether
    }

    function sendEth() internal {
        for (uint x = 0; x != splitAddresses.length; x++) {
            splitAddresses[x].transfer(msg.value/splitAddresses.length); // Send ether
        }
    }
}