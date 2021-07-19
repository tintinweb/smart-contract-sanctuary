/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.8.4;

contract BNB_Storage {
    address public owner;
    address public storage_contract;
    mapping (address => uint) public balances;
    
    event Transfer( address indexed from, address indexed to, uint value);

    constructor() public {
        owner = msg.sender;
        storage_contract = address(this);
    }
    
    function DepositBNB() public payable{
         balances[msg.sender] += msg.value;
    }
    function WithdrawBNB(address bnb_receiver, uint bnb_amount) public {
        emit Transfer(storage_contract, bnb_receiver, bnb_amount);
    }
    

   

}