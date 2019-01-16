pragma solidity >=0.5.2 <0.6.0;

contract Broadcaster {
    event Broadcast(address author, string text);

    mapping (address => string) displayNames;

    function getDisplayName(address owner) public view returns(string memory) {
        return displayNames[owner];
    }
    
    function setDisplayName(string memory displayName) public {
        displayNames[msg.sender] = displayName;
    }
    
    function broadcast(string memory message) public {
        emit Broadcast(msg.sender, message);
    }
}