/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity >=0.4.22 <0.6.0;
contract DepositAccount {
    address owner;
    uint public numberOfEntries;

    event NewEntry(address depositer, uint number);

    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw() public {
        require(owner == msg.sender);

        msg.sender.transfer(address(this).balance);
    }
    
    function withdraw(uint256 amount) public {
        require(owner == msg.sender);
        require(address(this).balance >= amount);
        
        msg.sender.transfer(amount);
    }
    
    function payment(uint _number) payable external {
        numberOfEntries++;
        emit NewEntry(msg.sender, _number);
    }

   // address of sender
    function getSender(
    ) public view returns (address) {    
        return msg.sender;
        
    }
}