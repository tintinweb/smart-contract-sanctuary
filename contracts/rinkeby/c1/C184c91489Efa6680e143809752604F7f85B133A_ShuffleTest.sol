pragma solidity ^0.8.9;

contract ShuffleTest {

    mapping(uint => uint) public tokenIdToSerum;


    function allocate(uint[] memory array, uint seed) public pure returns (uint[] memory) {
        uint length = array.length;
        uint[] memory result = new uint[](length);
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(seed))) % (array.length - i);
            uint256 temp = array[n];
            result[n] = array[i];
            result[i] = temp;
        }
        return result;
    }
}