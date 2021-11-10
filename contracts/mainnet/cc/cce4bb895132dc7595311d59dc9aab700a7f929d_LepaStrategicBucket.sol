/*
Contract Security Audited by Certik : https://www.certik.org/projects/lepasa
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface TransferLepa {
    function transfer(address recipient,uint256 amount) external returns (bool);
}

contract LepaStrategicBucket is Pausable,Ownable {
    TransferLepa private _lepaToken;

    struct Bucket {
        uint256 allocation;
        uint256 claimed;
    }

    mapping( address => Bucket) public users;

    uint256 public constant maxLimit =  39 * (10**6) * 10**18;
    uint256 public constant vestingSeconds = 365 * 86400;
    uint256 public totalMembers;    
    uint256 public allocatedSum;
    uint256 public vestingStartEpoch;

    event GrantAllocationEvent(address allcationAdd, uint256 amount);    
    event ClaimAllocationEvent(address addr, uint256 balance);
    event VestingStartedEvent(uint256 epochtime);

    constructor(TransferLepa tokenAddress,uint256 epochtime)  {
        require(address(tokenAddress) != address(0), "Token Address cannot be address 0");
        _lepaToken = tokenAddress;
        totalMembers = 0;
        allocatedSum = 0;
        vestingStartEpoch = epochtime;
        if (vestingStartEpoch >0)
        emit VestingStartedEvent(epochtime);
    }

    function startVesting(uint256 epochtime) external onlyOwner{
        require(vestingStartEpoch == 0, "Vesting already started.");
        vestingStartEpoch = epochtime;
        emit VestingStartedEvent(epochtime);
    }

    function GrantAllocation(address[] calldata _allocationAdd, uint256[] calldata _amount) external whenNotPaused onlyOwner{
      require(_allocationAdd.length == _amount.length);
      
      for (uint256 i = 0; i < _allocationAdd.length; ++i) {
            _GrantAllocation(_allocationAdd[i],_amount[i]);
        }
    }

    function _GrantAllocation(address allocationAdd, uint256 amount) internal {
        require(allocationAdd != address(0), "Invalid allocation address");
        require(amount >= 0, "Invalid allocation amount");
        require(amount >= users[allocationAdd].claimed, "Amount cannot be less than already claimed amount");
        require(allocatedSum - users[allocationAdd].allocation + amount <= maxLimit, "Limit exceeded");

        if(users[allocationAdd].allocation == 0) {                        
            totalMembers++;
        } 
        allocatedSum = allocatedSum - users[allocationAdd].allocation + amount;
        users[allocationAdd].allocation = amount;        
        emit GrantAllocationEvent(allocationAdd, amount);        
    }

    function GetClaimableBalance(address userAddr) public view returns (uint256) {
        require(vestingStartEpoch > 0, "Vesting not initialized");

        Bucket memory userBucket = users[userAddr];        
        require(userBucket.allocation != 0, "Address is not registered");
        
        uint256 totalClaimableBal = userBucket.allocation/10; // 10% of allocation
        totalClaimableBal = totalClaimableBal + ((block.timestamp - vestingStartEpoch)*(userBucket.allocation - totalClaimableBal)/vestingSeconds);

        if(totalClaimableBal > userBucket.allocation) {
            totalClaimableBal = userBucket.allocation;
        }

        require(totalClaimableBal > userBucket.claimed, "Vesting threshold reached");
        return totalClaimableBal - userBucket.claimed;
    }

    function ProcessClaim() external whenNotPaused {
        uint256 claimableBalance = GetClaimableBalance(_msgSender());
        require(claimableBalance > 0, "Claim amount invalid.");
        
        users[_msgSender()].claimed = users[_msgSender()].claimed + claimableBalance;
        emit ClaimAllocationEvent(_msgSender(), claimableBalance);
        require(_lepaToken.transfer(_msgSender(), claimableBalance), "Token transfer failed!"); 
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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