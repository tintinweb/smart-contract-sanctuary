// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./MoreOrLessArt.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || | ____    ____ | || |     ____     | || |  _______     | || |  _________   | || |     _  _     | | //
// | |    | || |    | || ||_   \  /   _|| || |   .'    `.   | || | |_   __ \    | || | |_   ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |  |   \/   |  | || |  /  .--.  \  | || |   | |__) |   | || |   | |_  \_|  | || |    \_|\_|    | | //
// | |              | || |  | |\  /| |  | || |  | |    | |  | || |   |  __ /    | || |   |  _|  _   | || |              | | //
// | |              | || | _| |_\/_| |_ | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___/ |  | || |              | | //
// | |              | || ||_____||_____|| || |   `.____.'   | || | |____| |___| | || | |_________|  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                          .----------------.  .----------------.                                          //
//                                         | .--------------. || .--------------. |                                         //
//                                         | |     ____     | || |  _______     | |                                         //
//                                         | |   .'    `.   | || | |_   __ \    | |                                         //
//                                         | |  /  .--.  \  | || |   | |__) |   | |                                         //
//                                         | |  | |    | |  | || |   |  __ /    | |                                         //
//                                         | |  \  `--'  /  | || |  _| |  \ \_  | |                                         //
//                                         | |   `.____.'   | || | |____| |___| | |                                         //
//                                         | |              | || |              | |                                         //
//                                         | '--------------' || '--------------' |                                         //
//                                          '----------------'  '----------------'                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || |   _____      | || |  _________   | || |    _______   | || |    _______   | || |     _  _     | | //
// | |    | || |    | || |  |_   _|     | || | |_   ___  |  | || |   /  ___  |  | || |   /  ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |    | |       | || |   | |_  \_|  | || |  |  (__ \_|  | || |  |  (__ \_|  | || |    \_|\_|    | | //
// | |              | || |    | |   _   | || |   |  _|  _   | || |   '.___`-.   | || |   '.___`-.   | || |              | | //
// | |              | || |   _| |__/ |  | || |  _| |___/ |  | || |  |`\____) |  | || |  |`\____) |  | || |              | | //
// | |              | || |  |________|  | || | |_________|  | || |  |_______.'  | || |  |_______.'  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract MoreOrLessVote is ERC721Enumerable, Ownable {

    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    uint16 public moreVotes;
    uint16 public lessVotes;

    uint16 public constant maxSupply = 1000;

    struct Vote {       
        address votedBy;
        bool isTheDecider;
        bool influencer;
        uint16[2] votesAtTime;
        bool vote;
    }

    Vote[maxSupply + 1] public voteInfos;
    MoreOrLessArt.Art[maxSupply + 1] public artInfos;

    mapping(address => bool) private hasVoted;

    constructor() ERC721("More or Less", "MORL") {
        uint256 mintNum = 0;
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        voteInfos[0].votedBy = msg.sender;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"More Or Less #',
                (tokenId).toString(),
            '",',
            '"description":"',
                getDescription(tokenId),
            '",',
            '"image":"',
                _generateImage(tokenId),
            '", "attributes":[',
                getMetadata(tokenId),
            ']',
        '}'));
    }

    function getDescription(uint256 tokenId) private pure returns (string memory) {
        if (tokenId == 0) {
            return "This is the genesis token for the MORE or LESS experiment by @yungwknd. It is constantly changing to reflect the unknown results of this experiment and all the possible different outputs.";
        }
        if (tokenId == maxSupply) {
            return "This is the closing token for the MORE or LESS experiment by @yungwknd. While its image may change, the metadata reflects the final sealing of the vote and what the participants decided.";
        }
        return "Provenance is everything. MORE or LESS is a social experiment by @yungwknd. It attempts to answer the question 'would you rather donate $100 or give me $10?'. Each participant receives a commemorative NFT as they vote to donate MORE or LESS. Thank you for participating.";
    }

    function _getVoteString(bool voteMore) private pure returns (string memory) {
        if (voteMore) {
            return "MORE";
        } else {
            return "LESS";
        }
    }

    function getSpecialMetadata(uint256 tokenId) private view returns (string memory) {
        if (tokenId == 0) {
            return string(abi.encodePacked(
                MoreOrLessArt._wrapTrait("Token Vote", "Abstain"),
                ',',MoreOrLessArt._wrapTrait("Created By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
                ',',MoreOrLessArt._wrapTrait("Genesis Token", "True"),
                ',',MoreOrLessArt._wrapTrait("Live Image", "True")
            ));
        } else if (tokenId == maxSupply) {
            return string(abi.encodePacked(
                MoreOrLessArt._wrapTrait("Token Vote", "Abstain"),
                ',',MoreOrLessArt._wrapTrait("Sealed By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
                ',',MoreOrLessArt._wrapTrait("Final Vote Count", string(abi.encodePacked(
                    moreVotes.toString(),
                    " MORE and ",
                    lessVotes.toString(),
                    " LESS."))),
                ',',MoreOrLessArt._wrapTrait("Live Image", "True")
            ));
        }
        return "";
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0 || tokenId == maxSupply) {
            return getSpecialMetadata(tokenId);
        }
        string memory metadata = string(abi.encodePacked(
            MoreOrLessArt._wrapTrait("Token Vote", _getVoteString(voteInfos[tokenId].vote)),
            ',',MoreOrLessArt._wrapTrait("Voted By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
            ',',getVotesAtTime(tokenId)
        ));

        if (artInfos[tokenId].whichShape == 0) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Circles", artInfos[tokenId].numCircles.toString())
            ));
        } else if (artInfos[tokenId].whichShape == 1) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Rectangles", artInfos[tokenId].numRects.toString())
            ));
        } else if (artInfos[tokenId].whichShape == 2) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Triangles", artInfos[tokenId].numTriangles.toString())
            ));
        } else {
            metadata = string(abi.encodePacked(
            metadata,
            ',',MoreOrLessArt._wrapTrait("Rectangles", artInfos[tokenId].numRects.toString()),
            ',',MoreOrLessArt._wrapTrait("Triangles", artInfos[tokenId].numTriangles.toString()),
            ',',MoreOrLessArt._wrapTrait("Circles", artInfos[tokenId].numCircles.toString())
            ));
        }

        metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Lines", artInfos[tokenId].numLines.toString())
        ));

        if (voteInfos[tokenId].isTheDecider) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Decider", "True")
            ));
        }
        if (voteInfos[tokenId].influencer) {
            metadata = string(abi.encodePacked(
                metadata,
                ',',
                MoreOrLessArt._wrapTrait("Influencer", "True")
            ));
        }
        
        return metadata;
    }

    function getVotesAtTime(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            MoreOrLessArt._wrapTrait("Votes at Time", string(abi.encodePacked(
                voteInfos[tokenId].votesAtTime[0].toString(),
                " MORE and ",
                voteInfos[tokenId].votesAtTime[1].toString(),
                " LESS.")))
        ));
    }

    function mintMORE() public payable {
        require(hasVoted[msg.sender] == false, 'Cannot vote twice.');
        require(msg.value > 100000000, 'Not enough ETH');
        require(totalSupply() < maxSupply, 'No more voting');
        uint256 mintNum = totalSupply();
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "MORE")));
        artInfos[mintNum].randomTimestamp = uint48(block.timestamp);
        artInfos[mintNum].randomDifficulty = uint128(block.difficulty);
        artInfos[mintNum].randomSeed = num;
        voteInfos[mintNum].votedBy = msg.sender;
        voteInfos[mintNum].votesAtTime = [moreVotes, lessVotes];
        voteInfos[mintNum].vote = true;
        _saveImageInfo(artInfos[mintNum]);
        voteInfos[mintNum].influencer = moreVotes == lessVotes;
        moreVotes++;
        voteInfos[mintNum].isTheDecider = moreVotes == 10 && lessVotes < 10;
    }

    function mintLESS() public payable {
        require(hasVoted[msg.sender] == false, 'Cannot vote twice.');
        require(msg.value > 10000000, 'Not enough ETH');
        require(totalSupply() < maxSupply, 'No more voting');
        uint256 mintNum = totalSupply();
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "LESS")));
        artInfos[mintNum].randomTimestamp = uint48(block.timestamp);
        artInfos[mintNum].randomDifficulty = uint128(block.difficulty);
        artInfos[mintNum].randomSeed = num;
        voteInfos[mintNum].votedBy = msg.sender;
        voteInfos[mintNum].votesAtTime = [moreVotes, lessVotes];
        voteInfos[mintNum].vote = false;
        _saveImageInfo(artInfos[mintNum]);
        voteInfos[mintNum].influencer = moreVotes == lessVotes;
        lessVotes++;
        voteInfos[mintNum].isTheDecider = lessVotes == 10 && moreVotes < 10;
    }

    function _generateImage(uint256 mintNum) private view returns (string memory) {
        MoreOrLessArt.Art memory artData = artInfos[mintNum];
        if (mintNum == 0 || mintNum == maxSupply) {
            artData.randomTimestamp = uint48(block.timestamp);
            artData.randomDifficulty = uint128(block.difficulty);
            artData.randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "MOREORLESS")));
            artData.whichShape = uint8(MoreOrLessArt.seededRandom(0, 4, artData.randomSeed, artData));
            artData.numRects = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+1, artData));
            artData.numCircles = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+2, artData));
            artData.numTriangles = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+3, artData));
            artData.numLines = uint8(MoreOrLessArt.seededRandom(1,10,artData.randomSeed+4, artData));
        }
        string memory triangles = MoreOrLessArt._generateTriangles(artData);
        string memory circles = MoreOrLessArt._generateCircles(artData);
        string memory rectangles = MoreOrLessArt._generateRectangles(artData);
        string memory lines = MoreOrLessArt._generateLines(artData);

        if (artInfos[mintNum].whichShape == 0) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), circles, lines, MoreOrLessArt._imageFooter));
        } else if (artInfos[mintNum].whichShape == 1) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), rectangles, lines, MoreOrLessArt._imageFooter));
        } else if (artInfos[mintNum].whichShape == 2) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), triangles, lines, MoreOrLessArt._imageFooter));
        }

        return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), circles, triangles, rectangles, lines, MoreOrLessArt._imageFooter));
    }

    function _saveImageInfo(MoreOrLessArt.Art storage artInfo) private {
        uint256 seed = artInfo.randomSeed;
        artInfo.whichShape = uint8(MoreOrLessArt.seededRandom(0, 4, seed, artInfo));
        artInfo.numRects = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 1, artInfo));
        artInfo.numCircles = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 2, artInfo));
        artInfo.numTriangles = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 3, artInfo));
        artInfo.numLines = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 4, artInfo));
    }

    function withdraw(address _to, uint amount) public onlyOwner {
        payable(_to).transfer(amount);
    }

    function sealVote(address _to) public onlyOwner {
        require(totalSupply() == maxSupply, "Voting must be complete.");
        uint256 mintNum = maxSupply;
        _safeMint(_to, mintNum);
        voteInfos[maxSupply].votedBy = msg.sender;
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || | ____    ____ | || |     ____     | || |  _______     | || |  _________   | || |     _  _     | | //
// | |    | || |    | || ||_   \  /   _|| || |   .'    `.   | || | |_   __ \    | || | |_   ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |  |   \/   |  | || |  /  .--.  \  | || |   | |__) |   | || |   | |_  \_|  | || |    \_|\_|    | | //
// | |              | || |  | |\  /| |  | || |  | |    | |  | || |   |  __ /    | || |   |  _|  _   | || |              | | //
// | |              | || | _| |_\/_| |_ | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___/ |  | || |              | | //
// | |              | || ||_____||_____|| || |   `.____.'   | || | |____| |___| | || | |_________|  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                          .----------------.  .----------------.                                          //
//                                         | .--------------. || .--------------. |                                         //
//                                         | |     ____     | || |  _______     | |                                         //
//                                         | |   .'    `.   | || | |_   __ \    | |                                         //
//                                         | |  /  .--.  \  | || |   | |__) |   | |                                         //
//                                         | |  | |    | |  | || |   |  __ /    | |                                         //
//                                         | |  \  `--'  /  | || |  _| |  \ \_  | |                                         //
//                                         | |   `.____.'   | || | |____| |___| | |                                         //
//                                         | |              | || |              | |                                         //
//                                         | '--------------' || '--------------' |                                         //
//                                          '----------------'  '----------------'                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || |   _____      | || |  _________   | || |    _______   | || |    _______   | || |     _  _     | | //
// | |    | || |    | || |  |_   _|     | || | |_   ___  |  | || |   /  ___  |  | || |   /  ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |    | |       | || |   | |_  \_|  | || |  |  (__ \_|  | || |  |  (__ \_|  | || |    \_|\_|    | | //
// | |              | || |    | |   _   | || |   |  _|  _   | || |   '.___`-.   | || |   '.___`-.   | || |              | | //
// | |              | || |   _| |__/ |  | || |  _| |___/ |  | || |  |`\____) |  | || |  |`\____) |  | || |              | | //
// | |              | || |  |________|  | || | |_________|  | || |  |_______.'  | || |  |_______.'  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
library MoreOrLessArt {

    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    struct Art {
        uint8 numRects;
        uint8 numCircles;
        uint8 numTriangles;
        uint8 numLines;
        uint8 whichShape;
        uint48 randomTimestamp;
        uint128 randomDifficulty;
        uint256 randomSeed;
    }

    string internal constant _imageFooter = "</svg>";

    function getRectanglePalette() internal pure returns(string[5] memory) {
      return ['%23ece0d1', '%23dbc1ac', '%23967259', '%23634832', '%2338220f'];
    }

    function getCirclePalette() internal pure returns(string[5] memory) {
      return ['%230F2A38', '%231D3C43', '%232A4930', '%23132F13', '%23092409'];
    }

    function getLinePalette() internal pure returns(string[5] memory) {
      return ['%23b3e7dc', '%23a6b401', '%23eff67b', '%23d50102', '%236c0102'];
    }

    function getTrianglePalette() internal pure returns(string[5] memory) {
      return ['%237c7b89', '%23f1e4de', '%23f4d75e', '%23e9723d', '%230b7fab'];
    }

    function getDBochmanPalette() internal pure returns(string[5] memory) {
      return ['%23000000', '%233d3d3d', '%23848484', '%23bbbbbb', '%23ffffff'];
    }

    function getColorPalette(uint256 seed, Art memory artData) private pure returns(string[5] memory) {
        uint16 r = seededRandom(0, 3, seed, artData);
        if (r == 0) {
            return getCirclePalette();
        } else if (r == 1) {
            return getTrianglePalette();
        } else if (r == 2) {
            return getRectanglePalette();
        } else {
            return getDBochmanPalette();
        }
    }

    function random(uint128 difficulty, uint48 timestamp, uint seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(difficulty, timestamp, seed)));
    }

    function seededRandom(uint low, uint high, uint256 seed, Art memory artData) internal pure returns (uint16) {
        uint seedR = uint(uint256(keccak256(abi.encodePacked(seed, random(artData.randomDifficulty, artData.randomTimestamp, artData.randomSeed)))));
        uint randomnumber = seedR % high;
        randomnumber = randomnumber + low;
        return uint16(randomnumber);
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function _generateHeader(uint256 seed, Art memory artData) internal pure returns (string memory) {
        string memory header = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='moreorless' width='1000' height='1000' viewBox='0 0 1000 1000' style='background-color:";
        string memory color = getColorPalette(seed, artData)[seededRandom(0, 5, seed, artData)];
        return string(abi.encodePacked(
            header,
            color,
            "'>"
        ));
    }

    function _generateCircles(Art memory artData) internal pure returns (string memory) {
        string memory circles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numCircles; i++) {
            circles = string(abi.encodePacked(
                circles,
                "<ellipse cx='",
                seededRandom(0, 1000, artData.randomSeed + i, artData).toString(),
                "' cy='",
                seededRandom(0, 1000, artData.randomSeed - i, artData).toString(),
                "' rx='",
                seededRandom(0, 100, artData.randomSeed + i - 1, artData).toString(),
                "' ry='",
                seededRandom(0, 100, artData.randomSeed - i + 1, artData).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed + i, artData)],
                "'",
            "/>"));
        }

        return circles;
    }

    function _generateSLines(uint256 seed, Art memory artData) internal pure returns (string memory) {
      return string(abi.encodePacked(
        " S",
        seededRandom(0, 1000, seed + 1, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 2, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 3, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 4, artData).toString()
      ));
    }

    function _generateLines(Art memory artData) internal pure returns (string memory) {
        string memory lines = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numLines; i++) {
            lines = string(abi.encodePacked(
                lines,
                "<path style='fill:none; stroke:",
                colorPalette[seededRandom(0, 5, i * i, artData)],
                "; stroke-width: 10px;' d='M",
                seededRandom(0, 400, i * i + 2, artData).toString(),
                " ",
                seededRandom(0, 400, i * i + 3, artData).toString(),
                _generateSLines(artData.randomSeed + i, artData),
                _generateSLines(artData.randomSeed - i, artData),
                " Z'",
            "/>"));
        }

        return lines;
    }

    function getTrianglePoints(uint256 seed, Art memory artData) private pure returns (string memory) {
        return string(abi.encodePacked(
            seededRandom(0, 1000, seed + 1, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 2, artData).toString(),
            " ",
            seededRandom(0, 1000, seed + 3, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 4, artData).toString(),
            " ",
            seededRandom(0, 1000, seed + 5, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 6, artData).toString(),
            "'"
      ));
    }

    function _generateTriangles(Art memory artData) internal pure returns (string memory) {
        string memory triangles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numTriangles; i++) {
            triangles = string(abi.encodePacked(
                triangles,
                "<polygon points='",
                getTrianglePoints(artData.randomSeed + i, artData),
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed - i, artData)],
                "'",
            "/>"));
        }

        return triangles;
    }

    function _generateRectangles(Art memory artData) internal pure returns (string memory) {
        string memory rectangles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numRects; i++) {
            rectangles = string(abi.encodePacked(
                rectangles,
                "<rect width='",
                seededRandom(0, 400, artData.randomSeed + i, artData).toString(),
                "' height='",
                seededRandom(0, 400, artData.randomSeed - i, artData).toString(),
                "' x='",
                seededRandom(0, 1000, artData.randomSeed - 1 - i, artData).toString(),
                "' y='",
                seededRandom(0, 1000, artData.randomSeed + 1 + i, artData).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed + i, artData)],
                "'",
            "/>"));
        }

        return rectangles;
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

