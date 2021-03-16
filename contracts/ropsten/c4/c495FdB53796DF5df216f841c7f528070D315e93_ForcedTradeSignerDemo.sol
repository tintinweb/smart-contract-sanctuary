/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.6.11;

contract ForcedTradeSignerDemo
{
    uint256 constant PERPETUAL_POSITION_ID_UPPER_BOUND = 2**64;
    uint256 constant PERPETUAL_AMOUNT_UPPER_BOUND = 2**64;
    uint256 constant K_MODULUS =
    0x800000000000011000000000000000000000000000000000000000000000001;
    address ZERO_ADDRESS = address(0x0);
    mapping (uint256 => address) ethKeys;
    uint256 systemAssetType;

    event LogForcedTradeRequest(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 nonce
    );

    function testQuickRegistration(address ethKey, uint256 starkKey) external {
        // Validate keys and availability.
        require(starkKey != 0, "INVALID_STARK_KEY");
        require(starkKey < K_MODULUS, "INVALID_STARK_KEY");
        require(ethKey != ZERO_ADDRESS, "INVALID_ETH_ADDRESS");
        require(ethKeys[starkKey] == ZERO_ADDRESS, "STARK_KEY_UNAVAILABLE");
        ethKeys[starkKey] = ethKey;
    }

    function testQuickRegisterCollateralAssetType(uint256 assetType) external {
        require(systemAssetType == uint256(0), "SYSTEM_ASSET_TYPE_ALREADY_SET");
        systemAssetType = assetType;
    }

    function getSystemAssetType() public view returns (uint256) {
        return systemAssetType;
    }

    function forcedTradeRequest(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes calldata signature,
        bool premiumCost
    ) external
    {
        require(vaultIdA < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");
        require(vaultIdB < PERPETUAL_POSITION_ID_UPPER_BOUND, "OUT_OF_RANGE_POSITION_ID");

        require(vaultIdA != vaultIdB, "IDENTICAL_VAULTS");
        require(collateralAssetId == systemAssetType, "SYSTEM_ASSET_NOT_IN_TRADE");
        require(collateralAssetId != uint256(0x0), "SYSTEM_ASSET_NOT_SET");
        require(collateralAssetId != syntheticAssetId, "IDENTICAL_ASSETS");
        require(amountCollateral < PERPETUAL_AMOUNT_UPPER_BOUND, "ILLEGAL_AMOUNT");
        require(amountSynthetic < PERPETUAL_AMOUNT_UPPER_BOUND, "ILLEGAL_AMOUNT");
        require(nonce < K_MODULUS, "INVALID_NONCE_VALUE");
        require(submissionExpirationTime >= block.timestamp / 3600, "REQUEST_TIME_EXPIRED");

        validatePartyBSignature(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            submissionExpirationTime,
            nonce,
            signature
        );

        emit LogForcedTradeRequest(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );
    }

    function getActionHash(string memory actionName, bytes memory packedActionParameters)
        internal
        pure
        returns(bytes32 actionHash)
    {
        actionHash = keccak256(abi.encodePacked(actionName, packedActionParameters));
    }

    function forcedTradeActionHash(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            getActionHash(
                "FORCED_TRADE",
                abi.encodePacked(
                    starkKeyA,
                    starkKeyB,
                    vaultIdA,
                    vaultIdB,
                    collateralAssetId,
                    syntheticAssetId,
                    amountCollateral,
                    amountSynthetic,
                    aIsBuyingSynthetic,
                    nonce
                )
            );
    }

    function validatePartyBSignature(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes memory signature
    ) internal view {
        bytes32 actionHash = forcedTradeActionHash(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );

        bytes32 signedData = keccak256(abi.encodePacked(actionHash, submissionExpirationTime));
        address signer;
        {
            uint8 v = uint8(signature[64]);
            bytes32 r;
            bytes32 s;

            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
            }
            signer = ecrecover(signedData, v, r, s);
        }
        require(signer == ethKeys[starkKeyB], "INVALID_SIGNATURE");
    }
}