// SPDX-License-Identifier: GPL-3.0



pragma solidity 0.6.12;

contract MockZeroExV2Integratee {
    bytes public ZRX_ASSET_DATA;

    constructor(bytes memory _zrxAssetData) public {
        ZRX_ASSET_DATA = _zrxAssetData;
    }
}

