// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IOpenSea {
    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external payable;
}

library OpenSeaMarket {

    address public constant OPENSEA = 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b;

    struct OpenSeaBuy {
        address[14] addrs;
        uint[18] uints;
        uint8[8] feeMethodsSidesKindsHowToCalls;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint8[2] vs;
        bytes32[5] rssMetadata;
    }

    function buyAssetsForEth(OpenSeaBuy[] memory openSeaBuys, bool revertIfTrxFails) public {
        for (uint256 i = 0; i < openSeaBuys.length; i++) {
            _buyAssetForEth(openSeaBuys[i], revertIfTrxFails);
        }
    }

    function _buyAssetForEth(OpenSeaBuy memory _openSeaBuy, bool _revertIfTrxFails) internal {
        bytes memory _data = abi.encodeWithSelector(IOpenSea.atomicMatch_.selector, _openSeaBuy.addrs, _openSeaBuy.uints, _openSeaBuy.feeMethodsSidesKindsHowToCalls, _openSeaBuy.calldataBuy, _openSeaBuy.calldataSell, _openSeaBuy.replacementPatternBuy, _openSeaBuy.replacementPatternSell, _openSeaBuy.staticExtradataBuy, _openSeaBuy.staticExtradataSell, _openSeaBuy.vs, _openSeaBuy.rssMetadata);
        (bool success, ) = OPENSEA.call{value:_openSeaBuy.uints[4]}(_data);
        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}