pragma solidity ^0.4.25;


contract Test {
    
    struct Winner {
        address player;
        uint amount;
    }
    
    Winner[] Winners;
    
    function addWinners(uint num) public {
        for (uint i = 0; i < num; i++){
            Winners.push(Winner(0x8bA6dB1932235A8f4dC9AD2f18f841B5f264420d, random(i)));
        }
    }
    
    function sort() public view {
        Winner memory tmp;
        for (uint i = 0; i < winnersLength() - 1; i++){
            for (uint j = 0; j < winnersLength() - 1; j++){
                if (Winners[j + 1].amount > Winners[j].amount) {
                    tmp = Winners[j];
                    Winners[j] = Winners[j + 1];
                    Winners[j + 1] = tmp;
                }
            }
        }
    }
    
    function showWinnersSort () public view returns (address, uint, address, uint, address, uint, address, uint, address, uint) {
        sort();
        return (
            Winners[0].player, Winners[0].amount,
            Winners[1].player, Winners[1].amount,
            Winners[2].player, Winners[2].amount,
            Winners[3].player, Winners[3].amount,
            Winners[4].player, Winners[4].amount
        );
    }
    
    function showWinners (uint i) public view returns (address, uint) {
        return (Winners[i].player, Winners[i].amount);
    }
    
    function winnersLength() public view returns (uint) {
        return Winners.length;
    }
    
    function random (uint i) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty,
            block.coinbase,
            msg.sender,
            i
        )));
    }
}