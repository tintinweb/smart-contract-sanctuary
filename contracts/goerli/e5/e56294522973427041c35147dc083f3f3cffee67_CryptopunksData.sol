/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity 0.7.6;

contract CryptopunksData {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = '</svg>';

    bytes private palette;
    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    mapping(uint64 => uint32) private composites;
    mapping(uint8 => bytes) private punks; // Grouped in sets of 100

    address payable internal deployer;
    bool private contractSealed = false;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setPalette(bytes memory _palette) external onlyDeployer unsealed {
        palette = _palette;
    }

    function addAsset(uint8 index, bytes memory encoding, string memory name) external onlyDeployer unsealed {
        assets[index] = encoding;
        assetNames[index] = name;
    }

    function addComposites(uint64 key1, uint32 value1, uint64 key2, uint32 value2, uint64 key3, uint32 value3, uint64 key4, uint32 value4) external onlyDeployer unsealed {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }

    function addPunks(uint8 index, bytes memory _punks) external onlyDeployer unsealed {
        punks[index] = _punks;
    }

    function sealContract() external onlyDeployer unsealed {
        contractSealed = true;
    }

    /*
    function punkImageSvgOld(uint16 index) external view returns (string memory svg) {
        require(index >= 0 && index < 10000);
        uint8 cell = uint8(index / 100);
        uint offset = (index % 100) * 8;
        svg = string(abi.encodePacked(SVG_HEADER));
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[cell][offset + j]);
            if (asset > 0) {
                bytes storage a = assets[asset];
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint x = uint(uint8(a[i * 3]) & 0xF0) >> 4;
                    uint y = uint(uint8(a[i * 3]) & 0xF);
                    uint color = uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4;
                    uint black = uint(uint8(a[i * 3 + 2]) & 0xF);
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            if (color & (1 << (dx * 2 + dy)) != 0) {
                                svg = string(abi.encodePacked(svg,
                                '<rect x="', toString(2 * x + dx), '" y="', toString(2 * y + dy),'" width="1" height="1" shape-rendering="crispEdges" fill="#', paletteEntry(uint8(a[i * 3 + 1])),'"/>'));
                            } else if (black & (1 << (dx * 2 + dy)) != 0) {
                                svg = string(abi.encodePacked(svg,
                                    '<rect x="', toString(2 * x + dx), '" y="', toString(2 * y + dy),'" width="1" height="1" shape-rendering="crispEdges" fill="black"/>'));
                            }
                        }
                    }
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }
    */

    function punkImageSvg(uint16 index) external view returns (string memory svg) {
        bytes memory pixels = punkImage(index);
        svg = string(abi.encodePacked(SVG_HEADER));
        bytes memory buffer = new bytes(8);
        for (uint y = 0; y < 24; y++) {
            for (uint x = 0; x < 24; x++) {
                uint p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(abi.encodePacked(svg,
                        '<rect x="', toString(x), '" y="', toString(y),'" width="1" height="1" shape-rendering="crispEdges" fill="#', string(buffer),'"/>'));
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function punkImage(uint16 index) public view returns (bytes memory) {
        require(index >= 0 && index < 10000);
        bytes memory pixels = new bytes(2304); // 24 x 24 x 4
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[uint8(index / 100)][(index % 100) * 8 + j]);
            if (asset > 0) {
                bytes storage a = assets[asset];
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,     // x
                        uint(uint8(a[i * 3]) & 0xF),           // y
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4, // color
                        uint(uint8(a[i * 3 + 2]) & 0xF)        // black
                    ];
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            uint p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(a[i * 3 + 1],
                                        pixels[p],
                                        pixels[p + 1],
                                        pixels[p + 2],
                                        pixels[p + 3]
                                    );
                                pixels[p] = c[0];
                                pixels[p+1] = c[1];
                                pixels[p+2] = c[2];
                                pixels[p+3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p+1] = 0;
                                pixels[p+2] = 0;
                                pixels[p+3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }

    function punkAttributes(uint16 index) external view returns (string memory text) {
        require(index >= 0 && index < 10000);
        uint8 cell = uint8(index / 100);
        uint offset = (index % 100) * 8;
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[cell][offset + j]);
            if (asset > 0) {
                if (j > 0) {
                    text = string(abi.encodePacked(text, ", ", assetNames[asset]));
                } else {
                    text = assetNames[asset];
                }
            } else {
                break;
            }
        }
    }

    function paletteEntry(uint8 index) internal view returns (string memory) {
        bytes memory buffer = new bytes(8);
        uint i = uint(index) * 4;
        for (uint j = 0; j < 4; j++) {
            uint8 value = uint8(palette[i++]);
            buffer[j * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            buffer[j * 2] = _HEX_SYMBOLS[value & 0xf];
        }
        return string(buffer);
    }

    function composite(byte index, byte yr, byte yg, byte yb, byte ya) internal view returns (bytes4 rgba) {
        uint x = uint(uint8(index)) * 4; // x = v[0]
        uint yAlpha = uint(uint8(ya)); // yAlpha = v[1]
        uint xAlpha = uint(uint8(palette[x + 3])); // xAlpha = v[2]
        if (yAlpha == 0 || xAlpha == 0xFF) {
            rgba = bytes4(uint32(
                    (uint(uint8(palette[x])) << 24) |
                    (uint(uint8(palette[x+1])) << 16) |
                    (uint(uint8(palette[x+2])) << 8) |
                    xAlpha
                ));
        } else {
            uint64 key =
                (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(uint8(palette[x + 3])) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    }

    /*
    // Composite palette index on top of existing r, g, b, a values
    function compositeOld(byte index, byte yr, byte yg, byte yb, byte ya) internal view returns (bytes4 rgba) {
        uint[4] memory v = [
            uint(uint8(index)) * 4, // x = v[0]
            uint(uint8(ya)), // yAlpha = v[1]
            0, // xAlpha = v[2]
            0 // outAlpha = v[3]
        ];
        v[2] = uint(uint8(palette[v[0] + 3]));
        if (v[1] == 0 || v[2] == 0xFF) {
            rgba = bytes4(uint32(
                (uint(uint8(palette[v[0]])) << 24) |
                (uint(uint8(palette[v[0]+1])) << 16) |
                (uint(uint8(palette[v[0]+2])) << 8) |
                v[2]
                ));
        } else {
            v[1] = (v[1] * (0xFF - v[2]) + 0x80) / 0xFF;
            v[3] = v[2] + v[1];
            uint result = (((uint8(palette[v[0]]) * v[2] + uint8(yr) * v[1] + (v[3] >> 1)) / v[3]) << 24) |
            (((uint8(palette[v[0]+1]) * v[2] + uint8(yg) * v[1] + (v[3] >> 1)) / v[3]) << 16) |
            (((uint8(palette[v[0]+2]) * v[2] + uint8(yb) * v[1] + (v[3] >> 1)) / v[3]) << 8) |
            v[3];
            rgba = bytes4(uint32(
                result
            ));
        }
    }
    */

    //// String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

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

}