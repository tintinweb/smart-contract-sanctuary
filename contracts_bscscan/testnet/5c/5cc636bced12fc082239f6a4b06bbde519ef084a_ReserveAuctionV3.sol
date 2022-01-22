/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

// OpenZeppelin library for performing math operations without overflows.
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin security library for preventing reentrancy attacks.
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
contract ReentrancyGuard {
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

    constructor() internal {
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

// For interacting with Zora's Market contract.
// import {IMarket} from "./interfaces/IMarket.sol";
// For checking `supportsInterface`.
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

// For interacting with NFT tokens.
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

abstract contract BleufiNft {
    // Required methods

    function royalities(uint256 _tokenId) public view virtual returns (uint256);

    function creators(uint256 _tokenId)
        public
        view
        virtual
        returns (address payable);
}

// contract IMediaModified {
//     mapping(uint256 => address) public tokenCreators;
//     address public marketContract;
// }

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

contract ReserveAuctionV3 is ReentrancyGuard, Ownable {
    // Use OpenZeppelin's SafeMath library to prevent overflows.
    using SafeMath for uint256;

    // ============ Constants ============

    // The minimum amount of time left in an auction after a new bid is created; 15 min.
    uint16 public constant TIME_BUFFER = 900;
    // The ETH needed above the current bid for a new bid to be valid; 0.001 ETH.
    uint8 public constant MIN_BID_INCREMENT_PERCENT = 10;
    // Interface constant for ERC721, to check values in constructor.
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    // Allows external read `getVersion()` to return a version for the auction.
    uint256 private constant RESERVE_AUCTION_VERSION = 1;

    // ============ Immutable Storage ============

    // The address of the ERC721 contract for tokens auctioned via this contract.
    address public immutable nftContract;
    // The address of the WETH contract, so that ETH can be transferred via
    // WETH if native ETH transfers fail.
    address public immutable wethAddress;
    // The address that initially is able to recover assets.
    address public immutable adminRecoveryAddress;

    address payable public brokerAddress;
    uint256 public brokrage;

    // ============ Mutable Storage ============

    /**
     * To start, there will be an admin account that can recover funds
     * if anything goes wrong. Later, this public flag will be irrevocably
     * set to false, removing any admin privileges forever.
     *
     * To check if admin recovery is enabled, call the public function `adminRecoveryEnabled()`.
     */
    bool private _adminRecoveryEnabled;
    /**
     * The account `adminRecoveryAddress` can also pause the contracts
     * while _adminRecoveryEnabled is enabled. This prevents people from using
     * the contract if there is a known problem with it.
     */
    bool private _paused;

    // A mapping of all of the auctions currently running.
    mapping(uint256 => Auction) public auctions;

    // ============ Structs ============

    struct Auction {
        // The value of the current highest bid.
        uint256 amount;
        // The amount of time that the auction should run for,
        // after the first bid was made.
        uint256 duration;
        // The time of the first bid.
        uint256 firstBidTime;
        // The minimum price of the first bid.
        uint256 reservePrice;
        uint8 curatorFeePercent;
        // The address of the auction's curator. The curator
        // can cancel the auction if it hasn't had a bid yet.
        address curator;
        // The address of the current highest bid.
        address payable bidder;
        // The address that should receive funds once the NFT is sold.
        address payable fundsRecipient;
    }

    // ============ Events ============

    // All of the details of a new auction,
    // with an index created for the tokenId.
    event AuctionCreated(
        uint256 indexed tokenId,
        address nftContractAddress,
        uint256 duration,
        uint256 reservePrice,
        uint8 curatorFeePercent,
        address curator,
        address fundsRecipient
    );

    // All of the details of a new bid,
    // with an index created for the tokenId.
    event AuctionBid(
        uint256 indexed tokenId,
        address nftContractAddress,
        address sender,
        uint256 value
    );

    // All of the details of an auction's cancelation,
    // with an index created for the tokenId.
    event AuctionCanceled(
        uint256 indexed tokenId,
        address nftContractAddress,
        address curator
    );

    // All of the details of an auction's close,
    // with an index created for the tokenId.
    event AuctionEnded(
        uint256 indexed tokenId,
        address nftContractAddress,
        address curator,
        address winner,
        uint256 amount,
        address nftCreator,
        address payable fundsRecipient
    );

    // When the curator recevies fees, emit the details including the amount,
    // with an index created for the tokenId.
    event CuratorFeePercentTransfer(
        uint256 indexed tokenId,
        address curator,
        uint256 amount
    );

    // Emitted in the case that the contract is paused.
    event Paused(address account);
    // Emitted when the contract is unpaused.
    event Unpaused(address account);

    // ============ Modifiers ============

    // Reverts if the sender is not admin, or admin
    // functionality has been turned off.
    modifier onlyAdminRecovery() {
        require(
            // The sender must be the admin address, and
            // adminRecovery must be set to true.
            adminRecoveryAddress == msg.sender && adminRecoveryEnabled(),
            "Caller does not have admin privileges"
        );
        _;
    }

    // Reverts if the sender is not the auction's curator.
    modifier onlyCurator(uint256 tokenId) {
        require(
            auctions[tokenId].curator == msg.sender,
            "Can only be called by auction curator"
        );
        _;
    }

    // Reverts if the contract is paused.
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // Reverts if the auction does not exist.
    modifier auctionExists(uint256 tokenId) {
        // The auction exists if the curator is not null.
        require(!auctionCuratorIsNull(tokenId), "Auction doesn't exist");
        _;
    }

    // Reverts if the auction exists.
    modifier auctionNonExistant(uint256 tokenId) {
        // The auction does not exist if the curator is null.
        require(auctionCuratorIsNull(tokenId), "Auction already exists");
        _;
    }

    // Reverts if the auction is expired.
    modifier auctionNotExpired(uint256 tokenId) {
        require(
            // Auction is not expired if there's never been a bid, or if the
            // current time is less than the time at which the auction ends.
            auctions[tokenId].firstBidTime == 0 ||
                block.timestamp < auctionEnds(tokenId),
            "Auction expired"
        );
        _;
    }

    // Reverts if the auction is not complete.
    // Auction is complete if there was a bid, and the time has run out.
    modifier auctionComplete(uint256 tokenId) {
        require(
            // Auction is complete if there has been a bid, and the current time
            // is greater than the auction's end time.
            auctions[tokenId].firstBidTime > 0 &&
                block.timestamp >= auctionEnds(tokenId),
            "Auction hasn't completed"
        );
        _;
    }

    // ============ Constructor ============

    constructor(
        address nftContract_,
        address wethAddress_,
        address adminRecoveryAddress_,
        address payable _broker,
        uint256 _brokrageAmt
    ) public {
        // require(
        //     IERC165(nftContract_).supportsInterface(ERC721_INTERFACE_ID),
        //     "Contract at nftContract_ address does not support NFT interface"
        // );
        // Initialize immutable memory.
        nftContract = nftContract_;
        wethAddress = wethAddress_;
        adminRecoveryAddress = adminRecoveryAddress_;
        // Initialize mutable memory.
        _paused = false;
        _adminRecoveryEnabled = true;
        _setBrokerDetails(_broker, _brokrageAmt);
    }

    // ============ set brokerAddress and brokrage ============
    function setBrokerDetails(address payable _broker, uint256 _brokrageAmt)
        public
        onlyOwner
    {
        _setBrokerDetails(_broker, _brokrageAmt);
    }

    function _setBrokerDetails(address payable _broker, uint256 _brokrageAmt)
        internal
    {
        require(_brokrageAmt < 100, "Brokerage can't be 100%");
        brokerAddress = _broker;
        brokrage = _brokrageAmt;
    }

    // ============ set brokerAddress and brokrage ============

    // ============ Create Auction ============

    function createAuction(
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint8 curatorFeePercent,
        address curator,
        address payable fundsRecipient
    ) external nonReentrant whenNotPaused auctionNonExistant(tokenId) {
        // Check basic input requirements are reasonable.
        require(curator != address(0));
        require(
            curator == brokerAddress,
            "curator address  should be equal to brokeraddress"
        );
        require(fundsRecipient != address(0));
        require(curatorFeePercent >= brokrage, "Curator fee should be < 100");
        // Initialize the auction details, including null values.
        auctions[tokenId] = Auction({
            duration: duration,
            reservePrice: reservePrice,
            curatorFeePercent: curatorFeePercent,
            curator: curator,
            fundsRecipient: fundsRecipient,
            amount: 0,
            firstBidTime: 0,
            bidder: address(0)
        });
        // Transfer the NFT into this auction contract, from whoever owns it.
        IERC721(nftContract).transferFrom(
            IERC721(nftContract).ownerOf(tokenId),
            address(this),
            tokenId
        );
        // Emit an event describing the new auction.
        emit AuctionCreated(
            tokenId,
            nftContract,
            duration,
            reservePrice,
            curatorFeePercent,
            curator,
            fundsRecipient
        );
    }

    // ============ Create Bid ============

    function createBid(uint256 tokenId, uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        auctionExists(tokenId)
        auctionNotExpired(tokenId)
    {
        // Validate that the user's expected bid value matches the ETH deposit.
        require(amount == msg.value, "Amount doesn't equal msg.value");
        require(amount > 0, "Amount must be greater than 0");
        // Check if the current bid amount is 0.
        if (auctions[tokenId].amount == 0) {
            // If so, it is the first bid.
            auctions[tokenId].firstBidTime = block.timestamp;
            // We only need to check if the bid matches reserve bid for the first bid,
            // since future checks will need to be higher than any previous bid.
            require(
                amount >= auctions[tokenId].reservePrice,
                "Must bid reservePrice or more"
            );
        } else {
            // Check that the new bid is sufficiently higher than the previous bid, by
            // the percentage defined as MIN_BID_INCREMENT_PERCENT.
            require(
                amount >=
                    auctions[tokenId].amount.add(
                        // Add 10% of the current bid to the current bid.
                        auctions[tokenId]
                            .amount
                            .mul(MIN_BID_INCREMENT_PERCENT)
                            .div(100)
                    ),
                "Must bid more than last bid by MIN_BID_INCREMENT_PERCENT amount"
            );

            // Refund the previous bidder.
            transferETHOrWETH(
                auctions[tokenId].bidder,
                auctions[tokenId].amount
            );
        }
        // Update the current auction.
        auctions[tokenId].amount = amount;
        auctions[tokenId].bidder = msg.sender;
        // Compare the auction's end time with the current time plus the 15 minute extension,
        // to see whether we're near the auctions end and should extend the auction.
        if (auctionEnds(tokenId) < block.timestamp.add(TIME_BUFFER)) {
            // We add onto the duration whenever time increment is required, so
            // that the auctionEnds at the current time plus the buffer.
            auctions[tokenId].duration += block.timestamp.add(TIME_BUFFER).sub(
                auctionEnds(tokenId)
            );
        }
        // Emit the event that a bid has been made.
        emit AuctionBid(tokenId, nftContract, msg.sender, amount);
    }

    // ============ End Auction ============

    function endAuction(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        auctionComplete(tokenId)
    {
        // Store relevant auction data in memory for the life of this function.
        BleufiNft Token = BleufiNft(nftContract);

        //  uint256 tokenId = tokenId;
        address creator = Token.creators(tokenId);
        uint256 royalities = Token.royalities(tokenId);
        uint256 royality = (royalities * auctions[tokenId].amount) / 10000;

        address winner = auctions[tokenId].bidder;
        uint256 amount = auctions[tokenId].amount;
        address curator = auctions[tokenId].curator;
        uint8 curatorFeePercent = auctions[tokenId].curatorFeePercent;
        address payable fundsRecipient = auctions[tokenId].fundsRecipient;
        // Remove all auction data for this token from storage.
        delete auctions[tokenId];
        // We don't use safeTransferFrom, to prevent reverts at this point,
        // which would break the auction.
        IERC721(nftContract).transferFrom(address(this), winner, tokenId);

        // First handle the curator's fee.
        if (curatorFeePercent > 0) {
            // Determine the curator amount, which is some percent of the total.
            uint256 curatorAmount = amount.mul(curatorFeePercent).div(100);
            // Send it to the curator.
            transferETHOrWETH(curator, curatorAmount);
            // Subtract the curator amount from the total funds available
            // to send to the funds recipient and original NFT creator.
            amount = amount.sub(curatorAmount);
            // Emit the details of the transfer as an event.
            emit CuratorFeePercentTransfer(tokenId, curator, curatorAmount);
        }
        // Get the address of the original creator, so that we can split shares
        // if appropriate.
        // address payable nftCreator =
        //     payable(
        //         address(IMediaModified(nftContract).tokenCreators(tokenId))
        //     );
        // If the creator and the recipient of the funds are the same
        // (and we expect this to be common), we can just do one transaction.
        if (creator == fundsRecipient) {
            transferETHOrWETH(creator, amount);
        } else {
            // Otherwise, we should determine the percent that goes to the creator.
            // Collect share data from Zora.
            // uint256 creatorAmount =
            //     // Call the splitShare function on the market contract, which
            //     // takes in a Decimal and an amount.
            //     IMarket(IMediaModified(nftContract).marketContract())
            //         .splitShare(
            //         // Fetch the decimal from the BidShares data on the market.
            //         IMarket(IMediaModified(nftContract).marketContract())
            //             .bidSharesForToken(tokenId)
            //             .creator,
            //         // Specify the amount.
            //         amount
            //     );
            // Send the creator's share to the creator.
            // transferETHOrWETH(nftCreator, creatorAmount);
            transferETHOrWETH(creator, royality);

            // Send the remainder of the amount to the funds recipient.
            // transferETHOrWETH(fundsRecipient, amount.sub(creatorAmount));
            transferETHOrWETH(fundsRecipient, amount.sub(royality));
        }
        // Emit an event describing the end of the auction.
        emit AuctionEnded(
            tokenId,
            nftContract,
            curator,
            winner,
            amount,
            creator,
            fundsRecipient
        );
    }

    // ============ Cancel Auction ============

    function cancelAuction(uint256 tokenId)
        external
        nonReentrant
        auctionExists(tokenId)
        onlyCurator(tokenId)
    {
        // Check that there hasn't already been a bid for this NFT.
        require(
            uint256(auctions[tokenId].firstBidTime) == 0,
            "Auction already started"
        );
        // Pull the creator address before removing the auction.
        address curator = auctions[tokenId].curator;
        // Remove all data about the auction.
        delete auctions[tokenId];
        // Transfer the NFT back to the curator.
        IERC721(nftContract).transferFrom(address(this), curator, tokenId);
        // Emit an event describing that the auction has been canceled.
        emit AuctionCanceled(tokenId, nftContract, curator);
    }

    // ============ Admin Functions ============

    // Irrevocably turns off admin recovery.
    function turnOffAdminRecovery() external onlyAdminRecovery {
        _adminRecoveryEnabled = false;
    }

    function pauseContract() external onlyAdminRecovery {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyAdminRecovery {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // Allows the admin to transfer any NFT from this contract
    // to the recovery address.
    function recoverNFT(uint256 tokenId) external onlyAdminRecovery {
        IERC721(nftContract).transferFrom(
            // From the auction contract.
            address(this),
            // To the recovery account.
            adminRecoveryAddress,
            // For the specified token.
            tokenId
        );
    }

    // Allows the admin to transfer any ETH from this contract to the recovery address.
    function recoverETH(uint256 amount)
        external
        onlyAdminRecovery
        returns (bool success)
    {
        // Attempt an ETH transfer to the recovery account, and return true if it succeeds.
        success = attemptETHTransfer(adminRecoveryAddress, amount);
    }

    // ============ Miscellaneous Public and External ============

    // Returns true if the contract is paused.
    function paused() public view returns (bool) {
        return _paused;
    }

    // Returns true if admin recovery is enabled.
    function adminRecoveryEnabled() public view returns (bool) {
        return _adminRecoveryEnabled;
    }

    // Returns the version of the deployed contract.
    function getVersion() external pure returns (uint256 version) {
        version = RESERVE_AUCTION_VERSION;
    }

    // ============ Private Functions ============

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function transferETHOrWETH(address to, uint256 value) private {
        // Try to transfer ETH to the given recipient.
        if (!attemptETHTransfer(to, value)) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(wethAddress).deposit{value: value}();
            IWETH(wethAddress).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    // Sending ETH is not guaranteed complete, and the method used here will return false if
    // it fails. For example, a contract can block ETH transfer, or might use
    // an excessive amount of gas, thereby griefing a new bidder.
    // We should limit the gas used in transfers, and handle failure cases.
    function attemptETHTransfer(address to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    // Returns true if the auction's curator is set to the null address.
    function auctionCuratorIsNull(uint256 tokenId) private view returns (bool) {
        // The auction does not exist if the curator is the null address,
        // since the NFT would not have been transferred in `createAuction`.
        return auctions[tokenId].curator == address(0);
    }

    // Returns the timestamp at which an auction will finish.
    function auctionEnds(uint256 tokenId) private view returns (uint256) {
        // Derived by adding the auction's duration to the time of the first bid.
        // NOTE: duration can be extended conditionally after each new bid is added.
        return auctions[tokenId].firstBidTime.add(auctions[tokenId].duration);
    }
}