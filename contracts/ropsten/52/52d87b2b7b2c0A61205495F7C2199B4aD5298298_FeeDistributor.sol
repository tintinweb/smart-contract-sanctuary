// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author crypt0s0nic
/// @title Fee distributor for StellarInu token
contract FeeDistributor is Ownable, ReentrancyGuard {
    event DividendClaimed(address indexed receiver, uint256 amount);

    // StellarInu token
    // CA: 0xfde57fee4bcca80485714bd640d6e5afe8ac4d66
    IERC20 public token;

    // Share and dividends variables
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 1e36;

    uint256 public rewardBalance = 0;

    // Fee configuration variables
    uint256 public marketingFee = 70;
    uint256 public nftFee = 10;
    uint256 public rewardFee = 20;
    uint256 public totalFee = 100;

    address public marketingFeeReceiver;
    address public nftFeeReceiver;

    uint256 public feeThreshold = 1 ether;

    /// @param _token an ERC20 token address
    /// @param _marketingFeeReceiver the address to receive marketing fee
    /// @param _nftFeeReceiver the address to receive NFT staking fee
    constructor(
        IERC20 _token,
        address _marketingFeeReceiver,
        address _nftFeeReceiver
    ) {
        token = _token;
        marketingFeeReceiver = _marketingFeeReceiver;
        nftFeeReceiver = _nftFeeReceiver;
    }

    /// @notice Allow contract to receive ether
    /// @dev Only accept ether from StellarInu token address
    /// Register shares and dividends for reward
    /// If the contract balance reaches a threshold, distributes the marketing and NFT staking fees
    receive() external payable nonReentrant {
        if (msg.sender != address(token)) return;

        setShare(tx.origin, token.balanceOf(tx.origin));

        uint256 rewardAmt = (msg.value * rewardFee) / totalFee;
        totalDividends += rewardAmt;
        dividendsPerShare += ((dividendsPerShareAccuracyFactor * rewardAmt) / totalShares);
        rewardBalance += rewardAmt;

        if (address(this).balance >= feeThreshold) distributeFees();
    }

    /// @notice Set marketing and NFT staking fees distribution threshold
    /// @dev total fee must be posittive to avoid divided by zero error
    /// Called by owner only
    /// @param _marketingFee the marketing fee in wei
    /// @param _nftFee the NFT staking fee in wei
    /// @param _rewardFee the reward fee in wei
    function setFees(
        uint256 _marketingFee,
        uint256 _nftFee,
        uint256 _rewardFee
    ) external onlyOwner {
        marketingFee = _marketingFee;
        nftFee = _nftFee;
        rewardFee = _rewardFee;
        totalFee = _marketingFee + _nftFee + _rewardFee;
        require(totalFee > 0, "FD::setFees: INVALID_FEES");
    }

    /// @notice Set marketing and NFT staking fees receiver address
    /// @dev `_marketingFeeReceiver` and `_nftFeeReceiver` must not be 0x0
    /// Called by owner only
    /// @param _marketingFeeReceiver the marketing fee receiver address
    /// @param _nftFeeReceiver the NFT staking fee receiver address
    function setFeeReceivers(address _marketingFeeReceiver, address _nftFeeReceiver) external onlyOwner {
        require(
            _marketingFeeReceiver != address(0) && _nftFeeReceiver != address(0),
            "FD::setFeeReceivers: BURN_ADDRESS"
        );
        marketingFeeReceiver = _marketingFeeReceiver;
        nftFeeReceiver = _nftFeeReceiver;
    }

    /// @notice Set marketing and NFT staking fees distribution threshold
    /// @dev `_amount` must be positive
    /// Called by owner only
    /// @param _amount the threshold in wei
    function setFeeThreshold(uint256 _amount) external onlyOwner {
        require(_amount > 0, "FD::setFeeThreshold: INVALID_AMOUNT");
        feeThreshold = _amount;
    }

    /// @notice Set shares to multiple shareholders
    /// @dev `_shareholders` and `_amounts` must have the same length
    /// Should be called once when contract is deployed to avoid messing up with the rewards
    /// Called by owner only
    /// @param _shareholders addresses of the shareholders
    /// @param _amounts balances of the shareholders
    function setShares(address[] calldata _shareholders, uint256[] calldata _amounts) external onlyOwner {
        require(_shareholders.length == _amounts.length, "FD::setShares: INVALID_INPUT");
        for (uint256 i = 0; i < _shareholders.length; i++) {
            setShare(_shareholders[i], _amounts[i]);
        }
    }

    /// @notice Private function to set share and reset share amount to input amount
    /// @param shareholder address of the shareholder
    /// @param amount the shares of the shareholder
    function setShare(address shareholder, uint256 amount) private {
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    /// @notice Allow contract owner to claim marketing and NFT staking fees
    /// @dev It reverts if both marketing and nft fees are 0
    /// It reverts if current balance of this contract is enough to pay reward only
    /// Calls distributeFees internally
    /// Called by owner only
    function claimFees() external onlyOwner {
        require(marketingFee > 0 || nftFee > 0, "FD::claimFees: INVALID_FEE");
        require(address(this).balance > rewardBalance, "FD::claimFees: INSUFFICIENT_BALANCE");
        distributeFees();
    }

    /// @notice Private function to distribute fees to marketing and NFT staking addresses
    /// @dev It doesn't revert to avoid failure in the functions invoking this function
    function distributeFees() private {
        if (totalFee <= 0) return;
        if (address(this).balance <= rewardBalance) return;

        uint256 amount = address(this).balance - rewardBalance;
        uint256 nftAmount = (amount * nftFee) / (nftFee + marketingFee);
        uint256 marketingAmount = amount - nftAmount;
        if (nftFee > 0) safeTransferETH(nftFeeReceiver, nftAmount);
        if (marketingFee > 0) safeTransferETH(marketingFeeReceiver, marketingAmount);
    }

    /// @notice Register share or the balance of the StellarInu token of the signer
    /// @dev Transaction must comes directly from a signer
    function registerShare() external {
        setShare(msg.sender, token.balanceOf(msg.sender));
    }

    /// @notice Distribute the accumulated ether reward to the sender
    /// @dev Emit a `DividendClaimed` event if the claimed amount is greater than 0 and contract balance is sufficient
    function claimDividend() external nonReentrant {
        require(shares[msg.sender].amount != 0, "FD::claimDividend: INSUFFICIENT_SHARE");
        uint256 amount = getUnpaidEarnings(msg.sender);
        require(amount > 0, "FD::claimDividend: INSUFFICIENT_EARNING");
        require(amount <= rewardBalance, "FD::claimDividend: INSUFFICIENT_REWARD");

        totalDistributed += amount;
        shares[msg.sender].totalRealised += amount;
        shares[msg.sender].totalExcluded = getCumulativeDividends(shares[msg.sender].amount);
        rewardBalance -= amount;

        safeTransferETH(msg.sender, amount);
        emit DividendClaimed(msg.sender, amount);
    }

    /// @notice Rescue ETH from the contract
    /// @dev Called by owner only
    /// @param receiver The payable address to receive ETH
    /// @param amount The amount in wei
    function withdrawETH(address payable receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0), "FD::withdrawETH: BURN_ADDRESS");
        require(address(this).balance >= amount, "FD::withdrawETH: INSUFFICIENT_BALANCE");
        safeTransferETH(receiver, amount);
    }

    /// @notice View the unpaid earnings of a shareholder
    /// @param shareholder The address of a token holder
    /// @return The amount of dividend in wei that `shareholder` can withdraw
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    /// @notice Private function to view the cumulative dividends of an amount of shares
    /// @param share the amount of shares
    /// @return The cumulative dividends in wei
    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    /// @dev Private function that adds shareholder to the dividend tracker
    /// Add the shareholder address to shareholders param
    /// @param shareholder The address of the shareholder
    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /// @dev Private function that removes shareholder from the dividend tracker
    /// Remove the shareholder address from shareholders param
    /// @param shareholder The address of the shareholder
    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    /// @dev Private function that safely transfers ETH to an address
    /// It fails if to is 0x0 or the transfer isn't successful
    /// @param to The address to transfer to
    /// @param value The amount to be transferred
    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "FD::safeTransferETH: ETH_TRANSFER_FAILED");
    }
}