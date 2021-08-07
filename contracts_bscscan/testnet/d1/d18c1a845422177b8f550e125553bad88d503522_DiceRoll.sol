/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

//define which compiler to use
pragma solidity ^0.5.0;

//contract name is MyFirstBSContract
contract DiceRoll {


    address payable public owner;
    uint public amount;
    mapping(address => uint) public choice;
    
    
    // owner is 
    constructor () public {
        owner = msg.sender; 
        
    }
    
//bet
    function bet(uint _value) public payable {
        require(_value>0 && _value<=6,'Value must belong to {1,2,3,4,5,6}.');
        require(choice[msg.sender] == 0,'Bet already done.');
  //      require(msg.sender.balance>amount);
        choice[msg.sender] = _value;
    }


    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, amount)));
    }
  
    function roll() private view returns (uint) {
        uint value = 1+random()%6;
        uint total = address(this).balance;
        
    }
  
  
//set the ammount to bet
    function setAmount(uint newAmount) public {
        require(msg.sender == owner, 'Only the owner can change the ammunt');
        require(newAmount >0 , 'Ammount must be non negative');
        amount = newAmount;
    }

//get
    function getAmount() public view returns (uint) {
        return address(this).balance;
    }
    

}