// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket{

    struct Offer {
        bool isForSale;
        address contAddr;
        uint tokenId;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        address contAddr;
        uint tokenId;
        address Bidder;
        uint value;
    }


    mapping(address => mapping(uint => Offer)) public tokensOfferedForSale;
    mapping(address => mapping(uint => Bid)) public tokenBids;
    mapping(address => uint) public pendingWithdrawals;

    event TokenOffered(address contAddr, uint indexed tokenId, uint minValue, address indexed toAddress);
    event TokenBidEntered(address contAddr, uint indexed tokenId, uint value, address indexed fromAddress);
    event TokenBidWithdrawn(address contAddr, uint indexed tokenId, uint value, address indexed fromAddress);
    event TokenBought(address contAddr, uint indexed tokenid, uint value, address indexed fromAddress, address indexed toAddress);
    event TokenNoLongerForSale(address contAddr, uint indexed tokenId);


    function offerTokenForSale(address contAddr, uint tokenId, uint minSalePriceInWei) public {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        require(NFT.getApproved(tokenId) == address(this), "market: approve this contract as operator");
        tokensOfferedForSale[contAddr][tokenId] = Offer(true, contAddr, tokenId, msg.sender, minSalePriceInWei, address(0));
        emit TokenOffered(contAddr, tokenId, minSalePriceInWei, address(0));
    }

    function offerTokenForSaleToAddress(address contAddr, uint tokenId, uint minSalePriceInWei, address toAddress) public {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        require(NFT.getApproved(tokenId) == address(this), "market: approve this contract as operator");
        tokensOfferedForSale[contAddr][tokenId] = Offer(true, contAddr, tokenId, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOffered(contAddr, tokenId, minSalePriceInWei, toAddress);
    }

    function tokenNoLongerForSale(address contAddr, uint tokenId) public {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        tokensOfferedForSale[contAddr][tokenId] = Offer(false, contAddr, tokenId, msg.sender, 0, address(0));
        emit TokenNoLongerForSale(contAddr, tokenId);
    }

    function buyToken(address contAddr, uint tokenId) public payable {
        IERC721 NFT = IERC721(contAddr);
        Offer memory offer = tokensOfferedForSale[contAddr][tokenId];
        require(offer.isForSale, "token is not for sale");
        if (offer.onlySellTo != address(0) && offer.onlySellTo != msg.sender) {
            revert("Market: not supposed to be sold to this user");
        }
        require(msg.value >= offer.minValue, "not enough eth");
        require(offer.seller == NFT.ownerOf(tokenId), "seller no longer owner of token");

        address seller = offer.seller;

        NFT.safeTransferFrom(seller, msg.sender, tokenId);
        pendingWithdrawals[seller] += msg.value;
        tokenNoLongerForSale(contAddr, tokenId);
        emit TokenBought(contAddr, tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a Bid from the new owner and refund it.
        // Any other Bid can stay in place.
        Bid memory bid = tokenBids[contAddr][tokenId];
        if (bid.Bidder == msg.sender) {
            // Kill the Bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            tokenBids[contAddr][tokenId] = Bid(false, contAddr, tokenId, address(0), 0);
        }
    }

    function enterBidForToken(address contAddr, uint tokenId) public payable {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) != msg.sender, "you already owned this token");
        require(msg.value != 0, "zero Bid value");
        Bid memory existing = tokenBids[contAddr][tokenId];
        require(msg.value >= existing.value, "you have to Bid at least equal to existing Bid");
        if (existing.value > 0) {
            // refund the failing Bid
            pendingWithdrawals[existing.Bidder] += existing.value;
        }
        tokenBids[contAddr][tokenId] = Bid(true, contAddr, tokenId, msg.sender, msg.value);
        emit TokenBidEntered(contAddr, tokenId, msg.value, msg.sender);
    }

    function withdrawBidForToken(address contAddr, uint tokenId) public {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) != msg.sender, "you already owned this token");
        Bid memory bid = tokenBids[contAddr][tokenId];
        require(bid.Bidder == msg.sender, "you have not Bid for this token");
        
        emit TokenBidWithdrawn(contAddr, tokenId, bid.value, msg.sender);
        tokenBids[contAddr][tokenId] = Bid(false, contAddr, tokenId, address(0), 0);
        // refund the Bid money
        address payable reciever = payable(msg.sender);
        reciever.transfer(bid.value);
    }

    function acceptBidForToken(address contAddr, uint tokenId, uint minPrice) public {
        IERC721 NFT = IERC721(contAddr);
        require(NFT.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        require(NFT.getApproved(tokenId) == address(this), "market: approve this contract as operator");
        Bid memory bid = tokenBids[contAddr][tokenId];
        require(bid.value != 0, "there is no Bid for this token");
        require(bid.value >= minPrice, "the Bid value is lesser than minPrice");
        address seller = msg.sender;
        NFT.safeTransferFrom(seller, bid.Bidder, tokenId);

        tokensOfferedForSale[contAddr][tokenId] = Offer(false, contAddr, tokenId, bid.Bidder, 0, address(0));
        tokenBids[contAddr][tokenId] = Bid(false, contAddr, tokenId, address(0), 0);
        pendingWithdrawals[seller] += bid.value;
        emit TokenBought(contAddr, tokenId, bid.value, seller, bid.Bidder);
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        address payable reciever = payable(msg.sender);
        reciever.transfer(amount);
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