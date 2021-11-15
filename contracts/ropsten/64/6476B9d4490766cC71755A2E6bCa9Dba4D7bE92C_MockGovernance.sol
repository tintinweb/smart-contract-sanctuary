// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernance {
    struct RewardScheduleEntry {
        uint256 startTime;
        uint256 epochDuration;
        uint256 rewardsPerEpoch; 
    }

    function rewardCollector(address producer) external view returns (address);
    function blockProducer(address producer) external view returns (bool);
    function rewardSchedule() external view returns (RewardScheduleEntry[] memory);

    event BlockProducerAdded(address indexed producer);
    event BlockProducerRemoved(address indexed producer);
    event BlockProducerRewardCollectorChanged(address indexed producer, address indexed collector);
    event RewardScheduleChanged();
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

import "../lib/Ownable.sol";
import "../interfaces/IGovernance.sol";

contract MockGovernance is Ownable, IGovernance {
    mapping (address => address) public override rewardCollector;
    mapping (address => bool) public override blockProducer;
    RewardScheduleEntry[] private _rewardSchedule;

    function add(address producer) onlyOwner public {
        emit BlockProducerAdded(producer);
    }

    function remove(address producer) onlyOwner public {
        emit BlockProducerRemoved(producer);
    }

    function delegate(address producer, address collector) onlyOwner public {
        rewardCollector[producer] = collector;
        emit BlockProducerRewardCollectorChanged(producer, collector);
    }

    function setRewardSchedule(RewardScheduleEntry[] calldata set) onlyOwner public {
        while (_rewardSchedule.length > set.length)
            _rewardSchedule.pop();
        for (uint i = 0; i < _rewardSchedule.length; ++i)
            _rewardSchedule[i] = set[i];
        for (uint i = set.length; i < set.length; ++i)
            _rewardSchedule.push(set[i]);
        emit RewardScheduleChanged();
    }

    function rewardSchedule() public override view returns (RewardScheduleEntry[] memory) {
        return _rewardSchedule;
    }
}

