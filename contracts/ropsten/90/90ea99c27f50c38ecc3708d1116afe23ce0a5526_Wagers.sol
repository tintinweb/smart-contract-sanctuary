// Luke Bernick
// CSE 297 Project 2

pragma solidity ^0.4.25;

contract Wagers {
    uint num_wagers;
    uint jackpot;
    address[5] gamblers;
    address private owner;
    
    constructor() public {
        num_wagers = 0;
        jackpot = 0;
        owner = msg.sender;
    }
    
    function decide_winner () private {
        uint winner = random() % 5;
        uint current_jackpot = jackpot;
        num_wagers = 0;
        jackpot = 0;
        gamblers[winner].transfer(current_jackpot);
    }
    
    function bet () public payable {
        require (
            msg.value > 0,
            "Must provide money to bet"
        );
        
        gamblers[num_wagers] = msg.sender;
        jackpot += msg.value;
        num_wagers++;
        
        if(num_wagers == 5) {
            decide_winner();
        }
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, gamblers)));
    }
    
    function get_num_wagers() public view returns(uint) {
        require (
            msg.sender == owner,
            "Only owner can access this!"
        );
        
        return num_wagers;
    }
    
    function get_jackpot() public view returns(uint) {
        require (
            msg.sender == owner,
            "Only owner can access this!"
        );
        
        return jackpot;
    }
    
    function get_gambler(uint num) public view returns(address) {
        require (
            msg.sender == owner,
            "Only owner can access this!"
        );
        require (
            num <= num_wagers,
            "Not that many wagers yet"
        );
        
        return gamblers[num];
    }
}