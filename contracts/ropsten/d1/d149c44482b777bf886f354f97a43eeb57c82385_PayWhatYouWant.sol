pragma solidity 0.5.2;

contract PayWhatYouWant 
{
    // The address to forward the deposits to
    address payable public adminAddress;
    
    // Event to broadcast a Deposit on a payable function
    event Deposited(address fromAddress, uint value);
    
    // Setup the contract and the address to forward deposits to
    constructor(address payable _admin) public
    {
        adminAddress = _admin;
    }
    
    // Method for people to deposit into to broadcast an event
    function deposit() public payable
    {
        emit Deposited(msg.sender, msg.value);
        adminAddress.transfer(msg.value);
    }
    
}