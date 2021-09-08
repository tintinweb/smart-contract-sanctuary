/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

//  MIT

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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol

//  MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol

//  MIT

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

//  MIT

pragma solidity >=0.6.0 <0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol

//  MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

//  MIT

pragma solidity ^0.7.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/interfaces/IRewardChest.sol

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

interface IRewardChest {
    function addToBalance(address _user, uint256 _amount)
        external
        returns (bool);

    function sendInstantClaim(address _user, uint256 _amount)
        external
        returns (bool);

    function owner() external view returns (address);
}

// File: contracts/interfaces/IXGTFreezer.sol

//  AGPL-3.0
pragma solidity 0.7.6;

interface IXGTFreezer {
    function freeze(uint256 _amount) external;

    function freezeFor(address _recipient, uint256 _amount) external;

    function thaw() external;
}

// File: contracts/rewards/StakingModule.sol

//  AGPL-3.0
pragma solidity 0.7.6;

contract StakingModule is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct UserInfo {
        uint256 shares;
        uint256 deposits;
        uint256 lastDepositedTime;
        uint256 lastUserActionTime;
    }

    IERC20 public xgt;
    IXGTFreezer public freezer;
    IRewardChest public rewardChest;

    mapping(address => bool) public authorized;
    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    uint256 public autoHarvestAfter;

    uint256 public constant YEAR_IN_SECONDS = 31536000;
    uint256 public constant BP_DECIMALS = 10000;

    uint256 public performanceFee;
    uint256 public callFee;
    uint256 public withdrawFee;
    uint256 public withdrawFeePeriod;
    uint256 public stakingAPY;

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(
        address indexed sender,
        uint256 performanceFee,
        uint256 callFee
    );

    function initialize(
        address _xgt,
        address _freezer,
        address _rewardChest
    ) public initializer {
        xgt = IERC20(_xgt);
        freezer = IXGTFreezer(_freezer);
        xgt.approve(_freezer, 2**256 - 1);
        rewardChest = IRewardChest(_rewardChest);

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        transferOwnership(rewardChest.owner());

        performanceFee = 200; // 2%
        callFee = 25; // 0.25%
        withdrawFee = 10; // 0.1%
        withdrawFeePeriod = 72 hours;
        stakingAPY = 9500; // 95% base APY, with compounding effect this is 150%
        autoHarvestAfter = 1 hours;
    }
    
    function resetFreezerAllowance() external onlyOwner {
        xgt.approve(address(freezer), 2**256 - 1);
    }

    function setAuthorized(address _addr, bool _authorized) external onlyOwner {
        authorized[_addr] = _authorized;
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
    }

    function setCallFee(uint256 _callFee) external onlyOwner {
        callFee = _callFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod)
        external
        onlyOwner
    {
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    function setStakingAPY(uint256 _stakingAPY) external onlyOwner {
        stakingAPY = _stakingAPY;
    }

    function setAutoHarvestTime(uint256 _autoHarvestTime) external onlyOwner {
        autoHarvestAfter = _autoHarvestTime;
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(xgt), "XGT-REWARD-MODULE-TOKEN-CANT-BE-XGT");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function deposit(uint256 _amount) external whenNotPaused notContract {
        require(false, "PAUSED");
        autoHarvestIfNecessary();
        _deposit(msg.sender, _amount, false);
    }

    function depositForUser(
        address _user,
        uint256 _amount,
        bool _skipLastDepositUpdate
    ) external whenNotPaused onlyAuthorized {
        require(false, "PAUSED");
        _deposit(_user, _amount, _skipLastDepositUpdate);
    }

    function _deposit(
        address _user,
        uint256 _amount,
        bool _skipLastDepositUpdate
    ) internal {
        require(_amount > 0, "XGT-REWARD-MODULE-CANT-DEPOSIT-ZERO");
        xgt.transferFrom(_user, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(balanceOf());
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[_user];

        user.shares = user.shares.add(currentShares);
        user.deposits = user.deposits.add(_amount);
        totalShares = totalShares.add(currentShares);
        user.lastUserActionTime = block.timestamp;
        if (!_skipLastDepositUpdate) {
            user.lastDepositedTime = block.timestamp;
        }

        emit Deposit(_user, _amount, currentShares, block.timestamp);
    }

    function withdraw(uint256 _shares) external notContract {
        require(false, "PAUSED");
        autoHarvestIfNecessary();
        _withdraw(msg.sender, _shares);
    }

    function withdrawForUser(address _user, uint256 _shares)
        external
        onlyAuthorized
    {
        _withdraw(_user, _shares);
    }

    function withdrawAll() external notContract {
        require(false, "PAUSED");
        autoHarvestIfNecessary();
        _withdraw(msg.sender, userInfo[msg.sender].shares);
    }

    function withdrawAllForUser(address _user) external onlyAuthorized {
        _withdraw(_user, userInfo[_user].shares);
    }
    
    function _withdraw(address _user, uint256 _shares) internal {
        UserInfo storage user = userInfo[_user];
        //require(
        //    _shares > 0,
        //    "XGT-REWARD-MODULE-NEED-TO-WITHDRAW-MORE-THAN-ZERO"
        //);
        //require(
        //    _shares <= user.shares,
        //    "XGT-REWARD-MODULE-CANT-WITHDRAW-MORE-THAN-MAXIMUM"
        //);

        //uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        //user.shares = user.shares.sub(_shares);
        //totalShares = totalShares.sub(_shares);
        //user.deposits = user.deposits.mul(user.shares).div(
        //    (user.shares.add(_shares))
        //);

        //if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
        //    uint256 currentWithdrawFee =
        //        currentAmount.mul(withdrawFee).div(BP_DECIMALS);
        //    freezer.freeze(currentWithdrawFee);
        //    currentAmount = currentAmount.sub(currentWithdrawFee);
        //}
        uint256 withdrawThis = user.deposits;
        user.deposits = 0;
        user.shares = 0;
        user.lastDepositedTime = 0;
        user.lastUserActionTime = block.timestamp;

        xgt.transfer(_user, withdrawThis);

        emit Withdraw(_user, withdrawThis, 0);
    }

    function harvest() public notContract whenNotPaused {
        uint256 harvestAmount = currentHarvestAmount();
        require(
            rewardChest.sendInstantClaim(address(this), harvestAmount),
            "XGT-REWARD-MODULE-INSTANT-CLAIM-FROM-CHEST-FAILED"
        );

        uint256 currentPerformanceFee =
            harvestAmount.mul(performanceFee).div(BP_DECIMALS);
        freezer.freeze(currentPerformanceFee);

        uint256 currentCallFee = harvestAmount.mul(callFee).div(BP_DECIMALS);
        xgt.transfer(msg.sender, currentCallFee);

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    function autoHarvestIfNecessary() public {
        if (block.timestamp.sub(lastHarvestedTime) > autoHarvestAfter) {
            harvest();
        }
    }

    function currentHarvestAmount() public view returns (uint256) {
        uint256 diff = block.timestamp.sub(lastHarvestedTime);
        uint256 harvestAmount =
            balanceOf().mul(stakingAPY).mul(diff).div(BP_DECIMALS).div(
                YEAR_IN_SECONDS
            );
        return harvestAmount;
    }

    function getCurrentUserBalance(address _user)
        public
        view
        returns (uint256)
    {
        uint256 harvestAfterFees =
            currentHarvestAmount()
                .mul(BP_DECIMALS.sub(performanceFee).sub(callFee))
                .div(BP_DECIMALS);
        uint256 balanceAfterHarvest = balanceOf().add(harvestAfterFees);
        if (totalShares == 0) {
            return 0;
        }
        return balanceAfterHarvest.mul(userInfo[_user].shares).div(totalShares);
    }

    function getCurrentUserInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            getCurrentUserBalance(_user),
            userInfo[_user].deposits,
            userInfo[_user].shares
        );
    }

    function balanceOf() public view returns (uint256) {
        return xgt.balanceOf(address(this));
    }

    function getHarvestRewards() external view returns (uint256) {
        uint256 amount = currentHarvestAmount();
        uint256 currentCallFee = amount.mul(callFee).div(BP_DECIMALS);

        return currentCallFee;
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }

    // Only for compatibility with reward chest
    function claimModule(address _user) external pure {
        return;
    }

    // Only for compatibility with reward chest
    function getClaimable(address _user) external pure returns (uint256) {
        return 0;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(
            !_isContract(msg.sender),
            "XGT-REWARD-MODULE-NO-CONTRACTS-ALLOWED"
        );
        require(
            msg.sender == tx.origin,
            "XGT-REWARD-MODULE-PROXY-CONTRACT-NOT-ALLOWED"
        );
        _;
    }

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "XGT-REWARD-MODULE-CALLER-NOT-AUTHORIZED"
        );
        _;
    }
}