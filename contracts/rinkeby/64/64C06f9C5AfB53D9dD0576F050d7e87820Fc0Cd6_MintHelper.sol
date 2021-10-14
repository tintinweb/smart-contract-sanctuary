// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import {IMintHelper} from "./IMintHelper.sol";

contract MintHelper is IMintHelper {
    function getParcelType(uint256 tokenId)
        external
        pure
        override
        returns (uint8)
    {
        if (tokenId <= 375) {
            // Mega Land
            return 1;
        } else if (tokenId <= 835) {
            // Giant Land
            return 2;
        } else if (tokenId <= 2205) {
            // Large Land
            return 3;
        } else if (tokenId <= 7200) {
            // Medium Land
            return 4;
        } else if (tokenId <= 15000) {
            // Standard Land
            return 5;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

interface IMintHelper {
    function getParcelType(uint256 tokenId) external returns (uint8);
}