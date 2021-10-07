/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File contracts/interfaces/IPublicAuctionHouse.sol

/// @title Interface for Auction Houses

pragma solidity ^0.8.6;

interface IPublicAuctionHouse {
    struct PublicAuction {
        // ID for the ERC721 token ID
        uint256 tokenId;
        // accept ETH = false, accept ERC20 = true
        bool acceptableOtherAsset;
        // ERC20 address for acceptableAsset
        address acceptableAsset;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // The minimum amount of time left in an auction after a new bid is created
        uint256 timeBuffer;
        // The minimum price accepted in an auction
        uint256 reservePrice;
        // The minimum percentage difference between the last bid amount and the current bid
        uint8 minBidIncrementPercentage;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed auctionId, uint256 indexed tokenId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed auctionId, uint256 indexed tokenId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed auctionId, uint256 indexed tokenId, uint256 endTime);

    event AuctionSettled(uint256 indexed auctionId, uint256 indexed tokenId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction(uint256 auctionId) external;

    function createNewAuction(
        uint256 _tokenId,
        bool _acceptableOtherAsset,
        address _acceptableAsset,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration) external;

    function createBid(uint256 auctionId) external payable;

    function createBidWithOtherAsset(uint256 auctionId, uint256 bidAmount) external;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/interfaces/INFT.sol

/// @title Interface for NFT

pragma solidity ^0.8.6;

interface INFT is IERC721 {
    function mint() external returns (uint256);
    function burn(uint256 tokenId) external;
}


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}


// File contracts/PublicAuctionHouse.sol

/// @title The NFT's public auction house
pragma solidity ^0.8.6;







contract PublicAuctionHouse is IPublicAuctionHouse, ReentrancyGuard, Ownable, IERC721Receiver {
    // The NFT token contract
    INFT public nft;

    // The address of the WETH contract
    address public weth;

    // The active auction
    uint256 public numAuctions;
    mapping(uint256 => IPublicAuctionHouse.PublicAuction) public auctionList;

    constructor(address _nft, address _weth) {
        require(_nft != address(0), "PublicAuctionHouse: nft address cannot be 0x0.");
        require(_weth != address(0), "PublicAuctionHouse: weth address cannot be 0x0.");

        nft = INFT(_nft);
        weth = _weth;
    }

    function createNewAuction(
        uint256 _tokenId,
        bool _acceptableOtherAsset,
        address _acceptableAsset,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration) external override nonReentrant onlyOwner {

        address tokenOwner = nft.ownerOf(_tokenId);
        require(msg.sender == tokenOwner, "PublicAuctionHouse: Caller must be the owner of the token with given tokenId.");

        if (_acceptableOtherAsset) {
            require(_acceptableAsset != address(0), "PublicAuctionHouse: acceptableAsset cannot be zero address.");
        }

        nft.transferFrom(msg.sender, address(this), _tokenId);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        IPublicAuctionHouse.PublicAuction memory _auction = IPublicAuctionHouse.PublicAuction({
            tokenId: _tokenId,
            acceptableOtherAsset: _acceptableOtherAsset,
            acceptableAsset: _acceptableAsset,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false,
            timeBuffer: _timeBuffer,
            reservePrice: _reservePrice,
            minBidIncrementPercentage: _minBidIncrementPercentage
        });

        numAuctions++;
        uint256 auctionId = numAuctions;
        auctionList[auctionId] = _auction;

        emit AuctionCreated(auctionId, _tokenId, startTime, endTime);
    }

    /**
     * @notice Settle the current auction with given auctionId
     */
    function settleAuction(uint256 auctionId) external override nonReentrant {
        _settleAuction(auctionId);
    }

    /**
     * @notice Create a bid for a NFT, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 auctionId) external payable override nonReentrant {
        require(auctionId <= numAuctions, "PublicAuctionHouse: auction does not exist");

        IPublicAuctionHouse.PublicAuction memory _auction = auctionList[auctionId];
        require(!_auction.acceptableOtherAsset, 'PublicAuctionHouse: Only accept eth');
        require(_auction.settled == false, 'PublicAuctionHouse: NFT not up for auction');
        require(block.timestamp < _auction.endTime, 'PublicAuctionHouse: Auction expired');
        require(msg.value >= _auction.reservePrice, 'PublicAuctionHouse: Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * _auction.minBidIncrementPercentage) / 100),
            'PublicAuctionHouse: Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auctionList[auctionId].amount = msg.value;
        auctionList[auctionId].bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < _auction.timeBuffer;
        if (extended) {
            auctionList[auctionId].endTime = _auction.endTime = block.timestamp + _auction.timeBuffer;
        }

        emit AuctionBid(auctionId, _auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(auctionId, _auction.tokenId, _auction.endTime);
        }
    }

    function createBidWithOtherAsset(uint256 auctionId, uint256 bidAmount) external override nonReentrant {
        require(auctionId <= numAuctions, "PublicAuctionHouse: auction does not exist");

        IPublicAuctionHouse.PublicAuction memory _auction = auctionList[auctionId];
        require(_auction.acceptableOtherAsset, 'PublicAuctionHouse: ETH is not accepable');
        require(_auction.settled == false, 'PublicAuctionHouse: NFT not up for auction');
        require(block.timestamp < _auction.endTime, 'PublicAuctionHouse: Auction expired');
        require(bidAmount >= _auction.reservePrice, 'PublicAuctionHouse: Must send at least reservePrice');
        require(
            bidAmount >= _auction.amount + ((_auction.amount * _auction.minBidIncrementPercentage) / 100),
            'PublicAuctionHouse: Must send more than last bid by minBidIncrementPercentage amount'
        );

        IERC20(_auction.acceptableAsset).transferFrom(msg.sender, address(this), bidAmount);

        address lastBidder = _auction.bidder;
        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferToken(_auction.acceptableAsset, lastBidder, _auction.amount);
        }

        auctionList[auctionId].amount = bidAmount;
        auctionList[auctionId].bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < _auction.timeBuffer;
        if (extended) {
            auctionList[auctionId].endTime = _auction.endTime = block.timestamp + _auction.timeBuffer;
        }

        emit AuctionBid(auctionId, _auction.tokenId, msg.sender, bidAmount, extended);

        if (extended) {
            emit AuctionExtended(auctionId, _auction.tokenId, _auction.endTime);
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the NFT is burned.
     */
    function _settleAuction(uint256 auctionId) internal {
        require(auctionId <= numAuctions, "PublicAuctionHouse: auction does not exist");

        IPublicAuctionHouse.PublicAuction memory _auction = auctionList[auctionId];
        require(_auction.startTime != 0, "PublicAuctionHouse: Auction hasn't begun");
        require(!_auction.settled, 'PublicAuctionHouse: Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "PublicAuctionHouse: Auction hasn't completed");

        auctionList[auctionId].settled = true;

        if (_auction.bidder == address(0)) {
            nft.transferFrom(address(this), owner(), _auction.tokenId);
            emit AuctionSettled(auctionId, _auction.tokenId, owner(), _auction.amount);
        } else {
            nft.transferFrom(address(this), _auction.bidder, _auction.tokenId);
            emit AuctionSettled(auctionId, _auction.tokenId, _auction.bidder, _auction.amount);
        }

        if (_auction.amount > 0) {
            if (!_auction.acceptableOtherAsset) {
                _safeTransferETHWithFallback(owner(), _auction.amount);
            } else {
                _safeTransferToken(_auction.acceptableAsset, owner(), IERC20(_auction.acceptableAsset).balanceOf(address(this)));
            }
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    function _safeTransferToken(address token, address to, uint256 amount) internal {
        IERC20(token).transfer(to, amount);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}