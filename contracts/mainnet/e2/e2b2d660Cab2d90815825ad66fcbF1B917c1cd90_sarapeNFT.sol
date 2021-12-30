// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

/**
* sarape NFT, 2021-12-29.
* ----------------------------------------------------------------------------
* Crafted following centuries-old traditional Mexican design and artisanal
* aesthetics, "sarape original" is a limited edition NFT collection generated
* 100% on-chain. Each sarape token is a truly unique (1/1) digital artwork.
* Only 256 tokens will be minted and exist forever in the ethereum blockchain.
* ----------------------------------------------------------------------------
*/

// Interfaces
interface Colorverse {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenNameById(uint256 tokenId) external view returns (string memory);
}

contract sarapeNFT is ERC721Enumerable {

    // Global variables

    /// Constants
    uint256 constant public MAX_SUPPLY = 256;
    uint256 constant public MAX_CLAIM_SUPPLY = 64;
    uint256 constant public LAST_ITEMS_SUPPLY = 32;
    uint256 constant public OWNER_MAX_CLAIM = 1;

    uint256 constant public INITIAL_PRICE = 16 * (10 ** 15);    //// 0.016 ether
    uint256 constant public FINAL_PRICE = 8 * (10 ** 16);       //// 0.080 ether

    /// Addresses
    address public immutable ARTIST_ADDRESS;
    address public COLORVERSE_ADDRESS;

    /// Minting
    uint256 public nextId;
    mapping(string => bool) public _colorPairExists;
    mapping(string => bool) public _invertedColorPairExists;
    mapping(address => bool) public _addressClaimedToken;

    /// Struct: sarape traits (color pair, minter)
    struct sarapeTraits {
        uint256 _c1;
        uint256 _c2;
        address _mintedBy;
    }
    mapping(uint256 => sarapeTraits) _sarapeTraits;

    /// Struct: claimed token color name status
    struct claimedTokenStatus {
        string _claimedTokenName;
        bool _isNamed;
    }

    /// Struct: parameters for svg rectangles
    struct rectParams {
        uint256 _x;
        uint256 _y;
        uint256 _w;
        uint256 _h;
        uint256 _f;
    }

    constructor() ERC721("sarape NFT", "SARP")
    {
        ARTIST_ADDRESS = 0x033301034e6d80dEf56d37F270e0DeE29F92ed3a;
        COLORVERSE_ADDRESS = 0xfEe27FB71ae3FEEEf2c11f8e02037c42945E87C4;
        nextId = 1;
    }

    // Public functions

    /// returns the current price
    function getCurrentPrice() public view returns (uint256 currentPrice) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply < MAX_CLAIM_SUPPLY) {
            currentPrice = 0;
        } else if (_totalSupply >= MAX_CLAIM_SUPPLY && _totalSupply < (MAX_SUPPLY - LAST_ITEMS_SUPPLY)) {
            currentPrice = INITIAL_PRICE;
        } else if (_totalSupply >= (MAX_SUPPLY - LAST_ITEMS_SUPPLY)) {
            currentPrice = FINAL_PRICE;
        }
    }

    /// returns the sarape color pair
    function sarapeColorPair(uint256 tokenId) public view returns (uint256, uint256) {
        require(_exists(tokenId), "Nonexistent token.");
        sarapeTraits storage st = _sarapeTraits[tokenId];
        return (st._c1, st._c2);
    }

    /// returns the sarape minter address
    function sarapeMintedBy(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Nonexistent token.");
        sarapeTraits storage st = _sarapeTraits[tokenId];
        return Strings.toHexString(uint256(uint160(st._mintedBy)));
    }

    /// returns sarape svg string
    function sarapeSVG(uint256 tokenId, bool viewBox) public view returns (string memory _sarapeSVG) {

        require(_exists(tokenId), "SVG query for nonexistent token.");

        sarapeTraits storage st = _sarapeTraits[tokenId];
        claimedTokenStatus memory _claimedToken = colorTokenNames(st._c1, st._c2);
        string memory svg;

        //// optionally, generate svg without a specified background color
        //// and with viewBox instead of fixed width and height (e.g. for website display)
        if (viewBox == true) {
            svg = "<svg viewBox='0 0 1080 1960' xmlns='http://www.w3.org/2000/svg'>";
        } else {
            svg = "<svg width='1080' height='1960' xmlns='http://www.w3.org/2000/svg' style='background-color:#808080'>";
        }

        //// set the sarape name string: if the token was claimed, get the color names, otherwise use the color hex codes
        string memory _sarapeName;
        if (tokenId <= MAX_CLAIM_SUPPLY) {
            _sarapeName = _claimedToken._claimedTokenName;
        } else {
            _sarapeName = string(abi.encodePacked(hexColor(st._c1), ".", hexColor(st._c2)));
        }

        //// Block scoping sarape sections to prevent 'stack too deep' error

        {   //// rainbow pattern, main sections
            uint256[39] memory _rainbow = rainbow(st._c1, st._c2);
            uint256[4] memory _ycoord = [uint256(291), 675, 1059, 1442];
            for(uint256 i = 0; i < _ycoord.length; i++) {
                for(uint256 ii = 0; ii < _rainbow.length; ii++) {
                    uint256 _y = _ycoord[i] + (ii * 4);
                    uint256 _f = _rainbow[ii];
                    string memory svgR = rectStr(rectParams(90, _y, 900, 4, _f));
                    svg = string(abi.encodePacked(svg, svgR));
                }
            }
        }

        {   //// intermediate sections
            uint256[7] memory _rainbowInter = [st._c1, accessoryInt(st._c1), 16777215, 0, 16777215, accessoryInt(st._c2), st._c2];
            uint256[3] memory _ycoordInter = [uint256(547), 931, 1314];
            for(uint256 i = 0; i < _ycoordInter.length; i++) {
                for(uint256 ii = 0; ii < _rainbowInter.length; ii++) {
                    uint256 _y = _ycoordInter[i] + (ii * 4);
                    uint256 _f = _rainbowInter[ii];
                    string memory svgRint = rectStr(rectParams(90, _y, 900, 4, _f));
                    svg = string(abi.encodePacked(svg, svgRint));
                }
            }
        }

        {   //// band pattern (black) , main sections
            uint256[8] memory _ycoordMain = [uint256(191), 447, 575, 831, 959, 1214, 1342, 1598];
            for(uint256 i = 0; i < _ycoordMain.length; i++) {
                string memory svgRmain = rectStr(rectParams(90, _ycoordMain[i], 900, 100, 0));
                svg = string(abi.encodePacked(svg, svgRmain));
            }
        }

        {   //// dotted pattern (black), main sections
            string memory svgDot1 = "<line x1='91' x2='989' y1='369' y2='369' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot2 = "<line x1='91' x2='989' y1='753' y2='753' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot3 = "<line x1='91' x2='989' y1='1137' y2='1137' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot4 = "<line x1='91' x2='989' y1='1520' y2='1520' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            svg = string(abi.encodePacked(svg, svgDot1, svgDot2, svgDot3, svgDot4));
        }

        {   //// frame (white), fringe
            string memory svgRfringetopfirst = "<rect x='90' y='145' width='2' height='46' fill='#ffffff'/>";
            string memory svgRfringebotfirst = "<rect x='90' y='1698' width='2' height='46' fill='#ffffff'/>";
            string memory svgLfringetop = "<line x1='120' x2='990' y1='168' y2='168' stroke='#ffffff' stroke-width='46' stroke-dasharray='2,29' />";
            string memory svgLfringebot = "<line x1='120' x2='990' y1='1722' y2='1722' stroke='#ffffff' stroke-width='46' stroke-dasharray='2,29' />";
            string memory svgEndtop = "<rect x='90' y='190' width='900' height='1' fill='#ffffff'/>";
            string memory svgEndbot = "<rect x='90' y='1698' width='900' height='1' fill='#ffffff'/>";
            svg = string(abi.encodePacked(svg, svgLfringetop, svgLfringebot, svgRfringetopfirst, svgRfringebotfirst, svgEndtop, svgEndbot));
        }

        {   //// token Id and token name (sarape title)
            string memory _svgTokenTitle = string(abi.encodePacked(
                "<text x='540px' y='1940px' fill='#f0f0f0' font-family='AndaleMono, Andale Mono, monospace' font-size='16px' text-anchor='middle' text-rendering='optimizeLegibility'>sarape ",
                Strings.toString(tokenId), "   |   ", '"', _sarapeName, '"', "   |   1/1</text>"
            ));
            svg = string(abi.encodePacked(svg, _svgTokenTitle, "</svg>"));
        }

        //// sarape svg string
        return svg;

    }

    /// returns sarape metadata: Base64 encoded ERC721 Metadata JSON Schema [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md]
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "URI query for nonexistent token.");

        sarapeTraits storage st = _sarapeTraits[tokenId];

        claimedTokenStatus memory _claimedToken = colorTokenNames(st._c1, st._c2);
        string memory _claimedTokenName = _claimedToken._claimedTokenName;
        bool _isNamed = _claimedToken._isNamed;
        string memory _traitSarapeName;

        string memory _traitColor1 = string(abi.encodePacked('#', hexColor(st._c1)));
        string memory _traitColor2 = string(abi.encodePacked('#', hexColor(st._c2)));
        string memory _traitTitle;
        string memory _traitMintedBy = sarapeMintedBy(tokenId);
        string memory _svg = sarapeSVG(tokenId, false);

        if (tokenId <= MAX_CLAIM_SUPPLY && _isNamed == true) {
            _traitSarapeName = _claimedTokenName;
            _traitTitle = 'color names';
        } else {
            _traitSarapeName = string(abi.encodePacked(hexColor(st._c1), '.', hexColor(st._c2)));
            _traitTitle = 'color hex codes';
        }

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                _traitSarapeName,
                                '","description": "Traditional. Original. Unique. Generated 100% on-chain.","image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(_svg)),
                                '","attributes": [{"trait_type": "Color 1", "value": "',
                                _traitColor1,
                                '"},{"trait_type": "Color 2","value": "',
                                _traitColor2,
                                '"},{"trait_type": "Title pattern","value": "',
                                _traitTitle,
                                '"},{"trait_type": "Minted by","value": "',
                                _traitMintedBy,
                                '"}]}'
                            )
                        )
                    )
                )
        );

    }

    /// returns the url for the contract metadata (JSON) [https://docs.opensea.io/docs/contract-level-metadata]
    function contractURI() public view returns (string memory) {
        return "https://sarape.io/nft/contract-metadata.json";
    }


    // External functions

    /// mints a token for the current price
    function mint(uint256 _c1, uint256 _c2) external payable {

        require(_c1 < 16777216 && _c2 < 16777216, "24-bit color exceeded.");

        string memory _colorPair = string(abi.encodePacked(Strings.toString(_c1), '.', Strings.toString(_c2)));
        string memory _invertedColorPair = string(abi.encodePacked(Strings.toString(_c2), '.', Strings.toString(_c1)));
        require(!_colorPairExists[_colorPair] && !_invertedColorPairExists[_invertedColorPair], "Color pair already used.");

        if (totalSupply() < MAX_CLAIM_SUPPLY) {
            require(!_addressClaimedToken[msg.sender], "Only one token per address can be claimed.");
            require(msg.sender == Colorverse(COLORVERSE_ADDRESS).ownerOf(_c1), "Address does not own color.");
            require(msg.sender == Colorverse(COLORVERSE_ADDRESS).ownerOf(_c2), "Address does not own color.");
            _addressClaimedToken[msg.sender] = true;
        } else {
            require(totalSupply() < MAX_SUPPLY, "All tokens minted.");
            require(msg.value >= getCurrentPrice(), "Insufficient ETH amount.");
        }

        sarapeTraits storage st = _sarapeTraits[nextId];
        st._c1 = _c1;
        st._c2 = _c2;
        st._mintedBy = msg.sender;

        _colorPairExists[_colorPair] = true;
        _invertedColorPairExists[_invertedColorPair] = true;

        _safeMint(msg.sender, nextId);

        nextId++;

    }

    /// withdraws balance
    function withdraw() external {
        uint256 balance = address(this).balance;
        payable(ARTIST_ADDRESS).transfer(balance);
    }

    /// changes Colorverse contract address (makes this contract future proof)
    function changeColorverseContractAddress(address newAddress) external {
        require(msg.sender == ARTIST_ADDRESS, 'Only the artist can change the Colorverse contract address.');
        COLORVERSE_ADDRESS = newAddress;
    }


    // Internal functions

    /// creates rgb array from color integer value
    function rgbColor(uint256 _colorInt) internal pure returns (uint256[3] memory) {
        uint256 r = _colorInt/(256**2);
        uint256 g = (_colorInt/256)%256;
        uint256 b = _colorInt%256;
        return [r, g, b];
    }

    /// converts color integer to hex value
    function hexColor(uint256 _colorInt) internal pure returns (string memory) {
        string memory _cHex = Strings.toHexString(_colorInt, 3);
        bytes memory b = bytes(_cHex);
        return string(bytes.concat(b[2], b[3], b[4], b[5], b[6], b[7]));
    }

    /// calculates accessory color from main color
    function accessoryInt(uint256 _c) internal pure returns (uint256) {

        //// get color rgb channels
        uint256[3] memory _rgbArray = rgbColor(_c);
        uint256 r = _rgbArray[0];
        uint256 g = _rgbArray[1];
        uint256 b = _rgbArray[2];

        //// calculate green channel
        uint256 gg;
        if (r == 255 && b == 255 && g == 255) { //// exception: pure white
            gg = 255;
        } else if (r == 0 && b == 0 && g == 0) { //// exception: pure black
            gg = 0;
        } else if (g <= 128) {
            gg = 255 - g;
        } else {
            gg = 255 - g + 32;
        }

        return (r * (256 ** 2)) + (gg * 256) + b;

    }

    /// calculates color tint (lighter color tone) or shade (darker color tone)
    function tintshade(uint256 _c, uint256 _n, uint256 _s, bool _tint) internal pure returns (uint256 _tintshade) {

        //// get color rgb channels
        uint256[3] memory _rgbArray = rgbColor(_c);
        uint256 r;
        uint256 g;
        uint256 b;

        //// calculate saturation for each channel
        if (_tint == true) {
            //// tints
            r = _rgbArray[0] + (((255 - _rgbArray[0]) / _s) * _n);
            g = _rgbArray[1] + (((255 - _rgbArray[1]) / _s) * _n);
            b = _rgbArray[2] + (((255 - _rgbArray[2]) / _s) * _n);
        } else {
            //// shades
            r = _rgbArray[0] - ((_rgbArray[0] / _s) * _n);
            g = _rgbArray[1] - ((_rgbArray[1] / _s) * _n);
            b = _rgbArray[2] - ((_rgbArray[2] / _s) * _n);
        }

        //// return color integer
        _tintshade = (r * (256 ** 2)) + (g * 256) + b;

    }

    /// creates 'rainbow' array (a list of colors in the order required for the main sections)
    function rainbow(uint256 _mc1, uint256 _mc2) internal pure returns (uint256[39] memory _rainbow) {

        //// accessory colors
        uint256 _ac1 = accessoryInt(_mc1);
        uint256 _ac2 = accessoryInt(_mc2);

        //// top, main 1 shades
        uint256[8] memory _ts = [uint256(5), 7, 4, 6, 3, 5, 2, 4];
        for(uint256 i = 0; i < _ts.length; i++) {
            _rainbow[i] = tintshade(_mc1, _ts[i], 8, false);
        }

        //// top, main/accessory 1
        _rainbow[8] = _mc1;
        _rainbow[9] = _ac1;

        //// top, main/accessory 1 tints
        uint256[4] memory _tt = [uint256(1), 2, 3, 4];
        for(uint256 i = 0; i < _tt.length; i++) {
            _rainbow[10 + (i * 2)] = tintshade(_mc1, _tt[i], 6, true);
            _rainbow[11 + (i * 2)] = tintshade(_ac1, _tt[i], 5, true);
        }

        //// middle, white;
        for(uint256 i = 18; i < 21; i++) {
            _rainbow[i] = uint256(16777215);
        }

        //// bottom, accessory/main 2 tints
        uint256[4] memory _bt = [uint256(4), 3, 2, 1];
        for(uint256 i = 0; i < _bt.length; i++) {
            _rainbow[21 + (i * 2)] = tintshade(_ac2, _bt[i], 5, true);
            _rainbow[22 + (i * 2)] = tintshade(_mc2, _bt[i], 6, true);
        }

        //// bottom accessory/main 2
        _rainbow[29] = _ac2;
        _rainbow[30] = _mc2;

        //// bottom, main 2 shades
        uint256[8] memory _bs = [uint256(4), 2, 5, 3, 6, 4, 7, 5];
        for(uint256 i = 0; i < _bs.length; i++) {
            _rainbow[31 + i] = tintshade(_mc2, _bs[i], 8, false);
        }

        return _rainbow;

    }

    /// generates svg rectangle string from template
    function rectStr(rectParams memory _r) internal pure returns (string memory _rect) {

        //// parameters
        string memory _x = Strings.toString(_r._x);
        string memory _y = Strings.toString(_r._y);
        string memory _w = Strings.toString(_r._w);
        string memory _h = Strings.toString(_r._h);
        string memory _f = hexColor(_r._f);

        //// string template
        _rect = string(abi.encodePacked("<rect x='", _x, "' y='", _y, "' width='", _w, "' height='", _h, "' fill='#", _f, "'/>"));

    }

    /// returns the name string for the sarape token name
    function colorTokenNames(uint256 _c1, uint256 _c2) internal view returns (claimedTokenStatus memory) {

        //// get color token names and set function variables
        string memory _c1ColorName = Colorverse(COLORVERSE_ADDRESS).tokenNameById(_c1);
        string memory _c2ColorName = Colorverse(COLORVERSE_ADDRESS).tokenNameById(_c2);

        string memory _claimedTokenName;
        bool _isNamed;

        //// temp variables to check if the color is named(i.e. color name length > 0)
        bytes memory _c1temp = bytes(_c1ColorName);
        bytes memory _c2temp = bytes(_c2ColorName);

        //// if the colors are not named, use the color hex codes for the token name
        if  (_c1temp.length != 0 && _c2temp.length != 0) {
            _claimedTokenName = string(abi.encodePacked(_c1ColorName, ', ', _c2ColorName));
            _isNamed = true;
        } else {
            _claimedTokenName = string(abi.encodePacked(hexColor(_c1), ".", hexColor(_c2)));
            _isNamed = false;
        }

        return claimedTokenStatus(_claimedTokenName, _isNamed);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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