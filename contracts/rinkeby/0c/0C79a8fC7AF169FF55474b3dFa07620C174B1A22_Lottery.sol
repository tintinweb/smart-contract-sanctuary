/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.8.2;

contract Lottery {
    
    address payable public manager; //Creator of the contract and manager for the lottery 
    address payable[] public players; //Players in the lottery and payable because one of them will get the entire contract balance
    
    constructor() {
        manager = payable(msg.sender); //ddress of the account who instantiated the contract
    }
    
    function enter() public payable { // payable is used when some ETH has to be sent to the function
    //require function is used to ensure some criteria is satisfied before rest of the function is executed
        require(msg.value > 0.01 ether, "You need to send more than 0.01 ETH to enter the Lottery"); 
        players.push(payable(msg.sender));
    }
    
    function random() private view returns(uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, block.number, players))); //block is a global object giving access to current block properties 
      //uint function converts the hash into uint and returns the uint value
    }
    
    function pickWinner() public onlyOwner {
        uint index = random() % players.length; //get the random players array index
 
        players[index].transfer(address(this).balance); //this will be an address and address is an object having properties and methods
        
    //Reset state of the players array so next round of lottery can start fresh        
        players = new address payable[](0); //New Dynamic Array with initial size of 0
    }
    
    // this is a check defined on the pickWinner function
    modifier onlyOwner() {
        require(msg.sender == manager, "Only Owner Can Call This Function");
        _; //end of modifier
    }
    
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }
}