pragma solidity ^0.4.0;
contract Lottery {
 //Maryam Khan
 //CSE 297 - Project 2

    address winner;
    uint amountWon;
    
    struct Player {
        uint wagerAmount; //amount the person is waging
        address target; // the person&#39;s own address&#39;
        bool played;
    }
    
    address[] playersAdd;
    uint peopleCount = 0;
    uint collectedFunds = 0;
    bool lotteryState;
    address public owner; 
    Player[] public players;
    
    //// declare an owner
    constructor () public payable {
        owner = address(this);
        lotteryState = true;
    }
    
    //// Choose a person to give money too
    function addtoLottery () public payable{
        
          
        players.push(Player({wagerAmount: msg.value, target: msg.sender, played: true}));
        collectedFunds += msg.value;
        playersAdd.push(msg.sender);
        owner.send(msg.value);
    }
    
    //// determine winner
    function determineWinner() public {
        require(players.length == 5, "We need to have five people in the lottery in order to play it.");
        uint whoWon = random() % players.length;
        (players[whoWon].target).send(collectedFunds/2);
        uint balancetoTransfer = collectedFunds - collectedFunds/2;
        balancetoTransfer = balancetoTransfer/4;
        for (uint j =0; j<5; j++) {
            if (j != whoWon) {
                (players[j].target).send(balancetoTransfer);
            }
        }
        lotteryState = false;
        collectedFunds = 0;
        
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, playersAdd));
    }
    
       
}