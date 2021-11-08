// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface ISwapFeeRewardWithRB {
    function accrueRBFromAuction(address account, address fromToken, uint amount) external;
}


contract Auction is ReentrancyGuard, Ownable, Pausable, IERC721Receiver {
    using SafeERC20 for IERC20;

    enum State {ST_OPEN, ST_FINISHED, ST_CANCELLED}

    struct TokenPair {
        IERC721 nft;
        uint256 tokenId;
    }

    struct Inventory {
        TokenPair pair;
        address seller;
        address bidder;
        IERC20 currency;
        uint256 askPrice;
        uint256 bidPrice;
        uint256 netBidPrice;
        uint256 startBlock;
        uint256 endTimestamp;
        State status;
    }

    event NFTBlacklisted(IERC721 nft, bool whitelisted);
    event NewAuction(
        uint256 indexed id,
        address indexed seller,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp,
        TokenPair pair
    );
    event NewBid(
        uint256 indexed id,
        address indexed bidder,
        uint256 price,
        uint256 netPrice,
        uint256 endTimestamp
    );
    event AuctionCancelled(uint256 indexed id);
    event AuctionFinished(uint256 indexed id, address indexed winner);
    event NFTAccrualListUpdate(address nft, bool state);

    bool internal _canReceive = false;
    IWETH public immutable weth;
    Inventory[] public auctions;
    //    mapping(uint256 => mapping(uint256 => TokenPair)) public auctionNfts; delete

    mapping(IERC721 => bool) public nftBlacklist;
    mapping(address => bool) public nftForAccrualRB; //add tokens on which RobiBoost is accrual
    mapping(IERC20 => bool) public dealTokenWhitelist;
    mapping(IERC721 => mapping(uint256 => uint256)) public auctionNftIndex; // nft -> tokenId -> id
    mapping(address => uint) public userFee; //User auction fee. if Zero - default fee

    uint constant MAX_DEFAULT_FEE = 1000; // max fee 10%
    address public treasuryAddress;
    uint public defaultFee = 100; //in base 10000 1%


    uint256 public extendEndTimestamp; // in seconds
    uint256 public minAuctionDuration; // in seconds

    uint256 public rateBase;
    uint256 public bidderIncentiveRate;
    uint256 public bidIncrRate;
    ISwapFeeRewardWithRB feeRewardRB;
    bool feeRewardRBIsEnabled;

    constructor(
        IWETH weth_,
        uint256 extendEndTimestamp_,
        uint256 minAuctionDuration_,
        uint256 rateBase_,
        uint256 bidderIncentiveRate_,
        uint256 bidIncrRate_,
        address treasuryAddress_,
        ISwapFeeRewardWithRB feeRewardRB_
    ) {
        weth = weth_;
        extendEndTimestamp = extendEndTimestamp_;
        minAuctionDuration = minAuctionDuration_;
        rateBase = rateBase_;
        bidderIncentiveRate = bidderIncentiveRate_;
        bidIncrRate = bidIncrRate_;
        treasuryAddress = treasuryAddress_;
        feeRewardRB = feeRewardRB_;

        auctions.push(
            Inventory({
        pair: TokenPair(IERC721(address(0)), 0),
        seller: address(0),
        bidder: address(0),
        currency: IERC20(address(0)),
        askPrice: 0,
        bidPrice: 0,
        netBidPrice: 0,
        startBlock: 0,
        endTimestamp: 0,
        status: State.ST_CANCELLED
        })
        );
    }

    function updateSettings(
        uint256 extendEndTimestamp_,
        uint256 minAuctionDuration_,
        uint256 rateBase_,
        uint256 bidderIncentiveRate_,
        uint256 bidIncrRate_,
        address treasuryAddress_,
        ISwapFeeRewardWithRB _feeRewardRB
    ) public onlyOwner {
        extendEndTimestamp = extendEndTimestamp_;
        minAuctionDuration = minAuctionDuration_;
        rateBase = rateBase_;
        bidderIncentiveRate = bidderIncentiveRate_;
        bidIncrRate = bidIncrRate_;
        treasuryAddress = treasuryAddress_;
        feeRewardRB = _feeRewardRB;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhiteListDealToken(IERC20 cur) public onlyOwner {
        dealTokenWhitelist[cur] = true;
    }

    function unWhitelistDealToken(IERC20 cur) public onlyOwner {
        delete dealTokenWhitelist[cur];
    }

    function blacklistNFT(IERC721 nft) public onlyOwner {
        nftBlacklist[nft] = true;
        emit NFTBlacklisted(nft, true);
    }

    function unblacklistNFT(IERC721 nft) public onlyOwner {
        delete nftBlacklist[nft];
        emit NFTBlacklisted(nft, false);
    }

    function addNftForAccrualRB(address _nft) public onlyOwner {
        require(_nft != address(0), "Address cant be zero");
        nftForAccrualRB[_nft] = true;
        emit NFTAccrualListUpdate(_nft, true);
    }

    function delNftForAccrualRB(address _nft) public onlyOwner {
        require(_nft != address(0), "Address cant be zero");
        delete nftForAccrualRB[_nft];
        emit NFTAccrualListUpdate(_nft, false);
    }

    function setUserFee(address user, uint fee) public onlyOwner {
        userFee[user] = fee;
    }

    function setDefaultFee(uint _newFee) public onlyOwner {
        require(_newFee <= MAX_DEFAULT_FEE, "New fee must be less than or equal to max fee");
        defaultFee = _newFee;
    }

    function enableRBFeeReward() public onlyOwner {
        feeRewardRBIsEnabled = true;
    }

    function disableRBFeeReward() public onlyOwner {
        feeRewardRBIsEnabled = false;
    }

    // public

    receive() external payable {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused returns (bytes4) {
        if (data.length > 0) {
            require(operator == from, 'caller should own the token');
            require(!nftBlacklist[IERC721(msg.sender)], 'token not allowed');
            (IERC20 currency, uint256 askPrice, uint256 endTimestamp) = abi.decode(
                data,
                (IERC20, uint256, uint256)
            );
            TokenPair memory pair = TokenPair({
            nft: IERC721(msg.sender),
            tokenId: tokenId
            });
            _sell(from, pair, currency, askPrice, endTimestamp);
        } else {
            require(_canReceive, 'cannot transfer directly');
        }

        return this.onERC721Received.selector;
    }

    function sell(
        TokenPair calldata pair,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp
    ) public nonReentrant whenNotPaused _waitForTransfer notContract {
        require(address(pair.nft) != address(0), 'Address cant be zero');

        require(!nftBlacklist[pair.nft], 'token not allowed');
        require(_isTokenOwnerAndApproved(pair.nft, pair.tokenId), 'token not approved');
        pair.nft.safeTransferFrom(msg.sender, address(this), pair.tokenId);

        _sell(msg.sender, pair, currency, askPrice, endTimestamp);
    }

    function _sell(
        address seller,
        TokenPair memory pair,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp
    ) internal _allowedDealToken(currency) {
        require(askPrice > 0, 'askPrice > 0');
        require(
            endTimestamp >= block.timestamp + minAuctionDuration,
            'auction duration not long enough'
        );

        uint256 id = auctions.length;

        auctions.push(
            Inventory({
        pair: pair,
        seller: seller,
        bidder: address(0),
        currency: currency,
        askPrice: askPrice,
        bidPrice: 0,
        netBidPrice: 0,
        startBlock: block.number,
        endTimestamp: endTimestamp,
        status: State.ST_OPEN
        })
        );

        auctionNftIndex[pair.nft][pair.tokenId] = id;
        emit NewAuction(id, seller, currency, askPrice, endTimestamp, pair);
    }

    function bid(uint256 id, uint256 offer)
    public
    payable
    _hasAuction(id)
    _isStOpen(id)
    nonReentrant
    whenNotPaused
    notContract
    {
        Inventory storage inv = auctions[id];
        require(block.timestamp < inv.endTimestamp, 'auction finished');

        // set offer to native value
        if (address(inv.currency) == address(weth)) {
            offer = msg.value;
        }

        // minimum increment
        require(offer >= getMinBidPrice(id), 'not enough');

        // collect token
        if (address(inv.currency) == address(weth)) {
            weth.deposit{value: offer}(); // convert to weth for later use
        } else {
            inv.currency.safeTransferFrom(msg.sender, address(this), offer);
        }

        // transfer some to previous bidder
        uint256 incentive = 0;
        if (inv.netBidPrice > 0 && inv.bidder != address(0)) {
            incentive = (offer * bidderIncentiveRate) / rateBase;
            _transfer(inv.currency, inv.bidder, inv.netBidPrice + incentive);
        }

        inv.bidPrice = offer;
        inv.netBidPrice = offer - incentive;
        inv.bidder = msg.sender;
        if (block.timestamp + extendEndTimestamp >= inv.endTimestamp) {
            inv.endTimestamp += extendEndTimestamp;
        }

        emit NewBid(id, msg.sender, offer, inv.netBidPrice, inv.endTimestamp);
    }

    function cancel(uint256 id)
    public
    _hasAuction(id)
    _isStOpen(id)
    _isSeller(id)
    nonReentrant
    whenNotPaused
    notContract
    {
        Inventory storage inv = auctions[id];
        require(inv.bidder == address(0), 'has bidder');
        _cancel(id);
    }

    function _cancel(uint256 id) internal {
        Inventory storage inv = auctions[id];

        inv.status = State.ST_CANCELLED;
        _transferInventoryTo(id, inv.seller);
        delete auctionNftIndex[inv.pair.nft][inv.pair.tokenId];
        emit AuctionCancelled(id);
    }

    // anyone can collect any auction, as long as it's finished
    function collect(uint256[] calldata ids) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            _collectOrCancel(ids[i]);
        }
    }

    function _collectOrCancel(uint256 id) internal _hasAuction(id) _isStOpen(id) {
        Inventory storage inv = auctions[id];
        require(block.timestamp >= inv.endTimestamp, 'auction not done yet');
        if (inv.bidder == address(0)) {
            _cancel(id);
        } else {
            _collect(id);
        }
    }

    function _collect(uint256 id) internal {
        Inventory storage inv = auctions[id];

        // take fee
        uint256 feeRate = userFee[inv.seller] == 0 ? defaultFee : userFee[inv.seller];
        uint256 fee = (inv.netBidPrice * feeRate) / 10000;
        if (fee > 0) {
            _transfer(inv.currency, treasuryAddress, fee);
            if(feeRewardRBIsEnabled && nftForAccrualRB[address(inv.pair.nft)]){
                feeRewardRB.accrueRBFromAuction(inv.bidder, address(inv.currency), fee / 2);
                feeRewardRB.accrueRBFromAuction(inv.seller, address(inv.currency), fee / 2);
            }
        }

        // transfer profit and token
        _transfer(inv.currency, inv.seller, inv.netBidPrice - fee);
        inv.status = State.ST_FINISHED;
        _transferInventoryTo(id, inv.bidder);

        emit AuctionFinished(id, inv.bidder);
    }

    function isOpen(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == State.ST_OPEN && block.timestamp < inv.endTimestamp;
    }

    function isCollectible(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == State.ST_OPEN && block.timestamp >= inv.endTimestamp;
    }

    function isCancellable(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == State.ST_OPEN && inv.bidder == address(0);
    }

    function numAuctions() public view returns (uint256) {
        return auctions.length;
    }

    function getMinBidPrice(uint256 id) public view returns (uint256) {
        Inventory storage inv = auctions[id];

        // minimum increment
        if (inv.bidPrice == 0) {
            return inv.askPrice;
        } else {
            return inv.bidPrice + (inv.bidPrice * bidIncrRate) / rateBase;
        }
    }

    // internal

    modifier _isStOpen(uint256 id) {
        require(auctions[id].status == State.ST_OPEN, 'auction finished or cancelled');
        _;
    }

    modifier _hasAuction(uint256 id) {
        require(id > 0 && id < auctions.length, 'auction does not exist');
        _;
    }

    modifier _isSeller(uint256 id) {
        require(auctions[id].seller == msg.sender, 'caller is not seller');
        _;
    }

    modifier _allowedDealToken(IERC20 token) {
        require(dealTokenWhitelist[token], 'currency not allowed');
        _;
    }

    modifier _waitForTransfer() {
        _canReceive = true;
        _;
        _canReceive = false;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function _transfer(
        IERC20 currency,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0 && to != address(0)) {
            if (address(currency) == address(weth)) {
                weth.withdraw(amount);
                payable(to).transfer(amount);
            } else {
                currency.safeTransfer(to, amount);
            }
        }
    }

    function _isTokenOwnerAndApproved(IERC721 token, uint256 tokenId) internal view returns (bool) {
        return
        (token.ownerOf(tokenId) == msg.sender) &&
        (token.getApproved(tokenId) == address(this) ||
        token.isApprovedForAll(msg.sender, address(this)));
    }

    function _transferInventoryTo(uint256 id, address to) internal {
        Inventory storage inv = auctions[id];
        inv.pair.nft.safeTransferFrom(address(this), to, inv.pair.tokenId);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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