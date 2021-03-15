//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../access/Operatable.sol";
import "../time/Debouncable.sol";
import "../time/Timeboundable.sol";
import "../SyntheticToken.sol";
import "../interfaces/IEmissionManager.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IBondManager.sol";
import "../interfaces/IBoardroom.sol";

/// Emission manager expands supply when the price goes up
contract EmissionManager is
    IEmissionManager,
    ReentrancyGuard,
    Operatable,
    Debouncable,
    Timeboundable
{
    using SafeMath for uint256;

    /// Stable fund address
    address public stableFund;
    /// Development fund address
    address public devFund;
    /// LiquidBoardroom contract
    IBoardroom public liquidBoardroom;
    /// VeBoardroom contract
    IBoardroom public veBoardroom;
    /// UniswapBoardroom contract
    IBoardroom public uniswapBoardroom;

    /// TokenManager contract
    ITokenManager public tokenManager;
    /// BondManager contract
    IBondManager public bondManager;

    /// Threshold for positive rebase
    uint256 public threshold = 105;
    /// Threshold for positive rebase
    uint256 public maxRebase = 200;
    /// Development fund allocation rate (in percentage points)
    uint256 public devFundRate = 2;
    /// Stable fund allocation rate (in percentage points)
    uint256 public stableFundRate = 69;
    /// LiquidBoardroom allocation rate (in percentage points)
    uint256 public liquidBoardroomRate = 75;
    /// VeBoardroom allocation rate (in percentage points)
    uint256 public veBoardroomRate = 0;

    /// Pauses positive rebases
    bool public pausePositiveRebase;

    /// Create new Emission manager
    /// @param startTime Start of the operations
    /// @param period The period between positive rebases
    constructor(uint256 startTime, uint256 period)
        public
        Debouncable(period)
        Timeboundable(startTime, 0)
    {}

    // --------- Modifiers ---------

    /// Checks if contract was initialized properly and ready for use
    modifier initialized() {
        require(isInitialized(), "EmissionManager: not initialized");
        _;
    }

    // --------- View ---------

    function uniswapBoardroomRate() public view returns (uint256) {
        return uint256(100).sub(veBoardroomRate).sub(liquidBoardroomRate);
    }

    /// Checks if contract was initialized properly and ready for use
    function isInitialized() public view returns (bool) {
        return
            (address(tokenManager) != address(0)) &&
            (address(bondManager) != address(0)) &&
            (address(stableFund) != address(0)) &&
            (address(devFund) != address(0)) &&
            (address(uniswapBoardroom) != address(0)) &&
            (address(liquidBoardroom) != address(0)) &&
            (stableFundRate > 0) &&
            (devFundRate > 0) &&
            (threshold > 100) &&
            (maxRebase > 100);
    }

    /// The amount for positive rebase of the synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    function positiveRebaseAmount(address syntheticTokenAddress)
        public
        view
        initialized
        returns (uint256)
    {
        uint256 oneSyntheticUnit =
            tokenManager.oneSyntheticUnit(syntheticTokenAddress);
        uint256 oneUnderlyingUnit =
            tokenManager.oneUnderlyingUnit(syntheticTokenAddress);

        uint256 rebasePriceUndPerUnitSyn =
            tokenManager.averagePrice(syntheticTokenAddress, oneSyntheticUnit);
        uint256 thresholdUndPerUnitSyn =
            threshold.mul(oneUnderlyingUnit).div(100);
        if (rebasePriceUndPerUnitSyn < thresholdUndPerUnitSyn) {
            return 0;
        }
        uint256 maxRebaseAmountUndPerUnitSyn =
            maxRebase.mul(oneUnderlyingUnit).div(100);
        rebasePriceUndPerUnitSyn = Math.min(
            rebasePriceUndPerUnitSyn,
            maxRebaseAmountUndPerUnitSyn
        );
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        uint256 supply =
            syntheticToken.totalSupply().sub(
                syntheticToken.balanceOf(address(bondManager))
            );
        return
            supply.mul(rebasePriceUndPerUnitSyn.sub(oneUnderlyingUnit)).div(
                oneUnderlyingUnit
            );
    }

    // --------- Public ---------

    /// Makes positive rebases for all eligible tokens
    function makePositiveRebase()
        public
        nonReentrant
        initialized
        debounce
        inTimeBounds
    {
        require(!pausePositiveRebase, "EmissionManager: Rebases are paused");
        address[] memory tokens = tokenManager.allTokens();
        for (uint32 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0)) {
                _makeOnePositiveRebase(tokens[i]);
            }
        }
    }

    // --------- Owner (Timelocked) ---------

    /// Set new dev fund
    /// @param _devFund New dev fund address
    function setDevFund(address _devFund) public onlyOwner {
        devFund = _devFund;
        emit DevFundChanged(msg.sender, _devFund);
    }

    /// Set new stable fund
    /// @param _stableFund New stable fund address
    function setStableFund(address _stableFund) public onlyOwner {
        stableFund = _stableFund;
        emit StableFundChanged(msg.sender, _stableFund);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setLiquidBoardroom(address _boardroom) public onlyOwner {
        liquidBoardroom = IBoardroom(_boardroom);
        emit LiquidBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setVeBoardroom(address _boardroom) public onlyOwner {
        veBoardroom = IBoardroom(_boardroom);
        emit VeBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setUniswapBoardroom(address _boardroom) public onlyOwner {
        uniswapBoardroom = IBoardroom(_boardroom);
        emit UniswapBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new TokenManager
    /// @param _tokenManager New TokenManager address
    function setTokenManager(address _tokenManager) public onlyOwner {
        tokenManager = ITokenManager(_tokenManager);
        emit TokenManagerChanged(msg.sender, _tokenManager);
    }

    /// Set new BondManager
    /// @param _bondManager New BondManager address
    function setBondManager(address _bondManager) public onlyOwner {
        bondManager = IBondManager(_bondManager);
        emit BondManagerChanged(msg.sender, _bondManager);
    }

    /// Set new dev fund rate
    /// @param _devFundRate New dev fund rate
    function setDevFundRate(uint256 _devFundRate) public onlyOwner {
        devFundRate = _devFundRate;
        emit DevFundRateChanged(msg.sender, _devFundRate);
    }

    /// Set new stable fund rate
    /// @param _stableFundRate New stable fund rate
    function setStableFundRate(uint256 _stableFundRate) public onlyOwner {
        stableFundRate = _stableFundRate;
        emit StableFundRateChanged(msg.sender, _stableFundRate);
    }

    /// Set new stable fund rate
    /// @param _veBoardroomRate New stable fund rate
    function setVeBoardroomRate(uint256 _veBoardroomRate) public onlyOwner {
        veBoardroomRate = _veBoardroomRate;
        emit VeBoardroomRateChanged(msg.sender, _veBoardroomRate);
    }

    /// Set new stable fund rate
    /// @param _liquidBoardroomRate New stable fund rate
    function setLiquidBoardroomRate(uint256 _liquidBoardroomRate)
        public
        onlyOwner
    {
        liquidBoardroomRate = _liquidBoardroomRate;
        emit LiquidBoardroomRateChanged(msg.sender, _liquidBoardroomRate);
    }

    /// Set new threshold
    /// @param _threshold New threshold
    function setThreshold(uint256 _threshold) public onlyOwner {
        threshold = _threshold;
        emit ThresholdChanged(msg.sender, _threshold);
    }

    /// Set new maxRebase
    /// @param _maxRebase New maxRebase
    function setMaxRebase(uint256 _maxRebase) public onlyOwner {
        maxRebase = _maxRebase;
        emit MaxRebaseChanged(msg.sender, _maxRebase);
    }

    // --------- Operator (immediate) ---------

    /// Pauses / unpauses positive rebases
    /// @param pause Sets the pause / unpause
    function setPausePositiveRebase(bool pause) public onlyOperator {
        pausePositiveRebase = pause;
        emit PositiveRebasePaused(msg.sender, pause);
    }

    /// Make positive rebase for one token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @dev The caller must ensure `managedToken` and `initialized` properties
    function _makeOnePositiveRebase(address syntheticTokenAddress) internal {
        tokenManager.updateOracle(syntheticTokenAddress);
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        uint256 amount = positiveRebaseAmount(syntheticTokenAddress);
        if (amount == 0) {
            return;
        }
        emit PositiveRebaseTotal(syntheticTokenAddress, amount);

        uint256 devFundAmount = amount.mul(devFundRate).div(100);
        tokenManager.mintSynthetic(
            syntheticTokenAddress,
            devFund,
            devFundAmount
        );
        emit DevFundFunded(syntheticTokenAddress, devFundAmount);
        amount = amount.sub(devFundAmount);

        uint256 stableFundAmount = amount.mul(stableFundRate).div(100);
        tokenManager.mintSynthetic(
            syntheticTokenAddress,
            stableFund,
            stableFundAmount
        );
        emit StableFundFunded(syntheticTokenAddress, stableFundAmount);
        amount = amount.sub(stableFundAmount);

        SyntheticToken bondToken =
            SyntheticToken(bondManager.bondIndex(syntheticTokenAddress));
        uint256 bondSupply = bondToken.totalSupply();
        uint256 bondPoolBalance = syntheticToken.balanceOf(address(this));
        uint256 bondShortage =
            Math.max(bondSupply, bondPoolBalance).sub(bondPoolBalance);
        uint256 bondAmount = Math.min(amount, bondShortage);
        if (bondAmount > 0) {
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(bondManager),
                bondAmount
            );
            emit BondDistributionFunded(syntheticTokenAddress, bondAmount);
        }
        amount = amount.sub(bondAmount);
        if (amount == 0) {
            return;
        }

        uint256 veBoardroomAmount = 0;
        if (veBoardroomRate > 0) {
            veBoardroomAmount = amount.mul(veBoardroomRate).div(100);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(veBoardroom),
                veBoardroomAmount
            );
            veBoardroom.notifyTransfer(
                syntheticTokenAddress,
                veBoardroomAmount
            );
            emit VeBoardroomFunded(syntheticTokenAddress, veBoardroomAmount);
        }

        uint256 liquidBoardroomAmount = 0;
        if (liquidBoardroomRate > 0) {
            liquidBoardroomAmount = amount.mul(liquidBoardroomRate).div(100);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(liquidBoardroom),
                liquidBoardroomAmount
            );
            liquidBoardroom.notifyTransfer(
                syntheticTokenAddress,
                liquidBoardroomAmount
            );
            emit LiquidBoardroomFunded(
                syntheticTokenAddress,
                liquidBoardroomAmount
            );
        }

        if (uniswapBoardroomRate() > 0) {
            uint256 uniswapBoardroomAmount =
                amount.sub(veBoardroomAmount).sub(liquidBoardroomAmount);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(uniswapBoardroom),
                uniswapBoardroomAmount
            );
            uniswapBoardroom.notifyTransfer(
                syntheticTokenAddress,
                uniswapBoardroomAmount
            );
            emit UniswapBoardroomFunded(
                syntheticTokenAddress,
                uniswapBoardroomAmount
            );
        }
    }

    event DevFundChanged(address indexed operator, address newFund);
    event StableFundChanged(address indexed operator, address newFund);
    event LiquidBoardroomChanged(address indexed operator, address newBoadroom);
    event VeBoardroomChanged(address indexed operator, address newBoadroom);
    event UniswapBoardroomChanged(
        address indexed operator,
        address newBoadroom
    );
    event TokenManagerChanged(
        address indexed operator,
        address newTokenManager
    );
    event BondManagerChanged(address indexed operator, address newBondManager);
    event PositiveRebasePaused(address indexed operator, bool pause);

    event DevFundRateChanged(address indexed operator, uint256 newRate);
    event StableFundRateChanged(address indexed operator, uint256 newRate);
    event VeBoardroomRateChanged(address indexed operator, uint256 newRate);
    event LiquidBoardroomRateChanged(address indexed operator, uint256 newRate);
    event ThresholdChanged(address indexed operator, uint256 newThreshold);
    event MaxRebaseChanged(address indexed operator, uint256 newThreshold);
    event PositiveRebaseTotal(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event BondDistributionFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event LiquidBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event VeBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event UniswapBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event DevFundFunded(address indexed syntheticTokenAddress, uint256 amount);
    event StableFundFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// Introduces `Operator` role that can be changed only by Owner.
abstract contract Operatable is Ownable {
    address public operator;

    constructor() internal {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this method");
        _;
    }

    /// Set new operator
    /// @param newOperator New operator to be set
    /// @dev Only owner is allowed to call this method.
    function transferOperator(address newOperator) public onlyOwner {
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Provides modifier for debouncing call to methods,
/// i.e. method cannot be called more earlier than debouncePeriod
/// since the last call
abstract contract Debouncable {
    /// Debounce period in secs
    uint256 public immutable debouncePeriod;
    /// Last time method successfully called (block timestamp)
    uint256 public lastCalled;

    /// @param _debouncePeriod Debounce period in secs
    constructor(uint256 _debouncePeriod) internal {
        debouncePeriod = _debouncePeriod;
    }

    /// Throws if the method was called earlier than debouncePeriod last time.
    modifier debounce() {
        uint256 timeElapsed = block.timestamp - lastCalled;
        require(
            timeElapsed >= debouncePeriod,
            "Debouncable: already called in this time slot"
        );
        _;
        lastCalled = block.timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Checks time bounds for contract
abstract contract Timeboundable {
    uint256 public immutable start;
    uint256 public immutable finish;

    /// @param _start The block timestamp to start from (in secs). Use 0 for unbounded start.
    /// @param _finish The block timestamp to finish in (in secs). Use 0 for unbounded finish.
    constructor(uint256 _start, uint256 _finish) internal {
        require(
            (_start != 0) || (_finish != 0),
            "Timebound: either start or finish must be nonzero"
        );
        require(
            (_finish == 0) || (_finish > _start),
            "Timebound: finish must be zero or greater than start"
        );
        uint256 s = _start;
        if (s == 0) {
            s = block.timestamp;
        }
        uint256 f = _finish;
        if (f == 0) {
            f = uint256(-1);
        }
        start = s;
        finish = f;
    }

    /// Checks if timebounds are satisfied
    modifier inTimeBounds() {
        require(block.timestamp >= start, "Timeboundable: Not started yet");
        require(block.timestamp <= finish, "Timeboundable: Already finished");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./access/Operatable.sol";

/// @title Synthetic token for the Klondike platform
contract SyntheticToken is ERC20Burnable, Operatable {
    /// Creates a new synthetic token
    /// @param _name Name of the token
    /// @param _symbol Ticker for the token
    /// @param _decimals Number of decimals
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    ///  Mints tokens to the recepient
    ///  @param recipient The address of recipient
    ///  @param amount The amount of tokens to mint
    function mint(address recipient, uint256 amount)
        public
        onlyOperator
        returns (bool)
    {
        _mint(recipient, amount);
    }

    ///  Burns token from the caller
    ///  @param amount The amount of tokens to burn
    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    ///  Burns token from address
    ///  @param account The account to burn from
    ///  @param amount The amount of tokens to burn
    ///  @dev The allowance for sender in address account must be
    ///  strictly >= amount. Otherwise the function call will fail.
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Emission manager as seen by other managers
interface IEmissionManager {

}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./ISmelter.sol";

/// Token manager as seen by other managers
interface ITokenManager is ISmelter {
    /// A set of synthetic tokens under management
    /// @dev Deleted tokens are still present in the array but with address(0)
    function allTokens() external view returns (address[] memory);

    /// Checks if the token is managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return True if token is managed
    function isManagedToken(address syntheticTokenAddress)
        external
        view
        returns (bool);

    /// Address of the underlying token
    /// @param syntheticTokenAddress The address of the synthetic token
    function underlyingToken(address syntheticTokenAddress)
        external
        view
        returns (address);

    /// Average price of the synthetic token according to price oracle
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount (average)
    /// @dev Fails if the token is not managed
    function averagePrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Current price of the synthetic token according to Uniswap
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount
    /// @dev Fails if the token is not managed
    function currentPrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Updates Oracle for the synthetic asset
    /// @param syntheticTokenAddress The address of the synthetic token
    function updateOracle(address syntheticTokenAddress) external;

    /// Get one synthetic unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the synthetic asset
    function oneSyntheticUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);

    /// Get one underlying unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the underlying asset
    function oneUnderlyingUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// Bond manager as seen by other managers
interface IBondManager {
    /// Called when new token is added in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param bondTokenAddress The address of the bond token
    function addBondToken(
        address syntheticTokenAddress,
        address bondTokenAddress
    ) external;

    /// Called when token is deleted in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param newOperator New operator for the bond token
    function deleteBondToken(address syntheticTokenAddress, address newOperator)
        external;

    function bondIndex(address syntheticTokenAddress)
        external
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Boardroom as seen by others
interface IBoardroom {
    /// Notify Boardroom about new incoming reward for token
    /// @param token Rewards denominated in this token
    /// @param amount The amount of rewards
    function notifyTransfer(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Smelter can mint and burn tokens
interface ISmelter {
    /// Burn SyntheticToken
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param owner Owner of the tokens to burn
    /// @param amount Amount to burn
    function burnSyntheticFrom(
        address syntheticTokenAddress,
        address owner,
        uint256 amount
    ) external;

    /// Mints synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param receiver Address to receive minted token
    /// @param amount Amount to mint
    function mintSynthetic(
        address syntheticTokenAddress,
        address receiver,
        uint256 amount
    ) external;

    /// Check if address is token admin
    /// @param admin - address to check
    function isTokenAdmin(address admin) external view returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}