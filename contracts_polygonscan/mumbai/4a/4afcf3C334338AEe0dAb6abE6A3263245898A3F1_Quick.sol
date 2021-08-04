/**
 *Submitted for verification at polygonscan.com on 2021-08-04
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract Quick {
    
    mapping(address => mapping(uint8 => uint8[])) public games;
    mapping(address => uint256) public blockNumbers;
    
    uint256 public a;
    
    constructor(uint256 _a) {
        a = _a;
    }
    
    function divine(uint8 _number) public pure returns(uint8, uint8) {
        return (_number / 13, _number % 13);
    }
    
    function getCardsPower(uint8 _card) public pure returns(uint8) {
        bytes13 cardsPower = "\x0B\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0A\x0A\x0A";
        return uint8(cardsPower[_card % 13]);
    }
    
    function getRandom(bytes32 _localhash, uint256 _length) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_localhash, _length)));
    }
    
    function test(uint256 _randomness, uint256 _nonce) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_randomness, _nonce)));
    }
    
    function game(address _player, uint8 _gameId) public {
        uint8[3] memory balance = [1, 2, 3];
        games[_player][_gameId] = balance;
    }
    
    function setBlock() public {
        blockNumbers[msg.sender] = block.number + 1;
    }
    
    function getBlock() public view returns(uint256) {
        return block.number;
    }
    
    function getBlockHash(address _address) public view returns(bytes32) {
        return blockhash(blockNumbers[_address]);
    }

}