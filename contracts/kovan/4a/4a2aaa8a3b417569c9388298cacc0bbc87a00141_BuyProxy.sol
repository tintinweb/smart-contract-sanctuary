/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
}

interface IERC1155 {

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) external;
}

interface IERC721 {

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;
}

interface Erc1155MarketplaceFacet {

    function executeERC1155Listing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;
    
    function getERC1155Listing(uint256 _listingId) external view returns (ERC1155Listing memory listing_);
}

interface Erc721MarketplaceFacet {

    function executeERC721Listing(
        uint256 _listingId
    ) external;
    
    function getERC721Listing(uint256 _listingId) external view returns (ERC721Listing memory listing_);
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract BuyProxy {
    // MATIC
    //address private diamondAddy = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    //address private ghstAddy = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    // KOVAN
    address private diamondAddy = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    address private ghstAddy = 0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5;
    Erc1155MarketplaceFacet private diamondMarketplaceERC1155 = Erc1155MarketplaceFacet(diamondAddy);
    Erc721MarketplaceFacet private diamondMarketplaceERC721 = Erc721MarketplaceFacet(diamondAddy);
    IERC20 private ghstErc20 = IERC20(ghstAddy);

    address public owner;

    constructor() {
        owner = msg.sender;
         ghstErc20.approve(diamondAddy, 1e29);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function approveGhst() public onlyOwner {
        ghstErc20.approve(diamondAddy, 1e29);
    }

    function withdrawItems(address erc1155TokenAddress, uint256[] memory ids, uint256[] memory values) public onlyOwner {
        IERC1155(erc1155TokenAddress).safeBatchTransferFrom(address(this), owner, ids, values, new bytes(0));
    }


    function findErc1155ListingId (uint256 listingId, uint256 quantity,
                                uint256 priceInWei,
                                uint256 erc1155TypeId, uint256 category, address erc1155TokenAddress,
                                uint256 tryNrMax) private view returns (uint256) {
        ERC1155Listing memory listing;
        uint256 foundListingId = 0;
        for (uint256 tryNr = 0; tryNr < tryNrMax; tryNr++) {
            foundListingId = listingId + tryNr;
    
            listing = diamondMarketplaceERC1155.getERC1155Listing(foundListingId);

            if (listing.listingId == foundListingId && listing.cancelled != true &&
                listing.sold != true && listing.priceInWei == priceInWei &&
                listing.erc1155TypeId == erc1155TypeId && listing.erc1155TokenAddress == erc1155TokenAddress &&
                listing.category == category && listing.quantity == quantity) {
                return foundListingId;
            }
        }
        return 0;
    }

    function execute1155Listing(uint256 listingId, uint256 quantity,
                                uint256 priceInWei,
                                uint256 erc1155TypeId, uint256 category, address erc1155TokenAddress,
                                uint256 tryNrMax) public onlyOwner {
        uint256 foundListingId = findErc1155ListingId(listingId, quantity, priceInWei, erc1155TypeId, category, erc1155TokenAddress, tryNrMax);
        require(foundListingId != 0, 'Listing could not be found');
        diamondMarketplaceERC1155.executeERC1155Listing(foundListingId, quantity, priceInWei);
    }

    function withdrawGotchi(uint256 gotchiId) public onlyOwner {
        IERC721(diamondAddy).safeTransferFrom(address(this), owner, gotchiId, new bytes(0));
    }

    function findErc721ListingId (uint256 listingId, uint256 gotchiId,
                                uint256 priceInWei, address erc721TokenAddress, uint256 tryNrMax) private view returns (uint256) {
        ERC721Listing memory listing;
        uint256 foundListingId = 0;
        for (uint256 tryNr = 0; tryNr < tryNrMax; tryNr++) {
            foundListingId = listingId + tryNr;
    
            listing = diamondMarketplaceERC721.getERC721Listing(foundListingId);

            if (listing.listingId == foundListingId && listing.cancelled != true &&
                listing.timePurchased != 0 && listing.priceInWei == priceInWei &&
                listing.erc721TokenId == gotchiId && listing.erc721TokenAddress == erc721TokenAddress) {
                return foundListingId;
            }
        }
        return 0;
    }

    function execute721Listing(uint256 listingId, uint256 gotchiId,
                                uint256 priceInWei, address erc721TokenAddress, uint256 tryNrMax) public onlyOwner {
        uint256 foundListingId = findErc721ListingId(listingId, gotchiId, priceInWei, erc721TokenAddress, tryNrMax);
        require(foundListingId != 0, 'Listing could not be found');

        diamondMarketplaceERC721.executeERC721Listing(foundListingId);
    }
}