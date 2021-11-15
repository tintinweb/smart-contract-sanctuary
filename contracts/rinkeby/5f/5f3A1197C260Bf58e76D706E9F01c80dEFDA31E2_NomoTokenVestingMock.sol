// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ITokenVesting.sol";

contract NomoTokenVestingMock is ITokenVesting, Ownable {
    using SafeERC20 for IERC20;

    /* ========== TYPES  ========== */

    /**
     * totalSupply : total supply allocated to the round
     * supplyLeft : available supply that can be assigned to investor
     * price : price of token (ex: 0.12$ = 0.12 * 100 = 12)
     * initialReleasePercent : percent to tokens which will be given at the tge
     * cliffPeriod : duration of cliff period
     * cliffEndTime : time at which cliff ends
     * vestingPeriod : duration of individual vesting
     * noOfVestings : total no of vesting to give
     */
    struct RoundInfo {
        uint256 totalSupply;
        uint256 supplyLeft;
        uint256 price;
        uint256 initialReleasePercent;
        uint256 cliffPeriod;
        uint256 cliffEndTime;
        uint256 vestingPeriod;
        uint256 noOfVestings;
    }

    /**
     * totalAssigned : total tokens assigned to the investor
     * vestingTokens : no of tokens to give at each vesting
     * vestingsClaimed : total no off vesting which will be given
     * initialClaimReleased : tell tokens released at the tge are received or not
     */
    struct Investor {
        uint256 totalAssigned;
        uint256 vestingTokens;
        uint256 vestingsClaimed;
        bool initialClaimReleased;
    }

    /**
     * beneficiary : address of account which be be able to claim tokens
     */
    struct TeamInfo {
        address beneficiary;
        uint256 cliffPeriod;
        uint256 cliffEndTime;
        uint256 vestingPeriod;
        uint256 noOfVestings;
        uint256 totalSupply;
        uint256 initialReleasePercent;
        uint256 vestingsClaimed;
        uint256 vestingTokens;
        bool initialClaimReleased;
    }

    /* ========== STATE VARIABLES  ========== */

    mapping(RoundType => RoundInfo) public roundInfo;
    mapping(RoundType => mapping(address => Investor)) public investorInfo;
    mapping(RoundType => address[]) internal investors;

    uint256 public startTime;
    IERC20 public nomoToken;

    /* ========== CONSTANTS ========== */

    /*
     * 100% = 100 * 100 (MULTIPLIER)
     * all value which are in percent are multiplied with MULTIPLIER(100) to handle precision up to 2 places
     */
    uint256 private constant PERCENTAGE_MULTIPLIER = 10000;

    /**
        365 days in 1 year
        1 month = 30 days + 10 hours,
        12 months = 360 days + 120 hours = 365 days
        4 months = 120 days + 40 hours;
        6 months = 180 days + 60 hours;
        9 months = 270 days + 90 hours;
    */

    /**
        supply : 100.0%
        initial release : 0%
        cliff: 5 minutes,
        vesting schedule : vest each 5 minutes for 7 days
        no of vestings : 2016 vests for 7 days (each 5 minutes)
     */
    uint256 private constant SUPPLY_PERCENT = 10000;
    uint256 private constant PRICE = 1e18;
    uint256 private constant INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant CLIFF_PERIOD = 5 minutes;
    uint256 private constant VESTING_PERIOD = 5 minutes;
    uint256 private constant NO_OF_VESTINGS = 2016;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev all the details are hard coded
     */
    constructor(IERC20 _nomoToken, uint256 _startAfter) public {
        require(_startAfter > 0, "Invalid startTime");

        uint256 _startTime = block.timestamp + _startAfter;

        nomoToken = _nomoToken;
        startTime = _startTime;
        uint256 nomoTotalSupply = _nomoToken.totalSupply();

        _addRound(
            RoundType.MAIN,
            nomoTotalSupply,
            PRICE,
            INITIAL_RELEASE_PERCENT,
            CLIFF_PERIOD,
            VESTING_PERIOD,
            NO_OF_VESTINGS,
            _startTime
        );
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /**
     * @notice update start time
     * @param _startAfter time after which u want to start (cant be 0);
     * @dev can only be updated before the start
     */
    function updateStartTime(uint256 _startAfter) external override {
        require(_startAfter > 0, "Invalid startTime");
        require(block.timestamp < startTime, "Already started");

        uint256 _startTime = block.timestamp + _startAfter;

        _massUpdateCliffEndTime(_startTime);

        startTime = _startTime;
    }

    /**
     * @notice add, update or remove single investor
     * @param _amount for how much amount (in $) has investor invested. ex  100$ = 100 * 100 = 100,00
     * @dev to remove make amount 0 before it starts
     * @dev you can add, updated and remove any time
     */
    function addOrUpdateInvestor(
        RoundType _roundType,
        address _investor,
        uint256 _amount
    ) external override {
        _addInvestor(_roundType, _investor, _amount);

        emit InvestorAdded(_roundType, _investor, _amount);
    }

    /**
     * @notice add, update or remove multiples investors
     */
    function addOrUpdateInvestors(
        RoundType _roundType,
        address[] memory _investors,
        uint256[] memory _amount
    ) external override {
        uint256 length = _investors.length;

        require(_amount.length == length, "Arguments length not match");

        for (uint256 i = 0; i < length; i++) {
            _addInvestor(_roundType, _investors[i], _amount[i]);
        }

        emit InvestorsAdded(_roundType, _investors, _amount);
    }

    /**
     * @notice recover any erc20 token (ex - nomo token)
     */
    function recoverToken(address _token, uint256 amount) external override {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }

    /* ========== Investor FUNCTIONS ========== */

    /**
     * @notice claim unlocked tokens (only investor)
     * @param _roundType Id of the round from which u want to withdraw tokens
     */
    function claimInvestorUnlockedTokens(RoundType _roundType) external override onlyInvestor(_roundType) started() {
        RoundInfo memory round = roundInfo[_roundType];
        Investor memory investor = investorInfo[_roundType][_msgSender()];

        require(investor.vestingsClaimed < round.noOfVestings, "Already claimed all vesting");

        uint256 unlockedTokens;

        if (block.timestamp >= round.cliffEndTime) {
            uint256 claimableVestingLeft;
            (unlockedTokens, claimableVestingLeft) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);

            investorInfo[_roundType][_msgSender()].vestingsClaimed = investor.vestingsClaimed + claimableVestingLeft;
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
            investorInfo[_roundType][_msgSender()].initialClaimReleased = true;
        }

        require(unlockedTokens > 0, "No unlocked tokens available");

        nomoToken.safeTransfer(_msgSender(), unlockedTokens);
        emit InvestorTokensClaimed(_roundType, _msgSender(), unlockedTokens);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    /**
     * @param _totalSupply : total supply of nomo token for this round
     * @param _price : price of nomo token in $
     * @param _initialReleasePercent : tokens to be released at token generation event
     * @param _cliffPeriod : time user have to wait after start to get his/her first vesting
     * @param _vestingPeriod : duration of single vesting (in secs)
     * @param _noOfVestings : total no of vesting will be given
     */
    function _addRound(
        RoundType _roundType,
        uint256 _totalSupply,
        uint256 _price,
        uint256 _initialReleasePercent,
        uint256 _cliffPeriod,
        uint256 _vestingPeriod,
        uint256 _noOfVestings,
        uint256 _startTime
    ) private {
        RoundInfo memory newRoundInfo;

        newRoundInfo.price = _price;
        newRoundInfo.totalSupply = _totalSupply;
        newRoundInfo.supplyLeft = _totalSupply;
        newRoundInfo.initialReleasePercent = _initialReleasePercent;
        newRoundInfo.cliffPeriod = _cliffPeriod;
        newRoundInfo.vestingPeriod = _vestingPeriod;
        newRoundInfo.noOfVestings = _noOfVestings;
        newRoundInfo.cliffEndTime = _startTime + _cliffPeriod;

        roundInfo[_roundType] = newRoundInfo;
    }

    function _massUpdateCliffEndTime(uint256 _startTime) private {
        roundInfo[RoundType.MAIN].cliffEndTime = _startTime + roundInfo[RoundType.MAIN].cliffPeriod;
    }

    function _addInvestor(
        RoundType _roundType,
        address _investorAddress,
        uint256 _amount
    ) private {
        require(_investorAddress != address(0), "Invalid address");

        RoundInfo memory round = roundInfo[_roundType];
        Investor storage investor = investorInfo[_roundType][_investorAddress];
        uint256 totalAssigned = (_amount * 1e18) / round.price;

        require(round.supplyLeft >= totalAssigned, "Insufficient supply");

        if (investor.totalAssigned == 0) {
            investors[_roundType].push(_investorAddress);
            roundInfo[_roundType].supplyLeft = round.supplyLeft - totalAssigned;
        } else {
            roundInfo[_roundType].supplyLeft = round.supplyLeft + investor.totalAssigned - totalAssigned;
        }
        investor.totalAssigned = totalAssigned;
        investor.vestingTokens =
            (totalAssigned - ((totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER)) /
            round.noOfVestings;
    }

    /**
     * @notice Calculate the total vesting claimable vesting left for investor
     * @dev will only run in case if cliff period ends and investor have unclaimed vesting left
     */
    function _getInvestorUnlockedTokensAndVestingLeft(RoundInfo memory _round, Investor memory _investor)
        private
        view
        returns (uint256, uint256)
    {
        uint256 totalClaimableVesting = ((block.timestamp - _round.cliffEndTime) / _round.vestingPeriod) + 1;

        uint256 claimableVestingLeft = totalClaimableVesting > _round.noOfVestings
            ? _round.noOfVestings - _investor.vestingsClaimed
            : totalClaimableVesting - _investor.vestingsClaimed;

        uint256 unlockedTokens = _investor.vestingTokens * claimableVestingLeft;

        return (unlockedTokens, claimableVestingLeft);
    }

    /* ========== VIEWS ========== */

    function getInvestorUnlockedTokensAndVestingLeft(RoundType _roundType, address _investor)
        public
        view
        returns (uint256 unlockedTokens, uint256 claimableVestingLeft)
    {
        RoundInfo memory round = roundInfo[_roundType];
        Investor memory investor = investorInfo[_roundType][_investor];
        (unlockedTokens, claimableVestingLeft) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);
    }

    /**
     * @return amount of unlockToken which are currently unclaimed for a investor
     */
    function getInvestorClaimableTokens(RoundType _roundType, address _investor)
        external
        view
        override
        returns (uint256)
    {
        RoundInfo memory round = roundInfo[_roundType];
        Investor memory investor = investorInfo[_roundType][_investor];

        if (startTime == 0 || block.timestamp < startTime || investor.vestingsClaimed == round.noOfVestings) return 0;

        uint256 unlockedTokens;
        if (block.timestamp >= round.cliffEndTime) {
            (unlockedTokens, ) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
        }

        return unlockedTokens;
    }

    /**
     * @return array containing investors of a particular round
     * filter in frontend ot get all the investor (totalAssigned != 0)
     */
    function getInvestors(RoundType _roundType) external view override returns (address[] memory) {
        return investors[_roundType];
    }

    function getInvestorTotalAssigned(RoundType _roundType, address _investor) external view returns (uint256) {
        return investorInfo[_roundType][_investor].totalAssigned;
    }

    function getInvestorVestingTokens(RoundType _roundType, address _investor) external view returns (uint256) {
        return investorInfo[_roundType][_investor].vestingTokens;
    }

    function getInvestorVestingsClaimed(RoundType _roundType, address _investor) external view returns (uint256) {
        return investorInfo[_roundType][_investor].vestingsClaimed;
    }

    function getInvestorTokensInContract(RoundType _roundType, address _investor) external view returns (uint256) {
        return
            investorInfo[_roundType][_investor].totalAssigned -
            (investorInfo[_roundType][_investor].vestingTokens * investorInfo[_roundType][_investor].vestingsClaimed);
    }

    /* ========== MODIFIERS ========== */

    modifier started() {
        require(block.timestamp > startTime, "Not started yet");
        _;
    }

    modifier onlyInvestor(RoundType _roundType) {
        require(investorInfo[_roundType][_msgSender()].totalAssigned > 0, "Caller is not a investor");
        _;
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity 0.6.12;

interface ITokenVesting {
    /* ========== TYPES ========== */

    enum RoundType {
        MAIN
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function updateStartTime(uint256 _startAfter) external;

    function addOrUpdateInvestor(
        RoundType _roundType,
        address _investor,
        uint256 _amount
    ) external;

    function addOrUpdateInvestors(
        RoundType _roundType,
        address[] calldata _investor,
        uint256[] calldata _amount
    ) external;

    function recoverToken(address _token, uint256 amount) external;

    /* ========== INVESTOR FUNCTION ========== */

    function claimInvestorUnlockedTokens(RoundType _roundType) external;

    /* ========== VIEWS ========== */

    function getInvestorClaimableTokens(RoundType _roundType, address _investor) external view returns (uint256);

    function getInvestors(RoundType _roundType) external view returns (address[] memory);

    /* ========== EVENTS ========== */

    event InvestorsAdded(RoundType roundType, address[] investors, uint256[] amount);

    event InvestorAdded(RoundType indexed roundType, address investors, uint256 amount);

    event InvestorTokensClaimed(RoundType indexed roundType, address indexed investor, uint256 amount);

    event RecoverToken(address indexed token, uint256 indexed amount);
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

