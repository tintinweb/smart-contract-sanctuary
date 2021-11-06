// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "../interfaces/ICubTraitProvider.sol";
import "../utils/CubComposition.sol";
import "../utils/TwoBitCubErrors.sol";
import "./TwoBitHoney.sol";

/// @title TwoBitCubs
contract TwoBitCubs is ERC721Enumerable, ICubTraitProvider, Ownable, ReentrancyGuard {
    /*
                          :=====-     .:------::.    :=====:
                        :**++++++#+=--:.      ..:-==#+++++++*=
                       -#******#=.                  .=*#*****#+
                       +*****#=                        :*#****%
                       -#**#*.                           +#***+
                        -###    .=+***=.       =+**+=:    +##=
                          #.  .=*******+      -*******+:   #.
                         -=  .+**%=+%*+:      .+*#+=%***:  :+
                         +.  +***##%#+  .-::-:  =#%##****.  #
                        :+   *******+   -%%%%+   =*******:  -=
                        *.   =******. :- .*#: .=  +*****+    #
                        #.    -+++-.   +%%%%%%#.   -=++-     *:
                        *-.            .#*++*%-             :#
                     =*###-:.            -==-.           .:-*:
                    -#****#*=-:..                    ..::=+=
                    .#*******#**+=-:::::......:::::-==+*#:
                     :##**********####**********####****#*
                       =##*****#******************#******#:
                         :=*###%*****************#+******%:
                             .=*:--===+++++++++#*+******##
                              -=              -*+*******%:
                           -=+****=           #+******#%*=-.
                         =*---+****#.         *#****###*=--++
                        =*.    +***#+          -*####**.    ++
                        +*     =***#*            =#***+     =*
                        .#=.  :***#%*--::::::::--+%#***-.  -#:
                         .+#**##*+-.:-==++++++==-:.-=*###*#+.
                             .............................
    */
    using Strings for uint256;

    /// @dev Price to adopt one cub
    uint256 public constant ADOPTION_PRICE = 0.15 ether;

    /// @dev The number of blocks until a growing cub becomes an adult (roughly 1 week)
    uint256 public constant ADULT_AGE = 44000;

    /// @dev Maximum cubs that will be minted (adopted and bread)
    uint256 public constant MAX_CUBS = 7500; // We expect ~4914 cubs, but are prepared for 7500 in deference to Honey holders, in case there are somehow lots of twins and triplets

    /// @dev Maximum quantity of cubs that can be adopted at once
    uint256 public constant MAX_ADOPT_QUANTITY = 10;

    /// @dev Maximum quantity of cubs that can be adopted in total
    uint256 public constant TOTAL_ADOPTIONS = 2500;

    /// @dev Reference to the TwoBitHoney contract
    TwoBitHoney internal immutable _twoBitHoney;

    /// @dev Counter for adopted Cubs
    uint256 private _adoptedCubs;

    /// @dev Counter for token Ids
    uint256 private _tokenCounter;

    /// @dev Seed for randomness
    uint256 private _seed;

    /// @dev The block number when adoption and mating are available
    uint256 private _wenMint;

    /// @dev Enables/disables the reveal
    bool private _wenReveal;

    /// @dev Mapping of TokenIds to Cub DNA
    mapping(uint256 => ICubTraits.DNA) private _tokenIdsToCubDNA;

    /// @dev Mapping of TokenIds to Cub growth
    mapping(uint256 => uint256) private _tokenIdsToBirthday;

    constructor(address twoBitHoney) ERC721("TwoBitCubs", "TBC") {
        _seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number-1), uint24(block.number))));
        _twoBitHoney = TwoBitHoney(twoBitHoney);
        _wenMint = 0;
        _wenReveal = false;
    }

    /// @dev Celebrate and marvel at the astonishing detail in each TwoBitBear Cub
    function adoptCub(uint256 quantity) public payable nonReentrant {
        if (_wenMint == 0 || block.number < _wenMint) revert NotOpenForMinting();
        if (quantity == 0 || quantity > MAX_ADOPT_QUANTITY) revert InvalidAdoptionQuantity();
        if (quantity > remainingAdoptions()) revert AdoptionLimitReached();
        if (msg.value < ADOPTION_PRICE * quantity) revert InvalidPriceSent();
        _mintCubs(0xFFFF, 0xFFFF, quantity);
        _adoptedCubs += quantity;
    }

    /// @notice For easy import into MetaMask 
    function decimals() public pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc ICubTraitProvider
    function familyForTraits(ICubTraits.TraitsV1 memory traits) public pure override returns (string memory) {
        string[18] memory families = ["Maeda", "Buffett", "Milonakis", "Petty", "VanDough", "Dammrich", "Pleasr", "Farmer", "Evan Dennis", "Hobbs", "Viselner", "Ghxsts", "Greenawalt", "Capacity", "Sheridan", "Ong", "Orrell", "Kong"];
        return families[traits.familyIndex];
    }

    /// Mate some bears
    /// @dev Throws if the parent TwoBitBear token IDs are not valid or not owned by the caller, or if the honey balance is insufficient
    function mateBears(uint256 parentBearOne, uint256 parentBearTwo) public nonReentrant {
        if (_wenMint == 0 || block.number < _wenMint) revert NotOpenForMinting();
        if (parentBearOne == parentBearTwo || _twoBitHoney.bearSpecies(parentBearOne) != _twoBitHoney.bearSpecies(parentBearTwo)) revert InvalidParentCombination();
        if (!_twoBitHoney.ownsBear(msg.sender, parentBearOne)) revert BearNotOwned(parentBearOne);
        if (!_twoBitHoney.ownsBear(msg.sender, parentBearTwo)) revert BearNotOwned(parentBearTwo);
        _twoBitHoney.burnHoneyForAddress(msg.sender); // Errors here will bubble up

        uint8 siblingSeed = uint8(_seed % 256);
        uint256 quantity = 1 + CubComposition.randomIndexFromPercentages(siblingSeed, _cubSiblingPercentages());
        _mintCubs(uint16(parentBearOne), uint16(parentBearTwo), quantity);
    }

    /// Wakes a cub from hibernation so that it will begin growing
    /// @dev Throws if msg sender is not the owner of the cub, or if the cub's aging has already begun
    function wakeCub(uint256 tokenId) public nonReentrant {
        if (msg.sender != ownerOf(tokenId)) revert CubNotOwned(tokenId);
        if (_tokenIdsToBirthday[tokenId] > 0) revert AgingAlreadyStarted();
        _tokenIdsToBirthday[tokenId] = block.number;
    }

    /// @inheritdoc ICubTraitProvider
    function isAdopted(ICubTraits.DNA memory dna) public pure override returns (bool) {
        return dna.firstParentTokenId == 0xFFFF; // || dna.secondParentTokenId == 0xFFFF;
    }

    /// @inheritdoc ICubTraitProvider
    function moodForType(ICubTraits.CubMoodType moodType) public pure override returns (string memory) {
        string[14] memory moods = ["Happy", "Hungry", "Sleepy", "Grumpy", "Cheerful", "Excited", "Snuggly", "Confused", "Ravenous", "Ferocious", "Hangry", "Drowsy", "Cranky", "Furious"];
        return moods[uint256(moodType)];
    }

    /// @inheritdoc ICubTraitProvider
    function moodFromParents(uint256 firstParentTokenId, uint256 secondParentTokenId) public view returns (ICubTraits.CubMoodType) {
        IBearable.BearMoodType moodOne = _twoBitHoney.bearMood(firstParentTokenId);
        IBearable.BearMoodType moodTwo = _twoBitHoney.bearMood(secondParentTokenId);
        (uint8 smaller, uint8 larger) = moodOne < moodTwo ? (uint8(moodOne), uint8(moodTwo)) : (uint8(moodTwo), uint8(moodOne));
        if (smaller == 0) {
            return ICubTraits.CubMoodType(4 + larger - smaller);
        } else if (smaller == 1) {
            return ICubTraits.CubMoodType(8 + larger - smaller);
        } else if (smaller == 2) {
            return ICubTraits.CubMoodType(11 + larger - smaller);
        }
        return ICubTraits.CubMoodType(13 + larger - smaller);
    }

    /// @inheritdoc ICubTraitProvider
    function nameForTraits(ICubTraits.TraitsV1 memory traits) public pure override returns (string memory) {
        string[18] memory names = ["Rhett", "Clon", "2476", "Tank", "Gremplin", "eBoy", "Pablo", "Chuck", "Justin", "MouseDev", "Pranksy", "Rik", "Joshua", "Racecar", "0xInuarashi", "OhhShiny", "Gary", "Kilo"];
        return names[traits.nameIndex];
    }

    /// Returns the remaining number of adoptions available
    function remainingAdoptions() public view returns (uint256) {
        return TOTAL_ADOPTIONS - _adoptedCubs;
    }

    /// @inheritdoc ICubTraitProvider
    function speciesForType(ICubTraits.CubSpeciesType speciesType) public pure override returns (string memory) {
        string[4] memory species = ["Brown", "Black", "Polar", "Panda"];
        return species[uint256(speciesType)];
    }

    /// @inheritdoc ICubTraitProvider
    function traitsV1(uint256 tokenId) public view override returns (ICubTraits.TraitsV1 memory traits) {
        if (!_exists(tokenId)) revert NonexistentCub();
        if (!_wenReveal) revert NotYetRevealed();

        ICubTraits.DNA memory dna = _tokenIdsToCubDNA[tokenId];
        bytes memory genes = abi.encodePacked(dna.genes); // 32 Bytes
        uint256 increment = (tokenId % 20) + 1;
        uint256 birthday = _tokenIdsToBirthday[tokenId];
        if (birthday > 0) {
            traits.age = block.number - birthday;
        }
        if (isAdopted(dna)) {
            traits.species = ICubTraits.CubSpeciesType(CubComposition.randomIndexFromPercentages(uint8(genes[9 + increment]), _adoptedPercentages()));
            traits.topColor = CubComposition.colorTopFromRandom(genes, 6 + increment, 3 + increment, 4 + increment, traits.species);
            traits.bottomColor = CubComposition.colorBottomFromRandom(genes, 5 + increment, 7 + increment, 1 + increment, traits.species);
            traits.mood = ICubTraits.CubMoodType(CubComposition.randomIndexFromPercentages(uint8(genes[increment]), _adoptedPercentages()));
        } else {
            traits.species = ICubTraits.CubSpeciesType(uint8(_twoBitHoney.bearSpecies(dna.firstParentTokenId)));
            traits.topColor = CubComposition.randomColorFromColors(_twoBitHoney.bearTopColor(dna.firstParentTokenId), _twoBitHoney.bearTopColor(dna.secondParentTokenId), genes, 6 + increment, 3 + increment);
            traits.bottomColor = CubComposition.randomColorFromColors(_twoBitHoney.bearBottomColor(dna.firstParentTokenId), _twoBitHoney.bearBottomColor(dna.secondParentTokenId), genes, 5 + increment, 7 + increment);
            traits.mood = moodFromParents(dna.firstParentTokenId, dna.secondParentTokenId);
        }
        traits.nameIndex = uint8(uint8(genes[2 + increment]) % 18);
        traits.familyIndex = uint8(uint8(genes[8 + increment]) % 18);
    }

    /// @dev Wen the world is ready
    function revealCubs() public onlyOwner {
        _wenReveal = true;
    }

    /// @dev Enable adoption
    function setMintingBlock(uint256 wenMint) public onlyOwner {
        _wenMint = wenMint;
    }

    /// @dev Exposes the raw image SVG to the world, for any applications that can take advantage
    function imageSVG(uint256 tokenId) public view returns (string memory) {
        ICubTraits.TraitsV1 memory traits = traitsV1(tokenId);        
        return string(CubComposition.createSvg(traits, ADULT_AGE));
    }

    /// @dev Exposes the image URI to the world, for any applications that can take advantage
    function imageURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_baseImageURI(), Base64.encode(bytes(imageSVG(tokenId)))));
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentCub();
        return string(abi.encodePacked(_baseURI(), Base64.encode(_metadataForToken(tokenId))));
    }

    /// @notice Send funds from sales to the team
    function withdrawAll() public payable onlyOwner {
        payable(0xDC009bCb27c70A6Da5A083AA8C606dEB26806a01).transfer(address(this).balance);
    }

    function _adoptedPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](3);
        array[0] = 54; // 54% Brown/Happy
        array[1] = 30; // 30% Black/Hungry
        array[2] = 15; // 15% Polar/Sleepy
        return array; // 1% Panda/Grumpy
    }

    function _attributesFromTraits(ICubTraits.TraitsV1 memory traits) private pure returns (bytes memory) {
        return abi.encodePacked(
            "trait_type\":\"Species\",\"value\":\"", speciesForType(traits.species),
            _attributePair("Mood", moodForType(traits.mood)),
            _attributePair("Name", nameForTraits(traits)),
            _attributePair("Family", familyForTraits(traits)),
            _attributePair("Realistic Head Fur", SVG.svgColorWithType(traits.topColor, ISVG.ColorType.None)),
            _attributePair("Realistic Body Fur", SVG.svgColorWithType(traits.bottomColor, ISVG.ColorType.None))
        );
    }

    function _attributePair(string memory name, string memory value) private pure returns (bytes memory) {
        return abi.encodePacked("\"},{\"trait_type\":\"", name, "\",\"value\":\"", value);
    }

    function _baseImageURI() private pure returns (string memory) {
        return "data:image/svg+xml;base64,";
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    // @dev should return roughly 2414 mated cubs
    function _cubSiblingPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 70; // 70% single cub
        array[1] = 25; // 25% twin cubs
        return array; // 5% triplet cubs
    }

    function _metadataForToken(uint256 tokenId) private view returns (bytes memory) {
        if (_wenReveal) {
            ICubTraits.DNA memory dna = _tokenIdsToCubDNA[tokenId];
            ICubTraits.TraitsV1 memory traits = traitsV1(tokenId);
            return abi.encodePacked(
                "{\"name\":\"",
                    _nameFromTraits(traits, tokenId),
                "\",\"description\":\"",
                    moodForType(traits.mood), " ", speciesForType(traits.species),
                "\",\"attributes\":[{\"",
                    _attributesFromTraits(traits), _parentAttributesFromDNA(dna),
                "\"}],\"image\":\"",
                    _baseImageURI(), Base64.encode(CubComposition.createSvg(traits, ADULT_AGE)),
                "\"}"
            );
        }
        return abi.encodePacked(
            "{\"name\":\"Rendering Cub #", tokenId.toString(), "...\",\"description\":\"Unrevealed\",\"image\":\"ipfs://Qmc5YVyzKZ6D3wjqLFcfUBPtp9yh7NKxst2M2N3nDFdKDZ\"}"
        );
    }

    function _mintCubs(uint16 parentBearOne, uint16 parentBearTwo, uint256 quantity) private {
        if (_tokenCounter + quantity > MAX_CUBS) revert NoMoreCubs();
        uint256 localSeed = _seed; // Write to _seed only at the end of this function to reduce gas
        uint256 tokenId = _tokenCounter;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId);
            _tokenIdsToCubDNA[tokenId] = ICubTraits.DNA(_seed, parentBearOne, parentBearTwo);
            tokenId += 1;
            if (i + 1 < quantity) {
                // Perform a light-weight seed adjustment to save gas
                localSeed = uint256(keccak256(abi.encodePacked(localSeed >> 1)));
            }
        }
        _tokenCounter = tokenId;
        // The sender's transaction now salts the next cubs' randomness
        _seed = uint256(keccak256(abi.encodePacked(localSeed >> 1, msg.sender, blockhash(block.number-1), uint24(block.number))));
    }

    function _nameFromTraits(ICubTraits.TraitsV1 memory traits, uint256 tokenId) private pure returns (string memory) {
        // TwoBitCubs will have 0-based user-facing numbers, to reduce confusion
        string memory speciesSuffix = traits.age < ADULT_AGE ? " Cub #" : " Bear #"; // Adult cubs no longer say 'Cub'
        return string(abi.encodePacked(nameForTraits(traits), " ", familyForTraits(traits), " the ", moodForType(traits.mood), " ", speciesForType(traits.species), speciesSuffix, tokenId.toString()));
    }

    function _parentAttributesFromDNA(ICubTraits.DNA memory dna) private pure returns (bytes memory) {
        if (dna.firstParentTokenId == 0xFFFF) {
            return "";
        }
        // TwoBitBears was 0-based for id's, but 1-based for user-facing numbers (like many apps). Ensure we display user-facing numbers in the attributes
        (uint256 smaller, uint256 larger) = dna.firstParentTokenId < dna.secondParentTokenId ?
            (dna.firstParentTokenId, dna.secondParentTokenId) :
            (dna.secondParentTokenId, dna.firstParentTokenId);
        string memory parents = string(abi.encodePacked("#", (smaller + 1).toString(), " & #", (larger + 1).toString()));
        return _attributePair("Parents", parents);
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ICubTraits.sol";

/// @title TwoBitCubs NFT Interface for provided ICubTraits
interface ICubTraitProvider{

    /// Returns the family of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The family text
    function familyForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);

    /// Returns whether the TwoBitCub with the given DNA is adopted
    /// @param dna The DNA of the Cub
    /// @return Whether the cub is adopted
    function isAdopted(ICubTraits.DNA memory dna) external pure returns (bool);

    /// Returns the text of a mood based on the supplied type
    /// @param moodType The CubMoodType
    /// @return The mood text
    function moodForType(ICubTraits.CubMoodType moodType) external pure returns (string memory);

    /// Returns the mood of a TwoBitCub based on its TwoBitBear parents
    /// @param firstParentTokenId The ID of the token that represents the first parent
    /// @param secondParentTokenId The ID of the token that represents the second parent
    /// @return The mood type
    function moodFromParents(uint256 firstParentTokenId, uint256 secondParentTokenId) external view returns (ICubTraits.CubMoodType);

    /// Returns the name of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The name text
    function nameForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);
    
    /// Returns the text of a species based on the supplied type
    /// @param speciesType The CubSpeciesType
    /// @return The species text
    function speciesForType(ICubTraits.CubSpeciesType speciesType) external pure returns (string memory);

    /// Returns the v1 traits associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Cub
    /// @return traits memory
    function traitsV1(uint256 tokenId) external view returns (ICubTraits.TraitsV1 memory traits);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICubTraits.sol";
import "./SVG.sol";

/// @title CubComposition
library CubComposition {

    using Strings for uint256;

    /// Returns the bottom color of a Two Bit Bear using a random source of bytes and r/g/b indices into the array
    function colorBottomFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, ICubTraits.CubSpeciesType species) internal pure returns (ISVG.Color memory) {
        return SVG.randomizeColors(
            _colorBottomFloorForSpecies(species),
            _colorBottomCeilingForSpecies(species),
            ISVG.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]), 0xFF)
        );
    }

    /// Returns the top color of a Two Bit Bear using a random source of bytes and r/g/b indices into the array
    function colorTopFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, ICubTraits.CubSpeciesType species) internal pure returns (ISVG.Color memory) {
        return SVG.randomizeColors(
            _colorTopFloorForSpecies(species),
            _colorTopCeilingForSpecies(species),
            ISVG.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]), 0xFF)
        );
    }

    /// Mixes two input colors with random variations based on provided seed data and percentages
    function randomColorFromColors(ISVG.Color memory color1, ISVG.Color memory color2, bytes memory source, uint256 indexRatio, uint256 indexPercentage) internal pure returns (ISVG.Color memory color) {
        // ratioPercentage will range from 0-100 to lean towards color1 or color2 when mixing
        // totalPercentage will range from 97-103 to either undermix or overmix the parent colors
        color = SVG.mixColors(color1, color2, uint8(source[indexRatio]) % 101, 97 + (uint8(source[indexPercentage]) % 7));
        color.alpha = 0xFF; // Force the alpha to fully opaque, regardless of mixing
    }

    /// Creates the SVG for a TwoBitBear Cub based on its ICubDetail.Traits
    function createSvg(ICubTraits.TraitsV1 memory traits, uint256 adultAge) internal pure returns (bytes memory) {
        string memory transform = svgTransform(traits, adultAge);
        return abi.encodePacked(
            SVG.svgOpen(1080, 1080),
            _createPath(SVG.brightenColor(traits.topColor, 7), "Head", "M405 675 L540 675 540 540 405 540 Z", "M370 675 L570 675 570 540 370 560 Z", transform),
            _createPath(traits.topColor, "HeadShadow", "M540 675 L675 675 675 540 540 540 Z", "M570 675 L710 675 710 564 570 540 Z", transform),
            _createPath(SVG.brightenColor(traits.bottomColor, 7), "Torso", "M405 810 L540 810 540 675 405 675 Z", "M370 790 L570 810 570 675 370 675 Z", transform),
            _createPath(traits.bottomColor, "TorsoShadow", "M540 810 L675 810 675 675 540 675 Z", "M570 810 L710 786 710 675 570 675 Z", transform),
            "</svg>"
        );
    }

    function _createPath(ISVG.Color memory color, string memory name, string memory path1, string memory path2, string memory transform) private pure returns (bytes memory) {
        return abi.encodePacked(
            "<path id='", name, "' d='", path1, "'", SVG.svgColorWithType(color, ISVG.ColorType.Fill), transform, "><animate attributeName='d' values='", path1, ";", path2, "' begin='4s' dur='1s' fill='freeze'/></path>"
        );
    }

    /// Returns a value based on the spread of a random seed and provided percentages (last percentage is assumed if the sum of all elements do not add up to 100)
    function randomIndexFromPercentages(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
        uint256 spread = random % 100;
        uint256 remainingPercent = 100;
        for (uint256 i = 0; i < percentages.length; i++) {
            remainingPercent -= percentages[i];
            if (spread >= remainingPercent) {
                return i;
            }
        }
        return percentages.length;
    }

    /// Creates a `transform` attribute for a `path` element based on the age of the cub
    function svgTransform(ICubTraits.TraitsV1 memory traits, uint256 adultAge) internal pure returns (string memory) {
        (string memory yScale, string memory yTranslate) = _yTransforms(traits, adultAge);
        return string(abi.encodePacked(" transform='translate(0,", yTranslate, "),scale(1,", yScale, ")'"));
    }

    function toSvgColor(uint24 packedColor) internal pure returns (ISVG.Color memory color) {
        color.red = uint8(packedColor >> 16);
        color.green = uint8(packedColor >> 8);
        color.blue = uint8(packedColor);
        color.alpha = 0xFF;
    }

    function _colorBottomFloorForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x40260E);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x222225);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xB1B6B4);
        } else { // Panda
            return toSvgColor(0x000000);
        }
    }

    function _colorBottomCeilingForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x77512D);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x48484D);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xDFE7E6);
        } else { // Panda
            return toSvgColor(0x121213);
        }
    }

    function _colorTopFloorForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x8D5D33);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x383840);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xD0E5E2);
        } else { // Panda
            return toSvgColor(0xDDDDDE);
        }
    }

    function _colorTopCeilingForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0xC1A286);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x575C6D);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xEBF0EF);
        } else { // Panda
            return toSvgColor(0xE2E1E8);
        }
    }

    function _yTransforms(ICubTraits.TraitsV1 memory traits, uint256 adultAge) private pure returns (string memory scale, string memory translate) {
        if (traits.age >= adultAge) {
            translate = "-810";
            scale = "2";
        } else if (traits.age > 0) {
            uint256 fraction = traits.age * 810 / adultAge;
            translate = fraction < 1 ? "-1" : string(abi.encodePacked("-", fraction.toString()));
            fraction = traits.age * 100 / adultAge;
            scale = string(abi.encodePacked(fraction < 10 ? "1.0" : "1.", fraction.toString()));
        } else {
            translate = "0";
            scale = "1";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When total adoption quantity has been reached
error AdoptionLimitReached();

/// @dev When cub aging has already started
error AgingAlreadyStarted();

/// @dev When the parent bear is not owned by the caller
error BearNotOwned(uint256 tokenId);

/// @dev When the cub is not owned by the caller
error CubNotOwned(uint256 tokenId);

/// @dev When adoption quantity is too high or too low
error InvalidAdoptionQuantity();

/// @dev When the parent identifiers are not unique or not of the same species
error InvalidParentCombination();

/// @dev When the price for adoption is not correct
error InvalidPriceSent();

/// @dev When the maximum number of cubs has been met
error NoMoreCubs();

/// @dev When the cub tokenId does not exist
error NonexistentCub();

/// @dev When minting block hasn't yet been reached
error NotOpenForMinting();

/// @dev When Reveal is false
error NotYetRevealed();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/IBearable.sol";

/// Represents a deployed TwoBitHoney contract
abstract contract TwoBitHoney is IERC1155, IBearable {

    /// Sets the address of the TwoBitCubs contract, which will have rights to burn honey tokens
    function setCubsContractAddress(address cubsContract) external virtual;

    /// Performs the burn of a single honey token on behalf of the TwoBitCubs contract
    /// @dev Throws if the msg.sender is not the configured TwoBitCubs contract
    function burnHoneyForAddress(address burnTokenAddress) external virtual;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISVG.sol";

/// @title ICubTraits interface
interface ICubTraits {

    /// Represents the species of a TwoBitCub
    enum CubSpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a TwoBitCub
    enum CubMoodType {
        Happy, Hungry, Sleepy, Grumpy, Cheerful, Excited, Snuggly, Confused, Ravenous, Ferocious, Hangry, Drowsy, Cranky, Furious
    }

    // Represents the DNA for a TwoBitCub
    struct DNA {
        uint256 genes;
        uint16 firstParentTokenId;
        uint16 secondParentTokenId;
    }

    /// Represents the v1 traits of a TwoBitCub
    /// @dev so...there'll be more?
    struct TraitsV1 {
        uint256 age;
        ISVG.Color topColor;
        ISVG.Color bottomColor;
        uint8 nameIndex;
        uint8 familyIndex;
        CubMoodType mood;
        CubSpeciesType species;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISVG image library interface
interface ISVG {

    /// Represents a color in RGB format with alpha
    struct Color {
        uint8 red;
        uint8 green;
        uint8 blue;
        uint8 alpha;
    }

    /// Represents a color type in an SVG image file
    enum ColorType {
        Fill, Stroke, None
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVG.sol";

error RatioInvalid();

/// @title SVG image library
library SVG {

    using Strings for uint256;

    /// Returns a Color that is brightened by the provided percentage
    /// @dev Any color component that is 0 will be treated as if it is 1. Also does not modify alpha
    function brightenColor(ISVG.Color memory source, uint32 percentage) internal pure returns (ISVG.Color memory color) {
        color.red = _brightenComponent(source.red, percentage);
        color.green = _brightenComponent(source.green, percentage);
        color.blue = _brightenComponent(source.blue, percentage);
        color.alpha = source.alpha;
    }

    /// Returns a mixed Color by balancing the ratio of `color1` over `color2`, with a total percentage (for overmixing and undermixing outside the source bounds)
    /// @dev Reverts with `RatioInvalid()` if `ratioPercentage` is > 100
    function mixColors(ISVG.Color memory color1, ISVG.Color memory color2, uint32 ratioPercentage, uint32 totalPercentage) internal pure returns (ISVG.Color memory color) {
        if (ratioPercentage > 100) revert RatioInvalid();
        color.red = _mixComponents(color1.red, color2.red, ratioPercentage, totalPercentage);
        color.green = _mixComponents(color1.green, color2.green, ratioPercentage, totalPercentage);
        color.blue = _mixComponents(color1.blue, color2.blue, ratioPercentage, totalPercentage);
        color.alpha = _mixComponents(color1.alpha, color2.alpha, ratioPercentage, totalPercentage);
    }

    /// Returns a proportionally-randomized Color between the floor and ceiling colors using a random Color seed
    /// @dev This algorithm does not support floor rgb values matching ceiling rgb values (ceiling must be at least +1 higher for each component)
    function randomizeColors(ISVG.Color memory floor, ISVG.Color memory ceiling, ISVG.Color memory random) internal pure returns (ISVG.Color memory color) {
        uint16 percent = (uint16(random.red) + uint16(random.green) + uint16(random.blue)) % 101; // Range is from 0-100
        color.red = _randomizeComponent(floor.red, ceiling.red, random.red, percent);
        color.green = _randomizeComponent(floor.green, ceiling.green, random.green, percent);
        color.blue = _randomizeComponent(floor.blue, ceiling.blue, random.blue, percent);
        color.alpha = 0xFF;
    }

    /// Returns an RGB string suitable for SVG based on the supplied Color and ColorType
    /// @dev includes necessary leading space for all types _except_ None
    function svgColorWithType(ISVG.Color memory color, ISVG.ColorType colorType) internal pure returns (string memory) {
        require(uint(colorType) < 3, "Invalid colorType");
        if (colorType == ISVG.ColorType.Fill) return string(abi.encodePacked(" fill='rgb(", _rawColor(color), ")'"));
        if (colorType == ISVG.ColorType.Stroke) return string(abi.encodePacked(" stroke='rgb(", _rawColor(color), ")'"));
        return string(abi.encodePacked("rgb(", _rawColor(color), ")")); // Fallback to None
    }
    
    /// Returns the opening of an SVG tag based on the supplied width and height
    function svgOpen(uint256 width, uint256 height) internal pure returns (string memory) {
        return string(abi.encodePacked("<svg viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg' version='1.1'>"));
    }

    function _brightenComponent(uint8 component, uint32 percentage) private pure returns (uint8 result) {
        uint32 brightenedComponent = (component == 0 ? 1 : component) * (percentage + 100) / 100;
        if (brightenedComponent > 0xFF) {
            result = 0xFF; // Clamp to 8 bits
        } else {
            result = uint8(brightenedComponent);
        }
    }

    function _mixComponents(uint8 component1, uint8 component2, uint32 ratioPercentage, uint32 totalPercentage) private pure returns (uint8 component) {
        uint32 mixedComponent = (uint32(component1) * ratioPercentage + uint32(component2) * (100 - ratioPercentage)) * totalPercentage / 10000;
        if (mixedComponent > 0xFF) {
            component = 0xFF; // Clamp to 8 bits
        } else {
            component = uint8(mixedComponent);
        }
    }

    function _randomizeComponent(uint8 floor, uint8 ceiling, uint8 random, uint16 percent) private pure returns (uint8 component) {
        component = floor + uint8(uint16(ceiling - (random & 0x01) - floor) * percent / uint16(100));
    }

    function _rawColor(ISVG.Color memory color) private pure returns (string memory) {
        return string(abi.encodePacked(uint256(color.red).toString(), ",", uint256(color.green).toString(), ",", uint256(color.blue).toString()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISVG.sol";

/// @title Interface for accessing official TwoBitBears data
interface IBearable {

    /// Represents the species of a TwoBitBear
    enum BearSpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a TwoBitBear
    enum BearMoodType {
        Happy, Hungry, Sleepy, Grumpy
    }

    /// Returns whether the TwoBitBear at tokenId currently belongs to the owner
    /// @dev Throws if the token ID is not valid.
    function ownsBear(address possibleOwner, uint256 tokenId) external view returns (bool);

    /// Returns the total tokens in the TwoBitBear contract
    function totalBears() external view returns (uint256);

    /// Returns the realistic body fur color of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearBottomColor(uint256 tokenId) external view returns (ISVG.Color memory color);

    /// Returns the all-important `BearMoodType` of the TwoBitBear at tokenId (be nice)
    /// @dev Throws if the token ID is not valid.
    function bearMood(uint256 tokenId) external view returns (BearMoodType);

    /// Returns the BearSpeciesType of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearSpecies(uint256 tokenId) external view returns (BearSpeciesType);

    /// Returns the realistic head fur color of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearTopColor(uint256 tokenId) external view returns (ISVG.Color memory color);
}