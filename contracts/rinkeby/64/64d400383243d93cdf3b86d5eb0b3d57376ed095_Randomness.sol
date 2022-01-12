/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract Randomness {

    address private owner;
    uint private _seed;
    address private game;

    constructor() {
        owner = msg.sender;
    }

    function setGame(address _game) external {
        require(msg.sender == owner);
        game = _game;
    }

    function update(uint256 __seed) external {
        require(msg.sender == game);
        _seed = __seed;
    }

    function seed() external view returns(uint256) {
        require(msg.sender == game);
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, _seed)));
    }
}