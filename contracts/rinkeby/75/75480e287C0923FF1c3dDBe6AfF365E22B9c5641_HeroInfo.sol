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
            memory head = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><clipPath id="clp"><rect width="100%" height="100%"/></clipPath><pattern xmlns="http://www.w3.org/2000/svg" patternUnits="userSpaceOnUse" width="25" height="13" patternTransform="scale(2) rotate(0)" id="star"><path d="M25.044 22.25c0 6.904-5.596 12.5-12.5 12.5s-12.5-5.596-12.5-12.5 5.596-12.5 12.5-12.5c5.786 0 10.655 3.932 12.079 9.27.274 1.03.421 2.113.421 3.23m0-9a2.5 2.5 0 00-2.363 1.688 12.5 12.5 0 011.672 3.212v.002a2.5 2.5 0 10.69-4.902zm-.037-5a7.5 7.5 0 00-6.125 3.227 12.5 12.5 0 016.121 11.773h.04a7.5 7.5 0 10-.036-15zm.023-5a12.5 12.5 0 00-10.998 6.588c.097.012.193.025.29.039h.005c.097.014.194.029.29.045h.003c.194.033.388.07.58.113h.004a12.5 12.5 0 011.123.3l.02.007.006.002a12.496 12.496 0 011.077.403l.032.01.033.016c.166.07.33.145.492.223l.016.008.004.002c.176.086.35.177.523.271l.006.002c.085.047.17.094.254.143l.004.002c.085.049.169.099.252.15l.004.002c.083.051.166.103.248.156l.004.002c.082.052.163.106.244.16l.004.002.24.168.004.002c.899.618 1.672 1.418 2.385 2.219l.004.004c.125.151.246.306.363.463l.004.004c.058.078.116.157.172.236l.004.004c.056.08.112.16.166.24l.002.004c.577.817.987 1.72 1.359 2.633l.002.004c.034.091.066.183.098.275l.002.004c.032.092.062.185.092.278l.002.003c.03.094.058.188.086.282l.002.004c.027.093.053.186.078.28l.002.005c.025.095.05.19.072.285l.002.004c.023.095.046.19.067.285.136.57.19 1.141.25 1.713l.003.05.002.04c.013.178.022.356.028.535v.023c.003.098.004.195.004.293v.014a12.5 12.5 0 01-.127 1.777c-.184 1.281-.582 2.34-1.002 3.412a12.505 12.505 0 01-.36.723c.494.059.99.088 1.488.088 6.904 0 12.5-5.596 12.5-12.5s-5.596-12.5-12.5-12.5zm-24.986 10a2.5 2.5 0 10.691 4.902 12.5 12.5 0 011.672-3.214A2.5 2.5 0 00.044 13.25zm-.037-5a7.5 7.5 0 10.078 15 12.5 12.5 0 016.121-11.773A7.5 7.5 0 00.007 8.25zm-.065-5c-6.898.008-12.486 5.602-12.486 12.5 0 6.904 5.596 12.5 12.5 12.5.525 0 1.05-.034 1.57-.1a12.5 12.5 0 019.448-18.3A12.5 12.5 0 00-.044 3.25zm12.602 3.5a2.5 2.5 0 00-2.39 1.773c.3.425.575.868.82 1.327a12.5 12.5 0 013.058-.012 12.5 12.5 0 01.875-1.399 2.5 2.5 0 00-2.363-1.689zm-1.57 3.1a12.5 12.5 0 013.058-.012M12.507 1.75a7.5 7.5 0 00-6.15 3.266 12.5 12.5 0 014.617 4.834 12.5 12.5 0 013.058-.012 12.5 12.5 0 014.676-4.861 7.5 7.5 0 00-6.201-3.227zm5.226 9.129a12.47 12.47 0 010 0zM10.974 9.85a12.5 12.5 0 013.058-.012m3.702 1.041a12.493 12.493 0 01-.001 0zM12.53-3.25a12.5 12.5 0 00-11.004 6.6 12.5 12.5 0 019.448 6.5 12.5 12.5 0 013.058-.012 12.5 12.5 0 019.526-6.498 12.5 12.5 0 00-11.014-6.59zm5.203 14.129a12.47 12.47 0 010 0zM25.043.25a2.5 2.5 0 00-2.362 1.688c.323.447.616.915.877 1.4a12.5 12.5 0 011.472-.088h.014a12.5 12.5 0 012.389.23 2.5 2.5 0 00-2.39-3.23zm-.036-5a7.5 7.5 0 00-6.125 3.227 12.5 12.5 0 014.676 4.86 12.5 12.5 0 011.472-.087h.014c2.5 0 4.944.75 7.014 2.152A7.5 7.5 0 0025.007-4.75zm-1.449 8.088a12.5 12.5 0 011.472-.088h.014m-.014-13a12.5 12.5 0 00-10.998 6.59 12.5 12.5 0 019.526 6.498 12.5 12.5 0 011.472-.088h.014a12.5 12.5 0 0110.678 6 12.5 12.5 0 001.822-6.5c0-6.904-5.596-12.5-12.5-12.5zM14.69 8.75a12.529 12.529 0 000 0zm3.043 2.129a12.47 12.47 0 010 0zM.043.25a2.5 2.5 0 00-2.394 3.217A12.5 12.5 0 01-.058 3.25h.014c.525 0 1.05.034 1.57.1a12.5 12.5 0 01.881-1.41A2.5 2.5 0 00.044.25zm-.036-5A7.5 7.5 0 00-6.987 5.355 12.5 12.5 0 01-.057 3.25h.013c.525 0 1.05.034 1.57.1a12.5 12.5 0 014.682-4.873A7.5 7.5 0 00.007-4.75zm.023-5c-6.898.008-12.486 5.602-12.486 12.5a12.5 12.5 0 001.78 6.428A12.5 12.5 0 01-.059 3.25h.014c.525 0 1.05.034 1.57.1a12.5 12.5 0 019.532-6.51A12.5 12.5 0 00.044-9.75zM9.722 7.951a12.497 12.497 0 010 0z" stroke-width="1" stroke="gold" fill="#002366"/></pattern></defs><style>text{fill:#fff;font-family:Courier New;font-size:13px}.tag{font-size:24px}ellipse{clip-path:url(#clp)}</style><rect width="100%" height="100%" fill="#002366"/><ellipse cx="400" cy="200" rx="150" ry="350" fill="url(#star)"/>';

        bytes memory loots = abi.encodePacked(
            textTag("Backstory: ", _loot[6], "50"),
            textTag("Class: ", _loot[2], "73"),
            textTag("Level: ", _loot[7], "96"),
            textTag("Sub-Class: ", _loot[3], "119"),
            textTag("Race: ", _loot[4], "142"),
            textTag("Sub-Race: ", _loot[5], "165"),
            textTag("Type: ", _loot[0], "188"),
            textTag("Description: ", _loot[1], "211")
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

