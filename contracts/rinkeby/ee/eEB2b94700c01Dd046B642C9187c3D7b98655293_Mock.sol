pragma solidity =0.8.6;

contract Mock { 
    
    function addUnitList() external view returns(uint256[7000] memory list) {
        for (uint256 i = 0; i < 10000; i++) {
            list[i] = i;
        }
    }
}

