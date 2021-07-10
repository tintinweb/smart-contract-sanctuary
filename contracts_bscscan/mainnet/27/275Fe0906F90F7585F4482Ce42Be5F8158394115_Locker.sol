/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// File: contracts\utils\Context.sol

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

// File: contracts\utils\Ownable.sol

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

// File: contracts\extensions\ILocker.sol

interface ILocker {
  /**
   * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
   * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
   */
  function checkLock(address source, uint256 remainBalance) external view returns (bool);
  function lock(address addr, uint256 amount, uint256 start, uint256 end, uint256 vestingMonth, uint256 cliff, uint index) external;
}

// File: contracts\Locker.sol

/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

struct LockDuration {
    uint256 start;
    uint256 end;
    // amount of token being locked
    uint256 lockAmount;
    // number of month it takes to release all {lockAmount}
    uint256 vestingMonth;
    // immidiately lock token transfer function from {start} to {cliff}
    // vesting will start after cliff time has passed
    uint256 cliff;

}

contract Locker is Ownable, ILocker {
    // contains addresses that were in the seeding, private sale or marketing campaign
    // these addresses will be locked from sending their token to other addresses in different durations
    // these lock durations will be stored in lockRecords
    mapping(address => bool) public whitelist;
    //mapping from address to presale stage -> lock amount
    mapping(address => mapping(uint => LockDuration)) public lockRecords;

    // address of deployed Presale contract
    address public presaleAddress;

    // number of block that represent 1 month in BSC
    uint256 public constant BLOCK_PER_MONTH = 864000;

    uint public constant PRESALE_STAGE = 6;

    modifier onlyPresaleAddress() {
        require(_msgSender() == presaleAddress, "Invalid caller, must be presale address");
        _;
    }

    event Lock(address addr, uint256 amount, uint256 start, uint256 vestingMonth, uint256 cliff);

    constructor() {}

    function setPresaleAddress(address newAddr) public onlyOwner {
        presaleAddress = newAddr;
    }

    /**
     * @dev lock an account from transfering CORI token in a specific block number
     * @param addr address representing account being locked
     * @param amount the amount being locked, account's balance can't go below this number during lock time
     * @param start block number represent start of lock period
     * @param end block number represent start of lock period
     * @param vestingMonth similar to {vestingMonth} in LockDuration
     * @param cliff number of months the token will be locked before able to vesting
     * @param index there are multiple presale stages and lock configurations, so we must index them to calculate the real locked amount in each stage
     */
    function lock(address addr, uint256 amount, uint256 start, uint256 end, uint256 vestingMonth, uint256 cliff, uint index) external override onlyPresaleAddress {
        LockDuration memory locker = lockRecords[addr][index];

        whitelist[addr] = true;
        // convert {cliff} to block number
        uint256 cliffEndTime = end + cliff * BLOCK_PER_MONTH;
        // getting the exact end time of Presale
        end = cliffEndTime + vestingMonth * BLOCK_PER_MONTH;
        // update lock amount
        lockRecords[addr][index] = LockDuration(start, end, amount + locker.lockAmount, vestingMonth, cliffEndTime);
    }
    /**
     * @dev calculate the true amount being locked of an address in one presale stage
     * @param source address representing account being checked
     * @param index index of presale stage
     * @return uint256 address representing the locked amount
     */
    function getRealLockedAmount(address source, uint index) public view returns (uint256) {
        LockDuration memory lockDuration = lockRecords[source][index];
        if (block.number >= lockDuration.end)
            return 0;
            
        uint256 monthPassSinceLock = 0;
        if (block.number > lockDuration.cliff)
            monthPassSinceLock = (block.number - lockDuration.cliff) / BLOCK_PER_MONTH;

        // avoid divide by zero
        if (lockDuration.vestingMonth == 0)
            return 0;

        uint256 amountVestedEachMonth = lockDuration.lockAmount / lockDuration.vestingMonth;
        return lockDuration.lockAmount - (monthPassSinceLock * amountVestedEachMonth);
    }

    function getLockedAmount(address source) public view returns(uint256) {
        uint256 lockAmount = 0;
        for (uint i = 0; i < PRESALE_STAGE; i++)
            lockAmount += getRealLockedAmount(source, i);
        return lockAmount;
    }

     /**
     * @dev check the validity of {newBalance} of {source} address, {newBalance} must smaller than lockedAmount of {source}
     */
    function checkLock(address source, uint256 newBalance) external view override returns (bool) {
        if (!whitelist[source])
            return false;
            
        uint256 lockAmount = getLockedAmount(source);

        if (lockAmount == 0)
            return false;

        if (newBalance < lockAmount)
            return true;
        return false;
    }
}