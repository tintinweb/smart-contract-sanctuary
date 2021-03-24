// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./Ownable.sol";

interface Token {
    function transfer(address to, uint256 value) external;
}

contract SwapAll is Ownable {

    constructor () Ownable(msg.sender) payable {}

    fallback() external payable {}

    receive() external payable {}

    function transferToken(address coin, address[] calldata dsts, uint256[] calldata values) public onlyOwner{
        require(dsts.length == values.length);
        Token token = Token(coin);
        uint256 total = 0;
        uint256 count = dsts.length;
        for (uint256 i = 0; i < count; i++) {
            token.transfer(dsts[i], values[i]);
            total += values[i];
        }
    }

    function transferEth(address payable[] calldata dsts, uint256[] calldata values) public onlyOwner{
        require(dsts.length == values.length);
        uint256 total = 0;
        for (uint256 i = 0; i < dsts.length; i++) {
            dsts[i].transfer(values[i]);
            total += values[i];
        }
    }
}