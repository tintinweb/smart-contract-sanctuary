pragma solidity ^0.4.23;

contract EventTest {
    
    address public owner;
    uint256 public incr;
    event Converted(address indexed who, string destinationAccount, uint256 amount, string extra);
    
    constructor() public {
        owner = msg.sender;
        incr = 10000000;
    }
    
    
    function convertMainchain(string destinationAccount, string extra) external returns (bool) {
        incr += 1000;
        emit Converted(msg.sender, destinationAccount, incr, extra);
        return true;
    }
    
}