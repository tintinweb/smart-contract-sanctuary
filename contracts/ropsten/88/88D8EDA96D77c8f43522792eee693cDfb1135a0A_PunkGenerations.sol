/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

abstract contract Composites {
   function composite(byte index, byte yr, byte yg, byte yb, byte ya) virtual external view returns (bytes4 rgba);
}

abstract contract Assets {
    function getAsset(uint8 index) virtual external view returns (bytes memory encoding);
    function getAssetName(uint8 index) virtual external view returns (string memory text);
    function getAssetType(uint8 index) virtual external view returns (uint8);
    function getAssetIndex(string calldata text, bool isMale) virtual external view returns (uint8);
    function getMappedAsset(uint8 index, bool toMale) virtual external view returns (uint8);
}

abstract contract CryptoPunksData {
    function punkAttributes(uint16 index) virtual external view returns (string memory text);
}

contract PunkGenerations {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = '</svg>';

    Composites private composites;
    Assets private assets;
    CryptoPunksData private cryptoPunksData;

    uint16 private punksCount;
    mapping(uint16 => bytes) private punks;
    mapping(uint16 => uint16) private fatherMapping;
    mapping(uint16 => uint16) private motherMapping;
    mapping(uint16 => uint16) private siblingMapping;
    mapping(uint16 => uint16) private generationMapping;
    mapping(uint16 => uint16) private child1Mapping;
    mapping(uint16 => uint16) private child2Mapping;

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
        assets = Assets(0x6759C76542a3de7267122887B77838959EDad620);
        cryptoPunksData = CryptoPunksData(0x5EbAa52C761B4447698bE5517Fc525eA5e6699CF);
        punksCount = 10000;
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
    
    function getAssetType(uint8 index) internal view returns (uint8) {
        return assets.getAssetType(index);
    }
    
    function getMappedAsset(uint8 index, bool toMale) internal view returns (uint8) {
        return assets.getMappedAsset(index, toMale);
    }

    function random(uint seed) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }
    
    struct TraitInfo {
        bool isMale;
        bool isDifferent;
        uint8 assetIndex;
        uint8 earringIndex;
        uint8 cigaretteIndex;
    }
    
    function breedPunkAssets(uint16 fatherIndex, uint16 motherIndex) internal view returns (bytes memory childAssets) {
        require(fatherIndex >= 0 && fatherIndex < 10000 + punksCount);
        require(motherIndex >= 0 && motherIndex < 10000 + punksCount);
        bytes memory fatherAssets = getPunkAssets(fatherIndex);
        bytes memory motherAssets = getPunkAssets(motherIndex);
        
        TraitInfo memory info;
        uint8 fa = uint8(fatherAssets[0]);
        require(fa >= 1 && fa < 5);
        uint8 ma = uint8(motherAssets[0]);
        require(ma >= 5 && ma < 9);
        
        childAssets = new bytes(8);
        uint rand = random(punksCount);

        uint8 low = (ma - 5) < (fa - 1) ? (ma - 5) : (fa - 1);
        uint8 high = (ma - 5) < (fa - 1) ? (fa - 1) : (ma - 5);
        info.isMale = (rand % 2) == 0;
        rand = random(rand);
        byte punkType = byte((info.isMale ? 1 : 5) + uint8(low + (rand % (high + 1 - low))));
        rand = random(rand);
        childAssets[info.assetIndex++] = punkType;
        info.isDifferent = uint8(punkType) != (info.isMale ? fa : ma);
        
        uint8[10] memory fatherTraits;
        uint8[10] memory motherTraits;
        for (uint8 j = 1; j < 8; ++j) {
            fa = uint8(fatherAssets[j]);
            fatherTraits[getAssetType(fa)] = fa;
            ma = uint8(motherAssets[j]);
            motherTraits[getAssetType(ma)] = ma;
        }
        
        for (uint8 j = 1; j < 10 && info.assetIndex < 8; ++j) {
            fa = info.isMale ? motherTraits[j] : fatherTraits[j]; // other parent traits
            ma = info.isMale ? fatherTraits[j] : motherTraits[j]; // same parent traits
            uint8 value = fa > 0 ? getMappedAsset(fa, info.isMale) : 0;
            if ((ma != 0) && ((value == 0) || (rand % 2 == 0))) {
                value = ma;
            }
            rand = random(rand);
            if (value != ma) {
                info.isDifferent = true;
            } else if ((value == 61) || (value == 125)) { 
                info.earringIndex = info.assetIndex; 
            } else if ((value == 19) || (value == 115)) { 
                info.cigaretteIndex = info.assetIndex; 
            }
            if (value > 0) {
                childAssets[info.assetIndex++] = byte(value);
            }
        }

        if (!info.isDifferent) {
            if (info.cigaretteIndex > 0) {
                for (uint8 j = info.cigaretteIndex; j < 8; ++j) {
                    childAssets[j] = j < 7 ? childAssets[j+1] : byte(0);
                }
            } else if (info.earringIndex > 0) {
                for (uint8 j = info.earringIndex; j < 8; ++j) {
                    childAssets[j] = j < 7 ? childAssets[j+1] : byte(0);
                }
            } else if (info.assetIndex < 7) {
                if (rand % 2 == 0) {
                    childAssets[info.assetIndex++] = byte(info.isMale ? 61 : 125);
                } else {
                    childAssets[info.assetIndex++] = byte(info.isMale ? 19 : 115);
                }
            }
        }
    }
    
    function mintChildPunks(uint16 fatherIndex, uint16 motherIndex) external {
        require(child1Mapping[fatherIndex] == 0);
        require(child1Mapping[motherIndex] == 0);
        require(siblingMapping[motherIndex] != fatherIndex);

        uint16 fatherGen = generationMapping[fatherIndex];
        uint16 motherGen = generationMapping[motherIndex];
        uint16 childGen = fatherGen > motherGen ? fatherGen + 1 : motherGen + 1;
        
        uint16 child1Index = punksCount;
        punks[punksCount++] = breedPunkAssets(fatherIndex, motherIndex);
        fatherMapping[child1Index] = fatherIndex;
        motherMapping[child1Index] = motherIndex;
        generationMapping[child1Index] = childGen;

        uint16 child2Index = punksCount;
        punks[punksCount++] = breedPunkAssets(fatherIndex, motherIndex);
        fatherMapping[child2Index] = fatherIndex;
        motherMapping[child2Index] = motherIndex;
        generationMapping[child2Index] = childGen;
        
        child1Mapping[fatherIndex] = child1Index;
        child2Mapping[fatherIndex] = child2Index;
        child1Mapping[motherIndex] = child1Index;
        child2Mapping[motherIndex] = child2Index;
        siblingMapping[child1Index] = child2Index;
        siblingMapping[child2Index] = child1Index;
    }

    function previewChildPunkAttributes(uint16 fatherIndex, uint16 motherIndex) external view returns (string memory text) {
        return punkAssetsAttributes(breedPunkAssets(fatherIndex, motherIndex), punksCount);
    }
    
    function previewChildPunkImageSvg(uint16 fatherIndex, uint16 motherIndex) external view returns (string memory svg) {
        return punkAssetsImageSvg(breedPunkAssets(fatherIndex, motherIndex), punksCount);
    }
    
    function getPunkAssets(uint16 index) internal view returns (bytes memory punkAssets) {
        if (index < 10000) {
            punkAssets = parseAssets(cryptoPunksData.punkAttributes(index));
        } else {
            punkAssets = new bytes(8);
            for (uint8 j = 0; j < 8; j++) {
                punkAssets[j] = punks[index][j];
            }
        }
    }

    function punkAssetsAttributes(bytes memory punkAssets, uint16 index) internal view returns (string memory text) {
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
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
        if (index < punksCount) {
            text = string(abi.encodePacked(text, ", Generation: ", toString(generationMapping[index])));
            uint16 father = fatherMapping[index]; 
            text = string(abi.encodePacked(text, ", Father: ", father > 0 ? toString(father) : "-"));
            uint16 mother = motherMapping[index]; 
            text = string(abi.encodePacked(text, ", Mother: ", mother > 0 ? toString(mother) : "-"));
            uint16 sibling = siblingMapping[index]; 
            text = string(abi.encodePacked(text, ", Sibling: ", sibling > 0 ? toString(sibling) : "-"));
            uint16 child1 = child1Mapping[index]; 
            text = string(abi.encodePacked(text, ", Child 1: ", child1 > 0 ? toString(child1) : "-"));
            uint16 child2 = child2Mapping[index]; 
            text = string(abi.encodePacked(text, ", Child 2: ", child2 > 0 ? toString(child2) : "-"));
        }
    }

    function borderImage(bytes memory pixels, bytes4 color) internal pure {
        for (uint i = 0; i < 24; i++) {
            bool previousOnX = false;
            bool previousOnY = false;
            for (uint j = 0; j < 24; j++) {
                uint pX = (i * 24 * 4) + (j * 4);
                uint pY = (j * 24 * 4) + (i * 4);
                bool onX = (pixels[pX+3] != 0x0) &&
                ((pixels[pX] != color[0]) || (pixels[pX+1] != color[1]) || (pixels[pX+2] != color[2]) || (pixels[pX+3] != color[3]));
                bool onY = (pixels[pY+3] != 0x0) &&
                ((pixels[pY] != color[0]) || (pixels[pY+1] != color[1]) || (pixels[pY+2] != color[2]) || (pixels[pY+3] != color[3]));
                if ((onX != previousOnX) && (j > 0)) {
                    if (onX) {
                        pX -= 4;
                    }
                    pixels[pX] = color[0];
                    pixels[pX+1] = color[1];
                    pixels[pX+2] = color[2];
                    pixels[pX+3] = color[3];
                }
                if ((onY != previousOnY) && (j > 0)) {
                    if (onY) {
                        pY -= 24*4;
                    }
                    pixels[pY] = color[0];
                    pixels[pY+1] = color[1];
                    pixels[pY+2] = color[2];
                    pixels[pY+3] = color[3];
                }
                previousOnX = onX;
                previousOnY = onY;
            }
        }
    }

    function punkAssetsImage(bytes memory punkAssets, uint16 index) internal view returns (bytes memory) {
        bytes memory pixels = new bytes(2304);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
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
        if ((index >= 10000) && (index < punksCount)) {
            uint16 generation = generationMapping[index];
            bytes4 color = 0xff04b4ff; // pink
            if (generation == 1) {
                color = 0x66a670ff; // green
            } else if (generation == 2) {
                color = 0x638596ff; // blue
            } else if (generation == 3) {
                color = 0x8e6fb6ff; // purple
            } else if (generation == 4) {
                color = 0x95554fff; // red
            }
            borderImage(pixels, color);
        }
        return pixels;
    }

    function punkAssetsImageSvg(bytes memory punkAssets, uint16 index) internal view returns (string memory svg) {
        bytes memory pixels = punkAssetsImage(punkAssets, index);
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

    function punkAttributes(uint16 index) external view returns (string memory text) {
        require(index >= 0 && index < punksCount);
        text = punkAssetsAttributes(getPunkAssets(index), index);
    }

    function punkImage(uint16 index) external view returns (bytes memory) {
        require(index >= 0 && index < punksCount);
        return punkAssetsImage(getPunkAssets(index), index);
    }
    
    function punkImageSvg(uint16 index) external view returns (string memory svg) {
        require(index >= 0 && index < punksCount);
        svg = punkAssetsImageSvg(getPunkAssets(index), index);
    }
    
    function bufferToString(bytes memory buffer, uint length) internal pure returns (string memory text) {
        bytes memory stringBuffer = new bytes(length);
        for (uint i = 0; i < length; ++i) {
            stringBuffer[i] = buffer[i];
        }
        text = string(stringBuffer);
    }
    
    function parseAssets(string memory attributes) internal view returns (bytes memory punkAssets) {
        punkAssets = new bytes(8);
        bytes memory stringAsBytes = bytes(attributes);
        bytes memory buffer = new bytes(stringAsBytes.length);

        uint index = 0;
        uint j = 0;
        bool isMale;
        for (uint i = 0; i < stringAsBytes.length; i++) {
            if (i == 0) {
                isMale = (stringAsBytes[i] != "F");
            }
            if (stringAsBytes[i] != ",") {
                buffer[j++] = stringAsBytes[i];
            } else {
                punkAssets[index++] = byte(assets.getAssetIndex(bufferToString(buffer, j), isMale));
                i++; // skip space
                j = 0;
            }
        }
        if (j > 0) {
            punkAssets[index++] = byte(assets.getAssetIndex(bufferToString(buffer, j), isMale));
        }
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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