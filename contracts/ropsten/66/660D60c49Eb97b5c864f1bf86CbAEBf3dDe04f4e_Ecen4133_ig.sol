/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.6.0;

contract Ecen4133_ig {
    int256 x = 5;
    address owner;  // The address of the creator of this contract
    
    // This function called once on contract deployment
    constructor() public {
        owner = msg.sender;
    }
    
    // Calling this function requires making a transaction
    function addOne() public {
        x += 1;
    }
    
    // Interacting with this function does NOT require making a transaction
    function whatIsX() public view returns (int256) {
        return x;
    }
    
    // Caller of this function will be in msg.sender
    function subOne() public payable {
        require(msg.sender == owner || msg.value > 1 ether);
        x -= 1;
    }
}