// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../../../../../interfaces/markets/tokens/IERC20.sol";
import "../../../../../interfaces/markets/tokens/IERC1155.sol";
import "../../../../../interfaces/markets/tokens/IERC721.sol";

interface INFTXVault {
    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function redeemTo(
        uint256 amount, 
        uint256[] memory specificIds, 
        address to
    ) external returns (uint256[] memory);

    function swapTo(
        uint256[] memory tokenIds,
        uint256[] memory amounts, /* ignored for ERC721 vaults */
        uint256[] memory specificIds,
        address to
    ) external returns (uint256[] memory);
}

interface ICryptoPunks {
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
}

library NftxV2Market {

    struct NFTXBuy {
        address vault;
        uint256 amount;
        uint256[] specificIds;
    }

    function _approve(
        address _operator, 
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        // in case of kitties
        if (_token == 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_token).approve(_operator, _tokenIds[i]);
            }
        }
        // in case of cryptopunks
        else if (_token == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                ICryptoPunks(_token).offerPunkForSaleToAddress(_tokenIds[i], 0, _operator);
            }
        }
        // default
        else if (!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        address fromERC721,
        address vault,
        uint256[] memory tokenIds
    ) external {
        _approve(vault, fromERC721, tokenIds);
        INFTXVault(vault).mint(tokenIds, tokenIds);
    }

    function sellERC1155BatchForERC20Equivalent(
        address fromERC1155,
        address vault,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        _approve(vault, fromERC1155, tokenIds);
        INFTXVault(vault).mint(tokenIds, amounts);
    }

    function buyAssetsForErc20(NFTXBuy[] memory nftxBuys, address recipient) external {
        for (uint256 i = 0; i < nftxBuys.length; i++) {
            INFTXVault(nftxBuys[i].vault).redeemTo(nftxBuys[i].amount, nftxBuys[i].specificIds, recipient);
        }
    }

    function swapErc721(
        address fromERC721,
        address vault,
        uint256[] memory fromTokenIds,
        uint256[] memory toTokenIds,
        address recipient
    ) external {
        // approve token to NFTX vault
        _approve(vault, fromERC721, fromTokenIds);
        // swap tokens and send back to the recipient
        uint256[] memory amounts;
        INFTXVault(vault).swapTo(fromTokenIds, amounts, toTokenIds, recipient);
    }

    function swapErc1155(
        address fromERC1155,
        address vault,
        uint256[] memory fromTokenIds,
        uint256[] memory fromAmounts,
        uint256[] memory toTokenIds,
        address recipient
    ) external {
        // approve token to NFTX vault
        _approve(vault, fromERC1155, fromTokenIds);
        // swap tokens and send back to the recipient
        INFTXVault(vault).swapTo(fromTokenIds, fromAmounts, toTokenIds, recipient);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC20 {
    /**
        * @dev Returns the amount of tokens owned by `account`.
        */
    function balanceOf(address account) external view returns (uint256);

    /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}