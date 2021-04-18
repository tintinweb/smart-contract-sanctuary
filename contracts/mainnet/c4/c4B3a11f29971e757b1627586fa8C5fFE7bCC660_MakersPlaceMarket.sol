/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



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

// Part: IMakersPlace

interface IMakersPlace {
    function purchase(uint256 _tokenId, address _referredBy) payable external;
}

// File: MakersPlaceMarket.sol

library MakersPlaceMarket {

    address public constant MAKERSPLACE = 0x7e3abdE9D9E80fA2d1A02c89E0eae91b233CDE35;

    struct MakersPlaceBuy {
        uint256 tokenId;
        uint256 price;
    }

    function buyAssetsForEth(bytes memory data, address recipient) public {
        MakersPlaceBuy[] memory makersPlaceBuys;
        (makersPlaceBuys) = abi.decode(
            data,
            (MakersPlaceBuy[])
        );

        for (uint256 i = 0; i < makersPlaceBuys.length; i++) {
            _buyAssetForEth(makersPlaceBuys[i].tokenId, makersPlaceBuys[i].price, recipient);
        }
    }

    function _buyAssetForEth(uint256 _tokenId, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(IMakersPlace(MAKERSPLACE).purchase.selector, _tokenId, 0x2A46f2fFD99e19a89476E2f62270e0a35bBf0756);

        (bool success, ) = MAKERSPLACE.call{value:_price}(_data);
        require(success, "_buyAssetForEth: makersPlace buy failed.");

        IERC721(0x2A46f2fFD99e19a89476E2f62270e0a35bBf0756).transferFrom(address(this), _recipient, _tokenId);
    }
}