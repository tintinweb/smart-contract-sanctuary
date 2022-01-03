//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoBees.sol";
import "./Traits.sol";
import "./IAttack.sol";

contract Randomizer is Ownable {
    struct Commit {
        uint256 block;
        address sender;
    }

    mapping(uint256 => Commit) commits;
    mapping(address => bool) controllers;
    uint256 commitIndex;

    event CommitHash(address indexed sender, uint256 block, uint256 index);

    constructor() {}

    function createCommit() public {
        require(controllers[msg.sender], "Not permitted");
        commits[commitIndex].block = block.number;
        commits[commitIndex].sender = tx.origin;
        commitIndex += 1;
        emit CommitHash(tx.origin, block.number, commitIndex - 1);
    }

    function reset(uint256 to) public onlyOwner {
        commitIndex = to;
    }

    function revealSeed(uint256 i) public view returns (uint256) {
        if (i < commitIndex && block.number > commits[i].block) return uint256(keccak256(abi.encode(commits[i].sender, i, blockhash(commits[i].block))));
        return 0;
    }

    /**
     * enables an address
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint8 color;
        uint8 eyes;
        uint8 mouth;
        uint8 nose;
        uint8 hair;
        uint8 accessory;
        uint8 feelers;
        uint8 strength;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increaseTokensPot(address _owner, uint256 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    function mint(
        address addr,
        uint256 tokenId,
        bool stake
    ) external;

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./Base64.sol";

contract Traits is Ownable {
    using Strings for uint256;
    using MerkleProof for bytes32[];
    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }
    string unrevealedImage;

    ICryptoBees beesContract;
    IHoney honeyContract;
    // mint price ETH
    uint256 public constant MINT_PRICE = .06 ether;
    uint256 public constant MINT_PRICE_DISCOUNT = .055 ether;
    uint256 public constant MINTS_PER_WHITELIST = 6;
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // mint price HONEY
    uint256 public constant MINT_PRICE_HONEY = 3000 ether;
    // mint price WOOL
    uint256 public mintPriceWool = 6600 ether;
    // max number of tokens that can be minted
    uint256 public constant MAX_TOKENS = 40000;
    // number of tokens that can be claimed for ETH
    uint256 public constant PAID_TOKENS = 10000;
    /// @notice controls if mintWithEthPresale is paused
    bool public mintWithEthPresalePaused = true;
    /// @notice controls if mintWithWool is paused
    bool public mintWithWoolPaused = true;
    /// @notice controls if mainMint is paused
    bool public mintWithEthPaused = true;

    mapping(address => uint8) public whitelistMints;

    bytes32 private merkleRootWhitelist;

    string[8] _traitTypes = ["Body", "Color", "Eyes", "Mouth", "Nose", "Hair", "Accessories", "Feelers"];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    string[4] _strengths = ["5", "6", "7", "8"];
    // 0 - 7 are associated with Bees, 8 - 18 are associated with Bears, 16 - 23 with Beekeeper
    uint8[][24] public rarities;
    // 0 - 7 are associated with Bees, 8 - 18 are associated with Bears, 16 - 23 with Beekeeper
    uint8[][24] public aliases;

    constructor() {
        // colours
        rarities[1] = [255, 215, 122, 76, 30, 15];
        aliases[1] = [0, 0, 0, 0, 0, 0];
        // eyes
        rarities[2] = [255, 217, 217, 230, 217, 204, 230, 230, 230, 230, 230, 191, 191, 191, 191];
        aliases[2] = [0, 0, 1, 2, 3, 4, 0, 1, 2, 6, 7, 1, 1, 2, 5];
        // mouth
        rarities[3] = [255, 202, 191, 181, 215, 248, 199, 194, 189, 184, 179, 217, 174, 174, 174, 174, 174];
        aliases[3] = [0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 10];
        // nose
        rarities[4] = [255, 230, 204, 192, 179, 179, 179];
        aliases[4] = [0, 0, 1, 2, 0, 1, 3];
        // hair
        rarities[5] = [255, 127, 204, 230, 115, 115, 115, 115, 115];
        aliases[5] = [0, 0, 1, 3, 5, 4, 1, 1, 2];
        // accessory
        rarities[6] = [255, 99, 53];
        aliases[6] = [0, 0, 0];
        // feelers
        rarities[7] = [255, 140, 204, 102, 179, 89, 89];
        aliases[7] = [0, 0, 1, 2, 0, 1, 3];

        //bear - colours
        rarities[9] = [255, 153, 153];
        aliases[9] = [0, 0, 1];

        //bear - eyes
        rarities[10] = [255, 220, 184, 148, 222, 186, 151, 225, 189, 153, 117, 240, 204, 168, 133, 145, 145, 97, 97];
        aliases[10] = [0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 3, 6, 10, 14];

        //bear - mouth
        rarities[11] = [255, 235, 184, 204, 225, 174, 245, 245, 245, 184, 184, 122];
        aliases[11] = [0, 0, 1, 2, 3, 4, 0, 1, 6, 2, 3, 5];

        //bear - nose
        rarities[12] = [255, 230, 204, 179, 179, 179, 179];
        aliases[12] = [0, 0, 1, 3, 1, 2, 3];

        //bear - hat/hair
        rarities[13] = [255, 204, 204, 204, 102, 102, 102, 102];
        aliases[13] = [0, 1, 0, 2, 3, 2, 4, 4];

        //bear - accessory
        rarities[14] = [255, 89, 89, 53, 53, 35, 35];
        aliases[14] = [0, 0, 1, 1, 2, 2, 3];

        // bear strength
        rarities[15] = [255, 102, 153, 51];
        aliases[15] = [0, 0, 1, 1];

        //beekeeper - color
        rarities[17] = [255, 153, 153, 153, 76, 76];
        aliases[17] = [0, 0, 1, 1, 2, 2];

        //beekeeper - eyes
        rarities[18] = [255, 170, 142, 113];
        aliases[18] = [0, 0, 1, 2];

        //beekeeper - mouth
        rarities[19] = [255, 243, 230, 217, 204, 192, 179];
        aliases[19] = [0, 0, 1, 2, 3, 4, 5];

        //beekeeper - hair
        rarities[21] = [255, 230, 230, 230, 230, 230, 230, 230, 230];
        aliases[21] = [0, 0, 1, 1, 3, 4, 3, 1, 0];

        //beekeeper - accessory
        rarities[22] = [255, 122, 122, 122, 122, 122, 122, 122, 122, 122, 92, 30];
        aliases[22] = [0, 0, 1, 1, 4, 3, 0, 2, 2, 1, 5, 4];
        //beekeeper skill
        rarities[23] = [255, 102, 153, 51];
        aliases[23] = [0, 0, 1, 2];
    }

    function setContracts(address _BEES, address _HONEY) external onlyOwner {
        honeyContract = IHoney(_HONEY);
        beesContract = ICryptoBees(_BEES);
    }

    /** MINTING */
    function mintForEth(
        address addr,
        uint256 amount,
        uint256 minted,
        uint256 value,
        bool stake
    ) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        mintCheck(addr, amount, minted, false, value, true);
        for (uint256 i = 1; i <= amount; i++) {
            beesContract.mint(addr, minted + i, stake);
        }
    }

    function mintForEthWhitelist(
        address addr,
        uint256 amount,
        uint256 minted,
        uint256 value,
        bytes32[] calldata _merkleProof,
        bool stake
    ) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf), "You are not on the whitelist!");
        mintCheck(addr, amount, minted, true, value, true);
        for (uint256 i = 1; i <= amount; i++) {
            beesContract.mint(addr, minted + i, stake);
            whitelistMints[addr]++;
        }
    }

    function mintForHoney(
        address addr,
        uint256 amount,
        uint256 minted,
        bool stake
    ) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        mintCheck(addr, amount, minted, false, 0, false);
        uint256 totalHoneyCost = 0;
        for (uint256 i = 1; i <= amount; i++) {
            totalHoneyCost += mintCost(minted + i);
            beesContract.mint(addr, minted + i, stake);
        }
        // honeyContract.burn(addr, totalHoneyCost);
    }

    function mintForWool(
        address addr,
        uint256 amount,
        uint256 minted,
        bool stake
    ) external returns (uint256 totalWoolCost) {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        require(!mintWithWoolPaused, "WOOL minting paused");
        require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
        mintCheck(addr, amount, minted, false, 0, false);

        for (uint256 i = 1; i <= amount; i++) {
            totalWoolCost += mintPriceWool;
            beesContract.mint(addr, minted + i, stake);
        }
    }

    function mintCheck(
        address addr,
        uint256 amount,
        uint256 minted,
        bool presale,
        uint256 value,
        bool isEth
    ) private view {
        require(tx.origin == addr, "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        if (presale) {
            require(!mintWithEthPresalePaused, "Presale mint paused");
            require(amount > 0 && whitelistMints[addr] + amount <= MINTS_PER_WHITELIST, "Only limited amount for WL mint");
        } else {
            require(amount > 0 && amount <= 10, "Invalid mint amount sale");
        }
        if (isEth) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            if (presale) require(amount * MINT_PRICE_DISCOUNT == value, "Invalid payment amount presale");
            else {
                require(amount * MINT_PRICE == value, "Invalid payment amount sale");
                require(!mintWithEthPaused, "Public sale currently paused");
            }
        }
    }

    function getTokenTextType(uint256 tokenId) external view returns (string memory) {
        require(beesContract.doesExist(tokenId), "ERC721Metadata: Nonexistent token");
        return _getTokenTextType(tokenId);
    }

    function _getTokenTextType(uint256 tokenId) private view returns (string memory) {
        uint8 _type = beesContract.getTokenData(tokenId)._type;
        if (_type == 1) return "BEE";
        else if (_type == 2) return "BEAR";
        else if (_type == 3) return "BEEKEEPER";
        else return "NOT REVEALED";
    }

    function setPresaleMintPaused(bool _paused) external onlyOwner {
        mintWithEthPresalePaused = _paused;
    }

    function setWoolMintPaused(bool _paused) external onlyOwner {
        mintWithWoolPaused = _paused;
    }

    function setMintWithEthPaused(bool _paused) external onlyOwner {
        mintWithEthPaused = _paused;
    }

    function setWoolMintPrice(uint256 _price) external onlyOwner {
        mintPriceWool = _price;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRootWhitelist = root;
    }

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 seed) public view returns (ICryptoBees.Token memory) {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        ICryptoBees.Token memory t = selectTraits(seed);
        return t;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 seed) internal view returns (ICryptoBees.Token memory t) {
        uint256 num = ((seed & 0xFFFF) % 100);
        t._type = 1;
        if (num < 20) t._type = 3;
        else if (num < 50) t._type = 2;
        uint8 shift = t._type > 0 ? ((t._type - 1) * 8) : 0;
        seed >>= 16;
        t.color = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        if (t._type != 3) {
            seed >>= 16;
            t.nose = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        }
        seed >>= 16;
        t.hair = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        if (t._type == 1) {
            seed >>= 16;
            t.feelers = selectTrait(uint16(seed & 0xFFFF), 7);
        } else {
            seed >>= 16;
            t.strength = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        }
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param t the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(ICryptoBees.Token memory t) internal pure returns (uint256) {
        return uint256(bytes32(abi.encodePacked(t._type, t.color, t.eyes, t.mouth, t.nose, t.hair, t.accessory, t.feelers, t.strength)));
    }

    /**
     * Gen 0 can be mint for honey too
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public pure returns (uint256) {
        if (tokenId <= 20000) return MINT_PRICE_HONEY;
        if (tokenId <= 30000) return 7500 ether;
        return 15000 ether;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traitNames the names and base64 encoded PNGs for each trait
     * @param traitImages the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(
        uint8 traitType,
        string[] calldata traitNames,
        string[] calldata traitImages
    ) external onlyOwner {
        require(traitNames.length == traitImages.length, "Mismatched inputs");
        for (uint256 i = 0; i < traitNames.length; i++) {
            traitData[traitType][uint8(i)] = Trait(traitNames[i], traitImages[i]);
        }
    }

    function uploadUnrevealImage(string calldata image) external onlyOwner {
        unrevealedImage = image;
    }

    // function random(uint256 seed) internal view returns (uint256) {
    //     return uint256(keccak256(abi.encodePacked(seed)));
    // }

    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        if (bytes(trait.png).length == 0) return "";
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    /**
     * generates an <image> element using base64 encoded PNGs
     * @return the <image> element
     */
    function drawUnrevealedImage() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    unrevealedImage,
                    '"/>'
                )
            );
    }

    // /**
    //  * generates an entire SVG by composing multiple <image> elements of PNGs
    //  * @param tokenId the ID of the token to generate an SVG for
    //  * @return a valid SVG of the Sheep / Wolf
    //  */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        ICryptoBees.Token memory s = beesContract.getTokenData(tokenId);
        uint8 shift = s._type > 0 ? ((s._type - 1) * 8) : 0;
        string memory svgString;
        if (s._type == 0) svgString = drawUnrevealedImage();
        else {
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[0 + shift][0]),
                    drawTrait(traitData[1 + shift][s.color]),
                    drawTrait(traitData[2 + shift][s.eyes]),
                    drawTrait(traitData[3 + shift][s.mouth]),
                    drawTrait(traitData[4 + shift][s.nose]),
                    drawTrait(traitData[5 + shift][s.hair]),
                    drawTrait(traitData[6 + shift][s.accessory]),
                    drawTrait(traitData[7][s.feelers])
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="cryptobees" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', traitType, '","value":"', value, '"}'));
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId) public view returns (string memory) {
        ICryptoBees.Token memory t = beesContract.getTokenData(tokenId);
        string memory textType = _getTokenTextType(tokenId);
        uint8 shift = t._type > 0 ? ((t._type - 1) * 8) : 0;
        string memory traits;
        traits = string(
            abi.encodePacked(
                attributeForTypeAndValue(_traitTypes[1], traitData[1 + shift][t.color].name),
                ",",
                attributeForTypeAndValue(_traitTypes[2], traitData[2 + shift][t.eyes].name),
                ",",
                attributeForTypeAndValue(_traitTypes[3], traitData[3 + shift][t.mouth].name),
                ",",
                attributeForTypeAndValue(_traitTypes[5], traitData[5 + shift][t.hair].name),
                ",",
                attributeForTypeAndValue(_traitTypes[6], traitData[6 + shift][t.accessory].name),
                ","
            )
        );
        if (t._type != 3) {
            traits = string(abi.encodePacked(traits, attributeForTypeAndValue(_traitTypes[4], traitData[4 + shift][t.nose].name), ","));
        }
        if (t._type == 1) {
            traits = string(abi.encodePacked(traits, attributeForTypeAndValue(_traitTypes[7], traitData[7][t.feelers].name), ","));
        } else if (t._type == 2) {
            traits = string(abi.encodePacked(traits, attributeForTypeAndValue("Strength", _strengths[t.strength]), ","));
        } else if (t._type == 3) {
            traits = string(abi.encodePacked(traits, attributeForTypeAndValue("Skill", _strengths[t.strength]), ","));
        }

        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Generation","value":',
                    tokenId <= PAID_TOKENS ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":"',
                    textType,
                    '"}]'
                )
            );
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        // require(beesContract.doesExist(tokenId), "ERC721Metadata: Nonexistent token");

        string memory textType = _getTokenTextType(tokenId);
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                textType,
                " #",
                uint256(tokenId).toString(),
                '", "type": "',
                textType,
                '", "description": "People realized that the path to prosperity is to relocate to a farm. Some have bought sheep, some land but many ended up with nothing. $HONEY is the new opportunity.',
                '","image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(drawSVG(tokenId))),
                '","attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IAttack {
    struct Settings {
        uint8 bearChance;
        uint8 beekeeperMultiplier;
        uint24 hiveProtectionBear;
        uint24 hiveProtectionKeeper;
        uint24 bearCooldownBase;
        uint24 bearCooldownPerHiveDay;
        uint24 beekeeperCooldownBase;
        uint24 beekeeperCooldownPerHiveDay;
        uint8 attacksToRestart;
    }
    struct UnresolvedAttack {
        uint24 tokenId;
        uint48 nonce;
        uint64 block;
        uint32 howMuch;
    }
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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHoney {
    function mint(address to, uint256 amount) external;

    function mintGiveaway(address[] calldata addresses, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function disableGiveaway() external;

    function addController(address controller) external;

    function removeController(address controller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        // solhint-disable-next-line no-inline-assembly
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}