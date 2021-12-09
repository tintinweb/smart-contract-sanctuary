// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "interfaces/IStakingRewards.sol";
import "interfaces/IUniversalOneSidedFarm.sol";
import "interfaces/IUniswapV2Router.sol";
import "interfaces/IUniswapV2ERC20.sol";
import "./libraries/TransferHelper.sol";

contract QuickSwapFarmsStrategy is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How much asset the user has provided.
        uint256 lpAmount; //How many LP tokens have been added for the user
        uint256 rewardTokensDebt; // Reward Tokens debited.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward tokens = (user.lpAmount * pool.accRewardTokensPerShare) - user.rewardTokensDebt
        //
        // Whenever a user deposits or withdraws asset tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardTokensPerShare`  gets updated.
        //   2. User receives the pending rewards sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. Any added LPs update the user's lpAmount.
        //   5. User's `rewardTokensDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 accRewardTokensPerShare; // Accumulated dQUICK per share times 1e12.
    }

    struct RewardsTransferMode {
        bool isRewardTokenEnabled;
    }

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    PoolInfo public poolInfo;

    RewardsTransferMode public rewardsTransferMode;

    // whitelisted liquidityManagers
    mapping(address => bool) public liquidityManagers;

    IERC20 public asset; //same which is used in stakingRewardsContract
    IERC20 public secondaryAsset; //the token used as tokenB when providing liquidity and as part of quickSwapLP.
    IERC20 public quick; //quick token
    IERC20 public rewardToken; //dquick token
    IUniswapV2ERC20 public quickSwapLP; //quickSwapLP
    IStakingRewards public stakingRewardsContract; //StakingRewards contract of QuickSwap
    IUniswapV2Router public quickSwapRouter; //quickSwap Router
    IUniversalOneSidedFarm public universalOneSidedFarm; //SingleSidedLiquidity Contract
    address public feeAddress; //feeAddress

    uint256 public strategyWithdrawalFeeBP = 0;
    uint256 public strategyDepositFeeBP = 0;
    uint256 public totalInputTokensStaked = 0;
    uint256 private constant DEADLINE =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    event LiquidityManagerStatus(address liquidityManager, bool status);
    event StrategyPoolUpdated(uint256 indexed accRewardTokensPerShare);
    event StrategyDeposit(address indexed user, uint256 amount);
    event StrategyWithdraw(address indexed user, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed feeAddress);
    event RescueAsset(address liquidityManager, uint256 rescuedAssetAmount);

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "No zero address");
        _;
    }

    modifier ensureValidTokenAddress(address _token) {
        require(_token != address(0), "No zero address");
        require(_token == address(asset), "Invalid token for deposit/withdraw");
        _;
    }

    modifier ensureValidLiquidityManager(address addressToCheck) {
        require(addressToCheck != address(0), "No zero address");
        require(liquidityManagers[addressToCheck], "Invalid Liquidity Manager");
        _;
    }

    /**
     * @notice Creates a new QuickSwap Strategy Contract
     * @param _asset same which is used in stakingRewardsContract
     * @param _secondaryAsset the token used as tokenB when providing liquidity and as part of quickSwapLP.
     * @param _quick quickToken address
     * @param _rewardToken dQUICK token address
     * @param _quickSwapLP; quickSwapLP address
     * @param _stakingRewardsContract; staking rewards contract used by quickSwapLP
     * @param _universalOneSidedFarm; SingleSidedLiquidity Contract used for depositing liquidity
     * @param _quickSwapRouter; quickSwap router
     * @param _feeAddress fee address for transferring residues and reward tokens
     * @dev deployer of contract is set as owner
     */
    constructor(
        IERC20 _asset,
        IERC20 _secondaryAsset,
        IERC20 _quick,
        IERC20 _rewardToken,
        IUniswapV2ERC20 _quickSwapLP,
        IStakingRewards _stakingRewardsContract,
        IUniversalOneSidedFarm _universalOneSidedFarm,
        IUniswapV2Router _quickSwapRouter,
        address _feeAddress
    ) {
        asset = _asset;
        secondaryAsset = _secondaryAsset;
        quick = _quick;
        rewardToken = _rewardToken;
        quickSwapLP = _quickSwapLP;
        stakingRewardsContract = _stakingRewardsContract;
        universalOneSidedFarm = _universalOneSidedFarm;
        quickSwapRouter = _quickSwapRouter;
        feeAddress = _feeAddress;
        rewardsTransferMode.isRewardTokenEnabled = true;
    }

    /**
     * @notice Updates the liquidity manager for the strategy
     * @param _liquidityManager Address of the liquidity manager
     * @param _status status is if we need to enable/disable this liquidity manager
     * @dev Only owner can call and update the liquidity manager
     */
    function updateLiquidityManager(address _liquidityManager, bool _status)
        external
        onlyOwner
        ensureNonZeroAddress(_liquidityManager)
    {
        updatePool();
        liquidityManagers[_liquidityManager] = _status;
        emit LiquidityManagerStatus(_liquidityManager, _status);
    }

    /**
     * @notice Updates the Staking Contract used by QuickSwap
     * @param _stakingRewardsContract Address of the Staking Contract
     * @dev Only owner can call and update the Staking Contract address
     */
    function updateQuickSwapStakingRewardsContract(IStakingRewards _stakingRewardsContract)
        external
        onlyOwner
        ensureNonZeroAddress(address(_stakingRewardsContract))
    {
        updatePool();
        stakingRewardsContract = _stakingRewardsContract;
    }

    /**
     * @notice Updates the UniversalOneSidedFarm Contract.
     * @param _universalOneSidedFarm Address of the UniversalOneSidedFarm Contract
     * @dev Only owner can call and update the UniversalOneSidedFarm Contract address
     */
    function updateUniversalOneSidedFarm(IUniversalOneSidedFarm _universalOneSidedFarm)
        external
        onlyOwner
        ensureNonZeroAddress(address(_universalOneSidedFarm))
    {
        updatePool();
        universalOneSidedFarm = _universalOneSidedFarm;
    }

    /**
     * @notice Updates the QuickSwap Router.
     * @param _quickSwapRouter Address of the QuickSwap Router
     * @dev Only owner can call and update the QuickSwap Router address
     */
    function updateQuickSwapRouter(IUniswapV2Router _quickSwapRouter)
        external
        onlyOwner
        ensureNonZeroAddress(address(_quickSwapRouter))
    {
        updatePool();
        quickSwapRouter = _quickSwapRouter;
    }

    /**
     * @notice Updates the QuickSwap LP Token Address.
     * @param _quickSwapLP Address of the QuickSwap LP
     * @dev Only owner can call and update the QuickSwap LP address
     */
    function updateQuickSwapLP(IUniswapV2ERC20 _quickSwapLP)
        external
        onlyOwner
        ensureNonZeroAddress(address(_quickSwapLP))
    {
        updatePool();
        quickSwapLP = _quickSwapLP;
    }

    /**
     * @notice Can be used by the owner to enable/disable mode for accumulated reward token rewards being sent to user
     * @param _isRewardTokenEnabled Boolean flag if we need to enable/disable the reward transfer mode for reward tokens
     * @dev Only owner can call and update this mode.
     */
    function updateRewardTokenRewardsTransferMode(bool _isRewardTokenEnabled) external onlyOwner {
        updatePool();
        rewardsTransferMode.isRewardTokenEnabled = _isRewardTokenEnabled;
    }

    /**
     * @notice Can be used by the owner to update the address for reward token
     * @param _rewardToken ERC20 address for the new reward token
     * @dev Only owner can call and update the rewardToken.
     */
    function updateRewardToken(IERC20 _rewardToken)
        external
        onlyOwner
        ensureNonZeroAddress(address(_rewardToken))
    {
        updatePool();
        rewardToken = _rewardToken;
    }

    /**
     * @notice Can be used by the owner to update the withdrawal fee.
     * @param _strategyWithdrawalFeeBP New withdrawal fee of the quickswap staking contracts in basis points
     * @dev Only owner can call and update the quickswap withdrawal fee.
     */
    function updateStrategyWithdrawalFee(uint256 _strategyWithdrawalFeeBP) external onlyOwner {
        updatePool();
        strategyWithdrawalFeeBP = _strategyWithdrawalFeeBP;
    }

    /**
     * @notice Can be used by the owner to update the deposit fee. Currently there is no deposit fee
     * @param _strategyDepositFeeBP New deposit fee of the quickswap staking contracts in basis points
     * @dev Only owner can call and update the quickswap deposit fee.
     */
    function updateStrategyDepositFee(uint256 _strategyDepositFeeBP) external onlyOwner {
        updatePool();
        strategyDepositFeeBP = _strategyDepositFeeBP;
    }

    /**
     * @notice Update fee address
     * @param _feeAddress New fee address for receiving the residue rewards
     * @dev Only owner can update the fee address
     */
    function setFeeAddress(address _feeAddress)
        external
        ensureNonZeroAddress(_feeAddress)
        onlyOwner
    {
        updatePool();
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    /**
     * @notice transfer accumulated asset. Shouldn't be called since this will transfer community's residue asset to feeAddress
     * @dev Only owner can call and claim the assets residue
     */
    function transferAssetResidue() external onlyOwner {
        updatePool();
        uint256 assetResidue = asset.balanceOf(address(this));
        TransferHelper.safeTransfer(address(asset), feeAddress, assetResidue);
    }

    /**
     * @notice transfer accumulated secondary asset. Shouldn't be called since this will transfer community's residue secondary asset to feeAddress
     * @dev Only owner can call and claim the secondary asset residue
     */
    function transferSecondaryAssetResidue() external onlyOwner {
        updatePool();
        uint256 secondaryAssetResidue = secondaryAsset.balanceOf(address(this));
        TransferHelper.safeTransfer(address(secondaryAsset), feeAddress, secondaryAssetResidue);
    }

    /**
     * @notice transfer accumulated reward tokens. Shouldn't be called since this will transfer community's reward tokens to feeAddress
     * @dev Only owner can call and claim the reward tokens residue
     */
    function transferRewardTokenRewards() external onlyOwner {
        updatePool();
        uint256 rewardTokenRewards = rewardToken.balanceOf(address(this));
        TransferHelper.safeTransfer(address(rewardToken), feeAddress, rewardTokenRewards);
    }

    /**
     * @dev View function to see pending rewards by QUICK Swap Staking Contracts.
     */
    function getStakingRewards() public view returns (uint256 pendingRewards) {
        pendingRewards = stakingRewardsContract.earned(address(this));
    }

    /**
     * @dev View function to get total LP staked in Staking Contracts.
     */
    function getTotalLPStaked() public view returns (uint256 totalLPStaked) {
        totalLPStaked = stakingRewardsContract.balanceOf(address(this));
    }

    /**
     * @dev function to claim dQUICK rewards
     */
    function _claimRewards() internal {
        stakingRewardsContract.getReward();
    }

    /**
     * @dev function to deposit asset from strategy to Quickswap Staking Contract.
     */
    function _depositAsset(uint256 _amount) internal returns (uint256 lpReceived) {
        asset.safeApprove(address(universalOneSidedFarm), _amount);
        lpReceived = universalOneSidedFarm.poolLiquidity(
            address(this),
            address(asset),
            _amount,
            address(quickSwapLP),
            address(asset),
            1
        );
        require(lpReceived > 0, "Error in providing liquidity");
        IERC20(address(quickSwapLP)).safeApprove(address(stakingRewardsContract), lpReceived);
        stakingRewardsContract.stake(lpReceived);
    }

    /**
     * @dev function to withdraw asset from Quickswap Stakign Contract to strategy
     */
    function _withdrawAsset(uint256 _lpAmountToWithdraw) internal returns (uint256 assetWithdrawn) {
        stakingRewardsContract.withdraw(_lpAmountToWithdraw);
        IERC20(address(quickSwapLP)).safeApprove(address(quickSwapRouter), _lpAmountToWithdraw);
        (uint256 assetAmountReceived, uint256 secondaryAssetAmountReceived) = quickSwapRouter
            .removeLiquidity(
                address(asset),
                address(secondaryAsset),
                _lpAmountToWithdraw,
                1,
                1,
                address(this),
                DEADLINE
            );
        uint256 swappedAmountReceived = _swapToken(
            secondaryAsset,
            asset,
            secondaryAssetAmountReceived
        );
        assetWithdrawn = assetAmountReceived.add(swappedAmountReceived);
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _fromToken The token address to swap from.
    @param _toToken The token address to swap to.
    @param _tokenAmount The amount of from tokens to swap
    @return swappedAmountReceived The quantity of tokens bought
    */
    function _swapToken(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _tokenAmount
    ) internal returns (uint256 swappedAmountReceived) {
        _fromToken.safeApprove(address(quickSwapRouter), 0);
        _fromToken.safeApprove(address(quickSwapRouter), _tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(_fromToken);
        path[1] = address(_toToken);

        swappedAmountReceived = quickSwapRouter.swapExactTokensForTokens(
            _tokenAmount,
            1,
            path,
            address(this),
            DEADLINE
        )[path.length - 1];

        require(swappedAmountReceived > 0, "Error Swapping Tokens");
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param _user Address of the user to see his pending rewards
     */
    function getPendingRewards(address _user) external view returns (uint256 pendingRewardTokens) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokensPerShare = pool.accRewardTokensPerShare;
        uint256 totalLPStaked = getTotalLPStaked();

        uint256 pendingRewards = getStakingRewards();

        if (totalLPStaked != 0) {
            if (rewardsTransferMode.isRewardTokenEnabled) {
                accRewardTokensPerShare = accRewardTokensPerShare.add(
                    pendingRewards.mul(1e12).div(totalLPStaked)
                );
            }
        }

        pendingRewardTokens = user.lpAmount.mul(accRewardTokensPerShare).div(1e12).sub(
            user.rewardTokensDebt
        );
    }

    /**
     * @notice Update reward variables of the pool to be up-to-date. This also claims the rewards generated from staking
     */
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        uint256 totalLPStaked = getTotalLPStaked();

        if (totalLPStaked == 0) {
            return;
        }

        uint256 pendingRewards = getStakingRewards();
        if (pendingRewards > 0) {
            _claimRewards();
        }

        if (rewardsTransferMode.isRewardTokenEnabled) {
            pool.accRewardTokensPerShare = pool.accRewardTokensPerShare.add(
                pendingRewards.mul(1e12).div(totalLPStaked)
            );
        }

        emit StrategyPoolUpdated(pool.accRewardTokensPerShare);
    }

    /**
     * @notice function to deposit asset to quickswap farms.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token deposited.
     * @param _user Address of the user who is depositing the asset
     * @dev Can only be called from the liquidity manager
     */
    function deposit(
        address _token,
        uint256 _amount,
        address _user
    )
        external
        ensureValidTokenAddress(_token)
        ensureNonZeroAddress(_user)
        ensureValidLiquidityManager(msg.sender)
        nonReentrant
        returns (uint256 depositedAmount)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        updatePool();
        _transferPendingRewards(_user);
        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            uint256 lpDeposited = _depositAsset(_amount);
            user.lpAmount = user.lpAmount.add(lpDeposited);
            depositedAmount = _amount;
        }
        totalInputTokensStaked = totalInputTokensStaked.add(_amount);
        user.rewardTokensDebt = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12);
        emit StrategyDeposit(_user, _amount);
    }

    /**
     * @notice function to withdraw asset from quickswap farms.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @param _amount amount of asset token the user wants to withdraw.
     * @param _user Address of the user who is withdrawing the asset
     * @dev Can only be called from the liquidity manager
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _user
    )
        external
        ensureValidTokenAddress(_token)
        ensureNonZeroAddress(_user)
        ensureValidLiquidityManager(msg.sender)
        nonReentrant
        returns (uint256 withdrawnAmount)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        _transferPendingRewards(_user);
        if (_amount > 0) {
            uint256 lpAmountToWithdraw = _amount.mul(user.lpAmount).div(user.amount);
            user.amount = user.amount.sub(_amount);
            user.lpAmount = user.lpAmount.sub(lpAmountToWithdraw);
            withdrawnAmount = _withdrawAsset(lpAmountToWithdraw);
            IERC20(_token).safeApprove(address(msg.sender), withdrawnAmount);
        }
        totalInputTokensStaked = totalInputTokensStaked.sub(_amount);
        user.rewardTokensDebt = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12);
        emit StrategyWithdraw(_user, _amount);
    }

    /**
     * @dev Function to transfer pending rewards (rewardToken) to the user.
     */
    function _transferPendingRewards(address _user) internal {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        uint256 pendingRewardTokens = user.lpAmount.mul(pool.accRewardTokensPerShare).div(1e12).sub(
            user.rewardTokensDebt
        );
        if (rewardsTransferMode.isRewardTokenEnabled && pendingRewardTokens > 0) {
            TransferHelper.safeTransfer(address(rewardToken), _user, pendingRewardTokens);
        }
    }

    /**
     * @notice function to withdraw all asset and transfer back to liquidity holder.
     * @param _token Address of the token. (Should be the same as the asset token)
     * @dev Can only be called from the liquidity manager by the owner
     */
    function rescueFunds(address _token)
        external
        ensureValidTokenAddress(_token)
        ensureValidLiquidityManager(msg.sender)
        returns (uint256 rescuedAssetAmount)
    {
        updatePool();
        uint256 totalLPStaked = getTotalLPStaked();

        if (totalLPStaked > 0) {
            _withdrawAsset(totalLPStaked);
            rescuedAssetAmount = asset.balanceOf(address(this));
            asset.safeApprove(address(msg.sender), rescuedAssetAmount);
            emit RescueAsset(msg.sender, rescuedAssetAmount);
        }
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

    constructor () internal {
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
pragma solidity >=0.6.0 <0.8.0;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claimDate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardRate() external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IUniversalOneSidedFarm {
    function poolLiquidity(
        address _userAddress,
        address _fromToken,
        uint256 _fromTokenAmount,
        address _pairAddress,
        address _toToken,
        uint256 _slippageAdjustedMinLP
    ) external payable returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
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