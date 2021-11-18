// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

contract LPPool is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public source;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IERC20Upgradeable public target;

    uint256 constant public OneDay = 1 seconds;
    uint256 constant public Percent = 100;
    uint256 constant public Thousand = 1000;


    uint256 public starttime;
    uint256 public periodFinish; // 默认不结束周期
    uint256 public rewardRate;
    //for tax if you getReward, pay the ratio in source token
    uint256 public taxRatio;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public accumulatedRewards;

    address public minerOwner;
    address taxCollector;    // 提前赎回 会收取费用


    address public feeManager;
    uint256 public fee;
    bool internal feeCharged;

    uint256 public withdrawCoolDown; // stake 锁定期
    //address => stake timestamp
    mapping(address => uint256) public withdrawCoolDownMap;


    //the logic should be hardcoded separately, or use a certain list
    //address => last stake/withdraw timestamp
    mapping(address => uint256) public detainTimestamp;
    uint256 public DETAIN_WITHIN_24;
    uint256 public DETAIN_BETWEEN_24_48;
    uint256 public DETAIN_EXCEED_48;

    //address => last getReward timestamp | detained amount
    mapping(address => uint256) public remainingTimestamp;
    mapping(address => uint256) public remaining;
    uint256 public remainingTimeLock;
    uint256 public remainingPercent;


    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event BonusPaid(address indexed user, uint256 reward);
    event RemainingPaid(address indexed user, uint256 reward);
    event TransferBack(address token, address to, uint256 amount);

    function initialize(
        address _target,
        address _source,
        uint256 _starttime,
        address _minerOwner,
        address _taxCollector,
        address _feeManager,
        uint256 _withdrawCoolDown
    ) initializer public {
        __Ownable_init();
        require(_target != address(0), "_target is zero address");
        require(_source != address(0), "_source is zero address");
        require(_minerOwner != address(0), "_minerOwner is zero address");

        target = IERC20Upgradeable(_target);
        source = IERC20Upgradeable(_source);
        starttime = _starttime;
        minerOwner = _minerOwner;
        taxCollector = _taxCollector;
        feeManager = _feeManager;
        withdrawCoolDown = _withdrawCoolDown;

        fee = 0 ether;

        remainingTimeLock = 30 days;
        remainingPercent = 70;

        periodFinish = 0;
        rewardRate = 0;
        taxRatio = 0;
        feeCharged = false;
    }



    modifier checkStart() {
        require(block.timestamp >= starttime, 'Pool: not start');
        _;
    }

    modifier updateCoolDown(){
        withdrawCoolDownMap[msg.sender] = block.timestamp;
        _;
    }

    modifier checkCoolDown(){
        require(withdrawCoolDownMap[msg.sender] + withdrawCoolDown <= block.timestamp, "Cooling Down");
        _;
    }

    modifier checkRemainingTimeLock(){
        require(remainingTimestamp[msg.sender] + remainingTimeLock <= block.timestamp, "Remaining Time Lock Triggered");
        _;
    }


    modifier updateDetain(){
        _;
        detainTimestamp[msg.sender] = block.timestamp;
    }

    modifier chargeFee(){
        bool lock = false;
        if (!feeCharged) {
            require(msg.value >= fee, "msg.value >= minimumFee");
            payable(feeManager).transfer(msg.value);
            feeCharged = true;
            lock = true;
        }
        _;
        if (lock) {
            feeCharged = false;
        }
    }


    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }


    // 这段时间内每个 token 的 stake 产出
    // rewardPerTokenStored +  (当前时间 - 每次有人 stake / withdraw 的时间 ) * 1s产出 / 总供应量 ）
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * (1e18) / totalSupply());
    }

    //008cc262
    // 抵押数量 * （当前阶段每个 抵押 产出） + 已经奖励过的
    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / (1e18) + rewards[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function stake(uint256 amount)
    public
    payable
    updateReward(msg.sender)
    checkStart
    chargeFee
    updateCoolDown
    updateDetain
    {
        require(amount > 0, 'Pool: Cannot stake 0');
        sourceStake(amount);
        emit Staked(msg.sender, amount);
    }

    //2e1a7d4d1
    function withdraw(uint256 amount)
    public
    payable
    updateReward(msg.sender)
    checkStart
    chargeFee
    checkCoolDown
    updateDetain
    {
        require(amount > 0, 'Pool: Cannot withdraw 0');

        uint256 sourceLeft = detain(amount);
        // 计算需要扣留多少
        sourceWithdraw(sourceLeft);

        if (isTaxOn()) {
            clearReward();
        }

        emit Withdrawn(msg.sender, amount);
    }

    //e9fad8ee
    function exit() external payable chargeFee checkCoolDown {
        getReward();
        //        getBonus();
        withdraw(balanceOf(msg.sender));
    }

    //3d18b912
    //hook the bonus when user getReward
    function getReward() public payable updateReward(msg.sender) checkStart chargeFee {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 remainingReward = reward * remainingPercent / Percent;
            uint256 immediateReturn = reward - remainingReward;

            if (remainingReward != 0) {
                remainingTimestamp[msg.sender] = block.timestamp;
                remaining[msg.sender] = remaining[msg.sender] + remainingReward;
            }

            if (immediateReturn != 0) {
                target.safeTransferFrom(minerOwner, msg.sender, immediateReturn);
                emit RewardPaid(msg.sender, immediateReturn);
                accumulatedRewards[msg.sender] = accumulatedRewards[msg.sender] + immediateReturn;
                //
                //                address userInviter = inviter[msg.sender];
                //                uint256 userBonus = immediateReturn.mul(bonusRatio).div(Percent);
                //                bonus[userInviter] = bonus[userInviter].add(userBonus);
            }


            if (isTaxOn()) {
                uint256 amount = balanceOf(msg.sender) * taxRatio / Percent;
                sourcePayTaxOrDetain(amount, taxCollector);
                //skip update reward again
            }
        }
    }

    function detain(uint256 amountToWithdraw) internal returns (uint256 sourceLeft){

        uint256 detainedAmount = calcDetain(msg.sender, amountToWithdraw);

        if (detainedAmount > 0) {
            sourcePayTaxOrDetain(detainedAmount, taxCollector);
        }
        sourceLeft = amountToWithdraw - detainedAmount;

        return sourceLeft;
    }

    function calcDetain(address who, uint256 amountToWithdraw) public view returns (uint256){
        uint256 ts = detainTimestamp[who];
        require(ts <= block.timestamp, "ts <= block.timestamp");

        uint256 delta = block.timestamp - ts;
        uint256 detainedAmount = 0;
        //I know the condition is redundant, just keep safe here
        if (delta <= 24 hours) {
            detainedAmount = amountToWithdraw * DETAIN_WITHIN_24 / Thousand;
        } else if (24 hours < delta && delta <= 48 hours) {
            detainedAmount = amountToWithdraw * DETAIN_BETWEEN_24_48 / Thousand;
        } else {
            detainedAmount = amountToWithdraw * DETAIN_EXCEED_48 / Thousand;
        }
        return detainedAmount;
    }

    function clearReward() internal updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
        }
    }

    function getRemaining() external payable chargeFee checkRemainingTimeLock {

        uint256 remainingReward = remaining[msg.sender];
        remaining[msg.sender] = 0;
        target.safeTransferFrom(minerOwner, msg.sender, remainingReward);

        emit RemainingPaid(msg.sender, remainingReward);
        accumulatedRewards[msg.sender] = accumulatedRewards[msg.sender] + remainingReward;

    }

    function transferBack(IERC20Upgradeable erc20Token, address to, uint256 amount) external onlyOwner {
        require(erc20Token != source, "For LPT, transferBack is not allowed, if you transfer LPT by mistake, sorry");

        if (address(erc20Token) == address(0)) {
            payable(to).transfer(amount);
        } else {
            erc20Token.safeTransfer(to, amount);
        }
        emit TransferBack(address(erc20Token), to, amount);
    }

    function isTaxOn() internal view returns (bool){
        return taxRatio != 0;
    }

    //you can call this function many time as long as block.number does not reach starttime and _starttime
    function initSet(
        uint256 _starttime,
        uint256 rewardPerDay,
        uint256 _taxRatio,
        uint256 _periodFinish,
        uint256 _detain_within_24,
        uint256 _detain_between_24_48,
        uint256 _detain_exceed_48
    )
    external
    onlyOwner
    updateReward(address(0))
    {

        require(block.timestamp < starttime, "block.timestamp < starttime");

        require(block.timestamp < _starttime, "block.timestamp < _starttime");
        require(_starttime < _periodFinish, "_starttime < _periodFinish");

        starttime = _starttime;
        rewardRate = rewardPerDay / OneDay;
        taxRatio = _taxRatio;
        periodFinish = _periodFinish;
        lastUpdateTime = starttime;

        DETAIN_WITHIN_24 = _detain_within_24;
        DETAIN_BETWEEN_24_48 = _detain_between_24_48;
        DETAIN_EXCEED_48 = _detain_exceed_48;
    }

    function updateRewardRate(uint256 rewardPerDay, uint256 _taxRatio, uint256 _periodFinish)
    external
    onlyOwner
    updateReward(address(0))
    {
        if (_periodFinish == 0) {
            _periodFinish = block.timestamp;
        }

        require(starttime < block.timestamp, "starttime < block.timestamp");
        require(block.timestamp <= _periodFinish, "block.timestamp <= _periodFinish");

        rewardRate = rewardPerDay / OneDay;
        taxRatio = _taxRatio;
        periodFinish = _periodFinish;
        lastUpdateTime = block.timestamp;
    }

    function changeMinerOwner(address _minerOwner) external onlyOwner {
        minerOwner = _minerOwner;
    }

    function changeTaxCollector(address _taxCollector) external onlyOwner {
        taxCollector = _taxCollector;
    }

    function changeFee(
        uint256 _fee,
        address _feeManager
    ) external onlyOwner {
        fee = _fee;
        feeManager = _feeManager;
    }

    function changeWithdrawCoolDown(uint256 _withdrawCoolDown) external onlyOwner {
        withdrawCoolDown = _withdrawCoolDown;
    }


    function changeRemainingConfig(uint256 _remainingTimeLock, uint256 _remainingPercent) external onlyOwner {
        remainingTimeLock = _remainingTimeLock;
        remainingPercent = _remainingPercent;
    }

    function changeDetainConfig(
        uint256 _detain_within_24,
        uint256 _detain_between_24_48,
        uint256 _detain_exceed_48
    ) external onlyOwner {
        DETAIN_WITHIN_24 = _detain_within_24;
        DETAIN_BETWEEN_24_48 = _detain_between_24_48;
        DETAIN_EXCEED_48 = _detain_exceed_48;
    }

    //=======================

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function sourceStake(uint256 amount) internal {
        uint256 amountBefore = source.balanceOf(address(this));
        source.safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountAfter = source.balanceOf(address(this));
        amount = amountAfter - amountBefore;

        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
    }

    function sourceWithdraw(uint256 amount) internal {
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        source.safeTransfer(msg.sender, amount);
    }

    function sourcePayTaxOrDetain(uint256 amount, address to) internal {
        if (amount > 0) {
            _totalSupply = _totalSupply - amount;
            _balances[msg.sender] = _balances[msg.sender] - amount;
            source.safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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