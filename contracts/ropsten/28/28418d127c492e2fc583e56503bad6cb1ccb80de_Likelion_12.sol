/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//younwoo noh

pragma solidity 0.8.0;

contract Likelion_12 {
    uint[] numbers;
    uint[] preblockhash;
    string[] char;
    uint[] blockhash;
    bytes32 hash;
    
    function hashing(uint a, string memory b) public{
    hash = keccak256(abi.encodePacked(a, b));
    }
    
    function setBlockheader(uint _number, uint _preblockhash, string memory _char, uint _blockhash) public {
        numbers.push(_number);
        preblockhash.push(_preblockhash);
        char.push(_char);
        blockhash.push(_blockhash);
    }
}