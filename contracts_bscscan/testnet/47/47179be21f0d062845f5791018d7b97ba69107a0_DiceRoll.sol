/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

//define which compiler to use
pragma solidity ^0.5.0;

//contract name is MyFirstBSContract
contract DiceRoll {


    address payable public owner;
    uint public amount;
    uint public round;
    mapping(uint => address payable []) public choice;
    mapping(address => uint) public history;
    
    // owner is 
    constructor () public {
        owner = msg.sender; 
        amount = 10000000000000000;
        round = 1;
    }
    
//bet
    function bet(uint _value) public payable {
        require(_value>0 && _value<=6,'Value must belong to {1,2,3,4,5,6}.');
        require(history[msg.sender] < round,'Bet already done.');
        require(msg.value==amount);
        choice[_value].push(msg.sender);
        history[msg.sender] = round;
    }


    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, amount)));
    }
  
    function roll() private returns (uint) {
        require(msg.sender == owner, 'Only can roll the dice.');
        uint value = 1+random()%6;
        value = 1; // testing
        uint total = address(this).balance;
        uint winners;    
        winners = choice[value].length;
        if(winners>0){
            uint topay = total/winners;
            for(uint i = 0 ; i<winners; i++){
                choice[value][i].transfer(topay);
            }
        }
        
        
        round++;
        return value;
    }
  
  
//set the ammount to bet
    function setAmount(uint newAmount) public {
        require(msg.sender == owner, 'Only the owner can change the amount.');
        require(newAmount >0 , 'Ammount must be non negative');
        amount = newAmount;
    }

//get
    function getAmount() public view returns (uint) {
        return address(this).balance;
    }
//get
    function getRound() public view returns (uint) {
        return round;
    }
    

}