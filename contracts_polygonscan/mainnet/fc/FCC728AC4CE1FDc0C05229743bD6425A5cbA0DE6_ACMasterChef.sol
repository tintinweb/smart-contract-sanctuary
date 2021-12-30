// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './AutoCompoundStrategy.sol';

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

/**
 * @title AutoCompound MasterChef
 * @notice strategy for auto-compounding on pools using a standard MasterChef contract
 * @author YieldWolf
 */
contract ACMasterChef is AutoCompoundStrategy {
    using SafeERC20 for IERC20;

    function _farmDeposit(uint256 amount) internal override {
        IERC20(stakeToken).safeIncreaseAllowance(masterChef, amount);
        IFarm(masterChef).deposit(pid, amount);
    }

    function _farmWithdraw(uint256 amount) internal override {
        IFarm(masterChef).withdraw(pid, amount);
    }

    function _farmEmergencyWithdraw() internal override {
        IFarm(masterChef).emergencyWithdraw(pid);
    }

    function _totalStaked() internal view override returns (uint256 amount) {
        (amount, ) = IFarm(masterChef).userInfo(pid, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/IYieldWolf.sol';

/**
 * @title Auto Compound Strategy
 * @notice handles deposits and withdraws on the underlying farm and auto-compound rewards
 * @author YieldWolf
 */
abstract contract AutoCompoundStrategy is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IYieldWolf public yieldWolf; // address of the YieldWolf staking contract
    address public masterChef; // address of the farm staking contract
    uint256 public pid; // pid of pool in the farm staking contract
    IERC20 public stakeToken; // token staked on the underlying farm
    IERC20 public token0; // first token of the lp (or 0 if it's a single token)
    IERC20 public token1; // second token of the lp (or 0 if it's a single token)
    IERC20 public earnToken; // reward token paid by the underlying farm
    address[] public extraEarnTokens; // some underlying farms can give rewards in multiple tokens
    IUniswapV2Router02 public swapRouter; // router used for swapping tokens
    IUniswapV2Router02 public liquidityRouter; // router used for adding liquidity to the LP token
    address public WNATIVE; // address of the network's native currency (e.g. ETH)
    bool public swapRouterEnabled = true; // if true it will use swap router for token swaps, otherwise liquidity router

    mapping(address => mapping(address => address[])) public swapPath; // paths for swapping 2 given tokens

    uint256 public sharesTotal = 0;
    bool public initialized;
    bool public emergencyWithdrawn;

    event Initialize();
    event Farm();
    event Pause();
    event Unpause();
    event EmergencyWithdraw();
    event TokenToEarn(address token);
    event WrapNative();

    modifier onlyOperator() {
        require(IYieldWolf(yieldWolf).operators(msg.sender), 'onlyOperator: NOT_ALLOWED');
        _;
    }

    function _farmDeposit(uint256 depositAmount) internal virtual;

    function _farmWithdraw(uint256 withdrawAmount) internal virtual;

    function _farmEmergencyWithdraw() internal virtual;

    function _totalStaked() internal view virtual returns (uint256);

    receive() external payable {}

    /**
     * @notice initializes the strategy
     * @dev similar to constructor but makes it easier for inheritance and for creating strategies from contracts
     * @param _pid the id of the pool in the farm's staking contract
     * @param _isLpToken whether the given stake token is a lp or a single token
     * @param _addresses list of addresses
     * @param _earnToToken0Path swap path from earn token to token0
     * @param _earnToToken1Path swap path from earn token to token1
     * @param _token0ToEarnPath swap path from token0 to earn token
     * @param _token1ToEarnPath swap path from token1 to earn token
     */
    function initialize(
        uint256 _pid,
        bool _isLpToken,
        address[7] calldata _addresses,
        address[] calldata _earnToToken0Path,
        address[] calldata _earnToToken1Path,
        address[] calldata _token0ToEarnPath,
        address[] calldata _token1ToEarnPath
    ) external onlyOwner {
        require(!initialized, 'initialize: ALREADY_INITIALIZED');
        initialized = true;
        yieldWolf = IYieldWolf(_addresses[0]);
        stakeToken = IERC20(_addresses[1]);
        earnToken = IERC20(_addresses[2]);
        masterChef = _addresses[3];
        swapRouter = IUniswapV2Router02(_addresses[4]);
        liquidityRouter = IUniswapV2Router02(_addresses[5]);
        WNATIVE = _addresses[6];
        if (_isLpToken) {
            token0 = IERC20(IUniswapV2Pair(_addresses[1]).token0());
            token1 = IERC20(IUniswapV2Pair(_addresses[1]).token1());
            swapPath[address(earnToken)][address(token0)] = _earnToToken0Path;
            swapPath[address(earnToken)][address(token1)] = _earnToToken1Path;
            swapPath[address(token0)][address(earnToken)] = _token0ToEarnPath;
            swapPath[address(token1)][address(earnToken)] = _token1ToEarnPath;
        } else {
            swapPath[address(earnToken)][address(stakeToken)] = _earnToToken0Path;
            swapPath[address(stakeToken)][address(earnToken)] = _token0ToEarnPath;
        }
        pid = _pid;
        emit Initialize();
    }

    /**
     * @notice deposits stake tokens in the underlying farm
     * @dev can only be called by YieldWolf contract which performs the required validations and logging
     * @param _depositAmount amount deposited by the user
     */
    function deposit(uint256 _depositAmount) external virtual onlyOwner nonReentrant whenNotPaused returns (uint256) {
        uint256 depositFee = (_depositAmount * yieldWolf.depositFee()) / 10000;
        _depositAmount = _depositAmount - depositFee;
        if (depositFee > 0) {
            stakeToken.safeTransfer(yieldWolf.feeAddress(), depositFee);
        }

        uint256 totalStakedBefore = totalStakeTokens() - _depositAmount;
        _farm();
        uint256 totalStakedAfter = totalStakeTokens();

        // adjust for deposit fees on the underlying farm and token transfer fees
        _depositAmount = totalStakedAfter - totalStakedBefore;

        uint256 sharesAdded = _depositAmount;
        if (totalStakedBefore > 0 && sharesTotal > 0) {
            sharesAdded = (_depositAmount * sharesTotal) / totalStakedBefore;
        }
        sharesTotal = sharesTotal + sharesAdded;

        return sharesAdded;
    }

    /**
     * @notice unstake tokens from the underlying farm and transfers them to the given address
     * @dev can only be called by YieldWolf contract which performs the required validations and logging
     * @param _withdrawAmount maximum amount to withdraw
     * @param _withdrawTo address that will receive the stake tokens
     * @param _bountyHunter address of the bounty hunter who execute the rule or the zero address if it's not a rule execution
     * @param _ruleFeeAmount how much to pay in concept of rule execution fees
     */
    function withdraw(
        uint256 _withdrawAmount,
        address _withdrawTo,
        address _bountyHunter,
        uint256 _ruleFeeAmount
    ) external virtual onlyOwner nonReentrant returns (uint256) {
        uint256 totalStakedOnFarm = _totalStaked();
        uint256 totalStake = totalStakeTokens();

        // number of shares that the withdraw amount represents (rounded up)
        uint256 sharesRemoved = (_withdrawAmount * sharesTotal - 1) / totalStake + 1;

        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal - sharesRemoved;

        if (totalStakedOnFarm > 0) {
            _farmWithdraw(_withdrawAmount);
        }

        uint256 stakeBalance = stakeToken.balanceOf(address(this));
        if (_withdrawAmount > stakeBalance) {
            _withdrawAmount = stakeBalance;
        }

        if (totalStake < _withdrawAmount) {
            _withdrawAmount = totalStake;
        }

        // apply rule execution fees
        if (_bountyHunter != address(0)) {
            uint256 bountyRuleFee = (_ruleFeeAmount * yieldWolf.ruleFeeBountyPct()) / 10000;
            uint256 platformRuleFee = _ruleFeeAmount - bountyRuleFee;
            if (bountyRuleFee > 0) {
                stakeToken.safeTransfer(_bountyHunter, bountyRuleFee);
            }
            if (platformRuleFee > 0) {
                stakeToken.safeTransfer(yieldWolf.feeAddress(), platformRuleFee);
            }
            _withdrawAmount -= _ruleFeeAmount;
        }

        // apply withdraw fees
        uint256 withdrawFee = (_withdrawAmount * yieldWolf.withdrawFee()) / 10000;
        if (withdrawFee > 0) {
            _withdrawAmount -= withdrawFee;
            stakeToken.safeTransfer(yieldWolf.feeAddress(), withdrawFee);
        }

        stakeToken.safeTransfer(_withdrawTo, _withdrawAmount);

        return sharesRemoved;
    }

    /**
     * @notice deposits the contract's balance of stake tokens in the underlying farm
     */
    function farm() external virtual nonReentrant whenNotPaused {
        _farm();
        emit Farm();
    }

    /**
     * @notice harvests earn tokens and deposits stake tokens in the underlying farm
     * @dev can only be called by YieldWolf contract which performs the required validations and logging
     *      if the contract is paused, this function becomes a no-op
     * @param _bountyHunter address that will get paid the bounty reward
     */
    function earn(address _bountyHunter) external virtual onlyOwner returns (uint256 bountyReward) {
        if (paused()) {
            return 0;
        }

        // harvest earn tokens
        uint256 earnAmountBefore = earnToken.balanceOf(address(this));
        _farmHarvest();

        if (address(earnToken) == WNATIVE) {
            wrapNative();
        }

        for (uint256 i; i < extraEarnTokens.length; i++) {
            tokenToEarn(extraEarnTokens[i]);
        }

        uint256 harvestAmount = earnToken.balanceOf(address(this)) - earnAmountBefore;

        if (harvestAmount > 0) {
            bountyReward = _distributeFees(harvestAmount, _bountyHunter);
        }
        uint256 earnAmount = earnToken.balanceOf(address(this));

        // if no token0, then stake token is a single token: Swap earn token for stake token
        if (address(token0) == address(0)) {
            if (stakeToken != earnToken) {
                _safeSwap(earnAmount, swapPath[address(earnToken)][address(stakeToken)], address(this), false);
            }
            _farm();
            return bountyReward;
        }

        // stake token is a LP token: Swap earn token for token0 and token1 and add liquidity
        if (earnToken != token0) {
            _safeSwap(earnAmount / 2, swapPath[address(earnToken)][address(token0)], address(this), false);
        }
        if (earnToken != token1) {
            _safeSwap(earnAmount / 2, swapPath[address(earnToken)][address(token1)], address(this), false);
        }
        uint256 token0Amt = token0.balanceOf(address(this));
        uint256 token1Amt = token1.balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
            token0.safeIncreaseAllowance(address(liquidityRouter), token0Amt);
            token1.safeIncreaseAllowance(address(liquidityRouter), token1Amt);
            liquidityRouter.addLiquidity(
                address(token0),
                address(token1),
                token0Amt,
                token1Amt,
                0,
                0,
                address(this),
                block.timestamp
            );
        }

        _farm();
        return bountyReward;
    }

    /**
     * @notice pauses the strategy in case of emergency
     * @dev can only be called by the operator. Only in case of emergency.
     */
    function pause() external virtual onlyOperator {
        _pause();
        emit Pause();
    }

    /**
     * @notice unpauses the strategy
     * @dev can only be called by the operator
     */
    function unpause() external virtual onlyOperator {
        require(!emergencyWithdrawn, 'unpause: CANNOT_UNPAUSE_AFTER_EMERGENCY_WITHDRAW');
        _unpause();
        emit Unpause();
    }

    /**
     * @notice enables or disables the swap router used for swapping earn tokens to stake tokens
     * @dev can only be called by YieldWolf contract which already performs the required validations and logging
     */
    function setSwapRouterEnabled(bool _enabled) external virtual onlyOwner {
        swapRouterEnabled = _enabled;
    }

    /**
     * @notice updates the swap path for a given pair
     * @dev can only be called by YieldWolf contract which already performs the required validations and logging
     */
    function setSwapPath(
        address _token0,
        address _token1,
        address[] calldata _path
    ) external virtual onlyOwner {
        swapPath[_token0][_token1] = _path;
    }

    /**
     * @notice updates the list of extra earn tokens
     * @dev can only be called by YieldWolf contract which already performs the required validations and logging
     */
    function setExtraEarnTokens(address[] calldata _extraEarnTokens) external virtual onlyOwner {
        extraEarnTokens = _extraEarnTokens;
    }

    /**
     * @notice converts any token in the contract into earn tokens
     * @dev it uses the predefined path if it exists or defaults to use WNATIVE
     */
    function tokenToEarn(address _token) public virtual nonReentrant whenNotPaused {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0 && _token != address(earnToken) && _token != address(stakeToken)) {
            address[] memory path = swapPath[_token][address(earnToken)];
            if (path.length == 0) {
                if (_token == WNATIVE) {
                    path = new address[](2);
                    path[0] = _token;
                    path[1] = address(earnToken);
                } else {
                    path = new address[](3);
                    path[0] = _token;
                    path[1] = WNATIVE;
                    path[2] = address(earnToken);
                }
            }
            if (path[0] != address(earnToken) && path[0] != address(stakeToken)) {
                _safeSwap(amount, path, address(this), true);
            }
            emit TokenToEarn(_token);
        }
    }

    /**
     * @notice converts NATIVE into WNATIVE (e.g. ETH -> WETH)
     */
    function wrapNative() public virtual {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWETH(WNATIVE).deposit{value: balance}();
        }
        emit WrapNative();
    }

    function totalStakeTokens() public view virtual returns (uint256) {
        return _totalStaked() + stakeToken.balanceOf(address(this));
    }

    /**
     * @notice invokes the emergency withdraw function in the underlying farm
     * @dev can only be called by the operator. Only in case of emergency.
     */
    function emergencyWithdraw() external virtual onlyOperator {
        if (!paused()) {
            _pause();
        }
        emergencyWithdrawn = true;
        _farmEmergencyWithdraw();
        emit EmergencyWithdraw();
    }

    function _farm() internal virtual {
        uint256 depositAmount = stakeToken.balanceOf(address(this));
        _farmDeposit(depositAmount);
    }

    function _farmHarvest() internal virtual {
        _farmDeposit(0);
    }

    function _distributeFees(uint256 _amount, address _bountyHunter) internal virtual returns (uint256) {
        uint256 bountyReward = 0;
        uint256 bountyRewardPct = _bountyHunter == address(0) ? 0 : yieldWolf.performanceFeeBountyPct();
        uint256 performanceFee = (_amount * yieldWolf.performanceFee()) / 10000;
        bountyReward = (performanceFee * bountyRewardPct) / 10000;
        uint256 platformPerformanceFee = performanceFee - bountyReward;
        if (platformPerformanceFee > 0) {
            earnToken.safeTransfer(yieldWolf.feeAddress(), platformPerformanceFee);
        }
        if (bountyReward > 0) {
            earnToken.safeTransfer(_bountyHunter, bountyReward);
        }
        return bountyReward;
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to,
        bool _ignoreErrors
    ) internal virtual {
        IUniswapV2Router02 router = swapRouterEnabled ? swapRouter : liquidityRouter;
        IERC20(_path[0]).safeIncreaseAllowance(address(router), _amountIn);
        if (_ignoreErrors) {
            try
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, 0, _path, _to, block.timestamp)
            {} catch {}
        } else {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, 0, _path, _to, block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IYieldWolf {
    function operators(address addr) external returns (bool);

    function depositFee() external returns (uint256);

    function withdrawFee() external returns (uint256);

    function performanceFee() external returns (uint256);

    function performanceFeeBountyPct() external returns (uint256);

    function ruleFee() external returns (uint256);

    function ruleFeeBountyPct() external returns (uint256);

    function feeAddress() external returns (address);

    function stakedTokens(uint256 pid, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}