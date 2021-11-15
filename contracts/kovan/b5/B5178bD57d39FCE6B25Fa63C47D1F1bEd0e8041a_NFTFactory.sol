// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IPeriod.sol";

contract NFTFactory is Ownable, IPeriod {

    uint private period;
    uint private periodStart;
    uint16 private amountPerPeriod;

    constructor(uint _period/*, uint _periodStart*/, uint16 _amountPerPeriod) {
        period = _period;
        periodStart = block.timestamp;//_periodStart;
        amountPerPeriod = _amountPerPeriod;
    }

    function getTotalAmount() override public view returns(uint) {
        return (block.timestamp - periodStart) / period * amountPerPeriod;
    }

    // get the current period id
    function getCurPeriod() override public view returns(uint) {
        return (block.timestamp - periodStart) / period;
    }

    function getPeriod() override external view returns(uint) {
        return period;
    }

    function getPeriodStart() override external view returns(uint) {
        return periodStart;
    }

    function getAmountPerPeriod() override external view returns(uint16) {
        return amountPerPeriod;
    }

    // get the start time of a period.
    function startTimeAt(uint _periodId) public view returns(uint) {
        return _periodId * period + periodStart;
    }

    // to check if the canvas id and period id are valid.
    // function checkValid(uint _canvasId, uint _periodId) public view returns(bool) {
    //     if(_canvasId <= 0 || _periodId == 0) {
    //         return false;
    //     }

    //     uint currPeriod = getCurPeriod();
    //     if(_periodId > currPeriod) {
    //         return false;
    //     }
    //     // TODO....

    //     return true;
    // }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPeriod {

    function getPeriod() external view returns(uint);
    function getPeriodStart() external view returns(uint);
    function getCurPeriod() external view returns(uint);
    function getAmountPerPeriod() external view returns(uint16);
    function getTotalAmount() external view returns(uint);
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

