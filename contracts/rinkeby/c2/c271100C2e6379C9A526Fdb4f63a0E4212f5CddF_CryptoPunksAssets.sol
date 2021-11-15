// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CryptoPunksAssets {

    enum Type { Kind, Face, Ear, Neck, Beard, Hair, Eyes, Mouth, Smoke, Nose }
    
    bytes private palette;
    mapping(uint64 => uint32) private composites;

    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    mapping(uint8 => Type) private assetTypes;
    mapping(string => uint8) private maleAssets;
    mapping(string => uint8) private femaleAssets;
    
    function composite(bytes1 index, bytes1 yr, bytes1 yg, bytes1 yb, bytes1 ya) external view returns (bytes4 rgba) {
        uint x = uint(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        if (xAlpha == 0xFF) {
            rgba = bytes4(
                    (uint32(uint8(palette[x])) << 24) |
                    (uint32(uint8(palette[x+1])) << 16) |
                    (uint32(uint8(palette[x+2])) << 8) |
                    uint32(xAlpha)
                );
        } else {
            uint64 key =
                (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(xAlpha) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    }
    
    function getAsset(uint8 index) external view returns (bytes memory encoding) {
        encoding = assets[index];
    }
    
    function getAssetName(uint8 index) external view returns (string memory text) {
        text = assetNames[index];        
    }

    function getAssetType(uint8 index) external view returns (uint8) {
        return uint8(assetTypes[index]);
    }

    function getAssetIndex(string calldata text, bool isMale) external view returns (uint8) {
        return isMale ? maleAssets[text] : femaleAssets[text];        
    }

    function getMappedAsset(uint8 index, bool toMale) external view returns (uint8) {
        return toMale ? maleAssets[assetNames[index]] : femaleAssets[assetNames[index]];
    }
    
    function setPalette(bytes memory encoding) external {
        palette = encoding;
    }

    function addComposites(uint64 key1, uint32 value1, uint64 key2, uint32 value2, uint64 key3, uint32 value3, uint64 key4, uint32 value4) external {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }
    
    function addAsset(uint8 index, Type assetType, bool isMale, string memory name, bytes memory encoding) external {
        assets[index] = encoding;
        assetNames[index] = name;
        assetTypes[index] = assetType;
        if (isMale) {
            maleAssets[name] = index;
        } else {
            femaleAssets[name] = index;
        }
    }
}

