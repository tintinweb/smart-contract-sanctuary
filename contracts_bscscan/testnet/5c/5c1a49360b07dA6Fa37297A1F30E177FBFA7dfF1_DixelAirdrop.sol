// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DixelAirdrop is Ownable, ReentrancyGuard {
    IERC20 public baseToken;

    bool public canClaim;

    struct WhiteListParams {
        address wallet;
        uint224 nftContribution;
        uint224 mintClubContribution;
    }

    struct Contribution {
        bool claimed;
        uint224 nftContribution; // category: 1
        uint224 mintClubContribution; // category: 2
    }

    struct Total {
        uint24 whiteListCount;
        uint224 nftTotalAmount;
        uint224 mintClubTotalAmount;
        uint224 nftTotalContribution;
        uint224 mintClubTotalContribution;
    }

    Total public total;
    mapping(address => Contribution) public userContributions;

    event ClaimAirdrop(address user, uint256 amount);

    // solhint-disable-next-line func-visibility
    constructor(address baseTokenAddress) {
        baseToken = IERC20(baseTokenAddress);
    }

    function addTokens(uint8 airdropCategory, uint80 amount) external onlyOwner {
        require(!canClaim, "CANNOT_CHANGE_TOTAL_SHARE_DURING_CLAIMING");
        require(airdropCategory == 1 || airdropCategory == 2, "INVALID_CATEGORY");

        assert(baseToken.transferFrom(_msgSender(), address(this), amount));

        unchecked {
            if (airdropCategory == 1) {
                total.nftTotalAmount += amount;
            } else if (airdropCategory == 2) {
                total.mintClubTotalAmount += amount;
            }
        }
    }

    function startAirdrop() external onlyOwner {
        canClaim = true;
    }

    function closeAirdrop() external onlyOwner {
        canClaim = false;
        uint256 balance = baseToken.balanceOf(address(this));

        // Withdraw all leftover balance
        assert(baseToken.transfer(_msgSender(), balance));
    }

    function whitelist(WhiteListParams[] calldata params) external onlyOwner {
        require(!canClaim, "CANNOT_ADD_WHITELIST_DURING_CLAIMING");

        for (uint256 i = 0; i < params.length; i++) {
            require(userContributions[params[i].wallet].nftContribution == 0, "DUPLICATED_RECORD");
            require(userContributions[params[i].wallet].mintClubContribution == 0, "DUPLICATED_RECORD");

            userContributions[params[i].wallet].nftContribution = params[i].nftContribution;
            userContributions[params[i].wallet].mintClubContribution = params[i].mintClubContribution;

            unchecked {
                total.nftTotalContribution += params[i].nftContribution;
                total.mintClubTotalContribution += params[i].mintClubContribution;
                total.whiteListCount += 1;
            }
        }
    }

    // MARK: - User accessible methods

    function isWhiteList(address wallet) public view returns (bool) {
        Contribution memory c = userContributions[wallet];

        return c.nftContribution > 0 || c.mintClubContribution > 0;
    }

    function airdropAmount(address wallet) public view returns (uint256) {
        Contribution memory c = userContributions[wallet];

        unchecked {
            return
                (total.nftTotalAmount * c.nftContribution) / total.nftTotalContribution +
                (total.mintClubTotalAmount * c.mintClubContribution) / total.mintClubTotalContribution;
        }
    }

    function claimableAmount(address wallet) public view returns (uint256) {
        if (!canClaim || hasClaimed(wallet)) {
            return 0;
        }

        return airdropAmount(wallet);
    }

    function hasClaimed(address wallet) public view returns (bool) {
        return userContributions[wallet].claimed;
    }

    function claim() external {
        address msgSender = _msgSender();
        require(canClaim, "AIRDROP_HAS_NOT_STARTED_OR_FINISHED");
        require(isWhiteList(msgSender), "NOT_INCLUDED_IN_THE_WHITE_LIST");
        require(!hasClaimed(msgSender), "ALREADY_CLAIMED");

        uint256 amount = claimableAmount(msgSender);

        userContributions[msgSender].claimed = true;
        assert(baseToken.transfer(msgSender, amount));

        emit ClaimAirdrop(msgSender, amount);
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