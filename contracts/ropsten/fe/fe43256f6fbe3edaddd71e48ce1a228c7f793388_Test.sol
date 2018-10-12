pragma solidity ^0.4.25;


contract Test {
    
    struct Winner {
        address player;
        uint amount;
    }
    
    Winner[] Winners;
    
    function addWinners() public {
        Winners.push(Winner(0x8bA6dB1932235A8f4dC9AD2f18f841B5f264420d, 15));
        Winners.push(Winner(0x65170459431D2E86c60Cf6ee6C6E5f8c8Ff23db1, 7));
        Winners.push(Winner(0x6E88a83c1621DEdc87036B526C69AB18AEEDE7Bd, 24));
        Winners.push(Winner(0x33ab7847D0D11C676426003244A1D00CbfA25042, 19));
        Winners.push(Winner(0x7623299C25b14A6B0D32396C1f4F204A976e644E, 3));
        Winners.push(Winner(0xe9500e23eBb32cCB63e079bb2e1155CAFF21B012, 50));
        Winners.push(Winner(0x8bA6dB1932235A8f4dC9AD2f18f841B5f264420d, 15));
        Winners.push(Winner(0x65170459431D2E86c60Cf6ee6C6E5f8c8Ff23db1, 7));
        Winners.push(Winner(0x6E88a83c1621DEdc87036B526C69AB18AEEDE7Bd, 24));
        Winners.push(Winner(0x33ab7847D0D11C676426003244A1D00CbfA25042, 19));
        Winners.push(Winner(0x7623299C25b14A6B0D32396C1f4F204A976e644E, 3));
        Winners.push(Winner(0xe9500e23eBb32cCB63e079bb2e1155CAFF21B012, 50));
        Winners.push(Winner(0x8bA6dB1932235A8f4dC9AD2f18f841B5f264420d, 15));
        Winners.push(Winner(0x65170459431D2E86c60Cf6ee6C6E5f8c8Ff23db1, 7));
        Winners.push(Winner(0x6E88a83c1621DEdc87036B526C69AB18AEEDE7Bd, 24));
        Winners.push(Winner(0x33ab7847D0D11C676426003244A1D00CbfA25042, 19));
        Winners.push(Winner(0x7623299C25b14A6B0D32396C1f4F204A976e644E, 3));
        Winners.push(Winner(0xe9500e23eBb32cCB63e079bb2e1155CAFF21B012, 50));
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
    
    function showWinnersSort () public view returns (address, uint) {
        sort();
        return (
            Winners[0].player, Winners[0].amount
        );
    }
    
    function showWinners (uint i) public view returns (address, uint) {
        return (Winners[i].player, Winners[i].amount);
    }
    
    function winnersLength() public view returns (uint) {
        return Winners.length;
    }
}