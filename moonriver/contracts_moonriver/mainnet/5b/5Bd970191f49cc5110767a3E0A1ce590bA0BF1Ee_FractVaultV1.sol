// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./standards/Ownable.sol";
import "./standards/ReentrancyGuard.sol";
import "./lib/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAnyswapV5Router.sol";
import "./FractStrategyV1.sol";

/**
 * @notice FractVault is a managed vault for `deposit tokens`. 
 */
contract FractVaultV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Array of addresses of supported strategies.
    address[] public supportedStrategies;

    // Constant used as a bips divisor.       
    uint256 internal constant BIPS_DIVISOR = 10000;

    // Total capital deployed across strategies.
    uint256 public deployedCapital;

    // Deposit token that the vault manages.
    IERC20 public depositToken;

    IAnyswapV5Router public anySwapRouter;

    // Mapping to check supportedStrategies array.
    mapping(address => bool) public supportedStrategiesMapping;

    /**
     * @notice This event is fired when the vault receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when the vault receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when the vault withdraws to a layer one address.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event WithdrawToLayerOne(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when a strategy is added to supportedStrategies.
     * @param strategy The address of the strategy.
     */
    event AddStrategy(address indexed strategy);

    /**
     * @notice This event is fired when a strategy is removed from supportedStrategies.
     * @param strategy The address of the strategy.
     */
    event RemoveStrategy(address indexed strategy);

    /**
     * @notice This event is fired when funds are deployed to a strategy.
     * @param strategy The address of the strategy.
     * @param amount The amount deployed to the strategy.
     */
    event DeployToStrategy(address indexed strategy, uint256 amount);

     /**
     * @notice This event is fired when funds are withdrawn from a strategy.
     * @param strategy The address of the strategy.
     * @param amount The amount withdrawn from the strategy.
     */
    event WithdrawFromStrategy(address indexed strategy, uint256 amount);

    /**
     * @notice This event is fired when tokens are recovered from the strategy contract.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event EmergencyWithdrawal(address token, uint amount);

    /**
     * @notice This event is fired when the anyswap router address is set.
     * @param routerAddress Specifies the anyswap router address.
     */
    event SetRouterAddress(address routerAddress);

    /**
     * @notice Constructor
     * @param _depositToken The address of the deposit token that the vault accepts. Uses the IERC20 Interface
     */
    constructor (address _depositToken) Ownable(msg.sender) {
        depositToken = IERC20(_depositToken);
    }

    /**
     * @notice Owner method for setting the anyswap router address to crosschain withdrawals.
     * @param routerAddress The address of the anyswap router on avalanche.
     */
    function setAnySwapRouter(address routerAddress) external onlyOwner {
        require(routerAddress != address(0), "Router address cannot be a 0 address");
        anySwapRouter = IAnyswapV5Router(routerAddress);
        emit SetRouterAddress(routerAddress);
    }

    /**
     * @notice Owner method for depositing to the vault, without deploying to a strategy.
     * @notice In order to deploy deposit amount to strategy, you must call deployToStrategy()
     * @notice Add the nonReentrant modifer to mitigate re-entry attacks.
     * @param amount amount
     */
    function depositToVault(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        uint256 currentBalance = getCurrentBalance();
        uint256 expectedBalance = currentBalance + amount;

        emit Deposit(msg.sender, amount);

        depositToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 updatedBalance = getCurrentBalance();
        require(updatedBalance >= expectedBalance, "Balance verification failed");

    }

    /**
     * @notice Owner method for deploying entire deposit token amount to a single strategy.
     * @param strategy strategy address.
     */
    function deployToStrategy(address strategy) external onlyOwner {
        require(strategy != address(0), "FractVault::no active strategy");
        require(supportedStrategiesMapping[strategy], "Strategy is not in supported strategies.");
        uint256 depositTokenBalance = 0;
        depositTokenBalance = depositToken.balanceOf(address(this));
        require(depositTokenBalance > 0, "Cannot deploy balance, amount must be greater than 0");

        deployedCapital += depositTokenBalance;

        emit DeployToStrategy(strategy, depositTokenBalance);

        depositToken.safeIncreaseAllowance(strategy, depositTokenBalance);
        FractStrategyV1(strategy).deposit(depositTokenBalance);
        require(depositToken.approve(strategy, 0), "Deployment Failed");
    }

    /**
     * @notice Owner method for deploying percentage amount of deposit tokens to a single strategy.
     * @param strategy strategy address.
     * @param depositPercentageBips percentage of deposit token amount to deploy. Use 10000 to deploy full amount.
     */
    function deployPercentageToStrategy(address strategy, uint256 depositPercentageBips) external onlyOwner {
        require(depositPercentageBips > 0 && depositPercentageBips <= BIPS_DIVISOR, "Invalid Percentage");
        require(supportedStrategiesMapping[strategy], "Strategy is not in supported strategies");
        uint256 depositTokenBalance = 0;
        depositTokenBalance = depositToken.balanceOf(address(this));
        require(depositTokenBalance != 0, "Deposit token balance must be greater than  0");
        uint256 amount = (depositTokenBalance * depositPercentageBips) / BIPS_DIVISOR;

        deployedCapital = deployedCapital + amount;

        emit DeployToStrategy(strategy, amount);

        depositToken.safeIncreaseAllowance(strategy, amount);
        FractStrategyV1(strategy).deposit(amount);
        require(depositToken.approve(strategy, 0), "Deployment Failed");
        
    }

    /**
     * @notice Owner method for withdrawing from the vault.
     * @notice Add the nonReentrant modifer to mitigate re-entry attacks.
     * @param amount receipt tokens held by msg.sender. 
     */
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Must withdraw more than 0");

        emit Withdraw(msg.sender, amount);

        depositToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Owner method for withdrawing from the vault to layer one.
     * @param anyToken address of anyToken.
     * @param toToken address of toToken on destination chain.
     * @param amount amount to withdraw to layer one via anyswap router.
     * @param chainId destination chain id to withdraw to.
     */
    function withdrawToLayerOne(
        address anyToken, 
        address toToken, 
        uint256 amount, 
        uint256 chainId) public onlyOwner {
        require(anyToken != address(0), "anyToken cannot be a 0 address");
        require(toToken != address(0), "anyswapRouter cannot be a 0 address");
        require(amount > 0, "Must withdraw more than 0");
        //add approval for anyswaprouter to spend anytoken
        IERC20(anyToken).approve(address(anySwapRouter), amount);

        emit WithdrawToLayerOne(msg.sender, amount);

        anySwapRouter.anySwapOutUnderlying(anyToken, toToken, amount, chainId);
    }

    /**
     * @notice Owner method for removing funds from strategy.
     * @param strategy address of strategy to withdraw from. 
     */
    function withdrawFromStrategy(address strategy) external onlyOwner {
        require(strategy != address(0), "Strategy cannot be a 0 address");
        require(supportedStrategiesMapping[strategy], "Strategy is not supported, cannot remove.");
        uint256 balanceBefore = getCurrentBalance();
        uint256 strategyBalanceShares = 0;
        uint256 withdrawnAmount = 0;
        strategyBalanceShares = FractStrategyV1(strategy).balanceOf(address(this));
        withdrawnAmount = FractStrategyV1(strategy).getDepositTokensForShares(strategyBalanceShares);
        require(withdrawnAmount + balanceBefore > balanceBefore, "Withdrawal failed");

        emit WithdrawFromStrategy(strategy, withdrawnAmount);

        FractStrategyV1(strategy).withdraw(strategyBalanceShares);

    }

    /**
     * @notice Owner method for removing percentage of funds from strategy.
     * @param strategy address of strategy to withdraw percentage from.
     * @param withdrawPercentageBips percentage of funds to withdraw. Use 10000 to withdraw full amount.
     */
    function withdrawPercentageFromStrategy(address strategy, uint256 withdrawPercentageBips) external onlyOwner {
        require(withdrawPercentageBips > 0 && withdrawPercentageBips <= BIPS_DIVISOR, "Percentage Required");
        uint256 balanceBefore = getCurrentBalance();
        uint256 shareBalance = 0;
        uint256 withdrawalAmount = 0;
        uint256 withdrawnAmount = 0;
        shareBalance = FractStrategyV1(strategy).balanceOf(address(this));
        withdrawalAmount = shareBalance * withdrawPercentageBips / BIPS_DIVISOR;
        withdrawnAmount = FractStrategyV1(strategy).getDepositTokensForShares(withdrawalAmount);
        require(withdrawnAmount > balanceBefore, "Withdrawal failed");

        emit WithdrawFromStrategy(strategy, withdrawnAmount);

        FractStrategyV1(strategy).withdraw(withdrawalAmount);
    }

    /**
     * @notice Owner method for adding supported strategy.
     * @param strategy address for new strategy
     */
    function addStrategy(address strategy) external onlyOwner {
        require(strategy != address(0), "Strategy is a 0 address");
        require(depositToken == FractStrategyV1(strategy).depositToken(), "FractVault::addStrategy, not compatible");
        supportedStrategiesMapping[strategy] = true;
        supportedStrategies.push(strategy);
        
        emit AddStrategy(strategy);
    }

    /**
     * @notice Owner method for removing strategy. 
     * @param strategy address for new strategy
     */
    function removeStrategy(address strategy) external onlyOwner {
        address[] storage strategiesToRemove = supportedStrategies;
        require(strategy != address(0), "Strategy is a 0 address");
        require(supportedStrategiesMapping[strategy], "Strategy is not supported, cannot remove.");
        for (uint256 i = 0; i < strategiesToRemove.length; i++) {
            if (strategy == strategiesToRemove[i]) {
                strategiesToRemove[i] = strategiesToRemove[strategiesToRemove.length - 1];
                strategiesToRemove.pop();
                break;
            }
        }
        supportedStrategies = strategiesToRemove;
        emit RemoveStrategy(strategy);
    }

    /**
     * @notice Returns current balance of deposit tokens in the vault. 
     */
    function getCurrentBalance() public view returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    /**
     * @notice Checks if strategy is a supported strategy.
     * @param strategy Address of strategy.
     */
    function checkStrategy(address strategy) external view returns (bool) {
        return supportedStrategiesMapping[strategy];
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function emergencyWithdrawal(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Recovery amount must be greater than 0");
        //rename this function and emitted event to EmergencyWithdrawal
        emit EmergencyWithdrawal(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Recovery Failed");
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);
    
    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "The address of the owner cannot be the zero address");
        require(addr != address(1), "The address of the owner cannot be the ecrecover address");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only the owner of the smart contract is allowed to call this function.");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "The target address cannot be the zero address");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) external virtual onlyOwner {
        require(addr != address(0), "The target address cannot be the zero address");
        require(addr != address(1), "The target address cannot be the ecrecover address");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.3;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.3;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.8.3;

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
pragma solidity 0.8.3;

interface IAnyswapV5Router {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./standards/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./FractERC20.sol";
import "./lib/DexLibrary.sol";

/**
 * @notice FractStrategyV1 should be inherited by new strategies.
 */

abstract contract FractStrategyV1 is FractERC20, Ownable {

    // Deposit token that the strategy accepts.
    IERC20 public depositToken;

    // Reward token that the strategy receives from protocol it interacts with.
    IERC20 public rewardToken;

    // Fractal Vault address;
    address public fractVault;
    
    // Developer Address
    address public devAddr;

    // Minimum amount of token rewards to harvest into the strategy.
    uint256 public minTokensToHarvest;

    // Minimum amount of tokens to deposit into strategy without harvesting.
    uint256 public maxTokensToDepositWithoutHarvest;

    // Total deposits in the strategy.
    uint256 public totalDeposits;

    // Bool value to enable or disable deposits.
    bool public depositsEnabled;

    // Fee that is given to EOA that calls harvest() function.
    uint256 public harvestRewardBips;

    // Fee that is sent to owner address.
    uint256 public adminFeeBips;

    // Constant used as a bips divisor. 
    uint256 constant internal BIPS_DIVISOR = 10000;

    // Constant for scaling values.
    uint256 public constant ONE_ETHER = 10**18;

    /**
     * @notice This event is fired when the strategy receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy harvest its earned rewards.
     * @param newTotalDeposits Specifies the total amount of deposits in the strategy.
     * @param newTotalSupply Specifies the total supply of receipt tokens the strategy has minted.
     */
    event Harvest(uint newTotalDeposits, uint newTotalSupply);

    /**
     * @notice This event is fired when tokens are recovered from the strategy contract.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event EmergencyWithdrawal(address token, uint amount);

    /**
     * @notice This event is fired when the admin fee is updated.
     * @param oldValue Old admin fee.
     * @param newValue New admin fee.
     */
    event UpdateAdminFee(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the harvest fee is updated.
     * @param oldValue Old harvest fee.
     * @param newValue New harvest fee.
     */
    event UpdateHarvestReward(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the min tokens to harvest is updated.
     * @param oldValue Old min tokens to harvest amount.
     * @param newValue New min tokens to harvest amount.
     */
    event UpdateMinTokensToHarvest(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the max tokens to deposit without harvest is updated.
     * @param oldValue Old max tokens to harvest without deposit.
     * @param newValue New max tokens to harvest without deposit.
     */
    event UpdateMaxTokensToDepositWithoutHarvest(uint oldValue, uint newValue);

     /**
     * @notice This event is fired when the developer address is updated.
     * @param oldValue Old developer address.
     * @param newValue New developer address.
     */
    event UpdateDevAddr(address oldValue, address newValue);

    /**
     * @notice This event is fired when deposits are enabled or disabled.
     * @param newValue Bool for enabling or disabling deposits.
     */
    event DepositsEnabled(bool newValue);

    /**
     * @notice This event is fired when the vault contract address is set. 
     * @param vaultAddress Specifies the address of the fractVault. 
     */
    event SetVault(address indexed vaultAddress);


    /**
     * @notice This event is fired when funds (interest) are withdrawn from a strategy.
     * @param amount The amount (interest) withdrawn from the strategy.
     */
    event WithdrawInterest(uint256 amount);

    /**
     * @notice This event is fired when the deposit token is altered. 
     * @param newTokenAddress The address of the new deposit token.  
     */
    event ChangeDepositToken(address indexed newTokenAddress);
    
    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "Only Developer can call this function");
        _;
    }

    /**
     * @notice Only called by vault
     */
    modifier onlyVault() {
        require(msg.sender == fractVault, "Only the fractVault can call this function.");
        _;
    }

    /**
     * @notice Initialized the different strategy settings after the contract has been deployed.
     * @param minHarvestTokens The minimum amount of pending reward tokens needed to call the harvest function.
     * @param adminFee The admin fee, charged when calling harvest function.
     * @param harvestReward The harvest fee, charged when calling the harvest function, given to EOA.
     */
    function initializeStrategySettings(uint256 minHarvestTokens, uint256 adminFee, uint256 harvestReward) 
    external onlyOwner {
        minTokensToHarvest = minHarvestTokens;
        adminFeeBips = adminFee;
        harvestRewardBips = harvestReward;

        updateMinTokensToHarvest(minTokensToHarvest);
        updateAdminFee(adminFeeBips);
        updateHarvestReward(harvestRewardBips);
    }

    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param vaultAddress Specifies the address of the poolContract. 
     */
    function setVaultAddress(address vaultAddress) external onlyOwner {
        require(vaultAddress != address(0), "Address cannot be a 0 address");
        fractVault = vaultAddress;

        emit SetVault(fractVault);

    }
    
    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0), "Revoke Failed");
    }

    /**
     * @notice Set a new deposit token, and swap current deposit tokens to new deposit tokens via lp pool.
     * @param oldDeposit The address of the old depositToken for the strategy.
     * @param newDeposit The address of the new depositToken for the strategy.
     * @param swapContract The address of the lp pool to swap old deposit token to new deposit token.
     * @param minAmountOut minimum amount out, calculated offchain. 
     */
    function changeDepositToken(address oldDeposit, address newDeposit, address swapContract, uint256 minAmountOut) external onlyOwner {
        require(oldDeposit != address(0), "Address cannot be a 0 address");
        require(newDeposit != address(0), "Address cannot be a 0 address");
        require(swapContract != address(0), "Address cannot be a 0 address");

        uint256 depositTokenBalance = depositToken.balanceOf(address(this));
        uint256 newDepositTokenBalance = 0;
        
        depositToken = IERC20(newDeposit);
        
        emit ChangeDepositToken(newDeposit);

        newDepositTokenBalance = DexLibrary.swap(
            depositTokenBalance,
            oldDeposit,
            newDeposit,
            IPair(swapContract),
            minAmountOut
        );
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint256 amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint256 amount) external virtual;
    
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount) public view returns (uint) {
        if (totalSupply * totalDeposits > 0) {
            return (amount * totalSupply) / totalDeposits;
        }
        return amount;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount) public view returns (uint) {
        if (totalSupply * totalDeposits > 0) {
            return (amount * totalDeposits) / totalSupply;
        }
        return 0;
    }

    /**
     * @notice Update harvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToHarvest(uint256 newValue) public onlyOwner {
        emit UpdateMinTokensToHarvest(minTokensToHarvest, newValue);
        minTokensToHarvest = newValue;
    }

    /**
     * @notice Update harvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutHarvest(uint256 newValue) external onlyOwner {
        emit UpdateMaxTokensToDepositWithoutHarvest(maxTokensToDepositWithoutHarvest,newValue);
        maxTokensToDepositWithoutHarvest = newValue;
    }

    /**
     * @notice Update admin fee
     * @param newValue fee in BIPS
     */
    function updateAdminFee(uint256 newValue) public onlyOwner {
        require(newValue + harvestRewardBips <= BIPS_DIVISOR, "Updated Failed");
        emit UpdateAdminFee(adminFeeBips, newValue);
        adminFeeBips = newValue;
    }

    /**
     * @notice Update harvest reward
     * @param newValue fee in BIPS
     */
    function updateHarvestReward(uint256 newValue) public onlyOwner {
        require(newValue + adminFeeBips <= BIPS_DIVISOR, "Update Failed");
        emit UpdateHarvestReward(harvestRewardBips, newValue);
        harvestRewardBips = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) external onlyOwner {
        require(depositsEnabled != newValue, "Update Failed");
        depositsEnabled = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) external onlyDev {
        require(newValue != address(0), "Address is a 0 address");
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function emergencyWithdrawal(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Recovery amount must be greater than 0");
        emit EmergencyWithdrawal(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Recovery Failed");
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity 0.8.3;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
pragma solidity 0.8.3;

/**
 * @notice FractERC20 adapts from Rari Capital's Solmate ERC20.
 */
abstract contract FractERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

        
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function allowance(address owner, address spender) external virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function totalTokenSupply() external view returns (uint256) {
        return totalSupply;
    }

    function approve(address spender, uint256 amount) external virtual returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external virtual returns (bool) {
        balances[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual returns (bool) {
        uint256 allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowances[from][msg.sender] = allowed - amount;

        balances[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }


    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balances[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "../interfaces/IERC20.sol";
import "../interfaces/IPair.sol";

library DexLibrary {

  bytes private constant ZERO_BYTES = new bytes(0);

  /**
   * @notice Swap directly through a Pair
   * @param amountIn input amount
   * @param fromToken address
   * @param toToken address
   * @param pair Pair used for swap
   * @param minAmountOut minimum amount out, calculated offchain.
   * @return output amount
   */
  function swap(uint256 amountIn, address fromToken, address toToken, IPair pair, uint256 minAmountOut) internal returns (uint256) {
    (address token0, ) = sortTokens(fromToken, toToken);
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
    uint256 amountOut1 = 0;
    uint256 amountOut2 = getAmountOut(amountIn, reserve0, reserve1);
    if (token0 != fromToken)
      (amountOut1, amountOut2) = (amountOut2, amountOut1);
    safeTransfer(fromToken, address(pair), amountIn);
    pair.swap(amountOut1, amountOut2, address(this), ZERO_BYTES);
    if (amountOut2 > amountOut1){
      require(amountOut2 > minAmountOut, "Slippage Exceeded");
      return amountOut2;
    }
    else {
      require(amountOut1 > minAmountOut, "Slippage Exceeded");
      return amountOut1;
    }
  }

  /**
   * @notice Add liquidity directly through a Pair
   * @dev Checks adding the max of each token amount
   * @param depositToken address
   * @param maxAmountIn0 amount token0
   * @param maxAmountIn1 amount token1
   * @return liquidity tokens
   */
  function addLiquidity(
    address depositToken,
    uint256 maxAmountIn0,
    uint256 maxAmountIn1
  ) internal returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IPair(address(depositToken))
      .getReserves();
    uint256 amountIn1 = _quoteLiquidityAmountOut(
      maxAmountIn0,
      reserve0,
      reserve1
    );
    if (amountIn1 > maxAmountIn1) {
      amountIn1 = maxAmountIn1;
      maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
    }

    safeTransfer(IPair(depositToken).token0(), depositToken, maxAmountIn0);
    safeTransfer(IPair(depositToken).token1(), depositToken, amountIn1);
    return IPair(depositToken).mint(address(this));
  }

  /**
   * @notice Add liquidity directly through a Pair
   * @dev Checks adding the max of each token amount
   * @param depositToken address
   * @return amounts of each token returned
   */
  function removeLiquidity(address depositToken)
    internal
    returns (uint256, uint256)
  {
    IPair pair = IPair(address(depositToken));
    require(address(pair) != address(0), "Invalid pair for removingliquidity");

    safeTransfer(depositToken, depositToken, pair.balanceOf(address(this)));
    (uint256 amount0, uint256 amount1) = pair.burn(address(this));

    return (amount0, amount1);
  }

  /**
   * @notice Quote liquidity amount out
   * @param amountIn input tokens
   * @param reserve0 size of input asset reserve
   * @param reserve1 size of output asset reserve
   * @return liquidity tokens
   */
  function _quoteLiquidityAmountOut(
    uint256 amountIn,
    uint256 reserve0,
    uint256 reserve1
  ) private pure returns (uint256) {
    return (amountIn * reserve1) / reserve0;
  }

  /**
   * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
   * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
   * @param tokenA address
   * @param tokenB address
   * @return sorted tokens
   */
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address, address)
  {
    return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  /**
   * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
   * @dev Assumes swap fee is 0.30%
   * @param amountIn input asset
   * @param reserveIn size of input asset reserve
   * @param reserveOut size of output asset reserve
   * @return maximum output amount
   */
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256) {
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn * 1000 + amountInWithFee;
    uint256 amountOut = numerator / denominator;
    return amountOut;
  }

  /**
   * @notice Safely transfer using an anonymous ERC20 token
   * @dev Requires token to return true on transfer
   * @param token address
   * @param to recipient address
   * @param value amount
   */
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    require(
      IERC20(token).transfer(to, value),
      "DexLibrary::TRANSFER_FROM_FAILED"
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function sync() external;
}