/**
 *Submitted for verification at FtmScan.com on 2021-12-10
*/

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from:
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.7;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)



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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/IFantomonTrainer.sol





interface IFantomonTrainer {

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    function getKinship(uint256 _tokenId) external view returns (uint256);
    function getFlare(uint256 _tokenId) external view returns (uint256);
    function getCourage(uint256 _tokenId) external view returns (uint256);
    function getWins(uint256 _tokenId) external view returns (uint256);
    function getLosses(uint256 _tokenId) external view returns (uint256);
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    function getStatus(uint256 _tokenId) external view returns (uint8);
    function getRarity(uint256 _tokenId) external view returns (uint8);
    function getClass(uint256 _tokenId) external view returns (uint8);
    function getFace(uint256 _tokenId) external view returns (uint8);
    function getHomeworld(uint256 _tokenId) external view returns (uint8);
    function getTrainerName(uint256 _tokenId) external view returns (string memory);
    function getHealing(uint256 _tokenId) external view returns (uint256);
    /* End getters
     **************************************************************************/
}


// File contracts/FantomonTrainerGraphicsV1.sol

/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from:
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/





contract FantomonTrainerGraphicsV1 is Ownable {

    string public INSTRUCTIONS = "Call tokenURI(tokenId). The returned metadata returns two relevant fields: 'art' and 'image'. In HTML, display them in that order ('art' then 'image') via two 'img' elements each of which uses `position: absolute`. This will overlay the Trainer stats SVG on top of the IPFS art PNG.";

    IFantomonTrainer trainers_;

    constructor (IFantomonTrainer _trainers) {
        trainers_ = _trainers;
    }

    //string private _baseURIextended = "ipfs://bafybeib3qdfhsed43gsoj3l6lckwvbqgb7svficyyyxp53lxzn6lcouwmu/"
    string private _baseURIextended = "https://ipfs.io/ipfs/bafybeib3qdfhsed43gsoj3l6lckwvbqgb7svficyyyxp53lxzn6lcouwmu/";

    string[5] private STATUSES = ["WATCHING ANIME", "PREPARING FOR BATTLE", "BATTLING", "TREATING WOUNDS", "LOST"];

    uint8 constant private RESTING   = 0;
    uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING  = 2;
    uint8 constant private HEALING   = 3;
    uint8 constant private LOST      = 4;

    string[4] private RARITIES = ["Common", "Rare", "Epic", "Legendary"];

    string[16] private CLASSES = [
        // 60%
        "Botanist",
        "Zoologist",
        "Hydrologist",
        "Entomologist",

        // 30%
        "Biochemist",
        "Microbiologist",
        "Biotechnologist",
        "Biomedical Engineer",

        // 9%
        "Geneticist",
        "Astrophysicist",
        "String Theorist",
        "Quantum Physicist",

        // 1%
        "Ent Mystic",
        "Ent Theorist",
        "Cosmic Explorer",
        "Ancient Ent Master"
    ];

    string[7] private FACES = ["1", "2", "3", "4", "5", "6", "7"];

    string[13] private WORLDS = [
        // 60%
        "Gunka",
        "Sha'afta",
        "Jiego ",
        "Beck S68",
        "Gem Z32",

        // 30%
        "Junapla",
        "Strigah",
        "Mastazu",

        // 9%
        "Clyve R24",
        "Larukin",
        "H-203",

        // 1%
        "Ancient Territories",
        "Relics Rock"
    ];

    // Setters
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    // Getters
    function getTrainerName(uint256 _tokenId) public view returns (string memory) {
        return trainers_.getTrainerName(_tokenId);
    }
    function getKinship(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getKinship(_tokenId));
    }
    function getFlare(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getFlare(_tokenId));
    }
    function getHealing(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getHealing(_tokenId));
    }
    function getCourage(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getCourage(_tokenId));
    }
    function getWins(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getWins(_tokenId));
    }
    function getLosses(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getLosses(_tokenId));
    }
    function getClass(uint256 _tokenId) public view returns (string memory) {
        return CLASSES[trainers_.getClass(_tokenId)];
    }
    function getFace(uint256 _tokenId) public view returns (string memory) {
        return FACES[trainers_.getFace(_tokenId)];
    }
    function getHomeworld(uint256 _tokenId) public view returns (string memory) {
        return WORLDS[trainers_.getHomeworld(_tokenId)];
    }
    function getRarity(uint256 _tokenId) public view returns (string memory) {
        return RARITIES[trainers_.getRarity(_tokenId)];
    }
    function getStatus(uint256 _tokenId) public view returns (string memory) {
        return STATUSES[trainers_.getStatus(_tokenId)];
    }
    function getImageURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_baseURIextended, getRarity(_tokenId), getFace(_tokenId)));
    }

    // Visualizations
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string[33] memory parts;
        uint8 x = 0;
        //parts[x]  = '<svg style="width: 50vh; height: 100vh" viewbox="0 0 246 448" preserveaspectratio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg"><style>.base { fill: black; font-family: Courier; font-size: 3.8vh; }</style><style>.trailer { fill: white; font-family: Courier; font-size: 2.8vh; }</style><style>.trailerGen { fill: gold; font-family: Courier; font-size: 2.8vh; }</style>'; x++;
        parts[x]  = '<svg style="width: 50vh; height: 100vh" xmlns="http://www.w3.org/2000/svg"><style>.base { fill: black; font-family: Courier; font-size: 3.8vh; }</style><style>.trailer { fill: white; font-family: Courier; font-size: 2.8vh; }</style><style>.trailerGen { fill: gold; font-family: Courier; font-size: 2.8vh; }</style>'; x++;
        parts[x]  = '<text style="transform:translate(27vh, 5.58vh)" text-anchor="middle" font-weight="bold" class="base">'; x++;
        parts[x]  =     getTrainerName(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text style="transform:translate(3vh, 54.24vh)" font-weight="bold" class="base">'
                        'Kinship: '; x++;
        parts[x]  =     getKinship(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text style="transform:translate(3vh, 58.48vh)" font-weight="bold" class="base">'
                        'Flare: '; x++;
        parts[x]  =    getFlare(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text style="transform:translate(3vh, 62.72vh)" font-weight="bold" class="base">'
                        'Healing: '; x++;
        parts[x] =     getHealing(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 66.96vh)" font-weight="bold" class="base">'
                        'Courage: '; x++;
        parts[x]  =    getCourage(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 71.20vh)" class="base">'
                        'Wins: '; x++;
        parts[x] =     getWins(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 75.44vh)" class="base">'
                        'Losses: '; x++;
        parts[x] =     getLosses(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 81.47vh)" class="trailer">'
                        'Class: '; x++;
        parts[x] =     getClass(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 84.82vh)" class="trailer">'
                        'Homeworld: '; x++;
        parts[x] =     getHomeworld(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 88.16vh)" class="trailer">'
                        'Rarity: '; x++;
        parts[x] =     getRarity(_tokenId); x++;
        parts[x] = '</text>'
                    '<text style="transform:translate(3vh, 92.85vh)" class="trailer">'
                        'Status: '; x++;
        parts[x] =     getStatus(_tokenId); x++;
        if (trainers_.getStatus(_tokenId) == RESTING) {  // if RESTING, green box
            parts[x] = '</text><rect x="2vh" y="89.95vh" width="38.75vh" height="3.79vh" style="fill:lime;stroke:lime;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == PREPARING) {  // if PREPARING, yellow box
            parts[x] = '</text><rect x="2vh" y="89.95vh" width="49vh" height="3.79vh" style="fill:yellow;stroke:yellow;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == BATTLING) {  // if BATTLING, blue box
            parts[x] = '</text><rect x="2vh" y="89.95vh" width="29vh" height="3.79vh" style="fill:cyan;stroke:cyan;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == HEALING) {  // if HEALING, red box
            parts[x] = '</text><rect x="2vh" y="89.95vh" width="40.25vh" height="3.79vh" style="fill:red;stroke:red;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else {  // if (trainers_.getStatus(_tokenId) == LOST) {  // if LOST, magenta box
            parts[x] = '</text><rect x="2vh" y="89.95vh" width="22.25vh" height="3.79vh" style="fill:magenta;stroke:magenta;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        }
        x++;
        parts[x] = '<text style="transform:translate(3vh, 97vh)" font-weight="bold" class="trailerGen">'
                        'Generation 1'
                    '</text>'
                    '<text style="transform:translate(52vh, 97vh)" text-anchor="end" class="trailer">#'; x++;
        parts[x] =     toString(_tokenId); x++;
        parts[x] = '</text>'; x++;
        parts[x] = '</svg>'; x++;

        uint8 i;
        string memory output = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        for (i = 9; i < 33; i += 8) {
            output = string(abi.encodePacked(output, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }

        x = 0;
        parts[x] = '{"name":"Fantomon Trainer #'                     ; x++ ;
        parts[x] = toString(_tokenId)                                ; x++ ;
        parts[x] = ': '                                              ; x++ ;
        parts[x] = getTrainerName(_tokenId)                          ; x++ ;
        parts[x] = '", "trainerId":"'                                ; x++ ;
        parts[x] = toString(_tokenId)                                ; x++ ;
        parts[x] = '", "art":"'                                      ; x++ ;
        parts[x] = getImageURI(_tokenId)                             ; x++ ;
        parts[x] = '", "attributes":[{"trait_type":"name","value":"' ; x++ ;
        parts[x] = getTrainerName(_tokenId)                          ; x++ ;
        parts[x] = '"}, {"trait_type":"avatar", "value":"'           ; x++ ;
        parts[x] = getFace(_tokenId)                                 ; x++ ;
        parts[x] = '"}, {"trait_type":"kinship", "value":"'          ; x++ ;
        parts[x] = getKinship(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"flare", "value":"'            ; x++ ;
        parts[x] = getFlare(_tokenId)                                ; x++ ;
        parts[x] = '"}, {"trait_type":"healing", "value":"'          ; x++ ;
        parts[x] = getHealing(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"courage", "value":"'          ; x++ ;
        parts[x] = getCourage(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"wins", "value":"'             ; x++ ;
        parts[x] = getWins(_tokenId)                                 ; x++ ;
        parts[x] = '"}, {"trait_type":"losses", "value":"'           ; x++ ;
        parts[x] = getLosses(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"class", "value":"'            ; x++ ;
        parts[x] = getClass(_tokenId)                                ; x++ ;
        parts[x] = '"}, {"trait_type":"homeworld", "value":"'        ; x++ ;
        parts[x] = getHomeworld(_tokenId)                            ; x++ ;
        parts[x] = '"}, {"trait_type":"rarity", "value":"'           ; x++ ;
        parts[x] = getRarity(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"status", "value":"'           ; x++ ;
        parts[x] = getStatus(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"generation", "value":"1"}], ' ; x++ ;

        string memory json = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        for (i = 9; i < 33; i += 8) {
            json = string(abi.encodePacked(json, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }

        json = Base64.encode(bytes(string(abi.encodePacked(json, '"description": "Fantomon Trainers are player profiles for the Fantomons Play-to-Earn game. Attributes (class, homeworld, rarity, and avatar#) are randomly chosen and stored on-chain. Stats are initialized to 1, wins and losses to 0, and can be increased via interactions in the Fantomon universe. Start playing at Fantomon.net", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
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
/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from:
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/