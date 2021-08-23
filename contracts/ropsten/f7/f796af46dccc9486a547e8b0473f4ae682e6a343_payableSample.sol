/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity 0.7.5;

contract  payableSample {

    //add the keyword payable to the state variable
    address payable public Owner;
    

    //set the owner to the msg.sender
    constructor () public {
        Owner = msg.sender; 
    }
    
    

    //create a modifier that the msg.sender must be the owner
    modifier onlyOwner() {
        require(msg.sender == Owner, 'Not owner');
        _;
    }
    
    function invest() external payable {}

    //the owner can withdraw from the contract because payable was added to the state variable above
    function withdraw (uint _amount) public onlyOwner {
        Owner.transfer(_amount); 
    }
    

    //to.transfer works because we made the address above payable.
    function transfer(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount); //to.transfer works because we made the address above payable.
    }
}