/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: IERC20

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

// Part: IERC721

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
    
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

// Part: IMarketPlace

interface IMarketPlace {
    
    struct Order {
        // Order ID
        bytes32 id;
        // Owner of the NFT
        address seller;
        // NFT registry address
        address nftAddress;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
    }
    
    /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    */
    function executeOrder(
        address nftAddress,
        uint256 assetId,
        uint256 price
    ) external;

    function orderByAssetId(address nftAddress, uint256 assetId) external view returns (Order memory order);
}

// File: DecentralandMarket.sol

library DecentralandMarket {

    address public constant MARKETPLACE_PROXY = 0x8e5660b4Ab70168b5a6fEeA0e0315cb49c8Cd539;
    address public constant ACCEPTED_TOKEN = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942; // MANA

    function buyAssetsForErc20(bytes memory data, address recipient) external {
        address[] memory nftAddrs;
        uint256[] memory assetIds;

        (nftAddrs, assetIds) = abi.decode(
            data,
            (address[],uint256[])
        );

        for (uint256 i = 0; i < nftAddrs.length; i++) {
            _buyAssetForErc20(assetIds[i], estimateAssetPriceInErc20(nftAddrs[i], assetIds[i]), nftAddrs[i], recipient);
        }
    }

    function estimateAssetPriceInErc20(address nftAddress, uint256 assetId) public view returns(uint256) {
        return IMarketPlace(MARKETPLACE_PROXY).orderByAssetId(nftAddress, assetId).price;
    }

    function estimateBatchAssetPriceInErc20(bytes memory data) external view returns(address[] memory erc20Addrs, uint256[] memory amounts) {
        address[] memory nftAddrs;
        uint256[] memory assetIds;

        (nftAddrs, assetIds) = abi.decode(
            data,
            (address[],uint256[])
        );
        
        erc20Addrs = new address[](nftAddrs.length);
        amounts = new uint256[](assetIds.length);

        for (uint256 i = 0; i < nftAddrs.length; i++) {
            erc20Addrs[i] = ACCEPTED_TOKEN;
            amounts[i] = estimateAssetPriceInErc20(nftAddrs[i], assetIds[i]);
        }
    }

    function _buyAssetForErc20(uint256 _assetId, uint256 _price, address _nftAddr, address _recipient) internal {
        IERC20(ACCEPTED_TOKEN).approve(MARKETPLACE_PROXY, _price);
        IMarketPlace(MARKETPLACE_PROXY).executeOrder(_nftAddr, _assetId, _price);
        IERC721(_nftAddr).transferFrom(address(this), _recipient, _assetId);
    }
}