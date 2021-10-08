/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity >= 0.6.12;


// SPDX-License-Identifier: GPL-3.0-or-later
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

abstract contract Lockable is Context {
    address private _locker;

    event LockerChanged(
        address indexed previousLocker,
        address indexed newLocker
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial locker.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _locker = msgSender;
        emit LockerChanged(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current locker.
     */
    function locker() public view returns (address) {
        return _locker;
    }

    /**
     * @dev Throws if called by any account other than the locker.
     */
    modifier onlyLocker() {
        require(_locker == _msgSender(), "Lockable: caller is not the locker");
        _;
    }

    /**
     * @dev Change locker of the contract to a new account (`newLocker`).
     * Can only be called by the current locker.
     */
    function changeLocker(address newlocker) public virtual onlyLocker {
        require(newlocker != address(0), "Lockable: new locker is the zero address");
        emit LockerChanged(_locker, newlocker);
        _locker = newlocker;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TempLock is Ownable, Lockable {
    uint256 public amtNoLock;
    uint256 public amtLock;
    address private _caller;

    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data, uint eta);

    constructor() public {
        amtNoLock = 100;
        amtLock = 100;
    }

    function executetion(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        emit ExecuteTransaction(target, value, signature, data, eta);
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: value}(callData);

        return returnData;
    }

    function getCaller() public view returns (address) {
        return _caller;
    }

    function getAmountNoLock() external view returns(uint256) {
        return amtNoLock;
    }

    function getAmountLock() external view returns(uint256) {
        return amtLock;
    }

    function getDataEncoded(uint256 data) public view returns (bytes memory) {
        return abi.encodePacked(data);
    }

    function setAmounLock(uint256 _amt) public {
        _caller = msg.sender;
        amtLock = _amt;
    }

    function setAmounNoLock(uint256 _amt) public {
        _caller = msg.sender;
        amtNoLock = _amt;
    }
}