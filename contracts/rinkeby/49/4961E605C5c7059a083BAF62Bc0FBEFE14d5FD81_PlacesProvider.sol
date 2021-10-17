// SPDX-License-Identifier: MIT

/// @title Places provider
/// @author Places DAO

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

import {IPlaces} from "./interfaces/IPlaces.sol";
import {IPlacesProvider} from "./interfaces/IPlacesProvider.sol";
import {IPlacesDrop} from "./interfaces/IPlacesDrop.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlacesProvider is IPlacesProvider, Ownable {
    IPlacesDrop[] private drops;

    constructor(IPlacesDrop[] memory _drops) {
        drops = _drops;
    }

    /**
     * @notice Query the neighborhood treasury for the given token.
     */
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

    /**
     * @notice Query the Place data for a given token.
     */
    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlaces.Place memory)
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

    /**
     * @notice Query the Place data for a total count.
     */
    function getPlaceSupply() external view returns (uint256 supplyCount) {
        require(drops.length > 0, "Provider not setup");
        return drops[drops.length - 1].getEndingIndex() + 1;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places provider
/// @author Places DAO

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

import {IPlaces} from "./IPlaces.sol";

interface IPlacesProvider {
    function getTreasury(uint256 tokenId)
        external
        view
        returns (address payable);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlaces.Place memory);

    function getPlaceSupply() external view returns (uint256 supplyCount);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places drop
/// @author Places DAO

/*************************************
 * ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ *
 * ▓ ▒                           ▓ ▒ *
 * ▒          ████  ████           ▓ *
 * ▓        ██  ████  ████         ▒ *
 * ▒      ███    ███████████       ▓ *
 * ▓      ████  ████████ ███       ▒ *
 * ▒        ██████████ ███         ▓ *
 * ▓          ██████ ███           ▒ *
 * ▒            ███ ██             ▓ *
 * ▓              ██               ▒ *
 * ▒ ▓                           ▒ ▓ *
 * ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ *
 *************************************/

pragma solidity ^0.8.6;

import {IPlaces} from "./IPlaces.sol";

interface IPlacesDrop {
    function getTreasury() external view returns (address payable);

    function getPlaceCount() external view returns (uint256);

    function getEndingIndex() external view returns (uint256);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlaces.Place memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places
/// @author Places DAO

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

interface IPlaces {
    /**
     * @notice Location – Represents a geographic coordinate with altitude.
     *
     * Latitude and longitude values are in degrees under the WGS 84 reference
     * frame. Altitude values are in meters. Two location types are provided
     * int256 and string. The integer representation enables on chain computation
     * where as the string representation provides future computational compatability.
     *
     * See IPlaceDrop.sol, IPlaceDrop.Place.Location
     *
     * Converting a location from a to integer uses GEO_RESOLUTION_INT denominator.
     * 37.73957402260721 encodes to 3773957402260721
     * -122.41902666230027 encodes to -12241902666230027
     *
     * hasAltitude – a boolean that indicates the validity of the altitude values
     * latitudeInt – integer representing the latitude in degrees encoded with
     * GEO_RESOLUTION_INT
     * longitudeInt – integer representing the longitude in degrees encoded with
     * GEO_RESOLUTION_INT
     * altitudeInt – integer representing the altitude in meters encoded with
     * GEO_RESOLUTION_INT
     * latitude – string representing the latitude coordinate in degrees under
     * the WGS 84 reference frame
     * longitude – string representing the longitude coordinate in degrees under
     * the WGS 84 reference frame
     * altitude – string representing the altitude measurement in meters
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
     * @notice Place – Represents place information for a geographic location.
     *
     * See IPlaceDrop.sol, IPlaceDrop.Place
     *
     * name – string representing the place name
     * streetAddress – string indicating a precise address
     * sublocality – string representing the subdivision and first-order civil
     * entity below locality (neighborhood or common name)
     * locality – string representing the incorporated city or town political
     * entity
     * subadministrativeArea – string representing the subdivision of the
     * second-order civil entity (county name)
     * administrativeArea – string representing the second-order civil entity
     * below country (state or region name)
     * country – string representing the national political entity
     * postalCode – string representing the code used to address postal mail
     * within the country
     * countryCode – string representing the ISO 3166-1 country code,
     * https://en.wikipedia.org/wiki/ISO_3166-1
     * location – geographic location of the place, see Location type
     * attributes – string array of attributes describing the place
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