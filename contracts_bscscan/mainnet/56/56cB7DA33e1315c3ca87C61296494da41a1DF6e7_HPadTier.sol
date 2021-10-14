// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IDO/IIDOPoint.sol";
import "../interfaces/IDO/IIDOTier.sol";

/** @title HPadTier
 * @notice this contract is to get users' tiers
 */

contract HPadTier is Ownable, IIDOTier {
    IIDOPoint public idoPointer;

    struct Tier {
        uint256 tierId;
        uint256 minPoint;
        uint256 multiplier;
    }

    Tier[] public tiers;

    constructor() {
        tiers.push(Tier({ tierId: 1, minPoint: 100 ether, multiplier: 1 })); // popular
        tiers.push(Tier({ tierId: 2, minPoint: 500 ether, multiplier: 2 })); // star
        tiers.push(Tier({ tierId: 3, minPoint: 1500 ether, multiplier: 4 })); // superstar
        tiers.push(Tier({ tierId: 4, minPoint: 2500 ether, multiplier: 10 })); // megastar
    }

    function getTiersCount() external view returns (uint256) {
        return tiers.length;
    }

    function getTotalMultiplier() external view override returns (uint256) {
        uint256 total = 0;

        for (uint256 index = 0; index < tiers.length; index++) {
            total = total + tiers[index].multiplier;
        }

        return total;
    }

    function getTiers() external view returns (Tier[] memory) {
        return tiers;
    }

    function getMultiplierAtIndex(uint256 index) external view override returns (uint256) {
        if (index >= tiers.length) {
            return 0;
        }

        return tiers[index].multiplier;
    }

    function getMultiplierAtTierId(uint256 tierId) external view override returns (uint256) {
        for (uint256 index = 0; index < tiers.length; index++) {
            Tier memory tier = tiers[index];
            if (tier.tierId == tierId) {
                return tier.multiplier;
            }
        }
        return 0;
    }

    function setTierInfo(
        uint256 index,
        uint256 minPoint,
        uint256 multiplier
    ) external onlyOwner {
        require(index < 4, "Invalid index");
        require(minPoint > 0, "Invalid minPoint");
        require(multiplier > 0, "Invalid multiplier");

        tiers[index].minPoint = minPoint;
        tiers[index].multiplier = multiplier;
    }

    function setIDOPointer(IIDOPoint _idoPointer) external onlyOwner {
        require(address(_idoPointer) != address(0), "Invalid address");

        idoPointer = _idoPointer;
    }

    function getTier(address user) external view override returns (uint256) {
        uint256 point = idoPointer.getPoint(user);

        uint256 index;

        for (index = 0; index < tiers.length; index++) {
            Tier memory tier = tiers[index];
            if (tier.minPoint > point) {
                break;
            }
        }

        return index; // 0: No tier, 1: bronze, 2: silver, 3: gold
    }

    function getMultiplier(address user) external view override returns (uint256) {
        uint256 point = idoPointer.getPoint(user);

        uint256 index;

        for (index = 0; index < tiers.length; index++) {
            Tier memory tier = tiers[index];
            if (tier.minPoint > point) {
                break;
            }
        }

        if (index == 0) {
            return 0;
        }

        return tiers[index - 1].multiplier;
    }

    function getTierId(address user) external view override returns (uint256) {
        uint256 point = idoPointer.getPoint(user);

        uint256 index;

        for (index = 0; index < tiers.length; index++) {
            Tier memory tier = tiers[index];
            if (tier.minPoint > point) {
                break;
            }
        }

        if (index == 0) {
            return 0;
        }

        return tiers[index - 1].tierId;
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

interface IIDOPoint {
    function getPoint(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIDOTier {
    function getTier(address user) external view returns (uint256);

    function getMultiplier(address user) external view returns (uint256);

    function getTotalMultiplier() external view returns (uint256);

    function getMultiplierAtIndex(uint256) external view returns (uint256);

    function getMultiplierAtTierId(uint256 tierId) external view returns (uint256);

    function getTierId(address user) external view returns (uint256);
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