/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber)
        external
        view
        returns (uint256);
}

contract OVLRelayLogic {
    event Convert(address indexed sender, uint256 nftId, uint256 amount);

    constructor() public {}

    function buy() external {}

    function convertItem() external {}

    function openChest() external {}

    function craft(bytes memory data) external {}

    function upgrade() external {}

    function getRandomNumber(
        IRandomness _contract,
        uint256 _totalWeight,
        uint256 randomNumber
    ) public {
        _contract.getRandomNumber(_totalWeight, randomNumber);
        emit Convert(msg.sender, 1222, 1111);
    }
}