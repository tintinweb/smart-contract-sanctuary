// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../../../../../interfaces/markets/tokens/IERC20.sol";
import "../../../../../interfaces/markets/tokens/IERC721.sol";
import "../../../../../interfaces/markets/tokens/IERC1155.sol";

interface IExchangeV2Core {
    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }
    
    struct Asset {
        AssetType assetType;
        uint value;
    }

    struct Order {
        address maker;
        Asset makeAsset;
        address taker;
        Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }
    
    function matchOrders(
        Order memory orderLeft,
        bytes memory signatureLeft,
        Order memory orderRight,
        bytes memory signatureRight
    ) external payable;
}

library RaribleV2Market {
    address public constant RARIBLE = 0x9757F2d2b135150BBeb65308D4a91804107cd8D6;

    struct RaribleBuy {
        IExchangeV2Core.Order orderLeft;
        bytes signatureLeft;
        IExchangeV2Core.Order orderRight;
        bytes signatureRight;
        uint256 price;
    }

    function buyAssetsForEth(RaribleBuy[] memory raribleBuys, bool revertIfTrxFails) external {
        for (uint256 i = 0; i < raribleBuys.length; i++) {
            _buyAssetForEth(raribleBuys[i], revertIfTrxFails);
        }
    }

    function _buyAssetForEth(RaribleBuy memory raribleBuy, bool revertIfTrxFails) internal {
        bytes memory _data = abi.encodeWithSelector(
            IExchangeV2Core(RARIBLE).matchOrders.selector, 
            raribleBuy.orderLeft,
            raribleBuy.signatureLeft,
            raribleBuy.orderRight,
            raribleBuy.signatureRight
        );
        (bool success, ) = RARIBLE.call{value:raribleBuy.price}(_data);
        if (!success && revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        if (success) {
            if (raribleBuy.orderLeft.takeAsset.assetType.assetClass == bytes4(keccak256("ETH"))) {
                // In case we got ETH
                (bool _success, ) = msg.sender.call{value: raribleBuy.orderLeft.takeAsset.value}('');
                require(_success, "_buyAssetForEth: Rarible market eth transfer failed");
            }
            else if (raribleBuy.orderLeft.takeAsset.assetType.assetClass == bytes4(keccak256("ERC20"))) {
                // In case we got ERC20
                (address addr) = abi.decode(raribleBuy.orderLeft.takeAsset.assetType.data, (address));
                IERC20(addr).transfer(msg.sender, raribleBuy.orderLeft.takeAsset.value);
            }
            else if (raribleBuy.orderLeft.takeAsset.assetType.assetClass == bytes4(keccak256("ERC721"))) {
                // In case we got ERC721
                (address addr, uint256 tokenId) = abi.decode(raribleBuy.orderLeft.takeAsset.assetType.data, (address, uint256));
                IERC721(addr).transferFrom(address(this), msg.sender, tokenId);
            }
            else if (raribleBuy.orderLeft.takeAsset.assetType.assetClass == bytes4(keccak256("ERC1155"))) {
                // In case we got ERC1155
                (address addr, uint256 tokenId) = abi.decode(raribleBuy.orderLeft.takeAsset.assetType.data, (address, uint256));
                IERC1155(addr).safeTransferFrom(address(this), msg.sender, tokenId, raribleBuy.orderLeft.takeAsset.value, "");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
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