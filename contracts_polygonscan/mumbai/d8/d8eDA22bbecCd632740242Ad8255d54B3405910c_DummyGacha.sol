// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DummyGacha {
    event mintWithGacha(string rarityName, uint256 basePoint, address to);

    function triggerEvent(string calldata rarityName, uint256 basePoint, address to) public {
        emit mintWithGacha(rarityName, basePoint, to);
    }
}