pragma solidity ^0.4.0;
contract CSE297P2 {

    uint public pot;
    uint public contestantIndex;
    address[] public addresses;
    
    constructor () public {
        contestantIndex = 0;
        pot = 0;
        addresses.length = 5;
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, 5));
    }

    function enterLottery() public payable {
        pot += msg.value;
        if (msg.value >= 1 ether) {
        addresses[contestantIndex] = msg.sender;
            if (contestantIndex == 4) {
                startLottery();
            }
        contestantIndex++;
        }
    }

    function startLottery() private {
        address winner = addresses[random() % 5];
        winner.transfer(pot);
        contestantIndex = 0;
        pot = 0;
    }
    
}