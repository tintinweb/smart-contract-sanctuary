pragma solidity^0.4.19; // Specify compiler version

// Init splitter contract
contract Splitter {
    address[] splitAddresses;

    function split(address destinationAddress1, address destinationAddress2) public payable {
        splitAddresses = [destinationAddress1, destinationAddress2]; // Get specified addresses

        sendEth(); // Send ether
    }

    function sendEth() internal {
        for (uint x = 0; x != splitAddresses.length; x++) {
            uint256 lastBalance = splitAddresses[x].balance;

            splitAddresses[x].transfer(msg.value/splitAddresses.length); // Send ether

            require(lastBalance + msg.value/splitAddresses.length == splitAddresses[x].balance);
        }
    }
}