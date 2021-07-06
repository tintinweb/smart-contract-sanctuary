// contracts/strategies/StratPancakeCakeV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPancakeswapFarm.sol";
import "../interfaces/IPancakeRouter01.sol";

/**
 * @dev Implementation of the PancakeSwap Cake Strategy.
 * This contract will compound Cake staking.
 * The owner of the contract is the BalleMaster contract.
 */
contract StratPancakeCakeV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // PancakeSwap's MasterChef address.
    address public immutable masterChef;
    // Deposit token (CAKE) address.
    address public immutable depositToken;
    // PancakeSwap router address.
    address public immutable router;

    // Address to send controller fee.
    address public rewards;
    // Address to send treasury fee.
    address public treasury;

    // Governance Gnosis Safe multisig.
    address public governance;
    // Operations Gnosis Safe multisig.
    address public operations;
    // Harvest addresses
    mapping(address => bool) public harvesters;

    uint256 public depositTotal = 0;
    uint256 public sharesTotal = 0;

    // 0.1% entrance fee. Goes to pool, prevents front-running.
    uint256 public entranceFee = 9990;
    // Factor to calculate fee 100 = 1%.
    uint256 public constant ENTRANCE_FEE_MAX = 10000;
    // 0.5% max settable entrance fee, LL = lowerlimit.
    uint256 public constant ENTRANCE_FEE_LL = 9950;

    // 4% performance fee.
    uint256 public performanceFee = 400;
    // 8% max settable performance fee, UL = upperlimit.
    uint256 public constant PERFORMANCE_FEE_UL = 800;
    // Factor to calculate fee 100 = 1%.
    uint256 public constant PERFORMANCE_FEE_MAX = 10000;
    // 3% goes to BALLE holders.
    uint256 public rewardsFeeFactor = 750;
    // 1% goes to treasury.
    uint256 public treasuryFeeFactor = 250;
    // Factor for fee distribution.
    uint256 public constant FEE_FACTOR_MAX = 1000;

    // 5% default slippage tolerance.
    uint256 public slippage = 950;
    // 10% max settable slippage tolerance, UL = upperlimit.
    uint256 public constant SLIPPAGE_UL = 990;

    // Swap routes
    address[] public earnedtokenToBallePath;

    // Paused state activated
    bool public paused = false;

    event SetSettings(
        uint256 entranceFee,
        uint256 performanceFee,
        uint256 rewardsFeeFactor,
        uint256 treasuryFeeFactor,
        uint256 slippage
    );
    event Harvest(uint256 amount);
    event DistributeFees(uint256 rewardsAmount, uint256 treasuryAmount);
    event SetGovernance(address indexed addr);

    /**
     * @dev Implementation of PancakeSwap Cake autocompounding strategy.
     */
    constructor(address[] memory _addresses, address[] memory _earnedtokenToBallePath) {
        depositToken = _addresses[0];
        router = _addresses[1];
        masterChef = _addresses[2];

        governance = msg.sender;
        harvesters[_addresses[4]] = true;
        rewards = _addresses[5];
        treasury = _addresses[6];

        earnedtokenToBallePath = _earnedtokenToBallePath;

        // The owner of the strategy contract is the BalleMaster contract
        transferOwnership(_addresses[3]);
    }

    /**
     * @dev Modifier to check the caller is the Governance Gnosis Safe multisig.
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /**
     * @dev Modifier to check the caller is the Governance or Operations Gnosis Safe multisig.
     */
    modifier onlyOperations() {
        require(msg.sender == operations || msg.sender == governance, "!operations");
        _;
    }

    /**
     * @dev Modifier to check the caller is the Governance or Operations Gnosis Safe multisig or an authorized harvester.
     */
    modifier onlyHarvester() {
        require(harvesters[msg.sender] || msg.sender == operations || msg.sender == governance, "!harvester");
        _;
    }

    /**
     * @dev Modifier to check that the strategy is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev Modifier to check that the strategy is paused.
     */
    modifier whenPaused() {
        require(paused, "!paused");
        _;
    }

    /**
     * @dev View function to see pending CAKEs on farm.
     */
    function pendingEarnedToken() external view returns (uint256) {
        return IPancakeswapFarm(masterChef).pendingCake(0, address(this));
    }

    /**
     * @dev Function to transfer tokens BalleMaster -> strategy and put it to work.
     */
    function deposit(address _user, uint256 _amount) public onlyOwner whenNotPaused returns (uint256) {
        require(_user != address(0), "!user");
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 sharesAdded = _amount;
        if (depositTotal > 0 && sharesTotal > 0) {
            sharesAdded = ((_amount * sharesTotal * entranceFee) / depositTotal) / ENTRANCE_FEE_MAX;
        }
        sharesTotal = sharesTotal + sharesAdded;

        farm(_amount);

        return sharesAdded;
    }

    /**
     * @dev Function to send depositToken to farm.
     */
    function farm(uint256 _amount) internal {
        bool first = (depositTotal == 0);
        uint256 amount = 0;
        if (_amount == 0) {
            amount = IERC20(depositToken).balanceOf(address(this));
        } else {
            amount = _amount;
        }
        depositTotal = depositTotal + amount;

        if (first) {
            // On first farming, set allowances
            setAllowances();
        }
        IPancakeswapFarm(masterChef).enterStaking(amount);
    }

    /**
     * @dev Function to transfer tokens strategy -> BalleMaster.
     */
    function withdraw(address _user, uint256 _amount) public onlyOwner returns (uint256, uint256) {
        require(_user != address(0), "!user");
        require(_amount > 0, "!amount");

        uint256 sharesRemoved = (_amount * sharesTotal) / depositTotal;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal - sharesRemoved;

        // If paused, tokens are already here
        if (!paused) {
            IPancakeswapFarm(masterChef).leaveStaking(_amount);
        }

        uint256 balance = IERC20(depositToken).balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        if (depositTotal < _amount) {
            _amount = depositTotal;
        }

        depositTotal = depositTotal - _amount;

        IERC20(depositToken).safeTransfer(msg.sender, _amount);

        return (sharesRemoved, _amount);
    }

    /**
     * @dev Function to harvest earnings and reinvest.
     */
    function harvest() public onlyHarvester whenNotPaused nonReentrant {
        // Harvest farm tokens
        IPancakeswapFarm(masterChef).leaveStaking(0);
        uint256 earnedAmt = IERC20(depositToken).balanceOf(address(this));

        emit Harvest(earnedAmt);

        // Distribute the fees
        earnedAmt = distributeFees(earnedAmt);

        farm(0);
    }

    /**
     * @dev Function to calculate and distribute the fees.
     */
    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (performanceFee > 0) {
                uint256 totalFee = (_earnedAmt * performanceFee) / PERFORMANCE_FEE_MAX;

                uint256 treasuryFee = (totalFee * treasuryFeeFactor) / FEE_FACTOR_MAX;
                // Swap treasuryFee to BALLE and send to treasury.
                safeSwap(
                    router,
                    treasuryFee,
                    slippage,
                    earnedtokenToBallePath,
                    treasury,
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp + 600
                );
                uint256 rewardsFee = (totalFee * rewardsFeeFactor) / FEE_FACTOR_MAX;
                // Swap rewardsFee to BALLE and send to rewards contract.
                safeSwap(
                    router,
                    rewardsFee,
                    slippage,
                    earnedtokenToBallePath,
                    rewards,
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp + 600
                );

                _earnedAmt = _earnedAmt - totalFee;

                emit DistributeFees(rewardsFee, treasuryFee);
            }
        }

        return _earnedAmt;
    }

    /**
     * @dev Function to change strategy settings.
     */
    function setSettings(
        uint256 _entranceFee,
        uint256 _performanceFee,
        uint256 _rewardsFeeFactor,
        uint256 _treasuryFeeFactor,
        uint256 _slippage
    ) public onlyOperations {
        require(_entranceFee >= ENTRANCE_FEE_LL, "!entranceFeeLL");
        require(_entranceFee <= ENTRANCE_FEE_MAX, "!entranceFeeMax");
        entranceFee = _entranceFee;

        require(_performanceFee <= PERFORMANCE_FEE_UL, "!performanceFeeUL");
        performanceFee = _performanceFee;

        require(_rewardsFeeFactor + _treasuryFeeFactor == FEE_FACTOR_MAX, "!feeFactor");
        rewardsFeeFactor = _rewardsFeeFactor;
        treasuryFeeFactor = _treasuryFeeFactor;

        require(_slippage <= SLIPPAGE_UL, "!slippageUL");
        slippage = _slippage;

        emit SetSettings(_entranceFee, _performanceFee, _rewardsFeeFactor, _treasuryFeeFactor, _slippage);
    }

    /**
     * @dev Function to change the Governance Gnosis Safe multisig.
     */
    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "zero address");
        governance = _governance;
        emit SetGovernance(_governance);
    }

    /**
     * @dev Function to change the Operations Gnosis Safe multisig.
     */
    function setOperations(address _operations) public onlyGovernance {
        require(_operations != address(0), "zero address");
        operations = _operations;
    }

    /**
     * @dev Function to change the rewards address.
     */
    function setRewards(address _rewards) public onlyGovernance {
        require(_rewards != address(0), "zero address");
        rewards = _rewards;
    }

    /**
     * @dev Function to change the treasury address.
     */
    function setTreasury(address _treasury) public onlyGovernance {
        require(_treasury != address(0), "zero address");
        treasury = _treasury;
    }

    /**
     * @dev Add a harvester address.
     */
    function addHarvester(address _harvester) external onlyOperations {
        require(_harvester != address(0), "zero address");
        harvesters[_harvester] = true;
    }

    /**
     * @dev Remove a harvester address.
     */
    function removeHarvester(address _harvester) external onlyOperations {
        require(_harvester != address(0), "zero address");
        harvesters[_harvester] = false;
    }

    /**
     * @dev Utility function for setting allowances with third party contracts.
     */
    function setAllowances() internal {
        // Approve token transfers, check if 0 before setting
        if (IERC20(depositToken).allowance(address(this), masterChef) == 0) {
            IERC20(depositToken).safeApprove(masterChef, type(uint256).max);
        }
        if (IERC20(depositToken).allowance(address(this), router) == 0) {
            IERC20(depositToken).safeApprove(router, type(uint256).max);
        }
    }

    /**
     * @dev Utility function for clearing allowances with third party contracts.
     */
    function clearAllowances() internal {
        // Disapprove token transfers
        IERC20(depositToken).safeApprove(masterChef, 0);
        IERC20(depositToken).safeApprove(router, 0);
    }

    /**
     * @dev Utility function for safely swap tokens.
     */
    function safeSwap(
        address _router,
        uint256 _amountIn,
        uint256 _slippage,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal {
        uint256[] memory amounts = IPancakeRouter01(_router).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IPancakeRouter01(_router).swapExactTokensForTokens(
            _amountIn,
            (amountOut * _slippage) / 1000,
            _path,
            _to,
            _deadline
        );
    }

    /**
     * @dev Stop the vault.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Internal function for stopping the vault.
     */
    function _pause() internal {
        if (!paused) {
            paused = true;

            if (depositTotal > 0) {
                // Withdraw all from staking pool
                IPancakeswapFarm(masterChef).leaveStaking(depositTotal);
            }

            // Clear allowances of third party contracts.
            clearAllowances();
        }
    }

    /**
     * @dev Restart the vault.
     */
    function unpause() external onlyOwner whenPaused {
        depositTotal = 0; // It will be set back on farm().
        paused = false;

        farm(0);
    }

    /**
     * @dev Stop the vault with emergencyWithdraw from farm.
     */
    function panic() external onlyOwner whenNotPaused {
        paused = true;

        // Emergency withdraw.
        IPancakeswapFarm(masterChef).emergencyWithdraw(0);

        // Clear allowances of third party contracts.
        clearAllowances();
    }

    /**
     * @dev Retire the vault.
     */
    function retire() external onlyOwner {
        // Stop vault
        _pause();
    }

    /**
     * @dev Function to use from Governance Gnosis Safe multisig only in case tokens get stuck.
     * This is to be used if someone, for example, sends tokens to the contract by mistake.
     * There is no guarantee governance will vote to return these.
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyGovernance {
        require(_to != address(0), "zero address");
        require(_token != depositToken, "!safe");

        IERC20(_token).safeTransfer(_to, _amount);
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

    constructor () {
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

// contracts/interfaces/IPancakeswapFarm.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo() external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// contracts/interfaces/IPancakeRouter01.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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