// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./CappedTokenSoldCrowdsaleHelper.sol";
import "./LaunchpadWhitelistCrowdsaleHelper.sol";
import "./NoDeliveryCrowdsale.sol";
import "./TimedCrowdsaleHelper.sol";
import "./VestedCrowdsale.sol";
import "./interfaces/ILaunchpadCrowdsaleWithVesting.sol";

/**
 * @title LaunchpadCrowdsaleWithVesting
 * @author Enjinstarter
 * @dev Launchpad crowdsale where there is no delivery of tokens in each purchase.
 */
contract LaunchpadCrowdsaleWithVesting is
    VestedCrowdsale,
    CappedTokenSoldCrowdsaleHelper,
    TimedCrowdsaleHelper,
    LaunchpadWhitelistCrowdsaleHelper,
    Pausable,
    ILaunchpadCrowdsaleWithVesting
{
    using SafeMath for uint256;

    struct LaunchpadCrowdsaleInfo {
        uint256 tokenCap;
        address vestingContract;
        address whitelistContract;
    }

    address public governanceAccount;
    address public crowdsaleAdmin;

    // max 1 lot
    constructor(
        address wallet_,
        address tokenSelling_,
        LaunchpadCrowdsaleInfo memory crowdsaleInfo,
        LotsInfo memory lotsInfo,
        Timeframe memory timeframe,
        PaymentTokenInfo[] memory paymentTokensInfo
    )
        Crowdsale(wallet_, tokenSelling_, lotsInfo, paymentTokensInfo)
        VestedCrowdsale(crowdsaleInfo.vestingContract)
        CappedTokenSoldCrowdsaleHelper(crowdsaleInfo.tokenCap)
        TimedCrowdsaleHelper(timeframe)
        LaunchpadWhitelistCrowdsaleHelper(crowdsaleInfo.whitelistContract)
    {
        governanceAccount = msg.sender;
        crowdsaleAdmin = msg.sender;
    }

    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "LaunchpadCrowdsaleWithVesting: sender unauthorized"
        );
        _;
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     */
    function buyTokens(address paymentToken, uint256 lots) external override {
        _buyTokensFor(msg.sender, paymentToken, lots, "");
    }

    /**
     * @param beneficiary Recipient of the token purchase
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     */
    function buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots
    ) external override {
        _buyTokensFor(beneficiary, paymentToken, lots, "");
    }

    /**
     * @return availableLots Available number of lots for beneficiary
     */
    function getAvailableLotsFor(address beneficiary)
        external
        view
        override
        returns (uint256 availableLots)
    {
        if (!whitelisted(beneficiary)) {
            return 0;
        }

        availableLots = _getAvailableTokensFor(beneficiary).div(
            getBeneficiaryCap(beneficiary)
        );
    }

    /**
     * @return remainingTokens Remaining number of tokens for crowdsale
     */
    function getRemainingTokens()
        external
        view
        override
        returns (uint256 remainingTokens)
    {
        remainingTokens = tokenCap().sub(tokensSold);
    }

    function pause() external override onlyBy(crowdsaleAdmin) {
        _pause();
    }

    function unpause() external override onlyBy(crowdsaleAdmin) {
        _unpause();
    }

    function extendTime(uint256 newClosingTime)
        external
        override
        onlyBy(crowdsaleAdmin)
    {
        _extendTime(newClosingTime);
    }

    function startDistribution(uint256 scheduleStartTimestamp)
        external
        override
        onlyBy(crowdsaleAdmin)
    {
        require(
            scheduleStartTimestamp > closingTime(),
            "LaunchpadCrowdsaleWithVesting: must be after closing time"
        );
        _startDistribution(scheduleStartTimestamp);
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadCrowdsaleWithVesting: zero account"
        );

        governanceAccount = account;
    }

    function setCrowdsaleAdmin(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadCrowdsaleWithVesting: zero account"
        );

        crowdsaleAdmin = account;
    }

    /**
     * @param beneficiary Address receiving the tokens
     * @return lotSize_ lot size of token being sold
     */
    function _lotSize(address beneficiary)
        internal
        view
        override
        returns (uint256 lotSize_)
    {
        lotSize_ = getBeneficiaryCap(beneficiary);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @param beneficiary Address receiving the tokens
     * @return tokenAmount Number of tokens that will be purchased
     */
    function _getTokenAmount(uint256 lots, address beneficiary)
        internal
        view
        override
        returns (uint256 tokenAmount)
    {
        tokenAmount = lots.mul(_lotSize(beneficiary));
    }

    /**
     * @param beneficiary Token beneficiary
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount of wei contributed
     * @param tokenAmount Number of tokens to be purchased
     */
    function _preValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    )
        internal
        view
        override
        whenNotPaused
        onlyWhileOpen
        tokenCapNotExceeded(tokensSold, tokenAmount)
        isWhitelisted(beneficiary)
    {
        // TODO: Investigate why modifier and require() don't work consistently for beneficiaryCapNotExceeded()
        if (
            getTokensPurchasedBy(beneficiary).add(tokenAmount) >
            getBeneficiaryCap(beneficiary)
        ) {
            revert("LaunchpadCrowdsaleWithVesting: beneficiary cap exceeded");
        }

        super._preValidatePurchase(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );
    }

    /**
     * @dev Extend parent behavior to update purchased amount of tokens by beneficiary.
     * @param beneficiary Token purchaser
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _updatePurchasingState(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal override {
        super._updatePurchasingState(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );

        _updateBeneficiaryTokensPurchased(beneficiary, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title CappedTokenSoldCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale with a limit for total tokens sold.
 */
contract CappedTokenSoldCrowdsaleHelper {
    using SafeMath for uint256;

    uint256 private _tokenCap;

    /**
     * @param tokenCap_ Max amount of tokens to be sold
     */
    constructor(uint256 tokenCap_) {
        require(tokenCap_ > 0, "CappedTokenSoldHelper: zero cap");
        _tokenCap = tokenCap_;
    }

    modifier tokenCapNotExceeded(uint256 tokensSold, uint256 tokenAmount) {
        require(
            tokensSold.add(tokenAmount) <= _tokenCap,
            "CappedTokenSoldHelper: cap exceeded"
        );
        _;
    }

    /**
     * @return tokenCap_ the token cap of the crowdsale.
     */
    function tokenCap() public view returns (uint256 tokenCap_) {
        tokenCap_ = _tokenCap;
    }

    /**
     * @dev Checks whether the token cap has been reached.
     * @return tokenCapReached_ Whether the token cap was reached
     */
    function tokenCapReached(uint256 tokensSold)
        external
        view
        returns (bool tokenCapReached_)
    {
        tokenCapReached_ = (tokensSold >= _tokenCap);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILaunchpadWhitelist.sol";

/**
 * @title LaunchpadWhitelistCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale in which only whitelisted users can contribute.
 */
contract LaunchpadWhitelistCrowdsaleHelper {
    using SafeMath for uint256;

    address public whitelistContract;

    mapping(address => uint256) private _tokensPurchased;

    /**
     * @param whitelistContract_ whitelist contract address
     */
    constructor(address whitelistContract_) {
        require(
            whitelistContract_ != address(0),
            "LaunchpadWhitelistCrowdsaleHelper: zero whitelist address"
        );

        whitelistContract = whitelistContract_;
    }

    // TODO: Investigate why modifier and require() don't work consistently for beneficiaryCapNotExceeded()
    /*
    modifier beneficiaryCapNotExceeded(
        address beneficiary,
        uint256 tokenAmount
    ) {
        require(
            _tokensPurchased[beneficiary].add(tokenAmount) <=
                ILaunchpadWhitelist(whitelistContract).whitelistedAmountFor(
                    beneficiary
                ),
            "LaunchpadWhitelistCrowdsaleHelper: beneficiary cap exceeded"
        );
        _;
    }
    */

    modifier isWhitelisted(address account) {
        require(
            ILaunchpadWhitelist(whitelistContract).isWhitelisted(account),
            "LaunchpadWhitelistCrowdsaleHelper: account not whitelisted"
        );
        _;
    }

    /**
     * @return tokenCap Cap for beneficiary in wei
     */
    function getBeneficiaryCap(address beneficiary)
        public
        view
        returns (uint256 tokenCap)
    {
        require(
            beneficiary != address(0),
            "LaunchpadWhitelistCrowdsaleHelper: zero beneficiary address"
        );

        tokenCap = ILaunchpadWhitelist(whitelistContract).whitelistedAmountFor(
            beneficiary
        );
    }

    /**
     * @dev Returns the amount of tokens purchased so far by specific beneficiary.
     * @param beneficiary Address of contributor
     * @return tokensPurchased Tokens purchased by beneficiary so far in wei
     */
    function getTokensPurchasedBy(address beneficiary)
        public
        view
        returns (uint256 tokensPurchased)
    {
        require(
            beneficiary != address(0),
            "LaunchpadWhitelistCrowdsaleHelper: zero beneficiary address"
        );

        tokensPurchased = _tokensPurchased[beneficiary];
    }

    function whitelisted(address account)
        public
        view
        returns (bool whitelisted_)
    {
        require(
            account != address(0),
            "LaunchpadWhitelistCrowdsaleHelper: zero account"
        );

        whitelisted_ = ILaunchpadWhitelist(whitelistContract).isWhitelisted(
            account
        );
    }

    /**
     * @param beneficiary Address of contributor
     * @param tokenAmount Amount in wei of token being purchased
     */
    function _updateBeneficiaryTokensPurchased(
        address beneficiary,
        uint256 tokenAmount
    ) internal {
        _tokensPurchased[beneficiary] = _tokensPurchased[beneficiary].add(
            tokenAmount
        );
    }

    /**
     * @return availableTokens Available number of tokens for purchase by beneficiary
     */
    function _getAvailableTokensFor(address beneficiary)
        internal
        view
        returns (uint256 availableTokens)
    {
        availableTokens = getBeneficiaryCap(beneficiary).sub(
            getTokensPurchasedBy(beneficiary)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./Crowdsale.sol";

/**
 * @title NoDeliveryCrowdsale
 * @author Enjinstarter
 * @dev Extension of Crowdsale contract where purchased tokens are not delivered.
 */
abstract contract NoDeliveryCrowdsale is Crowdsale {
    /**
     * @dev Overrides delivery by not delivering tokens upon purchase.
     */
    function _deliverTokens(address, uint256) internal pure override {
        return;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title TimedCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsaleHelper {
    using SafeMath for uint256;

    struct Timeframe {
        uint256 openingTime;
        uint256 closingTime;
    }

    Timeframe private _timeframe;

    /**
     * Event for crowdsale extending
     * @param prevClosingTime old closing time
     * @param newClosingTime new closing time
     */
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() {
        require(isOpen(), "TimedCrowdsaleHelper: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param timeframe Crowdsale opening and closing times
     */
    constructor(Timeframe memory timeframe) {
        require(
            timeframe.openingTime >= block.timestamp,
            "TimedCrowdsaleHelper: opening time is before current time"
        );
        require(
            timeframe.closingTime > timeframe.openingTime,
            "TimedCrowdsaleHelper: closing time is before opening time"
        );

        _timeframe.openingTime = timeframe.openingTime;
        _timeframe.closingTime = timeframe.closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() external view returns (uint256) {
        return _timeframe.openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _timeframe.closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return
            block.timestamp >= _timeframe.openingTime &&
            block.timestamp <= _timeframe.closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > _timeframe.closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsaleHelper: already closed");
        uint256 oldClosingTime = _timeframe.closingTime;
        require(
            newClosingTime > oldClosingTime,
            "TimedCrowdsaleHelper: before current closing time"
        );

        _timeframe.closingTime = newClosingTime;

        emit TimedCrowdsaleExtended(oldClosingTime, newClosingTime);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./Crowdsale.sol";
import "./interfaces/IVesting.sol";

/**
 * @title VestedCrowdsale
 * @author Enjinstarter
 * @dev Extension of Crowdsale contract where purchased tokens are transferred to a vesting schedule.
 */
abstract contract VestedCrowdsale is Crowdsale {
    address public vestingContract;

    constructor(address vestingContract_) {
        require(
            vestingContract_ != address(0),
            "VestedCrowdsale: zero vesting address"
        );

        vestingContract = vestingContract_;
    }

    function _startDistribution(uint256 scheduleStartTimestamp) internal {
        IVesting(vestingContract).setScheduleStartTimestamp(
            scheduleStartTimestamp
        );
    }

    /**
     * @dev Overrides delivery by transferring tokens to vesting schedule upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be vested
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount)
        internal
        override
    {
        IVesting(vestingContract).addVestingGrant(
            beneficiary,
            tokenAmount,
            true
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./ICrowdsale.sol";

/**
 * @title ILaunchpadCrowdsaleWithVesting
 * @author Enjinstarter
 */
interface ILaunchpadCrowdsaleWithVesting is ICrowdsale {
    function buyTokens(address paymentToken, uint256 lots) external;

    function buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots
    ) external;

    function getAvailableLotsFor(address beneficiary)
        external
        view
        returns (uint256 availableLots);

    function getRemainingTokens()
        external
        view
        returns (uint256 remainingTokens);

    function pause() external;

    function unpause() external;

    function extendTime(uint256 newClosingTime) external;

    function startDistribution(uint256 scheduleStartTimestamp) external;

    function setGovernanceAccount(address account) external;

    function setCrowdsaleAdmin(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title ILaunchpadWhitelist
 * @author Enjinstarter
 */
interface ILaunchpadWhitelist {
    function addWhitelisted(address account, uint256 amount) external;

    function removeWhitelisted(address account) external;

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;

    function removeWhitelistedBatch(address[] memory accounts) external;

    function setGovernanceAccount(address account) external;

    function setWhitelistAdmin(address account) external;

    function isWhitelisted(address account)
        external
        view
        returns (bool isWhitelisted_);

    function whitelistedAmountFor(address account)
        external
        view
        returns (uint256 whitelistedAmount);

    event WhitelistedAdded(address indexed account, uint256 amount);
    event WhitelistedRemoved(address indexed account);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICrowdsale.sol";

/**
 * @title Crowdsale
 * @author Enjinstarter
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ERC20 tokens. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard, ICrowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_NUM_PAYMENT_TOKENS = 10;
    uint256 public constant TOKEN_MAX_DECIMALS = 18;
    uint256 public constant TOKEN_SELLING_SCALE = 10**TOKEN_MAX_DECIMALS;

    // Amount of tokens sold
    uint256 public tokensSold;

    // The token being sold
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    address private _tokenSelling;

    // Lot size and maximum number of lots for token being sold
    LotsInfo private _lotsInfo;

    // Payment tokens
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    address[] private _paymentTokens;

    // Payment token decimals
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    mapping(address => uint256) private _paymentDecimals;

    // Indicates whether ERC20 token is acceptable for payment
    mapping(address => bool) private _isPaymentTokens;

    // Address where funds are collected
    address private _wallet;

    // How many weis one token costs for each ERC20 payment token
    mapping(address => uint256) private _rates;

    // Amount of wei raised for each payment token
    mapping(address => uint256) private _weiRaised;

    /**
     * @dev Rates will denote how many weis one token costs for each ERC20 payment token.
     * For USDC or USDT payment token which has 6 decimals, minimum rate will
     * be 1000000000000 which will correspond to a price of USD0.000001 per token.
     * @param wallet_ Address where collected funds will be forwarded to
     * @param tokenSelling_ Address of the token being sold
     * @param lotsInfo Lot size and maximum number of lots for token being sold
     * @param paymentTokensInfo Addresses, decimals, rates and lot sizes of ERC20 tokens acceptable for payment
     */
    constructor(
        address wallet_,
        address tokenSelling_,
        LotsInfo memory lotsInfo,
        PaymentTokenInfo[] memory paymentTokensInfo
    ) {
        require(wallet_ != address(0), "Crowdsale: zero wallet address");
        require(
            tokenSelling_ != address(0),
            "Crowdsale: zero token selling address"
        );
        require(lotsInfo.lotSize > 0, "Crowdsale: zero lot size");
        require(lotsInfo.maxLots > 0, "Crowdsale: zero max lots");
        require(paymentTokensInfo.length > 0, "Crowdsale: zero payment tokens");
        require(
            paymentTokensInfo.length < MAX_NUM_PAYMENT_TOKENS,
            "Crowdsale: exceed max payment tokens"
        );

        _wallet = wallet_;
        _tokenSelling = tokenSelling_;
        _lotsInfo = lotsInfo;

        for (uint256 i = 0; i < paymentTokensInfo.length; i++) {
            uint256 paymentDecimal = paymentTokensInfo[i].paymentDecimal;
            require(
                paymentDecimal <= TOKEN_MAX_DECIMALS,
                "Crowdsale: decimals exceed 18"
            );
            address paymentToken = paymentTokensInfo[i].paymentToken;
            require(
                paymentToken != address(0),
                "Crowdsale: zero payment token address"
            );
            uint256 rate_ = paymentTokensInfo[i].rate;
            require(rate_ > 0, "Crowdsale: zero rate");

            _isPaymentTokens[paymentToken] = true;
            _paymentTokens.push(paymentToken);
            _paymentDecimals[paymentToken] = paymentDecimal;
            _rates[paymentToken] = rate_;
        }
    }

    /**
     * @return tokenSelling_ the token being sold
     */
    function tokenSelling()
        external
        view
        override
        returns (address tokenSelling_)
    {
        tokenSelling_ = _tokenSelling;
    }

    /**
     * @return wallet_ the address where funds are collected
     */
    function wallet() external view override returns (address wallet_) {
        wallet_ = _wallet;
    }

    /**
     * @return paymentTokens_ the payment tokens
     */
    function paymentTokens()
        external
        view
        override
        returns (address[] memory paymentTokens_)
    {
        paymentTokens_ = _paymentTokens;
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return rate_ how many weis one token costs for specified ERC20 payment token
     */
    function rate(address paymentToken)
        external
        view
        override
        returns (uint256 rate_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        rate_ = _rate(paymentToken);
    }

    /**
     * @param beneficiary Address performing the token purchase
     * @return lotSize_ lot size of token being sold
     */
    function lotSize(address beneficiary)
        public
        view
        override
        returns (uint256 lotSize_)
    {
        require(
            beneficiary != address(0),
            "Crowdsale: zero beneficiary address"
        );

        lotSize_ = _lotSize(beneficiary);
    }

    /**
     * @return maxLots_ maximum number of lots for token being sold
     */
    function maxLots() external view override returns (uint256 maxLots_) {
        maxLots_ = _lotsInfo.maxLots;
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return weiRaised_ the amount of wei raised
     */
    function weiRaisedFor(address paymentToken)
        external
        view
        override
        returns (uint256 weiRaised_)
    {
        weiRaised_ = _weiRaisedFor(paymentToken);
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return isPaymentToken_ whether token is accepted for payment
     */
    function isPaymentToken(address paymentToken)
        public
        view
        override
        returns (bool isPaymentToken_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );

        isPaymentToken_ = _isPaymentTokens[paymentToken];
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @param beneficiary Address receiving the tokens
     * @return tokenAmount Number of tokens being sold that will be purchased
     */
    function getTokenAmount(uint256 lots, address beneficiary)
        external
        view
        override
        returns (uint256 tokenAmount)
    {
        require(lots > 0, "Crowdsale: zero lots");
        require(
            beneficiary != address(0),
            "Crowdsale: zero beneficiary address"
        );

        tokenAmount = _getTokenAmount(lots, beneficiary);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     * @param beneficiary Address receiving the tokens
     * @return weiAmount Amount in wei of ERC20 payment token
     */
    function getWeiAmount(
        address paymentToken,
        uint256 lots,
        address beneficiary
    ) external view override returns (uint256 weiAmount) {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(lots > 0, "Crowdsale: zero lots");
        require(
            beneficiary != address(0),
            "Crowdsale: zero beneficiary address"
        );
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        weiAmount = _getWeiAmount(paymentToken, lots, beneficiary);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     * @param nonEthAddress Recipient address on non ETH blockchain
     */
    function _buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots,
        string memory nonEthAddress
    ) internal nonReentrant {
        require(
            beneficiary != address(0),
            "Crowdsale: zero beneficiary address"
        );
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(lots > 0, "Crowdsale: zero lots");
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        // calculate token amount to be created
        uint256 tokenAmount = _getTokenAmount(lots, beneficiary);
        // calculate wei amount to transfer to wallet
        uint256 weiAmount = _getWeiAmount(paymentToken, lots, beneficiary);

        _preValidatePurchase(beneficiary, paymentToken, weiAmount, tokenAmount);

        // update state
        _weiRaised[paymentToken] = _weiRaised[paymentToken].add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        _updatePurchasingState(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );

        emit TokensPurchased(
            msg.sender,
            beneficiary,
            paymentToken,
            lots,
            weiAmount,
            tokenAmount,
            nonEthAddress
        );

        _processPurchase(beneficiary, tokenAmount);
        _forwardFunds(paymentToken, weiAmount);
        _postValidatePurchase(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return weiRaised_ the amount of wei raised
     */
    function _weiRaisedFor(address paymentToken)
        internal
        view
        virtual
        returns (uint256 weiRaised_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        weiRaised_ = _weiRaised[paymentToken];
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return rate_ how many weis one token costs for specified ERC20 payment token
     */
    function _rate(address paymentToken)
        internal
        view
        virtual
        returns (uint256 rate_)
    {
        rate_ = _rates[paymentToken];
    }

    /**
     * @return lotSize_ lot size of token being sold
     */
    function _lotSize(address)
        internal
        view
        virtual
        returns (uint256 lotSize_)
    {
        lotSize_ = _lotsInfo.lotSize;
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _preValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo/rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _postValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _deliverTokens(address beneficiary, uint256 tokenAmount)
        internal
        virtual
    {
        // TODO: support decimals for token selling
        // uint256 transferAmount = scaleWeiToDecimals(tokenAmount, _tokenSellingDecimals);
        // IERC20(_tokenSelling).safeTransfer(beneficiary, transferAmount);
        IERC20(_tokenSelling).safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
        virtual
    {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _updatePurchasingState(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @return tokenAmount Number of tokens that will be purchased
     */
    function _getTokenAmount(uint256 lots, address)
        internal
        view
        virtual
        returns (uint256 tokenAmount)
    {
        tokenAmount = lots.mul(_lotsInfo.lotSize).mul(TOKEN_SELLING_SCALE);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     * @param beneficiary Address receiving the tokens
     * @return weiAmount Amount in wei of ERC20 payment token
     */
    function _getWeiAmount(
        address paymentToken,
        uint256 lots,
        address beneficiary
    ) internal view virtual returns (uint256 weiAmount) {
        uint256 rate_ = _rate(paymentToken);
        uint256 tokenAmount = _getTokenAmount(lots, beneficiary);
        weiAmount = tokenAmount.mul(rate_).div(TOKEN_SELLING_SCALE);
    }

    /**
     * @dev Determines how ERC20 payment token is stored/forwarded on purchases.
     */
    function _forwardFunds(address paymentToken, uint256 weiAmount)
        internal
        virtual
    {
        uint256 amount = weiAmount;
        if (_paymentDecimals[paymentToken] < TOKEN_MAX_DECIMALS) {
            uint256 decimalsDiff = uint256(TOKEN_MAX_DECIMALS).sub(
                _paymentDecimals[paymentToken]
            );
            amount = weiAmount.div(10**decimalsDiff);
        }

        IERC20(paymentToken).safeTransferFrom(msg.sender, _wallet, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICrowdsale
 * @author Enjinstarter
 */
interface ICrowdsale {
    struct LotsInfo {
        uint256 lotSize;
        uint256 maxLots;
    }

    struct PaymentTokenInfo {
        address paymentToken;
        uint256 paymentDecimal;
        uint256 rate;
    }

    function tokenSelling() external view returns (address tokenSelling_);

    function wallet() external view returns (address wallet_);

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function rate(address paymentToken) external view returns (uint256 rate_);

    function lotSize(address beneficiary)
        external
        view
        returns (uint256 lotSize_);

    function maxLots() external view returns (uint256 maxLots_);

    function weiRaisedFor(address paymentToken)
        external
        view
        returns (uint256 weiRaised_);

    function isPaymentToken(address paymentToken)
        external
        view
        returns (bool isPaymentToken_);

    function getTokenAmount(uint256 lots, address beneficiary)
        external
        view
        returns (uint256 tokenAmount);

    function getWeiAmount(
        address paymentToken,
        uint256 lots,
        address beneficiary
    ) external view returns (uint256 weiAmount);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param paymentToken address of ERC20 token used for payment
     * @param lots number of lots to purchase
     * @param weiAmount weis paid for purchase
     * @param tokenAmount amount of tokens purchased
     * @param nonEthAddress recipient address on non ETH blockchain
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        address indexed paymentToken,
        uint256 lots,
        uint256 weiAmount,
        uint256 tokenAmount,
        string nonEthAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title IVesting
 * @author Enjinstarter
 */
interface IVesting {
    enum ReleaseMethod {
        IntervalEnd, // 0: at end of each interval
        LinearlyPerSecond //  1: linearly per second across interval
    }

    function addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) external;

    function revokeVestingGrant(address account) external;

    function release() external;

    function transferUnusedTokens() external;

    function addVestingGrantsBatch(
        address[] memory accounts,
        uint256[] memory grantAmounts,
        bool[] memory isRevocables
    ) external;

    function revokeVestingGrantsBatch(address[] memory accounts) external;

    function setScheduleStartTimestamp(uint256 scheduleStartTimestamp_)
        external;

    function setGovernanceAccount(address account) external;

    function setVestingAdmin(address account) external;

    function getVestingSchedule()
        external
        view
        returns (
            uint256 cliffDurationDays,
            uint256 percentReleaseAtGrantStart,
            uint256 percentReleaseAtIntervalStart,
            uint256 intervalDays,
            uint256 gapDays,
            uint256 numberOfIntervals,
            ReleaseMethod releaseMethod
        );

    function vestingGrantFor(address account)
        external
        view
        returns (
            uint256 grantAmount,
            bool isRevocable,
            bool isRevoked,
            bool isActive
        );

    function revoked(address account) external view returns (bool isRevoked);

    function releasedAmountFor(address account)
        external
        view
        returns (uint256 releasedAmount);

    function releasableAmountFor(address account)
        external
        view
        returns (uint256 unreleasedAmount);

    function vestedAmountFor(address account)
        external
        view
        returns (uint256 vestedAmount);

    function unvestedAmountFor(address account)
        external
        view
        returns (uint256 unvestedAmount);

    event VestingGrantAdded(
        address indexed account,
        uint256 indexed grantAmount,
        bool isRevocable
    );
    event VestingGrantRevoked(
        address indexed account,
        uint256 remainderAmount,
        uint256 grantAmount,
        uint256 releasedAmount
    );
    event TokensReleased(address indexed account, uint256 amount);
    event ScheduleStartTimestampSet(
        address indexed account,
        uint256 newScheduleStartTimestamp,
        uint256 oldScheduleStartTimestamp
    );
}