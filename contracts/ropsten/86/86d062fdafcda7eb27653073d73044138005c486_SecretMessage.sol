pragma solidity ^0.5.2;

contract SecretMessage {
    string private secret;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    
    function SetSecret(string calldata _secret) external onlyOwner {
        secret = _secret;
    }
}