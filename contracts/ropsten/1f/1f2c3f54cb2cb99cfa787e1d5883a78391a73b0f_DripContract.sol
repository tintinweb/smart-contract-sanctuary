pragma solidity ^0.4.24;

contract DripContract
{
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public
    {
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
        require(address(this).balance >= 10 finney, "Insufficient balance");
        msg.sender.transfer(10 finney);
    }
    
    function deposit(uint256 amount) payable public
    {
        require(msg.value == amount, "Amount doesn&#39;t match");
    }
    
    function getBalance() public view returns (uint256)
    {
        return address(this).balance;
    }
}