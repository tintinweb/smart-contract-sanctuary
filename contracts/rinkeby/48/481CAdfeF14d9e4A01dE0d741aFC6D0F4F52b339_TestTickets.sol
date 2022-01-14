// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./OwnableTokenAccessControl.sol";

interface IERC20Burn is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract TestTickets is OwnableTokenAccessControl {

    uint256 public constant TICKET_PRICE = 0.01 ether;
    
    constructor() {
    }

    function buyTicketsBurn(uint256 amount, address tokenAddress) external {
        require(_hasAccess(Access.Burn, tokenAddress), "Invalid token for buying tickets");
        uint tokenAmount = amount * TICKET_PRICE;
        IERC20Burn(tokenAddress).burnFrom(_msgSender(), tokenAmount);
    }

    function buyTickets(uint256 amount, address tokenAddress) external {
        require(_hasAccess(Access.Transfer, tokenAddress), "Invalid token for buying tickets");
        uint tokenAmount = amount * TICKET_PRICE;
        IERC20(tokenAddress).transferFrom(_msgSender(), address(this), tokenAmount);
    }

    function withdraw(IERC20 token) external onlyOwner {
        uint amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens available");
        token.transfer(_msgSender(), amount);
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OwnableTokenAccessControl
/// @notice Basic access control for utility tokens 
/// @author ponky
contract OwnableTokenAccessControl is Ownable {
    /// @dev Keeps track of how many accounts have been granted each type of access
    uint96 private _accessCounts;

    mapping (address => uint256) private _accessFlags;

    /// @dev Access types
    enum Access { Mint, Burn, Transfer }

    /// @dev Emitted when `account` is granted `access`.
    event AccessGranted(bytes32 indexed access, address indexed account);

    /// @dev Emitted when `account` is revoked `access`.
    event AccessRevoked(bytes32 indexed access, address indexed account);

    /// @dev Helper constants for fitting each access index into _accessCounts
    uint constant private _AC_BASE          = 4;
    uint constant private _AC_MASK_BITSIZE  = 1 << _AC_BASE;
    uint constant private _AC_MASK          = (1 << _AC_MASK_BITSIZE) - 1;

    /// @dev Convert the string `access` to an uint
    function _accessToIndex(bytes32 access) internal pure virtual returns (uint index) {
        if (access == 'MINT')       {return uint(Access.Mint);}
        if (access == 'BURN')       {return uint(Access.Burn);}
        if (access == 'TRANSFER')   {return uint(Access.Transfer);}
        revert("Invalid Access");
    }

    function _hasAccess(Access access, address account) internal view returns (bool) {
        return (_accessFlags[account] & (1 << uint(access))) != 0;
    }

    function hasAccess(bytes32 access, address account) public view returns (bool) {
        uint flag = 1 << _accessToIndex(access);        
        return (_accessFlags[account] & flag) != 0;
    }

    function grantAccess(bytes32 access, address account) external onlyOwner {
        //require(isContract(account), "Can only grant access to a contract");

        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags | (1 << index);
        require(flags != newFlags, "Account already has access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        uint accessCount = (_accessCounts >> shift) & _AC_MASK;
        unchecked {
            require(accessCount < (_AC_MASK-1), "Access disabled or limit reached");
            _accessCounts += uint96(1 << shift);
        }

        emit AccessGranted(access, account);
    }

    function revokeAccess(bytes32 access, address account) external onlyOwner {
        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint newFlags = flags & ~(1 << index);
        require(flags != newFlags, "Account does not have access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        unchecked {
            _accessCounts -= uint96(1 << shift);
        }

        emit AccessRevoked(access, account);
    }

    /// @dev Returns the number of accounts that have been granted `access`.
    function countOfAccess(bytes32 access) external view returns (uint) {
        uint index = _accessToIndex(access);

        uint shift = index << _AC_BASE;
        uint accessCount = (_accessCounts >> shift) & _AC_MASK;
        if (accessCount == _AC_MASK) {
            // access has been disabled
            accessCount = 0;
        }
        return accessCount;
    }

    function permanentlyDisableGrantingAccess(bytes32 access) external onlyOwner {
        uint index = _accessToIndex(access);
        
        uint shift = index << _AC_BASE;
        uint mask = _AC_MASK << shift;
        uint accessCount = _accessCounts & mask;
        require(accessCount != mask, "Granting access has already been disabled");
        require(accessCount == 0, "Revoke access from contracts first");
        _accessCounts |= uint96(mask);
    }

    function _permanentlyDisableGrantingAllAccess() internal {
        uint256 accessCounts = _accessCounts;
        uint shift = 0;
        do {
            uint mask = _AC_MASK << shift;
            uint accessCount = accessCounts & mask;
            require(accessCount == mask || accessCount == 0, "Revoke access from contracts first");
            unchecked {
                shift += _AC_MASK_BITSIZE;
            }
        } while (shift < 96);
        _accessCounts = type(uint96).max;
    }

    function renounceOwnership() public override onlyOwner {
        _permanentlyDisableGrantingAllAccess();

        _transferOwnership(address(0));
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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