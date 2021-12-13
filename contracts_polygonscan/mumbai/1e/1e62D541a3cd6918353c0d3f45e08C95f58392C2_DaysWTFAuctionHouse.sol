// SPDX-License-Identifier: GPL-3.0

/// @title The Days.WTF's Treasury in Time Space (TITS) DAO auction house

// LICENSE
// DaysWTFAuctionHouse.sol is a modified version of Nouns's NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// AuctionHouse.sol source code Copyright licensed under the GPL-3.0 license.
// With modifications by TITS DAO.

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IDaysWTFAuctionHouse } from './interfaces/IDaysWTFAuctionHouse.sol';
import { IDaysWTFToken } from './interfaces/IDaysWTFToken.sol';
import { IWhitelist } from './interfaces/IWhitelist.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract DaysWTFAuctionHouse is
    IDaysWTFAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    // The Days.WTF ERC721 token contract
    IDaysWTFToken public dayswtf;

    // The whitelist contract
    IWhitelist public whitelist;

    // Charity address, The Rainforest Foundation: 0x338326660F32319E2B0Ad165fcF4a528c1994aCb
    address payable public charity;

    // The address of the WETH contract
    address public weth;

    // The minimum price accepted in an auction
    uint256 public reservePrice; // default 10 matic

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage; // default 2%

    // When minting starts
    uint256 public startDate;

    // max free initial mint
    uint256 constant maxFreeMint = 10950;
    uint256 public freeMintCount;
    mapping(address => uint256) public freeMintLevelFlag; // everyone can free mint 1 token up to their level

    // The active auction
    IDaysWTFAuctionHouse.Auction public auction;

    // @notice When contract is not paused and free mint is not finished
    modifier whenMintActive() {
        require(!paused() && block.timestamp >= startDate && freeMintCount <= maxFreeMint, 'Minting is not active');
        _;
    }

    // @notice When contract is not paused and free mint is over
    modifier whenBidActive() {
        require(!paused() && block.timestamp >= startDate && freeMintCount >= maxFreeMint, 'Bidding is not active');
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IDaysWTFToken _dayswtf,
        IWhitelist _whitelist,
        address _charity,
        address _weth,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _startDate
    ) external initializer {
        require(_startDate > block.timestamp, 'startDate must be in the future');
        require(address(_whitelist) != address(0), 'whitelist must be set');
        require(address(_charity) != address(0), 'charity must be set');
        require(address(_weth) != address(0), 'weth must be set');

        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        freeMintCount = 0;
        dayswtf = _dayswtf;
        whitelist = _whitelist;
        charity = payable(_charity);
        weth = _weth;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        startDate = _startDate;
    }

    /**
     * @notice Get the maximum level someone can mint a free token, based on referral count.
     */
    function getMaxLevelFromReferralCount(uint256 _referralCount) public pure returns (uint256) {
        // Satoshi level
        if (_referralCount > 10950) return 6;
        if (_referralCount >= 2000) return 5;
        if (_referralCount >= 500) return 4;
        if (_referralCount >= 100) return 3;
        if (_referralCount >= 50) return 2;
        if (_referralCount >= 10) return 1;
        return 0;
    }

    function freeMint(string memory day) public whenMintActive {
        address _sender = _msgSender();
        require(whitelist.isWhitelisted(_sender), 'Only whitelisted users can mint');

        uint256 dayId = dayswtf.stringToDayId(day);
        uint256 dayLevel = dayswtf.getDayLevel(dayId);
        uint256 mask = 1 << dayLevel;
        uint256 maxLevel = getMaxLevelFromReferralCount(whitelist.getReferredCount(_sender));

        require(!dayswtf.exists(dayId), 'Day already exists');
        require(maxLevel >= dayLevel, 'Cannot mint a token higher than your level');
        require(freeMintLevelFlag[_sender] & mask == 0, 'For each level only 1 free mint is allowed');
        require(block.timestamp >= startDate + (6 - maxLevel) * 1 hours, 'Cannot yet mint, levels open up hourly');

        // increasing the counters
        freeMintLevelFlag[_sender] ^= mask;
        freeMintCount++;

        // mint the token
        if (!_mintTo(dayId, _sender, MintType.AIRDROP)) revert();

        emit AirdropMinted(dayId, _sender, dayLevel);
    }

    /**
     * @notice Settle the current auction, mint a new Day, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenBidActive {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Day, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(
        uint256 dayId,
        uint256 pastDayTimestamp,
        address _referral
    ) external payable override nonReentrant whenBidActive {
        IDaysWTFAuctionHouse.Auction memory _auction = auction;
        uint256 pastDayId = dayswtf.timestampToDayId(pastDayTimestamp);

        require(_auction.dayId == dayId, 'Day not up for auction');
        /* TODO: consider activating this check
        require(
            _auction.bidderFirst.bidder == address(0) || _auction.bidderFirst.bidder != _msgSender(),
            'You are the top bidder already.'
        );
        */
        require(!dayswtf.exists(pastDayId), 'Past day already exists');
        require(pastDayId < dayId, 'Past day must be before current day');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >=
                _auction.bidderFirst.amount + ((_auction.bidderFirst.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        // move the bidders
        if (_auction.bidderSecond.bidder != address(0)) auction.bidderThird = _auction.bidderSecond;
        if (_auction.bidderFirst.bidder != address(0)) {
            auction.bidderSecond = _auction.bidderFirst;
            _safeTransferETHWithFallback(_auction.bidderFirst.bidder, _auction.bidderFirst.amount); // refund last bidder
        }

        // save current bid
        auction.bidderFirst.amount = msg.value;
        auction.bidderFirst.bidder = payable(_msgSender());
        auction.bidderFirst.past = pastDayId;

        // no self-referral is allowed
        if (_msgSender() == _referral || _referral == address(0)) auction.bidderFirst.referral = payable(address(0));
        else auction.bidderFirst.referral = payable(_referral);

        emit AuctionBid(_auction.dayId, _msgSender(), msg.value);
    }

    /**
     * @notice Pause the Days.WTF auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Days.WTF auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        // FIXME: remove, or fine tune for MINT vs BID system
        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try dayswtf.mint(dayswtf.timestampToDayId(block.timestamp), MintType.TODAY) returns (uint256 dayId) {
            // create the auction
            uint256 startTime = block.timestamp;
            uint256 ellapsedDays = startTime / 1 days;
            uint256 endTime = ellapsedDays * 1 days;

            auction = Auction({
                dayId: dayId,
                startTime: startTime,
                endTime: endTime,
                settled: false,
                bidderFirst: Bid({ amount: 0, bidder: payable(0), referral: payable(0), past: 0 }),
                bidderSecond: Bid({ amount: 0, bidder: payable(0), referral: payable(0), past: 0 }),
                bidderThird: Bid({ amount: 0, bidder: payable(0), referral: payable(0), past: 0 })
            });

            emit AuctionCreated(dayId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Day is burned.
     */
    function _settleAuction() internal {
        IDaysWTFAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidderFirst.bidder == address(0)) {
            // no bidder, burn the day
            dayswtf.burn(_auction.dayId);
        } else {
            // transfer the day
            dayswtf.transferFrom(address(this), _auction.bidderFirst.bidder, _auction.dayId);

            // mint the past day chosen by the winner
            _mintTo(_auction.bidderFirst.past, _auction.bidderFirst.bidder, MintType.PAST);
        }

        /**
            Distribute bid
            - 60% dao
            - 16% second
            - 8% third bidder
            - 11% founders 
            - 5% charity or referral
        */
        if (_auction.bidderFirst.amount > 0) {
            if (_auction.bidderThird.bidder != address(0)) {
                // if we have at least three bidders
                _safeTransferETHWithFallback(owner(), (60 * _auction.bidderFirst.amount) / 100);
                _safeTransferETHWithFallback(_auction.bidderSecond.bidder, (16 * _auction.bidderFirst.amount) / 100);
                _safeTransferETHWithFallback(_auction.bidderThird.bidder, (8 * _auction.bidderFirst.amount) / 100);
            } else if (_auction.bidderSecond.bidder != address(0)) {
                // is we have only 2 bidders
                _safeTransferETHWithFallback(owner(), (60 * _auction.bidderFirst.amount) / 100);
                _safeTransferETHWithFallback(_auction.bidderSecond.bidder, (24 * _auction.bidderFirst.amount) / 100);
            } else {
                // if we have only one bidder he gets all 84%
                _safeTransferETHWithFallback(owner(), (84 * _auction.bidderFirst.amount) / 100);
            }

            // 11% goes to the founders
            _safeTransferETHWithFallback(dayswtf.getFoundersDAO(), (11 * _auction.bidderFirst.amount) / 100);

            // remaining 5% goes to the winner referral or chosen charity
            if (_auction.bidderFirst.referral != address(0))
                _safeTransferETHWithFallback(_auction.bidderFirst.referral, address(this).balance);
            else _safeTransferETHWithFallback(charity, address(this).balance);
        }

        emit AuctionSettled(_auction.dayId, _auction.bidderFirst.bidder, _auction.bidderFirst.amount);
    }

    /**
        @notice Mint and trasfer a day to the given address.
     */
    function _mintTo(
        uint256 _dayId,
        address _to,
        MintType _type
    ) internal returns (bool) {
        try dayswtf.mint(_dayId, _type) returns (uint256) {
            dayswtf.transferFrom(address(this), _to, _dayId);
        } catch Error(string memory) {
            _pause();
            return false;
        }
        return true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Days.WTF Auction Houses

import { IDaysWTFToken } from './IDaysWTFToken.sol';

pragma solidity ^0.8.6;

interface IDaysWTFAuctionHouse {
    struct Bid {
        address payable bidder;
        address payable referral;
        uint256 amount;
        uint256 past;
    }

    struct Auction {
        // ID for the Days.WTF (ERC721 token ID)
        uint256 dayId;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // Whether or not the auction has been settled
        bool settled;
        Bid bidderFirst;
        Bid bidderSecond;
        Bid bidderThird;
    }

    enum MintType {
        AIRDROP,
        PAST,
        TODAY
    }

    event AirdropMinted(uint256 indexed dayId, address to, uint256 level);

    event AuctionCreated(uint256 indexed dayId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed dayId, address sender, uint256 value);

    event AuctionSettled(uint256 indexed dayId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(
        uint256 dayId,
        uint256 pastDayTimestamp,
        address _referral
    ) external payable;

    function pause() external;

    function unpause() external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IDaysWTFDescriptor } from './IDaysWTFDescriptor.sol';
import { IDaysWTFAuctionHouse } from './IDaysWTFAuctionHouse.sol';

//import { INounsSeeder } from './INounsSeeder.sol';

interface IDaysWTFToken is IERC721 {
    struct DayData {
        bytes32 name;
        string url;
        string hash;
        uint256 seed;
    }

    enum DayLevel {
        NORMAL,
        MONTH,
        YEAR,
        LEAP,
        DECADE,
        CENTURY,
        MILLENNIUM
    }

    event DayDataChanged(uint256 indexed tokenId, string data, string value);

    event DayMinted(uint256 indexed tokenId);

    event DayBurned(uint256 indexed tokenId);

    event FoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IDaysWTFDescriptor descriptor);

    event DescriptorLocked();

    function getFoundersDAO() external view returns (address);

    function timestampToDayId(uint256 timestamp) external view returns (uint256);

    function stringToDayId(string memory dayString) external view returns (uint256);

    function getDayLevel(uint256 dayId) external view returns (uint256);

    function mint(uint256 _timestamp, IDaysWTFAuctionHouse.MintType _type) external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setFoundersDAO(address foundersDAO) external;

    function getDescriptor() external view returns (IDaysWTFDescriptor);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(IDaysWTFDescriptor _descriptor) external;

    function lockDescriptor() external;

    function getDayName(uint256 dayId) external view returns (string memory);

    function getDayUrl(uint256 dayId) external view returns (string memory);

    function getDayHash(uint256 dayId) external view returns (string memory);

    function getDaySeed(uint256 dayId) external view returns (uint256);

    function getDayData(uint256 dayId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256
        );

    function changeDayName(uint256 dayId, string memory newName) external;

    function changeDayUrl(uint256 dayId, string memory newUrl) external;

    function changeDayHash(uint256 dayId, string memory newHash) external;

    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Days.WTF Whitelist

pragma solidity ^0.8.6;

interface IWhitelist {
    function isFinished() external view returns (bool);

    function getReferredCount(address _account) external view returns (uint256);

    function isWhitelisted(address _account) external view returns (bool);

    function getWhitelistLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DaysWTFDescriptor

pragma solidity ^0.8.6;

import { IDaysWTFToken } from './IDaysWTFToken.sol';
import { IDaysWTFAuctionHouse } from './IDaysWTFAuctionHouse.sol';

interface IDaysWTFDescriptor {
    struct Day {
        uint16 year;
        uint8 month;
        uint8 day;
        bool negative;
    }

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IDaysWTFToken.DayData memory data) external view returns (string memory);

    function dataURI(uint256 tokenId, IDaysWTFToken.DayData memory data) external pure returns (string memory);

    function generateSVGImage(
        bytes memory _date,
        bytes memory _name,
        IDaysWTFToken.DayLevel _level,
        bytes memory _levelTxt,
        int16 _change,
        uint232 _random
    ) external pure returns (string memory);

    function isLeapYear(uint256 year) external pure returns (bool);

    function isValidDay(
        uint256 year,
        uint256 month,
        uint256 day
    ) external pure returns (bool);

    function isValidMonth(uint256 month) external pure returns (bool);

    function isValidYear(uint256 year) external pure returns (bool);

    function getDaysInYear(uint256 year) external pure returns (uint256);

    function timestampToDay(uint256 timestamp) external pure returns (Day memory);

    function timestampToDayId(uint256 timestamp) external pure returns (uint256);

    function dayToDayId(Day memory _day) external pure returns (uint256);

    function dayIdToDay(uint256 dayId) external pure returns (Day memory);

    function stringToDay(string memory date) external pure returns (Day memory);

    function stringToDayId(string memory date) external pure returns (uint256);

    function dayToString(Day memory day) external pure returns (string memory);

    function dayIdToString(uint256 dayId) external pure returns (string memory);

    function getDayLevel(Day memory day) external pure returns (IDaysWTFToken.DayLevel);

    function getDayLevel(uint256 dayId) external pure returns (IDaysWTFToken.DayLevel);

    function dayLevelToBytes(IDaysWTFToken.DayLevel level) external pure returns (bytes memory);

    function getSeed(uint256 dayId, IDaysWTFAuctionHouse.MintType _type) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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