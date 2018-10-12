pragma solidity ^0.4.24;

contract DripContract
{
    /* Define variable owner of the type address */
    address owner;
    bool ownerSet = false;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public
    {
        require(ownerSet == false);
        owner = msg.sender;
        
    }

    /* Function to recover the funds on the contract */
    function kill() public
    {
        if (msg.sender == owner)
        {
            owner.transfer(address(this).balance);
            selfdestruct(owner);
        }
    }
    
    function drip() public
    {
        require(address(this).balance >= 10 finney);
        msg.sender.transfer(10 finney);
    }
    
    function deposit(uint256 amount) payable public
    {
        require(msg.value == amount);
    }
    
    function getBalance() public view returns (uint256)
    {
        return address(this).balance;
    }
}