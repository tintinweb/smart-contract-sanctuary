pragma solidity ^0.4.8;


contract Lottery {
    
    mapping (address => uint256) winnings;
    address [] spots;
    
    string public name = "Lottery";
    uint public remainingSpots = 5;
    uint public rand = 0;
    address public winner;
    
    function Lottery() public {
    }
    
    //function to enter an address into the lottery
    function Enter() public payable {
        require(msg.value == 1000000000000000000); //Requires that each sender wagers 1 ether. 
        uint buyIn = msg.value;
        require(remainingSpots > 0); //There must be a spot for a user to enter
        spots.push(msg.sender); //pushes address into array of spots
        remainingSpots -= 1;
        
    }
    //Given randomizer function mod 5
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now)) % 5; 
    }
    
    //
    function RunLottery() public {
        require(remainingSpots == 0); //lottery must wait for 5 addresses
        rand = random(); 
        winner = spots[rand]; //random index chosen 
        remainingSpots = 5; //resets remaining spots
        winnings[winner] = 5; //winnings value is collected ether from players
        
        //resets spots
        for (uint i = 0; i < 4; i++) {
            spots[i] = 0;
        }
        
    }
    
    //Sends winning address the collected 5 ether
    function DepositFunds() public {
        winner.transfer(winnings[winner] * 1000000000000000000); //sends ether to winner
        winnings[winner] = 0; //resets winnings
    }

    
    
}