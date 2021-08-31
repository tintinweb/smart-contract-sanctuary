/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// File: openzeppelin-solidity/contracts/utils/Context.sol

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

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

// File: contracts/LiteBulbPresalePublic.sol

pragma solidity ^0.8.0;


/**
 * @dev Allows to create allocations for token sale.
 */
contract LiteBulbPresalePublic is Ownable {
    uint256 constant OWNER_PAYOUT_DELAY = 1 days;

    uint256 private _closingAllocationsRemainder;
    uint256 private _minimumAllocation;
    uint256 private _maximumAllocation;
    uint256 private _totalAllocationsLimit;
    uint256 private _totalAllocated;
    uint256 private _saleStart;
    bool private _isEveryoneAllowedToParticipate;
    bool private _wasClosed;
    bool private _wasStarted;
    mapping (address => uint256) private _allocations;
    mapping (address => bool) private _allowedParticipants;

    event SaleStarted();
    event SaleClosed();
    event Allocated(address indexed participant, uint256 allocation);

   /**
    * @dev Initializes sale contract with minimum and maximum amount that can be allocated and total allocation limit.
    * @param allowedParticipantsValue List of addresses allowed to participate.
    */
    constructor(address[] memory allowedParticipantsValue) {
        _closingAllocationsRemainder = 0;
        _minimumAllocation = 0;
        _maximumAllocation = 0;
        _totalAllocationsLimit = 0;
        _totalAllocated = 0;
        _saleStart = 0;
        _wasClosed = false;
        _wasStarted = false;

        _addAllowedParticipants(allowedParticipantsValue);
    }

    /**
     * @dev Extend the allowed participants list.
     * @param participantsValue List of allowed addresses to add.
     */
    function _addAllowedParticipants(address[] memory participantsValue) internal onlyOwner {
        for (uint256 i = 0; i < participantsValue.length; ++i) {
            _allowedParticipants[participantsValue[i]] = true;
        }
    }

   /**
    * @dev Setups and starts the sale.
    * @param minimumAllocationValue Minimum allocation value.
    * @param maximumAllocationValue Maximum allocation value.
    * @param totalAllocationsLimitValue Total allocations limit.
    * @param closingAllocationsRemainderValue Remaining amount of allocations allowing to close sale before reaching total allocations limit.
    */
    function startSale(uint256 minimumAllocationValue, uint256 maximumAllocationValue, uint256 totalAllocationsLimitValue, uint256 closingAllocationsRemainderValue) public onlyOwner {
        require(!_wasStarted, "PresalePublic: Sale was already started");
        require(!_wasClosed, "PresalePublic: Sale was already closed");

        _closingAllocationsRemainder = closingAllocationsRemainderValue;
        _minimumAllocation = minimumAllocationValue;
        _maximumAllocation = maximumAllocationValue;
        _totalAllocationsLimit = totalAllocationsLimitValue;
        _saleStart = block.timestamp;
        _wasStarted = true;

        emit SaleStarted();
    }

    /**
     * @dev Opens the sale to everyone.
     */
    function openSale() public payable onlyOwner {
        require(_wasStarted, "PresalePublic: Sale was not started yet");
        require(!_wasClosed, "PresalePublic: Sale was already closed");
        require(!_isEveryoneAllowedToParticipate, "PresalePublic: Sale was already opened to everyone");

        _isEveryoneAllowedToParticipate = true;
    }

    /**
     * @dev Allows to allocate currency for the sale.
     */
    function allocate() public payable {
        require(wasStarted(), "PresalePublic: Cannot allocate yet");
        require(areAllocationsAccepted(), "PresalePublic: Cannot allocate anymore");
        require((msg.value >= _minimumAllocation), "PresalePublic: Allocation is too small");
        require(((msg.value + _allocations[msg.sender]) <= _maximumAllocation), "PresalePublic: Allocation is too big");
        require(canAllocate(msg.sender), "PresalePublic: Not allowed to participate");
        require(msg.value + _totalAllocated <= _totalAllocationsLimit, "PresalePublic: You are too late.");
    

        _totalAllocated += msg.value;
        _allocations[msg.sender] += msg.value;

        emit Allocated(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to close sale and payout all currency.
     */
    function closeSale() public onlyOwner {

        payable(owner()).transfer(address(this).balance);

        _wasClosed = true;

        emit SaleClosed();
    }

    /**
     * @dev Extend the allowed participants list.
     * @param participantsValue List of allowed addresses to add.
     */
    function addAllowedParticipants(address[] memory participantsValue) public onlyOwner {
        require(areAllocationsAccepted(), "PresalePublic: Allocations were already closed");

        _addAllowedParticipants(participantsValue);
    }

    /**
     * @dev Returns amount allocated from given address.
     * @param participant Address to check.
     */
    function allocation(address participant) public view returns (uint256) {
        return _allocations[participant];
    }

    /**
     * @dev Checks if allocations are still accepted.
     */
    function areAllocationsAccepted() public view returns (bool) {
        return (isActive() && (_totalAllocationsLimit - _totalAllocated) >= _minimumAllocation);
    }

    /**
     * @dev Checks if given address can still allocate.
     * @param participant Address to check.
     */
    function canAllocate(address participant) public view returns (bool) {
        if (!areAllocationsAccepted() || !isAllowedToParticipate(participant)) {
            return false;
        }

        return ((_allocations[participant] + _minimumAllocation) <= _maximumAllocation);
    }

    /**
     * @dev Checks if owner can close sale and payout the currency.
     */
    function canCloseSale() public view returns (bool) {
        return (isActive() && (!areAllocationsAccepted() || _closingAllocationsRemainder >= (_totalAllocationsLimit - _totalAllocated) || block.timestamp >= (_saleStart + OWNER_PAYOUT_DELAY)));
    }

    /**
     * @dev Returns remaining amount of allocations allowing to close sale before reaching total allocations limit.
     */
    function closingAllocationsRemainder() public view returns (uint256) {
        return _closingAllocationsRemainder;
    }

    /**
     * @dev Checks if given address is allowed to participate.
     * @param participant Address to check.
     */
    function isAllowedToParticipate(address participant) public view returns (bool) {
        return (_isEveryoneAllowedToParticipate || _allowedParticipants[participant]);
    }

    /**
     * @dev Checks if sale is active.
     */
    function isActive() public view returns (bool) {
        return (_wasStarted && !_wasClosed);
    }

    /**
     * @dev Checks if everyone is allowed to participate.
     */
    function isEveryoneAllowedToParticipate() public view returns (bool) {
        return _isEveryoneAllowedToParticipate;
    }

    /**
     * @dev Returns minimum allocation amount.
     */
    function minimumAllocation() public view returns (uint256) {
        return _minimumAllocation;
    }

    /**
     * @dev Returns maximum allocation amount.
     */
    function maximumAllocation() public view returns (uint256) {
        return _maximumAllocation;
    }

    /**
     * @dev Returns sale start timestamp.
     */
    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    /**
     * @dev Returns total allocations limit.
     */
    function totalAllocationsLimit() public view returns (uint256) {
        return _totalAllocationsLimit;
    }

    /**
     * @dev Returns allocated amount.
     */
    function totalAllocated() public view returns (uint256) {
        return _totalAllocated;
    }

    /**
     * @dev Checks if sale was already started.
     */
    function wasStarted() public view returns (bool) {
        return _wasStarted;
    }

    /**
     * @dev Checks if sale was already closed.
     */
    function wasClosed() public view returns (bool) {
        return _wasClosed;
    }

    /**
     * @dev Fallback receive method.
     */
    receive() external payable {
        allocate();
    }
}