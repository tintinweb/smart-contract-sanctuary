/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity >=0.8.7;
 
contract Game{
    string[] public picks = ["rock", "paper", "scissors"];
    address owner;
 
    constructor(){
        owner = msg.sender;
    }
 
    function getFromPicks(uint index) public view returns (string memory) {
        require (picks.length > index, "IndexError");
        return picks[index];
    }
    
    function getFromPicks2(uint index) public returns (string memory) {
        return picks[index];
    }
    
    
    function getOwner() public view returns(address){
        return owner;
    }
 
    function balanceOf() public view returns(uint256){
        return address(this).balance;
    }
 
    function withdraw2() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
 
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
 
    function withdraw() public payable{
        require (msg.sender == owner, "Sender not owner");
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function chekcWin(string memory userChoice, string  memory compChoice) private returns(string memory) {
        if (keccak256(abi.encodePacked(compChoice)) == keccak256(abi.encodePacked(userChoice))) {
            return "draw";
        } else {
            return "lose";
        }
    }
 
 
    function play(string memory userChoice) public returns(string memory) {
        uint resRandom = getRandom();
        string memory compChoice = getFromPicks(resRandom);
        string memory result = chekcWin(compChoice, compChoice);
        return result;
    }
    
    function play2(string memory userChoice) public returns(string memory) {
        uint resRandom = getRandom();
        string memory compChoice = getFromPicks2(3);
        string memory result = chekcWin(compChoice, compChoice);
        return result;
    }
 
 
    function getTestRandom() private returns (uint res){
        uint res = 0;
        return res;
    }
    
    function getRandom() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % picks.length;
        
    }
 
}