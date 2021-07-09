/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\VestingLockPool.sol
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\VestingLockPool.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\VestingLockPool.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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


/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\VestingLockPool.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "./Ownable.sol";

contract VestingLockPool is Context, Ownable {

    struct VestPool {
        uint256 amount;        // the amount that will be released after the vesting period
        uint256 debt;           // the amount that user has withdrawn up till now
        uint256 release_start;  // the start of vesting period
        uint256 release_end;    // the end of vesting period 
        uint256 status;         // pool status: 0 - normal, 1 - canceled
    }

    mapping(address => VestPool) private _pools;
    IERC20 private _asset;

    event PoolCreated(address indexed poolOwner, uint256 amount, uint256 vest_start, uint256 vest_end);
    event PoolCanceled(address indexed poolOwner);
    event PoolWidthaw(address indexed poolOwner, uint256 amount, uint256 remain);
    event EmergencyWithdraw(address indexed poolOwner, uint256 amount, uint256 remain);

    constructor(IERC20 asset) {
        _asset = asset;
    }

    function createPool(address poolOwner, uint256 amount, uint256 vest_start, uint256 vest_end) external onlyOwner {
        VestPool storage pool = _pools[poolOwner];

        require(vest_end > vest_start, "invalid vesting period");
        require(pool.status == 0, "pool is canceled");
        
        _asset.transferFrom(owner(), address(this), amount);

        pool.amount += amount;
        pool.release_start = vest_start;
        pool.release_end = vest_end;

        emit PoolCreated(poolOwner, pool.amount, vest_start, vest_end);
    }
    
    function resetPool(address poolOwner) external onlyOwner {
        VestPool storage pool = _pools[poolOwner];
        require(pool.status == 1, "pool is active");
        
        delete _pools[poolOwner];
    }

    /**
     * @dev cancels a pool and trasfers fund of this pool back to owner address.
     * 
     * this is for emergency purpose only.
     */ 
    function cancelPool(address poolOwner) external onlyOwner {
        VestPool storage pool = _pools[poolOwner];

        require(pool.status == 0, "pool is canceled");
        require(pool.amount - pool.debt >= 0, "insufficient fund");

        pool.status = 1;
        _asset.transfer(owner(), pool.amount - pool.debt);

        emit PoolCanceled(poolOwner);
    }

    function availableOf(address poolOwner) public view returns(uint256) {
        VestPool storage pool = _pools[poolOwner];

        if (pool.status == 1 || pool.amount == 0)  
            return 0;

        uint256 moment = block.timestamp < pool.release_end ? block.timestamp : pool.release_end;
        uint256 fund = pool.amount * (moment - pool.release_start) / (pool.release_end - pool.release_start);
        return fund >= pool.debt ? fund - pool.debt : 0;
    }
    
    function poolOf(address poolOwner) external view returns(uint256 balance, uint256 available, uint256 vest_start, uint256 vest_end, uint256 status) {
        VestPool storage pool = _pools[poolOwner];
        
        balance = pool.amount - pool.debt;
        available = availableOf(poolOwner);
        vest_start = pool.release_start;
        vest_end = pool.release_end;
        status = pool.status;
    }

    function withdraw(uint256 amount) external {
        address poolOwner = _msgSender();
        VestPool storage pool = _pools[poolOwner];
        uint256 available = availableOf(poolOwner);

        require(available >= amount, "insufficient fund");
        pool.debt += amount;

        _asset.transfer(poolOwner, amount);

        emit PoolWidthaw(poolOwner, amount, available - amount);
    }
    
    /**
     * @dev allows poolOwner to withdraw fund before vesting period
     * 
     * for emergency usage only.
     */ 
    function emergencyWithdraw(address poolOwner, uint amount) external onlyOwner {
        VestPool storage pool = _pools[poolOwner];
        uint256 balance = pool.amount - pool.debt;
        
        require(balance >= amount, "insufficient fund");
        pool.debt += amount;

        _asset.transfer(poolOwner, amount);

        emit EmergencyWithdraw(poolOwner, amount, balance - amount);
    }
}