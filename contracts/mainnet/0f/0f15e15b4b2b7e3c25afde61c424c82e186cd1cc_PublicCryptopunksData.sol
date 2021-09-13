pragma solidity ^0.8.0;

import "./CryptopunksData.sol";

/**
 * Public
 *   ____                  _                          _          ____        _
 *  / ___|_ __ _   _ _ __ | |_ ___  _ __  _   _ _ __ | | _____  |  _ \  __ _| |_ __ _
 * | |   | '__| | | | '_ \| __/ _ \| '_ \| | | | '_ \| |/ / __| | | | |/ _` | __/ _` |
 * | |___| |  | |_| | |_) | || (_) | |_) | |_| | | | |   <\__ \ | |_| | (_| | || (_| |
 *  \____|_|   \__, | .__/ \__\___/| .__/ \__,_|_| |_|_|\_\___/ |____/ \__,_|\__\__,_|
 *             |___/|_|            |_|
 *
 * On-chain Public Cryptopunk assets.
 *
 * This contract holds the public asset data for the Cryptopunks on-chain.
 */
contract PublicCryptopunksData {
    string public constant SVG_HEADER =
        'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string public constant SVG_FOOTER = "</svg>";

    CryptopunksData public cryptopunksData;
    bytes public palette;
    mapping(uint8 => bytes) public assets;
    mapping(uint8 => string) public assetNames;
    mapping(uint64 => uint32) public composites;

    address internal deployer;
    bool private contractSealed = false;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    constructor(CryptopunksData _cryptopunksData) {
        deployer = msg.sender;
        cryptopunksData = _cryptopunksData;
    }

    function setPalette(bytes memory _palette) external onlyDeployer unsealed {
        palette = _palette;
    }

    function addAsset(
        uint8 index,
        bytes memory encoding,
        string memory name
    ) external onlyDeployer unsealed {
        assets[index] = encoding;
        assetNames[index] = name;
    }

    function addComposites(
        uint64 key1,
        uint32 value1,
        uint64 key2,
        uint32 value2,
        uint64 key3,
        uint32 value3,
        uint64 key4,
        uint32 value4
    ) external onlyDeployer unsealed {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }

    function sealContract() external onlyDeployer unsealed {
        contractSealed = true;
    }

    function composite(
        bytes1 index,
        bytes1 yr,
        bytes1 yg,
        bytes1 yb,
        bytes1 ya
    ) internal view returns (bytes4 rgba) {
        uint256 x = uint256(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        if (xAlpha == 0xFF) {
            rgba = bytes4(
                uint32(
                    (uint256(uint8(palette[x])) << 24) |
                        (uint256(uint8(palette[x + 1])) << 16) |
                        (uint256(uint8(palette[x + 2])) << 8) |
                        xAlpha
                )
            );
        } else {
            uint64 key = (uint64(uint8(palette[x])) << 56) |
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

    function packAssets(uint8[12] calldata assetsArr)
        external
        pure
        returns (uint96)
    {
        uint96 ret = 0;

        for (uint8 i = 0; i < 12; i++) {
            ret = ret | (uint96(assetsArr[i]) << (8 * (11 - i)));
        }

        return ret;
    }

    function render(uint96 packed) public view returns (bytes memory) {
        uint256 mask = 0xff << 88;
        bytes memory pixels = new bytes(2304);
        for (uint8 j = 0; j < 12; j++) {
            uint8 assetIndex = uint8(
                (packed & (mask >> (j * 8))) >> (8 * (11 - j))
            );
            if (assetIndex > 0) {
                bytes storage a = assets[assetIndex];
                uint256 n = a.length / 3;
                for (uint256 i = 0; i < n; i++) {
                    uint256[4] memory v = [
                        uint256(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint256(uint8(a[i * 3]) & 0xF),
                        uint256(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint256(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint256 dx = 0; dx < 2; dx++) {
                        for (uint256 dy = 0; dy < 2; dy++) {
                            uint256 p = ((2 * v[1] + dy) *
                                24 +
                                (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(
                                    a[i * 3 + 1],
                                    pixels[p],
                                    pixels[p + 1],
                                    pixels[p + 2],
                                    pixels[p + 3]
                                );
                                pixels[p] = c[0];
                                pixels[p + 1] = c[1];
                                pixels[p + 2] = c[2];
                                pixels[p + 3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p + 1] = 0;
                                pixels[p + 2] = 0;
                                pixels[p + 3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }

    function renderSvg(uint96 packed)
        external
        view
        returns (string memory svg)
    {
        bytes memory pixels = render(packed);
        svg = string(abi.encodePacked(SVG_HEADER));
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(
                        abi.encodePacked(
                            svg,
                            '<rect x="',
                            toString(x),
                            '" y="',
                            toString(y),
                            '" width="1" height="1" shape-rendering="crispEdges" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function getPackedAssetNames(uint96 packed)
        external
        view
        returns (string memory text)
    {
        uint96 mask = 0xff << 88;
        for (uint8 j = 0; j < 12; j++) {
            uint8 asset = uint8((packed & (mask >> (j * 8))) >> (8 * (11 - j)));
            if (asset > 0) {
                if (j > 0) {
                    text = string(
                        abi.encodePacked(text, ", ", assetNames[asset])
                    );
                } else {
                    text = assetNames[asset];
                }
            }
        }
    }

    function isPackedEqualToOriginalPunkIndex(uint96 packed, uint16 punkIndex)
        public
        view
        returns (bool)
    {
        string memory packedAssetNames = this.getPackedAssetNames(packed);
        string memory punkAssetNames = cryptopunksData.punkAttributes(
            punkIndex
        );

        return
            keccak256(bytes(packedAssetNames)) ==
            keccak256(bytes(punkAssetNames));
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