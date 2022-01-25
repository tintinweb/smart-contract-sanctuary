// SPDX-License-Identifier: MIT
/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░##################################################░░
░░##################################################░░
░░#######WXOdodOXW##################################░░
░░######Nd'     'dN##################NXK00KXNW######░░
░░#####Wd.       .xW#############W0d:'......':d0W###░░
░░#####Wo         dW############Kc.            .oX##░░
░░######Kc.     .lX############X:               .dW#░░
░░#######W0dcccd0W#############0,                oW#░░
░░#############################X:               ,0##░░
░░######WXOxdooodxk0KXW########Nc              ,OW##░░
░░####Xx;.          ..,:codxxkxl.            .cK####░░
░░##Nk'                                     'kN#####░░
░░#Nd.                                    .lX#######░░
░░#k.                                    ;OW########░░
░░Wl                                   .dN##########░░
░░Wl                                 .cKW###########░░
░░#x.                               ,kN#############░░
░░#Xc                             .dX###############░░
░░##Xc                          .lKW################░░
░░###Xo.                      .lKW##################░░
░░####W0c.                ..,dKW####################░░
░░######WKd;.          .;oOXN#######################░░
░░#########WXOxolllodx0XW###########################░░
░░##################################################░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
>>>          inspired by blobshape.js              <<<
*/
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

import {Utils} from "./libraries/Utils.sol";
import {SVGBlob} from "./libraries/SVGBlob.sol";

contract BlobzBlockz is ERC721URIStorage {
    address private _owner;
    uint256 public _tokenCounter;
    event CreatedBlobzBlockz(uint256 indexed tokenId);

    uint256 internal nonce;
    uint16 internal constant SIZE = 200;
    uint256 public constant PRICE = 100000000000000000;
    uint16 internal constant MAX_BLOBS = 9;

    uint256[] internal _mintableIds;
    mapping(uint256 => uint256) _mintedIds;
    mapping(uint256 => uint256) _timingIds;
    mapping(uint256 => uint256) _themeIds;
    mapping(uint256 => uint256) _subThemeIds;
    mapping(uint256 => uint256) _themeAttrIds;
    mapping(uint256 => uint256) _nbBlobsIds;
    mapping(uint256 => uint256[MAX_BLOBS * 2]) _posIds;
    mapping(uint256 => uint256[MAX_BLOBS]) _scaleIds;

    uint256 public constant MAX_SUPPLY = 512;
    uint256 public REMAINING_SUPPLY = 512;

    constructor() ERC721("BLOBZ", "BlobzBlockz") {
        _owner = msg.sender;
        _tokenCounter = 0;
        nonce = 0;

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            _mintableIds.push(i);
        }
    }

    string[] internal _themes;
    string[] internal _subThemes;
    string[] internal _pos;
    string[] internal _scale;
    string[] internal _timings;

    string internal _p0;
    string internal _p1;
    string internal _p2;
    string internal _p3;
    string internal _p4;

    function _setSvgParts(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3,
        string memory p4
    ) public {
        require(msg.sender == _owner, "Only owner");
        _p0 = p0;
        _p1 = p1;
        _p2 = p2;
        _p3 = p3;
        _p4 = p4;
    }

    function _setThemes(string[] memory themes, string[] memory subThemes)
        public
    {
        require(
            msg.sender == _owner && themes.length > 0 && subThemes.length > 0,
            "Only owner"
        );
        _themes = themes;
        _subThemes = subThemes;
    }

    function _setPos(string[] memory pos) public {
        require(msg.sender == _owner && pos.length > 0, "Only owner");
        _pos = pos;
    }

    function _setScale(string[] memory scale) public {
        require(msg.sender == _owner && scale.length > 0, "Only owner");
        _scale = scale;
    }

    function _setTimings(string[] memory timings) public {
        require(msg.sender == _owner && timings.length > 0, "Only owner");
        _timings = timings;
    }

    function totalSupply() external view returns (uint256) {
        return MAX_SUPPLY - REMAINING_SUPPLY;
    }

    function preMint() internal returns (uint256) {
        require(REMAINING_SUPPLY > 0, "All tokens have been minted");
        uint256 r = Utils.randomWithTimestamp(nonce, MAX_SUPPLY);
        uint256 newTokenIndex = r % _mintableIds.length;
        uint256 newTokenId = _mintableIds[newTokenIndex];

        _mintableIds[newTokenIndex] = _mintableIds[_mintableIds.length - 1];
        _mintableIds.pop();
        _mintedIds[_tokenCounter] = newTokenId;

        _timingIds[newTokenId] = newTokenId % _timings.length;

        for (uint16 i = 0; i < MAX_BLOBS * 2; i++) {
            _posIds[newTokenId][i] = Utils.randomWithTimestamp(
                nonce++,
                _pos.length
            );
        }

        for (uint16 i = 0; i < MAX_BLOBS; i++) {
            _scaleIds[newTokenId][i] = Utils.randomWithTimestamp(
                nonce++,
                _scale.length
            );
        }

        _themeIds[newTokenId] = Utils.getWeightedIndex(
            newTokenId,
            _themes.length
        );

        _subThemeIds[newTokenId] = Utils.randomWithTimestamp(
            newTokenId,
            _subThemes.length
        );

        _nbBlobsIds[newTokenId] =
            MAX_BLOBS -
            Utils.randomWithTimestamp(nonce++, 4);

        return newTokenId;
    }

    function mint() public payable {
        require(
            msg.sender == _owner || msg.value >= PRICE,
            "Bitch better get my money! min 100000000000000 (0,001) required"
        );
        uint256 newTokenId = preMint();
        _safeMint(msg.sender, _tokenCounter);
        _tokenCounter++;
        REMAINING_SUPPLY--;

        emit CreatedBlobzBlockz(newTokenId);
    }

    function mintTo(address to) public {
        require(msg.sender == _owner, "Only owner");
        uint256 newTokenId = preMint();
        _safeMint(to, _tokenCounter);
        _tokenCounter++;
        REMAINING_SUPPLY--;

        emit CreatedBlobzBlockz(newTokenId);
    }

    function batchMint(uint256 _count) public {
        require(msg.sender == _owner, "Only owner");
        uint256 maxCount = MAX_SUPPLY - _tokenCounter;
        uint256 count = _count;
        if (_count > maxCount) count = maxCount;
        for (uint256 i = 0; i < count; i++) {
            mint();
        }
    }

    function batchMintTo(address[] memory addresses) public {
        require(msg.sender == _owner, "Only owner");
        uint256 maxCount = MAX_SUPPLY - _tokenCounter;
        uint256 count = addresses.length;
        if (addresses.length > maxCount) count = maxCount;
        for (uint256 i = 0; i < count; i++) {
            mintTo(addresses[i]);
        }
    }

    function withdraw() public payable {
        require(msg.sender == _owner, "Only owner");
        payable(_owner).transfer(address(this).balance);
    }

    function generateSVG(uint256 targetId)
        internal
        view
        returns (string memory svg)
    {
        string[3] memory parts;

        parts[0] = string(
            abi.encodePacked(
                _p0,
                _themes[_themeIds[targetId]],
                _subThemes[_subThemeIds[targetId]],
                _timings[_timingIds[targetId]],
                Utils.getBytesParams(targetId)
            )
        );

        parts[1] = "";
        parts[2] = "";

        string memory id = "";
        uint256 size;
        uint16 nbC = 3;
        string memory c = "";
        string memory path = "";

        for (uint16 i = 0; i < _nbBlobsIds[targetId]; i++) {
            id = Utils.uint2str(i);
            size = 200 + (i * 25);
            nbC = i % 4;

            c = Utils.getSvgCircles(nbC);

            path = SVGBlob.generateBlobPath(
                uint32(size),
                2 + i,
                0,
                uint32(targetId * 1000 + i),
                0
            );

            parts[0] = string(
                abi.encodePacked(
                    parts[0],
                    "--p",
                    id,
                    ": translate(",
                    _pos[_posIds[targetId][(i * 2)]],
                    "rem,",
                    _pos[_posIds[targetId][(i * 2) + 1]],
                    "rem) scale(",
                    _scale[_scaleIds[targetId][i]],
                    ");"
                )
            );

            parts[1] = string(
                abi.encodePacked(
                    parts[1],
                    '<radialGradient id="blob',
                    id,
                    '_" cx="300" cy="',
                    Utils.uint2str(300 + size / 3),
                    '" r="',
                    Utils.uint2str(size + 75),
                    _p2
                )
            );

            parts[2] = string(
                abi.encodePacked(
                    parts[2],
                    '<g class="blob_',
                    id,
                    '"><g>',
                    c,
                    '<path fill="url(#blob',
                    id,
                    '_)" d="',
                    path,
                    '" /></g></g>'
                )
            );
        }

        parts[0] = string(abi.encodePacked(parts[0], _p1));
        parts[1] = string(abi.encodePacked(parts[1], _p3));
        parts[2] = string(abi.encodePacked(parts[2], _p4, "</svg>"));

        for (uint16 i = 0; i < parts.length; i++) {
            svg = string(abi.encodePacked(svg, parts[i]));
        }

        return svg;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 _targetID = _mintedIds[_tokenId];
        string memory svg = generateSVG(_targetID);

        string memory attrs = string(
            abi.encodePacked(
                '"attributes": [{"trait_type": "Color 1","value": "',
                Utils.uint2str(_themeIds[_targetID]),
                '"}, {"trait_type": "Color 2","value": "',
                Utils.uint2str(_subThemeIds[_targetID]),
                '"}, {"trait_type": "Speed","value": "',
                Utils.uint2str(_timingIds[_targetID]),
                '"}, {"trait_type": "Concentration","value": "',
                Utils.uint2str(_nbBlobsIds[_targetID]),
                '"}], "external_url": "https://w3b.bz/nft/blobbz/',
                Utils.uint2str(_tokenId),
                '"'
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"BlobzBlockz #',
                                Utils.uint2str(_targetID),
                                '", "description":"BLOBZ Token - #',
                                Utils.uint2str(_targetID),
                                ' - fully chain generated and hosted, blobz art animations series each one is verifiably unique in shapes colors and animations",',
                                attrs,
                                ', "background_color": "#fff", "image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(svg)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
/// @title Utils library for RNG and uint string interpolation
/**
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
*/

pragma solidity 0.8.11;

library Utils {
    /**
        @param v uint number to convert ty bytes32
        @return ret bytes32 string interpolatable format
    */
    function uintToBytes(uint256 v) public pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2**8));
                ret |= bytes32(((v % 10) + 48) * 2**(8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

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

    /**
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function random(uint256 nonce, uint256 max) public view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    /**
        generates random numbers every time timestamp of block execution changes
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function randomWithTimestamp(uint256 nonce, uint256 max)
        public
        view
        returns (uint256)
    {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    function getIndexAt(uint256 a, uint8 n) internal pure returns (uint256) {
        if (a & (1 << n) != 0) {
            return 1;
        }
        return 0;
    }

    function getWeightedIndex(uint256 i, uint256 max)
        internal
        pure
        returns (uint256)
    {
        return ((i % (max + 1)) + 1) % ((i % max) + 1);
    }

    function getBytesParams(uint256 targetId)
        internal
        pure
        returns (string memory bytesParams)
    {
        for (uint8 i = 0; i < 9; i++) {
            bytesParams = string(
                abi.encodePacked(
                    bytesParams,
                    "--b",
                    uint2str(i),
                    ":",
                    uint2str(getIndexAt(targetId, i)),
                    ";"
                )
            );
        }
        return bytesParams;
    }

    function getSvgCircles(uint256 nbC)
        internal
        pure
        returns (string memory circles)
    {
        for (uint16 j = 1; j <= nbC; j++) {
            circles = string(
                abi.encodePacked(
                    circles,
                    '<circle class="circle_',
                    Utils.uint2str(j),
                    '" cx="300" cy="',
                    Utils.uint2str(300 - (j * 20)),
                    '" r="',
                    Utils.uint2str(j * 20),
                    '" fill="url(#blobC_)" />'
                )
            );
        }

        return circles;
    }
}

// SPDX-License-Identifier: MIT
/// @title A library used to construct ERC721 token URIs and SVG blob paths
/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░##################################################░░
░░##################################################░░
░░#######WXOdodOXW##################################░░
░░######Nd'     'dN##################NXK00KXNW######░░
░░#####Wd.       .xW#############W0d:'......':d0W###░░
░░#####Wo         dW############Kc.            .oX##░░
░░######Kc.     .lX############X:               .dW#░░
░░#######W0dcccd0W#############0,                oW#░░
░░#############################X:               ,0##░░
░░######WXOxdooodxk0KXW########Nc              ,OW##░░
░░####Xx;.          ..,:codxxkxl.            .cK####░░
░░##Nk'                                     'kN#####░░
░░#Nd.                                    .lX#######░░
░░#k.                                    ;OW########░░
░░Wl                                   .dN##########░░
░░Wl                                 .cKW###########░░
░░#x.                               ,kN#############░░
░░#Xc                             .dX###############░░
░░##Xc                          .lKW################░░
░░###Xo.                      .lKW##################░░
░░####W0c.                ..,dKW####################░░
░░######WKd;.          .;oOXN#######################░░
░░#########WXOxolllodx0XW###########################░░
░░##################################################░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
>>>          inspired by blobshape.js              <<<
*/

pragma solidity 0.8.11;

import {Utils} from "./Utils.sol";

library SVGBlob {
    /** 
        generates pseudo random blob path shapes

        @param size size of created blob
        @param growth  scale ratio of generated blob
        @param edges number of points to generate the blob path (min: 3, max 7)
        @param seed number used to generate deterministic random shapes 
        @param curveMethod index of curve function (default: Q)
                [0 => Q]
                [1 => S]
                [2 => T]
                [3 => L]
        @return path 
    */
    function generateBlobPath(
        uint32 size,
        uint32 growth,
        uint32 edges,
        uint32 seed,
        uint16 curveMethod
    ) public view returns (string memory) {
        return
            _createSvgPath(
                _createPoints(size, growth, edges, seed),
                curveMethod
            );
    }

    /**
        shorthand for a simple blobs
     */
    function blob() public view returns (string memory) {
        return
            generateBlobPath(
                100,
                3,
                3,
                uint32(Utils.randomWithTimestamp(1, 1000)),
                0
            );
    }

    /** 
        retrieves center theta point
        @param value point ratio multiplicator
        @param min  min result value
        @param max max result value
        @return radius theta point distance
    */
    function _getThetaPoint(
        uint32 value,
        uint32 min,
        uint32 max
    ) internal pure returns (uint32 radius) {
        radius = min + ((value * (max - min)) / 1000);
        if (radius > max) {
            radius = radius - min;
        } else if (radius < min) {
            radius = radius + min;
        }
    }

    /** 
        retrieves trigonometry table lookups for a given ratio
        @param count trigonometry angle ratio (from 3 to 7);
        @return array of trigonometry table lookup
    */
    function _divide(uint32 count) internal pure returns (uint32[2][7] memory) {
        uint32[2] memory R1 = [uint32(2000), uint32(1000)];

        if (count <= 3) {
            return [
                R1,
                [uint32(500), uint32(1866)],
                [uint32(500), uint32(134)],
                R1,
                R1,
                R1,
                R1
            ];
        }
        if (count == 4)
            return [
                R1,
                [uint32(1000), uint32(2000)],
                [uint32(0), uint32(2224)],
                [uint32(1000), uint32(0)],
                R1,
                R1,
                R1
            ];

        if (count == 5)
            return [
                R1,
                [uint32(1309), uint32(1951)],
                [uint32(191), uint32(1587)],
                [uint32(191), uint32(412)],
                [uint32(1309), uint32(49)],
                R1,
                R1
            ];

        if (count == 6)
            return [
                R1,
                [uint32(1500), uint32(1866)],
                [uint32(500), uint32(1870)],
                [uint32(0), uint32(2220)],
                [uint32(500), uint32(134)],
                [uint32(1500), uint32(134)],
                R1
            ];

        return [
            R1,
            [uint32(1623), uint32(1781)],
            [uint32(777), uint32(1975)],
            [uint32(99), uint32(1434)],
            [uint32(99), uint32(566)],
            [uint32(777), uint32(25)],
            [uint32(1623), uint32(218)]
        ];
    }

    /**
        calculate point coordinates
        @param origin theta point of blob shape
        @param radius distance from theta to requested point
        @param T trigonometry table
        @return single array of coordinates X and Y
    */
    function _getCoordinates(
        uint32 origin,
        uint32 radius,
        uint32[2] memory T
    ) internal pure returns (uint32[2] memory) {
        uint32 rx = T[0];
        uint32 ry = T[1];

        uint32 x = rx >= 1000
            ? origin + ((radius * (rx - 1000)) / 1000)
            : origin - ((radius * (1000 - rx)) / 1000);
        uint32 y = ry >= 1000
            ? origin + ((radius * (ry - 1000)) / 1000)
            : origin - ((radius * (1000 - ry)) / 1000);

        return [x, y];
    }

    /**
        generate array of points to form a blob
        @param size size of generated blob
        @param minGrowth min scaling of generated blob
        @param edgesCount number of points forming the blob
        @param seed used for generating pseudo random shape
        @return array[@param edgesCount] of array[2] coordinates X and Y
    */
    function _createPoints(
        uint32 size,
        uint32 minGrowth,
        uint32 edgesCount,
        uint32 seed
    ) internal view returns (uint32[2][] memory) {
        uint32 outerRad = size / 2;
        uint32 innerRad = (minGrowth * outerRad) / 10;
        uint32 edges = edgesCount < 3 || edgesCount > 7
            ? uint32(Utils.random(seed, 2)) + 3
            : edgesCount;

        uint32[2][7] memory slices = _divide(edges);
        uint32[2] memory p;
        uint32[2][] memory destPoints = new uint32[2][](edges);

        for (uint32 i = 0; i < edges; i++) {
            uint32 O = _getThetaPoint(
                uint32(Utils.random(i + seed, 1000)) + 1,
                innerRad,
                outerRad
            );
            p = _getCoordinates(outerRad, O, slices[i]);
            destPoints[i][0] = p[0];
            destPoints[i][1] = p[1];
        }
        return destPoints;
    }

    /** 
        generates svg curve path along givent points
        @param points array of coordinates
        @return svg formatted curve path
     */
    function _createSvgPath(uint32[2][] memory points, uint16 curveMethodId)
        internal
        pure
        returns (string memory)
    {
        string memory svgPath = "";
        string[4] memory methods = ["Q", "S", "T", "L"];
        uint16 methodId = curveMethodId > 3 ? 3 : curveMethodId;
        string memory C = methods[methodId];
        uint32[2] memory p1;
        uint32[2] memory p2;
        uint32[2] memory mid = [
            (points[0][0] + points[1][0]) / 2,
            (points[0][1] + points[1][1]) / 2
        ];

        svgPath = string(
            abi.encodePacked(
                svgPath,
                "M",
                Utils.uint2str(mid[0]),
                ",",
                Utils.uint2str(mid[1])
            )
        );

        for (uint32 i = 0; i < points.length; i++) {
            p1 = points[(i + 1) % points.length];
            p2 = points[(i + 2) % points.length];
            mid = [(p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2];
            svgPath = string(
                abi.encodePacked(
                    svgPath,
                    C,
                    Utils.uint2str(p1[0]),
                    ",",
                    Utils.uint2str(p1[1]),
                    ",",
                    Utils.uint2str(mid[0]),
                    ",",
                    Utils.uint2str(mid[1])
                )
            );
        }
        svgPath = string(abi.encodePacked(svgPath, "Z"));
        return svgPath;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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