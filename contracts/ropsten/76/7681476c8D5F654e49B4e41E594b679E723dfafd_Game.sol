/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Game{
    uint public ans;
    bool public win;
    constructor() {
        ans = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 9000) + 1000;
        win = false;
    }
    
    error NotInRange(uint num);
    
    modifier checkGuessRange(uint _num) {
        if (_num < 1000 || _num >= 10000)
            revert NotInRange(_num);
        _;
    }
    
    function guess(uint num) public payable checkGuessRange(num) {
        require(msg.value == 1 gwei);
        win = (num == ans);
    }
    
}