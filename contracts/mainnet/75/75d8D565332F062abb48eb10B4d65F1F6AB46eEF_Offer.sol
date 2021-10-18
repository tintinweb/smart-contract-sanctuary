/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

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


// File @openzeppelin/contracts/security/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]


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


// File contracts/interfaces/IKoansToken.sol

pragma solidity ^0.8.6;

interface IKoansToken is IERC721 {
    event KoanCreated(uint256 indexed tokenId);

    event KoanBurned(uint256 indexed tokenId);

    event FoundersDAOUpdated(address koansDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    function setContractURIHash(string memory newContractURIHash) external;
    
    function setFoundersDAO(address _foundersDAO) external;

    function setMinter(address _minter) external;
    
    function lockMinter() external;

    function mintFoundersDAOKoan(string memory _foundersDAOMetadataURI) external;

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMetadataURI(uint256 tokenId, string memory metadataURI) external;

}


// File contracts/interfaces/IKoansAuctionHouse.sol

pragma solidity ^0.8.6;

interface IKoansAuctionHouse {
    struct Auction {
        // ID for the Koan (ERC721 token ID)
        uint256 koanId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // The address to payout a portion of the auction's proceeds to.
        address payable payoutAddress;
    }

    event AuctionCreated(uint256 indexed koanId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed koanId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed koanId, uint256 endTime);

    event AuctionSettled(uint256 indexed koanId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event PayoutRewardBPUpdated(uint256 artistRewardBP);

    event AuctionDurationUpdated(uint256 duration);

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    function createBid(uint256 koanId) external payable;

    function addOffer(string memory _uri, address _payoutAddress) external;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 _timeBuffer) external;

    function setReservePrice(uint256 _reservePrice) external;

    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external;

    function setPayoutRewardBP(uint256 _payoutRewardBP) external;

    function setDuration(uint256 _duration) external;

    function setOfferAddress(address _koanOfferAddress) external;

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


// File contracts/interfaces/ISashoToken.sol

pragma solidity ^0.8.6;

interface ISashoToken is IERC20 {

    function mint(address account, uint256 rawAmount) external;

    function burn(uint256 tokenId) external;

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}


// File contracts/interfaces/IOffer.sol

pragma solidity ^0.8.6;

interface IOffer {

    struct Offer {
        // IPFS path for the propsoed image/metadata.
        string uriPath;
        // The address to pay proceeds if this offer wins an auction.
        address payoutAddress;
        // Count of the total votes in favor of this
        // offer.
        uint voteCount;
    }

    struct OfferPeriod {
        // ID for the Offer period
        uint256 id;
        // The block where the offer submission period is scheduled to begin.
        uint256 offerStartBlock;
        // The block where the offer submission period is scheduled to end and
        // voting should begin.
        uint256 offerEndBlock;
        // The block where voting is scheduled to end
        uint256 votingEndBlocks;
        // If this offer period has already been settled.
        bool settled;
    }

    event KoanVoted(uint256 indexed koanId, uint256 offerPeriodId, uint256 offerId);

    event SashoVoted(address indexed sashoAddress, uint256 offerPeriodId, uint256 offerId, uint256 sashoVotes);

    event OfferPeriodSettled(uint256 offerPeriodId, string uriPath, address artist);

    event OfferPeriodCreated(uint256 offerPeriodId);

    event OfferPeriodEndedWithoutProposal(uint256 offerPeriodId);

    event OfferPeriodEndedWithoutVotes(uint256 offerPeriodId);

    event ArtOffered(uint256 indexed offerPeriodId, address indexed submitter, uint256 offerIndex, string uriPath, address payoutAddress);

    event KoanVotingWeightUpdated(uint256 koanVotingWeight);

    event MinCollateralUpdated(uint256 minCollateral);

    event OfferFeeUpdated(uint256 offerFee);

    event OfferDurationBlocksUpdated(uint256 offerDurationBlocks);

    event VotingPeriodDurationBlocksUpdated(uint256 votingPeriodDurationBlocks);

    function pause() external;

    function unpause() external;

    function settleOfferPeriod() external;

    function settleCurrentAndCreateNewOfferPeriod() external;

    function setKoanVotingWeight(uint koanVotingWeight_) external;

    function setMinCollateral(uint minCollateral_) external;

    function setOfferFee(uint offerFee_) external;

    function setOfferDurationBlocks(uint offerDurationBlocks_) external;

    function setVotingPeriodDurationBlocks(uint votingPeriodDurationBlocks_) external;

}


// File contracts/interfaces/IWETH.sol


pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}


// File contracts/Offer.sol


/// @title The Offer contract.

pragma solidity ^0.8.6;









contract Offer is IOffer, Pausable, ReentrancyGuard, Ownable { 
    // The address of the Koans contract
    address public koans;

    // The address of the Sasho contract.
    address public sashos;

    // The duration of an offer period in blocks.
    uint256 public offerDurationBlocks;

    // The duration of a voting period in blocks.
    uint256 public votingPeriodDurationBlocks;

    // How many Sashos votes the votes from a single Koan is equivalent to.
    uint256 public koanVotingWeight;

    // The active offer period.
    IOffer.OfferPeriod public offerPeriod;

    // The auction house contract that mints and auctions the Koans.
    IKoansAuctionHouse public auctionHouse;

    // A mapping of Offer Period IDs to wallets and whether or not they've voted yet
    // in this offer period's voting period.
    mapping(uint256 => mapping(address => bool)) public sashoVotesPerOfferPeriod;

    // A mapping of Offer Period IDs to Koan IDs and whether or not they've voted yet
    // in this offer period's voting period.
    mapping(uint256 => mapping(uint256 => bool)) public koanVotesPerOfferPeriod;

    // A mapping from the Offer Period ID to an array of the offers under consideration.
    mapping(uint256 => Offer[]) public offersPerOfferPeriod;

    // A mapping of Offer Period IDs to addresses and the amount of collateral they've put
    // up for offers in that period. 
    mapping(uint256 => mapping(address => uint256)) public offerPeriodToAddressCollateral;

    // The minimum amount of eth that must be included with an offer as collateral.
    uint256 public minCollateral;

    // The ETH fee that must be paid to the DAO when making an offer.
    uint256 public offerFee;

    // The address of the Koans DAO to send fees to.
    address public koansDAO;

    // The address of the WETH contract
    address public weth;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    constructor(
        address _koans,
        address _sashos,
        uint256 _offerDurationBlocks,
        uint256 _votingPeriodDurationBlocks,
        IKoansAuctionHouse _auctionHouse,
        address _koansDAO,
        address _weth
        ) {

        _pause();

        koans = _koans;
        sashos = _sashos;
        offerDurationBlocks = _offerDurationBlocks;
        votingPeriodDurationBlocks = _votingPeriodDurationBlocks;
        auctionHouse = _auctionHouse;
        // Set initial voting weight to be equal to a million Sashos.
        koanVotingWeight = 1000000*10e18;
        offerPeriod = OfferPeriod({
            id: 0,
            offerStartBlock: 0,
            offerEndBlock: block.number + offerDurationBlocks,
            votingEndBlocks: block.number + offerDurationBlocks + votingPeriodDurationBlocks,
            settled: false
            });
        koansDAO = _koansDAO;
        minCollateral = 0;
        offerFee = 0;
        weth = _weth;
    }

    /**
     * @notice Add an offer to the current OfferPeriod.
     * @dev Excess value is saved as collateral.
     */
     function offer(string memory uriPath, address payoutAddress) external payable whenNotPaused nonReentrant {
        // Consider adding map + check that the URI is not already present
        require(block.number >= offerPeriod.offerStartBlock, "Offer period hasn't begun");
        require(block.number < offerPeriod.offerEndBlock, "Offer period has ended." );
        require(msg.value >= minCollateral + offerFee, "Must include collateral and fee.");
        offerPeriodToAddressCollateral[offerPeriod.id][msg.sender] += msg.value - offerFee;
        _safeTransferETHWithFallback(koansDAO, offerFee);
        Offer memory offer = Offer({
            uriPath: uriPath,
            payoutAddress: payoutAddress,
            voteCount: 0
            });
        offersPerOfferPeriod[offerPeriod.id].push(offer);
        emit ArtOffered(
            /*offerPeriodId=*/offerPeriod.id,
            /*submitter=*/msg.sender,
            /*offerIndex=*/offersPerOfferPeriod[offerPeriod.id].length - 1,
            /*uriPath=*/uriPath,
            /*payoutAddress=*/payoutAddress);
    }

    /**
     *  @notice Reclaim collateral from a previous offer period.
     */
     function reclaimCollateral(uint256 offerPeriodId) external nonReentrant {
        require(offerPeriodId < offerPeriod.id, "Offer period hasn't ended");
        uint256 collateralToReclaim = offerPeriodToAddressCollateral[offerPeriodId][msg.sender];
        offerPeriodToAddressCollateral[offerPeriodId][msg.sender] = 0;
        _safeTransferETHWithFallback(msg.sender, collateralToReclaim);
    }

    /**
     * @notice Pause the Koans offer contract.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new offer periods can be started when paused,
     * anyone can settle an ongoing offer period.
     */
     function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Koans offer contract.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new offer period.
     */
     function unpause() external override onlyOwner {
        _unpause();
        if (offerPeriod.offerStartBlock == 0 || offerPeriod.settled) {
            _createOfferPeriod();
        }
    }

    /**
     * @notice Vote for the offer at `offer` using the koan matching koanId.
     */
     function voteWithKoan(uint256 koanId, uint offer) external whenNotPaused nonReentrant {
        require(block.number > offerPeriod.offerEndBlock, "Voting period hasn't started" );
        require(block.number < offerPeriod.votingEndBlocks, "Voting period has ended" );
        require(msg.sender == IKoansToken(koans).ownerOf(koanId), "Voter doesn't own Koan");
        require(!koanVotesPerOfferPeriod[offerPeriod.id][koanId], "Koan has already voted");
        offersPerOfferPeriod[offerPeriod.id][offer].voteCount += koanVotingWeight;
        koanVotesPerOfferPeriod[offerPeriod.id][koanId] = true;
        emit KoanVoted(koanId, offerPeriod.id, offer);
    }

    /**
     * @notice Vote for offer using the Sasho balance of msg.sender's wallet (at the last checkpoint
     * stored in the Sashos contract.) 
     */
     function voteWithSasho(uint offer) external whenNotPaused nonReentrant {
        require(block.number > offerPeriod.offerEndBlock, "Voting period hasn't started" );
        require(block.number < offerPeriod.votingEndBlocks, "Voting period has ended" );
        require(!sashoVotesPerOfferPeriod[offerPeriod.id][msg.sender], "Sasho wallet has already voted");
        sashoVotesPerOfferPeriod[offerPeriod.id][msg.sender] = true;

        uint96 sashoVotes = ISashoToken(sashos).getPriorVotes(msg.sender, offerPeriod.offerEndBlock);
        offersPerOfferPeriod[offerPeriod.id][offer].voteCount += sashoVotes;

        emit SashoVoted(msg.sender, offerPeriod.id, offer, sashoVotes);
    }


    /**
     * @notice Settle the current offer period and create a new one.
     */
     function settleCurrentAndCreateNewOfferPeriod() external override nonReentrant whenNotPaused {
      _settleOfferPeriod();
      _createOfferPeriod();
  }

    /**
     * @notice Set the voting weight of a Koan (in Sasho equivalent units)
     */
     function setKoanVotingWeight(uint _koanVotingWeight) external override onlyOwner {
        koanVotingWeight = _koanVotingWeight;

        emit KoanVotingWeightUpdated(_koanVotingWeight);
    }

    /**
     * @notice Set the minimum ethereum collateral needed to make an offer.
     */
     function setMinCollateral(uint _minCollateral) external override onlyOwner {
        minCollateral = _minCollateral;

        emit MinCollateralUpdated(_minCollateral);
    }

    /**
     * @notice Set the fee paid to the DAO when making an offer.
     */
     function setOfferFee(uint _offerFee) external override onlyOwner {
        offerFee = _offerFee;

        emit OfferFeeUpdated(_offerFee);
    }

    /**
     * @notice Set the offering duration in blocks.
     * @dev Only callable by the owner.
     */
     function setOfferDurationBlocks(uint _offerDurationBlocks) external override onlyOwner {
        offerDurationBlocks = _offerDurationBlocks;

        emit OfferDurationBlocksUpdated(_offerDurationBlocks);
    }

    /**
     * @notice Set the offering duration in blocks.
     * @dev Only callable by the owner.
     */
     function setVotingPeriodDurationBlocks(uint _votingPeriodDurationBlocks) external override onlyOwner {
        votingPeriodDurationBlocks = _votingPeriodDurationBlocks;

        emit VotingPeriodDurationBlocksUpdated(_votingPeriodDurationBlocks);
    }

    /**
     * @notice Settle the current offer period and add the URI and payout info to the
     * auction house queue.
     */
     function settleOfferPeriod() external override whenPaused nonReentrant {
        _settleOfferPeriod();

    }

    function _createOfferPeriod() internal {
        offerPeriod = OfferPeriod({
            id: offerPeriod.id + 1,
            offerStartBlock: block.number,
            offerEndBlock: block.number + offerDurationBlocks,
            votingEndBlocks: block.number + offerDurationBlocks + votingPeriodDurationBlocks,
            settled: false
            });
        emit OfferPeriodCreated(offerPeriod.id);
    }

    function _settleOfferPeriod() internal {
        require(offerPeriod.offerStartBlock != 0, "Offer period hasn't begun");
        require(!offerPeriod.settled, "Offer has already been settled");
        require(block.number >= offerPeriod.votingEndBlocks,
            "Voting period hasn't ended");

        offerPeriod.settled = true;
        if (offersPerOfferPeriod[offerPeriod.id].length == 0) {
            emit OfferPeriodEndedWithoutProposal(offerPeriod.id);
            return;
        }

        Offer memory winningOffer = _winningOffer();
        if (winningOffer.voteCount != 0) {
            auctionHouse.addOffer(winningOffer.uriPath, winningOffer.payoutAddress);
            emit OfferPeriodSettled(offerPeriod.id, winningOffer.uriPath, winningOffer.payoutAddress);
            return;
        }
        emit OfferPeriodEndedWithoutVotes(offerPeriod.id);
    }

    /**
     * @notice Return the current winning offer.
     * @dev the returned value will have the default values set for its fields
     * if there are no votes on any of the offers.
     */
     function _winningOffer() internal view
     returns (Offer memory winningOffer) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < offersPerOfferPeriod[offerPeriod.id].length; p++) {
            if (offersPerOfferPeriod[offerPeriod.id][p].voteCount > winningVoteCount) {
                winningVoteCount = offersPerOfferPeriod[offerPeriod.id][p].voteCount;
                winningOffer = offersPerOfferPeriod[offerPeriod.id][p];
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

}