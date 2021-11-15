// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 */
contract BitBaseTimeLock is Ownable {

    /**
     * @dev ERC20 contract being held = BitBase (BTBS)
     */
    IERC20 public BTBS;
    
    /**
     * @dev timestamp when token unlock logic begins = contract deployment timestamp
     */
    uint256 public startDate;

    address[] private addresessArray;
    
    /**
     * @dev Struct that holds the user data: bought and withdrawn tokens
     */
    struct User {
        uint256 bought;
        uint256 withdrawn;
    }
    
    /**
     * @dev mapping of an address to a User struct
     */
    mapping(address => User) public userData;
    
    /**
     * @dev event emitted when a user claims tokens
     */
    event Claimed(address indexed account, uint256 amount);
    
    /**
     * @dev event emitted when the owner updates the address of a user to a new one.
     */
    event AddressUpdated(address indexed accountOld, address indexed accountNew);

    /**
     * @dev event emitted when the owner sets the addresses of the users with the corresponding amount of locked tokens
     */
    event AddressesSet(bool set);

    constructor () {
        BTBS = IERC20(0x32E6C34Cd57087aBBD59B5A4AECC4cB495924356);
        startDate = block.timestamp;
    }


    /**
     * @dev Percentage of unlocked BTBS from total purchased amount 
     * Unlocked:
     * day 90 = 5%
     * day 180 = 10%
     * day 300 = 15%
     * After day 300 = 0.7%/day
     * @return releasePercentage Percentage magnified x100 to decrease precision errors: 500 = 5%
     */
    function unlocked() public view virtual returns (uint256) {

       uint256 startLinearRelease = startDate + 300 days;
       uint256 releasePercentage;
       
       if (block.timestamp <= startDate + 90 days) {
           releasePercentage = 0;
       } else if (block.timestamp < startDate + 180 days) {
           releasePercentage = 500;
       } else if (block.timestamp >= startDate + 180 days && block.timestamp < startLinearRelease) {
           releasePercentage = 1000;
       } else if (block.timestamp >= startLinearRelease) {
           uint256 timeSinceLinearRelease = block.timestamp - startLinearRelease;
           uint256 linearRelease = timeSinceLinearRelease * 1000 / 1234286; //0.7% Daily
           releasePercentage = 1500 + linearRelease;
       }
       
       if (releasePercentage >= 10000) {
           releasePercentage = 10000;
       }
       return releasePercentage;
    }
    
    /**
     * @dev Sends the available amount of tokens to withdraw to the caller
     */
    function _claim(address account) internal virtual {
        uint256 withdrawable = availableToWithdraw(account);
        userData[account].withdrawn += withdrawable;
        BTBS.transfer(account, withdrawable);
        emit Claimed(account, withdrawable);
    }

    /**
     * @dev Sends the available amount of tokens to withdraw to the caller
     */
    function claim() public virtual {
        _claim(msg.sender);
    }
    
    /**
     * @dev Returns the avilable amount of tokens for an address to withdraw = unlockedTotal - claimedAmount
     * @param account The user address
     */
    function availableToWithdraw(address account) public view virtual returns (uint256) {
        return unlockedTotal(account) - claimedAmount(account);
    }
    
    /**
     * @dev Returns the total amount of tokens that has been unlocked for an account
     * @param account The user address
     */
    function unlockedTotal(address account) public view virtual returns (uint256) {
        return userData[account].bought * unlocked() / 10000;
    }
    
    /**
     * @dev Returns the amount of tokens that an address has bought in private sale
     * @param account The user address
     */
    function boughtAmount(address account) public view virtual returns (uint256) {
        return userData[account].bought;
    }
    
    /**
     * @dev Returns de amount of tokens that an address already claimed
     * @param account The user address
     */
    function claimedAmount(address account) public view virtual returns (uint256) {
        return userData[account].withdrawn;
    }
    
    /**
     * @dev Returns the amount of tokens that an address has not yet claim = bought - withdrawn
     * @param account The user address
     */
    function leftToClaim(address account) public view virtual returns (uint256) {
        return userData[account].bought - userData[account].withdrawn;
    }
    
    
    /**
     * @dev This function allows the owner to update a user address in case of lost keys or security breach from the user side.
     * IMPORTANT: Should only be called after proper KYC examination.
     * @param accountOld The old account address
     * @param accountNew The old account address
     */
    function updateAddress(address accountOld, address accountNew) public virtual onlyOwner {
        userData[accountNew].withdrawn = userData[accountOld].withdrawn;
        userData[accountNew].bought = userData[accountOld].bought;
        userData[accountOld].withdrawn = 0;
        userData[accountOld].bought = 0;
        emit AddressUpdated(accountOld, accountNew);
    }
    
    /**
     * @dev Allows owner to recover any ERC20 sent into the contract. Only owner can call this function.
     * @param tokenAddress The token contract address
     * @param amount The amount to be withdrawn. If the amount is set to 0 it will withdraw all the balance of tokenAddress.
     */
    function recoverERC20(address tokenAddress, uint256 amount) public virtual onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (amount == 0) {
            uint256 balance = token.balanceOf(address(this));
            token.transfer(owner(), balance);
        } else if (amount != 0) {
            token.transfer(owner(), amount);
        }
    }
    
    /**
     * @dev Allows owner to set an array of addresess who bought and the corresponding amounts. Only owner can call this function.
     * @param accounts Array of user addresess
     * @param amounts Array of user amounts
     */
    function setBoughtAmounts(address[] memory accounts, uint256[] memory amounts) public virtual onlyOwner {
        addresessArray = accounts;
        for (uint256 i = 0; i < accounts.length; i++) {
            userData[accounts[i]].bought = amounts[i];
        }
        emit AddressesSet(true);
    }

    /**
     * @dev Allows owner to send the "availableToWithdraw()" tokens to all the addresess at once.
     * This function has been implemented to help the less tech-savvy users receive their tokens. Only owner can call this function.
     */
    function sendToAll() public virtual onlyOwner {
        for (uint256 i = 0; i < addresessArray.length; i++) {
            _claim(addresessArray[i]);
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

