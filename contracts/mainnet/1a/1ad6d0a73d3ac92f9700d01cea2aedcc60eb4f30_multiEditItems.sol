/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface Inventory {
        function changeFeaturesForItem(
        uint256 _tokenId,
        uint8 _feature1,
        uint8 _feature2,
        uint8 _feature3,
        uint8 _feature4,
        uint8 _equipmentPosition
    ) external;
}

contract multiEditItems {
    address admin;
    Inventory inv = Inventory(0x9680223F7069203E361f55fEFC89B7c1A952CDcc);

    constructor() {
        admin = msg.sender;
    }

    function execute(
        uint256[] memory _tokenIds,
        uint8 _feature1,
        uint8 _feature2,
        uint8 _feature3,
        uint8 _feature4,
        uint8 _equipmentPosition
    ) public {
        require(msg.sender == admin, "Not admin");

        for(uint i = 0; i < _tokenIds.length; i++) {
            inv.changeFeaturesForItem(
                _tokenIds[i],
                _feature1,
                _feature2,
                _feature3,
                _feature4,
                _equipmentPosition
            );
        }
    }
}