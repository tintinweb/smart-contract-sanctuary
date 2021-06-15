/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract RPS {
    enum HAND{ ROCK, PAPER, SCISSORS }
    
    address private player1;
    HAND private hand1;
    uint256 private wager;
    
    address private player2;
    HAND private hand2;
    
    function placeWager(HAND h) public payable {
        require(msg.value > 0.0001 ether, "Wager too small");
        require(player1 == address(0), "Bet has been already initialized");
        player1 = msg.sender;
        hand1 = h;
        wager = msg.value;
    }
    
    function acceptWager(HAND h) public payable {
        require(player1 != address(0), "Bet has not been initialized yet");
        require(player2 == address(0), "No more room in this round");
        require(msg.value == wager, "Wager must be matched");
        player2 = msg.sender;
        hand2 = h;
    }
    
    function beats(HAND a, HAND b) private pure returns(bool) {
        return (a == HAND.ROCK && b == HAND.SCISSORS)
            || (a == HAND.SCISSORS && b == HAND.PAPER)
            || (a == HAND.PAPER && b == HAND.ROCK);
    }
    
    modifier isWinner() {
        require(player1 != address(0), "Bet isn't resolved");
        require(player2 != address(0), "Bet isn't resolved");
        require(player1 == msg.sender || player2 == msg.sender, "Only players can withdraw money");
        if(msg.sender == player1) {
            require(beats(hand1, hand2));
        } else {
            require(beats(hand2, hand1));
        }
        _;
    }
    
    function withdraw() public isWinner{
        player1 = address(0);
        player2 = address(0);
        payable(msg.sender).transfer(wager * 2);
    }
}