pragma solidity ^0.4.0;

contract Lottery{
    
    address public owner;
    address[5] public userIds;
    uint count;
    
    constructor () public {
        owner = msg.sender;
        count = 0;
    }
    
    function enterLottery() public payable{
        userIds[count] = msg.sender;
        count = count + 1;
        
        if(count == 4)
            generateWinner();
            count = 0;
    }
    
    function getRandom() public returns(uint) {
        return random();
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, userIds));
    }
    
    function generateWinner() public {
        if(count == 4)
            uint index = random() % userIds.length;
            userIds[index].transfer(address(this).balance);
    }
}