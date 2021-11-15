contract Faucet {
    // Save a list of people who received test ether
    mapping (address => bool) public received;
    
    // The size of the 
    uint public drip = 0.1 ether;
    
    // Owner has special permissions
    address owner = msg.sender;

    receive() external payable {
        require(msg.value > 0, "You have to send some ether to receive eternal gratitude");
        emit EternalGratitude(msg.sender, msg.value);
    }
    
    function request() external {
        address payable requester = payable(msg.sender);
        
        require(received[requester] == false, "Already received funds from faucet");
        received[requester] = true;
        
        requester.transfer(drip);
    }
    
    function setDrip(uint _drip) external {
        require(owner == msg.sender, "Only owner can change drip");
        
        drip = _drip;
    }

    event EternalGratitude(address, uint);
}

