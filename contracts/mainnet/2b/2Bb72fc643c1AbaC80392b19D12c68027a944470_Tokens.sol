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

import "Common.sol";
import "LibConstants.sol";
import "MGovernance.sol";
import "MTokens.sol";
import "TokenAssetData.sol";
import "TokenQuantization.sol";
import "IERC20.sol";
import "MainStorage.sol";

/**
  Registration of a new token (:sol:func:`registerToken`) entails defining a new asset type within
  the system, and associating it with an `assetInfo` array of
  bytes and a quantization factor (`quantum`).

  The `assetInfo` is a byte array, with a size depending on the token.
  For ETH, assetInfo is 4 bytes long. For ERC20 tokens, it is 36 bytes long.

  For each token type, the following constant 4-byte hash is defined, called the `selector`:

   | `ETH_SELECTOR = bytes4(keccak256("ETH()"));`
   | `ERC20_SELECTOR = bytes4(keccak256("ERC20Token(address)"));`
   | `ERC721_SELECTOR = bytes4(keccak256("ERC721Token(address,uint256)"));`
   | `MINTABLE_ERC20_SELECTOR = bytes4(keccak256("MintableERC20Token(address)"));`
   | `MINTABLE_ERC721_SELECTOR = bytes4(keccak256("MintableERC721Token(address,uint256)"));`

  For each token type, `assetInfo` is defined as follows:


  The `quantum` quantization factor defines the multiplicative transformation from the native token
  denomination as a 256b unsigned integer to a 63b unsigned integer representation as used by the
  Stark exchange. Only amounts in the native representation that represent an integer number of
  quanta are allowed in the system.

  The asset type is restricted to be the result of a hash of the `assetInfo` and the
  `quantum` masked to 250 bits (to be less than the prime used) according to the following formula:

  | ``uint256 assetType = uint256(keccak256(abi.encodePacked(assetInfo, quantum))) &``
  | ``0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;``

  Once registered, tokens cannot be removed from the system, as their IDs may be used by off-chain
  accounts.

  New tokens may only be registered by a Token Administrator. A Token Administrator may be instantly
  appointed or removed by the contract Governor (see :sol:mod:`MainGovernance`). Typically, the
  Token Administrator's private key should be kept in a cold wallet.
*/
contract Tokens is
    MainStorage,
    LibConstants,
    MGovernance,
    TokenQuantization,
    TokenAssetData,
    MTokens
{
    event LogTokenRegistered(uint256 assetType, bytes assetInfo);
    event LogTokenAdminAdded(address tokenAdmin);
    event LogTokenAdminRemoved(address tokenAdmin);

    using Addresses for address;
    using Addresses for address payable;

    modifier onlyTokensAdmin() {
        require(tokenAdmins[msg.sender], "ONLY_TOKENS_ADMIN");
        _;
    }

    function registerTokenAdmin(address newAdmin) external onlyGovernance() {
        tokenAdmins[newAdmin] = true;
        emit LogTokenAdminAdded(newAdmin);
    }

    function unregisterTokenAdmin(address oldAdmin) external onlyGovernance() {
        tokenAdmins[oldAdmin] = false;
        emit LogTokenAdminRemoved(oldAdmin);
    }

    function isTokenAdmin(address testedAdmin) external view returns (bool) {
        return tokenAdmins[testedAdmin];
    }


    function registerToken(uint256 assetType, bytes calldata assetInfo) external {
        registerToken(assetType, assetInfo, 1);
    }

    /*
      Registers a new asset to the system.
      Once added, it can not be removed and there is a limited number
      of slots available.
    */
    function registerToken(
        uint256 assetType,
        bytes memory assetInfo,
        uint256 quantum
    ) public onlyTokensAdmin() {
        // Make sure it is not invalid or already registered.
        require(!registeredAssetType[assetType], "ASSET_ALREADY_REGISTERED");
        require(assetType < K_MODULUS, "INVALID_ASSET_TYPE");
        require(quantum > 0, "INVALID_QUANTUM");
        require(quantum <= MAX_QUANTUM, "INVALID_QUANTUM");
        require(assetInfo.length >= SELECTOR_SIZE, "INVALID_ASSET_STRING");

        // Require that the assetType is the hash of the assetInfo and quantum truncated to 250 bits.
        uint256 enforcedId = uint256(keccak256(abi.encodePacked(assetInfo, quantum))) & MASK_250;
        require(assetType == enforcedId, "INVALID_ASSET_TYPE");

        // Add token to the in-storage structures.
        registeredAssetType[assetType] = true;
        assetTypeToAssetInfo[assetType] = assetInfo;
        assetTypeToQuantum[assetType] = quantum;

        bytes4 tokenSelector = extractTokenSelector(assetInfo);

        // Ensure the selector is of an asset type we know.
        require(
            tokenSelector == ETH_SELECTOR ||
            tokenSelector == ERC20_SELECTOR ||
            tokenSelector == ERC721_SELECTOR ||
            tokenSelector == MINTABLE_ERC20_SELECTOR ||
            tokenSelector == MINTABLE_ERC721_SELECTOR,
            "UNSUPPORTED_TOKEN_TYPE"
        );

        if (tokenSelector == ETH_SELECTOR) {
            // Assset info for ETH assetType is only a selector, i.e. 4 bytes length.
            require(assetInfo.length == 4, "INVALID_ASSET_STRING");
        } else {
            // Assset info for other asset types are a selector + uint256 concatanation.
            // We pass the address as a uint256 (zero padded),
            // thus its length is 0x04 + 0x20 = 0x24.
            require(assetInfo.length == 0x24, "INVALID_ASSET_STRING");
            address tokenAddress = extractContractAddress(assetInfo);
            require(tokenAddress.isContract(), "BAD_TOKEN_ADDRESS");
            if (tokenSelector == ERC721_SELECTOR || tokenSelector == MINTABLE_ERC721_SELECTOR) {
                require(quantum == 1, "INVALID_NFT_QUANTUM");
            }
        }

        // Log the registration of a new token.
        emit LogTokenRegistered(assetType, assetInfo);
    }

    /*
      Transfers funds from msg.sender to the exchange.
    */
    function transferIn(uint256 assetType, uint256 quantizedAmount) internal {
        bytes memory assetInfo = getAssetInfo(assetType);
        uint256 amount = fromQuantized(assetType, quantizedAmount);

        bytes4 tokenSelector = extractTokenSelector(assetInfo);
        if (tokenSelector == ERC20_SELECTOR) {
            address tokenAddress = extractContractAddress(assetInfo);
            IERC20 token = IERC20(tokenAddress);
            uint256 exchangeBalanceBefore = token.balanceOf(address(this));
            token.transferFrom(msg.sender, address(this), amount); // NOLINT: unused-return.
            uint256 exchangeBalanceAfter = token.balanceOf(address(this));
            require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
            // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
            require(
                exchangeBalanceAfter == exchangeBalanceBefore + amount,
                "INCORRECT_AMOUNT_TRANSFERRED");
        } else if (tokenSelector == ETH_SELECTOR) {
            require(msg.value == amount, "INCORRECT_DEPOSIT_AMOUNT");
        } else {
            revert("UNSUPPORTED_TOKEN_TYPE");
        }
    }

    function transferInNft(uint256 assetType, uint256 tokenId) internal {
        bytes memory assetInfo = getAssetInfo(assetType);

        bytes4 tokenSelector = extractTokenSelector(assetInfo);
        require(tokenSelector == ERC721_SELECTOR, "NOT_ERC721_TOKEN");
        address tokenAddress = extractContractAddress(assetInfo);
        tokenAddress.safeTokenContractCall(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenId
            )
        );
    }

    /*
      Transfers funds from the exchange to recipient.
    */
    function transferOut(
        address payable recipient,
        uint256 assetType,
        uint256 quantizedAmount
    ) internal {
        bytes memory assetInfo = getAssetInfo(assetType);
        uint256 amount = fromQuantized(assetType, quantizedAmount);

        bytes4 tokenSelector = extractTokenSelector(assetInfo);
        if (tokenSelector == ERC20_SELECTOR) {
            address tokenAddress = extractContractAddress(assetInfo);
            IERC20 token = IERC20(tokenAddress);
            uint256 exchangeBalanceBefore = token.balanceOf(address(this));
            token.transfer(recipient, amount); // NOLINT: unused-return.
            uint256 exchangeBalanceAfter = token.balanceOf(address(this));
            require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
            // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
            require(
                exchangeBalanceAfter == exchangeBalanceBefore - amount,
                "INCORRECT_AMOUNT_TRANSFERRED");
        } else if (tokenSelector == ETH_SELECTOR) {
            recipient.performEthTransfer(amount);
        } else {
            revert("UNSUPPORTED_TOKEN_TYPE");
        }
    }

    /*
      Transfers NFT from the exchange to recipient.
    */
    function transferOutNft(address recipient, uint256 assetType, uint256 tokenId) internal {
        bytes memory assetInfo = getAssetInfo(assetType);
        bytes4 tokenSelector = extractTokenSelector(assetInfo);
        require(tokenSelector == ERC721_SELECTOR, "NOT_ERC721_TOKEN");
        address tokenAddress = extractContractAddress(assetInfo);
        tokenAddress.safeTokenContractCall(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                address(this),
                recipient,
                tokenId
            )
        );
    }

    function transferOutMint(
        uint256 assetType,
        uint256 quantizedAmount,
        bytes memory mintingBlob) internal {
        uint256 amount = fromQuantized(assetType, quantizedAmount);
        address tokenAddress = extractContractAddress(getAssetInfo(assetType));
        tokenAddress.safeTokenContractCall(
            abi.encodeWithSignature(
                "mintFor(address,uint256,bytes)",
                msg.sender, amount, mintingBlob)
        );
    }
}
