pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PathMinterClaim is Ownable{

    IERC20 private token;

    uint256 public initialPercentage;
    uint256 public grandTotalClaimed = 0;
    uint256 public startTime;
    uint256 public endVesting;

    struct Allocation {
        uint256 initialAllocation; //Initial token allocated
        uint256 totalAllocated; // Total tokens allocated
        uint256 amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed minter, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint256 _startTime, uint256 _endVesting, uint256 _initialPercentage) {
        require(_startTime <= _endVesting, "start time should be larger than endtime");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endVesting = _endVesting;
        initialPercentage = _initialPercentage;
    }



    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].initialAllocation;
            newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation) / (endVesting - startTime)) * (block.timestamp - startTime);
        }
        return newClaimAmount;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation (address[] memory _addresses, uint[] memory _totalAllocated) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length);
        for (uint i = 0; i < _addresses.length; i++ ) {
            uint initialAllocation =  _totalAllocated[i] * initialPercentage / 100;
            allocations[_addresses[i]] = Allocation(initialAllocation, _totalAllocated[i], 0);
        }
    }

    /**
    * @dev Check current claimable amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount (address _recipient) public view returns (uint amount) {
        return allocations[_recipient].totalAllocated - allocations[msg.sender].amountClaimed;
    }

    /**
    * @dev Allows msg.sender to claim their allocated tokens
     */

    function claim() external {
        require(allocations[msg.sender].amountClaimed < allocations[msg.sender].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(msg.sender);
        uint tokensToClaim = getClaimTotal(msg.sender);
        allocations[msg.sender].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(msg.sender, tokensToClaim));
        emit claimedToken(msg.sender, tokensToClaim, allocations[msg.sender].amountClaimed);
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

// SPDX-License-Identifier: MIT

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