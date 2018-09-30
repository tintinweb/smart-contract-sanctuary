pragma solidity ^0.4.18;


contract A {
    
    int[] public intArray;
    uint[] public uintArray;
    bytes32[] public bytes32Array;
    bytes2[] public byteArray;
    address[] public addressArray;
    string[] public stringsArray;
    
    string public slovo;
    function setWord() public {
        slovo = "huj";
    }
    
    function ssword(string _word) public {
        slovo = _word;
    }
}