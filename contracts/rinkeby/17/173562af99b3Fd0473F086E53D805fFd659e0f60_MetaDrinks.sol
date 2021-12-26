// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./MetaDrinksTypes.sol";
import "./MetaDrinksSvgGenerator.sol";
import "./MetaDrinksDataGenerator.sol";
import "./MetaDrinksMetaDataGenerator.sol";

contract MetaDrinks is ERC721Enumerable, ReentrancyGuard, Ownable, MetaDrinksDataGenerator {
    // immutable configuration
    uint256 private constant TOKEN_PRICE = 0.05 ether;
    uint256 private constant MAX_TOKENS_COUNT = 7777;
    address private constant leaderAddress = 0x488eD15Ad873B34B4Ba547d00ed1b93f0fFB552C;
    address private constant engineerAddress = 0xDC745a99eaE7F20d8E8Dd9fA7e208f9A622C2B45;
    address private constant bartenderAddress = 0xa4bad3F83Ea2FC2D9A54253A007236FF8Ff8eF3A;

    // mutable configuration
    uint256 public mintStartsAtTimestamp;
    uint256 public maxTokensPerAddress;
    uint256 public maxTokensPerTransaction;
    uint256 public reservedTokensCount;

    // tokens counters
    uint256 public tokenCounter;
    mapping(address => uint256) private tokensCountPerAddress;

    // whitelist
    bool public isWhitelistActive = false;
    mapping(address => uint256) private whitelistAddressToLimit;

    constructor() ERC721("Metadrinks", "metadrinks") {
        mintStartsAtTimestamp = 0;
        maxTokensPerAddress = 20;
        maxTokensPerTransaction = 20;
        reservedTokensCount = 500;
    }

    // region ---- mutable configuration ------------------------------------------------------------
    function setMintStartsAtTimestamp(uint256 _mintStartsAtTimestamp) external onlyOwner {
        mintStartsAtTimestamp = _mintStartsAtTimestamp;
    }

    function setMaxTokens(uint256 _maxTokensPerAddress, uint256 _maxTokensPerTransaction) external onlyOwner {
        maxTokensPerAddress = _maxTokensPerAddress;
        maxTokensPerTransaction = _maxTokensPerTransaction;
    }

    function setReservedTokensCount(uint256 _reservedTokensCount) external onlyOwner {
        reservedTokensCount = _reservedTokensCount;
    }

    function setIsWhitelistActive(bool _isActive) external onlyOwner {
        isWhitelistActive = _isActive;
    }

    function updateWhitelistAddresses(address[] memory _addresses, uint256[] memory _amounts) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistAddressToLimit[_addresses[i]] = _amounts[i];
        }
    }
    // region ---- mutable configuration ------------------------------------------------------------

    // region ---- withdraw --------------------------------------------------------
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 engineerShare = (30 * balance) / 100;
        uint256 bartenderShare = (30 * balance) / 100;
        payable(engineerAddress).transfer(engineerShare);
        payable(bartenderAddress).transfer(bartenderShare);
        payable(leaderAddress).transfer(balance - engineerShare - bartenderShare);
    }

    // region ---- withdraw --------------------------------------------------------

    // region ---- mint --------------------------------------------------------
    function mint(uint256 _amount) external payable nonReentrant {
        uint256 currWhitelistAddressLimit = isWhitelistActive ? whitelistAddressToLimit[msg.sender] : 0;
        if (currWhitelistAddressLimit > 0) {
            int256 whitelistLimitDiff = int256(currWhitelistAddressLimit) - int256(_amount);
            require(whitelistLimitDiff >= 0, "Minting would exceed max supply for whitelisted address");
            whitelistAddressToLimit[msg.sender] = uint256(whitelistLimitDiff);
        } else {
            // check sale started (tested)
            require(block.timestamp >= mintStartsAtTimestamp, "Sale not started yet or paused");
        }

        // check tokens per address (tested)
        uint256 newAddressTokensCount = tokensCountPerAddress[msg.sender] + _amount;
        require(newAddressTokensCount <= maxTokensPerAddress, "Too many tokens per address");

        // check tokens per transaction (tested)
        require(_amount <= maxTokensPerTransaction, "Too many tokens per transaction");

        // check ethers value (tested)
        require(msg.value >= _amount * TOKEN_PRICE, "Wrong ether value");

        // remember new tokens count for the address
        tokensCountPerAddress[msg.sender] = newAddressTokensCount;

        // mint tokens
        mintTokensInternal(msg.sender, _amount);
    }

    function airdrop(address[] memory _addresses, uint256[] memory _amounts) external nonReentrant onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintTokensInternal(_addresses[i], _amounts[i]);
        }
    }

    function mintTokensInternal(address _toAddress, uint256 _amount) internal {
        // checks amount not zero (tested)
        require(_amount > 0, "Must mint at least one token");

        // checks tokens limit plus amount not reached (tested)
        require(tokenCounter + _amount + reservedTokensCount <= MAX_TOKENS_COUNT, "Minting would exceed max supply");

        // mint tokens
        for (uint256 i = 0; i < _amount; i++) {
            mintTokenInternal(_toAddress);
        }
    }

    function mintTokenInternal(address _toAddress) internal {
        // inc the counter
        tokenCounter++;

        // mint
        _safeMint(_toAddress, tokenCounter);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "Token not minted");
        MetaDrinksTypes.Drink memory drink = genDrink(_tokenId);
        return MetaDrinksMetaDataGenerator.genJsonTokenURI(drink, MetaDrinksSvgGenerator.genSvg(drink));
    }

    // region ---- mint --------------------------------------------------------
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

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

library MetaDrinksTypes {
    struct Drink {
        string symbol;
        string nameA;
        string nameB;
        string nameC;
        string alcoBase;
        string alcoBasePostfix;
        string bitterSweet;
        string sourPart;
        bool hasFruitOrHerb;
        string fruitOrHerb;
        string dressing;
        string dressingPostfix;
        string method;
        string glass;
        bool hasGlassPostfix;
        string glassPostfix;
        bool hasTopUp;
        string topUp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaDrinksTypes.sol";
import "./MetaDrinksUtils.sol";

library MetaDrinksSvgGenerator {
    function genSvg(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<svg viewBox="0 0 800 800" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg" font-family="Courier New" font-size="71" fill="#FFF"><style>.t{font-size:42px;}.s{fill:#000;}</style><path fill="#000" d="M0 0h800v800H0z"/><g text-anchor="end" transform="translate(-30)">',
                genDrinkName(_drink),
                '<text x="100%" y="752">[', _drink.symbol, ']</text></g><g transform="translate(30 288)">',
                genDrinkComposition(_drink),
                '</g></svg>'
            ));
    }

    function genDrinkName(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        uint256 nameWidthA = MetaDrinksUtils.len(_drink.nameA) * 43;
        uint256 nameWidthB = MetaDrinksUtils.len(_drink.nameB) * 43;
        uint256 nameWidthC = MetaDrinksUtils.len(_drink.nameC) * 43;

        // all in one line
        if (nameWidthA + nameWidthB + nameWidthC + 43 * 2 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">',
                    MetaDrinksUtils.upper(_drink.nameA),
                    " ",
                    MetaDrinksUtils.upper(_drink.nameB),
                    " ",
                    MetaDrinksUtils.upper(_drink.nameC),
                    "</text>"
                ));
        }

        // first two in one line
        if (nameWidthA + nameWidthB + 43 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), " ", MetaDrinksUtils.upper(_drink.nameB), "</text>",
                    '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameC), "</text>"
                ));
        }

        // second two in one line
        if (nameWidthB + nameWidthC + 43 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), "</text>",
                    '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameB), " ", MetaDrinksUtils.upper(_drink.nameC), "</text>"
                ));
        }

        // only first two in two lines, third one dropped
        return string(abi.encodePacked(
                '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), "</text>",
                '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameB), "</text>"
            ));
    }

    function genDrinkComposition(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory result) {
        // first 3 items are always present
        uint8 index = 3;
        result = string(abi.encodePacked(
                genSvgHighlightedText(0, _drink.alcoBase, _drink.alcoBasePostfix),
                genSvgHighlightedText(1, _drink.bitterSweet, "1 ual"),
                genSvgHighlightedText(2, _drink.sourPart, "1 ual")
            ));

        // maybe add fruit or herb
        if (_drink.hasFruitOrHerb) {
            result = string(abi.encodePacked(result, genSvgHighlightedText(index++, _drink.fruitOrHerb, "mzttio")));
        }

        // specie or appetizer is always present
        result = string(abi.encodePacked(result, genSvgHighlightedText(index++, _drink.dressing, _drink.dressingPostfix)));

        // maybe add method (depends on fruit or herb)
        if (!_drink.hasFruitOrHerb) {
            result = string(abi.encodePacked(result, genSvgText(index++, _drink.method)));
        }

        // glass is always present
        string memory glassText = _drink.hasGlassPostfix
        ? genSvgHighlightedText(index++, _drink.glass, _drink.glassPostfix)
        : genSvgText(index++, _drink.glass);
        result = string(abi.encodePacked(result, glassText));

        // maybe add top up
        if (_drink.hasTopUp) {
            result = string(abi.encodePacked(result, genSvgHighlightedText(index, _drink.topUp, "htl mc")));
        }
    }

    function genSvgText(uint256 _index, string memory _text) internal pure returns (string memory) {
        return string(abi.encodePacked('<text y="', MetaDrinksUtils.uint2str(_index * 58), '" class="t">', _text, "</text>"));
    }

    function genSvgHighlightedText(uint256 _index, string memory _text, string memory _highlightedText) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<rect y="', calcHighlightRectY(_index), '" x="', MetaDrinksUtils.uint2str(uint256((MetaDrinksUtils.len(_text) + 1) * 2522 / 100) - 10), '" width="', MetaDrinksUtils.uint2str(uint256(MetaDrinksUtils.len(_highlightedText) * 2522 / 100) + 20), '" height="48px"/>',
                '<text y="', MetaDrinksUtils.uint2str(_index * 58), '" class="t">', _text, ' <tspan class="t s">', _highlightedText, "</tspan></text>"
            ));
    }

    function calcHighlightRectY(uint256 _index) internal pure returns (string memory) {
        uint256 textY = _index * 58;
        return textY >= 36
        ? MetaDrinksUtils.uint2str(textY - 36)
        : string(abi.encodePacked("-", MetaDrinksUtils.uint2str(36 - textY)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaDrinksTypes.sol";
import "./MetaDrinksUtils.sol";

contract MetaDrinksDataGenerator {
    // names
    string[100] internal namesListA = ["thjnZ4pI", "PQUpl", "jGlK", "3w0kX", "4qE9", "CH1H9BY", "42oYmMdY", "iAbm", "VxBAVg", "yoYB", "dzLTrgCK", "nT22", "aiv", "uKmmiO", "P65h3", "qqwICW", "rgCCcb", "f7StlU3", "0VvHFq", "DxEaT", "fkKDvi", "r6CWOR", "7ve6yOw", "US2iv", "bEZy", "WpGS5", "VhMiid0", "rvwyieB", "OZUXzX", "r5FqSNx", "jKKP", "ZIOLHa7", "grhzX", "LtRmCmnw", "ja8LFRP", "JidMkbSC", "BM6wsSfY", "bSHH7QQ3", "k28nULv5", "ys9e15cO", "xhtlJ4", "1j6tll9", "NGLpE", "k7LUVau", "aOAtvK9A", "eBDeW", "y2JEv", "cx760a", "tbhO8z", "VdaJZxL", "Vxj1ww", "ItER2y", "oCKrEVi", "BfkAvxW", "nDjs", "VZqmG", "3150b", "oa798yR", "EuXANj", "6bn5do", "WUEe", "xWC8p", "BazLkLp", "7Ysw", "ZgFGEM", "WfQP7N25", "TWu0", "xLlad", "9PxCT8n", "WJi05", "QiTJ", "6vIVK", "SL1vm", "isVDFZ", "dNxB", "fq4", "5Kcf2M", "sv8p", "X1qAIQH", "SqQHm8sG", "E4gpREWw", "wBPSvq", "KPVxj7C1", "rQ9dNm", "8gS68HJD", "T8IhkUoJ", "PTj6", "rQWWL", "ExKgK2r", "MLfB8", "mug0pAB", "dsAepD", "Dn0JOmuC", "VsVxxJA", "xRGNEXF", "kGhc", "hQ8ALJc", "k3Yeh8H", "sJTOO4u", "ez4h7l5"];
    string[100] internal namesListB = ["tF248WV", "3NCm2dQ", "Z6qvRA", "Pkh7", "akwz", "4ByS", "5tfD4", "yGkPTOM", "jpOjo5l", "wN7yD", "R6yEIec", "7KX4r", "y3Ui5F9", "ZssHM", "iHdgzn", "SscPkuLn", "V6kvur", "2F3", "Dw", "NQeUu", "ogBzXTm", "GWelfI", "7ogX", "Xjoow8s", "cqZez3wF", "itfzfIU", "J6Rq7dW", "FkNg91M", "4Xvk", "ZEEIES", "z2O479L", "BYux1hq", "djhOo3k", "1jQoQ0yB", "k7jWA", "6BvK8ZA", "o5M6", "p7vZmM", "uVBgE", "YTn3lwRx", "DbaW", "yWd", "6udaTmPI", "iww3Mylz", "XvZrX", "yY2hV", "ln7rs3Sl", "X7sIOD", "adXwvLl", "yEKRKSF", "bXxia0", "5qeMSLLc", "eyxJ5", "w6NbZ", "S6pk6b", "N0o", "GtfvMtp", "NiFs", "AGbuIz9", "dqbMvH", "HnvX3pI", "oPV74H", "mbng", "GSKLqyQ", "LImoGLk9", "mAV6", "PnjrRC", "hYWO3", "rtgd0rch", "ir6B", "bFBW61O", "VqwYhUc", "n2oWUOn", "hrq3V", "1SBI892", "K8EPzUp", "UhOKq", "eJWgot", "mBF7L", "QlNkL", "YokAp", "tchg4y", "aUGJW", "tQI6Bbu", "sKmX", "7fuPLU", "aTh0AK2R", "PmwFNt", "X7foSdkS", "QtVxhu2P", "WCjPCldJ", "eb7w465", "qoRr9", "apvcB", "wBwW3C8d", "jiHa2", "kMd4b25b", "QjHxOFv", "2Hr3Ele2", "WQ1TIFX"];
    string[100] internal namesListC = ["NcwKtr", "yE4U", "1Tm", "C6Ez", "llx", "6KeI7", "qaOdP", "Spv9dhD", "y2qIUne", "uNrP", "QoYV0a", "wbHqRz", "acyxiC9", "zSuKTC", "SrAocZa", "syl1TsHl", "HUHrNgaG", "46MrlHg", "TQCgZf5k", "iL6I7ZJ", "ft4Uhf", "nFLDzvQ", "b17Ri3", "Qx4O0N", "I9Dl4", "3fHHdD", "wVtddU", "QfbdB", "8XPm", "gDjXwhY", "gEFNoG", "NHV", "7Ri7zIj", "MOzvwnxG", "o3oXJOs", "FxmYMg", "VwS", "4KieB", "8zw4vYOr", "UOUxwqA", "Ntq3PB2", "ho3Xz", "nV4j", "HuXEUD", "zZjTU3K9", "e6rUNmk", "ddtvosfC", "2cBDEok", "K4Fg", "E2YD8x", "pDGT", "m70i141E", "3g", "9Htivzb", "lrIr", "GwM6cKT", "wKgfB", "gGPpbicT", "PFgfhX", "zoN", "LiV", "iXAUl", "32fm76", "76r", "v4OGP", "w0uaW", "nhFJWXv", "77m8VVB", "wrqSNcm1", "FalF825", "pSmjMO", "xGDPW", "IB9f", "nRPA14a", "T6LA", "8dUHu3oU", "t222h5", "TUpr", "aAHPU", "Dx1t", "dWywf", "hLiCz", "OfLF0", "UvlJ8gWe", "2gWn", "Dbw8", "ftEpst86", "7nNO3WxU", "p0S9qK3", "VWM", "Gu9E", "SCZf", "xmt3gH", "wZWE", "pO60gF", "8FGQrYS", "lKRajYO", "vwl7Gvv", "Hj2gBpK", "8DeYO7o0"];

    // alco base
    string[20] internal alcoBasesList = ["1PUZeSnXgQbUXsLxaT", "4NZQ9sbd", "4ZVGWN", "C9RZf", "IKpkcIK4J", "INCsRD4", "KGeINKM", "LVEXq8Mlt", "Ow5y9FbrhG", "Qu1MXBDjdJmVYPjuC1zn5", "UkzD", "V1Am4n", "VAY", "VS2a4K", "Vnkf5Ewn", "e0a", "oTB7rCq", "odRYvR", "ouPwyA", "sgomdOX"];

    // bitter sweets
    string[17] internal bitterSweetsList = ["0qkolu6o", "7n3UrmoHPXeD8F", "84pNqDNqczAmMk8", "8plG", "DBQvevjt2tSpENx9p", "F1mxjHN29FADIA", "FzOxHdJ9lJkb9kQ", "JuDvxCpRzj3", "MXkxc", "TeemVsaVLLMuq9", "UVCoY5zEG8De3", "Z7M2F5", "ZFH5HdEcbkTNnOrOnWT1h", "fIqHqghUzO5YER", "hExV1ikVgm3h47NYSE", "iQYFMolX", "xXuPj3mZXkhasU"];

    // sour parts
    string[17] internal sourPartsList = ["H02r4C2NDVgJjRm", "LDNfEpVqj7acMAbu", "OaFJ1P72NTl79nfd", "PG3cPRpFKok8X0wt5", "Qk2CJHAzKCLlIWI", "TuuHE4pVl0", "U1T7jNHr7F", "XWA0z8ewGOU7brL", "Z3Pxn7GFr", "Ze7oVYrRpyo", "fe51XfihwRfUY", "mRbKvo1E6lT7Dmw", "uKdFFJ58t5", "uUpyJ94Y5Jj", "viJxgU1uO6170tojlT", "wv8hIbmeXR5m7B", "zeMoE9"];

    // fruits and herbs
    string[15] internal fruitsAndHerbs = ["2LLtYwZVq", "2fgXQUgatvisRe", "73xXRcmuq", "AhbNJwbEq0D", "K74jLBqR7", "MJdSp7cGXyJAVn", "XHvto4raXLneL3", "dLexuPpFH7", "kEkAY82XrP", "mhXeDscYgFgq1", "oQh3eEaq5l", "pEX5IoeQzIR2", "s9mfpgXRgU9j7pm", "u61LmZw33hF", "uzSl3xpdLB3K80ueG"];

    // dressings
    string[18] internal dressingsList = ["0NDmPzfqf", "1enZL1NutsDb", "3AitD2pC", "3RNU7mnESWOKTlsrTkuf", "6uPTqBr", "98OkNvVovuezIu", "EjyDGWsZ1ilU", "KwoTq0ZUKuVg", "S8fnarWI", "UARFJBF8Bg4C", "WrVEJYGT1e8VVXWc", "eNVdbh", "hmxPtN5eOnkpwd", "ks9gmFkAg", "mjLrN0m", "oROju7hDlq2a", "pr0z8YODnOtcdo2kgUSG", "rfUD4vN"];
    uint256[] internal dressingsPinchPostfix;

    // methods
    string[4] internal methodsList = ["0ogJi", "9KlX", "JdSJS", "Ul5rzSJBB2xf2jHGnXoh"];

    // glasses
    string[16] internal glassesList = ["4CdANVJ1", "6wQav1OIPgvN", "9Y8H1iRPA", "A443NJW", "WUFB", "WY5s", "Yiw", "cEgrA7mRFoGYv", "f43o8740", "fZqyGI26vM", "hl8X9yRWL", "joYiy9B", "lY3P", "nxTMme", "y48ObveR", "ynTTIC"];
    uint256[] internal glassesCupsList;
    uint256[] internal glassesMugsList;
    uint256[] internal glassesIceCubesList;
    uint256[] internal glassesCrushedIceList;
    uint256[] internal glassesBlocksTopUps;

    // top ups
    string[17] internal topUpsList = ["0ofbGJcc", "3mnT9gnGW", "5OhobeM8l6U", "6FV3Psco9l4vs", "8GgfZ3qbIhZQ", "8r2aDTvkE7pQJqm", "CHw2", "EtRmV", "Fk9YL2k", "KMRPX", "O88uVhevw", "abwyUsSBWe", "fMrPANeE7KMa", "hMjZX", "jrnpzGCF", "njBx", "sZVzquvB6RpuG"];

    constructor() {
        // dressings
        dressingsPinchPostfix = [1, 2, 3, 4, 5, 16];

        // glasses
        glassesCupsList = [1, 11];
        glassesMugsList = [0, 12];
        glassesIceCubesList = [0, 1, 3, 5, 9, 10];
        glassesCrushedIceList = [2, 4, 6, 11, 12, 13, 14, 15];
        glassesBlocksTopUps = [7, 8, 9];
    }

    function genDrink(uint256 _tokenId) internal view returns (MetaDrinksTypes.Drink memory) {
        uint256 alcoBasePartsCount = genAlcoBasePart(_tokenId);
        uint256 fruitOrHerbRandomness = MetaDrinksUtils.reRollRandomness(_tokenId, "fh");
        uint256 dressingIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "dr") % dressingsList.length;
        uint256 glassIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "gl") % glassesList.length;
        string memory glassPostfix = genGlassPostfix(glassIndex);
        string[] memory names = genNames(_tokenId);
        return MetaDrinksTypes.Drink(
            genSymbol(alcoBasePartsCount),
            names[0],
            names[1],
            names[2],
            alcoBasesList[MetaDrinksUtils.reRollRandomness(_tokenId, "ab") % alcoBasesList.length],
            string(abi.encodePacked(MetaDrinksUtils.uint2str(alcoBasePartsCount), alcoBasePartsCount == 1 ? " ual" : " uals")),
            bitterSweetsList[MetaDrinksUtils.reRollRandomness(_tokenId, "bs") % bitterSweetsList.length],
            sourPartsList[MetaDrinksUtils.reRollRandomness(_tokenId, "sp") % sourPartsList.length],
            fruitOrHerbRandomness % 100 < 75,
            fruitsAndHerbs[fruitOrHerbRandomness % fruitsAndHerbs.length],
            dressingsList[dressingIndex],
            MetaDrinksUtils.isUintArrayContains(dressingsPinchPostfix, dressingIndex) ? "sltsd" : "hnat",
            methodsList[MetaDrinksUtils.reRollRandomness(_tokenId, "me") % methodsList.length],
            genGlass(glassIndex),
            bytes(glassPostfix).length != 0,
            glassPostfix,
            !MetaDrinksUtils.isUintArrayContains(glassesBlocksTopUps, glassIndex),
            topUpsList[MetaDrinksUtils.reRollRandomness(_tokenId, "tu") % topUpsList.length]
        );
    }

    function genNames(uint256 _tokenId) internal view returns (string[] memory result) {
        uint256 randIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "n") % 100;
        uint256 slowIndex = 100 - 1 - (_tokenId + uint256(_tokenId / 100)) % 100;
        uint256 fastIndex = _tokenId % 100;
        result = new string[](3);
        result[0] = namesListA[randIndex];
        result[1] = namesListB[slowIndex];
        result[2] = namesListC[fastIndex];
    }

    function genAlcoBasePart(uint256 _tokenId) internal pure returns (uint256) {
        uint256 prob = MetaDrinksUtils.reRollRandomness(_tokenId, "abp") % 10;
        // 10%
        if (prob == 0) return 0;
        // 20%
        if (prob < 3) return 1;
        // 40%
        if (prob < 7) return 2;
        // 30%
        return 3;
    }

    function genGlass(uint256 _glassIndex) internal view returns (string memory) {
        string memory glass = glassesList[_glassIndex];
        string memory glassTypePostfix;
        if (MetaDrinksUtils.isUintArrayContains(glassesCupsList, _glassIndex)) {
            glassTypePostfix = "lst";
        }
        if (MetaDrinksUtils.isUintArrayContains(glassesMugsList, _glassIndex)) {
            glassTypePostfix = "bsm";
        } else {
            glassTypePostfix = "ltsdrt";
        }
        return string(abi.encodePacked(glass, " ", glassTypePostfix));
    }

    function genGlassPostfix(uint256 _glassIndex) internal view returns (string memory) {
        if (MetaDrinksUtils.isUintArrayContains(glassesIceCubesList, _glassIndex)) {
            return "ysw mbcky";
        }
        if (MetaDrinksUtils.isUintArrayContains(glassesCrushedIceList, _glassIndex)) {
            return "smhjuyld ysw";
        }
        return "";
    }

    function genSymbol(uint256 _partsCount) internal pure returns (string memory) {
        if (_partsCount == 0) return "0";
        if (_partsCount == 1) return "1";
        if (_partsCount == 2) return "2";
        return "3";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./MetaDrinksTypes.sol";

library MetaDrinksMetaDataGenerator {
    function genJsonTokenURI(MetaDrinksTypes.Drink memory _drink, string memory _drinkSvg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
                "{",
                '"name":"', string(abi.encodePacked(_drink.nameA, " ", _drink.nameB, " ", _drink.nameC)), '",',
                '"description": "The genesis collection of 7777 Metadrinks with two generatives within each of them. A singular mantra in the title which sends you to a headspace and a unique random how-to. Ownership and commercial usage rights are given to you, the Metadrinker, over your [%]. Feel free to use it any way you want. [metadrinks.io](https://metadrinks.io/)",',
                '"image":"', genSvgImageURI(_drinkSvg), '",',
                '"attributes":', genAttributes(_drink),
                "}"
            ))))));
    }

    function genSvgImageURI(string memory _svg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(string(abi.encodePacked(_svg))))));
    }

    function genAttributes(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '[',
                genStrAttr("Alco Base", genStrValue(_drink.alcoBase, _drink.alcoBasePostfix), true),
                genStrAttr("Bittersweet Part", genStrValue(_drink.bitterSweet, "1 ual"), true),
                genStrAttr("Sour Part", genStrValue(_drink.sourPart, "1 ual"), true),
                _drink.hasFruitOrHerb ? genStrAttr("Fruit or Herb", genStrValue(_drink.fruitOrHerb, "mzttio"), true) : "",
                genStrAttr("Dressing", genStrValue(_drink.dressing, _drink.dressingPostfix), true),
                !_drink.hasFruitOrHerb ? genStrAttr("Method", _drink.method, true) : "",
                genStrAttr("Glass", _drink.hasGlassPostfix ? genStrValue(_drink.glass, _drink.glassPostfix) : _drink.glass, true),
                _drink.hasTopUp ? genStrAttr("Top Up", genStrValue(_drink.topUp, "htl mc"), true) : "",
                genStrAttr("Symbol", _drink.symbol, false),
                ']'
            ));
    }

    function genStrAttr(string memory _type, string memory _value, bool withComma) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '{',
                '"trait_type":"', _type, '",',
                '"value":"', _value, '"',
                withComma ? '},' : '}'
            ));
    }

    function genStrValue(string memory _part1, string memory _part2) internal pure returns (string memory) {
        return string(abi.encodePacked(_part1, " ", _part2));
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

pragma solidity ^0.8.0;

library MetaDrinksUtils {
    function concatLists(uint256[] memory _list1, uint256[] memory _list2) internal pure returns (uint256[] memory result) {
        result = new uint256[](_list1.length + _list2.length);

        uint i = 0;
        for (; i < _list1.length; i++) {
            result[i] = _list1[i];
        }

        uint j = 0;
        while (j < _list2.length) {
            result[i++] = _list2[j++];
        }
    }

    function excludeFromList(string[] storage _list, uint256[] memory _exclude) internal view returns (string[] memory result) {
        uint256 curr = 0;
        result = new string[](_list.length);
        for (uint256 i = 0; i < _list.length; i++) {
            string memory value = _list[i];
            if (!isUintArrayContains(_exclude, i)) {
                result[curr++] = value;
            }
        }
    }

    function getExcludedArrayLen(string[] memory _list) internal pure returns (uint256) {
        uint256 l = 0;
        for (uint256 i = 0; i < _list.length; i++) {
            if (bytes(_list[i]).length == 0) {
                return l;
            }
            l++;
        }
        return l;
    }

    function isUintArrayContains(uint256[] memory _arr, uint256 _value) internal pure returns (bool) {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_value == _arr[i]) {
                return true;
            }
        }
        return false;
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 _len;
        while (j != 0) {
            _len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(_len);
        uint256 k = _len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function len(string memory _base) internal pure returns (uint256 l) {
        l = 0;
        uint256 baseLen = bytes(_base).length;
        uint256 ptr;
        assembly {
            ptr := add(_base, 0x20)
        }
        ptr = ptr - 31;
        uint256 end = ptr + baseLen;
        for (; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upperLetter(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _upperLetter(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }
        return _b1;
    }

    function reRollRandomness(uint256 _randomness, string memory _input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(uint2str(_randomness), _input)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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
}