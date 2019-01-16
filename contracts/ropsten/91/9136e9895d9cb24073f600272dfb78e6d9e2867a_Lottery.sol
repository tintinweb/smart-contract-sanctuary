pragma solidity ^0.4.25;
contract Lottery{
    
    uint totalAmount;
    uint numOfPlayers = 0;
    mapping (uint => address) players;
    mapping (address => bool) participated;
    enum State {Accepting, Distributing, Paid}
    State state;
    constructor() public{
        state = State.Accepting;
    }
    function wager() public payable joinable{
        if(msg.value > 0){
            if(participated[msg.sender] == false){
                players[numOfPlayers] = msg.sender;
                participated[msg.sender] = true;
                numOfPlayers++;
                if (numOfPlayers == 5){
                    state = State.Distributing;
                }
            }
            totalAmount += msg.value;
            if (state == State.Distributing){
                selectWinner();
            }
        }
    }
    
    modifier joinable(){
        require (state == State.Accepting);
        _;
    }
    modifier isFinished(){
        require (state == State.Distributing);
        _;
    }
    modifier restatable(){
        require (state == State.Paid);
        _;
    }
    function selectWinner() private isFinished{
        uint winner = random()%5;
        players[winner].transfer(totalAmount);
        state = State.Paid;
        restart();
    }
    
    function restart() private restatable{
        totalAmount = 0;
        numOfPlayers = 0;
        for (uint i = 0; i < 5; i++){
            participated[players[i]] = false;
        }
        state = State.Accepting;
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, 5));
    }

}