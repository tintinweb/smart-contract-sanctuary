// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @title JustBackgrounds
/// @author jpegmint.xyz

import "./Colors.sol";
import "./Traits.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/////////////////////////////////////////////////////////////////////////////////
//       __         __    ___           __                              __     //
//   __ / /_ _____ / /_  / _ )___ _____/ /_____ ________  __ _____  ___/ /__   //
//  / // / // (_-</ __/ / _  / _ `/ __/  '_/ _ `/ __/ _ \/ // / _ \/ _  (_-<   //
//  \___/\_,_/___/\__/ /____/\_,_/\__/_/\_\\_, /_/  \___/\_,_/_//_/\_,_/___/   //
//                                        /___/                                //
/////////////////////////////////////////////////////////////////////////////////

contract JustBackgrounds is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    bool private _isReserved;
    uint8[] private _unusedColors;
    uint256 private _tokenPrice = 0.01 ether;
    uint256 private _tokenReserved = 10;
    uint256 private _tokenMaxPerTxn = 1;
    uint256 private _tokenMaxSupply = 256;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => bytes1) private _tokenToColorIndex;

    constructor() ERC721("JustBackgrounds", "GRNDS") {
        _pause();
        for(uint256 i = 0; i < _tokenMaxSupply; i++) {
            _unusedColors.push(uint8(i));
        }
    }

    function availableSupply() public view returns (uint256) {
        return _tokenMaxSupply - totalSupply();
    }

    /// Minting Functions ///
    function mintCollectibles(uint256 howMany) external payable whenNotPaused {
        require(availableSupply() >= howMany, "GRNDS: Qty exceeds available supply");
        require(howMany > 0 && howMany <= _tokenMaxPerTxn, "GRNDS: Qty exceeds max per txn");
        require(msg.value >= howMany * _tokenPrice, "GRNDS: Not enough ether sent");
        
        for (uint256 i = 0; i < howMany; i++) {
            _mintBackground(msg.sender, uint8(_generateRandomNumber(i) % _unusedColors.length));
        }
    }

    function reserveCollectibles() external onlyOwner {
        require(!_isReserved, "GRNDS: Tokens already reserved.");
        require(_tokenReserved <= availableSupply(), "GRNDS: Qty exceeds available supply");

        _isReserved = true;
        for (uint256 i = 0; i < _tokenReserved; i++) {
            _mintBackground(msg.sender, uint8(i));
        }
    }

    /**
     * @dev Mints collectible and stores assigned color.
     */
    function _mintBackground(address to, uint8 colorIndex) private nonReentrant {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());

        _tokenToColorIndex[_tokenIdCounter.current()] = bytes1(_unusedColors[colorIndex]);
        _unusedColors[colorIndex] = _unusedColors[_unusedColors.length - 1];
        _unusedColors.pop();
    }

    /**
     * @dev Generates pseudorandom number, functional for random color assignment.
     */
    function _generateRandomNumber(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, blockhash(block.number), seed)));
    }

    /**
     * @dev On-chain, dynamic generation of metadata and SVG background.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "GRNDS: URI query for nonexistent token");

        string memory mintNumber = tokenId.toString();
        bytes6 metadata = Colors.getColorMetadata(_tokenToColorIndex[tokenId]);
        Traits.ColorTraits memory traits = Traits.getColorTraits(metadata);

        bytes memory byteString;
        byteString = abi.encodePacked(byteString, 'data:application/json;utf8,{');
        byteString = abi.encodePacked(byteString, '"created_by": "jpegmint.xyz",');
        byteString = abi.encodePacked(byteString, '"external_url": "https://justbackgrounds.xyz/",');

        /// Dynamic Name ///
        if (_checkIfMatch(traits.special, 'Transparent') || _checkIfMatch(traits.special, 'Meme')) {
            byteString = abi.encodePacked(byteString, '"name": "', traits.name, '",');
        } else {
            byteString = abi.encodePacked(byteString, '"name": "', traits.name, " #", traits.hexCode, '",');
        }

        /// Dynamic Description ///
        byteString = abi.encodePacked(byteString, '"description": "**Just Backgrounds** (b. 2021)\\n\\n');
        if (_checkIfMatch(traits.special, 'Transparent') || _checkIfMatch(traits.special, 'Meme')) {
            byteString = abi.encodePacked(byteString, "**", traits.name, '**\\n\\n');
        } else {
            byteString = abi.encodePacked(byteString, "**", traits.name, "**, *#", traits.hexCode, '*\\n\\n');
        }
        byteString = abi.encodePacked(byteString, 'Hand crafted SVG, 1920 x 1920 pixels",');

        /// Dynamic SVG ///
        byteString = abi.encodePacked(byteString
            ,'"image": "data:image/svg+xml;utf8,'
            ,'', _generateSvgFromTraits(traits), '",'
        );

        byteString = abi.encodePacked(byteString, '"attributes":[');
        byteString = abi.encodePacked(byteString,'{"trait_type": "Family", "value": "', traits.family, '"},');
        byteString = abi.encodePacked(byteString,'{"trait_type": "Source", "value": "', traits.source, '"},');
        byteString = abi.encodePacked(byteString,'{"trait_type": "Brightness", "value": "', traits.brightness, '"},');
        if (_checkIfMatch(traits.special, 'None')) {
            byteString = abi.encodePacked(byteString,'{"trait_type": "Special", "value": "', traits.special, '"},');
        }
        byteString = abi.encodePacked(byteString,'{"trait_type": "Edition", "display_type": "number", "value": ', mintNumber, ', "max_value": ', _tokenMaxSupply.toString(), '}');
        byteString = abi.encodePacked(byteString, ']');
        byteString = abi.encodePacked(byteString, '}');

        return string(byteString);
    }

    /**
     * @dev Generates SVGs based on traits.
     */
    function _generateSvgFromTraits(Traits.ColorTraits memory traits) private pure returns (bytes memory svg) {

        svg = abi.encodePacked(svg, "<svg xmlns='http://www.w3.org/2000/svg' width='1920' height='1920'>");

        if (_checkIfMatch(traits.special, 'Meme')) {
            svg = abi.encodePacked(svg
                ,"<defs><pattern id='grid' width='20' height='20' patternUnits='userSpaceOnUse'>"
                ,"<rect fill='black' x='0' y='0' width='10' height='10' opacity='0.1'/>"
                ,"<rect fill='white' x='10' y='0' width='10' height='10'/>"
                ,"<rect fill='black' x='10' y='10' width='10' height='10' opacity='0.1'/>"
                ,"<rect fill='white' x='0' y='10' width='10' height='10'/>"
                ,"</pattern></defs>"
                ,"<rect fill='url(#grid)' x='0' y='0' width='100%' height='100%'/>"
            );
        } else if (_checkIfMatch(traits.special, 'Transparent')) {
            svg = abi.encodePacked(svg,"<rect width='100%' height='100%' fill='#FFFFFF' opacity='0'/>");
        } else {
            svg = abi.encodePacked(svg,"<rect width='100%' height='100%' fill='#", traits.hexCode, "'/>");
        }
        
        svg = abi.encodePacked(svg, '</svg>');
    }

    /**
     * @dev Compares strings and returns whether they match.
     */
    function _checkIfMatch(string memory a, string memory b) private pure returns (bool) {
        return (bytes(a).length == bytes(b).length) && keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// Sale Functions ///
    function startSale() external onlyOwner {
        _unpause();
    }

    function pauseSale() external onlyOwner {
        _pause();
    }

    function withdrawAll() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
    }

    /// Override Boilerplate ///
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @author jpegmint.xyz

library Colors {

    /**
     * @dev Compact colorBytes storage.
     * R G B N F T
     * 00ffff00790c
     * R = Red
     * G = Green
     * B = Blue
     * N = Name
     * F = Family
     * T = Source, Brightness, Special
     */
    function getColorMetadata(bytes1 bits) external pure returns (bytes6 colorBytes) {
        
             if (bits == 0x00) colorBytes = 0xf1f7fb5c0017;
        else if (bits == 0x01) colorBytes = 0xecc5c0c9054B;
        else if (bits == 0x02) colorBytes = 0x6c3f19fa0183;
        else if (bits == 0x03) colorBytes = 0x4169e1cd0002;
        else if (bits == 0x04) colorBytes = 0x708090e10202;
        else if (bits == 0x05) colorBytes = 0xfffacd870906;
        else if (bits == 0x06) colorBytes = 0xdecade52065B;
        else if (bits == 0x07) colorBytes = 0xa55e75100123;
        else if (bits == 0x08) colorBytes = 0xd10de55f0623;
        else if (bits == 0x09) colorBytes = 0xf1e57a6e092B;
        else if (bits == 0x0a) colorBytes = 0x00ffff0c0079;
        else if (bits == 0x0b) colorBytes = 0x000000200201;
        else if (bits == 0x0c) colorBytes = 0x0000ff220001;
        else if (bits == 0x0d) colorBytes = 0xff00ff750671;
        else if (bits == 0x0e) colorBytes = 0x8080807a0201;
        else if (bits == 0x0f) colorBytes = 0x0080007b0301;
        else if (bits == 0x10) colorBytes = 0x00ff00950301;
        else if (bits == 0x11) colorBytes = 0x8000009b0101;
        else if (bits == 0x12) colorBytes = 0x000080aa0001;
        else if (bits == 0x13) colorBytes = 0x808000af0301;
        else if (bits == 0x14) colorBytes = 0x800080c30601;
        else if (bits == 0x15) colorBytes = 0xff0000c70701;
        else if (bits == 0x16) colorBytes = 0xc0c0c0de0249;
        else if (bits == 0x17) colorBytes = 0x008080eb0301;
        else if (bits == 0x18) colorBytes = 0xfffffffc0805;
        else if (bits == 0x19) colorBytes = 0xffff00fe0909;
        else if (bits == 0x1a) colorBytes = 0x7fffd40d001A;
        else if (bits == 0x1b) colorBytes = 0x5f9ea02f0002;
        else if (bits == 0x1c) colorBytes = 0x6495ed3a0002;
        else if (bits == 0x1d) colorBytes = 0x00ffff3d007A;
        else if (bits == 0x1e) colorBytes = 0x00008b400002;
        else if (bits == 0x1f) colorBytes = 0x00ced14f0002;
        else if (bits == 0x20) colorBytes = 0x00bfff560002;
        else if (bits == 0x21) colorBytes = 0x1e90ff610002;
        else if (bits == 0x22) colorBytes = 0xadd8e688000A;
        else if (bits == 0x23) colorBytes = 0xe0ffff8a0006;
        else if (bits == 0x24) colorBytes = 0x87cefa91000A;
        else if (bits == 0x25) colorBytes = 0xb0c4de93000A;
        else if (bits == 0x26) colorBytes = 0x0000cd9d0002;
        else if (bits == 0x27) colorBytes = 0x48d1cca30002;
        else if (bits == 0x28) colorBytes = 0x191970a50002;
        else if (bits == 0x29) colorBytes = 0xafeeeeb6000A;
        else if (bits == 0x2a) colorBytes = 0xb0e0e6c2000A;
        else if (bits == 0x2b) colorBytes = 0x87ceebdf000A;
        else if (bits == 0x2c) colorBytes = 0x4682b4e60002;
        else if (bits == 0x2d) colorBytes = 0x40e0d0f8001A;
        else if (bits == 0x2e) colorBytes = 0xffe4c41f0106;
        else if (bits == 0x2f) colorBytes = 0xffebcd210106;
        else if (bits == 0x30) colorBytes = 0xa52a2a2c0102;
        else if (bits == 0x31) colorBytes = 0xdeb8872d018A;
        else if (bits == 0x32) colorBytes = 0xd2691e340102;
        else if (bits == 0x33) colorBytes = 0xfff8dc3b0106;
        else if (bits == 0x34) colorBytes = 0xb8860b420102;
        else if (bits == 0x35) colorBytes = 0xdaa520790102;
        else if (bits == 0x36) colorBytes = 0xffdeada9010A;
        else if (bits == 0x37) colorBytes = 0xcd853fbd0102;
        else if (bits == 0x38) colorBytes = 0xbc8f8fcc0102;
        else if (bits == 0x39) colorBytes = 0x8b4513cf0102;
        else if (bits == 0x3a) colorBytes = 0xf4a460d3010A;
        else if (bits == 0x3b) colorBytes = 0xa0522ddc0102;
        else if (bits == 0x3c) colorBytes = 0xd2b48ce9010A;
        else if (bits == 0x3d) colorBytes = 0xf5deb3fb010A;
        else if (bits == 0x3e) colorBytes = 0xa9a9a943020A;
        else if (bits == 0x3f) colorBytes = 0x2f4f4f4e0202;
        else if (bits == 0x40) colorBytes = 0x6969695e0202;
        else if (bits == 0x41) colorBytes = 0xdcdcdc76020A;
        else if (bits == 0x42) colorBytes = 0xd3d3d38c020A;
        else if (bits == 0x43) colorBytes = 0x778899920202;
        else if (bits == 0x44) colorBytes = 0x7fff0032030A;
        else if (bits == 0x45) colorBytes = 0x008b8b410302;
        else if (bits == 0x46) colorBytes = 0x006400440302;
        else if (bits == 0x47) colorBytes = 0x556b2f470302;
        else if (bits == 0x48) colorBytes = 0x8fbc8f4c030A;
        else if (bits == 0x49) colorBytes = 0x228b22740302;
        else if (bits == 0x4a) colorBytes = 0xadff2f7c030A;
        else if (bits == 0x4b) colorBytes = 0x7cfc0086030A;
        else if (bits == 0x4c) colorBytes = 0x90ee908d030A;
        else if (bits == 0x4d) colorBytes = 0x20b2aa900302;
        else if (bits == 0x4e) colorBytes = 0x32cd32960302;
        else if (bits == 0x4f) colorBytes = 0x66cdaa9c031A;
        else if (bits == 0x50) colorBytes = 0x3cb371a00302;
        else if (bits == 0x51) colorBytes = 0x00fa9aa20302;
        else if (bits == 0x52) colorBytes = 0x6b8e23b00302;
        else if (bits == 0x53) colorBytes = 0x98fb98b5030A;
        else if (bits == 0x54) colorBytes = 0x2e8b57d70302;
        else if (bits == 0x55) colorBytes = 0x00ff7fe40302;
        else if (bits == 0x56) colorBytes = 0x9acd32ff030A;
        else if (bits == 0x57) colorBytes = 0xffd70078094A;
        else if (bits == 0x58) colorBytes = 0xff7f50390402;
        else if (bits == 0x59) colorBytes = 0xff8c00480402;
        else if (bits == 0x5a) colorBytes = 0xff4500b20402;
        else if (bits == 0x5b) colorBytes = 0xff6347f40402;
        else if (bits == 0x5c) colorBytes = 0xff1493550502;
        else if (bits == 0x5d) colorBytes = 0xff69b47e0502;
        else if (bits == 0x5e) colorBytes = 0xffb6c18e050A;
        else if (bits == 0x5f) colorBytes = 0xc71585a40502;
        else if (bits == 0x60) colorBytes = 0xdb7093b70502;
        else if (bits == 0x61) colorBytes = 0xffc0cbbf050A;
        else if (bits == 0x62) colorBytes = 0x8a2be2230602;
        else if (bits == 0x63) colorBytes = 0x8b008b460602;
        else if (bits == 0x64) colorBytes = 0x9932cc490602;
        else if (bits == 0x65) colorBytes = 0x483d8b4d0602;
        else if (bits == 0x66) colorBytes = 0x9400d3500602;
        else if (bits == 0x67) colorBytes = 0x4b0082800602;
        else if (bits == 0x68) colorBytes = 0xe6e6fa840606;
        else if (bits == 0x69) colorBytes = 0xff00ff980672;
        else if (bits == 0x6a) colorBytes = 0xba55d39e0602;
        else if (bits == 0x6b) colorBytes = 0x9370db9f0602;
        else if (bits == 0x6c) colorBytes = 0x7b68eea10602;
        else if (bits == 0x6d) colorBytes = 0xda70d6b30602;
        else if (bits == 0x6e) colorBytes = 0xdda0ddc1060A;
        else if (bits == 0x6f) colorBytes = 0x6a5acde00602;
        else if (bits == 0x70) colorBytes = 0xd8bfd8ef060A;
        else if (bits == 0x71) colorBytes = 0xee82eef9060A;
        else if (bits == 0x72) colorBytes = 0xdc143c3c0702;
        else if (bits == 0x73) colorBytes = 0x8b00004a0702;
        else if (bits == 0x74) colorBytes = 0xe9967a4b070A;
        else if (bits == 0x75) colorBytes = 0xb22222700702;
        else if (bits == 0x76) colorBytes = 0xcd5c5c7f0702;
        else if (bits == 0x77) colorBytes = 0xf08080890702;
        else if (bits == 0x78) colorBytes = 0xffa07a8f070A;
        else if (bits == 0x79) colorBytes = 0xfa8072d20702;
        else if (bits == 0x7a) colorBytes = 0xf0f8ff080806;
        else if (bits == 0x7b) colorBytes = 0xfaebd70b0806;
        else if (bits == 0x7c) colorBytes = 0xf0ffff140806;
        else if (bits == 0x7d) colorBytes = 0xf5f5dc1c0806;
        else if (bits == 0x7e) colorBytes = 0xfffaf0720806;
        else if (bits == 0x7f) colorBytes = 0xf8f8ff770806;
        else if (bits == 0x80) colorBytes = 0xf0fff07d0806;
        else if (bits == 0x81) colorBytes = 0xfffff0810806;
        else if (bits == 0x82) colorBytes = 0xfff0f5850806;
        else if (bits == 0x83) colorBytes = 0xfaf0e6970806;
        else if (bits == 0x84) colorBytes = 0xf5fffaa60806;
        else if (bits == 0x85) colorBytes = 0xffe4e1a70806;
        else if (bits == 0x86) colorBytes = 0xfdf5e6ae0806;
        else if (bits == 0x87) colorBytes = 0xfff5eed80806;
        else if (bits == 0x88) colorBytes = 0xfffafae20806;
        else if (bits == 0x89) colorBytes = 0xf5f5f5fd0806;
        else if (bits == 0x8a) colorBytes = 0xbdb76b45090A;
        else if (bits == 0x8b) colorBytes = 0xf0e68c83090A;
        else if (bits == 0x8c) colorBytes = 0xfafad28b0906;
        else if (bits == 0x8d) colorBytes = 0xffffe0940906;
        else if (bits == 0x8e) colorBytes = 0xffe4b5a80906;
        else if (bits == 0x8f) colorBytes = 0xeee8aab4090A;
        else if (bits == 0x90) colorBytes = 0xffefd5b90906;
        else if (bits == 0x91) colorBytes = 0xffdab9bb090A;
        else if (bits == 0x92) colorBytes = 0xffa500b10408;
        else if (bits == 0x93) colorBytes = 0x663399c60600;
        else if (bits == 0x94) colorBytes = 0xaccede01005B;
        else if (bits == 0x95) colorBytes = 0xbaffed160057;
        else if (bits == 0x96) colorBytes = 0xbedded1a005B;
        else if (bits == 0x97) colorBytes = 0xbeefed1b005B;
        else if (bits == 0x98) colorBytes = 0xdaffed3f0057;
        else if (bits == 0x99) colorBytes = 0xdeeded540257;
        else if (bits == 0x9a) colorBytes = 0xdeface570357;
        else if (bits == 0x9b) colorBytes = 0xdabbed3e065B;
        else if (bits == 0x9c) colorBytes = 0xfacade69055B;
        else if (bits == 0x9d) colorBytes = 0xbeaded18065B;
        else if (bits == 0x9e) colorBytes = 0xefface650957;
        else if (bits == 0x9f) colorBytes = 0x0de55aac0323;
        else if (bits == 0xa0) colorBytes = 0x0ff1cead002B;
        else if (bits == 0xa1) colorBytes = 0x50bbede30023;
        else if (bits == 0xa2) colorBytes = 0x51e57add032B;
        else if (bits == 0xa3) colorBytes = 0x57a71ce50323;
        else if (bits == 0xa4) colorBytes = 0x5ad157d00323;
        else if (bits == 0xa5) colorBytes = 0x5afe57d1032B;
        else if (bits == 0xa6) colorBytes = 0x5a55edd50023;
        else if (bits == 0xa7) colorBytes = 0x5c0ff5d60023;
        else if (bits == 0xa8) colorBytes = 0x5eabedd90023;
        else if (bits == 0xa9) colorBytes = 0x5ecededa002B;
        else if (bits == 0xaa) colorBytes = 0x5eededdb002B;
        else if (bits == 0xab) colorBytes = 0x70a575f20323;
        else if (bits == 0xac) colorBytes = 0x70ffeef3002B;
        else if (bits == 0xad) colorBytes = 0x7007edf50623;
        else if (bits == 0xae) colorBytes = 0x71c7acf0002B;
        else if (bits == 0xaf) colorBytes = 0x71db17f10323;
        else if (bits == 0xb0) colorBytes = 0x7abbede7002B;
        else if (bits == 0xb1) colorBytes = 0x7ac71ce80323;
        else if (bits == 0xb2) colorBytes = 0x7ea5edec0023;
        else if (bits == 0xb3) colorBytes = 0x7ea5e5ed0023;
        else if (bits == 0xb4) colorBytes = 0x7e57edee0623;
        else if (bits == 0xb5) colorBytes = 0xa55e550f0123;
        else if (bits == 0xb6) colorBytes = 0xa55157110123;
        else if (bits == 0xb7) colorBytes = 0xa77e57120123;
        else if (bits == 0xb8) colorBytes = 0xa771c5130623;
        else if (bits == 0xb9) colorBytes = 0xacac1a000923;
        else if (bits == 0xba) colorBytes = 0xacce5502032B;
        else if (bits == 0xbb) colorBytes = 0xace71c03032B;
        else if (bits == 0xbc) colorBytes = 0xac1d1c040723;
        else if (bits == 0xbd) colorBytes = 0xadd1c705002B;
        else if (bits == 0xbe) colorBytes = 0xad0be5060623;
        else if (bits == 0xbf) colorBytes = 0xaffec707032B;
        else if (bits == 0xc0) colorBytes = 0xb0a575240123;
        else if (bits == 0xc1) colorBytes = 0xb0bbed25062B;
        else if (bits == 0xc2) colorBytes = 0xb0bca726022B;
        else if (bits == 0xc3) colorBytes = 0xb0d1e527002B;
        else if (bits == 0xc4) colorBytes = 0xb00b1e280723;
        else if (bits == 0xc5) colorBytes = 0xb055e5290623;
        else if (bits == 0xc6) colorBytes = 0xb1de751d032B;
        else if (bits == 0xc7) colorBytes = 0xbab1e515062B;
        else if (bits == 0xc8) colorBytes = 0xba51c5170623;
        else if (bits == 0xc9) colorBytes = 0xbea575190923;
        else if (bits == 0xca) colorBytes = 0xc0ffee360027;
        else if (bits == 0xcb) colorBytes = 0xc0071e370723;
        else if (bits == 0xcc) colorBytes = 0xc1cada35022B;
        else if (bits == 0xcd) colorBytes = 0xcadd1e2e092B;
        else if (bits == 0xce) colorBytes = 0xcea5ed30062B;
        else if (bits == 0xcf) colorBytes = 0xd00dad620623;
        else if (bits == 0xd0) colorBytes = 0xd077ed630623;
        else if (bits == 0xd1) colorBytes = 0xd1bbed5d062B;
        else if (bits == 0xd2) colorBytes = 0xd155ed600623;
        else if (bits == 0xd3) colorBytes = 0xdeba5e51092B;
        else if (bits == 0xd4) colorBytes = 0xdec1de53052B;
        else if (bits == 0xd5) colorBytes = 0xdefea7580327;
        else if (bits == 0xd6) colorBytes = 0xdefec7590327;
        else if (bits == 0xd7) colorBytes = 0xde7ec75a0523;
        else if (bits == 0xd8) colorBytes = 0xde7e575b0423;
        else if (bits == 0xd9) colorBytes = 0xe57a7e680423;
        else if (bits == 0xda) colorBytes = 0xedd1e564052B;
        else if (bits == 0xdb) colorBytes = 0xeffec7660327;
        else if (bits == 0xdc) colorBytes = 0xf007ed730523;
        else if (bits == 0xdd) colorBytes = 0xf1bbed6d052B;
        else if (bits == 0xde) colorBytes = 0xf177ed710523;
        else if (bits == 0xdf) colorBytes = 0xface756a042B;
        else if (bits == 0xe0) colorBytes = 0xfa5c1a6b0723;
        else if (bits == 0xe1) colorBytes = 0xfa57ed6c0523;
        else if (bits == 0xe2) colorBytes = 0xe5e4e2c0054B;
        else if (bits == 0xe3) colorBytes = 0xb87333380143;
        else if (bits == 0xe4) colorBytes = 0x5a9487ba0343;
        else if (bits == 0xe5) colorBytes = 0xb5a6422a0943;
        else if (bits == 0xe6) colorBytes = 0xcd7f322b0443;
        else if (bits == 0xe7) colorBytes = 0xc1c1bbb8024B;
        else if (bits == 0xe8) colorBytes = 0x50c878670313;
        else if (bits == 0xe9) colorBytes = 0x6c2dc70a0613;
        else if (bits == 0xea) colorBytes = 0x5efb6e82031B;
        else if (bits == 0xeb) colorBytes = 0xfdeef4bc0817;
        else if (bits == 0xec) colorBytes = 0x2554c7d40013;
        else if (bits == 0xed) colorBytes = 0xf62217ce0713;
        else if (bits == 0xee) colorBytes = 0xfaf7f7c50817;
        else if (bits == 0xef) colorBytes = 0xeed1e3ca051B;
        else if (bits == 0xf0) colorBytes = 0xffc20009091B;
        else if (bits == 0xf1) colorBytes = 0xaa915fc40113;
        else if (bits == 0xf2) colorBytes = 0xf8dfa11e098B;
        else if (bits == 0xf3) colorBytes = 0xab9f8d0e0183;
        else if (bits == 0xf4) colorBytes = 0xdeb887ea098B;
        else if (bits == 0xf5) colorBytes = 0x4e312e330183;
        else if (bits == 0xf6) colorBytes = 0xc04000990783;
        else if (bits == 0xf7) colorBytes = 0x824526310183;
        else if (bits == 0xf8) colorBytes = 0xf6d7af6f098B;
        else if (bits == 0xf9) colorBytes = 0xedcaa1be098B;
        else if (bits == 0xfa) colorBytes = 0xa55b53c80183;
        else if (bits == 0xfb) colorBytes = 0x65000ccb0183;
        else if (bits == 0xfc) colorBytes = 0xf1c38e9a018B;
        else if (bits == 0xfd) colorBytes = 0xab8251ab0183;
        else if (bits == 0xfe) colorBytes = 0xfffffff60867;
        else if (bits == 0xff) colorBytes = 0xfffffff70837;

        return colorBytes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @author jpegmint.xyz

library Traits {

    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    struct ColorTraits {
        string hexCode;
        string name;
        string family;
        string source;
        string brightness;
        string special;
    }
    
    function getColorTraits(bytes6 colorBytes) external pure returns (ColorTraits memory traits) {
        traits = ColorTraits(
            _extractColorHexCode(colorBytes),
            _extractColorName(colorBytes),
            _extractColorFamily(colorBytes),
            _extractColorSource(colorBytes),
            _extractColorBrightness(colorBytes),
            _extractColorSpecial(colorBytes)
        );
    }

    function _extractColorHexCode(bytes6 colorBytes) internal pure returns (string memory) {
        uint8 r = uint8(colorBytes[0]);
        uint8 g = uint8(colorBytes[1]);
        uint8 b = uint8(colorBytes[2]);
        bytes memory buffer = new bytes(6);
        buffer[0] = _HEX_SYMBOLS[r >> 4 & 0xf];
        buffer[1] = _HEX_SYMBOLS[r & 0xf];
        buffer[2] = _HEX_SYMBOLS[g >> 4 & 0xf];
        buffer[3] = _HEX_SYMBOLS[g & 0xf];
        buffer[4] = _HEX_SYMBOLS[b >> 4 & 0xf];
        buffer[5] = _HEX_SYMBOLS[b & 0xf];
        return string(buffer);
    }

    function _extractColorFamily(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[4];

             if (bits == 0x00) trait = 'Blue Colors';
        else if (bits == 0x01) trait = 'Brown Colors';
        else if (bits == 0x02) trait = 'Gray Colors';
        else if (bits == 0x03) trait = 'Green Colors';
        else if (bits == 0x04) trait = 'Orange Colors';
        else if (bits == 0x05) trait = 'Pink Colors';
        else if (bits == 0x06) trait = 'Purple Colors';
        else if (bits == 0x07) trait = 'Red Colors';
        else if (bits == 0x08) trait = 'White Colors';
        else if (bits == 0x09) trait = 'Yellow Colors';
    }

    function _extractColorSource(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[5] & 0x03;

             if (bits == 0x00) trait = 'CSS Color';
        else if (bits == 0x01) trait = 'HTML Basic';
        else if (bits == 0x02) trait = 'HTML Extended';
        else if (bits == 0x03) trait = 'Other';
    }

    function _extractColorBrightness(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = (colorBytes[5] >> 2) & 0x03;

             if (bits == 0x00) trait = 'Dark';
        else if (bits == 0x01) trait = 'Light';
        else if (bits == 0x02) trait = 'Medium';
    }

    function _extractColorSpecial(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = (colorBytes[5] >> 4) & 0x0F;

             if (bits == 0x00) trait = 'None';
        else if (bits == 0x01) trait = 'Gems';
        else if (bits == 0x02) trait = 'HEX Word';
        else if (bits == 0x03) trait = 'Meme';
        else if (bits == 0x04) trait = 'Metallic';
        else if (bits == 0x05) trait = 'Real Word';
        else if (bits == 0x06) trait = 'Transparent';
        else if (bits == 0x07) trait = 'Twin';
        else if (bits == 0x08) trait = 'Woods';
    }

    function _extractColorName(bytes6 colorBytes) internal pure returns (string memory trait) {
        bytes1 bits = colorBytes[3];

             if (bits == 0x00) trait = 'Acacia';
        else if (bits == 0x01) trait = 'Accede';
        else if (bits == 0x02) trait = 'Access';
        else if (bits == 0x03) trait = 'Acetic';
        else if (bits == 0x04) trait = 'Acidic';
        else if (bits == 0x05) trait = 'Addict';
        else if (bits == 0x06) trait = 'Adobes';
        else if (bits == 0x07) trait = 'Affect';
        else if (bits == 0x08) trait = 'Alice Blue';
        else if (bits == 0x09) trait = 'Amber';
        else if (bits == 0x0A) trait = 'Amethyst';
        else if (bits == 0x0B) trait = 'Antique White';
        else if (bits == 0x0C) trait = 'Aqua';
        else if (bits == 0x0D) trait = 'Aquamarine';
        else if (bits == 0x0E) trait = 'Ash';
        else if (bits == 0x0F) trait = 'Assess';
        else if (bits == 0x10) trait = 'Assets';
        else if (bits == 0x11) trait = 'Assist';
        else if (bits == 0x12) trait = 'Attest';
        else if (bits == 0x13) trait = 'Attics';
        else if (bits == 0x14) trait = 'Azure';
        else if (bits == 0x15) trait = 'Babies';
        else if (bits == 0x16) trait = 'Baffed';
        else if (bits == 0x17) trait = 'Basics';
        else if (bits == 0x18) trait = 'Beaded';
        else if (bits == 0x19) trait = 'Beasts';
        else if (bits == 0x1A) trait = 'Bedded';
        else if (bits == 0x1B) trait = 'Beefed';
        else if (bits == 0x1C) trait = 'Beige';
        else if (bits == 0x1D) trait = 'Bidets';
        else if (bits == 0x1E) trait = 'Birch';
        else if (bits == 0x1F) trait = 'Bisque';
        else if (bits == 0x20) trait = 'Black';
        else if (bits == 0x21) trait = 'Blanched Almond';
        else if (bits == 0x22) trait = 'Blue';
        else if (bits == 0x23) trait = 'Blue Violet';
        else if (bits == 0x24) trait = 'Boasts';
        else if (bits == 0x25) trait = 'Bobbed';
        else if (bits == 0x26) trait = 'Bobcat';
        else if (bits == 0x27) trait = 'Bodies';
        else if (bits == 0x28) trait = 'Boobie';
        else if (bits == 0x29) trait = 'Bosses';
        else if (bits == 0x2A) trait = 'Brass';
        else if (bits == 0x2B) trait = 'Bronze';
        else if (bits == 0x2C) trait = 'Brown';
        else if (bits == 0x2D) trait = 'Burly Wood';
        else if (bits == 0x2E) trait = 'Caddie';
        else if (bits == 0x2F) trait = 'Cadet Blue';
        else if (bits == 0x30) trait = 'Ceased';
        else if (bits == 0x31) trait = 'Cedar';
        else if (bits == 0x32) trait = 'Chartreuse';
        else if (bits == 0x33) trait = 'Cherry';
        else if (bits == 0x34) trait = 'Chocolate';
        else if (bits == 0x35) trait = 'Cicada';
        else if (bits == 0x36) trait = 'Coffee';
        else if (bits == 0x37) trait = 'Cootie';
        else if (bits == 0x38) trait = 'Copper';
        else if (bits == 0x39) trait = 'Coral';
        else if (bits == 0x3A) trait = 'Cornflower Blue';
        else if (bits == 0x3B) trait = 'Cornsilk';
        else if (bits == 0x3C) trait = 'Crimson';
        else if (bits == 0x3D) trait = 'Cyan';
        else if (bits == 0x3E) trait = 'Dabbed';
        else if (bits == 0x3F) trait = 'Daffed';
        else if (bits == 0x40) trait = 'Dark Blue';
        else if (bits == 0x41) trait = 'Dark Cyan';
        else if (bits == 0x42) trait = 'Dark Goldenrod';
        else if (bits == 0x43) trait = 'Dark Gray';
        else if (bits == 0x44) trait = 'Dark Green';
        else if (bits == 0x45) trait = 'Dark Khaki';
        else if (bits == 0x46) trait = 'Dark Magenta';
        else if (bits == 0x47) trait = 'Dark Olive Green';
        else if (bits == 0x48) trait = 'Dark Orange';
        else if (bits == 0x49) trait = 'Dark Orchid';
        else if (bits == 0x4A) trait = 'Dark Red';
        else if (bits == 0x4B) trait = 'Dark Salmon';
        else if (bits == 0x4C) trait = 'Dark Sea Green';
        else if (bits == 0x4D) trait = 'Dark Slate Blue';
        else if (bits == 0x4E) trait = 'Dark Slate Gray';
        else if (bits == 0x4F) trait = 'Dark Turquoise';
        else if (bits == 0x50) trait = 'Dark Violet';
        else if (bits == 0x51) trait = 'Debase';
        else if (bits == 0x52) trait = 'Decade';
        else if (bits == 0x53) trait = 'Decide';
        else if (bits == 0x54) trait = 'Deeded';
        else if (bits == 0x55) trait = 'Deep Pink';
        else if (bits == 0x56) trait = 'Deep Sky Blue';
        else if (bits == 0x57) trait = 'Deface';
        else if (bits == 0x58) trait = 'Defeat';
        else if (bits == 0x59) trait = 'Defect';
        else if (bits == 0x5A) trait = 'Detect';
        else if (bits == 0x5B) trait = 'Detest';
        else if (bits == 0x5C) trait = 'Diamond';
        else if (bits == 0x5D) trait = 'Dibbed';
        else if (bits == 0x5E) trait = 'Dim Gray';
        else if (bits == 0x5F) trait = 'Diodes';
        else if (bits == 0x60) trait = 'Dissed';
        else if (bits == 0x61) trait = 'Dodger Blue';
        else if (bits == 0x62) trait = 'Doodad';
        else if (bits == 0x63) trait = 'Dotted';
        else if (bits == 0x64) trait = 'Eddies';
        else if (bits == 0x65) trait = 'Efface';
        else if (bits == 0x66) trait = 'Effect';
        else if (bits == 0x67) trait = 'Emerald';
        else if (bits == 0x68) trait = 'Estate';
        else if (bits == 0x69) trait = 'Facade';
        else if (bits == 0x6A) trait = 'Facets';
        else if (bits == 0x6B) trait = 'Fascia';
        else if (bits == 0x6C) trait = 'Fasted';
        else if (bits == 0x6D) trait = 'Fibbed';
        else if (bits == 0x6E) trait = 'Fiesta';
        else if (bits == 0x6F) trait = 'Fir';
        else if (bits == 0x70) trait = 'Fire Brick';
        else if (bits == 0x71) trait = 'Fitted';
        else if (bits == 0x72) trait = 'Floral White';
        else if (bits == 0x73) trait = 'Footed';
        else if (bits == 0x74) trait = 'Forest Green';
        else if (bits == 0x75) trait = 'Fuchsia';
        else if (bits == 0x76) trait = 'Gainsboro';
        else if (bits == 0x77) trait = 'Ghost White';
        else if (bits == 0x78) trait = 'Gold';
        else if (bits == 0x79) trait = 'Goldenrod';
        else if (bits == 0x7A) trait = 'Gray';
        else if (bits == 0x7B) trait = 'Green';
        else if (bits == 0x7C) trait = 'Green Yellow';
        else if (bits == 0x7D) trait = 'Honey Dew';
        else if (bits == 0x7E) trait = 'Hot Pink';
        else if (bits == 0x7F) trait = 'Indian Red';
        else if (bits == 0x80) trait = 'Indigo';
        else if (bits == 0x81) trait = 'Ivory';
        else if (bits == 0x82) trait = 'Jade';
        else if (bits == 0x83) trait = 'Khaki';
        else if (bits == 0x84) trait = 'Lavender';
        else if (bits == 0x85) trait = 'Lavender Blush';
        else if (bits == 0x86) trait = 'Lawn Green';
        else if (bits == 0x87) trait = 'Lemon Chiffon';
        else if (bits == 0x88) trait = 'Light Blue';
        else if (bits == 0x89) trait = 'Light Coral';
        else if (bits == 0x8A) trait = 'Light Cyan';
        else if (bits == 0x8B) trait = 'Light Goldenrod Yellow';
        else if (bits == 0x8C) trait = 'Light Gray';
        else if (bits == 0x8D) trait = 'Light Green';
        else if (bits == 0x8E) trait = 'Light Pink';
        else if (bits == 0x8F) trait = 'Light Salmon';
        else if (bits == 0x90) trait = 'Light Sea Green';
        else if (bits == 0x91) trait = 'Light Sky Blue';
        else if (bits == 0x92) trait = 'Light Slate Gray';
        else if (bits == 0x93) trait = 'Light Steel Blue';
        else if (bits == 0x94) trait = 'Light Yellow';
        else if (bits == 0x95) trait = 'Lime';
        else if (bits == 0x96) trait = 'Lime Green';
        else if (bits == 0x97) trait = 'Linen';
        else if (bits == 0x98) trait = 'Magenta';
        else if (bits == 0x99) trait = 'Mahogany';
        else if (bits == 0x9A) trait = 'Maple';
        else if (bits == 0x9B) trait = 'Maroon';
        else if (bits == 0x9C) trait = 'Medium Aquamarine';
        else if (bits == 0x9D) trait = 'Medium Blue';
        else if (bits == 0x9E) trait = 'Medium Orchid';
        else if (bits == 0x9F) trait = 'Medium Purple';
        else if (bits == 0xA0) trait = 'Medium Sea Green';
        else if (bits == 0xA1) trait = 'Medium Slate Blue';
        else if (bits == 0xA2) trait = 'Medium Spring Green';
        else if (bits == 0xA3) trait = 'Medium Turquoise';
        else if (bits == 0xA4) trait = 'Medium Violet Red';
        else if (bits == 0xA5) trait = 'Midnight Blue';
        else if (bits == 0xA6) trait = 'Mint Cream';
        else if (bits == 0xA7) trait = 'Misty Rose';
        else if (bits == 0xA8) trait = 'Moccasin';
        else if (bits == 0xA9) trait = 'Navajo White';
        else if (bits == 0xAA) trait = 'Navy';
        else if (bits == 0xAB) trait = 'Oak';
        else if (bits == 0xAC) trait = 'Odessa';
        else if (bits == 0xAD) trait = 'Office';
        else if (bits == 0xAE) trait = 'Old Lace';
        else if (bits == 0xAF) trait = 'Olive';
        else if (bits == 0xB0) trait = 'Olive Drab';
        else if (bits == 0xB1) trait = 'Orange';
        else if (bits == 0xB2) trait = 'Orange Red';
        else if (bits == 0xB3) trait = 'Orchid';
        else if (bits == 0xB4) trait = 'Pale Goldenrod';
        else if (bits == 0xB5) trait = 'Pale Green';
        else if (bits == 0xB6) trait = 'Pale Turquoise';
        else if (bits == 0xB7) trait = 'Pale Violet Red';
        else if (bits == 0xB8) trait = 'Palladium';
        else if (bits == 0xB9) trait = 'Papaya Whip';
        else if (bits == 0xBA) trait = 'Patina';
        else if (bits == 0xBB) trait = 'Peach Puff';
        else if (bits == 0xBC) trait = 'Pearl';
        else if (bits == 0xBD) trait = 'Peru';
        else if (bits == 0xBE) trait = 'Pine';
        else if (bits == 0xBF) trait = 'Pink';
        else if (bits == 0xC0) trait = 'Platinum';
        else if (bits == 0xC1) trait = 'Plum';
        else if (bits == 0xC2) trait = 'Powder Blue';
        else if (bits == 0xC3) trait = 'Purple';
        else if (bits == 0xC4) trait = 'Pyrite';
        else if (bits == 0xC5) trait = 'Quartz';
        else if (bits == 0xC6) trait = 'Rebecca Purple';
        else if (bits == 0xC7) trait = 'Red';
        else if (bits == 0xC8) trait = 'Redwood';
        else if (bits == 0xC9) trait = 'Rose Gold';
        else if (bits == 0xCA) trait = 'Rose Quartz';
        else if (bits == 0xCB) trait = 'Rosewood';
        else if (bits == 0xCC) trait = 'Rosy Brown';
        else if (bits == 0xCD) trait = 'Royal Blue';
        else if (bits == 0xCE) trait = 'Ruby';
        else if (bits == 0xCF) trait = 'Saddle Brown';
        else if (bits == 0xD0) trait = 'Sadist';
        else if (bits == 0xD1) trait = 'Safest';
        else if (bits == 0xD2) trait = 'Salmon';
        else if (bits == 0xD3) trait = 'Sandy Brown';
        else if (bits == 0xD4) trait = 'Sapphire';
        else if (bits == 0xD5) trait = 'Sassed';
        else if (bits == 0xD6) trait = 'Scoffs';
        else if (bits == 0xD7) trait = 'Sea Green';
        else if (bits == 0xD8) trait = 'Sea Shell';
        else if (bits == 0xD9) trait = 'Seabed';
        else if (bits == 0xDA) trait = 'Secede';
        else if (bits == 0xDB) trait = 'Seeded';
        else if (bits == 0xDC) trait = 'Sienna';
        else if (bits == 0xDD) trait = 'Siesta';
        else if (bits == 0xDE) trait = 'Silver';
        else if (bits == 0xDF) trait = 'Sky Blue';
        else if (bits == 0xE0) trait = 'Slate Blue';
        else if (bits == 0xE1) trait = 'Slate Gray';
        else if (bits == 0xE2) trait = 'Snow';
        else if (bits == 0xE3) trait = 'Sobbed';
        else if (bits == 0xE4) trait = 'Spring Green';
        else if (bits == 0xE5) trait = 'Static';
        else if (bits == 0xE6) trait = 'Steel Blue';
        else if (bits == 0xE7) trait = 'Tabbed';
        else if (bits == 0xE8) trait = 'Tactic';
        else if (bits == 0xE9) trait = 'Tan';
        else if (bits == 0xEA) trait = 'Teak';
        else if (bits == 0xEB) trait = 'Teal';
        else if (bits == 0xEC) trait = 'Teased';
        else if (bits == 0xED) trait = 'Teases';
        else if (bits == 0xEE) trait = 'Tested';
        else if (bits == 0xEF) trait = 'Thistle';
        else if (bits == 0xF0) trait = 'Tictac';
        else if (bits == 0xF1) trait = 'Tidbit';
        else if (bits == 0xF2) trait = 'Toasts';
        else if (bits == 0xF3) trait = 'Toffee';
        else if (bits == 0xF4) trait = 'Tomato';
        else if (bits == 0xF5) trait = 'Tooted';
        else if (bits == 0xF6) trait = 'Transparent';
        else if (bits == 0xF7) trait = 'Transparent?';
        else if (bits == 0xF8) trait = 'Turquoise';
        else if (bits == 0xF9) trait = 'Violet';
        else if (bits == 0xFA) trait = 'Walnut';
        else if (bits == 0xFB) trait = 'Wheat';
        else if (bits == 0xFC) trait = 'White';
        else if (bits == 0xFD) trait = 'White Smoke';
        else if (bits == 0xFE) trait = 'Yellow';
        else if (bits == 0xFF) trait = 'Yellow Green';
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

