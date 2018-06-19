pragma solidity 0.4.22;

// EthGraffiti.com

// A stupid internet experiment
// Will probably give you cancer

contract EthGraffiti {
    
    address owner;
    uint public constant MESSAGE_PRICE = 69 wei;
    mapping (uint => string) public messages;
    uint public messageNumber;
    
    constructor () public {
        owner = msg.sender;
    }
    
    function sendMessage(string message) public payable {
        require (msg.value == MESSAGE_PRICE);
        messages[messageNumber] = message;
        messageNumber++;
    }
    
    function withdraw() public {
        require (msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}