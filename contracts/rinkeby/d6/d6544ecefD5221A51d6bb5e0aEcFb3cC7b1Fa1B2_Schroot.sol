// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Schroot is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private price = 10000000000000000; // 0.01 ETH

    string[] private weapons = [
    "Pepper Spray",
    "Throwing Stars",
    "Handcuffs",
    "Taser",
    "Asian-style Sword",
    "Nunchaku",
    "Baton",
    "Boomerang",
    "Brass Knuckles",
    "Sai Dagger",
    "Knife",
    "Sword",
    "Blowgun",
    "Whip",
    "Curved Sabre",
    "Reinforced Bow and Arrow",
    "Saber",
    "Dart",
    "Knife"
    ];

    string[] private skills = [
    "Surveillance",
    "Guitar",
    "Recorder",
    "German",
    "Goju Ryu Karate",
    "Survivalism",
    "Ping Pong",
    "Framing People",
    "Sleeping on a Fence"
    ];

    string[] private favorites = [
    "Heavy Metal",
    "The Crow",
    "Sci-Fi",
    "The Beatles",
    "Muscle Cars",
    "Judge Judy",
    "Baby Otters",
    "Paperback Writer",
    "Eleanor Rigby"
    ];

    string[] private clothes = [
    "Mustard colored short sleeve shirt",
    "Dark Check style Necktie",
    "Two-button Brown suit jacket",
    "Motorcycle helmet",
    "Motorcycle jacket",
    "Metal clear lens glasses",
    "Casio calculator watch",
    "Pager",
    "Nokie Flip Phone"
    ];

    string[] private pets = [
    "Prahna",
    "Frog",
    "Artic Wolf",
    "Henrietta the Raccoon",
    "Opossum"
    ];

    string[] private knowledge = [
    "Health Care Plans",
    "Real Estate",
    "Notary Public",
    "Beets",
    "Former Volunteer Sheriff Deputy",
    "Bears",
    "717-555-0177"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }

    function getSkill(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SKILL", skills);
    }

    function getFavorite(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FAVORITE", favorites);
    }

    function getClothes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLOTHES", clothes);
    }

    function getPets(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "PETS", pets);
    }

    function getKnowledge(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "KNOWLEDGE", knowledge);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory output) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        output = sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[13] memory parts;

        string memory SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><rect x="0" y="0" width="1000" height="1000" fill="#feca1f"/>';
        string memory SVG_TITLE = '<text transform="translate(37.38 99.31)" font-size="100" fill="#000" font-family="AmericanTypewriter-Semibold, American Typewriter" font-weight="600">schroot</text>';
        string memory SVG_PIC = '<path id="path0" fill-rule="evenodd" clip-rule="evenodd" d="M759.3,470.4c-75.6,18.5-76.3,104-52.4,158.8c12.5,23.7,4,45.9,26.5,43c4.9,25.4,5.9,48.4,27.3,58.6c-10.4,7.2-13.1,18.4-20,26.3c-8.5,5.3-18.3,20.6-28,23.8c-30.1,0.3-9.3,15.4-21.8,30.6c1.3,23-18,52.7-20.8,69.2c6.3,7.3,26.2,14,35.1,16.6c2.5,14.2-11.9,44.1-4.3,54.6c13.8,11.2,11.9-35.9,15.5-49.5c-0.3-4.2,3.3-1.2,7-0.6c9.1,2.9,12.8,2.4,21.1,4.2c0.9,10.2,0.8,20.4-0.2,43.4c-0.7,6.2,4.3,9.2,4.4,0.2c0-29.5,3.5-100.1-8.6-124.5c-3.7,15,6.4,32.5,3.3,67.7c-12.9-0.7-35.9-8.7-45.6-14.3c-2.7-1.7-9.2-4.9-9.4-6.5c-5.9-6.6-6,5.7,2.4,7.9c12.5,10.3,39.8,14.3,53.5,19.7c-15.3,1.1-40.9-7.9-57.2-13.9c-3.4-1.5-15.5-7.6-12.8-8.7c7.3-4,14.5-33.8,17.5-42.8c1.7-7.4,3.1-15.8,3.7-21.2c4.5-2.2,11.3-10.5,4.3-9.8c-1.3-13.5-1.1-16.5,13.2-17.1c5.7-0.7,5-0.2,20.5-15.5c5.6-4.1,11.4-13.7,13-8.4c6.5,12.2,31,39.5,40.5,46.3c3-5.5,1.4-31.5,5.7-37.1c0,1.8,5.9,10.9,9.7,14.9c15.8,20.6-7.1,60.7-18.7,84c-16.7,19.6-8.6,27.1,1.3,47.2c8.9,24.3,7.8,4.6,15.4,0.5c5.1,1.6-0.8-8.7,6.1-1.1c15.1,12.2,25.4,28.5,35.8,35c7.5-12.9,35.2-39,25.8-53.2c-9.3-15.2,12.1-1.6,15.9-1.3c6.2,1.9,16.7-12.5,21.9-12.9c3,23.4,0.8,60.2,18.1,68.7c17.6,8.5-24-55.9,4.1-56.8c1.6,12.6,4.5,24.9,9,37.4c4.8,19.5,11.3,13,4.4-0.8c-2.1-11.7-15.5-36.3-4.5-42.6c13.7-10.4,15.3-6.8,13.3-15.4c-8.8-19.9-13.4-43.8-17.7-64.9c-0.9-11.7-8.7-12.5-18.9-17.1c-2-1.8,0.2-8.9-4.5-8.3c-10.3,1.8-33.4-18.7-46-32.6c-14-34.6,5.6-8.9,14.3-42c6.9-17.3,2.8-39.2,3-53.9c16-11,8.2-41.5,12.9-54.9c30.7-43.9,1.4-124.5-56.6-124.5c-8.9-1.8-22.7,0.9-29.6,6.2C792.5,473.3,777.7,469.5,759.3,470.4 M793.9,507.1c12.4,1.8,11.4,7.3,20.6,6.6c40.4-29.3,40.7,33.5,18.6,53.4c6.3,5,19.4-11.7,23-17.2c1.1,12.1-8.8,12.6-5,18.1c12.1-0.5,11.7-32.5,16.9-37.8c13.7,5.8-22.1,51.7,5.8,31.9c9.8-0.7,7.7,29.4,7.2,39.6c-9.3,2.7-26.4-0.4-36.7,2.2c-5.6,2-19.3-1.7-18.6,3.9c26.7,10.3,77.8-24.9,58.1,35.1c-4.5,13.4-25,17.4-36.4,11.8c-13.3-6.7-17-24.1-20.9-40.5c3.6-9.8-16.5-8.8-24-5.3c-3.2-5.7-59.7,2.9-58.9-5.9c-6.9-10.6-2.4-12.5,1-20.3c-0.2-10.9,25.8,8,29.5-2c1.5-2.8,1.5-2.8-6.3-6.9c-10.2-3.7,9-1.9,10.8-4.2c3-2.1,2.2-8.2,5.7-9.6c5.9-3.7-0.3-8.8-4.3-11.7C758.4,535.7,764.8,496.7,793.9,507.1 M860.8,541.4c-0.3,1.5-0.6,0.9-0.3-0.3C860.8,539.7,861.1,540,860.8,541.4 M711.9,611.3c9.2,7.8,13.4,23.1,13.4,35.1c-3.5,2.8,12.8,20.7,2.7,20.7c-11.8,0-4.2-18.8-11.4-26c-5.3-10.7,2,3.4,3.2-1.7C725.1,635.6,690.2,611,711.9,611.3 M750.7,612c14.8,2.9,70.5-14.7,39,34c-17.1,21.7-50.7,7-51.1-18.8C734.8,613.2,736.3,609.6,750.7,612 M820.2,611.8c4.6,15.8,24.7,55.2-7.3,47.7c-4.5-2.2-7.2-1-5.1,2.2c7.9,8.8,24.5,3.1,27.3-7.4c8,10.2,29,12.4,40.2,5.4l0.2,2.1c10.5,45-13.4,78-60.8,71.4c-17.7-1.5-42.4,2.7-55.4-10.3c-11-16.9-18.4-56-13.5-66.6c21.3,19.6,33.2-3.9,47.3,8c2.9,2.1,2.4-1.4,4-1.3c1.7,0.9,3.5,0.4,4.3-1.2c1.2-2.5,0.7-3.5-1.5-3.5c-5.6,1.1-8.8-13-1.3-12.9C819,626.4,797,606.6,820.2,611.8 M803.8,617.9c0.3,1-0.4,2.6-0.8,3.7C803.1,620.4,802.9,613.5,803.8,617.9 M732.5,619.9c1.2,1-4.5,1.5-1.6,0.1C732.1,619.3,732.3,619.3,732.5,619.9 M816.4,679.1c-5.3,1.7-26.6,3.2-28.2,10.8c17.4,0.9,39.3-14.8,59.9-0.1c1.1,1.3,2-0.7,2.3,0.7c3.2,7.7,6-4.7,2.8-6.8C842.4,683.6,829.9,676.1,816.4,679.1 M783.8,685.1c-1.5,0.6-1.9,4.3-0.8,6.7C786.4,698.9,790.7,681,783.8,685.1 M836.8,693.4c-6.6,7.9-28.8-0.6-31.2,3.7c-8.5,11.2,18.3,18.9,26.3,6.2C834.4,701.6,843.9,694,836.8,693.4 M768.4,734.2c8.5,3.8,15.3,14.3,25.5,17.8c-5.3,14.4-9.7,31.6-10,47.4C764.1,780,729.3,747.7,768.4,734.2 M848.4,735.2c-4.4,14.9-30.1,18.4-39.1,12.5C822.7,734.6,830.6,738.9,848.4,735.2 M853.8,738.2c7.8,13.3,3.1,23.2-1.8,35.6c-2.2,5.6-4.9,19.1-5.8,13.2c-1.7-10.1-6.2-29.3-7.8-34.5C844.7,752.8,850.1,737.5,853.8,738.2 M799.2,754.6c-3.1,2.5-1-0.7,0.2-0.5C799.7,754.1,799.7,754.2,799.2,754.6 M833,756.5c2.4,0.6,3.6,9.8-0.8,5.1C823.1,755.9,821.4,753.7,833,756.5 M812.5,757.5c1.5,10.4,25.3,11,19,22.5C826.4,777.4,784.7,753.2,812.5,757.5 M872.3,767.5c69.8,55.8,45.1,10,69.9,99.8c-47,33.3-25.2,17.2-36.6-28.6c3.5-32.8-40.5-28.3-62.4-19.3c-2.9,2.3-5.3-14.2-7.2-18.4c-5.6-13.4,0.2-18.6,2.3-28.6c1.6,0.1,3.3,18.5,4.5,20.3c3.7,26.3,15.9-28.9,19.6-35.1C863.6,756.3,866.9,763.1,872.3,767.5M802.2,776.8c0.7,3.8,20.4,12,15.4,13.9C810.6,794.4,791.7,763.7,802.2,776.8 M827.4,794.4c4.3-0.5,3.3,5.3,4.9,10.7C825.3,800.6,806,794.7,827.4,794.4 M814.1,810.1c10.9,7.7,27.5,10.3,27.5,26.6c-6.4,0.8-24.7-15.9-31.6-14.7C810.7,820,809.8,805.8,814.1,810.1 M882.4,818.3c7.2,1.6,18,3.4,17.9,11.3c-15.5-0.4-30.1-6-47.1,1.3c-4.7,1.2-1.2,7,2.4,4.5c11.8-5.7,31-2.3,42.9-0.3c3.5,0.6,12.3,45.9,3.6,45.4c-6.6,2.4-12.7,13.4-19.5,10.6c-6.9-2.6-12-4-19.3-4.9c-4.5-12.4-8.4-22.7-12.6-36.3c-2.6-10.1-5.4-16.1-7.3-24.6C852.7,820.1,869.9,816.6,882.4,818.3 M813.1,840.3c12,10,36.2,11.2,38.6,28c-15.2-2.9-30.2-14.9-44.2-20.6C809.4,840.7,806.2,834.3,813.1,840.3 M803.4,841.3c-0.3,3.3-0.4,2.6-2.1,2.9C802.3,842.5,804.2,834.3,803.4,841.3 M806.6,864.8c10.1,8.1,43.8,27.9,53,25.6c0.6,1,7.9,15.5,6.7,17.4C859.4,912.7,788.9,868.3,806.6,864.8 M794.9,865.5c4.2,1.9-1.6,10.3-2,12.1c-0.9-0.7-3.6-5.5-5.2-4.9C790.5,870.6,791.5,860.9,794.9,865.5 M944.4,872.7c9.4,4.3-31.7,29.6-33.2,22.2c-1.6-3.7,5.6-4.6,8.2-6.5C924.5,887.7,944.2,869.1,944.4,872.7 M805.2,892.8c27.2,30.3,65.3,22.2,36.8,51.5c-10.2-5.8-33.1-33-42-42.2c-5.8-5.9-3.7-7.4-1.7-14.7C798.8,884.5,802.5,891.1,805.2,892.8 M781.2,890.3c4.6,12.4,21.7,22.4,10.3,31.1C790.4,916.8,769.9,879.9,781.2,890.3"/>';

        parts[0] = '<style>.base { fill: black; font-family: "American Typewriter", serif; font-size: 40px; }</style><text x="40" y="200" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="40" y="250" class="base">';

        parts[3] = getSkill(tokenId);

        parts[4] = '</text><text x="40" y="300" class="base">';

        parts[5] = getFavorite(tokenId);

        parts[6] = '</text><text x="40" y="350" class="base">';

        parts[7] = getClothes(tokenId);

        parts[8] = '</text><text x="40" y="400" class="base">';

        parts[9] = getPets(tokenId);

        parts[10] = '</text><text x="40" y="450" class="base">';

        parts[11] = getKnowledge(tokenId);

        parts[12] = '</text></svg>';

        string memory output = string(abi.encodePacked(SVG_HEADER, SVG_TITLE, SVG_PIC, parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        output = string(abi.encodePacked(output, parts[6], parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Schroot #', toString(tokenId), '", "description": "Schroot is randomized Dwight gear generated and stored on chain..", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function getGreatness(uint256 tokenId, string memory keyPrefix) public pure returns (uint256 greatness) {
        uint256 rand = uint256(keccak256(abi.encodePacked(string(abi.encodePacked(keyPrefix, toString(tokenId))))));
        greatness = rand % 21;
    }

    function mint(uint256 amount) public payable {
        require(price * amount <= msg.value, "Don't fuck around.");
        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
            claim(_tokenIds.current());
        }
    }

    function claim(uint256 tokenId) internal {
        require(tokenId > 0 && tokenId < 8338, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
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

    constructor() ERC721("Schroot", "SCHROOT") Ownable() {}

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        uint256 _each = address(this).balance / 5;
        require(payable(0x00796e910Bd0228ddF4cd79e3f353871a61C351C).send(_each));   // sara
        require(payable(0x30119E6DA1578F721cf5e9945b148Ae2E512ca01).send(_each));   // robo overlord
        require(payable(0x3546BD99767246C358ff1497f1580C8365b25AC8).send(_each));   // gotrilla
        require(payable(0xe0Ea9a993870eA3c8E883DC3Ecc9596D5073C8Cb).send(_each));   // robo rambo
        require(payable(0x7656b24015973209cb45Db8d1F1A63d670eF02ed).send(_each));   // community
    }
}

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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
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