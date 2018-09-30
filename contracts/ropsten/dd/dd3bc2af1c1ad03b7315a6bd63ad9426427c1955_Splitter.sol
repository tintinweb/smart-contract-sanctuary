pragma solidity^0.4.24; // Specify compiler version

// Init splitter contract
contract Splitter {
    mapping (address => uint256) unspentSplits; // Store pending withdrawals

    function split(address destinationAddresses1, address destinationAddress2) public payable {
        unspentSplits[destinationAddresses1] = msg.value / 2;
        unspentSplits[destinationAddress2] = msg.value / 2;
    }

    function withdraw() public {
        sendEth(msg.sender); // Send ether
    }

    function sendEth(address destinationAddress) internal {
        destinationAddress.transfer(unspentSplits[destinationAddress]); // Attempt to transfer to specified address

        unspentSplits[destinationAddress] = 0; // Set address pending split to 0
    }
}