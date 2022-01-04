pragma solidity ^0.8.9;

contract ShuffleTest {

    mapping(uint => uint) public tokenIdToSerum;


    function allocate(uint[] memory array, uint seed) public pure returns (uint[] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = uint256(keccak256(abi.encodePacked(seed))) % (array.length - i);
            uint256 temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }
        return array;
    }
}