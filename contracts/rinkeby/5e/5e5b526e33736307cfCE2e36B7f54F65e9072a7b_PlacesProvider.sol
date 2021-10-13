// SPDX-License-Identifier: MIT

/// @title Places provider

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import {IPlacesProvider} from "./interfaces/IPlacesProvider.sol";
import {IPlacesDrop} from "./interfaces/IPlacesDrop.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlacesProvider is IPlacesProvider, Ownable {
    address private minter;
    IPlacesDrop[] private drops;

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(IPlacesDrop[] memory _drops) {
        drops = _drops;
    }

    function getTreasury(uint256 tokenId)
        external
        view
        returns (address payable)
    {
        require(drops.length > 0, "Provider not setup");
        uint256 dropIndex = 0;
        while (dropIndex < drops.length) {
            if (tokenId <= drops[dropIndex].getEndingIndex()) {
                break;
            } else {
                dropIndex++;
            }
        }

        require(
            tokenId <= drops[dropIndex].getEndingIndex(),
            "Token exceeds places."
        );

        return drops[dropIndex].getTreasury();
    }

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlacesDrop.Place memory)
    {
        require(drops.length > 0, "Provider not setup");
        uint256 dropIndex = 0;
        while (dropIndex < drops.length) {
            if (tokenId <= drops[dropIndex].getEndingIndex()) {
                break;
            } else {
                dropIndex++;
            }
        }

        require(
            tokenId <= drops[dropIndex].getEndingIndex(),
            "Token exceeds places"
        );

        return drops[dropIndex].getPlace(tokenId);
    }

    function getPlaceSupply() external view returns (uint256 supplyCount) {
        require(drops.length > 0, "Provider not setup");
        return drops[drops.length - 1].getEndingIndex() + 1;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places provider

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import {IPlacesDrop} from "./IPlacesDrop.sol";

interface IPlacesProvider {
    function getTreasury(uint256 tokenId)
        external
        view
        returns (address payable);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlacesDrop.Place memory);

    function getPlaceSupply() external view returns (uint256 supplyCount);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places drop

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

interface IPlacesDrop {
    /**
     * @notice Represents a 3D geographical coordinate with altitude.
     */
    struct Location {
        int256 latitudeInt;
        int256 longitudeInt;
        int256 altitudeInt;
        bool hasAltitude;
        string latitude;
        string longitude;
        string altitude;
    }

    /**
     * @notice Represents place information for a geographic location.
     */
    struct Place {
        string name;
        string streetAddress;
        string sublocality;
        string locality;
        string subadministrativeArea;
        string administrativeArea;
        string country;
        string postalCode;
        string countryCode;
        Location location;
        string[3] attributes;
    }

    function getTreasury() external view returns (address payable);

    function getPlaceCount() external view returns (uint256);

    function getEndingIndex() external view returns (uint256);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlacesDrop.Place memory);
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