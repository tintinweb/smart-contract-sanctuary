// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IAaveGovernanceV2.sol";
import "./interfaces/IStakedAave.sol";
import "./interfaces/ILdoAave.sol";
import "./libraries/LSTokenGovPowerSnapshot.sol";
import "./FeeDistributor.sol";

/**
 * @title Lido Liquid Staked AAVE
 * @author 0x_larry <[email protected]>
 *
 * Simplified AAVE staking solution where the user is alleviated from the burden of having
 * to manually claim and reinvest staking rewards by himself, while retaining the liquid
 * character of the native stkAAVE token.
 */
contract LdoAave is
    Initializable,
    OwnableUpgradeable,
    LSTokenGovPowerSnapshot,
    FeeDistributor,
    ILdoAave
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public aave;
    IStakedAave public stkAave;
    IAaveGovernanceV2 public aaveGovernance;

    uint256 public feeRate;
    bool public adminVotingRelinquished;

    uint256 internal _savedFee;

    //------------------------------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------------------------------

    function initialize(
        address _aave,
        address _stkAave,
        address _aaveGovernance,
        address _priceFeed,
        address _lidoAgent,
        address _delphiAgent,
        uint256 _feeRate,
        string memory name,
        string memory symbol
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __LSTokenGovPowerSnapshot_init(name, symbol, 18);
        __FeeDistributor_init(_aave, _priceFeed, _lidoAgent, _delphiAgent);

        aave = IERC20Upgradeable(_aave);
        stkAave = IStakedAave(_stkAave);
        aaveGovernance = IAaveGovernanceV2(_aaveGovernance);

        feeRate = _feeRate;
        adminVotingRelinquished = false;

        _savedFee = 0;

        // Approve Aave staking contract to spend infinite amount of AAVE
        aave.safeApprove(address(stkAave), uint256(-1));
    }

    //------------------------------------------------------------------------------------
    // External functions: for users
    //------------------------------------------------------------------------------------

    function stake(uint256 amount) external override {
        require(amount > 0, "Amount must be greater then zero");

        uint256 shares = _getSharesByUnderlying(amount);

        aave.safeTransferFrom(msg.sender, address(this), amount);
        stkAave.stake(address(this), amount);

        _mintShares(msg.sender, shares);

        emit Staked(msg.sender, shares, amount);
    }

    function cooldown() external override {
        stkAave.cooldown();
    }

    /**
     * @dev This function takes the amount of shares to burn as the argument. However,
     * most users may find it more intuitive to put in an amount of tokens, instead of
     * shares. The conversion from the amount of tokens to shares can be performed by the
     * frontend.
     */
    function redeem(uint256 shares) external override {
        require(shares > 0, "Shares must be greater than zero");
        require(shares <= shareOf(msg.sender), "Cannot burn more than what you have");

        uint256 amount = _getUnderlyingByShares(shares);
        uint256 amountStaked = _getStaked();
        uint256 amountToRedeem = amount > amountStaked ? amountStaked : amount;
        uint256 amountToClaim = amount > amountToRedeem ? amount.sub(amountToRedeem) : 0;

        _savedFee = _savedFee.add(_calculateFee(amountToClaim));

        stkAave.redeem(msg.sender, amountToRedeem);

        if (amountToClaim > 0) {
            stkAave.claimRewards(msg.sender, amountToClaim);
        }

        _burnShares(msg.sender, shares);

        emit Redeemed(msg.sender, shares, amount);
    }

    //------------------------------------------------------------------------------------
    // External functions: management
    //------------------------------------------------------------------------------------

    /**
     * @dev Claimed reward and restake
     */
    function harvest() external override {
        (uint256 rewardsAfterFee, uint256 fee) = _getRewardsBreakdown();

        _savedFee = 0;
        _incrementFees(fee);

        stkAave.claimRewards(address(this), type(uint256).max);
        stkAave.stake(address(this), rewardsAfterFee);

        _writeTotalStakedSnapshot();

        emit Harvested(rewardsAfterFee, fee);
    }

    /**
     * @dev Get a breakdown of the current claimable rewards.
     * @return rewardsAfterFee The portion of rewards that is to be restaked
     * @return fee The portion of rewards that is going to be charged as fee and splitted
     * between Lido DAO and the developer (e.g. Delphi Labs)
     */
    function getRewardsBreakdown() external view override returns (uint256, uint256) {
        return _getRewardsBreakdown();
    }

    //------------------------------------------------------------------------------------
    // External functions: governance
    //------------------------------------------------------------------------------------

    /**
     * @dev Set the rate of fee charged on staking rewards claimed
     * @param _feeRate The new rate in basis points, e.g. 50 indicated 0.5%
     */
    function setFeeRate(uint256 _feeRate) external override onlyOwner {
        feeRate = _feeRate;
    }

    /**
     * @dev Admin vote on behalf of all stakers
     * Note: In the long term it is planned to get ldoAAVE accepted as a voting token in
     * Aave governance, so that stakers can vote on their own behalf. Before this happens,
     * the admin needs to have relinquished his power to execute this function.
     * @param proposalId The ID of the proposal to vote on
     * @param support `true` = vote for, `false` = vote against
     */
    function adminVote(uint256 proposalId, bool support) external override onlyOwner {
        require(!adminVotingRelinquished, "Admin has relinquish voting power");

        aaveGovernance.submitVote(proposalId, support);
    }

    /**
     * @dev For the admin to relinquish his power to vote on behalf of stakers. Once
     * executed, he won't be able to call `adminVote` anymore.
     */
    function adminRelinquish() external override onlyOwner {
        adminVotingRelinquished = true;
    }

    //------------------------------------------------------------------------------------
    // Internal functions: overrides
    //------------------------------------------------------------------------------------

    /**
     * @dev The total amount of underlying asset is the sum of staked AAVE and claimable
     * rewards.
     */
    function _getTotalUnderlying() internal view override returns (uint256) {
        (uint256 rewardsAfterFee, ) = _getRewardsBreakdown();

        return _getStaked().add(rewardsAfterFee);
    }

    /**
     * @dev Returns the total amount of AAVE token staked in governance.
     */
    function _getStaked() internal view override returns (uint256) {
        return stkAave.balanceOf(address(this));
    }

    //------------------------------------------------------------------------------------
    // Private functions
    //------------------------------------------------------------------------------------

    function _getRewardsBreakdown()
        private
        view
        returns (uint256 rewardsAfterFee, uint256 fee)
    {
        uint256 rewards = stkAave.getTotalRewardsBalance(address(this));
        uint256 unsavedFee = _calculateFee(rewards);

        fee = unsavedFee.add(_savedFee);
        rewardsAfterFee = rewards.sub(fee);
    }

    function _calculateFee(uint256 profit) private view returns (uint256) {
        return profit.mul(feeRate).div(10000);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

/**
 * @dev Forked from
 * https://github.com/aave/governance-v2/blob/master/contracts/interfaces/IAaveGovernanceV2.sol
 */
interface IAaveGovernanceV2 {
    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Forked from
 * https://github.com/aave/aave-stake-v2/blob/master/contracts/interfaces/IStakedAave.sol
 */
interface IStakedAave is IERC20 {
    function stake(address onBehalfOf, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface ILdoAave {
    //------------------------------------------------------------------------------------
    // External functions: for users
    //------------------------------------------------------------------------------------

    function stake(uint256 amount) external;

    function cooldown() external;

    function redeem(uint256 amount) external;

    //------------------------------------------------------------------------------------
    // External functions: management
    //------------------------------------------------------------------------------------

    function harvest() external;

    function getRewardsBreakdown() external view returns (uint256, uint256);

    //------------------------------------------------------------------------------------
    // External functions: governance
    //------------------------------------------------------------------------------------

    function setFeeRate(uint256 _feeRate) external;

    function adminVote(uint256 proposalId, bool support) external;

    function adminRelinquish() external;

    //------------------------------------------------------------------------------------
    // Events
    //------------------------------------------------------------------------------------

    event Staked(address account, uint256 shares, uint256 amount);
    event Redeemed(address account, uint256 shares, uint256 amount);
    event Harvested(uint256 amountAfterFee, uint256 fee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./LSToken.sol";
import "../interfaces/IGovernancePowerDelegationToken.sol";

/**
 * @title LSTokenGovPowerSnapshot
 * @author 0x_larry <[email protected]>
 *
 * Liquid Staking Token including snapshots of governance power on transfer-related actions.
 * Exposes an external function `getPowerAtBlock` for querying voting power of each token
 * holder at specific past blocks. This conforms to Aave's `IGovernancePowerDelegationToken`
 * interface and is required for a token to be used as a voting token in AAVE governance.
 *
 * Specifically, three sets of snapshots are recorded:
 * - totalStaked: updated upon `_mint`, `_burn` (and `harvest`, if present)
 * - totalShares: updated upon `_mint` and `_burn`
 * - userShares: updated upon `_mint`, `_burn`, and `_transfer`
 *
 * At any block, the user's voting power is pro rate share of the whole pool's power, i.e.
 * userVotingPower = totalStaked * userShares[account] / totalShares
 *
 * Each token inherits this contract needs to implement `_getStaked` function, in addition
 * to `_getTotalUnderlying` as required by the base `LSToken`.
 *
 * Modified from:
 * https://github.com/aave/aave-stake-v2/blob/master/contracts/lib/ERC20WithSnapshot.sol
 * and
 * https://github.com/aave/aave-token-v2/blob/master/contracts/token/base/GovernancePowerDelegationERC20.sol
 */
abstract contract LSTokenGovPowerSnapshot is
    Initializable,
    LSToken,
    IGovernancePowerDelegationToken
{
    using SafeMathUpgradeable for uint256;

    struct Snapshot {
        uint256 blockNumber;
        uint256 value;
    }

    mapping(uint256 => Snapshot) private totalStakedSnapshots;
    uint256 private totalStakedCount;

    mapping(uint256 => Snapshot) private totalSharesSnapshots;
    uint256 private totalSharesCount;

    mapping(address => mapping(uint256 => Snapshot)) private userSharesSnapshots;
    mapping(address => uint256) private userSharesCount;

    // TODO: reserve some storage spaces for implementing delegation!

    //------------------------------------------------------------------------------------
    // Initializer
    //------------------------------------------------------------------------------------

    function __LSTokenGovPowerSnapshot_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        __LSToken_init(_name, _symbol, _decimals);
    }

    //------------------------------------------------------------------------------------
    // External functions
    //------------------------------------------------------------------------------------

    /**
     * @dev Returns the delegated power of a user at a certain block
     * @param user Address of the user
     * @param blockNumber Block number at which the user's power is to be queried
     * @param delegationType At the time this parameter makes no difference, as we have
     * not yet implemented delegation
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view override returns (uint256) {
        require(
            delegationType == DelegationType.VOTING_POWER ||
                delegationType == DelegationType.PROPOSITION_POWER,
            "Invalid delegation type"
        );

        uint256 totalStaked =
            totalStakedCount > 0
                ? _searchByBlockNumber(
                    totalStakedSnapshots,
                    totalStakedCount,
                    blockNumber
                )
                : _getStaked();

        uint256 totalShares =
            totalSharesCount > 0
                ? _searchByBlockNumber(
                    totalSharesSnapshots,
                    totalSharesCount,
                    blockNumber
                )
                : _totalShares;

        uint256 userShares =
            userSharesCount[user] > 0
                ? _searchByBlockNumber(
                    userSharesSnapshots[user],
                    userSharesCount[user],
                    blockNumber
                )
                : _shares[user];

        if (totalStaked == 0 || totalShares == 0 || userShares == 0) {
            return 0;
        } else {
            return totalStaked.mul(userShares).div(totalShares);
        }
    }

    //------------------------------------------------------------------------------------
    // Internal functions
    //------------------------------------------------------------------------------------

    /**
     * @dev Performs a binary search among a group of snapshots
     * @param snapshots Mapping where the snapshots are indexed by block numbers
     * @param snapshotCount The number of snapshots in the given mapping
     * @param blockNumber The block number being searched
     */
    function _searchByBlockNumber(
        mapping(uint256 => Snapshot) storage snapshots,
        uint256 snapshotCount,
        uint256 blockNumber
    ) internal view returns (uint256) {
        require(blockNumber <= block.number, "Invalid block number");

        // If there's no snapshot at all, or if the queried block number is earlier the
        // even the first snapshot, then return 0
        if (snapshotCount == 0 || snapshots[0].blockNumber > blockNumber) {
            return 0;
        }

        // If there's no change since the latest snapshot, then return the latest value
        if (snapshots[snapshotCount.sub(1)].blockNumber <= blockNumber) {
            return snapshots[snapshotCount.sub(1)].value;
        }

        // Otherwise, do binary search
        uint256 lower = 0;
        uint256 upper = snapshotCount.sub(1);

        while (upper > lower) {
            uint256 center = upper.sub(upper.sub(lower).div(2));
            Snapshot memory snapshot = snapshots[center];

            if (snapshot.blockNumber == blockNumber) {
                return snapshot.value;
            } else if (snapshot.blockNumber < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        return snapshots[lower].value;
    }

    /**
     * @dev Writes a snapshot after any operation involving transfer of value.
     * Specifically, `_transfer`, `_mint`, `_burn`, and `harvest`.
     */
    function _afterTokenTransfer(address from, address to) internal override {
        if (from == to) return;

        if (from == address(0) || to == address(0)) {
            _writeTotalStakedSnapshot();
            _writeTotalSharesSnapshot();
        }

        if (from != address(0)) {
            _writeUserSharesSnapshot(from);
        }

        if (to != address(0)) {
            _writeUserSharesSnapshot(to);
        }
    }

    /**
     * @dev Write a snapshot for the total amount of staked Aave at the current block.
     */
    function _writeTotalStakedSnapshot() internal {
        uint256 currentBlock = block.number;

        if (
            totalStakedCount > 0 &&
            totalStakedSnapshots[totalStakedCount.sub(1)].blockNumber == currentBlock
        ) {
            totalStakedSnapshots[totalStakedCount.sub(1)].value = _getStaked();
        } else {
            totalStakedSnapshots[totalStakedCount] = Snapshot(currentBlock, _getStaked());
            totalStakedCount = totalStakedCount.add(1);
        }
    }

    /**
     * @dev Write a snapshot of the total shares at the current block.
     */
    function _writeTotalSharesSnapshot() internal {
        uint256 currentBlock = block.number;

        if (
            totalSharesCount > 0 &&
            totalSharesSnapshots[totalSharesCount.sub(1)].blockNumber == currentBlock
        ) {
            totalSharesSnapshots[totalSharesCount.sub(1)].value = _totalShares;
        } else {
            totalSharesSnapshots[totalSharesCount] = Snapshot(currentBlock, _totalShares);
            totalSharesCount = totalSharesCount.add(1);
        }
    }

    /**
     * @dev Write a snapshot of a user's shares at the current block.
     * @param user Address of the user
     */
    function _writeUserSharesSnapshot(address user) internal {
        uint256 currentBlock = block.number;

        uint256 _count = userSharesCount[user];
        mapping(uint256 => Snapshot) storage _snapshots = userSharesSnapshots[user];

        if (_count > 0 && _snapshots[_count.sub(1)].blockNumber == currentBlock) {
            _snapshots[_count.sub(1)].value = _shares[user];
        } else {
            _snapshots[_count] = Snapshot(currentBlock, _shares[user]);
            userSharesCount[user] = _count.add(1);
        }
    }

    /**
     * @dev returns the current total staked amount
     */
    function _getStaked() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IFeeDistributor.sol";

/**
 * @title FeeDistributor
 * @author 0x_larry <[email protected]>
 *
 * This contract implements the agreements between Lido and Delphi Labs regarding the
 * split of fees generated by the Aave Liquid Staking protocol.
 *
 * Specifically, the following rules are implemented:
 *
 * - 30% of fees generated by the Product shall be paid to an address provided by the
 *   Analyst until such total fees equal $1,000,000 then;
 * - 20% of fees generated by the Product shall be paid to an address provided by the
 *   Analyst until such total fee equal $2,500,000 then;
 * - 10% of fees generated by the Product shall be paid to an address provided by the
 *   Analyst for all fee amounts in excess of $2,500,000
 * - This tiered payment structure shall reset on each the anniversary of the Product
 *   launch date.
 *
 * Since the thresholds are denomited in USD, we use the Chainlink oracle to fetch USD
 * price of the AAVE token.
 */
abstract contract FeeDistributor is Initializable, IFeeDistributor {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public feeToken;
    AggregatorV3Interface public priceFeed;

    address public lidoAgent;
    address public delphiAgent;

    uint256 public totalFeeUsd;
    uint256 public lastResetTimestamp;

    uint256 public collectibleFeeLido;
    uint256 public collectibleFeeDelphi;

    //------------------------------------------------------------------------------------
    // Initializer
    //------------------------------------------------------------------------------------

    /**
     * @param _priceFeed Address of the token price oracle
     * @param _lidoAgent Address owned by Lido where the fee shall be distributed
     * @param _delphiAgent Address owned by Delphi where the fee shall be distributed
     */
    function __FeeDistributor_init(
        address _feeToken,
        address _priceFeed,
        address _lidoAgent,
        address _delphiAgent
    ) internal initializer {
        feeToken = IERC20Upgradeable(_feeToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
        lidoAgent = _lidoAgent;
        delphiAgent = _delphiAgent;

        _resetTotalFee();
        _resetcollectibleFee();
    }

    //------------------------------------------------------------------------------------
    // External functions
    //------------------------------------------------------------------------------------

    function distributeFees() external override {
        feeToken.safeTransfer(lidoAgent, collectibleFeeLido);
        feeToken.safeTransfer(delphiAgent, collectibleFeeDelphi);

        _resetcollectibleFee();
    }

    function setDelphiAgent(address _delphiAgent) external override {
        require(msg.sender == delphiAgent, "Only Delphi can call");

        delphiAgent = _delphiAgent;
    }

    //------------------------------------------------------------------------------------
    // Internal functions
    //------------------------------------------------------------------------------------

    function _incrementFees(uint256 fee) internal {
        uint256 aavePriceUsd = _getAavePriceUsd();
        uint256 feeUsd = _aaveToUsd(fee, aavePriceUsd);

        uint256 feeToDelphi = _usdToAave(_calculateFeeSplit(feeUsd), aavePriceUsd);
        uint256 feeToLido = fee.sub(feeToDelphi);

        collectibleFeeLido = collectibleFeeLido.add(feeToLido);
        collectibleFeeDelphi = collectibleFeeDelphi.add(feeToDelphi);

        totalFeeUsd = totalFeeUsd.add(feeUsd);
    }

    //------------------------------------------------------------------------------------
    // Private functions
    //------------------------------------------------------------------------------------

    /**
     * @dev Calculate the portion of fee that shall be sent to Delphi according to the
     * agreement.
     * @param feeUsd The amount of fee generated by a restake event
     * @return The portion of fee that shall be sent to Delphi
     */
    function _calculateFeeSplit(uint256 feeUsd) private view returns (uint256) {
        uint256 _totalFeeUsd =
            block.timestamp.sub(lastResetTimestamp) > 365 days ? 0 : totalFeeUsd;

        uint256 newTotalFeeUsd = _totalFeeUsd.add(feeUsd);

        // The portion of fee that is subject to 30% split
        uint256 bracket1 =
            _totalFeeUsd < 1_000_000e8
                ? _min(newTotalFeeUsd, 1_000_000e8).sub(_totalFeeUsd)
                : 0;

        // The portion of fee that is subject to 20% split
        uint256 bracket2 =
            _totalFeeUsd < 2_500_000e8 && newTotalFeeUsd > 1_000_000e8
                ? _min(newTotalFeeUsd, 2_500_000e8).sub(_max(_totalFeeUsd, 1_000_000e8))
                : 0;

        // The portion of fee that is subject to 10% split
        uint256 bracket3 =
            newTotalFeeUsd > 2_500_000e8
                ? newTotalFeeUsd.sub(_max(_totalFeeUsd, 2_500_000e8))
                : 0;

        return bracket3.add(bracket2.mul(2)).add(bracket1.mul(3)).div(10);
    }

    function _resetTotalFee() private {
        if (
            lastResetTimestamp == 0 || block.timestamp.sub(lastResetTimestamp) > 365 days
        ) {
            totalFeeUsd = 0;
            lastResetTimestamp = block.timestamp;
        }
    }

    function _resetcollectibleFee() private {
        collectibleFeeLido = 0;
        collectibleFeeDelphi = 0;
    }

    function _getAavePriceUsd() private view returns (uint256) {
        (, int256 aavePriceUsd, , , ) = priceFeed.latestRoundData();
        return uint256(aavePriceUsd);
    }

    function _aaveToUsd(uint256 amountAave, uint256 aavePriceUsd)
        private
        pure
        returns (uint256 amountUsd)
    {
        amountUsd = amountAave.mul(aavePriceUsd).div(1e18);
    }

    function _usdToAave(uint256 amountUsd, uint256 aavePriceUsd)
        private
        pure
        returns (uint256 amountAave)
    {
        amountAave = amountUsd.mul(1e18).div(aavePriceUsd);
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../interfaces/ILSToken.sol";

/**
 * @title LiquidStakingToken (LSToken)
 * @author 0x_larry <[email protected]>
 *
 * ERC-20 token whose total supply reflects the amount of asset under management (NAV),
 * with each account's balance representing the account's share of the NAV.
 *
 * To be inherited by specific implementations of Lido Liquid Staking tokens, e.g. ldoAAVE
 * or ldoSNX.
 *
 * Each token inherits this contract needs to implement `_getTotalUnderlying` and optionally
 * `_afterTokenTransfer` functions.
 *
 * Refer to EIP-20 for the specification of each public function:
 * https://eips.ethereum.org/EIPS/eip-20
 */
abstract contract LSToken is Initializable, ILSToken {
    using SafeMathUpgradeable for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 internal _totalShares;
    mapping(address => uint256) internal _shares;
    mapping(address => mapping(address => uint256)) internal _allowances;

    //------------------------------------------------------------------------------------
    // Initializer
    //------------------------------------------------------------------------------------

    function __LSToken_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    //------------------------------------------------------------------------------------
    // Public functions: Read
    //------------------------------------------------------------------------------------

    function totalSupply() public view override returns (uint256) {
        return _getTotalUnderlying();
    }

    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }

    function shareOf(address account) public view override returns (uint256) {
        return _shares[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _getUnderlyingByShares(_shares[account]);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    //------------------------------------------------------------------------------------
    // Public functions: Write
    //------------------------------------------------------------------------------------

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transferShares(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][to];

        require(currentAllowance >= amount, "Transfer amount exceeds allowance!");

        _transferShares(from, to, amount);
        _approve(from, to, currentAllowance.sub(amount));

        return true;
    }

    //------------------------------------------------------------------------------------
    // Internal functions
    //------------------------------------------------------------------------------------

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transferShares(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");

        uint256 shares = _getSharesByUnderlying(amount);

        _shares[from] = _shares[from].sub(shares, "Transfer amount exceeds balance!");
        _shares[to] = _shares[to].add(shares);

        _afterTokenTransfer(from, to);

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Mint the user an amount of tokens corresponding to `_shares`.
     */
    function _mintShares(address to, uint256 shares) internal {
        require(to != address(0), "Cannot mint to zero address");

        _shares[to] = _shares[to].add(shares);
        _totalShares = _totalShares.add(shares);

        _afterTokenTransfer(address(0), to);

        emit Transfer(address(0), to, _getUnderlyingByShares(shares));
    }

    /**
     * @notice Burn an amount of tokens corresponding to `_shares` from the
     * user's account.
     */
    function _burnShares(address from, uint256 shares) internal {
        require(from != address(0), "Cannot burn from zero address");

        uint256 amount = _getUnderlyingByShares(shares);

        _shares[from] = _shares[from].sub(shares, "Burn amount exceeds balance!");
        _totalShares = _totalShares.sub(shares);

        _afterTokenTransfer(from, address(0));

        emit Transfer(from, address(0), amount);
    }

    /**
     * @notice Returns the amount of underlying asset represented a specificied
     * amount of shares.
     */
    function _getUnderlyingByShares(uint256 shares) internal view returns (uint256) {
        if (_totalShares == 0) {
            return shares; // by default, 1 share = 1 unit of the underlying asset
        } else {
            return _getTotalUnderlying().mul(shares).div(_totalShares);
        }
    }

    /**
     * @notice Returns the amount of shares represented by a specified amount of
     * underlying asset.
     */
    function _getSharesByUnderlying(uint256 amount) internal view returns (uint256) {
        uint256 totalUnderlying = _getTotalUnderlying();

        if (totalUnderlying == 0) {
            return amount;
        } else {
            return _totalShares.mul(amount).div(totalUnderlying);
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens, including minting and burning.
     */
    function _afterTokenTransfer(address from, address to) internal virtual {}

    /**
     * @dev Returns the total amount of underlying asset under management.
     */
    function _getTotalUnderlying() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

/**
 * @dev A token needs to conform to this interface in order to be used as a voting token
 * in Aave governance V2.
 *
 * Modified from
 * https://github.com/aave/governance-v2/blob/master/contracts/interfaces/IGovernancePowerDelegationToken.sol
 */
interface IGovernancePowerDelegationToken {
    enum DelegationType {VOTING_POWER, PROPOSITION_POWER}

    /**
     * @dev get the power of a user at a specified block
     * @param user address of the user
     * @param blockNumber block number at which to get power
     * @param delegationType delegation type (propose/vote)
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILSToken is IERC20 {
    function totalShares() external view returns (uint256);

    function shareOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IFeeDistributor {
    event FeeWithdrawn(uint256 toLido, uint256 toDelphi);

    function distributeFees() external;

    function setDelphiAgent(address _delphiAgent) external;
}

