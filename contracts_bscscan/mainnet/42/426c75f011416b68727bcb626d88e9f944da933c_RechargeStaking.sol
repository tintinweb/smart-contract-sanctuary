// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRCore.sol";
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected][email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Recharge Finance
https://recharge.finance
*/

contract RechargeStaking is Ownable {
    using SafeERC20 for IERC20;

    struct Staker {
        uint256 amount;
        uint256 lockedUntil;
        uint256 amountWithMultiplier;
        uint256 stakePos;
        uint256 multiplier;
        uint256 yieldLock;
    }

    mapping (address => uint256) private _stakers;
    mapping (address => uint256) private _stakes;

    mapping (uint256 => uint256) private _periods;
    uint16[] private _periodMap;

    uint256 private stakeP;

    uint256 private _lastRewardTokenBalance;

    IERC20 private _stakeToken;

    IRCore private _reactor;

    uint128 public totalStakedWithMultipliers;
    uint128 public totalStaked;

    uint256 public lockYieldReward;

    bool public isPaused;

    modifier isNotPaused() {
        require(!isPaused, "Contract is paused");

        _;
    }

    constructor(address coreToken) {
        _periods[0] = 100;
        _periods[7] = 110;
        _periods[30] = 140;
        _periods[90] = 200;

        _periodMap = [0, 7, 30, 90];

        lockYieldReward = 20;

        _reactor = IRCore(coreToken);
    }

    function getPeriod(uint256 index) external view returns (uint256) {
        return _periodMap[index];
    }

    function getPeriodMultiplier(uint256 period_) external view returns (uint256) {
        return _periods[period_];
    }

    function getTotalPeriods() external view returns (uint256) {
        return _periodMap.length;
    }

    function stakeLockedUntil(address staker) public view returns (uint256) {
        return getStaker(staker).lockedUntil;
    }

    /**
    * @notice address of the token that can be staked in this pool
    */
    function tokenContract() public view returns (address) {
        return address(_stakeToken);
    }

    function viewStake(address account) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        Staker memory staker_ = getStaker(account);
        return (
            staker_.amount,
            staker_.lockedUntil,
            staker_.amountWithMultiplier,
            staker_.multiplier,
            staker_.yieldLock,
            staker_.stakePos
        );
    }

    function saveStaker(address owner, Staker memory staker_) internal {
        _stakers[owner] = flattenStaker(staker_.amount, staker_.lockedUntil, staker_.amountWithMultiplier, staker_.multiplier, staker_.yieldLock);
        _stakes[owner] = staker_.stakePos;
    }

    function flattenStaker(uint256 amount, uint256 lockedUntil, uint256 amountWithMultiplier, uint256 multiplier, uint256 lockYield) internal pure returns (uint256) {
        uint256 s = amount;
        s |= lockedUntil<<192;
        s |= amountWithMultiplier<<128;
        s |= multiplier<<112;
        s |= lockYield<<104;
        return s;
    }

    function getStaker(address account) internal view returns (Staker memory) {
        uint256 stakeProps = _stakers[account];
        Staker memory stake_;
        stake_.amount = uint256(uint64(stakeProps));
        stake_.lockedUntil = uint256(uint48(stakeProps>>192));
        stake_.amountWithMultiplier = uint256(uint64(stakeProps>>128));
        stake_.multiplier = uint256(uint16(stakeProps>>112));
        stake_.yieldLock = uint256(uint8(stakeProps>>104));
        stake_.stakePos = _stakes[account];
        return stake_;
    }

    /**
    * @dev override this function to implement fee deductions when a stake is added
    */
    function prepareStakeDepositAmount(uint256 amount) pure internal virtual returns (uint256) {
        return amount;
    }

    /**
    * @dev override this function to implement fee deductions when unstaking
    */
    function prepareUnstakeAmount(uint256 amount) pure internal virtual returns (uint256) {
        return amount;
    }

    /**
    * @notice After approving the contract, lock `amount` of tokens.
    */
    function stake(uint256 amount, uint256 period, uint8 lockYield) isNotPaused external {
        require(_stakers[msg.sender] == 0, "Unstake first");
        require(_periods[period] > 0, "Incorrect period");

        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        amount = prepareStakeDepositAmount(amount);

        uint256 lockReward = (lockYield == 1) ? lockYieldReward : 0;
        uint256 bonusMultiplier = (_periods[period] + lockReward);
        uint256 amountWithMultiplier = amount * bonusMultiplier / 100;

        totalStakedWithMultipliers += uint128(amountWithMultiplier);
        totalStaked += uint128(amount);

        Staker memory staker_ = Staker(amount, block.timestamp + (period * 1 days), amountWithMultiplier, stakeP, bonusMultiplier, lockYield);
        staker_.stakePos = stakeP;
        saveStaker(msg.sender, staker_);

        updateTokenBalance();
    }

    function unstake() external {
        updateTokenBalance();

        if (tokensOwed(msg.sender) > 0) {
            _claim();
        }

        Staker memory staker_ = getStaker(msg.sender);
        // allow people to unstake if paused
        require(staker_.lockedUntil <= block.timestamp || isPaused, "Stake locked");

        uint256 amount = prepareUnstakeAmount(staker_.amount);
        totalStakedWithMultipliers -= uint128(staker_.amountWithMultiplier);
        totalStaked -= uint128(staker_.amount);

        // Clear staker
        _stakers[msg.sender] = 0;
        _stakes[msg.sender] = 0;

        _stakeToken.safeTransfer(msg.sender, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        Staker memory staker_ = getStaker(account);
        return staker_.amount;
    }

    function syncBalances() external {
        updateTokenBalance();
    }

    function updateTokenBalance() internal {
        _reactor.updateBalance();

        uint256 contractBalance = _reactor.expectedDistributorBalance(address(this));
        if (contractBalance > _lastRewardTokenBalance && totalStakedWithMultipliers > 0) {
            uint256 reward = contractBalance - _lastRewardTokenBalance;
            stakeP = stakeP + (reward * 10**12 / totalStakedWithMultipliers);
            _lastRewardTokenBalance = contractBalance;
        }
    }

    function updateLastRewardTokenBalance() internal {
        _lastRewardTokenBalance = _reactor.expectedDistributorBalance(address(this));
    }

    /**
    * @notice determines account rewards even if stakes updates haven't been triggered
    */
    function estimateTokensOwed(address account) public view returns (uint256) {
        Staker memory staker_ = getStaker(account);
        uint256 deposited = staker_.amountWithMultiplier;

        if (deposited == 0) {
            return 0;
        }

        uint256 contractBalance = _reactor.expectedDistributorBalance(address(this));
        uint256 reward = contractBalance - _lastRewardTokenBalance;
        uint256 estStakeP = stakeP + (reward * 10**12 / uint256(totalStakedWithMultipliers));

        return deposited * (estStakeP - staker_.stakePos) / 10**12;
    }

    function tokensOwed(address account) public view returns (uint256) {
        Staker memory staker_ = getStaker(account);
        uint256 deposited = staker_.amountWithMultiplier;

        return deposited * (stakeP - staker_.stakePos) / 10**12;
    }

    function claim() external {
        require(_stakers[msg.sender] > 0, "Nothing staked");

        updateTokenBalance();

        _claim();
    }

    function _claim() internal {
        uint256 owed = tokensOwed(msg.sender);
        require(owed > 0, "Nothing to claim");

        Staker memory staker_ = getStaker(msg.sender);
        require(isPaused || staker_.yieldLock == 0 || staker_.lockedUntil <= block.timestamp, "Yield locked");

        staker_.stakePos = stakeP;
        saveStaker(msg.sender, staker_);

        _reactor.distribute(msg.sender, owed);

        updateLastRewardTokenBalance();
    }

    /*****
     * Administrative functions
     *****/

    /**
    * @notice pauses the contract and stops users from staking or adding liquidity
    */
    function pause(bool pause_) external onlyOwner {
        isPaused = pause_;
    }

    function setTokens(address stakeToken) external onlyOwner {
        require(address(_stakeToken) == address(0));

        updateLastRewardTokenBalance();

        _stakeToken = IERC20(stakeToken);
    }

    /**
     * Store a new period multiplier
     * @param days_ the number of days
     * @param multiplier where 100 = 1x, 110 = 1.1x, 200 = 2x, etc
     */
    function addPeriod(uint256 days_, uint256 multiplier) external onlyOwner {
        _periods[days_] = multiplier;
        _periodMap.push(uint16(days_));
    }

    /**
     * @param days_ which period to reset.
     */
    function removePeriod(uint256 days_) external onlyOwner {
        _periods[days_] = 0;

        uint16[] memory newPeriods = new uint16[](_periodMap.length - 1);

        uint256 index;

        for (uint256 i = 0; i < _periodMap.length; i++) {
            if (_periodMap[i] != days_) {
                newPeriods[index++] = _periodMap[i];
            }
        }

        _periodMap = newPeriods;
    }

    /**
     * @param amount multiplier to apply when staker chooses to lock fees
     */
    function updateYieldLock(uint256 amount) external onlyOwner {
        lockYieldReward = amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRCore is IERC20 {

    /**
     * @dev mint RCORE in exchange for R3FI, requires approval prior to minting
     */
    function mint(uint256 amount) external returns (bool);

    /**
     * @dev burn RCORE in exchange for R3FI
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev returns an (accurate) estimate of the contract's available balance, you will generally want to use
     * this method to maintain an up to date rewards balance.
     */
    function expectedDistributorBalance(address contract_) external view returns (uint256);

    /**
     * @dev returns the actual contract's available balance currently stored in the contract.
     * if it differs to expectedDistributorBalance(), you will want to call updateBalance() to calculate
     * up to date rewards.
     */
    function distributorBalance(address contract_) external view returns (uint256);

    /**
     * @dev send R3FI rewards to `recipient`, depending on your pool requirements your contract may need to maintain
     * a certain amount of RCORE tokens to receive benefits from the pool.
     */
    function distribute(address recipient, uint256 amount) external;

    /**
     * @dev calling will update the state and calculate up to date rewards for contracts. It is regularly called when other
     * core functions are triggered but you may need to trigger it to access the full amount of rewards available to your contract.
     */
    function updateBalance() external;
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
    constructor () {
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

