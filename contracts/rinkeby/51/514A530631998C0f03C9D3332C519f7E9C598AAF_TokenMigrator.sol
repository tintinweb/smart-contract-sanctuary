/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

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
        return msg.data;
    }
}

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

contract TokenMigrator is Ownable {
    IERC20 public token0;
    IERC20 public token1;
    
    struct Account {
        address wallet;
        uint256 amount;
    }
    
    uint256 token0Amount;
    uint256 token1Amount;
    
    mapping (address => uint256) private index;
    
    Account[] private accounts;
    
    bool depositEnabled;
    bool distributeDone;
    
    constructor(address token0address, address token1address) {
        token0 = IERC20(token0address);
        token1 = IERC20(token1address);
        
        accounts.push(Account(address(0), 0));
    }
    
    function getDepositCount() public view returns (uint256) {
        return accounts.length;
    }
    
    function depositStatus() public view returns (bool) {
        return depositEnabled;
    }
    
    function enableDeposits() public onlyOwner {
        require(!depositEnabled, "TokenMigrator: Deposits are already enabled");
        depositEnabled = true;
    }
    
    function disableDeposits() public onlyOwner {
        require(depositEnabled, "TokenMigrator: Deposits are already enabled");
        depositEnabled = false;
    }
    
    function deposit(uint256 amount) public {
        require(depositEnabled, "TokenMigrator: Deposits are disabled");
        token0.transferFrom(msg.sender, address(this), amount);
        
        if(index[msg.sender] != 0) {
            accounts[index[msg.sender]].amount += amount;
        } else {
            index[msg.sender] = accounts.length;
            accounts.push(Account(msg.sender, amount));
        }
        
        token0Amount += amount;
    }
    
    function withdrawToken0(uint256 amount) public onlyOwner {
        require(token0Amount >= amount, "TokenMigrator: Insufficient token0 balance");
        token0Amount -= amount;
        IERC20(token0).transfer(msg.sender, amount);
    }
    
    function depositToken1(uint256 amount) public onlyOwner {
        IERC20(token1).transferFrom(msg.sender, address(this), amount);
        token1Amount += amount;
    }
    
    function withdrawToken1(uint256 amount) public onlyOwner {
        require(token1Amount >= amount, "TokenMigrator: Insufficient token1 balance");
        token1Amount -= amount;
        IERC20(token1).transfer(msg.sender, amount);
    }
    
    function distribute(uint256 fromIndex, uint256 toIndex, uint256 numerator, uint256 denominator) public onlyOwner {
        require(token0Amount * numerator / denominator <= token1Amount, "TokenMigrator: Not enough token1 to distribute");
        require(fromIndex >= toIndex, "TokenMigrator: Invalid arguments");
        
        if(accounts.length - 1 > toIndex) toIndex = accounts.length - 1;
        
        for (uint256 i = fromIndex; i < toIndex + 1; i++) {
            if(accounts[i].wallet == address(0)) continue;
            if(accounts[i].amount == 0) continue;
            
            accounts[i].amount = 0;
            IERC20(token1).transfer(accounts[i].wallet, accounts[i].amount * numerator / denominator);
        }
    }
}