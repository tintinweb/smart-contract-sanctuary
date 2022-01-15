// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./lib/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./FractStrategyV1.sol";
import "./FractERC20.sol";

/**
 * @notice FractVault is a managed vault for `deposit tokens` that accepts deposits in the form of `deposit tokens` OR `strategy tokens`.
 */
contract VaultV1 is FractERC20, Ownable {

    uint256 internal constant BIPS_DIVISOR = 10000;

    /// @notice Deposit token that the vault manages
    IERC20 public depositToken;

    /// @notice Receipt token that the vault mints upon deposit
    FractERC20 public receiptToken;

    /// @notice Total deposits in terms of depositToken
    uint public totalDeposits;

    /// @notice Earned interest from depositing into strategies. To be determined where it is sent. 
    uint256 public earnedInterest;

    /// @notice Active strategy where deposits are sent by default
    address public activeStrategy;

    /// @notice Supported strategies
    address[] public supportedStrategies;

    /// @notice Supported deposit tokens 
    mapping(address => bool) public supportedDepositTokens;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Deployed(address indexed strategy, uint256 amount);
    event InterestEarned(uint256 amount);
    event AddStrategy(address indexed strategy);
    event RemoveStrategy(address indexed strategy);
    event SetActiveStrategy(address indexed strategy);


    constructor (
        address _depositToken,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) FractERC20(
        _name,
        _symbol,
        _decimals
    )
      Ownable(msg.sender) {
        _name;
        depositToken = IERC20(_depositToken);
        supportedDepositTokens[_depositToken] = true;
    }

    /**
     * @notice Deposit to currently active strategy
     * @dev By default, Vaults send new deposits to the active strategy
     * @param amount amount
     */

    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
    }
    
    function _deposit(address account, uint256 amount) private {
        require(account != address(0), "Account is a 0 address");
        require(amount > 0, "Amount must be greater than 0");
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        require(depositToken.transferFrom(msg.sender, address(this), amount), "Deposit failed, transferFrom failed");
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        uint256 confirmedAmount = balanceAfter - balanceBefore;
        require(confirmedAmount > 0, "Deposit failed, amount too low");
        totalDeposits = totalDeposits + confirmedAmount;
        _mint(account, getSharesForDepositTokens(confirmedAmount));

        emit Deposit(account, confirmedAmount);
    }

    function deployToStrategy() public onlyOwner {
        _deployToStrategy();
    }

    function _deployToStrategy() private {
        require(activeStrategy != address(0), "FractVault::no active strategy");
        uint256 depositTokenBalance = depositToken.balanceOf(address(this));
        require(depositTokenBalance > 0, "Cannot deploy balance, amount must be greater than 0");
        depositToken.approve(activeStrategy, depositTokenBalance);
        FractStrategyV1(activeStrategy).deposit(depositTokenBalance);
        depositToken.approve(activeStrategy, 0);

        emit Deployed(activeStrategy, depositTokenBalance);
    }

    /**
     * @notice Withdraw from the vault
     * @param amount receipt tokens
     */

    
    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint256 amount) private {
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        require(depositTokenAmount > 0, "FractVault::withdraw, amount too low");
        uint256 liquidDeposits = depositToken.balanceOf(address(this));
        require(liquidDeposits > 0, "FractVault:balance too low");
        uint256 interest = liquidDeposits - depositTokenAmount;
        _safeTransfer(address(depositToken), msg.sender, depositTokenAmount);
        _burn(msg.sender, amount);
        totalDeposits = totalDeposits - depositTokenAmount;
        earnedInterest = earnedInterest + interest;
        emit Withdraw(msg.sender, depositTokenAmount);
        emit InterestEarned(earnedInterest);
    }

    /**
     * @notice Revoke approval for an anonymous ERC20 token
     * @dev Requires token to return true on approve
     * @param token address
     * @param spender address
     */
    function _revokeApproval(address token, address spender) private {
        require(token != address(0), "Token address is 0");
        require(spender != address(0), "Spender address is 0");
        require(IERC20(token).approve(spender, 0), "FractVault::revokeApproval");
    }

    /**
     * @notice Safely transfer using an anonymous ERC20 token
     * @dev Requires token to return true on transfer
     * @param token address
     * @param to recipient address
     * @param value amount
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        require(token != address(0), "Token address is 0");
        require(to != address(0), "To address is 0");
        require(value > 0, "amount must be greater than 0");
        require(IERC20(token).transfer(to, value), 'FractVault::TRANSFER_FROM_FAILED');
    }

    /**
     * @notice Set an active strategy
     * @dev Set to address(0) to disable deposits
     * @param strategy address for new strategy
     */
    function setActiveStrategy(address strategy) public onlyOwner {
        require(supportedDepositTokens[strategy] == true, "FractVault::setActiveStrategy, not found");
        require(depositToken.approve(strategy, type(uint256).max));
        activeStrategy = strategy;
        emit SetActiveStrategy(strategy);
    }

    /**
     * @notice Add a supported strategy and allow deposits
     * @dev Makes light checks for compatible deposit tokens
     * @param strategy address for new strategy
     */
    function addStrategy(address strategy) public onlyOwner {
        require(supportedDepositTokens[strategy] == false, "FractVault::addStrategy, already supported");
        require(depositToken == FractStrategyV1(strategy).depositToken(), "FractVault::addStrategy, not compatible");
        supportedDepositTokens[strategy] = true;
        supportedStrategies.push(strategy);

        emit AddStrategy(strategy);
    }

    /**
     * @notice Remove a supported strategy and revoke approval
     * @param strategy address for new strategy
     */
    function removeStrategy(address strategy) public onlyOwner {
        require(strategy != activeStrategy, "FractVault::removeStrategy, cannot remove activeStrategy");
        require(strategy != address(depositToken), "FractVault::removeStrategy, cannot remove deposit token");
        require(supportedDepositTokens[strategy] == true, "FractVault::removeStrategy, not supported");
        _revokeApproval(address(depositToken), strategy);
        supportedDepositTokens[strategy] = false;
        for (uint i = 0; i < supportedStrategies.length; i++) {
            if (strategy == supportedStrategies[i]) {
                supportedStrategies[i] = supportedStrategies[supportedStrategies.length - 1];
                supportedStrategies.pop();
                break;
            }
        }

        emit RemoveStrategy(strategy);
    }

    /**
     * @notice Owner method for removing funds from strategy (to rebalance, typically)
     * @notice Will only work for active strategy address.
     * @param strategy address
     */

    function withdrawFromStrategy(address strategy) public onlyOwner {
        _withdrawFromStrategy(strategy);
    
    }

    function _withdrawFromStrategy(address strategy) private {
        require(strategy != address(0), "FractVault::no active strategy");
        require(activeStrategy != address(0), "FractVault::no active strategy");
        require(activeStrategy==strategy, "Strategy must be active strategy");
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        uint256 strategyBalanceShares = FractStrategyV1(strategy).balanceOf(address(this));
        FractStrategyV1(strategy).withdraw(strategyBalanceShares);
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "YakVault::_withdrawDepositTokensFromStrategy withdrawal failed");
    }

    /**
     * @notice Count deposit tokens deployed in a strategy
     * @param strategy address
     * @return amount deposit tokens
     */
    function getDeployedBalance(address strategy) public view returns (uint) {
        uint vaultShares = FractStrategyV1(strategy).balanceOf(address(this));
        return FractStrategyV1(strategy).getDepositTokensForShares(vaultShares);
    }

    /**
     * @notice Count deposit tokens deployed across supported strategies
     * @dev Does not include deprecated strategies
     * @return amount deposit tokens
     */
    function estimateDeployedBalances() public view returns (uint) {
        uint deployedFunds = 0;
        for (uint i = 0; i < supportedStrategies.length; i++) {
            deployedFunds = deployedFunds + getDeployedBalance(supportedStrategies[i]);
        }
        return deployedFunds;
    }

    function resetTotalDeposits() public {
        uint liquidBalance = depositToken.balanceOf(address(this));
        uint deployedBalance = estimateDeployedBalances();
        totalDeposits = liquidBalance + deployedBalance;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply * totalDeposits == 0) {
            return 0;
        }
        return (amount * totalDeposits) / totalSupply;
    }

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply * totalDeposits == 0) {
            return amount;
        }
        return (amount * totalSupply) / totalDeposits;
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
    function destroy(address payable addr) public virtual onlyOwner {
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
pragma solidity 0.8.3;

import "./lib/Ownable.sol";
import "./lib/Permissioned.sol";
import "./interfaces/IERC20.sol";
import "./FractERC20.sol";

/**
 * @notice FractStrategy should be inherited by new strategies
 */
abstract contract FractStrategyV1 is FractERC20, Ownable, Permissioned {

    IERC20 public depositToken;
    IERC20 public rewardToken;
    
    address public devAddr;

    uint256 private _theFee;

    uint public MIN_TOKENS_TO_REINVEST;
    uint public MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
    bool public DEPOSITS_ENABLED;

    uint public REINVEST_REWARD_BIPS;
    uint public ADMIN_FEE_BIPS;

    uint constant internal BIPS_DIVISOR = 10000;

    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);
    event Reinvest(uint newTotalDeposits, uint newTotalSupply);
    event Recovered(address token, uint amount);
    event UpdateAdminFee(uint oldValue, uint newValue);
    event UpdateReinvestReward(uint oldValue, uint newValue);
    event UpdateMinTokensToReinvest(uint oldValue, uint newValue);
    event UpdateMaxTokensToDepositWithoutReinvest(uint oldValue, uint newValue);
    event UpdateDevAddr(address oldValue, address newValue);
    event DepositsEnabled(bool newValue);

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "FractStrategy::onlyEOA");
        _;
    }

    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "FractStrategy::onlyDev");
        _;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0));
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint amount) external virtual;

    /**
     * @notice Deposit on behalf of another account
     * @dev Must mint receipt tokens to `account`
     * @param account address to receive receipt tokens
     * @param amount deposit tokens
     */
    function depositFor(address account, uint amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint amount) external virtual;

    /**
     * @notice Reinvest reward tokens into deposit tokens
     */
    function reinvest() external virtual;

    /**
     * @notice Estimate reinvest reward
     * @return reward tokens
     */
    function estimateReinvestReward() external view returns (uint) {
        uint unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {
            return (unclaimedRewards * REINVEST_REWARD_BIPS) / BIPS_DIVISOR;
        }
        return 0;
    }

    /**
     * @notice Reward tokens available to strategy, including balance
     * @return reward tokens
     */
    function checkReward() public virtual view returns (uint);

    /**
     * @notice Estimated deposit token balance deployed by strategy, excluding balance
     * @return deposit tokens
     */
    function estimateDeployedBalance() external virtual view returns (uint);

    /**
     * @notice Rescue all available deployed deposit tokens back to Strategy
     * @param minReturnAmountAccepted min deposit tokens to receive
     * @param disableDeposits bool
     */
    function rescueDeployedFunds(uint minReturnAmountAccepted, bool disableDeposits) external virtual;

    /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() public virtual view returns (uint);
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply * totalDeposits() == 0) {
            return amount;
        }
        return (amount * totalSupply) / totalDeposits();
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply * totalDeposits() == 0) {
            return 0;
        }
        return (amount * totalDeposits()) / totalSupply;
    }

    /**
     * @notice Update reinvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToReinvest(uint newValue) public onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;
    }

    /**
     * @notice Update reinvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutReinvest(uint newValue) public onlyOwner {
        emit UpdateMaxTokensToDepositWithoutReinvest(MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST, newValue);
        MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST = newValue;
    }

    /**
     * @notice Update admin fee
     * @param newValue fee in BIPS
     */
    function updateAdminFee(uint newValue) public onlyOwner {
        require(newValue + REINVEST_REWARD_BIPS <= BIPS_DIVISOR);
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;
    }

    /**
     * @notice Update reinvest reward
     * @param newValue fee in BIPS
     */
    function updateReinvestReward(uint newValue) public onlyOwner {
        require(newValue + ADMIN_FEE_BIPS <= BIPS_DIVISOR);
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(DEPOSITS_ENABLED != newValue);
        DEPOSITS_ENABLED = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) public onlyDev {
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint tokenAmount) external onlyOwner {
        require(tokenAmount > 0);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount));
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param amount amount
     */
    function recoverAVAX(uint amount) external onlyOwner {
        require(amount > 0);
        payable(msg.sender).transfer(amount);
        emit Recovered(address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.3;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @notice Adapted from Rari-Capital's Solmate ERC20 Implementation
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.

abstract contract FractERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

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

    function allowance(address owner, address spender) public virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
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
    ) public virtual returns (bool) {
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

import "./Ownable.sol";

abstract contract Permissioned is Ownable {

    uint public numberOfAllowedDepositors;
    mapping(address => bool) public allowedDepositors;

    event AllowDepositor(address indexed account);
    event RemoveDepositor(address indexed account);

    modifier onlyAllowedDeposits() {
        if (numberOfAllowedDepositors > 0) {
            require(allowedDepositors[msg.sender] == true, "Permissioned::onlyAllowedDeposits, not allowed");
        }
        _;
    }

    /**
     * @notice Add an allowed depositor
     * @param depositor address
     */
    function allowDepositor(address depositor) external onlyOwner {
        require(allowedDepositors[depositor] == false, "Permissioned::allowDepositor");
        allowedDepositors[depositor] = true;
        numberOfAllowedDepositors = numberOfAllowedDepositors + 1;
        emit AllowDepositor(depositor);
    }

    /**
     * @notice Remove an allowed depositor
     * @param depositor address
     */
    function removeDepositor(address depositor) external onlyOwner {
        require(numberOfAllowedDepositors > 0, "Permissioned::removeDepositor, no allowed depositors");
        require(allowedDepositors[depositor] == true, "Permissioned::removeDepositor, not allowed");
        allowedDepositors[depositor] = false;
        numberOfAllowedDepositors = numberOfAllowedDepositors - 1;
        emit RemoveDepositor(depositor);
    }
}