pragma solidity ^0.4.0;
// Nicole Weber
contract Lottery {

    struct Player {
        uint etherAmt;
        address delegate;
    }

    address public chairperson;
    address public winner;
    Player[] public players;
    //mapping(address => Player) public players;
    uint public count = 0;
    uint public totalEtherAmt = 0;
    address[] public weightedArray;

    constructor() public {
        players.length = 5;
        chairperson = msg.sender;
    }
    
    function enterLottery() public payable {
        Player memory newPlayer;
        newPlayer.etherAmt = msg.value;
        newPlayer.delegate = msg.sender;
        players[count] = newPlayer;
        totalEtherAmt = totalEtherAmt + newPlayer.etherAmt;
        count++;
        if(count==5) {
            pickWinner();
            count = 0;
            totalEtherAmt = 0;
        }
    }
    
    function determineWeights() public {
        weightedArray.length = totalEtherAmt;
        uint curPos = 0;
        for(uint i = 0; i < 5; i++) {
            for (uint j = 0; j < players[i].etherAmt; j++) {
                weightedArray[curPos] = players[i].delegate;
                curPos++;
            }
        }
    }
    
    function pickWinner() public returns (address) {
        uint myrandom = random();
        myrandom = myrandom%totalEtherAmt;
        determineWeights();
        weightedArray[myrandom].transfer(totalEtherAmt);
        winner = weightedArray[myrandom];
        return winner;
    }
    
    function random () private view returns(uint) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%251);
    }

}