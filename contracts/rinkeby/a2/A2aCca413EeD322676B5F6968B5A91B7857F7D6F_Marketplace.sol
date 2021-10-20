// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {

    struct Offer {
        IERC721 nftAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        address buyer;
        bool active;
    }

    event NewOffer(
        IERC721 indexed nftAddress,
        uint256 indexed offerId,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price);
    event ItemBought(uint256 indexed offerId);
    event OfferCanceled(uint256 indexed offerId);

    mapping (uint256 => Offer) public offers;
    uint256 public numOffers = 0;

    function makeBuyOffer(IERC721 _nftAddress, uint256 tokenId) payable public {
        require(_nftAddress.ownerOf(tokenId) != address(0));
        uint256 offerId = numOffers;
        offers[offerId] = Offer({
            nftAddress: _nftAddress,
            tokenId: tokenId,
            price: msg.value,
            seller: address(0),
            buyer: msg.sender,
            active: true
        });
        numOffers += 1;
        emit NewOffer(_nftAddress, offerId, tokenId, offers[offerId].seller, offers[offerId].buyer, offers[offerId].price);
    }

    function makeSellOffer(IERC721 _nftAddress, uint256 tokenId, uint256 price) public {
        uint256 offerId = numOffers;
        offers[offerId] = Offer({
            nftAddress: _nftAddress,
            tokenId: tokenId,
            price: price,
            seller: msg.sender,
            buyer: address(0),
            active: true
        });
        numOffers += 1;

        offers[offerId].nftAddress.safeTransferFrom(
            offers[offerId].seller,
            address(this),
            offers[offerId].tokenId
        );
        emit NewOffer(_nftAddress, offerId, tokenId, offers[offerId].seller, offers[offerId].buyer, offers[offerId].price);
    }

    function acceptBuyOffer(uint256 offerId) public {
        require(offers[offerId].active, "Offer must be active");
        require(offers[offerId].seller == address(0), "Must be a buy offer");

        offers[offerId].seller = msg.sender;
        offers[offerId].active = false;

        offers[offerId].nftAddress.safeTransferFrom(
            offers[offerId].seller,
            offers[offerId].buyer,
            offers[offerId].tokenId
        );
        (bool success, ) = offers[offerId].seller.call{value: offers[offerId].price}("");
        require(success, "Transfer failed.");
        emit ItemBought(offerId);
    }

    function acceptSellOffer(uint256 offerId) public payable {
        require(offers[offerId].price == msg.value, "Incorrect value sent.");
        require(offers[offerId].active, "Offer must be active");
        require(offers[offerId].buyer == address(0), "Must be a sell offer");

        offers[offerId].buyer = msg.sender;
        offers[offerId].active = false;

       offers[offerId].nftAddress.safeTransferFrom(
            address(this),
            offers[offerId].buyer,
            offers[offerId].tokenId
        );
        (bool success, ) = offers[offerId].seller.call{value: offers[offerId].price}("");
        require(success, "Transfer failed.");
        emit ItemBought(offerId);
    }

    function cancelBuyOffer(uint256 offerId) public {
        require(offers[offerId].active, "Offer must be active");
        require(offers[offerId].seller == address(0), "Must be a buy offer");
        require(msg.sender == offers[offerId].buyer, "Only the buyer can cancel offer.");

        offers[offerId].active = false;
        (bool success, ) = offers[offerId].buyer.call{value: offers[offerId].price}("");
        require(success, "Transfer failed.");
        emit OfferCanceled(offerId);
    }

    function cancelSellOffer(uint256 offerId) public {
        require(offers[offerId].active, "Offer must be active");
        require(offers[offerId].buyer == address(0), "Must be a sell offer");
        require(offers[offerId].seller == msg.sender, "Only the seller can cancel offer.");

        offers[offerId].active = false;
        offers[offerId].nftAddress.safeTransferFrom(
            address(this),
            offers[offerId].seller,
            offers[offerId].tokenId
        );
        emit OfferCanceled(offerId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns(bytes4) {
        bytes4 _ERC721_RECEIVED = 0x150b7a02;
        return _ERC721_RECEIVED;
    }

    /**
     * Returns a list of tokens that are for sale by a certain address.
     * Each value should appear only once.
     */
    function getSellTokenBy(IERC721 _nftAddress, address seller) public view returns(uint256[] memory){
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].seller == seller) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].seller == seller) {
                result[k] = offers[i].tokenId;
                k += 1;
            }
        }
        return result;
    }

    /**
     * Returns a list of tokens that a certain address is offering to buy.
     * (Theoretically, there could be duplicates here.)
     */
    function getBuyTokensBy(IERC721 _nftAddress, address buyer) public view returns(uint256[] memory){
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].buyer == buyer) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].buyer == buyer) {
                result[k] = offers[i].tokenId;
                k += 1;
            }
        }
        return result;
    }

    /**
     * Returns a list of offersIds that are on sale by a certain address.
     */
    function getSellOffersBy(IERC721 _nftAddress, address seller) public view returns(uint256[] memory){
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].seller == seller) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].seller == seller) {
                result[k] = i;
                k += 1;
            }
        }
        return result;
    }

    /**
     * Returns a list of offersIds where a certain address is trying to buy.
     */
    function getBuyOffersBy(IERC721 _nftAddress, address buyer) public view returns(uint256[] memory){
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].buyer == buyer) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].buyer == buyer) {
                result[k] = i;
                k += 1;
            }
        }
        return result;
    }

    function getBuyOffers(IERC721 _nftAddress, uint256 tokenId) public view returns(uint256[] memory) {
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].tokenId == tokenId && offers[i].seller == address(0)) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].active && offers[i].nftAddress == _nftAddress && offers[i].tokenId == tokenId && offers[i].seller == address(0)) {
                result[k] = i;
                k += 1;
            }
        }
        return result;
    }

    function getSellOffers(IERC721 _nftAddress, uint256 tokenId) public view returns(uint256[] memory) {
        uint256 size = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].tokenId == tokenId && offers[i].nftAddress == _nftAddress && offers[i].active && offers[i].buyer == address(0)) {
                size += 1;
            }
        }
        uint256[] memory result = new uint256[](size);
        uint256 k = 0;
        for (uint256 i = 0; i < numOffers; i++) {
            if (offers[i].tokenId == tokenId && offers[i].nftAddress == _nftAddress && offers[i].active && offers[i].buyer == address(0)) {
                result[k] = i;
                k += 1;
            }
        }
        return result;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}