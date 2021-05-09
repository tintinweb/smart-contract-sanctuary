/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

pragma solidity ^0.5.0;

contract MyFaucet{
    event Deposit(address from, uint amount);
    event Withdraw(address to, uint amount);
    
    address payable public owner;
    
    constructor() public { owner = msg.sender; }
    
    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner of this contract can access this!");
        _;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function withdraw(uint256 a) public{
        require(a <= 100, "Cannot withdraw more than 100 wei!");
        require(a <= address(this).balance, "Insufficient funds in contract!");
        
        msg.sender.transfer(a);
        emit Withdraw(msg.sender, a);
    }
    
    function () external payable{
        emit Withdraw(msg.sender, msg.value);
    }
    
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}