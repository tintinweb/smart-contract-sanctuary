/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: GPL-3.0

interface IGrexieV2 {
    function receiveTokens() external;
}

contract GrethnicCleanser {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    function cleanse(uint _mintAmount, uint _mintGoal, address _target) onlyOwner external {
        uint repetitions = (_mintGoal + _mintAmount - 1) / _mintAmount;
        for (uint i = 0; i < repetitions; i++) {
            IGrexieV2(_target).receiveTokens();
        }
    }
}