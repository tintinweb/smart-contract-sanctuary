// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PrivateSaleWithFeeSharing
 * @notice It handles the private sale for LOOKS tokens (against ETH) and the fee-sharing
 * mechanism for sale participants. It uses a 3-tier system with different
 * costs (in ETH) to participate. The exchange rate is expressed as the price of 1 ETH in LOOKS token.
 * It is the same for all three tiers.
 */
contract PrivateSaleWithFeeSharing is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum SalePhase {
        Pending, // Pending (owner sets up parameters)
        Deposit, // Deposit (sale is in progress)
        Over, // Sale is over, prior to staking
        Staking, // Staking starts
        Withdraw // Withdraw opens
    }

    struct UserInfo {
        uint256 rewardsDistributedToAccount; // reward claimed by the sale participant
        uint8 tier; // sale tier (e.g., 1/2/3)
        bool hasDeposited; // whether the user has participated
        bool hasWithdrawn; // whether the user has withdrawn (after the end of the fee-sharing period)
    }

    // Number of eligible tiers in the private sale
    uint8 public constant NUMBER_TIERS = 3;

    IERC20 public immutable looksRareToken;

    IERC20 public immutable rewardToken;

    // Maximum blocks for withdrawal
    uint256 public immutable MAX_BLOCK_FOR_WITHDRAWAL;

    // Total LOOKS expected to be distributed
    uint256 public immutable TOTAL_LOOKS_DISTRIBUTED;

    // Current sale phase (uint8)
    SalePhase public currentPhase;

    // Block where participants can withdraw the LOOKS tokens
    uint256 public blockForWithdrawal;

    // Price of WETH in LOOKS for the sale
    uint256 public priceOfETHInLOOKS;

    // Total amount committed in the sale (in ETH)
    uint256 public totalAmountCommitted;

    // Total reward tokens (i.e., WETH) distributed across stakers
    uint256 public totalRewardTokensDistributedToStakers;

    // Keeps track of the cost to join the sale for a given tier
    mapping(uint8 => uint256) public allocationCostPerTier;

    // Keeps track of the number of whitelisted participants for each tier
    mapping(uint8 => uint256) public numberOfParticipantsForATier;

    // Keeps track of user information (e.g., tier, amount collected, participation)
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint8 tier);
    event Harvest(address indexed user, uint256 amount);
    event NewSalePhase(SalePhase newSalePhase);
    event NewAllocationCostPerTier(uint8 tier, uint256 allocationCostInETH);
    event NewBlockForWithdrawal(uint256 blockForWithdrawal);
    event NewPriceOfETHInLOOKS(uint256 price);
    event UsersWhitelisted(address[] users, uint8 tier);
    event UserRemoved(address user);
    event Withdraw(address indexed user, uint8 tier, uint256 amount);

    /**
     * @notice Constructor
     * @param _looksRareToken address of the LOOKS token
     * @param _rewardToken address of the reward token
     * @param _maxBlockForWithdrawal maximum block for withdrawal
     * @param _totalLooksDistributed total number of LOOKS tokens to distribute
     */
    constructor(
        address _looksRareToken,
        address _rewardToken,
        uint256 _maxBlockForWithdrawal,
        uint256 _totalLooksDistributed
    ) {
        require(_maxBlockForWithdrawal > block.number, "Owner: MaxBlockForWithdrawal must be after block number");

        looksRareToken = IERC20(_looksRareToken);
        rewardToken = IERC20(_rewardToken);
        blockForWithdrawal = _maxBlockForWithdrawal;

        MAX_BLOCK_FOR_WITHDRAWAL = _maxBlockForWithdrawal;
        TOTAL_LOOKS_DISTRIBUTED = _totalLooksDistributed;
    }

    /**
     * @notice Deposit ETH to this contract
     */
    function deposit() external payable nonReentrant {
        require(currentPhase == SalePhase.Deposit, "Deposit: Phase must be Deposit");
        require(userInfo[msg.sender].tier != 0, "Deposit: Not whitelisted");
        require(!userInfo[msg.sender].hasDeposited, "Deposit: Has deposited");
        require(msg.value == allocationCostPerTier[userInfo[msg.sender].tier], "Deposit: Wrong amount");

        userInfo[msg.sender].hasDeposited = true;
        totalAmountCommitted += msg.value;

        emit Deposit(msg.sender, userInfo[msg.sender].tier);
    }

    /**
     * @notice Harvest WETH
     */
    function harvest() external nonReentrant {
        require(currentPhase == SalePhase.Staking, "Harvest: Phase must be Staking");
        require(userInfo[msg.sender].hasDeposited, "Harvest: User not eligible");

        uint256 totalTokensReceived = rewardToken.balanceOf(address(this)) + totalRewardTokensDistributedToStakers;

        uint256 pendingRewardsInWETH = ((totalTokensReceived * allocationCostPerTier[userInfo[msg.sender].tier]) /
            totalAmountCommitted) - userInfo[msg.sender].rewardsDistributedToAccount;

        // Revert if amount to transfer is equal to 0
        require(pendingRewardsInWETH != 0, "Harvest: Nothing to transfer");

        userInfo[msg.sender].rewardsDistributedToAccount += pendingRewardsInWETH;
        totalRewardTokensDistributedToStakers += pendingRewardsInWETH;

        // Transfer funds to account
        rewardToken.safeTransfer(msg.sender, pendingRewardsInWETH);

        emit Harvest(msg.sender, pendingRewardsInWETH);
    }

    /**
     * @notice Withdraw LOOKS + pending WETH
     */
    function withdraw() external nonReentrant {
        require(currentPhase == SalePhase.Withdraw, "Withdraw: Phase must be Withdraw");
        require(userInfo[msg.sender].hasDeposited, "Withdraw: User not eligible");
        require(!userInfo[msg.sender].hasWithdrawn, "Withdraw: Has already withdrawn");

        // Final harvest logic
        {
            uint256 totalTokensReceived = rewardToken.balanceOf(address(this)) + totalRewardTokensDistributedToStakers;
            uint256 pendingRewardsInWETH = ((totalTokensReceived * allocationCostPerTier[userInfo[msg.sender].tier]) /
                totalAmountCommitted) - userInfo[msg.sender].rewardsDistributedToAccount;

            // Skip if equal to 0
            if (pendingRewardsInWETH > 0) {
                userInfo[msg.sender].rewardsDistributedToAccount += pendingRewardsInWETH;
                totalRewardTokensDistributedToStakers += pendingRewardsInWETH;

                // Transfer funds to sender
                rewardToken.safeTransfer(msg.sender, pendingRewardsInWETH);

                emit Harvest(msg.sender, pendingRewardsInWETH);
            }
        }

        // Update status to withdrawn
        userInfo[msg.sender].hasWithdrawn = true;

        // Calculate amount of LOOKS to transfer based on the tier
        uint256 looksAmountToTransfer = allocationCostPerTier[userInfo[msg.sender].tier] * priceOfETHInLOOKS;

        // Transfer LOOKS token to sender
        looksRareToken.safeTransfer(msg.sender, looksAmountToTransfer);

        emit Withdraw(msg.sender, userInfo[msg.sender].tier, looksAmountToTransfer);
    }

    /**
     * @notice Update sale phase to withdraw after the sale lock has passed.
     * It can called by anyone.
     */
    function updateSalePhaseToWithdraw() external {
        require(currentPhase == SalePhase.Staking, "Phase: Must be Staking");
        require(block.number >= blockForWithdrawal, "Phase: Too early to update sale status");

        // Update phase to Withdraw
        currentPhase = SalePhase.Withdraw;

        emit NewSalePhase(SalePhase.Withdraw);
    }

    /**
     * @notice Remove a user from the whitelist
     * @param _user address of the user
     */
    function removeUserFromWhitelist(address _user) external onlyOwner {
        require(currentPhase == SalePhase.Pending, "Owner: Phase must be Pending");
        require(userInfo[_user].tier != 0, "Owner: Tier not set for user");

        numberOfParticipantsForATier[userInfo[_user].tier]--;
        userInfo[_user].tier = 0;

        emit UserRemoved(_user);
    }

    /**
     * @notice Set allocation per tier
     * @param _tier tier of sale
     * @param _allocationCostInETH allocation in ETH for the tier
     */
    function setAllocationCostPerTier(uint8 _tier, uint256 _allocationCostInETH) external onlyOwner {
        require(currentPhase == SalePhase.Pending, "Owner: Phase must be Pending");
        require(_tier > 0 && _tier <= NUMBER_TIERS, "Owner: Tier outside of range");

        allocationCostPerTier[_tier] = _allocationCostInETH;

        emit NewAllocationCostPerTier(_tier, _allocationCostInETH);
    }

    /**
     * @notice Update block deadline for withdrawal of LOOKS
     * @param _blockForWithdrawal block for withdrawing LOOKS for sale participants
     */
    function setBlockForWithdrawal(uint256 _blockForWithdrawal) external onlyOwner {
        require(
            _blockForWithdrawal <= MAX_BLOCK_FOR_WITHDRAWAL,
            "Owner: Block for withdrawal must be lower than max block for withdrawal"
        );

        blockForWithdrawal = _blockForWithdrawal;

        emit NewBlockForWithdrawal(_blockForWithdrawal);
    }

    /**
     * @notice Set price of 1 ETH in LOOKS
     * @param _priceOfETHinLOOKS price of 1 ETH in LOOKS
     */
    function setPriceOfETHInLOOKS(uint256 _priceOfETHinLOOKS) external onlyOwner {
        require(currentPhase == SalePhase.Pending, "Owner: Phase must be Pending");
        priceOfETHInLOOKS = _priceOfETHinLOOKS;

        emit NewPriceOfETHInLOOKS(_priceOfETHinLOOKS);
    }

    /**
     * @notice Update sale phase for the first two phases
     * @param _newSalePhase SalePhase (uint8)
     */
    function updateSalePhase(SalePhase _newSalePhase) external onlyOwner {
        if (_newSalePhase == SalePhase.Deposit) {
            require(currentPhase == SalePhase.Pending, "Owner: Phase must be Pending");

            // Risk checks
            require(priceOfETHInLOOKS > 0, "Owner: Exchange rate must be > 0");
            require(getMaxAmountLOOKSToDistribute() == TOTAL_LOOKS_DISTRIBUTED, "Owner: Wrong amount of LOOKS");
            require(
                looksRareToken.balanceOf(address(this)) >= TOTAL_LOOKS_DISTRIBUTED,
                "Owner: Not enough LOOKS in the contract"
            );
            require(blockForWithdrawal > block.number, "Owner: Block for withdrawal wrongly set");
        } else if (_newSalePhase == SalePhase.Over) {
            require(currentPhase == SalePhase.Deposit, "Owner: Phase must be Deposit");
        } else {
            revert("Owner: Cannot update to this phase");
        }

        // Update phase to the new sale phase
        currentPhase = _newSalePhase;

        emit NewSalePhase(_newSalePhase);
    }

    /**
     * @notice Withdraw the total commited amount (in ETH) and any LOOKS surplus.
     * It also updates the sale phase to Staking phase.
     */
    function withdrawCommittedAmount() external onlyOwner nonReentrant {
        require(currentPhase == SalePhase.Over, "Owner: Phase must be Over");

        // Transfer ETH to the owner
        (bool success, ) = msg.sender.call{value: totalAmountCommitted}("");
        require(success, "Owner: Transfer fail");

        // If some tiered users did not participate, transfer the LOOKS surplus to contract owner
        if (totalAmountCommitted * priceOfETHInLOOKS < (TOTAL_LOOKS_DISTRIBUTED)) {
            uint256 tokenAmountToReturnInLOOKS = TOTAL_LOOKS_DISTRIBUTED - (totalAmountCommitted * priceOfETHInLOOKS);
            looksRareToken.safeTransfer(msg.sender, tokenAmountToReturnInLOOKS);
        }

        // Update phase status to Staking
        currentPhase = SalePhase.Staking;

        emit NewSalePhase(SalePhase.Staking);
    }

    /**
     * @notice Whitelist a list of user addresses for a given tier
     * It updates the sale phase to staking phase.
     * @param _users array of user addresses
     * @param _tier tier for the array of users
     */
    function whitelistUsers(address[] calldata _users, uint8 _tier) external onlyOwner {
        require(currentPhase == SalePhase.Pending, "Owner: Phase must be Pending");
        require(_tier > 0 && _tier <= NUMBER_TIERS, "Owner: Tier outside of range");

        for (uint256 i = 0; i < _users.length; i++) {
            require(userInfo[_users[i]].tier == 0, "Owner: Tier already set");
            userInfo[_users[i]].tier = _tier;
        }

        // Adjust count of participants for the given tier
        numberOfParticipantsForATier[_tier] += _users.length;

        emit UsersWhitelisted(_users, _tier);
    }

    /**
     * @notice Retrieve amount of reward token (WETH) a user can collect
     * @param user address of the user who participated in the private sale
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        if (userInfo[user].hasDeposited == false || userInfo[user].hasWithdrawn) {
            return 0;
        }

        uint256 totalTokensReceived = rewardToken.balanceOf(address(this)) + totalRewardTokensDistributedToStakers;
        uint256 pendingRewardsInWETH = ((totalTokensReceived * allocationCostPerTier[userInfo[user].tier]) /
            totalAmountCommitted) - userInfo[user].rewardsDistributedToAccount;

        return pendingRewardsInWETH;
    }

    /**
     * @notice Retrieve max amount to distribute (in LOOKS) for sale
     */
    function getMaxAmountLOOKSToDistribute() public view returns (uint256 maxAmountCollected) {
        for (uint8 i = 1; i <= NUMBER_TIERS; i++) {
            maxAmountCollected += (allocationCostPerTier[i] * numberOfParticipantsForATier[i]);
        }

        return maxAmountCollected * priceOfETHInLOOKS;
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