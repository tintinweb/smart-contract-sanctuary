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
pragma solidity ^0.5.2;

import "MainStorage.sol";
import "MTokenAssetData.sol";
import "LibConstants.sol";

contract TokenAssetData is MainStorage, LibConstants, MTokenAssetData {
    bytes4 internal constant ERC20_SELECTOR = bytes4(keccak256("ERC20Token(address)"));
    bytes4 internal constant ETH_SELECTOR = bytes4(keccak256("ETH()"));
    bytes4 internal constant ERC721_SELECTOR = bytes4(keccak256("ERC721Token(address,uint256)"));
    bytes4 internal constant MINTABLE_ERC20_SELECTOR =
    bytes4(keccak256("MintableERC20Token(address)"));
    bytes4 internal constant MINTABLE_ERC721_SELECTOR =
    bytes4(keccak256("MintableERC721Token(address,uint256)"));

    // The selector follows the 0x20 bytes assetInfo.length field.
    uint256 internal constant SELECTOR_OFFSET = 0x20;
    uint256 internal constant SELECTOR_SIZE = 4;
    uint256 internal constant TOKEN_CONTRACT_ADDRESS_OFFSET = SELECTOR_OFFSET + SELECTOR_SIZE;
    string internal constant NFT_ASSET_ID_PREFIX = "NFT:";
    string internal constant MINTABLE_PREFIX = "MINTABLE:";

    /*
      Extract the tokenSelector from assetInfo.

      Works like bytes4 tokenSelector = abi.decode(assetInfo, (bytes4))
      but does not revert when assetInfo.length < SELECTOR_OFFSET.
    */
    function extractTokenSelector(bytes memory assetInfo) internal pure
        returns (bytes4 selector) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            selector := and(
                0xffffffff00000000000000000000000000000000000000000000000000000000,
                mload(add(assetInfo, SELECTOR_OFFSET))
            )
        }
    }

    function getAssetInfo(uint256 assetType) public view returns (bytes memory assetInfo) {
        // Verify that the registration is set and valid.
        require(registeredAssetType[assetType], "ASSET_TYPE_NOT_REGISTERED");

        // Retrieve registration.
        assetInfo = assetTypeToAssetInfo[assetType];
    }

    function isEther(uint256 assetType) internal view returns (bool) {
        return extractTokenSelector(getAssetInfo(assetType)) == ETH_SELECTOR;
    }

    function isMintableAssetType(uint256 assetType) internal view returns (bool) {
        bytes4 tokenSelector = extractTokenSelector(getAssetInfo(assetType));
        return
            tokenSelector == MINTABLE_ERC20_SELECTOR ||
            tokenSelector == MINTABLE_ERC721_SELECTOR;
    }

    function extractContractAddress(bytes memory assetInfo)
        internal pure returns (address _contract) {
        uint256 offset = TOKEN_CONTRACT_ADDRESS_OFFSET;
        uint256 res;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            res := mload(add(assetInfo, offset))
        }
        _contract = address(res);
    }

    function calculateNftAssetId(uint256 assetType, uint256 tokenId)
        internal
        pure
        returns(uint256 assetId) {
        assetId = uint256(keccak256(abi.encodePacked(NFT_ASSET_ID_PREFIX, assetType, tokenId))) &
            MASK_250;
    }

    function calculateMintableAssetId(uint256 assetType, bytes memory mintingBlob)
        internal
        pure
        returns(uint256 assetId) {
        uint256 blobHash = uint256(keccak256(mintingBlob));
        assetId = (uint256(keccak256(abi.encodePacked(MINTABLE_PREFIX ,assetType, blobHash)))
            & MASK_240) | MINTABLE_ASSET_ID_FLAG;
    }

}
