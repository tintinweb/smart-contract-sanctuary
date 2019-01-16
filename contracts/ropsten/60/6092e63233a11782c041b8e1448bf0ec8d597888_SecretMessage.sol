pragma solidity >=0.4.22 <0.6.0;

contract SecretMessage {
    address public owner;
    string private secret;

    constructor(string memory _secret) public {
        owner = msg.sender;
        secret = _secret;
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    
    function GetSecret() external view onlyOwner returns (string memory) {
        return secret;
    }
}