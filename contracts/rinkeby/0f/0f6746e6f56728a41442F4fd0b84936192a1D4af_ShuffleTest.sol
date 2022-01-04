pragma solidity ^0.8.9;

contract ShuffleTest {
    function shuffle(uint[] memory array, uint seed) public pure returns (uint[] memory) {
        uint length = array.length;
        uint[] memory result = new uint[](length);
        for (uint i = 0; i < length; i++) {
            result[i] = array[i];
        }
        for (uint h = 0; h < length; h++) {
            uint j = uint256(keccak256(abi.encodePacked(seed))) % (length - h);
            uint temp = result[h];
            result[h] = result[j];
            result[j] = temp;
        }
        return result;
    }
}