/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

abstract contract Composites {
   function composite(byte index, byte yr, byte yg, byte yb, byte ya) virtual external view returns (bytes4 rgba);
}

abstract contract Assets {
    function getAsset(uint8 index) virtual external view returns (bytes memory encoding);
    function getAssetName(uint8 index) virtual external view returns (string memory text);
}

abstract contract OGPunks1 {
    function getAsset(uint16 punkIndex, uint8 assetIndex) virtual external view returns (uint8);
}

abstract contract OGPunks2 {
    function getAsset(uint16 punkIndex, uint8 assetIndex) virtual external view returns (uint8);
}

abstract contract OGPunks3 {
    function getAsset(uint16 punkIndex, uint8 assetIndex) virtual external view returns (uint8);
}

abstract contract OGPunks4 {
    function getAsset(uint16 punkIndex, uint8 assetIndex) virtual external view returns (uint8);
}

contract LostPunks {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = '</svg>';

    Composites private composites;
    Assets private assets;
    OGPunks1 private ogPunks1;
    OGPunks2 private ogPunks2;
    OGPunks3 private ogPunks3;
    OGPunks4 private ogPunks4;

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
        composites = Composites(0xEbaa058DCE7C4B3439Afae9Ac19A131000eB94e8);
        assets = Assets(0xdD89Fcab78Fb837D06C8973442de17e48f58F7D3);
        ogPunks1 = OGPunks1(0x3d9D3cb9d414638Cf4a2cCAa284c9192dAA1774b);
        ogPunks2 = OGPunks2(0xD52Bf1c58aC593d8901a03432B51575a406e1082);
        ogPunks3 = OGPunks3(0x63eD8Fb96bcB37a3e2FBA2502b6E52Bb26293486);
        ogPunks4 = OGPunks4(0xac422b438CdBBf9FEAAEF48c383BB429591851Ea);
    }
    
    function destroy() external onlyDeployer unsealed {
        selfdestruct(deployer);
    }
    
    function sealContract() external onlyDeployer unsealed {
        contractSealed = true;
    }

    function composite(byte index, byte yr, byte yg, byte yb, byte ya) internal view returns (bytes4 rgba) {
        rgba = composites.composite(index, yr, yg, yb, ya);
    }
    
    function getAsset(uint8 index) internal view returns (bytes memory encoding) {
        encoding = assets.getAsset(index);
    }
    
    function getAssetName(uint8 index) internal view returns (string memory text) {
        text = assets.getAssetName(index);
    }
    
    function getPunkAsset(uint16 punkIndex, uint8 assetIndex) internal view returns (uint8) {
        if (punkIndex < 2500) {
            return ogPunks1.getAsset(punkIndex, assetIndex);
        } else if (punkIndex < 5000) {
            return ogPunks2.getAsset(punkIndex, assetIndex);
        } else if (punkIndex < 7500) {
            return ogPunks3.getAsset(punkIndex, assetIndex);
        } else if (punkIndex < 10000) {
            return ogPunks4.getAsset(punkIndex, assetIndex);
        } else {
            return 0;
        }
    }

    function punkImage(uint16 index) public view returns (bytes memory) {
        require(index >= 0 && index < 10000);
        bytes memory pixels = new bytes(2304);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = getPunkAsset(index, j);
            if (asset > 0) {
                bytes memory a = getAsset(asset);
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3]) & 0xF),
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3 + 2]) & 0xF)
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
    
    /**
     * The Cryptopunk image for the given index, in SVG format.
     * In the SVG, each "pixel" is represented as a 1x1 rectangle.
     * @param index the punk index, 0 <= index < 10000
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

    /**
     * The Cryptopunk attributes for the given index.
     * The attributes are a comma-separated list in UTF-8 string format.
     * The first entry listed is not technically an attribute, but the "head type" of the Cryptopunk.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkAttributes(uint16 index) external view returns (string memory text) {
        require(index >= 0 && index < 10000);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = getPunkAsset(index, j);
            if (asset > 0) {
                if (j > 0) {
                    text = string(abi.encodePacked(text, ", ", getAssetName(asset)));
                } else {
                    text = getAssetName(asset);
                }
            } else {
                break;
            }
        }
    }

    //// String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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