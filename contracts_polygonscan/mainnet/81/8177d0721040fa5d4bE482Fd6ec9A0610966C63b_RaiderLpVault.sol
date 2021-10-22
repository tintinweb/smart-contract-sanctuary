//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// !! IMPORTANT !! The most up to date SafeMath relies on Solidity 0.8.0's new overflow protection. 
// If you use an older version of Soliditiy you MUST also use an older version of SafeMath

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @author Oighty (h/t to Nat Eliason for authoring the RaiderStaking contract). Please contact me on Twitter (@oightytag) or Discord (Oighty #4287) if you have any questions about this contract.
 */

interface IRaiderStaking {
    // --------- UTILITY FUNCTIONS ------------
    function isStaker(address _address) external view returns(bool);

    // ----------- STAKING ACTIONS ------------
    function createStake(uint _amount) external;
    function removeStake(uint _amount) external;
    // Backup function in case something happens with the update rewards functions
    function emergencyUnstake(uint _amount) external;

    // ------------ REWARD ACTIONS ---------------
    function getRewards() external;
    function updateAddressRewardsBalance(address _address) external returns (uint);
    function updateBigRewardsPerToken() external;
    function userPendingRewards(address _address) external view returns (uint);

    // ------------ ADMIN ACTIONS ---------------
    function withdrawRewards(uint _amount) external;
    function depositRewards(uint _amount) external;
    function setDailyEmissions(uint _amount) external;
    function pause() external;
    function unpause() external;

    // ------------ VIEW FUNCTIONS ---------------
    function timeSinceLastReward() external view returns (uint);
    function rewardsBalance() external view returns (uint);
    function addressStakedBalance(address _address) external view returns (uint);
    function showStakingToken() external view returns (address);
    function showRewardToken() external view returns (address);
    function showBigRewardsPerToken() external view returns (uint);
    function showBigUserRewardsCollected() external view returns (uint);
}

contract RaiderLpVault is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //  -------------------- CONTRACT VARIABLES --------------------
    string public name;

    // Tokens and Contracts to Interface with
    IRaiderStaking public stakingContract; // The staking contract that the vault will compound into
    IUniswapV2Pair internal _stakingToken; // The LP token people can stake
    IERC20 internal _pairedToken; // The non-MATIC token in the LP
    IERC20 internal _rewardToken; // The token people will be rewarded with
    IUniswapV2Pair internal _rewardLpToken; // The LP token for the reward token paired with MATIC
    IERC20 internal _wmaticToken; // The WMATIC token
    IUniswapV2Router02 internal _router; // Sushiswap Router to swap tokens and provide liquidity
    address[] internal swapPath;

    // Permissions
    address public manager; // Address that is able to compound the vault

    // Constants
    uint constant MAX_UNIT = (2 ** 256) - 1;
    uint constant BIG_UNIT = 10 ** 18;

    // Balances
    uint public stakingContractTokenBalance; // Total balance of tokens staked in the staking contract
    mapping(address => bool) public userStatus; // Mapping of vault users to active/inactive
    uint public vaultWeight; // Vault weight, increases as vault compounds rewards. Used for determining user vault allocaations.
    mapping(address => uint) public userStartWeights; // Vault weight when user deposited (weighted average vault weight if multiple deposits)
    mapping(address => uint) public userDepositAmounts; // Amount of tokens that the user has deposited in the contract.

    uint public rewardTokenFeeBalance; // Balance of reward tokens that are set aside for fees

    // Parameters
    uint public compoundFrequency; // number of seconds to wait between compounding
    uint public lastCompoundTime; // For calculating how recently the vault was compounded
    uint public feePercent; // Percentage fee for performance and operations (in big units of percent * 10 ** 18)

    //  -------------------- EVENTS --------------------
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Compounded(uint timestamp, uint256 amount);
    event Received(address sender, uint amount);
    
    //  -------------------- CONSTRUCTOR FUNCTION --------------------
    constructor(
        string memory name_,
        address stakingContractAddress_,
        address stakingTokenAddress_,
        address pairedTokenAddress_,
        address rewardTokenAddress_,
        address rewardTokenLpAddress_,
        address routerAddress_,
        uint compoundFrequency_,
        uint feePercent_,
        address manager_
    ) {
        // Assign initial variable values
        name = name_;
        lastCompoundTime = block.timestamp;
        stakingContract = IRaiderStaking(stakingContractAddress_);
        _stakingToken = IUniswapV2Pair(stakingTokenAddress_);
        _rewardToken = IERC20(rewardTokenAddress_);
        _rewardLpToken = IUniswapV2Pair(rewardTokenLpAddress_);
        _pairedToken = IERC20(pairedTokenAddress_);
        _router = IUniswapV2Router02(routerAddress_);
        _wmaticToken = IERC20(_router.WETH());
        compoundFrequency = compoundFrequency_;
        feePercent = feePercent_;
        manager = manager_;
        vaultWeight = BIG_UNIT;

        // Approve Reward Token and Token to Pair for LP on Router
        _pairedToken.approve(routerAddress_, MAX_UNIT);
        if (rewardTokenAddress_ != pairedTokenAddress_) {
            _rewardToken.approve(routerAddress_, MAX_UNIT);
        }

        // Approve WMATIC on the Router
        _wmaticToken.approve(routerAddress_, MAX_UNIT);

        // Approve LP Token on Router
        _stakingToken.approve(routerAddress_, MAX_UNIT);

        // Approve staking contract for LP Token
        _stakingToken.approve(stakingContractAddress_, MAX_UNIT);
    }

    //  -------------------- VIEW FUNCTIONS --------------------
    function timeSinceLastCompound() public view returns (uint) {
        return block.timestamp.sub(lastCompoundTime);
    }
    
    function totalBalance() external view returns (uint) {
        return _stakingToken.balanceOf(address(this)).add(stakingContractTokenBalance);
    }
    
    function showStakingToken() external view returns (address) {
        return address(_stakingToken);
    }

    function getUserBalance(address address_) public view returns (uint) {
        if (userStartWeights[address_] == 0) {
            return 0;
        } else {
            return userDepositAmounts[address_].mul(vaultWeight).div(userStartWeights[address_]);
        }
    }

    //  -------------------- UTILITY FUNCTIONS --------------------

    receive() external payable { // Receive function required by the Sushiswap Router
        emit Received(msg.sender, msg.value);
    }

    function isUser(address _address) public view returns(bool) {
        return userStatus[_address];
    }

    function _addUser(address _address) internal {
        userStatus[_address] = true;
    }

    function _removeUser(address _address) internal {
        userStatus[_address] = false;
    }
    
    function _stakeTokens(uint amount_) internal { // stakes the specified amount of LP tokens in the staking contract
        stakingContract.createStake(amount_);
        stakingContractTokenBalance = stakingContractTokenBalance.add(amount_);
    }

    function _removeStakedTokens(uint amount_) internal { // unstakes the specified amount of LP tokens in the staking contract
        stakingContract.removeStake(amount_);
        stakingContractTokenBalance = stakingContractTokenBalance.sub(amount_);
    }
    
    function _compound() internal whenNotPaused {
        // Avoid compounding excessively from repeated calls
        if (timeSinceLastCompound() > 10) {
            // Get outstanding rewards
            uint startingBalance = _rewardToken.balanceOf(address(this));
            stakingContract.getRewards();
            uint endingBalance = _rewardToken.balanceOf(address(this));
            rewardTokenFeeBalance = rewardTokenFeeBalance.add(
                (endingBalance.sub(startingBalance))
                .mul(feePercent)
                .div(BIG_UNIT)
            );
            uint rewardsToCompound = (_rewardToken.balanceOf(address(this))).sub(rewardTokenFeeBalance);
            if (rewardsToCompound > 0) {
        
                // Declare variables for swaps
                uint minAmountMatic;
                uint minAmountPairedToken;
                uint desiredAmountMatic;
                uint desiredAmountPairedToken;
                uint reserveA;
                uint reserveB;
                uint[] memory amounts;

                // Swap tokens to get the right amounts for providing liquidity
                if (address(_rewardToken) == address(_pairedToken)) { // RAIDER/MATIC LP Case
                    // Swap 1/2 of the reward token for MATIC
                    (reserveA, reserveB, ) = _stakingToken.getReserves();
                    minAmountMatic = _router.getAmountOut(rewardsToCompound.mul(50 * (10 ** 16)).div(BIG_UNIT), reserveB, reserveA);
                    swapPath.push(address(_rewardToken));
                    swapPath.push(address(_wmaticToken));
                    
                    amounts = _router.swapExactTokensForETH(
                        rewardsToCompound.mul(50 * (10 ** 16)).div(BIG_UNIT),
                        minAmountMatic,
                        swapPath,
                        address(this),
                        block.timestamp + 30
                    );
                    desiredAmountMatic = amounts[1];
                    delete amounts;
                    delete swapPath;

                    desiredAmountPairedToken = (_pairedToken.balanceOf(address(this))).sub(rewardTokenFeeBalance);

                } else { // AURUM/MATIC LP Case
                    // Swap the rewards for MATIC
                    (reserveA, reserveB, ) = _rewardLpToken.getReserves(); // Token A is WMATIC in all of the Raider Pairs and Token B is the _pairedToken
                    minAmountMatic = _router.getAmountOut(rewardsToCompound, reserveB, reserveA); // accounts for slippage and fees
                    swapPath.push(address(_rewardToken));
                    swapPath.push(address(_wmaticToken));

                    amounts = _router.swapExactTokensForETH(
                        rewardsToCompound, // amount of _rewardToken in
                        minAmountMatic, // minAmount of matic out
                        swapPath, // _router path
                        address(this), // address to send matic to (this contract)
                        block.timestamp + 20 // deadline for executing the swap
                    );
                    desiredAmountMatic = amounts[1].mul(50 * (10 ** 16)).div(BIG_UNIT);
                    delete amounts;
                    delete swapPath;

                    // Swap 1/2 of the MATIC for the token to pair
                    (reserveA, reserveB, ) = _stakingToken.getReserves(); // Token A is WMATIC in all of the Raider Pairs and Token B is the _pairedToken
                    minAmountPairedToken = _router.getAmountOut(desiredAmountMatic, reserveA, reserveB); // accounts for slippage and fees
                    swapPath.push(address(_wmaticToken));
                    swapPath.push(address(_pairedToken));

                    _router.swapExactETHForTokens{ value: desiredAmountMatic }(
                        minAmountPairedToken, // minimum amonut of tokens out
                        swapPath, // _router path
                        address(this), // address to send matic to (this contract)
                        block.timestamp + 40 // deadline for executing the swap
                    );
                    delete swapPath;

                    desiredAmountPairedToken = _pairedToken.balanceOf(address(this));
                }

                {
                    // Add liquidity to the LP
                    (reserveA, reserveB, ) = _stakingToken.getReserves();
                    minAmountPairedToken = _router.getAmountOut(desiredAmountMatic, reserveA, reserveB);
                    minAmountMatic = _router.quote(minAmountPairedToken, reserveB, reserveA);

                    (,, uint newStakingTokens) = _router.addLiquidityETH{ value: desiredAmountMatic }(
                        address(_pairedToken), // token to pair address
                        desiredAmountPairedToken, // desired amount of token to pair
                        minAmountPairedToken, // minimum amount of token to pair
                        minAmountMatic, // minimum amount of matic to pair - same as minimum received from swap
                        address(this), // address to receive the LP tokens (this contract)
                        block.timestamp + 60 // deadline for supplying the liquidity
                    );

                    // Update vault weight based on new staking tokens added
                    if (stakingContractTokenBalance > 0) {
                        vaultWeight = vaultWeight.mul(stakingContractTokenBalance.add(newStakingTokens)).div(stakingContractTokenBalance);
                    }
                
                    // Deposit the LP tokens in the staking contract
                    _stakeTokens(newStakingTokens);
                }

                // Emit event and update last compound time
                lastCompoundTime = block.timestamp;
                emit Compounded(lastCompoundTime, rewardsToCompound);

            }
        }
    }

    //  -------------------- MANAGER FUNCTIONS --------------------
    function compound() external payable whenNotPaused nonReentrant {
        // Require the manager role to compound the vault
        require(msg.sender == manager, "Must be manager to compound.");
        _compound();
    }

    //  -------------------- OWNER FUNCTIONS --------------------
    function setStakingContract(address stakingContractAddress_) external onlyOwner {
        stakingContract = IRaiderStaking(stakingContractAddress_);
        // Approve staking contract for LP Token
        _stakingToken.approve(stakingContractAddress_, MAX_UNIT);
    }
    
    function setStakingToken(address stakingTokenAddress_) external onlyOwner {
        _stakingToken = IUniswapV2Pair(stakingTokenAddress_);
        
        // Approve LP Token on Router
        _stakingToken.approve(address(_router), MAX_UNIT);

        // Approve staking contract for LP Token
        _stakingToken.approve(address(stakingContract), MAX_UNIT);
    }

    function setPairedToken(address pairedTokenAddress_) external onlyOwner {
        _pairedToken = IERC20(pairedTokenAddress_);
        // Approve Paired Token on Router
        _pairedToken.approve(address(_router), MAX_UNIT);
    }
    
    function setRewardToken(address rewardTokenAddress_) external onlyOwner {
        _rewardToken = IERC20(rewardTokenAddress_);
        // Approve reward token on the router
        _rewardToken.approve(address(_router), MAX_UNIT);
    }

    function setRewardLpToken(address rewardLpTokenAddress_) external onlyOwner {
        _rewardLpToken = IUniswapV2Pair(rewardLpTokenAddress_);
    }

    function setRouter(address routerAddress_) external onlyOwner {
        _router = IUniswapV2Router02(routerAddress_);

        // Approve Reward Token and Token to Pair for LP on Router
        _pairedToken.approve(routerAddress_, MAX_UNIT);
        _rewardToken.approve(routerAddress_, MAX_UNIT);

        // Approve WMATIC on the Router
        _wmaticToken.approve(routerAddress_, MAX_UNIT);

        // Approve LP Token on Router
        _stakingToken.approve(routerAddress_, MAX_UNIT);
    }

    function setManager(address managerAddress_) external onlyOwner {
        manager = managerAddress_;
    }

    function setCompoundFrequency(uint seconds_) external onlyOwner {
        compoundFrequency = seconds_;
    }

    function setFeePercent(uint percent_) external onlyOwner {
        feePercent = percent_;
    }

    function withdrawRewardTokenFees(uint amount_) external onlyOwner nonReentrant {
        require(amount_ > 0, "Cannot withdraw 0.");
        require(rewardTokenFeeBalance >= amount_, "Amount > current fee balance.");
        _rewardToken.safeTransfer(owner(), amount_);
        rewardTokenFeeBalance = rewardTokenFeeBalance.sub(amount_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //  -------------------- USER FUNCTIONS --------------------
    function deposit(uint amount_) external payable whenNotPaused nonReentrant {
        // Require the deposit to be non-zero
        require(amount_ > 0, "Cannot deposit 0.");

        // Compound the vault on deposit (required for security)
        _compound();

        // Transfer the staking tokens to the vault
        _stakingToken.transferFrom(msg.sender, address(this), amount_);
        
        // Add user to user list and update the user's deposit amount and start weight
        if(isUser(msg.sender)) {
            userStartWeights[msg.sender] = (vaultWeight.mul(userDepositAmounts[msg.sender].add(amount_))).div(getUserBalance(msg.sender).add(amount_));
        } else {
            _addUser(msg.sender);
            userStartWeights[msg.sender] = vaultWeight;        
        }
        userDepositAmounts[msg.sender] = userDepositAmounts[msg.sender].add(amount_);

        // Stake the added tokens
        _stakeTokens(amount_);

        // Emit deposit event
        emit Deposited(msg.sender, amount_);
    }
    
    function withdraw(uint amount_) external nonReentrant {
        // Require the amount be greater than zero and the sender to have a balance greater than or equal to the amount
        require(amount_ > 0, "Cannot withdraw 0.");
        require(getUserBalance(msg.sender) >= amount_, "Cannot withdraw > your balance.");

        // Remove the required amount of tokens from the staking contract
        _removeStakedTokens(amount_);

        // Deduct the proportionate amount from the user's deposit amount
        userDepositAmounts[msg.sender] = userDepositAmounts[msg.sender].sub(amount_.mul(userStartWeights[msg.sender]).div(vaultWeight));

        // Transfer the tokens to the user
        _stakingToken.transfer(msg.sender, amount_);
        emit Withdrawn(msg.sender, amount_);

        // If user's deposit amount is zero, remove from user list
        if (userDepositAmounts[msg.sender] == 0) {
            userStartWeights[msg.sender] = 0;
            _removeUser(msg.sender);
        }
    }

    function withdrawAll() external payable nonReentrant {
        // Require the sender to have a non-zero balance
        require(getUserBalance(msg.sender) > 0, "Your balance is 0.");

        // Compound the vault to get outstanding rewards if withdrawing all
        _compound();

        // Get the user's final balance
        uint userFinalBalance = getUserBalance(msg.sender);

        // Remove the user's tokens from the staking contract
        _removeStakedTokens(userFinalBalance);

        // Zero out the user's balance
        userDepositAmounts[msg.sender] = 0;
        userStartWeights[msg.sender] = 0;

        // Transfer the tokens to the user
        _stakingToken.transfer(msg.sender, userFinalBalance);
        emit Withdrawn(msg.sender, userFinalBalance);

        // Remove from user list
        _removeUser(msg.sender);
    }
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
    constructor() {
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

    constructor() {
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