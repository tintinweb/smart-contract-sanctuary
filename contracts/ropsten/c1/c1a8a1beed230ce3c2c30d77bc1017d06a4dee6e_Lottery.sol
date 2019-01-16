pragma solidity ^0.4.11;

contract Lottery {
    
    mapping(address => uint) allBets;
    mapping(uint => address) allUsers;
    uint totalUsers = 0;
    uint totalBets = 0;
    
    address owner;
    
    function Lottery() {
        owner = msg.sender;
    }
    
    function Bet() public payable {
        if (msg.value > 0) {
            if(allBets[msg.sender] == 0) {
                allUsers[totalUsers] = msg.sender;
                totalUsers += 1;
            }
            allBets[msg.sender] += msg.value;
            totalBets += msg.value;
        }
    }
    
    function FinishLottery() public {
        if (msg.sender == owner) {
            uint sum = 0;
            uint winningDraw = uint(block.blockhash(block.number-1)) % totalBets + 1;
            for (uint i = 0; i < totalUsers; i++){
                sum += allBets[allUsers[i]];
                if( sum >= winningDraw) {
                    selfdestruct(allUsers[i]);
                    return;
                }
            }
        }
    }
}