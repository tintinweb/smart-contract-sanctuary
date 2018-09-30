pragma solidity^0.4.24;

contract BadSender {
    // Forward funds to the splitter contract
    function forward(address address1, address address2) payable {
        // This is the address of the splitter contract
        address splitterContract = 0x139Fc1169B70D222FF8ed018fF53c64e14b6597a;
        Splitter splitter = Splitter(splitterContract);
        splitter.split.gas(200000).value(msg.value)(address1, address2);
    }

    // Purely malevolent fallback
    function () {
        revert();
    }
}

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