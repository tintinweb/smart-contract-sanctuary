/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity ^0.5.1;
contract PiggyBank {
    
    uint public savingGoal;
    uint public savedAmount;
    address payable public beneficiary;
    
    constructor(uint _savingGoal, address payable _benficiary) public payable {
        savingGoal = _savingGoal; 
        savedAmount = msg.value;
        beneficiary = _benficiary;
    }
    
    function() external payable { }
    
    function breakPiggyBank() public payable {
        if (address(this).balance > savingGoal) {
                beneficiary.send(address(this).balance);
            }
    }
        
}