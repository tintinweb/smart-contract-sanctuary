/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: MIT

/******************************************/
/*       SafeMath starts here             */
/******************************************/

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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


/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


/******************************************/
/*       DinoAllocation starts here  */
/******************************************/

pragma solidity ^0.6.0;

contract DinoAllocation is Ownable {

    using SafeMath for uint256;

    IERC20 public DINO; 

    uint256 endBlock;
    address treasury;
    bool initialized;
    bool treasuryExecuted;

    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
        bool team;
    }

    /**
     * @dev Populate allocations.
     */
    constructor() public 
    {
        allocations[0x75598C888Ca893342B69FB133ad07Cc71c6B6aaf] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xfFC3d9BED3fCe83Aa6A606C961ae37d7CC6d131b] = Allocation({
            sharePerBlock: 410958904109589000,
            lastWithdrawalBlock: block.number,
            team: true   
        });
        allocations[0x2728ee74bcD72c49220F93d37e52ad83548eCbE6] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4D6945c269195Ab9ef821ed67baEeC7c16B5002E] = Allocation({
            sharePerBlock: 479452054794521000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x350661d34c58a8eb8ec7e3aD5bc809753B60FD59] = Allocation({
            sharePerBlock: 239726027397260000,
            lastWithdrawalBlock: block.number,
            team: true   
        });
        allocations[0x4a7fAA271539b039C72c15bC085802e19EA25432] = Allocation({
            sharePerBlock: 239726027397260000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xD534B942A243e6fc69C66d1ec3AbcD55991bE24C] = Allocation({
            sharePerBlock: 164383561643836000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x267A6E6d9e4cD70aA0382B02E9b5cDcE67807a93] = Allocation({
            sharePerBlock: 315068493150685000,
            lastWithdrawalBlock: block.number,
            team: true   
        });
        allocations[0x4B2EC9B3202c2de0923bf21A099121656c087ba5] = Allocation({
            sharePerBlock: 205479452054795000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x04FB55364a095a0566AFEb96cC73F0c400871ac5] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x2d47720ddc8f33AA4082FF578199CA66Ee2FE0fB] = Allocation({
            sharePerBlock: 164383561643836000,
            lastWithdrawalBlock: block.number,
            team: true   
        });
        allocations[0xeA66889573dA26723C13a1023264488448b3f655] = Allocation({
            sharePerBlock: 109589041095890000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x10954a5eb844E853020b5F19a392b82Fd62630fE] = Allocation({
            sharePerBlock: 205479452054795000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x9b06a7576BaA9e212Cbe1fDBFf122D084b969b26] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: true   
        });
        allocations[0x1823e397Ef23F780fd3E275aAa508b1f6f49B541] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xe1F7d90c783EaC11966d72b398f742e01F78Dfa3] = Allocation({
            sharePerBlock: 82191780821917800,
            lastWithdrawalBlock: block.number,
            team: true  
        });

        treasury = 0xA77364249507F3e55cFb1143e139F931dCC00E9e;
        endBlock = block.number.add(2372500);
    }


    function initialize(IERC20 _DINO) public onlyOwner
    {
        require(initialized == false, "Already initialized.");
        initialized = true;
        DINO = _DINO;
    }
    
    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() public
    {
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[msg.sender].lastWithdrawalBlock;
        allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[msg.sender].sharePerBlock.mul(unlockedBlock.sub(tempLastWithdrawalBlock));
        DINO.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Check the remaining balance of a shareholder's total outstanding shares.
     */
    function getTotalOutstandingBalance() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock.mul(endBlock.sub(allocations[msg.sender].lastWithdrawalBlock));
    }

    /**
     * @dev Check the balance of a shareholder's claimable shares.
     */
    function getUnlockedBalance() external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[msg.sender].sharePerBlock.mul(unlockedBlock.sub(allocations[msg.sender].lastWithdrawalBlock));
    }

    /**
     * @dev Withdraw initial share attributed towards the treasury.
     */
    function treasuryWithdraw() public
    {
        require(treasuryExecuted == false, "Treasury share already withdrawn.");
        treasuryExecuted = true;
        DINO.transfer(treasury, (1000000*1e9));
    }

    /**
     * @dev Emergency function to change allocations.
     */
    function changeAllocation(address _allocation, uint256 _newSharePerBlock) public onlyOwner 
    {
        require (allocations[_allocation].team == false, "Can't change allocations of team members.");
        allocations[_allocation].sharePerBlock = _newSharePerBlock;
    }

}