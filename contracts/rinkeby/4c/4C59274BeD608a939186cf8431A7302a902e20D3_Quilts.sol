//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuiltGenerator.sol";

contract Quilts is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 4000;
    uint256 public constant PRICE = 0.025 ether;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public tokensMinted;
    bool public isSaleActive = false;

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        QuiltGenerator.QuiltStruct memory quilt;
        string memory svg;
        (quilt, svg) = QuiltGenerator.getQuiltForSeed(
            Strings.toString(tokenId)
        );

        string[10] memory colorNames = [
            "Pink panther",
            "Cherry blossom",
            "Desert",
            "Forest",
            "Mushroom",
            "Mint tea",
            "Fairy grove",
            "Pumpkin",
            "Twilight",
            "Black & white"
        ];

        string[15] memory patchNames = [
            "Quilty",
            "2",
            "Flow",
            "4",
            "Sunbeam",
            "Spires",
            "Division",
            "Crashing waves",
            "Equilibrium",
            "Ichimatsu",
            "Highlands",
            "Log cabin",
            "Maiz",
            "Flying geese",
            "Pinwheel"
        ];

        string[4] memory backgroundNames = [
            "Dusty",
            "Flags",
            "Electric",
            "Pool waves"
        ];

        string[4] memory smoothnessNames = [
            "Chill",
            "Wavey",
            "Real wavey",
            "Super wavey"
        ];

        string memory patches;
        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                patches = string(
                    abi.encodePacked(
                        patches,
                        '"',
                        patchNames[quilt.patches[col][row]],
                        '"',
                        col == quilt.patchXCount - 1 &&
                            row == quilt.patchYCount - 1
                            ? ""
                            : ","
                    )
                );
            }
        }

        string memory traits = string(
            abi.encodePacked(
                '[{"trait_type":"Background","value":"',
                backgroundNames[quilt.backgroundIndex],
                '"},{"trait_type":"Animated background","value":"',
                quilt.animatedBg ? "true" : "false",
                '"},{"trait_type":"Theme","value":"',
                colorNames[quilt.themeIndex],
                '"},{"trait_type":"Background theme","value":"',
                colorNames[quilt.backgroundThemeIndex],
                '"},{"trait_type":"Patches","value":[',
                patches,
                ']},{"trait_type":"Patch count","value":',
                Strings.toString(quilt.patchXCount * quilt.patchYCount),
                '},{"trait_type":"Aspect ratio","value":"'
            )
        );

        traits = string(
            abi.encodePacked(
                traits,
                Strings.toString(quilt.patchXCount),
                ":",
                Strings.toString(quilt.patchYCount),
                '"},{"trait_type":"Smoothness","value":"',
                smoothnessNames[quilt.smoothnessFactor - 1],
                '"},{"trait_type":"Hovers","value":"',
                quilt.hovers ? "true" : "false",
                '"},{"trait_type":"Roundness","value":',
                Strings.toString(quilt.roundness),
                "}]"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Quilt #',
                        Strings.toString(tokenId),
                        '","description":"Quilts are randomly generated and stored on-chain. Get one for yourself and stay cosy.","attributes":',
                        traits,
                        ',"image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim(uint256 numTokens) public payable virtual {
        if (_msgSender() != owner()) {
            require(isSaleActive, "Sale not active");
        }
        require(totalSupply() < MAX_SUPPLY, "All quilts minted");
        require(
            totalSupply() + numTokens <= MAX_SUPPLY,
            "Minting exceeds max supply"
        );
        require(numTokens <= MAX_PER_TX, "Mint fewer quilts");
        require(numTokens > 0, "Must mint at least 1 quilt");
        require(PRICE * numTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokensMinted + 1;
            _safeMint(_msgSender(), tokenId);
            tokensMinted += 1;
        }
    }

    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdrawAll() public payable nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    constructor() ERC721("Quilts", "QUILTS") {}
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library QuiltGenerator {
    struct QuiltStruct {
        uint256[5][5] patches;
        uint256 quiltX;
        uint256 quiltY;
        uint256 quiltW;
        uint256 quiltH;
        uint256 xOff;
        uint256 yOff;
        uint256 maxX;
        uint256 maxY;
        uint256 patchXCount;
        uint256 patchYCount;
        uint256 roundness;
        uint256 themeIndex;
        uint256 backgroundIndex;
        uint256 backgroundThemeIndex;
        uint256 smoothnessFactor;
        bool hovers;
        bool animatedBg;
    }

    struct RandValues {
        uint256 x;
        uint256 y;
        uint256 roundness;
        uint256 theme;
        uint256 bg;
        uint256 sf;
    }

    function getQuiltForSeed(string memory seed)
        external
        pure
        returns (QuiltStruct memory, string memory)
    {
        QuiltStruct memory quilt;
        RandValues memory rand;

        rand.x = random(seed, "X") % 100;
        rand.y = random(seed, "Y") % 100;

        quilt.patchXCount = 3;
        if (rand.x < 1) {
            quilt.patchXCount = 1;
        } else if (rand.x >= 1 && rand.x < 10) {
            quilt.patchXCount = 2;
        } else if (rand.x >= 60 && rand.x < 90) {
            quilt.patchXCount = 4;
        } else if (rand.x >= 90) {
            quilt.patchXCount = 5;
        }

        quilt.patchYCount = 3;
        if (quilt.patchXCount == 1) {
            quilt.patchYCount = 1;
        } else if (rand.y >= 1 && rand.y < 10) {
            quilt.patchYCount = 2;
        } else if (rand.y >= 60 && rand.y < 90) {
            quilt.patchYCount = 4;
        } else if (rand.y >= 90) {
            quilt.patchYCount = 5;
        }

        if (quilt.patchXCount == 2 && quilt.patchYCount == 5) {
            quilt.patchXCount = 3;
        }
        if (quilt.patchYCount == 2 && quilt.patchXCount == 5) {
            quilt.patchYCount = 3;
        }

        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                quilt.patches[col][row] =
                    random(seed, string(abi.encodePacked("P", col, row))) %
                    15;
            }
        }

        quilt.maxX = 64 * quilt.patchXCount + (quilt.patchXCount - 1) * 4;
        quilt.maxY = 64 * quilt.patchYCount + (quilt.patchYCount - 1) * 4;
        quilt.xOff = (500 - quilt.maxX) / 2;
        quilt.yOff = (500 - quilt.maxY) / 2;
        quilt.quiltW = quilt.maxX + 32;
        quilt.quiltH = quilt.maxY + 32;
        quilt.quiltX = quilt.xOff + 0 - 16;
        quilt.quiltY = quilt.yOff + 0 - 16;

        rand.roundness = random(seed, "R") % 100;
        quilt.roundness = 8;
        if (rand.roundness >= 70 && rand.roundness < 90) {
            quilt.roundness = 16;
        } else if (rand.roundness >= 90) {
            quilt.roundness = 0;
        }

        rand.theme = random(seed, "T") % 1000;
        quilt.themeIndex = 0;
        if (rand.theme >= 115 && rand.theme < 230) {
            quilt.themeIndex = 1;
        } else if (rand.theme >= 230 && rand.theme < 345) {
            quilt.themeIndex = 2;
        } else if (rand.theme >= 345 && rand.theme < 460) {
            quilt.themeIndex = 3;
        } else if (rand.theme >= 460 && rand.theme < 575) {
            quilt.themeIndex = 4;
        } else if (rand.theme >= 575 && rand.theme < 690) {
            quilt.themeIndex = 5;
        } else if (rand.theme >= 690 && rand.theme < 805) {
            quilt.themeIndex = 6;
        } else if (rand.theme >= 805 && rand.theme < 930) {
            quilt.themeIndex = 7;
        } else if (rand.theme >= 930 && rand.theme < 990) {
            quilt.themeIndex = 8;
        } else if (rand.theme >= 990) {
            quilt.themeIndex = 9;
        }

        quilt.backgroundThemeIndex = random(seed, "SBGT") % 100 > 33
            ? random(seed, "SBGT") % 10
            : quilt.themeIndex;

        rand.bg = random(seed, "BG") % 100;
        quilt.backgroundIndex = 0;
        if (rand.bg >= 70 && rand.bg < 80) {
            quilt.backgroundIndex = 1;
        } else if (rand.bg >= 80 && rand.bg < 90) {
            quilt.backgroundIndex = 2;
        } else if (rand.bg >= 90) {
            quilt.backgroundIndex = 3;
        }

        rand.sf = random(seed, "TF") % 100;
        quilt.smoothnessFactor = 1;
        if (rand.sf >= 50 && rand.sf < 70) {
            quilt.smoothnessFactor = 2;
        } else if (rand.sf >= 70 && rand.sf < 90) {
            quilt.smoothnessFactor = 3;
        } else if (rand.sf >= 95) {
            quilt.smoothnessFactor = 4;
        }

        quilt.hovers = random(seed, "H") % 100 > 90;
        quilt.animatedBg = random(seed, "ABG") % 100 > 70;

        string[4][10] memory colors = [
            ["#5c457b", "#ff8fa4", "#f9bdbd", "#fbced6"],
            ["#006d77", "#ffafcc", "#ffe5ef", "#bde0fe"],
            ["#3d405b", "#f2cc8f", "#e07a5f", "#f4f1de"],
            ["#333d29", "#656d4a", "#dda15e", "#c2c5aa"],
            ["#6d2e46", "#d5b9b2", "#a26769", "#ece2d0"],
            ["#006d77", "#83c5be", "#ffddd2", "#edf6f9"],
            ["#351f39", "#726a95", "#719fb0", "#a0c1b8"],
            ["#472e2a", "#e78a46", "#fac459", "#fde3ae"],
            ["#0d1b2a", "#2f4865", "#7b88a7", "#b4c0d0"],
            ["#222222", "#eeeeee", "#bbbbbb", "#eeeeee"]
        ];

        string[15] memory patches = [
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h64v32H0z"/><path fill="url(#c2)" d="M0 32 16 0v32H0Zm16 0L32 0v32H16Zm16 0L48 0v32H32Zm16 0L64 0v32H48Z"/><circle cx="16" cy="48" r="4" fill="url(#c1)"/><circle cx="48" cy="48" r="4" fill="url(#c1)"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M32 0h32v64H32z"/><path fill="url(#c3)" d="M0 64 64 0v64H0Z"/><circle cx="46" cy="46" r="10" fill="url(#c2)"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="m52 16 8-16h16l-8 16v16l8 16v16H60V48l-8-16V16Zm-64 0 8-16h16L4 16v16l8 16v16H-4V48l-8-16V16Z"/><path fill="url(#c3)" d="m4 16 8-16h16l-8 16v16l8 16v16H12V48L4 32V16Zm32 0 8-16h16l-8 16v16l8 16v16H44V48l-8-16V16Z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 60h64v8H0zm0-16h64v8H0zm0-16h64v8H0zm0-16h64v8H0zM0-4h64v8H0z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M16 0H8L0 8v8L16 0Zm16 0h-8L0 24v8L32 0Zm16 0h-8L0 40v8L48 0Zm16 0h-8L0 56v8L64 0Zm0 16V8L8 64h8l48-48Zm0 16v-8L24 64h8l32-32Zm0 16v-8L40 64h8l16-16Zm0 16v-8l-8 8h8Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 64 32 0v64H0Zm32 0L64 0v64H32Z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 64 64 0v64H0Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 16V0h64L48 16V0L32 16V0L16 16V0L0 16Z"/><path fill="url(#c2)" d="M0 48V32h64L48 48V32L32 48V32L16 48V32L0 48Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h48v48H0z"/><path fill="url(#c2)" d="M0 48 48 0v48H0Z"/><circle cx="23" cy="25" r="8" fill="url(#c3)"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M0 0h32v32H0zm32 32h32v32H32z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M16 0 0 16v16l16-16 16 16 16-16 16 16V16L48 0 32 16 16 0Zm0 32L0 48v16l16-16 16 16 16-16 16 16V48L48 32 32 48 16 32Z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="M8 8h40v8H8z"/><path fill="url(#c2)" d="M24 32h8v8h-8zm8-8h8v8h-8z"/><path fill="url(#c1)" d="M24 24h8v8h-8zm8 8h8v8h-8zM16 48h40v8H16z"/><path fill="url(#c2)" d="M8 16h8v40H8zm40-8h8v40h-8z"/>',
            '<path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c1)" d="m24 4 8 8-8 8V4Zm0 40 8 8-8 8V44Zm-4-20-8 8-8-8h16Zm40 0-8 8-8-8h16ZM40 4l-8 8 8 8V4Zm0 40-8 8 8 8V44Zm-20-4-8-8-8 8h16Zm40 0-8-8-8 8h16Z"/><path fill="url(#c2)" d="M24 24h16v16H24z"/>',
            '<path fill="url(#c1)" d="M0 0h64v64H0z"/><path fill="url(#c2)" d="m32 0 16 16-16 16V0Zm0 64L16 48l16-16v32ZM48 0l16 16-16 16V0ZM16 64 .0000014 48 16 32v32Z"/><path fill="url(#c3)" d="M0 16 16 2e-7 32 16H0Zm64 32L48 64 32 48h32ZM32 32 16 16 0 32h32Zm0 0 16 16 16-16H32Z"/>',
            '<path fill="url(#c2)" d="M0 0h64v64H0z"/><path fill="url(#c3)" d="M0 0h64v64H0z"/><path fill="url(#c2)" d="M32 32-.0000014.0000019 32 5e-7V32Zm0 0 32 32H32V32Z"/><path fill="url(#c1)" d="M32 32-.00000381 64l.0000028-32H32Zm0 0L64 0v32H32Z"/>'
        ];

        string[4] memory backgrounds = [
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="64" height="64" patternUnits="userSpaceOnUse"><circle cx="32" cy="32" r="8" fill="transparent" stroke="url(#c1)" stroke-width="1" opacity=".6"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.2" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" xChannelSelector="B" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,64;"  repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="128" height="128" patternUnits="userSpaceOnUse"><path d="m64 16 32 32H64V16ZM128 16l32 32h-32V16ZM0 16l32 32H0V16ZM128 76l-32 32h32V76ZM64 76l-32 32h32V76Z" fill="url(#c2)"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.002" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="100"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)" opacity=".2">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,128;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="64" height="64" patternUnits="userSpaceOnUse"><path d="M32 0L0 32V64L32 32L64 64V32L32 0Z" fill="url(#c1)" opacity=".1"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.004" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; -128,0;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            ),
            string(
                abi.encodePacked(
                    '<pattern id="bp" width="80" height="40" patternUnits="userSpaceOnUse"><path d="M0 20a20 20 0 1 1 0 1M40 0a20 20 0 1 0 40 0m0 40a20 20 0 1 0 -40 0" fill="url(#c2)" opacity=".2"/></pattern><filter id="bf"><feTurbulence type="fractalNoise" baseFrequency="0.02" numOctaves="1" seed="',
                    seed,
                    '"/><feDisplacementMap in="SourceGraphic" scale="200"/></filter><g filter="url(#bf)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#bp)">',
                    quilt.animatedBg
                        ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; 0,-80;" repeatCount="indefinite"/>'
                        : "",
                    "</rect></g>"
                )
            )
        ];

        string[7] memory parts;

        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                uint256 x = quilt.xOff + 68 * col;
                uint256 y = quilt.yOff + 68 * row;
                uint256 patchPartIndex = quilt.patches[col][row];

                parts[0] = string(
                    abi.encodePacked(
                        parts[0],
                        '<mask id="s',
                        Strings.toString(col + 1),
                        Strings.toString(row + 1),
                        '"><rect rx="',
                        Strings.toString(quilt.roundness),
                        '" x="',
                        Strings.toString(x),
                        '" y="',
                        Strings.toString(y),
                        '" width="64" height="64" fill="white"/></mask>'
                    )
                );

                parts[5] = string(
                    abi.encodePacked(
                        parts[5],
                        '<g mask="url(#s',
                        Strings.toString(col + 1),
                        Strings.toString(row + 1),
                        ')"><g transform="translate(',
                        Strings.toString(x),
                        " ",
                        Strings.toString(y),
                        ')">',
                        patches[patchPartIndex],
                        "</g></g>"
                    )
                );

                parts[6] = string(
                    abi.encodePacked(
                        parts[6],
                        '<rect rx="',
                        Strings.toString(quilt.roundness),
                        '" stroke-width="2" stroke-linecap="round" stroke="url(#c1)" stroke-dasharray="4 4" x="',
                        Strings.toString(x),
                        '" y="',
                        Strings.toString(y),
                        '" width="64" height="64" fill="transparent"/>'
                    )
                );
            }
        }

        parts[1] = string(
            abi.encodePacked(
                '<linearGradient id="c1"><stop stop-color="',
                colors[quilt.themeIndex][0],
                '"/></linearGradient><linearGradient id="c2"><stop stop-color="',
                colors[quilt.themeIndex][1],
                '"/></linearGradient><linearGradient id="c3"><stop stop-color="',
                colors[quilt.themeIndex][2],
                '"/></linearGradient><linearGradient id="c4"><stop stop-color="',
                colors[quilt.backgroundThemeIndex][3],
                '"/></linearGradient>'
            )
        );

        parts[2] = backgrounds[quilt.backgroundIndex];

        parts[3] = string(
            abi.encodePacked(
                '<rect transform="translate(',
                Strings.toString(quilt.quiltX + 8),
                " ",
                Strings.toString(quilt.quiltY + 8),
                ')" x="0" y="0" width="',
                Strings.toString(quilt.quiltW),
                '" height="',
                Strings.toString(quilt.quiltH),
                '" rx="',
                Strings.toString(
                    quilt.roundness == 0 ? 0 : quilt.roundness + 8
                ),
                '" fill="url(#c1)"/>'
            )
        );

        parts[4] = string(
            abi.encodePacked(
                '<rect x="',
                Strings.toString(quilt.quiltX),
                '" y="',
                Strings.toString(quilt.quiltY),
                '" width="',
                Strings.toString(quilt.quiltW),
                '" height="',
                Strings.toString(quilt.quiltH),
                '" rx="',
                Strings.toString(
                    quilt.roundness == 0 ? 0 : quilt.roundness + 8
                ),
                '" fill="url(#c2)" stroke="url(#c1)" stroke-width="2"/>'
            )
        );

        string memory svg = string(
            abi.encodePacked(
                '<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"><defs>',
                parts[0],
                parts[1],
                '</defs><rect width="500" height="500" fill="url(#c4)"/>',
                parts[2],
                '<filter id="f" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence baseFrequency="',
                quilt.smoothnessFactor * 3 >= 10 ? "0.0" : "0.00",
                Strings.toString(quilt.smoothnessFactor * 3),
                '" seed="',
                seed,
                '"/><feDisplacementMap in="SourceGraphic" scale="10"/></filter><g><g filter="url(#f)">',
                parts[3]
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                quilt.hovers
                    ? '<animateTransform attributeName="transform" type="scale" additive="sum" dur="4s" values="1 1; 1.005 1.02; 1 1;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
                    : "",
                '</g><g filter="url(#f)">',
                parts[4],
                parts[5],
                parts[6],
                quilt.hovers
                    ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; -4,-16; 0,0;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
                    : "",
                "</g></g></svg>"
            )
        );

        return (quilt, svg);
    }

    function random(string memory seed, string memory key)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(key, seed)));
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