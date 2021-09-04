//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./PFPAbilityScoresSvgs.sol";

contract PFPAbilityScores is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    // ON-CHAIN METADATA
    PFPAbilityScoresSvgs metadata;

    // CONSTANTS
    uint256 public constant MINT_PRICE = 15000000000000000;
    uint256 public constant MAX_PURCHASE_COUNT = 20;
    uint256 public MAX_NFT_COUNT = 40000;

    // METADATA SEED
    uint256 public FINAL_BLOCK_HEIGHT = 0;
    uint256 public RANDOM_SEED = 0;

    // ABILITIES
    uint256 NUM_TRAITS = 6;
    uint256 NUM_AFFINITIES = 6;
    uint256[15] SCORE_THRESHOLDS = [5, 17, 38, 70, 118, 186, 281, 411, 588, 827, 1147, 1574, 2142, 2896, 3896];

    uint256 OFFSET_TRAITS     = 0;
    uint256 OFFSET_AFFINITIES = 16;
    uint256 OFFSET_SCORE      = 32;

    uint256 TRAIT_MASK    = 0xffff;
    uint256 AFFINITY_MASK = 0xffff;
    uint256 SCORE_MASK    = 0xffffffff;

    uint8 DEFAULT_SCORE = 10;
    uint256 MIN_SCORE = 11;
    uint256 MAX_SCORE = 25;

    enum AbilityTrait { STR, DEX, CON, INT, WIS, CHA }
    enum AbilityAffinity { VOID, EARTH, FIRE, LIGHTNING, WIND, WATER }
    struct Ability {
        uint256         tokenId;
        AbilityTrait    trait;
        AbilityAffinity affinity;
        uint8           score;
    }

    // METADATA
    string public DESCRIPTION = "These are a set of 100% on-chain stats (Strength, Dexterity, Constitution, Intelligence, Wisdom, and Charismma) you can rely on being available for any wallet, anytime.  Work to collect, trade, and upgrade your PFP's abilities today.";
    string public EXTERNAL_URL = "https://pfpabilityscores.eth.link";

    // LOGIC
    constructor(address _metadata) ERC721("PFP Ability Scores", "PFPABILITYSCORES") {
        metadata = PFPAbilityScoresSvgs(_metadata);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setDescription(string calldata _desc) public onlyOwner {
        DESCRIPTION = _desc;
    }

    function setExternalUrl(string calldata _url) public onlyOwner {
        EXTERNAL_URL = _url;
    }

    function burnRemaining() public onlyOwner {
        require(totalSupply() < MAX_NFT_COUNT, "Can't burn remaining when supply is max");
        MAX_NFT_COUNT = totalSupply(); // Reduce supply
        _setFinalBlock(); // Set final block
    }

    function purchase(uint256 _numTokens) public payable nonReentrant {
        require(_numTokens <= MAX_PURCHASE_COUNT, "Max 20 NFTs can be minted");
        require((MINT_PRICE * _numTokens) == msg.value, "Incorrect ETH amount sent");
        require((totalSupply() + _numTokens) <=  MAX_NFT_COUNT, "Mint request exceeds supply");

        uint256 _tokenId = totalSupply();
        for (uint256 i = 0; i < _numTokens; i++) {
            _safeMint(msg.sender, ++_tokenId);
        }

        if (totalSupply() == MAX_NFT_COUNT) {
            _setFinalBlock();
        }
    }

    function airdrop(address[] calldata _to, uint256 _numTokensEach) public nonReentrant onlyOwner {
        require((totalSupply() + _numTokensEach * _to.length) <=  MAX_NFT_COUNT, "Mint request exceeds supply");

        uint256 _tokenId = totalSupply();

        for (uint256 iAddr = 0; iAddr < _to.length; iAddr++) {
            for (uint256 i = 0; i < _numTokensEach; i++) {
                _safeMint(_to[iAddr], ++_tokenId);
            }
        }

        if (totalSupply() == MAX_NFT_COUNT) {
            _setFinalBlock();
        }
    }

    function _setFinalBlock() internal {
        require(FINAL_BLOCK_HEIGHT == 0, "Final block height already set");
        FINAL_BLOCK_HEIGHT = block.number;
    }

    function lockSeed() public nonReentrant {
        require(FINAL_BLOCK_HEIGHT > 0, "Final block height not set");
        require(RANDOM_SEED == 0, "Random seed already set");

        // Use the blockhash of the final block height to determine the random seed
        if (FINAL_BLOCK_HEIGHT + 255 <= block.number) {
            RANDOM_SEED = uint256(
                keccak256(
                    abi.encodePacked(
                        FINAL_BLOCK_HEIGHT,
                        blockhash(FINAL_BLOCK_HEIGHT)
                    )
                )
            );
        // If, for whatever reason, we don't set the random seed in time, then fallback
        } else {
            RANDOM_SEED = uint256(
                keccak256(
                    abi.encodePacked(
                        FINAL_BLOCK_HEIGHT,
                        owner()
                    )
                )
            );
        }
    }

    function revealed() public view returns (bool) {
        return RANDOM_SEED > 0;
    }

    function getStats(address _wallet) public view returns(Ability[] memory stats) {
        stats = new Ability[](6);

        // Defaults
        for (uint256 i = 0; i < stats.length; i++) {
            stats[i].trait = AbilityTrait(i);
            stats[i].score = DEFAULT_SCORE;
        }

        if (revealed()) {
            // Get stats
            uint256 balance = balanceOf(_wallet);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_wallet, i);
                Ability memory tokenAbility = getAbility(tokenId);
                if (stats[uint256(tokenAbility.trait)].score < tokenAbility.score) {
                    stats[uint256(tokenAbility.trait)] = tokenAbility;
                }
            }
        }
    }

    function getAffinityStats(address _wallet, uint256 _affinity) public view returns(Ability[] memory stats) {
        stats = new Ability[](6);

        // Defaults
        for (uint256 i = 0; i < stats.length; i++) {
            stats[i].trait = AbilityTrait(i);
            stats[i].score = DEFAULT_SCORE;
        }

        if (revealed()) {
            // Get stats
            uint256 balance = balanceOf(_wallet);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_wallet, i);
                Ability memory tokenAbility = getAbility(tokenId);
                if (tokenAbility.affinity == AbilityAffinity(_affinity)) {
                    if (stats[uint256(tokenAbility.trait)].score < tokenAbility.score) {
                        stats[uint256(tokenAbility.trait)] = tokenAbility;
                    }
                }
            }
        }
    }

    function getAbility(uint256 _tokenId) public view returns (Ability memory) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(RANDOM_SEED, _tokenId)
            )
        );

        // Determine the trait, affinity
        AbilityTrait    trait    = getTrait(randomNumber);
        AbilityAffinity affinity = getAffinity(randomNumber);

        // Determine the score
        uint8 score = getScore(randomNumber);

        return Ability(_tokenId, trait, affinity, score);
    }

    function getTrait(uint256 _random) internal view returns (AbilityTrait) {
        return AbilityTrait(((_random >> OFFSET_TRAITS) & TRAIT_MASK) % NUM_TRAITS);
    }

    function getAffinity(uint256 _random) internal view returns (AbilityAffinity) {
        if (_random == 0) {
            return AbilityAffinity(0); // VOID
        }

        return AbilityAffinity((((_random >> OFFSET_AFFINITIES) & AFFINITY_MASK) % (NUM_AFFINITIES - 1)) + 1);
    }

    function getScore(uint256 _random) internal view returns (uint8) {
        if (_random == 0) {
            return DEFAULT_SCORE; // Default per wallet
        }

        uint256 score = ((_random >> OFFSET_SCORE) & SCORE_MASK) % SCORE_THRESHOLDS[SCORE_THRESHOLDS.length - 1];

        // Start at the second-to-last, work down
        for (uint256 i = SCORE_THRESHOLDS.length - 2; i > 0; i--) {
            if (score >= SCORE_THRESHOLDS[i]) {
                return uint8(MAX_SCORE - (i + 1));
            }
        }

        if (score >= SCORE_THRESHOLDS[0]) {
            return uint8(MAX_SCORE - 1);
        }

        return uint8(MAX_SCORE);
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(totalSupply() >= _tokenId, "Token ID does not exist");

        // Pre-reveal
        if (RANDOM_SEED == 0) {
            return string(
                abi.encodePacked(
                    abi.encodePacked(
                        bytes('data:application/json;utf8,{"name":"Ability #'),
                        uint2str(_tokenId),
                        bytes('","description":"'),
                        DESCRIPTION,
                        bytes('","external_url":"'),
                        bytes(EXTERNAL_URL),
                        bytes('","image_data":"'),
                        metadata.getDefaultSvg(),
                        bytes('"}')
                    )
                )
            );
        }

        Ability memory ability = getAbility(_tokenId);

        return string(
            abi.encodePacked(
                abi.encodePacked(
                    bytes('data:application/json;utf8,{"name":"Ability #'),
                    uint2str(_tokenId),
                    bytes('","description":"'),
                    DESCRIPTION,
                    bytes('","external_url":"'),
                    bytes(EXTERNAL_URL),
                    bytes('","image_data":"'),
                    metadata.getSvg(uint256(ability.trait), uint256(ability.affinity), uint256(ability.score))
                ),
                abi.encodePacked(
                    bytes('","attributes":[{"trait_type": "Ability", "value": "'),
                    traitToString(ability.trait),
                    bytes('"},{"trait_type": "Element", "value": "'),
                    affinityToString(ability.affinity),
                    bytes('"},{"trait_type": "Score", "value": '),
                    uint2str(uint256(ability.score)),
                    bytes('}]}')
                )
            )
        );
    }

    function traitToString(AbilityTrait _trait) public pure returns (string memory) {
        if (_trait == AbilityTrait.STR) {
            return "Strength";
        } else if (_trait == AbilityTrait.DEX) {
            return "Dexterity";
        } else if (_trait == AbilityTrait.CON) {
            return "Constitution";
        } else if (_trait == AbilityTrait.INT) {
            return "Intellect";
        } else if (_trait == AbilityTrait.WIS) {
            return "Wisdom";
        } else if (_trait == AbilityTrait.CHA) {
            return "Charisma";
        }

        return "";
    }

    function affinityToString(AbilityAffinity _affinity) public pure returns (string memory) {
        if (_affinity == AbilityAffinity.EARTH) {
            return "Earth";
        } else if (_affinity == AbilityAffinity.FIRE) {
            return "Fire";
        } else if (_affinity == AbilityAffinity.LIGHTNING) {
            return "Lightning";
        } else if (_affinity == AbilityAffinity.WIND) {
            return "Wind";
        } else if (_affinity == AbilityAffinity.WATER) {
            return "Water";
        }

        return "Void";
    }


    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        return string(bstr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function checkCredits(bytes memory _credits) public pure returns (bool) {
        return bytes32(0xa248833c524b8486a9a02690e46068063fb5407b0547bf0521d6820d4def3111) == keccak256(_credits);
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

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PFPAbilityScoresSvgs is Ownable {

    // Constants
    bytes[6] public primaryColors   = [bytes('6E6E6E'), bytes('656D4A'), bytes('DC2F02'), bytes('5C415D'), bytes('8594D6'), bytes('1B4965')];
    bytes[6] public secondaryColors = [bytes('DADADA'), bytes('B6AD90'), bytes('FAA307'), bytes('FFFC31'), bytes('D6E5E3'), bytes('5FA8D3')];

    // Ordering: STR, DEX, CON, INT, WIS, CHA
    bytes[6] public abilitySizes = [bytes('421 347'), bytes('340 355'), bytes('354 362'), bytes('409 359'), bytes('352 372'), bytes('403 377')];
    bytes[6] public elementPos   = [bytes('127 126'), bytes('100 102'), bytes('106 128'), bytes('137 91'), bytes('105 56'), bytes('134 58')];
    bytes[6] public scorePos     = [bytes('289 243'), bytes('28 233'), bytes('29 255'), bytes('53 38'), bytes('28 39'), bytes('299 49')];

    // Data
    bytes[6] public elements;
    bytes[30] public scores;

    // Abilities are stored into three components each
    // Top
    // -> Element
    // Middle
    // -> Number
    // Footer
    bytes[6] public abilities_top;
    bytes[6] public abilities_mid;
    bytes[6] public abilities_bot;


    function storeAbilityTop(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        abilities_top[_ability] = _b;
    }

    function storeAbilityMid(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        abilities_mid[_ability] = _b;
    }

    function appendAbilityMid(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        abilities_mid[_ability] = abi.encodePacked(abilities_mid[_ability], _b);
    }

    function storeAbilityBot(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        abilities_bot[_ability] = _b;
    }

    function storeElement(uint256 _element, bytes memory _b) public onlyOwner {
        require(_element <= 5, "Out of range");
        elements[_element] = _b;
    }

    function storeScore(uint256 _score, bytes memory _b) public onlyOwner {
        require(_score <= 99, "Out of range");
        scores[_score] = _b;
    }

    function setAbilitySize(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        abilitySizes[_ability] = _b;
    }

    function setElementPos(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        elementPos[_ability] = _b;
    }

    function setScorePos(uint256 _ability, bytes memory _b) public onlyOwner {
        require(_ability <= 5, "Out of range");
        scorePos[_ability] = _b;
    }

    function getSvg(uint256 _ability, uint256 _element, uint256 _score) public view returns (bytes memory) {
        return abi.encodePacked(
            getHeader(_ability, _element),
            abilities_top[_ability],
            getElement(_ability, _element),
            abilities_mid[_ability],
            getScore(_ability, _score),
            abilities_bot[_ability],
            bytes('</svg>')
        );
    }

    function getSvgString(uint256 _ability, uint256 _element, uint256 _score) public view returns (string memory) {
        return string(getSvg(_ability, _element, _score));
    }

    function getHeader(uint256 _ability, uint256 _element) internal view returns (bytes memory) {
        return abi.encodePacked(
            bytes('<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?><svg version=\\"1.1\\" viewBox=\\"0 0 '),
            abilitySizes[_ability],
            bytes('\\" xmlns=\\"http://www.w3.org/2000/svg\\"><defs><linearGradient id=\\"primaryColor\\"><stop stop-color=\\"#'),
            primaryColors[_element],
            bytes('\\"/></linearGradient><linearGradient id=\\"secondaryColor\\"><stop stop-color=\\"#'),
            secondaryColors[_element],
            bytes('\\"/></linearGradient></defs>')
        );
    }

    function getElement(uint256 _ability, uint256 _element) internal view returns (bytes memory) {
        return abi.encodePacked(
            bytes('<g transform=\\"translate('),
            elementPos[_ability],
            bytes(')\\">'),
            elements[_element],
            bytes('</g>')
        );
    }

    function getScore(uint256 _ability, uint256 _score) internal view returns (bytes memory) {
        return abi.encodePacked(
            bytes('<g transform=\\"translate('),
            scorePos[_ability],
            bytes(')\\">'),
            scores[_score],
            bytes('</g>')
        );
    }

    function getDefaultSvg() public view returns (bytes memory) {
        return bytes('<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?><svg width=\\"330px\\" height=\\"330px\\" viewBox=\\"0 0 330 330\\" version=\\"1.1\\" xmlns=\\"http://www.w3.org/2000/svg\\" xmlns:xlink=\\"http://www.w3.org/1999/xlink\\"><g id=\\"pfp-unrevealed\\"><path d=\\"M165.1,10.4 C79.9,10.4 10.6,79.7 10.6,164.8 C10.6,250 79.9,319.3 165.1,319.3 C250.2,319.3 319.5,250 319.5,164.8 C319.5,79.7 250.2,10.4 165.1,10.4 Z\\" id=\\"Path-Copy-6\\" fill=\\"#DADADA\\"></path><path d=\\"M165.1,10.4 C79.9,10.4 10.6,79.7 10.6,164.8 C10.6,250 79.9,319.3 165.1,319.3 C250.2,319.3 319.5,250 319.5,164.8 C319.5,79.7 250.2,10.4 165.1,10.4 Z M165.1,329.3 C74.4,329.3 0.6,255.5 0.6,164.8 C0.6,74.2 74.4,0.4 165.1,0.4 C255.8,0.4 329.5,74.2 329.5,164.8 C329.5,255.5 255.8,329.3 165.1,329.3 L165.1,329.3 Z\\" id=\\"Fill-136\\" fill=\\"#6E6E6E\\"></path><path d=\\"M165.1,23.9 C87.4,23.9 24.1,87.1 24.1,164.8 C24.1,242.6 87.4,305.8 165.1,305.8 C242.8,305.8 306,242.6 306,164.8 C306,87.1 242.8,23.9 165.1,23.9 Z M165.1,312.8 C83.5,312.8 17.1,246.4 17.1,164.8 C17.1,83.3 83.5,16.9 165.1,16.9 C246.7,16.9 313,83.3 313,164.8 C313,246.4 246.7,312.8 165.1,312.8 L165.1,312.8 Z\\" id=\\"Fill-137\\" fill=\\"#6E6E6E\\"></path><path d=\\"M131.6,169 L131.6,151.3 L136.3,151.3 C140.3,151.3 143.7,150.3 146.5,148.1 C149.3,145.8 150.8,142.7 150.8,139 L150.8,139 L150.8,126.2 C150.8,124.3 150.1,122.7 148.6,121.4 C147.2,120.1 145.5,119.4 143.5,119.4 L143.5,119.4 L121.8,119.4 L121.8,169 L131.6,169 Z M136.3,142.2 L131.6,142.2 L131.6,128.6 L140.9,128.6 L140.9,139 C140.9,141.1 139.4,142.2 136.3,142.2 L136.3,142.2 Z M163.8,169 L163.8,148.8 L177.5,148.8 L177.5,139.6 L163.8,139.6 L163.8,128.6 L180.2,128.6 L180.2,119.4 L154,119.4 L154,169 L163.8,169 Z M191.8,169 L191.8,151.3 L196.4,151.3 C200.5,151.3 203.9,150.3 206.6,148.1 C209.5,145.8 210.9,142.7 210.9,139 L210.9,139 L210.9,126.2 C210.9,124.3 210.2,122.7 208.8,121.4 C207.3,120.1 205.6,119.4 203.7,119.4 L203.7,119.4 L181.9,119.4 L181.9,169 L191.8,169 Z M196.4,142.2 L191.8,142.2 L191.8,128.6 L201.1,128.6 L201.1,139 C201.1,141.1 199.5,142.2 196.4,142.2 L196.4,142.2 Z M93,199 L93.8,195 L97.1,195 L97.9,199 L101.9,199 L98.1,179.2 L92.8,179.2 L89,199 L93,199 Z M96.4,191.3 L94.5,191.3 L95.5,182.9 L96.4,191.3 Z M108.5,199 C110.1,199 111.4,198.6 112.5,197.7 C113.7,196.8 114.3,195.6 114.3,194 L114.3,194 L114.3,192.2 C114.3,190.8 113.7,189.7 112.5,188.9 C113.4,188.1 113.8,187.2 113.8,186 L113.8,186 L113.8,181.9 C113.8,181.1 113.5,180.5 112.9,180 C112.3,179.4 111.6,179.2 110.9,179.2 L110.9,179.2 L102.7,179.2 L102.7,199 L108.5,199 Z M108.4,187.2 L106.6,187.2 L106.6,182.8 L109.8,182.8 L109.8,186 C109.8,186.3 109.7,186.6 109.4,186.9 C109.1,187.1 108.8,187.2 108.4,187.2 L108.4,187.2 Z M108.5,195.3 L106.6,195.3 L106.6,190.9 L108.9,190.9 C109.3,190.9 109.6,191 109.9,191.3 C110.2,191.5 110.3,191.8 110.3,192.2 L110.3,192.2 L110.3,194 C110.3,194.9 109.7,195.3 108.5,195.3 L108.5,195.3 Z M120,199 L120,179.2 L116.1,179.2 L116.1,199 L120,199 Z M131.6,199 L131.6,195.3 L126.2,195.3 L126.2,179.2 L122.2,179.2 L122.2,199 L131.6,199 Z M136.3,199 L136.3,179.2 L132.4,179.2 L132.4,199 L136.3,199 Z M145.1,199 L145.1,182.8 L148.9,182.8 L148.9,179.2 L137.3,179.2 L137.3,182.8 L141.2,182.8 L141.2,199 L145.1,199 Z M156,199 L156,192.2 L160.1,179.2 L156.1,179.2 C155.5,181.1 154.8,184.3 154,188.7 C153.2,184.3 152.5,181.1 151.9,179.2 L151.9,179.2 L147.9,179.2 L152,192.2 L152,199 L156,199 Z M173.7,199 C174.5,199 175.2,198.7 175.8,198.2 C176.3,197.7 176.6,197 176.6,196.3 L176.6,196.3 L176.6,192.2 C176.6,190.7 176.1,189.5 174.9,188.5 C173.8,187.7 172.5,187.2 170.8,187.2 C169.6,187.2 169,186.8 169,186 L169,186 L169,182.8 L172.7,182.8 L172.7,185.9 L176.6,185.9 L176.6,181.9 C176.6,181.1 176.3,180.5 175.8,180 C175.2,179.4 174.5,179.2 173.7,179.2 L173.7,179.2 L167.9,179.2 C167.1,179.2 166.5,179.4 165.9,180 C165.3,180.5 165,181.1 165,181.9 L165,181.9 L165,186 C165,187.5 165.6,188.7 166.8,189.6 C167.8,190.5 169.2,190.9 170.8,190.9 C172.1,190.9 172.7,191.4 172.7,192.2 L172.7,192.2 L172.7,195.3 L169,195.3 L169,192.3 L165,192.3 L165,196.3 C165,197 165.3,197.7 165.9,198.2 C166.5,198.7 167.1,199 167.9,199 L167.9,199 L173.7,199 Z M186.8,199 C187.6,199 188.3,198.7 188.9,198.2 C189.4,197.7 189.7,197 189.7,196.3 L189.7,196.3 L189.7,192.3 L185.8,192.3 L185.8,195.3 L182.1,195.3 L182.1,182.8 L185.8,182.8 L185.8,185.9 L189.7,185.9 L189.7,181.9 C189.7,181.1 189.4,180.5 188.9,180 C188.3,179.4 187.6,179.2 186.8,179.2 L186.8,179.2 L181,179.2 C180.2,179.2 179.6,179.4 179,180 C178.4,180.5 178.1,181.1 178.1,181.9 L178.1,181.9 L178.1,196.3 C178.1,197 178.4,197.7 179,198.2 C179.6,198.7 180.2,199 181,199 L181,199 L186.8,199 Z M199.6,199 C200.4,199 201.1,198.7 201.7,198.2 C202.3,197.7 202.6,197 202.6,196.3 L202.6,196.3 L202.6,181.9 C202.6,181.1 202.3,180.5 201.7,180 C201.1,179.4 200.4,179.2 199.6,179.2 L199.6,179.2 L193.9,179.2 C193.1,179.2 192.4,179.4 191.8,180 C191.2,180.5 191,181.1 191,181.9 L191,181.9 L191,196.3 C191,197 191.2,197.7 191.8,198.2 C192.4,198.7 193.1,199 193.9,199 L193.9,199 L199.6,199 Z M198.6,195.3 L194.9,195.3 L194.9,182.8 L198.6,182.8 L198.6,195.3 Z M208.7,199 L208.7,191.9 L211,191.9 C211.4,191.9 211.7,192.1 212,192.3 C212.2,192.6 212.4,192.9 212.4,193.2 L212.4,193.2 L212.4,199 L216.3,199 L216.3,193.2 C216.3,191.9 215.8,190.9 214.8,190.1 C215.8,189.3 216.3,188.3 216.3,187 L216.3,187 L216.3,181.9 C216.3,181.1 216,180.5 215.5,180 C214.9,179.4 214.2,179.2 213.4,179.2 L213.4,179.2 L204.7,179.2 L204.7,199 L208.7,199 Z M211,188.3 L208.7,188.3 L208.7,182.8 L212.4,182.8 L212.4,187 C212.4,187.3 212.2,187.6 212,187.9 C211.7,188.1 211.4,188.3 211,188.3 L211,188.3 Z M228.8,199 L228.8,195.3 L222.2,195.3 L222.2,190.9 L227.7,190.9 L227.7,187.2 L222.2,187.2 L222.2,182.8 L228.8,182.8 L228.8,179.2 L218.3,179.2 L218.3,199 L228.8,199 Z M238.3,199 C239,199 239.7,198.7 240.3,198.2 C240.9,197.7 241.2,197 241.2,196.3 L241.2,196.3 L241.2,192.2 C241.2,190.7 240.6,189.5 239.4,188.5 C238.3,187.7 237,187.2 235.4,187.2 C234.1,187.2 233.5,186.8 233.5,186 L233.5,186 L233.5,182.8 L237.2,182.8 L237.2,185.9 L241.2,185.9 L241.2,181.9 C241.2,181.1 240.9,180.5 240.3,180 C239.7,179.4 239,179.2 238.3,179.2 L238.3,179.2 L232.5,179.2 C231.7,179.2 231,179.4 230.4,180 C229.8,180.5 229.6,181.1 229.6,181.9 L229.6,181.9 L229.6,186 C229.6,187.5 230.1,188.7 231.3,189.6 C232.4,190.5 233.7,190.9 235.4,190.9 C236.6,190.9 237.2,191.4 237.2,192.2 L237.2,192.2 L237.2,195.3 L233.5,195.3 L233.5,192.3 L229.6,192.3 L229.6,196.3 C229.6,197 229.8,197.7 230.4,198.2 C231,198.7 231.7,199 232.5,199 L232.5,199 L238.3,199 Z\\" id=\\"PFPABILITYSCORES\\" fill=\\"#6E6E6E\\" fill-rule=\\"nonzero\\"></path><g id=\\"element-wind\\" transform=\\"translate(131, 36)\\" fill=\\"#6E6E6E\\"><path d=\\"M22.2,21.2 C23.1,21.7 24.1,21.9 25.2,21.9 L49.5,21.9 C50.1,21.9 50.5,21.4 50.5,20.9 C50.5,20.3 50.1,19.8 49.5,19.8 L25.2,19.8 C24.4,19.8 23.7,19.7 23.1,19.4 C20.9,18.3 19.3,16.4 18.6,14.1 C17.7,11.1 18.9,7.9 21.5,6.2 C23.7,4.9 26.4,5.2 28.2,7.1 C29.3,8.3 29.8,9.7 29.4,11.1 C29.1,12.5 28.1,13.6 26.8,14 C26.1,14.2 25.3,14.2 24.6,13.8 C23.9,13.4 23.4,12.8 23.2,12 C23,11.5 22.4,11.2 21.9,11.4 C21.4,11.5 21.1,12.1 21.2,12.7 C21.6,14 22.5,15 23.7,15.6 C24.8,16.2 26.2,16.4 27.4,16 C29.4,15.3 30.9,13.7 31.4,11.6 C31.9,9.5 31.2,7.3 29.6,5.7 C27.2,3.1 23.4,2.6 20.5,4.5 C17,6.6 15.5,10.8 16.7,14.7 C17.6,17.6 19.6,20 22.2,21.2\\" id=\\"Fill-44\\"></path><path d=\\"M43.8,34.6 L15.2,34.6 C13.9,34.6 12.7,34.9 11.7,35.4 C8.7,36.9 6.4,39.6 5.3,42.9 C3.9,47.4 5.8,52.2 9.7,54.6 C11.1,55.5 12.6,55.9 14.1,55.9 C16.4,55.9 18.6,55 20.3,53.3 C22.1,51.4 22.9,48.9 22.3,46.5 C21.7,44.1 20,42.3 17.7,41.6 C14.8,40.6 11.6,42.3 10.7,45.3 C10.5,45.8 10.8,46.4 11.4,46.6 C11.9,46.7 12.5,46.4 12.6,45.9 C13.2,44 15.2,42.9 17.1,43.5 C18.7,44 19.9,45.3 20.3,47 C20.7,48.7 20.2,50.4 18.9,51.8 C16.6,54.1 13.4,54.5 10.8,52.9 C7.6,50.9 6.1,47.1 7.3,43.5 C8.1,40.7 10,38.5 12.6,37.2 C13.3,36.9 14.2,36.7 15.2,36.7 L43.8,36.7 C44.4,36.7 44.8,36.2 44.8,35.7 C44.8,35.1 44.4,34.6 43.8,34.6\\" id=\\"Fill-45\\"></path><path d=\\"M56.4,25.4 L27.9,25.4 C27.4,25.4 26.9,25.8 26.9,26.3 C26.9,26.9 27.4,27.3 27.9,27.3 L56.4,27.3 C56.9,27.3 57.4,26.9 57.4,26.3 C57.4,25.8 56.9,25.4 56.4,25.4\\" id=\\"Fill-46\\"></path><path d=\\"M15.4,31.9 L43.8,31.9 C44.4,31.9 44.8,31.5 44.8,31 C44.8,30.4 44.4,30 43.8,30 L15.4,30 C14.8,30 14.4,30.4 14.4,31 C14.4,31.5 14.8,31.9 15.4,31.9\\" id=\\"Fill-47\\"></path></g><g id=\\"element-earth\\" transform=\\"translate(192, 218)\\" fill=\\"#6E6E6E\\" fill-rule=\\"nonzero\\"><path d=\\"M42.4,44.7 C42.4,46.9 40.5,48.7 38.3,48.7 L24.1,48.7 C23.6,48.7 23.2,48.7 22.8,48.5 L4.5,42.5 C2.7,41.9 1.5,40 1.8,38.1 L2.8,30.5 C3.6,25.3 7.3,21.1 12.3,19.8 L24,16.9 C24.3,16.8 24.7,16.8 25,16.8 C25.9,16.8 26.7,17 27.4,17.6 L40.7,27.7 C41.8,28.5 42.4,29.7 42.4,30.9 L42.4,44.7 L42.4,44.7 Z M42.5,26.4 L29.2,16.3 C27.7,15.1 25.8,14.7 23.9,15.2 L12.2,18.1 C6.3,19.6 1.9,24.5 1.1,30.6 L0.1,38.2 C-0.4,41.2 1.4,44.1 4.3,45 L22.6,51.1 C23.2,51.3 23.8,51.4 24.5,51.4 L38.8,51.4 C42.2,51.4 45,48.6 45,45.1 L45,31.4 C45,29.4 44.1,27.6 42.5,26.4 L42.5,26.4 Z\\" id=\\"Shape\\"></path><path d=\\"M46.1,17.3 L44.3,21.1 C44.2,21.3 43.9,21.4 43.6,21.3 L39.4,19.2 C39.3,19.2 39.3,19.1 39.2,19.1 L34.6,14.7 C34.4,14.5 34.3,14.3 34.4,14.1 L35.7,12.1 C36.3,11.3 37.2,10.8 38.3,10.8 C38.6,10.8 38.8,10.8 39.1,10.9 L42.9,11.7 C43.1,11.8 43.3,11.9 43.4,12.1 L46,16.9 C46.1,17 46.1,17.2 46.1,17.3 L46.1,17.3 Z M48.4,16.2 L45.7,11.4 L45.7,11.4 C45.3,10.7 44.6,10.2 43.9,10 L40,9.1 C37.7,8.6 35.5,9.5 34.3,11.3 L33,13.3 C32.3,14.4 32.5,15.9 33.5,16.8 L38.2,21.1 C38.4,21.3 38.7,21.5 38.9,21.6 L43.2,23.7 C43.6,23.9 44,24 44.4,24 C45.4,24 46.3,23.5 46.8,22.5 L48.5,18.7 C48.9,17.9 48.8,17 48.4,16.2 L48.4,16.2 Z\\" id=\\"Shape\\"></path><path d=\\"M57.3,28 L54.4,29.8 C54.4,29.8 54.4,29.8 54.3,29.9 L50,31.1 C50,31.1 50,31.1 50,31.1 L49.5,29.7 C49.2,29 49.4,28.1 50.1,27.5 L52.1,25.4 C52.2,25.4 52.2,25.4 52.3,25.4 L52.3,25.4 L56,25.4 L57.4,27.8 C57.4,27.8 57.4,27.9 57.3,28 L57.3,28 Z M59.7,27.2 L59.7,27.2 L58.3,24.7 C57.9,24.1 57.2,23.7 56.5,23.7 L52.8,23.6 C52.7,23.6 52.7,23.6 52.7,23.6 C52.1,23.6 51.5,23.9 51,24.3 L49,26.4 C47.7,27.7 47.3,29.5 47.9,31 L48.5,32.5 C48.8,33.3 49.6,33.8 50.4,33.7 C50.6,33.7 50.9,33.7 51.1,33.7 L55.4,32.3 C55.6,32.3 55.8,32.2 56,32.1 L58.9,30.2 C59.9,29.5 60.3,28.2 59.7,27.2 L59.7,27.2 Z\\" id=\\"Shape\\"></path><path d=\\"M13.7,24.8 L10.3,23.3 C9.9,23.1 9.3,23.3 9.1,23.8 C8.9,24.3 9.1,24.9 9.6,25.1 L12.9,26.5 C13,26.6 13.2,26.6 13.3,26.6 C13.7,26.6 14,26.4 14.2,26 C14.4,25.6 14.2,25 13.7,24.8\\" id=\\"Path\\"></path><path d=\\"M13.7,28.9 L10.3,27.5 C9.9,27.2 9.3,27.5 9.1,28 C8.9,28.4 9.1,29 9.6,29.2 L12.9,30.7 C13,30.7 13.2,30.8 13.3,30.8 C13.7,30.8 14,30.5 14.2,30.2 C14.4,29.7 14.2,29.1 13.7,28.9\\" id=\\"Path\\"></path><path d=\\"M13.7,33.4 L10.3,32 C9.9,31.7 9.3,32 9.1,32.5 C8.9,32.9 9.1,33.5 9.6,33.7 L12.9,35.2 C13,35.2 13.2,35.3 13.3,35.3 C13.7,35.3 14,35 14.2,34.7 C14.4,34.2 14.2,33.6 13.7,33.4\\" id=\\"Path\\"></path><path d=\\"M13.7,37.4 L10.3,36.1 C9.9,35.9 9.3,36.1 9.1,36.5 C8.9,37 9.1,37.5 9.6,37.6 L12.9,38.9 C13,39 13.2,39 13.3,39 C13.7,39 14,38.8 14.2,38.5 C14.4,38 14.2,37.5 13.7,37.4\\" id=\\"Path\\"></path><path d=\\"M13.7,41.3 L10.3,39.8 C9.9,39.6 9.3,39.8 9.1,40.3 C8.9,40.8 9.1,41.4 9.6,41.6 L12.9,43 C13,43.1 13.2,43.1 13.3,43.1 C13.7,43.1 14,42.9 14.2,42.5 C14.4,42.1 14.2,41.5 13.7,41.3\\" id=\\"Path\\"></path></g><g id=\\"element-fire\\" transform=\\"translate(77, 217)\\" fill=\\"#6E6E6E\\"><g id=\\"Group\\" transform=\\"translate(9.8, 0.8)\\"><path d=\\"M40.7,41.5 C39.4,50.5 32.4,55.7 21.4,55.7 C9.9,55.7 3.4,50.9 2,41.5 C1.1,34.5 3.1,27 8,19.3 C10.1,22.9 12.9,25.7 16.4,27.7 C16.7,27.9 17.2,27.8 17.4,27.5 C17.7,27.2 17.8,26.8 17.6,26.5 C17.6,26.4 15.6,22.5 14.5,17.5 C13.7,14 14.8,10.5 17.3,8.1 C18.7,6.7 21.3,4.3 22.9,2.8 C23,4.7 23.7,7.5 26,9.6 C28.6,12 29.2,15.8 27.5,18.9 L27.5,19 C23,26.8 30.2,32.1 30.3,32.2 C30.6,32.4 31,32.4 31.3,32.2 C31.6,32.1 31.8,31.7 31.7,31.4 C31.7,31.3 31.2,23.5 34.7,19.5 C39.7,26.9 41.7,34.3 40.7,41.5 Z M35.5,17.8 C35.4,17.6 35.1,17.4 34.9,17.4 C34.6,17.4 34.4,17.4 34.2,17.6 C30.6,20.6 30,26.4 29.9,29.5 C28.4,27.7 26.6,24.4 29,20 L29.1,20 C31.2,16.2 30.4,11.4 27.2,8.4 C24.1,5.6 24.7,1.1 24.7,1 C24.8,0.6 24.6,0.3 24.2,0.1 C23.9,-0.1 23.5,-0 23.2,0.2 C23.2,0.3 18.2,4.8 16,6.9 C13,9.9 11.8,14 12.7,18 C13.3,20.7 14.1,23 14.7,24.6 C12.3,22.8 10.4,20.3 8.9,17.3 C8.8,17.1 8.5,16.9 8.2,16.8 C7.8,16.8 7.5,17 7.4,17.2 C1.6,25.8 -0.8,34.1 0.3,41.9 C1.7,52.3 9,57.8 21.4,57.8 C27.1,57.8 32.1,56.4 35.7,53.7 C39.4,51 41.8,46.9 42.5,42 C43.6,34 41.3,25.8 35.5,17.8 L35.5,17.8 Z\\" id=\\"Fill-15\\"></path></g><path d=\\"M34.5,26.3 C35.6,29.4 35.9,32.1 35.4,34.3 C34.8,37.6 30,43.3 30.7,45.6 C31.2,47.2 33.9,46.5 38.6,43.7 C34.6,48.6 32,51.2 30.8,51.6 C28.9,52.1 24.8,51.3 22.5,48.3 C20.2,45.3 20.6,39.1 23.3,33.4 C23.7,32.5 22.2,40.2 25,40.8 C27.8,41.4 30.2,39.2 32.2,36.7 C33.6,34.9 34.3,31.5 34.5,26.3 Z\\" id=\\"Fill-94\\" transform=\\"translate(29.8, 39) rotate(-12) translate(-29.8, -39) \\"></path></g><g id=\\"element-lightning\\" transform=\\"translate(229, 96)\\" fill=\\"#6E6E6E\\"><path d=\\"M30.8,18.9 C30.6,19.3 30.7,19.8 31.1,20.1 L39.9,25.5 L34.2,33.4 C34.1,33.6 34,33.9 34.1,34.2 C34.1,34.4 34.3,34.7 34.5,34.8 L43.5,40.2 L30.4,53.7 L35.3,42.8 C35.5,42.3 35.3,41.8 34.8,41.5 L25.2,36.8 L31.2,29 C31.4,28.8 31.4,28.5 31.4,28.3 C31.3,28 31.2,27.8 30.9,27.6 L23,22.8 L35.4,7.4 L30.8,18.9 Z M39.3,1.1 C38.9,0.8 38.3,0.9 38,1.3 L20.9,22.5 C20.7,22.8 20.6,23 20.7,23.3 C20.7,23.6 20.9,23.8 21.1,24 L29.1,28.8 L23,36.6 C22.9,36.8 22.8,37.1 22.9,37.4 C22.9,37.6 23.1,37.9 23.4,38 L33.1,42.9 L26.4,57.8 C26.2,58.2 26.3,58.7 26.7,59 C26.9,59.1 27.2,59.2 27.5,59.1 C27.6,59.1 27.8,59 28,58.8 L45.8,40.7 C46,40.5 46.1,40.2 46.1,39.9 C46.1,39.6 45.9,39.4 45.6,39.2 L36.5,33.7 L42.2,25.9 C42.3,25.7 42.4,25.4 42.3,25.1 C42.3,24.9 42.1,24.7 41.9,24.5 L33,19 L39.7,2.3 C39.9,1.8 39.7,1.3 39.3,1.1 L39.3,1.1 Z M20.8,31.3 C16,35.8 13.6,38.1 13.6,38.3 C13.6,38.4 15.8,39.8 20.3,42.5 L14.2,48.6 L16.4,43 C16.5,42.8 14.1,41.4 9.2,38.9 L20.8,31.3 Z\\" id=\\"Fill-94\\" transform=\\"translate(27.6, 30) rotate(1) translate(-27.6, -30) \\"></path><path d=\\"M46,7.1 C42.8,12.4 41.1,15 41.1,15.1 C41.1,15.2 42.3,17.2 44.6,21 C44.7,20.8 42.5,18.9 38.2,15.4 L46,7.1 Z\\" id=\\"Fill-94\\" transform=\\"translate(42.1, 14.1) rotate(-10) translate(-42.1, -14.1) \\"></path></g><g id=\\"element-water\\" transform=\\"translate(37, 96)\\" fill=\\"#6E6E6E\\"><path d=\\"M44.3,51.2 C41,54.8 36,57 31.1,57 C26.2,57 21.3,54.8 18,51.2 C15,48 13.6,44 13.9,39.9 C15.3,23.9 27.7,7.6 31.1,3.4 C34.6,7.6 47,23.9 48.3,39.9 C48.7,44 47.2,48 44.3,51.2 Z M50.6,39.6 C49.7,29.5 44.7,19.5 40.7,12.8 C36.3,5.7 32.2,1 32,0.8 C31.6,0.2 30.7,0.2 30.2,0.8 C30.1,1 26,5.7 21.6,12.8 C17.5,19.5 12.5,29.5 11.7,39.6 C11.3,44.4 12.9,49.1 16.3,52.7 C20.1,56.9 25.5,59.3 31.1,59.3 C36.7,59.3 42.1,56.9 45.9,52.7 C49.3,49.1 51,44.4 50.6,39.6 L50.6,39.6 Z\\" id=\\"Fill-73\\"></path><path d=\\"M38.4,34 C38,33.8 37.5,33.8 37.2,34.2 C36.9,34.5 37,35.1 37.4,35.3 C40.3,37.6 41.9,41.1 41.9,44.8 C41.9,49.7 38.9,54.2 34.3,55.9 C33.9,56.1 33.7,56.5 33.9,57 C34,57.3 34.3,57.5 34.6,57.5 C34.7,57.5 34.8,57.5 34.9,57.4 C40.1,55.5 43.6,50.4 43.6,44.8 C43.6,40.5 41.7,36.6 38.4,34\\" id=\\"Fill-66\\" transform=\\"translate(38.7, 45.7) rotate(37) translate(-38.7, -45.7) \\"></path></g></g></svg>');
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
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}