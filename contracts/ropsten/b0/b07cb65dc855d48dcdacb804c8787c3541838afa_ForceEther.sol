pragma solidity ^0.4.24; // Specify compiler version

contract ForceEther {
    function Deposit() public payable {

    }
    
    function Force(address destination) public {
        selfdestruct(destination); // Self destruct
    }
}