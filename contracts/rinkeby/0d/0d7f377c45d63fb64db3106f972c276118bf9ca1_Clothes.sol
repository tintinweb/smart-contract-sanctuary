// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Clothes is ERC721Enumerable, Ownable {
    uint256 constant MAX_SUPPLY = 2460;
    uint256 ownerMintsRemaining = 40;
    uint256 constant MAX_MINT = 5;
    uint256 deploymentTime;

    uint256 public rerolledCount = 0;
    mapping(uint256 => bool) wasRerolled;

    struct MintPass {
        IERC721Enumerable token;
        uint256 count;
        mapping(uint256 => bool) used;
    }

    MintPass[3] mintPasses;

    mapping(address => uint256) rerollsRemaining;
    mapping(address => uint256) mintCount;

    uint256 constant private ADJECTIVES_OFFSET = 0;
    uint256 constant private ADJECTIVES_COUNTS = (20 << 18) + (15 << 12) + (12 << 6) + 11;
    uint256 constant private COLORS_OFFSET = (20 + 15 + 12 + 11) * 16;
    uint256 constant private COLORS_COUNTS = (10 << 18) + (8 << 12) + (13 << 6) + 6;
    uint256 constant private MATERIALS_OFFSET = COLORS_OFFSET + (10 + 8 + 13 + 6) * 16;
    uint256 constant private MATERIALS_COUNTS = (7 << 18) + (7 << 12) + 1;
    uint256 constant private ARTICLES_OFFSET = MATERIALS_OFFSET + (7 + 7 + 1) * 16;
    uint256 constant private ARTICLES_COUNTS = (16 << 18) + (18 << 12) + (17 << 6) + 10;

    bytes constant data = hex"6c6f6e6700000000000000000000000073686f72740000000000000000000000746173746566756c000000000000000062726561746861626c650000000000006672696c6c790000000000000000000066757a7a790000000000000000000000666f726d616c0000000000000000000066616e6379000000000000000000000074696768740000000000000000000000736167677900000000000000000000006c6f6f736500000000000000000000006672756d70790000000000000000000064756c6c0000000000000000000000006375746500000000000000000000000064726162000000000000000000000000736c65656b0000000000000000000000736f6674000000000000000000000000666164656400000000000000000000007368696e790000000000000000000000636c65616e00000000000000000000006f6c642d66617368696f6e65640000006e617567687479000000000000000000737461696e2d726573697374616e74006e6561746c79207072657373656400007772696e6b6c65640000000000000000686970000000000000000000000000006368696300000000000000000000000064657369676e65720000000000000000736c696e6b79000000000000000000007363726174636879000000000000000073747265746368790000000000000000736b696d7079000000000000000000006d6f6465726e000000000000000000007374756e6e696e670000000000000000737472696b696e67000000000000000076696e74616765000000000000000000666f726d2d66697474696e6700000000736578790000000000000000000000007465617261776179000000000000000066696c746879000000000000000000006669657263650000000000000000000069726f6e696300000000000000000000726574726f0000000000000000000000736f7068697374696361746564000000656c6567616e74000000000000000000657870656e7369766500000000000000676c616d6f726f757300000000000000626564617a7a6c656400000000000000666972652d726574617264616e7400006c696d697465642d65646974696f6e006d6f6e6f6772616d6d6564000000000062756c6c65742d70726f6f66000000006472792d636c65616e206f6e6c790000776174657270726f6f660000000000007461696c6f726564000000000000000068616e642d737469746368656400000072657665727369626c65000000000000656469626c650000000000000000000079656c6c6f77000000000000000000006f72616e6765000000000000000000007265640000000000000000000000000070696e6b000000000000000000000000626c7565000000000000000000000000677265656e000000000000000000000062726f776e0000000000000000000000626c61636b000000000000000000000077686974650000000000000000000000677261790000000000000000000000006e656f6e20677265656e0000000000006e656f6e206f72616e676500000000006e656f6e2079656c6c6f7700000000006261627920626c7565000000000000006e61767920626c75650000000000000070656163680000000000000000000000637265616d0000000000000000000000666f7265737420677265656e000000007275627900000000000000000000000063686172747265757365000000000000696e6469676f000000000000000000007065726977696e6b6c650000000000006d61726f6f6e0000000000000000000073616c6d6f6e00000000000000000000686f742070696e6b00000000000000006c6176656e646572000000000000000063616e6479206170706c65207265640062757267756e64790000000000000000656d6572616c6400000000000000000070756d706b696e00000000000000000073696c7665720000000000000000000063616d6f75666c6167650000000000006c656f70617264207072696e740000007469652d647965640000000000000000707572706c65000000000000000000007261696e626f77000000000000000000676f6c6400000000000000000000000064656e696d00000000000000000000006c656174686572000000000000000000636f74746f6e00000000000000000000776f6f6c000000000000000000000000706f6c79657374657200000000000000666c616e6e656c0000000000000000006e796c6f6e00000000000000000000006c61636500000000000000000000000076656c766574000000000000000000006275726c617000000000000000000000666973686e6574000000000000000000736174696e00000000000000000000007477656564000000000000000000000073696c6b000000000000000000000000456779707469616e20636f74746f6e00742d73686972740000000000000000006c656767696e677300000000000000006a65616e730000000000000000000000636f6c6c61726564207368697274000064726573730000000000000000000000626c6f757365000000000000000000006e6967687420676f776e000000000000736b6972740000000000000000000000626f786572730000000000000000000073756974000000000000000000000000706f6c6f000000000000000000000000736e65616b65727300000000000000006865656c73000000000000000000000074726f7573657273000000000000000073616e64616c730000000000000000007363617266000000000000000000000063617072692070616e74730000000000636172676f2070616e74730000000000747572746c65206e65636b000000000074757865646f00000000000000000000676f776e000000000000000000000000686f6f6469650000000000000000000068616c74657220746f700000000000007472656e636820636f61740000000000676c6f766573000000000000000000006a756d706572000000000000000000007061726b610000000000000000000000736e6f7770616e7473000000000000007475626520746f700000000000000000736c6970706572730000000000000000626f6f7473000000000000000000000074696500000000000000000000000000626f772d7469650000000000000000007261696e636f617400000000000000006576656e696e6720676f776e0000000063726f7020746f7000000000000000006b696c74000000000000000000000000737765617465722076657374000000006d696e69736b6972740000000000000062656c6c2d626f74746f6d73000000006f766572616c6c730000000000000000736b6f72740000000000000000000000686f6f7020736b697274000000000000706c6174666f726d2073686f65730000737765617470616e74730000000000006c65677761726d6572730000000000006c6f6e6720756e64657277656172000067616c6f736865730000000000000000666c69702d666c6f707300000000000073757370656e64657273000000000000706561636f6174000000000000000000726f6265000000000000000000000000747261636b2073756974000000000000736f636b7300000000000000000000007061726163687574652070616e747300726f6c6c657220736b617465730000006865656c6965730000000000000000006f6e65736965000000000000000000006173736c6573732063686170730000006c696e6765726965000000000000000063726f63730000000000000000000000";

    constructor(
        IERC721Enumerable book,
        IERC721Enumerable signet,
        IERC721Enumerable boomerang
    )
        ERC721("The Emperor's Non-fungible Clothes", "CLOTHES")
    {
        mintPasses[0].token = book;
        mintPasses[0].count = 30;

        mintPasses[1].token = signet;
        mintPasses[1].count = 25;

        mintPasses[2].token = boomerang;
        mintPasses[2].count = 2**256-1; // infinity

        deploymentTime = block.timestamp;
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;base64,',
            b64(abi.encodePacked(
                '{'
                    '"name": "The Emperor\'s Non-fungible Clothes",'
                    '"description": "Only the wise can see the Emperor\'s Non-fungible Clothes. Up to 2,500 unique NFTs (but collectors determine the final number!), 100% on chain. No website, and no roadmap.\\n\\nNote that this is the final artwork, permanently stored on the blockchain. The idea for this generative NFT project came about from a discussion about how a URL pointing to a JPEG or GIF is the least interesting part of a NFT.",'
                    '"image": "', getImage(), '"'
                '}'
            ))
        ));
    }

    // This function automatically mints using any available mint passes. It
    // also mints one token per 0.02 ETH sent. There is a maximum of 5 tokens
    // minted per address, and the total supply is limited to 2500, including
    // rerolled tokens.
    function mint() external payable {
        require(block.timestamp >= deploymentTime + 24 hours || msg.value == 0, "Only mint passes are accepted for the first 24 hours.");
        require(msg.value % 0.02 ether == 0, "You can only send a multiple of 0.02 ETH.");
        require(totalSupply() + rerolledCount < MAX_SUPPLY, "Cap reached.");
        uint256 available = MAX_SUPPLY - (totalSupply() + rerolledCount);

        uint256 howMany = 0;
        uint256 rerolls = 0;

        // for each mint pass
        for (uint256 i = 0; i < mintPasses.length; i++) {
            MintPass storage pass = mintPasses[i];

            // if the sender has at least one token
            if (pass.token.balanceOf(msg.sender) > 0) {
                // get their first token (should only have one)
                uint256 tokenId = pass.token.tokenOfOwnerByIndex(msg.sender, 0);

                // if the token ID is unused and less than the allowed count
                if (tokenId < pass.count && !pass.used[tokenId]) {
                    // use up the token
                    pass.used[tokenId] = true;

                    // grant another free clothes token (with reroll)
                    howMany += 1;
                    rerolls += 1;
                }
            }
        }

        // bonus for having all 3!
        if (howMany == 3) {
            howMany = 5;
            rerolls = 5;
        }

        if (howMany > available) {
            howMany = available;
            rerolls = 0; // there will be no tokens left to generate
        }

        // 0.02 ETH per paid token
        uint256 paid = msg.value / 0.02 ether;
        howMany += paid;
        rerolls += paid / 2; // one reroll per two paid tokens

        require(howMany <= available, "Cap reached.");
        require(howMany > 0, "Not minting anything.");

        mintCount[msg.sender] += howMany;
        rerollsRemaining[msg.sender] += rerolls;
        require(mintCount[msg.sender] <= MAX_MINT, "Can't mint more than 5 tokens.");

        for (uint256 i = 0; i < howMany; i++) {
            _mintOne(msg.sender);
        }
    }

    // 40 are held back for founders to mint just in case everything sells out
    function ownerMint(uint256 howMany, address to) external onlyOwner {
        require(ownerMintsRemaining > howMany);
        ownerMintsRemaining -= howMany;

        for (uint256 i = 0; i < howMany; i++) {
            _mintOne(to);
        }
    }

    // extract lambos
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _mintOne(address recipient) internal {
        uint256 tokenId = gen();
        // generate token IDs until we found one unclaimed and unrerolled
        while (_exists(tokenId) || wasRerolled[tokenId]) {
            tokenId = gen();
        }

        // mint the token we generated
        _mint(recipient, tokenId);
    }

    // Give up a token in exchange for another randomly selected one. Rerolls
    // are limited. Mint passes give you one reroll per token, and purchased
    // tokens give you half as many rerolls as tokens purchased (in one call).
    // To maximize available rerolls, make sure to purchase at least two tokens
    // in each call to mint().
    function reroll(uint256 tokenId) external {
        require(totalSupply() + rerolledCount < MAX_SUPPLY, "Cap reached.");
        require(rerollsRemaining[msg.sender] > 0, "No rerolls remaining.");
        require(ownerOf(tokenId) == msg.sender, "Only owner may reroll.");

        rerollsRemaining[msg.sender] -= 1;
        wasRerolled[tokenId] = true;
        rerolledCount += 1;
        _burn(tokenId);

        _mintOne(msg.sender);
    }

    uint256 internalSeed = 0;
    function rand(uint256 max) internal returns (uint256) {
        return uint256(keccak256(abi.encode(
            msg.sender,
            block.timestamp,
            block.difficulty,
            blockhash(block.number - 1),
            internalSeed++))) % max;
    }
    
    function choose(uint256 counts) internal returns (uint256) {
        uint256 a = counts >> 18;
        uint256 b = (counts >> 12) & 0x3F;
        uint256 c = (counts >> 6) & 0x3F;
        uint256 d = counts & 0x3F;
        
        uint256 range = a * 10 + b * 7 + c * 4 + d * 2;
        
        uint256 r = rand(range);

        uint256 i = 0;
        while (true) {
            uint256 score = i < a ? 10 : i < a+b ? 7 : i < a+b+c ? 4 : 2;
            if (r < score) {
                return i;
            }
            r -= score;
            i += 1;
        }
        
        revert();
    }

    function wordFor(uint256 offset, uint256 index) internal pure returns (string memory) {
        uint256 position = offset + index*16;
        uint128 word = 0;

        for (uint256 i = 0; i < 16; i++) {
            word *= 256;
            word += uint8(data[position+i]);
        }

        return string(trim(abi.encodePacked(word)));
    }

    function gen() internal returns (uint256) {
        if (rand(500) == 0) {
            return rand(3);
        }
        
        if (rand(125) == 0) {
            return (1 << 32) + choose(ARTICLES_COUNTS);
        }
        
        return (2 << 32) + (choose(ADJECTIVES_COUNTS) << 24) + (choose(COLORS_COUNTS) << 16) + (choose(MATERIALS_COUNTS) << 8) + choose(ARTICLES_COUNTS);
    }

    function getImage() pure internal returns (string memory) {
        return string(abi.encodePacked(
            'data:image/svg+xml;base64,',
            b64('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 76 76" version="1.1"><rect x="4" y="4" width="68" height="68" ry="5" style="fill:#ffffff;stroke:#808080;stroke-width:2;stroke-linecap:round;stroke-dasharray:3,5"/></svg>')
        ));
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        uint8 typ = uint8(id >> 32);
        uint8 adjective = uint8(id >> 24);
        uint8 color = uint8(id >> 16);
        uint8 material = uint8(id >> 8);
        uint8 article = uint8(id);
        
        string memory name;
        string memory adjectiveString;
        string memory colorString;
        string memory materialString;
        string memory articleString;
        
        if (typ == 0) {
            name = article == 0 ? "ugly Christmas sweater" : article == 1 ? "itsy-bitsy teeny-weeny yellow polka dot bikini" : "Hawaiian shirt";
        } else if (typ == 1) {
            adjectiveString = "diamond";
            articleString = wordFor(ARTICLES_OFFSET, article);
            name = string(abi.encodePacked("diamond ", articleString));
        } else {
            adjectiveString = wordFor(ADJECTIVES_OFFSET, adjective);
            colorString = wordFor(COLORS_OFFSET, color);
            materialString = wordFor(MATERIALS_OFFSET, material);
            articleString = wordFor(ARTICLES_OFFSET, article);
            name = string(abi.encodePacked(
                adjectiveString, " ",
                colorString, " ",
                materialString, " ",
                articleString
            ));
        }
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            b64(abi.encodePacked(
                "{",
                '"name":"the Emperor\'s ', name, '","image":"',
                getImage(),
                '","attributes":[',
                typ == 0
                ? abi.encodePacked(
                    '{"trait_type":"article","value":"',
                    name,
                    '"}]}')
                : abi.encodePacked(
                    '{"trait_type":"adjective","value":"',
                    adjectiveString,
                    '"},',
                    bytes(colorString).length != 0
                    ? string(abi.encodePacked(
                        '{"trait_type":"color","value":"',
                        colorString,
                        '"},{"trait_type":"material","value":"',
                        materialString,
                        '"},'))
                    : '',
                    abi.encodePacked(
                        '{"trait_type":"article","value":"',
                        articleString,
                        '"}]}'
                    )
                )
            ))
        ));
    }
    
    function trim(bytes memory input) internal pure returns (bytes memory) {
        uint256 len = 0;
        while (len < input.length && input[len] != 0) {
            len += 1;
        }
        bytes memory output = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            output[i] = input[i];
        }
        return output;
    }

    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function b64(bytes memory bs) internal pure returns (string memory) {
        uint256 rem = bs.length % 3;

        uint256 res_length = (bs.length + 2) / 3 * 4;
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= bs.length; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(bs[i]),
                uint8(bs[i+1]),
                uint8(bs[i+2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(bs[bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(bs[bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j+1] = b1;
            if (rem == 2) {
              res[j+2] = b2;
            }
        }
        
        for (uint256 k = j + rem+1; k < res_length; k++) {
            res[k] = '=';
        }

        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
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