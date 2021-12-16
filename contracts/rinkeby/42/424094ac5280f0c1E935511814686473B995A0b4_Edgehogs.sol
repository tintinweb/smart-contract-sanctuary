// SPDX-License-Identifier: MIT
//🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔🦔
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721P, ERC721Enum} from "./base/ERC721Enum.sol";
import {Base64} from "base64-sol/base64.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

interface InterfaceDescriptor {
  function renderBack(uint256 _trait) external view returns (bytes memory);

  function renderMouth(uint256 _trait) external view returns (bytes memory);

  function renderAccessory(uint256 _trait) external view returns (bytes memory);

  function renderBackground(uint256 _trait)
    external
    view
    returns (bytes memory);

  function renderBottom(uint256 _trait) external view returns (bytes memory);

  function renderClothes(uint256 _trait) external view returns (bytes memory);

  function renderEyes(uint256 _trait) external view returns (bytes memory);

  function renderHeadgear(uint256 _trait) external view returns (bytes memory);
}

contract Edgehogs is Ownable, ERC721Enum {
  uint256 public constant MAX = 6666;
  uint256 public constant MAX_FREE = 666;
  uint256 public constant MAX_REROLLS = 1000;
  uint256 public constant PURCHASE_LIMIT = 10;
  uint256 public constant PRICE = 0.025 ether;
  uint256 public constant REROLL_PRICE = 0.01 ether;

  uint256 public mintedTokens;
  uint256 public rerollsMade;
  uint256 public freeClaimed;

  uint8 public saleState = 0; // = = DEV, 1 = PRESALE, 2 = PUBLIC, 3 = CLOSED

  // OpenSea auto approve is live
  bool public isOpenSeaApproved;
  // OpenSea proxy registry contract
  OpenSeaProxyRegistry public openSeaProxyRegistry;

  //Save seed for traits for each token
  mapping(uint256 => uint256) public tokenSeed;
  // amount minted by address in presale
  mapping(address => uint256) public whitelistMints;

  InterfaceDescriptor public descriptor;

  uint16[][8] rarities;
  string[][8] traitsByName;

  // presale merkle tree root
  bytes32 internal _merkleRoot;

  //SVG-parts shared by all Edgehogs
  string private constant svgStart =
    "<svg id='edgehog' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256' width='640' height='640'>";
  string private constant svgEnd =
    "<style>#edgehog{shape-rendering: crispedges; image-rendering: -moz-crisp-edges; image-rendering: optimizeSpeed; image-rendering: -webkit-crisp-edges; image-rendering: -webkit-optimize-contrast; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";
  string private constant _body =
    "<image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEABAMAAACuXLVVAAAAFVBMVEVHcEzLtaGTg2onDQhZVlLsmJkAAABLyaKyAAAAAXRSTlMAQObYZgAAATNJREFUeNrt2tsNgkAQQFFasAVbsAVbsAX7L0FJmGSyWQwmCyxw7qc85vBDcGEYJEmSJEmSJEmSJEmSJEmSFvRIbXEcAABAn4DX1D/HxTEAAADHB2TEfeqWin3yb+M+zYYDAAB0AQhEObxWIJ/fAAAArgfI2wEAAK4JyAEAAJwXUDb3QNJ0OAAAwO6A8WTjjWVuaPSeAgAAOBcghke1G1IePrbK1QMAAOwOKBcgf9X8SQgAAGA3QDk896y0+tUDAAB0AdjsRSUAAMDugCXDa4uTzRcmAAAADgEIRCxeNPuYGQAAoAtAXpwEAAC4JiCfGAAAAGDJHxMAAIDzAAJRfrCw2QIFAABAN4Dai8va8NW+pgYAAOgSUKv5cAAAgO4AtQ8X87ZhjQAAALoDLN0GAABwGMAHTDthTLhaRQMAAAAASUVORK5CYII='/>";

  constructor(
    InterfaceDescriptor descriptor_,
    OpenSeaProxyRegistry openSeaProxyRegistry_,
    bytes32 merkleRoot_
  ) ERC721P("EDGEHOGS", unicode"⚉") {
    //Solidity 0.8.10 does not seem to support Unicode 10.0 emojis as of now, otherwise it would have been 🦔 ofc

    // Initializing variables
    descriptor = descriptor_;
    openSeaProxyRegistry = openSeaProxyRegistry_;
    _merkleRoot = merkleRoot_;

    //sum of rarities values must be equal to the mod used in getRandomIndex, 10000 in our case
    rarities[0] = [0, 100, 1900, 2000, 2000, 2000, 2000]; //backgrounds
    rarities[1] = [
      0,
      1000,
      850,
      700,
      700,
      700,
      600,
      600,
      500,
      500,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      50
    ]; //backs
    rarities[2] = [
      0,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      50
    ]; //bottoms
    rarities[3] = [
      0,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      50
    ]; //clothes
    rarities[4] = [
      0,
      1000,
      800,
      800,
      800,
      600,
      600,
      500,
      500,
      400,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      150,
      100,
      50
    ]; //mouths
    rarities[5] = [
      0,
      800,
      600,
      600,
      600,
      600,
      600,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      50,
      50,
      50,
      50
    ]; //headgears
    rarities[6] = [
      0,
      850,
      800,
      800,
      600,
      600,
      600,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      50
    ]; //eyes
    rarities[7] = [
      0,
      800,
      700,
      700,
      700,
      700,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      400,
      400,
      400,
      300,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      50,
      50
    ]; //accessories

    //traits
    //backgrounds
    traitsByName[0] = [
      "n/a",
      "Psychedelic",
      "Purple",
      "Orange",
      "Green",
      "Pink",
      "Red"
    ];
    //backs
    traitsByName[1] = [
      "n/a",
      "Edgehog",
      "Firework",
      "Black",
      "Neon Sparks",
      "Shoomery",
      "Pirate",
      "Punk",
      "Grant us Eyes",
      "Rainbow",
      "Neon Punk",
      "Psychedelic",
      "Slime",
      "Spotty",
      "Christmas",
      "Brainiac",
      "Cyberhog",
      "Bubble gum",
      "Skellyhog",
      "TNT",
      "Biohazard",
      "Robohog",
      "Hellhog",
      "Virus",
      "Pure Gold",
      "Diamond"
    ];
    //bottoms
    traitsByName[2] = [
      "n/a",
      "Fancy",
      "Padre",
      "Joker",
      "Vault Dweller",
      "Santa",
      "Torn Jeans",
      "Fishnets",
      "Bikini",
      "Green",
      "Pajamas",
      "BDSM",
      "Mime",
      "Pink",
      "Jungle",
      "Rainbow",
      "Elvis",
      "Bathog",
      "Partyhog",
      "Skelly",
      "Pure Gold"
    ];
    //clothes
    traitsByName[3] = [
      "n/a",
      "Pink",
      "Joker",
      "Vault Dweller",
      "Padre",
      "Santa",
      "Freddy",
      "Pierced Nips",
      "Bikini",
      "Punk",
      "Pajamas",
      "BDSM",
      "Mime",
      "Rapper",
      "Buff",
      "Rainbow",
      "Elvis",
      "Bathog",
      "Partyhog",
      "Skelly",
      "Pure Gold"
    ];
    //mouths
    traitsByName[4] = [
      "None",
      "Plain",
      "Smile",
      "Drooling",
      "Tongue",
      "Pipe",
      "Party",
      "Love",
      "Zombie",
      "Rabid",
      "Blush",
      "Mime",
      "Bubble gum",
      "Blunt",
      "Bloody",
      "Licker",
      "Vampire",
      "Blotter",
      "Virus",
      "Red Beard",
      "Golden tooth",
      "TNT",
      "Hannibal",
      "Biohazard",
      "Laser"
    ];
    //headgears
    traitsByName[5] = [
      "n/a",
      "None",
      "Beanie",
      "Fastfood",
      "Apple",
      "Frying pan",
      "Tinfoil hat",
      "Arrow",
      "Punk",
      "Rabbit ears",
      "Doc",
      "Pizza",
      "Anntennae",
      "Horny",
      "Pretty bow",
      "Eye",
      "Devil",
      "Skull",
      "Toad",
      "Unicorn",
      "Kamikaze",
      "Santa",
      "Pirate",
      "Alien eyes",
      "Demon",
      "Crown",
      "Chief",
      "Zombie hand",
      "Fake halo",
      "Brainz",
      "Strawberry cap",
      "Russian hat",
      "Frankenhog",
      "Plunger",
      "Sroomhead",
      "Octopus",
      "Plague Doctor",
      "VR"
    ];
    //eyes
    traitsByName[6] = [
      "n/a",
      "Plain",
      "Sus",
      "Green",
      "Crosseyed",
      "Angry",
      "Kawaii",
      "Tired",
      "Grumpy",
      "Red goggles",
      "Green goggles",
      "Bloodshot",
      "Goomba",
      "Eye patch",
      "Squinty",
      "Insane",
      "Vampire",
      "Pop out",
      "Popeye",
      "Dizzy",
      "Triple eye",
      "Hearts",
      "XX",
      "Alien",
      "VR goggles",
      "Cyclops",
      "Rainbow goggles",
      "Cyborg",
      "Cyberhog",
      "Demon",
      "Hogminator",
      "Steampunk",
      "Deal with it",
      "Lasers"
    ];
    //accessories
    traitsByName[7] = [
      "n/a",
      "None",
      "Coffee",
      "Sausage",
      "Sorcerer staff",
      "Mana potion",
      "Bong",
      "Pirate flag",
      "Whip",
      "Beer",
      "Steel claws",
      "Trident",
      "Knife",
      "Club",
      "Balloon",
      "Shocker",
      "Biohazard",
      "Lightsaber",
      "Master Sword",
      "Doggy",
      "Rose",
      "Gun",
      "Pee",
      "Chainsaw",
      "Scythe",
      "Dildo",
      "Minigun"
    ];
  }

  //Get the attribute name for the properties of the token by its index
  function getTrait(uint256 _trait, uint256 index)
    private
    view
    returns (string memory)
  {
    return traitsByName[_trait][index];
  }

  ////////////////////////////////////////////////////////////
  /////🦔GENERATE TRAITS AND SVG BASED ON SEED🦔/////////////
  ///////////////////////////////////////////////////////////

  //Get randomized values for each different trait with a single pseudorandom seed
  // note: we are generating both traits and SVG on the fly based on the seed which is the the only parameter saved in memory
  // Not writing a whole struct allows for serious gas savings on mint, but has a downside that we can't easily address or change a single trait
  function getRandomTraits(uint256 randomNumber)
    public
    view
    returns (string memory svg, string memory properties)
  {
    uint16[] memory randomInputs = expand(randomNumber, 8);
    uint16[] memory traits = new uint16[](8);
    /** traits[0] bg
        traits[1] back
        traits[2] bottom
        traits[3] clothes
        traits[4] mouth
        traits[5] headgear
        traits[6] eyes
        traits[7] accessory
    */

    traits[0] = getRandomIndex(rarities[0], randomInputs[0]);
    traits[1] = getRandomIndex(rarities[1], randomInputs[1]);
    traits[2] = getRandomIndex(rarities[2], randomInputs[2]);
    traits[3] = getRandomIndex(rarities[3], randomInputs[3]);
    traits[4] = getRandomIndex(rarities[4], randomInputs[4]);
    traits[5] = getRandomIndex(rarities[5], randomInputs[5]);
    traits[6] = getRandomIndex(rarities[6], randomInputs[6]);
    traits[7] = getRandomIndex(rarities[7], randomInputs[7]);

    //handling compatibility exceptions
    //tnt              //hellhog
    if (traits[1] == 19 || traits[1] == 22) {
      traits[5] = 1;
    }
    //tnt
    if (traits[4] == 21) {
      traits[7] = 0;
    }
    //staff              //scythe         //plain
    if (traits[7] == 4 || traits[7] == 24) {
      traits[4] = 1;
    }
    //VR
    if (traits[5] == 37) {
      traits[6] = 1;
    }
    //Plague
    if (traits[5] == 36) {
      traits[6] = 1;
      traits[4] = 0;
    }

    // render svg
    bytes memory _svg = renderEdgehog(
      traits[0],
      traits[1],
      traits[2],
      traits[3],
      traits[4],
      traits[5],
      traits[6],
      traits[7]
    );

    svg = Base64.encode(_svg);

    // pack properties, put 1 after the last property for JSON to be formed correctly (no comma after the last one)
    bytes memory _properties = abi.encodePacked(
      packMetaData("background", getTrait(0, traits[0]), 0),
      packMetaData("back", getTrait(1, traits[1]), 0),
      packMetaData("bottom", getTrait(2, traits[2]), 0),
      packMetaData("clothes", getTrait(3, traits[3]), 0),
      packMetaData("mouth", getTrait(4, traits[4]), 0),
      packMetaData("headgear", getTrait(5, traits[5]), 0),
      packMetaData("eyes", getTrait(6, traits[6]), 0),
      packMetaData("accessory", getTrait(7, traits[7]), 1)
    );

    properties = string(abi.encodePacked(_properties));
    return (svg, properties);
  }

  // Get a random attribute using the rarities defined
  // Shout out to Anonymice for the logic
  function getRandomIndex(
    uint16[] memory attributeRarities,
    uint256 randomNumber
  ) private pure returns (uint16 index) {
    uint16 random10k = uint16(randomNumber % 10000);
    uint16 lowerBound;
    for (uint16 i = 1; i <= attributeRarities.length; i++) {
      uint16 percentage = attributeRarities[i];

      if (random10k < percentage + lowerBound && random10k >= lowerBound) {
        return i;
      }
      lowerBound = lowerBound + percentage;
    }
    revert();
  }

  //Get attribute svg for each different property of the token
  function renderEdgehog(
    uint16 _background,
    uint16 _back,
    uint16 _bottom,
    uint16 _clothes,
    uint16 _mouth,
    uint16 _headgear,
    uint16 _eyes,
    uint16 _accessory
  ) public view returns (bytes memory) {
    bytes memory start = abi.encodePacked(
      svgStart,
      descriptor.renderBackground(_background),
      descriptor.renderBack(_back),
      _body
    );
    return
      abi.encodePacked(
        start,
        descriptor.renderBottom(_bottom),
        descriptor.renderClothes(_clothes),
        descriptor.renderAccessory(_accessory),
        descriptor.renderHeadgear(_headgear),
        descriptor.renderEyes(_eyes),
        descriptor.renderMouth(_mouth),
        svgEnd
      );
  }

  /////////////////////////////////////
  /////🦔GENERATE METADATA🦔//////////
  ////////////////////////////////////

  //Get the metadata for a token in base64 format
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token not found");
    (string memory svg, string memory properties) = getRandomTraits(
      tokenSeed[tokenId]
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"Edgehog #',
              uint2str(tokenId),
              '", "description": "Edgehogs are edgy as fuck.", "traits": [',
              properties,
              '], "image":"data:image/svg+xml;base64,',
              svg,
              '"}'
            )
          )
        )
      );
  }

  // Bundle metadata so it follows the standard
  function packMetaData(
    string memory name,
    string memory svg,
    uint256 last
  ) private pure returns (bytes memory) {
    string memory comma = ",";
    if (last > 0) comma = "";
    return
      abi.encodePacked(
        '{"trait_type": "',
        name,
        '", "value": "',
        svg,
        '"}',
        comma
      );
  }

  /////////////////////////////////////
  /////🦔MINTING🦔////////////////////
  ////////////////////////////////////

  function reroll(uint256 tokenId) external payable {
    require(saleState == 2, "Reroll not active");
    require(msg.sender == ownerOf(tokenId), "Only owner can reroll");
    require(rerollsMade < MAX_REROLLS, "No more rerolls");
    require(REROLL_PRICE == msg.value, "Ether value sent is not correct");

    tokenSeed[tokenId] = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId + 1))
    );
    rerollsMade = rerollsMade + 1;
  }

  function mint(uint256 numberOfTokens) external payable {
    uint256 supply = totalSupply();
    require(saleState == 2, "Public sale not active");
    require(numberOfTokens <= PURCHASE_LIMIT, "Too many");
    require(supply + numberOfTokens <= MAX, "Would exceed max supply");
    require(PRICE * numberOfTokens == msg.value, "Gimme more");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      tokenSeed[supply + i] = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender, supply + i))
      );
      _safeMint(msg.sender, supply + i, "");
    }
    delete supply;
  }

  //free mint, 1 per transaction, address must be whtelisted
  function presaleMint(bytes32[] calldata proof_) public {
    uint256 tokenId = totalSupply() + 1;
    require(saleState == 1, "Presale not active");
    require(freeClaimed + 1 <= MAX_FREE, "All free Edgehogs claimed");
    require(tokenId <= MAX, "Claim would exceed maximum supply");
    require(isWhitelisted(msg.sender, proof_), "Not on the list");
    require(whitelistMints[msg.sender] == 0, "Already minted");

    whitelistMints[msg.sender]++;
    tokenSeed[tokenId] = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))
    );
    _safeMint(msg.sender, tokenId, "");
    freeClaimed += 1;
    delete tokenId;
  }

  ///////////////////////////////////
  /////🦔ADMIN🦔////////////////////
  //////////////////////////////////

  function setOpenSeaProxyRegistry(OpenSeaProxyRegistry openSeaProxyRegistry_)
    external
    onlyOwner
  {
    openSeaProxyRegistry = openSeaProxyRegistry_;
  }

  function flipOpenSeaApproved() external onlyOwner {
    isOpenSeaApproved = !isOpenSeaApproved;
  }

  function flipSaleState() external onlyOwner {
    require(saleState < 3, "Sale state is already closed");
    saleState++;
  }

  // Withdraw to owner
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  ///////////////////////////////////
  /////🦔HELPERS🦔//////////////////
  //////////////////////////////////

  function isApprovedForAll(address _owner, address operator)
    public
    view
    override
    returns (bool)
  {
    return
      (isOpenSeaApproved &&
        address(openSeaProxyRegistry.proxies(_owner)) == operator) ||
      super.isApprovedForAll(_owner, operator);
  }

  // Check if the address is whitelisted
  function isWhitelisted(address account_, bytes32[] calldata proof_)
    public
    view
    returns (bool)
  {
    return _verify(_leaf(account_), proof_);
  }

  // Set Merckle root
  function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
    _merkleRoot = merkleRoot_;
  }

  // Encode Merckle leaf from address
  function _leaf(address account_) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account_));
  }

  // verify proof
  function _verify(bytes32 leaf_, bytes32[] memory proof_)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof_, _merkleRoot, leaf_);
  }

  ///set attributes libraries
  function setDescriptor(address source) external onlyOwner {
    descriptor = InterfaceDescriptor(source);
  }

  function expand(uint256 _randomNumber, uint256 n)
    private
    pure
    returns (uint16[] memory expandedValues)
  {
    expandedValues = new uint16[](n);
    for (uint256 i = 0; i < n; i++) {
      expandedValues[i] = bytes2uint(keccak256(abi.encode(_randomNumber, i)));
    }
    return expandedValues;
  }

  function bytes2uint(bytes32 _a) private pure returns (uint16) {
    return uint16(uint256(_a));
  }

  function freeClaimedCount() external view returns (uint256) {
    return freeClaimed;
  }

  function rerollsMadeCount() external view returns (uint256) {
    return rerollsMade;
  }

  //Helper function to convert uint to string
  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  //if you are reading this, you are a true blockchain nerd. Much love - @spiridono! 🦔
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721P.sol";

abstract contract ERC721Enum is ERC721P, IERC721Enumerable {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721P)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256 tokenId)
  {
    require(index < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (owner == _owners[i]) {
        if (count == index) return i;
        else ++count;
      }
    }
    require(false, "ERC721Enum: owner ioob");
  }

  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _owners.length;
  }

  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(index < ERC721Enum.totalSupply(), "ERC721Enum: global ioob");
    return index;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC721P is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  string private _name;
  string private _symbol;
  address[] internal _owners;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    uint256 count = 0;
    uint256 length = _owners.length;
    for (uint256 i = 0; i < length; ++i) {
      if (owner == _owners[i]) {
        ++count;
      }
    }
    delete length;
    return count;
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721P.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _owners.length && _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721P.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

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

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);
    _owners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721P.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    _owners[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721P.ownerOf(tokenId) == from,
      "ERC721: transfer of token that is not own"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721P.ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
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

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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