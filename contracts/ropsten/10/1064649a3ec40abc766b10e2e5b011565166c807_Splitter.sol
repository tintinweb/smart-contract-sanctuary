pragma solidity^0.4.24; // Specify compiler version

// Init splitter contract
contract Splitter {
    mapping (address => uint256) unspentSplits; // Store pending withdrawals

    function split(address[] destinationAddresses) public payable {
        for (uint x = 0; x != destinationAddresses.length; x++) {
            unspentSplits[destinationAddresses[x]] = msg.value / destinationAddresses.length;
        }
    }

    function withdraw() public {
        sendEth(msg.sender); // Send ether
    }

    function sendEth(address destinationAddress) internal {
        destinationAddress.transfer(unspentSplits[destinationAddress]); // Attempt to transfer to specified address

        unspentSplits[destinationAddress] = 0; // Set address pending split to 0
    }
}