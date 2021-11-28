// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/Ownable.sol";
import "./lib/ITraits.sol";
import "./lib/IPeople.sol";

contract Traits is Ownable, ITraits {

    using Strings for uint256;

    // Trait stores each trait by name and base64-encoded png data,
    // 
    // each Trait must have a png binding to it
    struct Trait {
        string name;
        string png;
    }

    // _attrList is list of all Attributes
    string[9] _attrList = [
        "job",
        "skin",
        "eyes",
        "ear",
        "mouth",
        "nose",
        "glasses",
        "hair",
        "cloth"
    ];
    // _attrNumber is number os each Attributes
    uint8[9] _attrNumber = [ 0, 4, 0, 0, 0, 0, 0, 0, 0 ];

    // skinList stores all skins
    string[4] skinList = [
        "black",
        "white",
        "yellow",
        "brown"
    ];

    // mapping from job ID to job name
    mapping(uint8 => string) public jobList;
    // mapping from job ID to profession0 ID
    mapping(uint8 => uint8) public prof0Map;
    // mapping from job ID to profession1 ID
    mapping(uint8 => uint8) public prof1Map;
    // mapping from [job ID * 4 + skin ID] to hand ID
    mapping(uint8 => uint8) public handMap;

    // traitData stores all Trait,
    //
    // mapping: index in _traitTypeList => index of Trait in specific Type => Trait Data
    //
    // index 0 of Trait in specific Type represents an empty PNG
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;

    IPeople public people;

    constructor() {}

    /** ADMIN **/

    function setPeople(address _people) external onlyOwner {
        people = IPeople(_people);
    }
    /**
     *  uploadTraits is operated by Administrator to upload each trait
     *  @param traitType index in _traitTypeList to specify which type of traits to be uploaded
     *  @param traitIdList array stores IDs of traits to be uploaded
     *  @param traitList the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(uint8 traitType, uint8[] calldata traitIdList, Trait[] calldata traitList) external onlyOwner {
        require(traitIdList.length == traitList.length, "Mismatched inputs");
        for (uint i = 0; i < traitIdList.length; i++) {
            traitData[traitType][traitIdList[i]] = Trait(
                traitList[i].name,
                traitList[i].png
            );

            // update corresponding Number
            if (traitType >= 2 && traitType <= 8 && traitIdList[i] + 1 > _attrNumber[traitType]) {
                _attrNumber[traitType] = traitIdList[i] + 1;
            }
        }
    }

    /**
     *  uploadJob is operated by Administrator to upload a new job,
     *  profession0, profession1, hand[0] ~ hand[3] must be uploaded before call this function
     *  @param jobID ID of job, must be unique
     *  @param jobName name of job
     *  @param prof0 ID of profession0 corresponding to job
     *  @param prof1 ID of profession1 corresponding to job
     *  @param hand 4 ID of hand corresponding to job
     */
    function uploadJob(uint8 jobID, string calldata jobName, uint8 prof0, uint8 prof1, uint8[] calldata hand) external onlyOwner {
        if (jobID + 1 > _attrNumber[0]) {
            _attrNumber[0] = jobID + 1;
        }
        jobList[jobID] = jobName;
        prof0Map[jobID] = prof0;
        prof1Map[jobID] = prof1;
        handMap[jobID * 4] = hand[0];
        handMap[jobID * 4 + 1] = hand[1];
        handMap[jobID * 4 + 2] = hand[2];
        handMap[jobID * 4 + 3] = hand[3];
    }


    /** RENDER */

    /**
     *  drawTrait generates an <image> element using base64 encoded PNGs
     *  @param trait the trait storing the PNG data
     *  @return the <image> element
     */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            trait.png,
            '"/>'
        ));  
    }

    /**
     *  drawSVGWithPeopleFirstPart generates the first part of an entire SVG by composing multiple <image> elements for PNGs
     *  to avoid "Stack too deep, try removing local variables" error
     *  @param peopleTrait the People struct of the token to generate an SVG for
     *  @return a valid SVG of the People
     */
    function drawSVGWithPeopleFirstPart(IPeople.People memory peopleTrait) public view returns (string memory) {
        uint8 prof0Id = prof0Map[peopleTrait.job];
        string memory svgString = string(abi.encodePacked(
            prof0Id != 0 ? drawTrait(traitData[0][prof0Id]) : '',
            drawTrait(traitData[1][peopleTrait.skin]),
            drawTrait(traitData[2][peopleTrait.eyes]),
            drawTrait(traitData[3][peopleTrait.ear]),
            drawTrait(traitData[4][peopleTrait.mouth]),
            drawTrait(traitData[5][peopleTrait.nose])
        ));

        return svgString;
    }

    /**
     *  drawSVGWithPeople generates an entire SVG by composing multiple <image> elements for PNGs
     *  @param peopleTrait the People struct of the token to generate an SVG for
     *  @return a valid SVG of the People
     */
    function drawSVGWithPeople(IPeople.People memory peopleTrait) public view returns (string memory) {
        string memory svgString1 = drawSVGWithPeopleFirstPart(peopleTrait);
        uint8 handId = handMap[peopleTrait.job * 4 + peopleTrait.skin];
        uint8 prof1Id = prof1Map[peopleTrait.job];
        string memory svgString2 = string(abi.encodePacked(
            drawTrait(traitData[6][peopleTrait.glasses]),
            drawTrait(traitData[7][peopleTrait.hair]),
            drawTrait(traitData[8][peopleTrait.cloth]),
            handId != 0 ? drawTrait(traitData[9][handId]) : '',
            prof1Id != 0 ? drawTrait(traitData[10][prof1Id]) : ''
        ));

        return string(abi.encodePacked(
            '<svg id="people" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svgString1,
            svgString2,
            "</svg>"
        ));
    }

    /**
    * generates an attribute for the attributes array in the ERC721 metadata standard
    * @param traitType the trait type to reference as the metadata key
    * @param value the token's trait associated with the key
    * @return a JSON dictionary for the single attribute
    */
    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            traitType,
            '","value":"',
            value,
            '"}'
        ));
    }

    function compileAttributesWithPeople(IPeople.People memory peopleTrait) public view returns (string memory) {
        string memory traits = string(abi.encodePacked(
            attributeForTypeAndValue(_attrList[0], jobList[peopleTrait.job]), ',',
            attributeForTypeAndValue(_attrList[1], skinList[peopleTrait.skin]), ',',
            attributeForTypeAndValue(_attrList[2], traitData[2][peopleTrait.eyes].name), ',',
            attributeForTypeAndValue(_attrList[3], traitData[3][peopleTrait.ear].name), ',',
            attributeForTypeAndValue(_attrList[4], traitData[4][peopleTrait.mouth].name), ',',
            attributeForTypeAndValue(_attrList[5], traitData[5][peopleTrait.nose].name), ',',
            attributeForTypeAndValue(_attrList[6], traitData[6][peopleTrait.glasses].name), ',',
            attributeForTypeAndValue(_attrList[7], traitData[7][peopleTrait.hair].name), ',',
            attributeForTypeAndValue(_attrList[8], traitData[8][peopleTrait.cloth].name)
        ));

        return string(abi.encodePacked(
            '[',
            traits,
            ']'
        ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IPeople.People memory p = people.getTokenTraits(tokenId);
        string memory metadata = string(abi.encodePacked(
            "{", 
                '"name": "', 'People #', tokenId.toString(), '",',
                '"description": "PEOPLE!",', 
                '"image": "data:image/svg+xml;base64,', base64(bytes(drawSVGWithPeople(p))), '",', 
                '"attributes":', compileAttributesWithPeople(p),
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }

    function getAttrNumber() public view returns (uint8[9] memory) {
        return _attrNumber;
    }

    // BASE 64 - Written by Brech Devos
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getAttrNumber() external view returns (uint8[9] memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPeople {

    // struct to store each token's traits
    struct People {
        uint8 job;
        uint8 skin;
        uint8 eyes;
        uint8 ear;
        uint8 mouth;
        uint8 nose;
        uint8 glasses;
        uint8 hair;
        uint8 cloth;
    }

    function getTokenTraits(uint256 tokenId) external view returns (People memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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