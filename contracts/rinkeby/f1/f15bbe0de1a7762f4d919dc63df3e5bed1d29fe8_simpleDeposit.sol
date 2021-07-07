/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract simpleDeposit{
    address owner;
    string name;
    uint amount;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    function receiveDeposit(uint _amount) payable public {
        amount = amount + _amount;
    }
    
    function checkBalance() public view returns(uint){
        return amount;
    }
    
    function withDraw(uint funds) public {
        msg.sender.transfer(funds);
    }
}