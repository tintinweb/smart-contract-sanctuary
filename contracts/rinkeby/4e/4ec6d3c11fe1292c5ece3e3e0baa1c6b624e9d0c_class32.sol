/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }
    
    // query balance
    function queryOwnerBalance() public view returns(uint){
        return owner.balance;
    }
    function queryContractBalance() public view returns(uint){
        return address(this).balance;   // address(this) means this contract's address
    }
    
    // different between send and transfer: return type
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);    // contract send money to owner
        return reuslt;
    }
    function transfer(uint money) public {
        owner.transfer(money);  // contract transfer money to owner
    }
    
    // contract selfdestruct: if destruct, this contract cannot be used any more!
    function destruct() public {
        require(msg.sender==owner, "Error: Only contract onwer can call this function."); // check is the owner
        selfdestruct(msg.sender);
    }
}