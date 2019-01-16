pragma solidity ^0.4.25;

contract Slot{
    address public owner;
    struct game{
        address player;
        bool win;
        uint256 amount;
        uint32 gameResult;
        uint256 reward;
    }
    
    game[] public games;
    
    event GameResult(
        address player,
        bool win,
        uint256 amount,
        uint8 number1,
        uint8 number2,
        uint8 number3,
        uint256 reward
        );
    
    constructor() public {
        owner = msg.sender;
    }
    
    function destroy() public{
        require(owner == msg.sender);
        selfdestruct(owner);
    }
    
    function chargeMoney() public payable{
        require(owner == msg.sender);
    }
    
    function bet() public payable{
        require(msg.value > 0);
        require(address(this).balance > msg.value*8);
        
        bool win = false;
        
        uint32 gameResult = uint32(blockhash(block.number-1))% 1000;
        uint8 n1 = uint8( gameResult / 100 );
        uint8 n2 = uint8( (gameResult%100) / 10 );
        uint8 n3 = uint8(  gameResult % 10 );
        
        uint256 reward = msg.value;
        
        if(n1 == n2) { reward = reward*2; win = true; }
        if(n2 == n3) { reward = reward*2; win = true; }
        if(n1 == n3) { reward = reward*2; win = true; }
        
        if(win){
            msg.sender.transfer(reward);
        } else {
            reward = 0;
        }
        emit GameResult( msg.sender, win, msg.value, n1, n2, n3, reward);
        games.push( game( msg.sender, win, msg.value, gameResult, reward));
    }
    
    
    function jackpot() public view returns (uint256) {
        return address(this).balance;
    }
    
}