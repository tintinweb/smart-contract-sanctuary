/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



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

// Part: ISuperRare

interface ISuperRare {
    /**
     * @dev Purchases the token if it is for sale.
     * @param _originContract address of the contract storing the token.
     * @param _tokenId uint256 ID of the token.
     */
    function buy(address _originContract, uint256 _tokenId) external payable;

    /**
     * @dev Gets the sale price of the token including the marketplace fee.
     * @param _originContract address of the contract storing the token.
     * @param _tokenId uint256 ID of the token
     * @return uint256 sale price of the token including the fee.
     */
    function tokenPriceFeeIncluded(address _originContract, uint256 _tokenId)
    external
    view
    returns (uint256);
}

// File: SuperRareMarket.sol

library SuperRareMarket {

    address public constant SUPERRARE = 0x65B49f7AEE40347f5A90b714be4eF086f3fe5E2C;
    address public constant SUPR = 0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;

    function buyAssetsForEth(bytes memory data, address recipient) public {
        uint256[] memory tokenIds;
        (tokenIds) = abi.decode(
            data,
            (uint256[])
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _buyAssetForEth(tokenIds[i], estimateAssetPriceInEth(tokenIds[i]), recipient);
        }
    }

    function estimateAssetPriceInEth(uint256 tokenId) public view returns(uint256) {
        return ISuperRare(SUPERRARE).tokenPriceFeeIncluded(SUPR, tokenId);
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        uint256[] memory tokenIds;
        (tokenIds) = abi.decode(
            data,
            (uint256[])
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalCost += ISuperRare(SUPERRARE).tokenPriceFeeIncluded(SUPR, tokenIds[i]);
        }
    }

    function _buyAssetForEth(uint256 _tokenId, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(ISuperRare(SUPERRARE).buy.selector, SUPR, _tokenId);

        (bool success, ) = SUPERRARE.call{value:_price}(_data);
        require(success, "_buyAssetForEth: SuperRare buy failed.");

        IERC721(SUPR).transferFrom(address(this), _recipient, _tokenId);        
    }
}