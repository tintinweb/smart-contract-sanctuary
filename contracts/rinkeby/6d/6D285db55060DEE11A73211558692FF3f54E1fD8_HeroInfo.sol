// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract HeroInfo is Ownable {

    string[] internal names = [
        "Adriana"
    ];

    string[] internal shortDescriptions = [
        "A lone adventurer"
    ];

    // There can be only three types: Cliche, Standard, Original
    string[] internal typeOfs = [
        "Cliche"
    ];

    string[] internal birthdays = [
        "1631305906"
    ];

    string[] internal classes = [
        "Paladin"
    ];

    string[] internal subClasses = [
        "Oath of Conquest"
    ];

    string[] internal races = [
        "Aasimar"
    ];

    string[] internal subRaces = [
        "Defender"
    ];

    string[] internal backstories = [
        "Soldier"
    ];

    string[] internal levels = [
        "1"
    ];

    string[] internal alignments = [
        "Lawful Evil"
    ];

    string[] internal characterSheets = [
        "QmejtwD4NJjAimNosWAWX2eLcTwfoaVGGptURuThsGmg2q"
    ];

    function getName(uint256 tokenId) public view returns (string memory) {
        return names[tokenId];
    }

    function getShortDescription(uint256 tokenId) public view returns (string memory) {
        return shortDescriptions[tokenId];
    }

    function getType(uint256 tokenId) public view returns (string memory) {
        return typeOfs[tokenId];
    }

    function getBirthday(uint256 tokenId) public view returns (string memory) {
        return birthdays[tokenId];
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        return classes[tokenId];
    }

    function getSubClass(uint256 tokenId) public view returns (string memory) {
        return subClasses[tokenId];
    }

    function getRace(uint256 tokenId) public view returns (string memory) {
        return races[tokenId];
    }

    function getSubRace(uint256 tokenId) public view returns (string memory) {
        return subRaces[tokenId];
    }

    function getBackstory(uint256 tokenId) public view returns (string memory) {
        return backstories[tokenId];
    }

    function getLevel(uint256 tokenId) public view returns (string memory) {
        return levels[tokenId];
    }

    function getCharacterSheet(uint256 tokenId) public view returns (string memory) {
        return characterSheets[tokenId];
    }

    function addHeroInfo(
        string memory name,
        string memory shortDescription,
        string memory typeOf,
        string memory birthday,
        string memory class,
        string memory subClass,
        string memory race,
        string memory subRace,
        string memory backstory,
        string memory level,
        string memory alignment,
        string memory characterSheet
    ) external onlyOwner returns(uint256) {
        names.push(name);
        shortDescriptions.push(shortDescription);
        typeOfs.push(typeOf);
        birthdays.push(birthday);
        classes.push(class);
        subClasses.push(subClass);
        races.push(race);
        subRaces.push(subRace);
        backstories.push(backstory);
        levels.push(level);
        alignments.push(alignment);
        characterSheets.push(characterSheet);
        return names.length - 1;
    }

    function build(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        bytes memory _name = abi.encodePacked(getName(tokenId));
        bytes memory _characterSheet = abi.encodePacked(getCharacterSheet(tokenId));
        string memory _shortDescriptionString = getShortDescription(tokenId);
        bytes memory _shortDescription = abi.encodePacked(_shortDescriptionString);
        bytes memory _tokenId = abi.encodePacked(toString(tokenId));
        string[8] memory loot = [
            getType(tokenId),
            _shortDescriptionString,
            getClass(tokenId),
            getSubClass(tokenId),
            getRace(tokenId),
            getSubRace(tokenId),
            getBackstory(tokenId),
            getLevel(tokenId)
        ];

        bytes memory attrs = abi.encodePacked(
            makeAttr("Type", loot[0], "none"),
            ",",
            makeAttr("Birthday", loot[1], "date"),
            ",",
            makeAttr("Class", loot[2], "none"),
            ",",
            makeAttr("Sub-Class", loot[3], "none"),
            ",",
            makeAttr("Race", loot[4], "none"),
            ",",
            makeAttr("Sub-Race", loot[5], "none"),
            ",",
            makeAttr("Backstory", loot[6], "none"),
            ",",
            makeAttr("Level", loot[7], "ranking")
        );

        bytes memory svg = makeSvg(_name, _tokenId, loot);

        return makeJson(_name, _characterSheet, _shortDescription, svg, attrs);
    }

    function makeJson(
        bytes memory _name,
        bytes memory _characterSheet,
        bytes memory _shortDescription,
        bytes memory _svg,
        bytes memory _attrs
    ) internal pure returns (string memory) {
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name, '", "external_url": "https://ipfs.io/ipfs/', _characterSheet,
                '", "description": "`', _shortDescription, '` *** This special character for Dungeons and Dragons Game is handmade, well balanced and stored on chain. Skills, equipment, and other functionality are intentionally specified so you will not be bothered creating ones. Feel free to play this complete DnD character!", "image_data": "data:image/svg+xml;base64,',
                Base64.encode(_svg),
                '", "attributes": [',
                _attrs,
                "]}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function textTag(
        string memory _prefixTxt,
        string memory _txt,
        string memory _yPos
    )
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked('<text x="8" y="', _yPos, '">', _prefixTxt, _txt, "</text>");
    }

    function makeAttr(string memory _k, string memory _v, string memory _d)
        internal
        pure
        returns (bytes memory)
    {
        if (keccak256(abi.encodePacked(_d)) == keccak256(abi.encodePacked('none'))) {
            return
                abi.encodePacked('{"trait_type": "', _k, '", "value": "', _v, '"}');
        } else if (keccak256(abi.encodePacked(_d)) == keccak256(abi.encodePacked('ranking'))) {
            return
                abi.encodePacked('{"trait_type": "', _k, '", "value": ', _v, '}');
        } else {
            return
                abi.encodePacked('{"trait_type": "', _k, '", "value": "', _v, '", "display_type": "', _d, '"}');
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    function makeSvg(bytes memory _name, bytes memory _tokenId, string[8] memory _loot)
        internal
        pure
        returns (bytes memory)
    {
        string
            memory head = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><clipPath id="clp"><rect width="100%" height="100%"/></clipPath><pattern id="star" viewBox="0,0,10,10" width="10%" height="10%"><polygon points="0,0 2,5 0,10 5,8 10,10 8,5 10,0 5,2" fill="gold"/></pattern></defs><style>text{fill:#fff;font-family:Helvetica;font-size:13px}.tag{font-size:24px}ellipse{clip-path:url(#clp)}</style><rect width="100%" height="100%" fill="#002366"/><ellipse cx="320" cy="320" rx="130" ry="130" fill="url(#star)"/>';

        bytes memory loots = abi.encodePacked(
            textTag("Type: ", _loot[0], "50"),
            textTag("Short story: ", _loot[1], "77"),
            textTag("Class: ", _loot[2], "96"),
            textTag("Sub-Class: ", _loot[3], "119"),
            textTag("Race: ", _loot[4], "142"),
            textTag("Sub-Race: ", _loot[5], "165"),
            textTag("Backstory: ", _loot[6], "188"),
            textTag("Level: ", _loot[7], "211")
        );

        return
            abi.encodePacked(
                head,
                abi.encodePacked(
                    '<text x="8" y="30" class="tag">',
                    _name,
                    "</text>",
                    '<text x="8" y="335">Token ID: ',
                    _tokenId,
                    "</text>"
                ),
                loots,
                "</svg>"
            );
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma abicoder v2;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}