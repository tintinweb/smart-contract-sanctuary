/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity 0.8.7;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/TokenVesting.sol


pragma solidity ^0.8.7;



// CLIFF PERIOD - 3 Months
// VESTING - Linear vesting 5% each month

contract TokenVesting is Ownable {
    IERC20 token;

    uint256 public VESTING_TIME = 4 minutes;
    uint256 public VESTING_TERM = 7;
    uint256 public CLIFF_PERIOD = 2; // substract 1 to be able to claim first amount at the third month.
    uint256 public TGE_PERCENT = 10;
    uint256 public vestingStartDate;
    uint256 public totalAllocationAmount = 0; //private

    struct Receiver {
        address wallet;
        uint256 amount;
    }

    mapping(address => uint256) public allocation; //private
    mapping(address => uint256) public claimed; //private

    modifier isBeneficiary {
        require(allocation[msg.sender] > 0, 'not allowed');
        _;
    }

    constructor(address tokenAdress, uint256 _vestingStartDate) {
        token = IERC20(tokenAdress);
        vestingStartDate = _vestingStartDate;
    }

    function addAllocations(Receiver[] memory receivers) external onlyOwner {
        for (uint256 i=0; i<receivers.length; i++) {
            uint256 amount = receivers[i].amount * 10**18;
            address receiver = receivers[i].wallet;
            allocation[receiver] = amount;
            totalAllocationAmount += totalAllocationAmount + amount;
        }
    }

    function claim() external isBeneficiary {
        require(block.timestamp > vestingStartDate, 'vesting hasnt started');
        require(allocation[msg.sender] != claimed[msg.sender], 'cannot claim more');
        uint256 claimable = claimableAmount();
        require(claimable > 0, 'no tokens to claim');

        claimed[msg.sender] += claimable;
        require(token.transfer(msg.sender, claimable), 'could not transfer token');
    }

    function claimableAmount() private view returns (uint256) {
        uint256 TGE_Amount = allocation[msg.sender] / 100 * TGE_PERCENT;

        if (claimed[msg.sender] >= TGE_Amount) {
            uint256 vestingAllocation = allocation[msg.sender] - TGE_Amount;
            uint256 vestingClaimed = claimed[msg.sender] - TGE_Amount;
            uint256 cliffPeriodByVestingTerm = CLIFF_PERIOD * VESTING_TIME;

            if (block.timestamp < vestingStartDate + cliffPeriodByVestingTerm) return 0;

            uint256 passedTimeByTerm = (block.timestamp - vestingStartDate - cliffPeriodByVestingTerm) / VESTING_TIME;
        
            uint256 amount = (vestingAllocation / VESTING_TERM * passedTimeByTerm) - vestingClaimed;

            if (vestingClaimed + amount > vestingAllocation) {
                amount = vestingAllocation - vestingClaimed;
            }
        
            return amount;
        } else {
            uint256 amount = TGE_Amount;

            return amount;
        }
    }

    function displayClaimableAmount() external view returns (uint256) {
        return claimableAmount();
    }

    function withdrawRemaining() external onlyOwner {
        // Withdraw the remaining balance in case those are not claimed for 3 years.
        require(vestingStartDate + 30 * 30 days < block.timestamp);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function allocatedAmount() external view onlyOwner returns (uint256) {
        return totalAllocationAmount;
    }

    function contractBalance() external view onlyOwner returns (uint256)  {
        return token.balanceOf(address(this));
    }
}

contract Time {
    function getBlockTime() external view returns (uint256) {
        return block.timestamp;
    }
}