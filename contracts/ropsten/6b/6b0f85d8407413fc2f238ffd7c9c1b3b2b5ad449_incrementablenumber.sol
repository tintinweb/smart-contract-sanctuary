//LAB 1 Simple Counter Contract
//This contract creates a counter that can only be incremented by address that deployed the contract or another approved address.


pragma solidity ^0.4.25;


contract incrementablenumber {
    
    uint256 private counter;
    address public owner;
    address public approvedAddress;
    
    //This is the constructor function. In the body set the owner variable to the address that deployed the contract (IE msg.sender)
    constructor() public {
        owner = msg.sender;
}
    //this function will return the current value of the counter variable
    function getCount() public view returns (uint256){
        return counter;
    }
    //This function will increment the counter variable by one ONLY if the caller is the owner of the contract or the approved address
    function incCounter() public{
        if (msg.sender==owner || msg.sender == approvedAddress)
            counter++;
    }

    //This function will set the approvedAddress to _approvedAddress ONLY if the caller is the owner of the function.
    function setApprovedAddress(address _approvedAddress) public{
        if (msg.sender==owner)
            approvedAddress=_approvedAddress;
    }

//To submit the lab deploy the contract to ropsten, verify the contract on etherscan, and set approved address to the instructors ethereum address 0x0fe83e8a12E88A16BeD8d1c8dc2210dAFE1Fc33b


//Send the address of the contract to the instructor. The instructor needs to be able to increment the counter using their ethereum account.
}