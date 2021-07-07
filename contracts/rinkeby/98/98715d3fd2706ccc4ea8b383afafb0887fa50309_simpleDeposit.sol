/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract simpleDeposit {
    address owner;
    string name;
    uint amount;
    
    constructor (string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
        }
    function Deposit () payable public {
        amount = amount+msg.value;
    }
    function checkBalance () public view returns(uint){
    return amount;
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    function Withdraw(uint funds) public isOwner {
        if(funds <= amount){
          msg.sender.transfer(funds);
          amount = amount - funds;
       }
        
    }
    
}