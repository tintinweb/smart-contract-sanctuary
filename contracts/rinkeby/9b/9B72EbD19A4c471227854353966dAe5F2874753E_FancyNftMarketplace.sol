// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./RecoverableErc20ByOwner.sol";
import "./interfaces/IDistributionRoyaltyPool.sol";
import "./interfaces/IFancyNftMarketplace.sol";

/// @custom:security-contact [email protected]
contract FancyNftMarketplace is
    Pausable,
    ReentrancyGuard,
    RecoverableErc20ByOwner,
    IFancyNftMarketplace
{
    using SafeMath for uint256;

    struct Offer {
        bool isForSale;
        uint256 tokenId;
        address seller;
        uint256 minValue; // in trx
        address onlySellTo; // specify to sell only to a specific person
        uint256 offerListIndex;
    }

    struct Bid {
        bool hasBid;
        uint256 tokenId;
        address bidder;
        uint256 value;
        uint256 counter;
    }

    address public immutable nft;
    address public immutable distributionPool;
    uint256 public dexFeePercent = 5;
    uint256 private _bidcounter = 0;

    // A record of nfts that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public nftsOfferedForSale;

    // Data about all open offers
    Offer[] public offers;

    // A record of the highest nft bid
    mapping(uint256 => Bid) public nftBids;

    constructor(address nft_, address distributionPool_) {
        distributionPool = distributionPool_;
        nft = nft_;
    }

    function offerNftForSale(uint256 tokenId, uint256 minSalePrice)
        public
        whenNotPaused
        nonReentrant
    {
        require(IERC721(nft).ownerOf(tokenId) == _msgSender(), "Only owner");
        require(
            (IERC721(nft).getApproved(tokenId) == address(this) ||
                IERC721(nft).isApprovedForAll(_msgSender(), address(this))),
            "Not Approved"
        );

        IERC721(nft).safeTransferFrom(_msgSender(), address(this), tokenId);

        Offer memory currentOffer = Offer(
            true,
            tokenId,
            _msgSender(),
            minSalePrice,
            address(0),
            offers.length
        );
        nftsOfferedForSale[tokenId] = currentOffer;
        offers.push(currentOffer);

        emit NftOffered(tokenId, minSalePrice, address(0));
    }

    function offerNftForSaleToAddress(
        uint256 tokenId,
        uint256 minSalePrice,
        address toAddress
    ) public whenNotPaused nonReentrant {
        require(IERC721(nft).ownerOf(tokenId) == _msgSender(), "Only owner");
        require(
            (IERC721(nft).getApproved(tokenId) == address(this) ||
                IERC721(nft).isApprovedForAll(_msgSender(), address(this))),
            "Not Approved"
        );

        IERC721(nft).safeTransferFrom(_msgSender(), address(this), tokenId);

        Offer memory currentOffer = Offer(
            true,
            tokenId,
            _msgSender(),
            minSalePrice,
            toAddress,
            offers.length
        );
        nftsOfferedForSale[tokenId] = currentOffer;
        offers.push(currentOffer);

        emit NftOffered(tokenId, minSalePrice, toAddress);
    }

    function buyNft(uint256 tokenId, uint256 refId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Offer memory offer = nftsOfferedForSale[tokenId];

        require(offer.isForSale == true, "nft is not for sale"); // nft not actually for sale

        if (
            offer.onlySellTo != address(0) && offer.onlySellTo != _msgSender()
        ) {
            revert("you can't buy this nft");
        } // nft not supposed to be sold to this user

        require(_msgSender() != offer.seller, "You can not buy your nft");
        require(msg.value >= offer.minValue, "Didn't send enough BNB"); // Didn't send enough BNB
        require(
            address(this) == IERC721(nft).ownerOf(tokenId),
            "Seller no longer owner of nft"
        ); // Seller no longer owner of nft

        address seller = offer.seller;

        IERC721(nft).safeTransferFrom(address(this), _msgSender(), tokenId);

        emit Transfer(seller, _msgSender(), 1);

        //Remove offers data
        Offer memory emptyOffer = Offer(
            false,
            tokenId,
            _msgSender(),
            0,
            address(0),
            0
        );
        nftsOfferedForSale[tokenId] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        emit NftNoLongerForSale(tokenId);

        // Calculate fee
        (uint256 sellerShare, uint256 feeShare) = _calculateShares(msg.value);
        _sendEth(seller, sellerShare);
        IDistributionRoyaltyPool(distributionPool).deposit{value: feeShare}(
            _msgSender(),
            refId
        );

        emit NftBought(tokenId, msg.value, seller, _msgSender());
        emit NftSell(tokenId, msg.value, _msgSender());

        Bid memory bid = nftBids[tokenId];

        if (bid.hasBid) {
            nftBids[tokenId] = Bid(false, tokenId, address(0), 0, 0);
            _sendEth(bid.bidder, bid.value);
        }
    }

    function enterBidForNft(uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Offer memory offer = nftsOfferedForSale[tokenId];

        require(offer.isForSale == true, "nft is not for sale");
        require(offer.seller != _msgSender(), "owner can not bid");
        require(msg.value > 0, "bid can not be zero");

        Bid memory existing = nftBids[tokenId];
        require(
            msg.value > existing.value,
            "you can not bid lower than last bid"
        );

        if (existing.value > 0) {
            // Refund the failing bid
            _sendEth(existing.bidder, existing.value);
        }
        _bidcounter++;
        nftBids[tokenId] = Bid(
            true,
            tokenId,
            _msgSender(),
            msg.value,
            _bidcounter
        );

        emit NftBidEntered(tokenId, msg.value, _msgSender());
    }

    function acceptBidForNft(
        uint256 tokenId,
        uint256 minPrice,
        uint256 refId
    ) public whenNotPaused nonReentrant {
        Offer memory offer = nftsOfferedForSale[tokenId];

        address seller = offer.seller;

        Bid memory bid = nftBids[tokenId];

        require(seller == _msgSender(), "Only NFT Owner");
        require(bid.value > 0, "there is not any bid");
        require(bid.value >= minPrice, "bid is lower than min price");

        IERC721(nft).safeTransferFrom(address(this), bid.bidder, tokenId);

        emit Transfer(seller, bid.bidder, 1);

        Offer memory emptyOffer = Offer(
            false,
            tokenId,
            _msgSender(),
            0,
            address(0),
            0
        );
        nftsOfferedForSale[tokenId] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        nftBids[tokenId] = Bid(false, tokenId, address(0), 0, 0);

        // Calculate fee
        (uint256 sellerShare, uint256 feeShare) = _calculateShares(bid.value);
        _sendEth(offer.seller, sellerShare);
        IDistributionRoyaltyPool(distributionPool).deposit{value: feeShare}(
            _msgSender(),
            refId
        );

        emit NftBought(tokenId, bid.value, seller, bid.bidder);
        emit NftSell(tokenId, bid.value, bid.bidder);
    }

    function withdrawBidForNft(uint256 tokenId) public nonReentrant {
        Bid memory bid = nftBids[tokenId];

        require(bid.hasBid == true, "There is not bid");
        require(bid.bidder == _msgSender(), "Only bidder can withdraw");

        uint256 amount = bid.value;

        nftBids[tokenId] = Bid(false, tokenId, address(0), 0, 0);

        // Refund the bid money
        _sendEth(_msgSender(), amount);

        emit NftBidWithdrawn(tokenId, bid.value, _msgSender());
    }

    function nftNoLongerForSale(uint256 tokenId) public nonReentrant {
        Offer memory offer = nftsOfferedForSale[tokenId];
        require(offer.isForSale == true, "nft is not for sale");

        address seller = offer.seller;
        require(seller == _msgSender(), "Only Owner");

        IERC721(nft).safeTransferFrom(address(this), _msgSender(), tokenId);

        Offer memory emptyOffer = Offer(
            false,
            tokenId,
            _msgSender(),
            0,
            address(0),
            0
        );
        nftsOfferedForSale[tokenId] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        Bid memory bid = nftBids[tokenId];

        if (bid.hasBid) {
            nftBids[tokenId] = Bid(false, tokenId, address(0), 0, 0);

            // Refund the bid money
            _sendEth(bid.bidder, bid.value);
        }

        emit NftNoLongerForSale(tokenId);
    }

    function _calculateShares(uint256 value)
        internal
        view
        returns (uint256 sellerShare_, uint256 feeShare_)
    {
        feeShare_ = _fraction(dexFeePercent, 100, value);
        sellerShare_ = value - feeShare_;
    }

    function _fraction(
        uint256 devidend,
        uint256 divisor,
        uint256 value
    ) internal pure returns (uint256) {
        return (value.mul(devidend)).div(divisor);
    }

    function offersMaxIndex() public view returns (uint256) {
        return offers.length;
    }

    function changeDexFee(uint256 dexFeePercent_) public onlyOwner {
        dexFeePercent = dexFeePercent_;
    }

    // pause
    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _data;
        emit ERC721Received(_operator, _from, _tokenId);
        return this.onERC721Received.selector;
    }

    function _sendEth(address recipient, uint256 value) internal {
        (bool success, ) = recipient.call{value: value}("");
        require(success, "Unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IFancyNftMarketplace is IERC721Receiver {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event NftTransfer(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
    event NftOffered(
        uint256 indexed tokenId,
        uint256 indexed minValue,
        address indexed toAddress
    );
    event NftBidEntered(
        uint256 indexed tokenId,
        uint256 indexed value,
        address indexed fromAddress
    );
    event NftBidWithdrawn(
        uint256 indexed tokenId,
        uint256 indexed value,
        address indexed fromAddress
    );
    event NftBought(
        uint256 indexed tokenId,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event NftSell(
        uint256 indexed tokenId,
        uint256 indexed value,
        address indexed toAddress
    );
    event NftNoLongerForSale(uint256 indexed tokenId);
    event ERC721Received(address operator, address _from, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IDistributionRoyaltyPool {
    function deposit(address referral, uint256 refId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev The contract is intendent to help recovering arbitrary ERC20 tokens
 * accidentally transferred to the contract address.
 */
abstract contract RecoverableErc20ByOwner is Ownable {
    function _getRecoverableAmount(address tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @param tokenAddress ERC20 token's address to recover
     * @param amount to recover from contract's address
     * @param to address to receive tokens from the contract
     */
    function recoverFunds(
        address tokenAddress,
        uint256 amount,
        address to
    ) external virtual onlyOwner {
        uint256 recoverableAmount = _getRecoverableAmount(tokenAddress);
        require(
            amount <= recoverableAmount,
            "RecoverableByOwner: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        recoverErc20(tokenAddress, amount, to);
    }

    function recoverErc20(
        address tokenAddress,
        uint256 amount,
        address to
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RecoverableByOwner: TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}