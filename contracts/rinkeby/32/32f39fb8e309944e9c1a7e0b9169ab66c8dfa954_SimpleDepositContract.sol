/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract SimpleDepositContract {
    
    address owner;
    string name;
    uint amount;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    function receiveDeposit() payable public {
        amount = amount + msg.value;
    }
    
    function checkBalance() public view returns(uint) {
        return amount;
    }
    
    // modifier to check if requestor is owner of contract
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw(uint funds) public onlyOwner {
        msg.sender.transfer(funds);
    }
    
}