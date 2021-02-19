// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ETHSplitter {
    address payable public address1;
    address payable public address2;

    constructor(address payable givenAddress1, address payable givenAddress2)
        public
    {
        address1 = givenAddress1;
        address2 = givenAddress2;
    }

    receive() external payable {
        uint256 splitAmount = msg.value / 2;
        address1.transfer(splitAmount);
        address2.transfer(splitAmount);
    }
}