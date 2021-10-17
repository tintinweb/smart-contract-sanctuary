// SPDX-License-Identifier: MIT

/// @title Places descriptor
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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "base64-sol/base64.sol";
import {IPlaces} from "./interfaces/IPlaces.sol";
import {IPlacesDescriptor} from "./interfaces/IPlacesDescriptor.sol";

contract PlacesDescriptor is IPlacesDescriptor, Ownable {
    /**
     * @notice Create contract metadata for Opensea.
     */
    function constructContractURI()
        external
        pure
        override
        returns (string memory)
    {
        return "";
    }

    /**
     * @notice Create the ERC721 token URI for a token.
     */
    function constructTokenURI(uint256 tokenId, IPlaces.Place memory place)
        external
        pure
        override
        returns (string memory)
    {
        string[30] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 520 520"><style>.text { font-family: monospace; font-size: 16px; fill: white; } .name { font-size: 18px; font-weight: 600; } .blue { fill: #2681FF; }.black { fill: black; }</style>';

        parts[
            1
        ] = '<defs><filter x="0" y="0" width="1" height="1" id="blue"><feFlood flood-color="#2681FF" /><feComposite in="SourceGraphic" operator="xor" /></filter></defs><rect width="100%" height="100%" fill="black"/>';

        parts[
            2
        ] = '<circle cx="260" cy="260" r="164" fill="#102440" stroke="#none"/><circle cx="260" cy="260" r="12" fill="black" stroke="#2681FF" stroke-width="4"/><rect x="252" y="220" width="16" height="16" transform="rotate(45 260 228)" fill="#2681FF"/>';

        parts[
            3
        ] = '<text x="50%" y="224" text-anchor="middle" filter="url(#blue)" class="text name">';

        parts[4] = place.name;
        parts[
            5
        ] = '</text><text x="50%" y="224" text-anchor="middle" class="text name black">';
        parts[6] = place.name;
        parts[
            7
        ] = '</text><text x="50%" y="223" text-anchor="middle" class="text name">';
        parts[8] = place.name;
        parts[9] = '</text><g class="text"><text x="24" y="34">';
        parts[10] = place.attributes[0];
        parts[11] = '</text><text x="24" y="58">';
        parts[12] = place.attributes[1];
        parts[13] = '</text><text x="24" y="82">';
        parts[14] = place.attributes[2];
        parts[15] = '</text></g><g class="text"><text x="24" y="398">';
        parts[16] = place.sublocality;
        parts[17] = '</text><text x="24" y="422"><tspan>';
        parts[18] = place.locality;
        parts[19] = "</tspan><tspan>, </tspan><tspan>";
        parts[20] = place.administrativeArea;
        parts[21] = '</tspan></text><text x="24" y="446">';
        parts[22] = place.streetAddress;
        parts[23] = '</text><text x="24" y="470">Elevation ';
        parts[24] = (place.location.hasAltitude)
            ? place.location.altitude
            : "???";
        if (place.location.hasAltitude) {
            parts[25] = 'm</text><text x="24" y="494" class="blue">';
        } else {
            parts[25] = '</text><text x="24" y="494" class="blue">';
        }
        parts[26] = place.location.latitude;
        parts[27] = ", ";
        parts[28] = place.location.longitude;
        parts[29] = "</text></g></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29]
            )
        );

        string[14] memory traitParts;
        traitParts[0] = '"trait_type": "SUBLOCALITY", "value": "';
        traitParts[1] = place.sublocality;
        traitParts[2] = '"}, {"trait_type": "LOCALITY", "value": "';
        traitParts[3] = place.locality;
        traitParts[
            4
        ] = '"}, {"trait_type": "SUBADMINISTRATIVE AREA", "value": "';
        traitParts[5] = place.subadministrativeArea;
        traitParts[6] = '"}, {"trait_type": "ADMINISTRATIVE AREA", "value": "';
        traitParts[7] = place.administrativeArea;
        traitParts[8] = '"}, {"trait_type": "COUNTRY", "value": "';
        traitParts[9] = place.country;
        traitParts[10] = '"}, {"trait_type": "POSTAL CODE", "value": "';
        traitParts[11] = place.postalCode;
        traitParts[12] = '"}, {"trait_type": "ATTRIBUTE", "value": "';
        traitParts[13] = place.attributes[0];

        string memory traits = string(
            abi.encodePacked(
                traitParts[0],
                traitParts[1],
                traitParts[2],
                traitParts[3],
                traitParts[4],
                traitParts[5],
                traitParts[6],
                traitParts[7],
                traitParts[8]
            )
        );
        traits = string(
            abi.encodePacked(
                traits,
                traitParts[9],
                traitParts[10],
                traitParts[11],
                traitParts[12],
                traitParts[13]
            )
        );

        bool hasSecondTrait = bytes(place.attributes[1]).length > 0;
        bool hasThirdTrait = bytes(place.attributes[2]).length > 0;
        if (hasSecondTrait && hasThirdTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[1],
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[2]
                )
            );
        } else if (hasSecondTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[1]
                )
            );
        } else if (hasThirdTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[2]
                )
            );
        }

        traits = string(
            abi.encodePacked(
                traits,
                '"}, {"display_type": "number", "trait_type": "LATITUDE", "value": ',
                place.location.latitude,
                '}, {"display_type": "number", "trait_type": "LONGITUDE", "value": ',
                place.location.longitude
            )
        );

        if (place.location.hasAltitude) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '}, {"display_type": "number", "trait_type": "ALTITUDE", "value": ',
                    place.location.altitude
                )
            );
        }

        // props to Brecht Devos Base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        place.name,
                        unicode" – Place #",
                        toString(tokenId),
                        '", "description": "Places is an experiment to establish geographic locations as non-fungible tokens on the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{',
                        traits,
                        "}]}"
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /**
     * @notice [MIT License] via Loot, inspired by OraclizeAPI's implementation - MIT license
     * @dev https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places descriptor
/// @author Places DAO

/*************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░███░░░░░░░░░░░░░███░░░░░░░ *
 * ░▒▒▒░░░███░░░░░░░░░░░░░███░░░▒▒▒░ *
 * ░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░ *
 * ░░░░█████████████████████████░░░░ *
 * ░░░░░░█████    ███    █████░░░░░░ *
 * ░░░░░░░░█████████████████░░░░░░░░ *
 * ░░░░░░░░░░████▓▓▓▓▓▓███░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *************************************/

pragma solidity ^0.8.6;

import {IPlaces} from "./IPlaces.sol";

interface IPlacesDescriptor {
    function constructContractURI() external pure returns (string memory);

    function constructTokenURI(uint256 tokenId, IPlaces.Place memory place)
        external
        pure
        returns (string memory);
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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