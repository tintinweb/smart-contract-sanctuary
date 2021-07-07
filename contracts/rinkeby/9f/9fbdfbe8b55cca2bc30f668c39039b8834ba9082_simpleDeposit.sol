/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract simpleDeposit {
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
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw(uint funds) public onlyOwner {
        // if(funds <= amount) {
        //     msg.sender.transfer(funds);
        //     updateBalance(funds);
        // }
        
        require(funds<=amount);
        msg.sender.transfer(funds);
        updateBalance(funds);
    }
}