// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/staking/IStaking.sol";
import "../interfaces/staking/IDStaking.sol";

interface IStakingRoot {
    struct DStakingInfo {
        address addr;
        uint256 rewardsAmount;
    }

    function dStakings(uint256) external view returns (DStakingInfo memory);

    function dStakingCount() external view returns (uint256);
}

contract DStakingUtils is Ownable {
    address public stakingRoot;
    address public staking;

    function setStakingRoot(address _stakingRoot) external onlyOwner {
        require(address(_stakingRoot) != address(0), "Invalid _stakingRoot");

        stakingRoot = _stakingRoot;
    }

    function setStaking(address _staking) external onlyOwner {
        require(address(_staking) != address(0), "Invalid _staking");

        staking = _staking;
    }

    function getTotalDStakedAmount() external view returns (uint256 total) {
        uint256 dStakingCount = IStakingRoot(stakingRoot).dStakingCount();

        for (uint256 index = 0; index < dStakingCount; index++) {
            address dStakingAddr = IStakingRoot(stakingRoot).dStakings(index).addr;
            total = total + IDStaking(dStakingAddr).getTotalDelegatedAmount();
        }
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return IStaking(staking).getTotalDelegatedAmount();
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

interface IStaking {
    function getDelegatedAmount(address user) external view returns (uint256);

    function getTotalDelegatedAmount() external view returns (uint256);

    function withdrawAnyToken(
        address _token,
        uint256 amount,
        address beneficiary
    ) external;

    function claim() external;

    function undelegate(uint256 amount, bool _withdrawRewards) external;

    function delegate(uint256 amount) external;

    function pendingRewards(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDStaking {
    function getTotalDelegatedAmount() external view returns (uint256);

    function getDelegatedAmount(address user) external view returns (uint256);

    function withdrawAnyToken(
        address _token,
        uint256 amount,
        address beneficiary
    ) external;

    function claim() external;

    function undelegate(uint256 amount) external;

    function delegateFor(address beneficiary, uint256 amount) external;

    function delegate(uint256 amount) external;

    function redelegate(address toDStaking, uint256 amount) external;

    function pendingRewards(address _user) external view returns (uint256);

    function initDeposit(
        address creator,
        address beneficiary,
        uint256 amount
    ) external;
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