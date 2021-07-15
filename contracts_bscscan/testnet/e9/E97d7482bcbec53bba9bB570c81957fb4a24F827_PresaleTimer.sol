// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IPresaleTimer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PresaleTimer is IPresaleTimer, Ownable {
    uint256 internal _presaleStartTime; //1626908400: 22th July 0:00 BST
    uint256 internal _presaleEndTime; //1629586799: 21rst August 23:59:59 BST

    modifier presaleNotEnded() {
        require(!isOver(), "Time is up no more update");
        _;
    }

    constructor(uint256 start, uint256 end) {
        _presaleStartTime = start;
        _presaleEndTime = end;
    }

    function updateEndTime(uint256 end)
        public
        override
        onlyOwner
        presaleNotEnded
    {
        _presaleEndTime = end;
        emit PresaleEndTimeUpdated(end);
    }

    function stopPresale() public override onlyOwner {
        _presaleEndTime = block.timestamp;
        emit PresaleStopped(_presaleEndTime);
    }

    function startDate() public view override returns (uint256) {
        return _presaleStartTime;
    }

    function endDate() public view override returns (uint256) {
        return _presaleEndTime;
    }

    function hasStarted() public view override returns (bool) {
        return block.timestamp >= _presaleStartTime;
    }

    function isOver() public view override returns (bool) {
        return block.timestamp >= _presaleEndTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IPresaleTimer {
    event PresaleEndTimeUpdated(uint256 time);
    event PresaleStopped(uint256 time);

    function updateEndTime(uint256 end) external;

    function stopPresale() external;

    function startDate() external view returns (uint256);

    function endDate() external view returns (uint256);

    function hasStarted() external view returns (bool);

    function isOver() external view returns (bool);
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