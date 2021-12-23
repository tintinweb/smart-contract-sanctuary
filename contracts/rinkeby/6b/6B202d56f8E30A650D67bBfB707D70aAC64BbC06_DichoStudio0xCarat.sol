// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


//   ****            ******                               **  
//  *///**          **////**                             /**  
// /*  */* **   ** **    //   ******   ******  ******   ******
// /* * /*//** ** /**        //////** //**//* //////** ///**/ 
// /**  /* //***  /**         *******  /** /   *******   /**  
// /*   /*  **/** //**    ** **////**  /**    **////**   /**  
// / ****  ** //** //****** //********/***   //********  //** 
//  ////  //   //   //////   //////// ///     ////////    //  

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * @title DichoStudio 0xCarat
 * @author codesza, adapted from NPassCore.sol, NDerivative.sol, Voyagerz.sol, and CryptoCoven.sol
 * and inspired by Vows and Runners: Next Generation
 */


contract DichoStudio0xCarat is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    /// @notice A counter for tokens
    Counters.Counter private _tokenIds;
    
    uint256 private constant _maxPublicSupply = 888;
    uint256 private constant _maxRingsPerWallet = 3;
    uint256 public saleStartTimestamp;
    address private openSeaProxyRegistryAddress;
    
    /// @notice Records of crafter- and wearer- derived seeds 
    mapping(uint256 => uint256) private _ringSeed;
    mapping(uint256 => uint256) private _wearerSeed;

    /// @notice Recordkeeping beyond balanceOf
    mapping(address => uint256) private _crafterBalance;
    
    constructor(address _openSeaProxyRegistryAddress) ERC721("Dicho Studio 0xCarat", "RING") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    /// @notice Craft rings, a.k.a. mint 
    function craft(uint256 numToMint) external nonReentrant {
        require(isSaleOpen(), "Sale not open");
        require(numToMint > 0 && numToMint <= mintsAvailable(), "Out of rings");
        require(
            _crafterBalance[msg.sender] + numToMint <= _maxRingsPerWallet,
            "Max rings to craft is three"
        );
        
        uint256 tokenId; 

        for (uint256 i = 0; i < numToMint; i++) {
            _tokenIds.increment();
            tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _ringSeed[tokenId] = randSeed(msg.sender, tokenId, 13999234923493293432397);
            _wearerSeed[tokenId] = _ringSeed[tokenId];
        }
        _crafterBalance[msg.sender] += numToMint;
    }

    /// @notice Gift rings using safeTransferFrom
    function gift(address to, uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Gift a ring you own");
        safeTransferFrom(msg.sender, to, tokenId);
    }

    /// @notice To divorce, burn the ring.
    function divorce(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Burn a ring you own");
        _burn(tokenId);
    }

    /// @notice Is it time yet? 
    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartTimestamp && saleStartTimestamp != 0;
    }
    
    /// @notice Calculate available open mints
    function mintsAvailable() public view returns (uint256) {
        return _maxPublicSupply - _tokenIds.current();
    }


    // ============ OWNER ONLY ROUTINES ============

    /// @notice Allows owner to withdraw amount
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Allows owner to change sale time start
    function setSaleTimestamp(uint256 timestamp) external onlyOwner {
        saleStartTimestamp = timestamp;
    }

    // ============ HELPER FUNCTIONS / UTILS ============
    
    /// @notice Random seed generation, from Voyagerz contract
    function randSeed(address addr, uint256 tokenId, uint256 modulus) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(addr, block.timestamp, block.difficulty, tokenId))) % modulus;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function correctColor(uint256 hue, uint256 sat, uint256 lum, uint256 seed) internal pure returns (uint256, uint256) {
        if (hue <= 55 && hue >= 27 && sat < 66 && lum < 49) {
            sat = 70;
            lum = (seed % 33) + 48;
        }
        return (sat, lum);
    }


    // ============ RING CONSTRUCTION ============
    
    /// @notice Baseline parameters for a ring 
    struct RingParams {
        uint256 gemcol_h;
        uint256 gemcol_s;
        uint256 gemcol_l;
        uint256 bgcol_h;
        uint256 bgcol_s;
        uint256 cut_idx; 
        uint256 band_idx;
        string bandcol;
    }

    /// @notice Using wearer and crafter seeds to define ring parameters
    function getRingParams(uint256 tokenId) internal view returns (RingParams memory) {
        RingParams memory rp;
        {
            uint256 rSeed = _ringSeed[tokenId];

            // gem color derived from minter-derived seed. still influences ethereum cut
            rp.gemcol_h = rSeed % 335;
            rSeed = rSeed >> 8;
            rp.gemcol_s = ((rSeed & 0xFF) % 40) + 40; // (40, 80) 
            rSeed = rSeed >> 8;
            rp.gemcol_l = ((rSeed & 0xFF) % 50) + 30; // (30, 80) 
            rSeed = rSeed >> 8;
            (rp.gemcol_s, rp.gemcol_l) = correctColor(rp.gemcol_h, rp.gemcol_s, rp.gemcol_l, rSeed);

            // gem cut and ring band color 
            if ((rSeed & 0xFF) < 8) { // 8/255 = ~3% chance of "ethereum" cut 
                rp.cut_idx = 0;
            } else if ((rSeed & 0xFF) < 59) { // between 8 and 59 / 255 = ~20% chance of emerald cut
                rp.cut_idx = 2;
            } else if ((rSeed & 0xFF) < 148) { // between 59 and 148 / 255 = ~35% chance of solitaire cut 
                rp.cut_idx = 3;
            } else {
                rp.cut_idx = 1; // round
            }
            
            rSeed = rSeed >> 8;

            if ((rSeed & 0xFF) < 26) { // <26/255 = ~10% chance of rose gold band 
                rp.bandcol = "#C48891";
                rp.band_idx = 0;
            } else if ((rSeed & 0xFF) < 115) { // between 26 and 115 / 255 = 35% chance of platinum band 
                rp.bandcol = "#C4C4C4";
                rp.band_idx = 1;
            } else {
                rp.bandcol = "#D7BB59";
                rp.band_idx = 2;
            }

            if (_wearerSeed[tokenId] != _ringSeed[tokenId]) {
                uint256 wSeed = _wearerSeed[tokenId];
                rp.bgcol_h = wSeed % 335;
                wSeed = wSeed >> 8; 
                (rp.bgcol_s,) = correctColor(rp.bgcol_h, ((wSeed & 0xFF) % 35) + 35, 35, 0); // (35, 70)
            } else {
                rp.bgcol_h = rp.gemcol_h;
                rp.bgcol_s = rp.gemcol_s;

                if (rp.band_idx == 2 && rp.gemcol_h < 48 && rp.gemcol_h > 27) {
                    rp.band_idx = 1;
                    rp.bandcol = "#C4C4C4";
                }
            }
        }

        return rp;
    }
    
    /// @notice Constructing the ring's svg using its parameters 
    function getSvg(uint256 tokenId) internal view returns (bytes memory, RingParams memory) {
        RingParams memory rp = getRingParams(tokenId);

        bytes memory buf;

        {
            buf = abi.encodePacked(
                '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">'
                "<defs>"
            );

            if (rp.cut_idx == 0) {
                buf = abi.encodePacked(
                    buf,
                    '<radialGradient id="b" r="2" cy="100%" cx="30%" fx="100%" fy="10%">'
                    '<stop stop-color="#7FDEFF"/>'
                    '<stop offset=".19" stop-color="#CFC7FA" stop-opacity=".8"/>'
                    '<stop offset=".23" stop-color="#CED9ED" stop-opacity=".79"/>'
                    '<stop offset=".32" stop-opacity="1" stop-color="hsl(',
                    toString(rp.gemcol_h),
                    ",",
                    toString(rp.gemcol_s),
                    "%,",
                    toString(rp.gemcol_l),
                    '%)" />'
                    '<stop stop-color="#EFC8DD" offset=".33" stop-opacity=".6"/>'
                    '<stop stop-color="#CED9ED" offset=".4" stop-opacity=".8"/>'
                    '</radialGradient>'
                );
            } else {
                if (rp.cut_idx == 3) {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" cx="1.6" cy="0" r="1" fy="0.6" spreadMethod="reflect" gradientUnits="userSpaceOnUse" gradientTransform="'
                        'matrix(0 45.7397 -53.6119 0 250 165)">'
                    );
                } else if (rp.cut_idx == 2) {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" spreadMethod="reflect" fy="1" r="1" cy="0" cx="1.6" gradientTransform="'
                        'rotate(179.48 125.62 79.01) scale(177.459 42.9393)" gradientUnits="userSpaceOnUse">'
                    );
                    
                } else {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" gradientUnits="userSpaceOnUse" gradientTransform="'
                        'matrix(0 -100 60 0 249.9 161.75)" spreadMethod="reflect" fy="0.9" r="1" cy="0" cx="1.7">'
                    );
                    
                }
                buf = abi.encodePacked(
                    buf,
                    '<stop stop-color="hsl(',
                    toString(rp.gemcol_h + 25),
                    ",",
                    toString(rp.gemcol_s + 20),
                    "%,",
                    toString(rp.gemcol_l + 10),
                    '%)"/>'
                    '<stop offset="1" stop-color="hsl(',
                    toString(rp.gemcol_h),
                    ",",
                    toString(rp.gemcol_s),
                    "%,",
                    toString(rp.gemcol_l),
                    '%)" stop-opacity="0.4" />'
                    '</radialGradient>'
                );
            }
        
        }

        {
            buf = abi.encodePacked(
                buf,
                '<filter id="a" x="0" y="0" width="100%" height="100%" '
                'filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                '<feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>'
                '<feOffset xmlns="http://www.w3.org/2000/svg" dy="3" dx="3" />'
                '<feComposite in2="hardAlpha" operator="out"/>'
                '<feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/>'
                '<feBlend in2="BackgroundImageFix" result="effect1_dropShadow"/>'
                '<feBlend in="SourceGraphic" in2="effect1_dropShadow" result="shape"/>'
                '<feGaussianBlur stdDeviation="2" result="blur1"/>'
                '<feSpecularLighting result="spec1" in="blur1" specularExponent="70" lighting-color="hsl(',
                toString(rp.bgcol_h + 25),
                ",",
                toString(rp.bgcol_s + 20),
                "%, ",
                toString((rp.bgcol_h + 25) < 210 ? 35 : (rp.bgcol_h + 25) < 330 ? 65 : 80),
                '%)">'
                '<fePointLight x="140" y="150" z="300" /></feSpecularLighting>'
                '<feComposite in="SourceGraphic" in2="spec1" operator="arithmetic" k1="0" k2="1" k3="1" k4="0" />'
                "</filter>"
            );

            buf = abi.encodePacked(
                buf,
                '<radialGradient id="bg" cx="0.4" cy="0.32" r="2.5">'
                '<stop offset="0%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 40%)" />'
                '<stop offset="20%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 22%)" />'
                '<stop offset="60%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 10%)" />'
                "</radialGradient>"
                "</defs>"
            );
        }

        buf = abi.encodePacked(
            buf,
            '<rect x="0" y="0" width="100%" height="100%" fill="url(#bg)" />'
            '<g filter="url(#a)">'
            '<path d="M249.5 343c-37.3 0-67.5-30.2-67.5-67.5s30.2-67.5 67.5-67.5 67.5 30.2 67.5 67.5-30.2 67.5-67.5 67.5Z" '
            'stroke="',
            rp.bandcol, 
            '" stroke-width="13.8" fill="none"/>'
        );

        {
            if (rp.cut_idx == 0) { // eth cut 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M249.3 113.8c-.2.4-5.4 9.3-11.7 19.6-6.3 10.4-11.4 19-11.5 19.2-.1.2 3.3 2.3 11.9 7.4l12 7.1 '
                    '12-7.1c8.6-5.1 12-7.2 11.9-7.4-.4-1.1-23.8-39.6-24.1-39.6-.1 0-.4.3-.5.8Zm-23.2 43.9c.5.8 23.8 33.7 23.9 '
                    '33.7.2 0 24.1-33.8 24-33.9-.1-.1-22.4 13.1-23.4 13.8l-.6.4-11.6-6.8c-6.4-3.8-11.8-7-12.1-7.2-.3-.3-.4-.3-.2 0Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="m237 179 13 17.1 13-17.1 3.5-5 .3-.3c.3-.3.7-.1.7.3v.1l-7 16-5 '
                    '12.5h-11l-5-12.5-7-16v-.1c0-.4.4-.6.7-.3l.3.3 3.5 5Z" fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else if (rp.cut_idx == 1) { // round 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M210 164.9a34.76 34.76 0 0 1 33.9-34.75l6.1-.15 6.1.15A34.76 34.76 0 0 1 290 164.9c0 1.31-.66 '
                    '2.53-1.76 3.24l-36.06 23.44a4 4 0 0 1-4.36 0l-36.06-23.44a3.86 3.86 0 0 1-1.76-3.24Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M210.49 167.01 250 192.23l39.51-25.22a4.86 4.86 0 0 1 '
                    '5.9.53c.85.78.84 2.12-.03 2.88L259 202.5l-9-.5-9 .5-36.38-32.08a1.94 1.94 0 0 1-.04-2.88 4.86 4.86 0 0 1 5.9-.53Z" '
                    'fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else if (rp.cut_idx == 2) { // emerald
                buf = abi.encodePacked(
                    buf,
                    '<path d="M241.1 191h30.2l14.9-10 13.6-9.6c.9-.6 1.8-1.4 2.5-2.2l6.9-7.6 6.8-9.6c.3-.4.5-.9.5-1.4v-.4c0-.9-.2-1.8-'
                    '.7-2.6l-2.9-4.8c-1.8-3-5.1-4.8-8.6-4.8H198.7c-3.5 0-6.8 1.8-8.6 4.8l-2.9 4.8c-.5.8-.7 1.7-.7 2.6v.4c0 .5.2 1 .5 '
                    '1.4l6.8 9.6 6.9 7.6c.7.8 1.6 1.6 2.5 2.2l13.6 9.6 14.9 10h9.4Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="m232.8 191 18.2-2 19 2 6.1-4.5-25.1-3-24.3 3 6.1 4.5Zm18.2-14 '
                    '39.3-.4c.6 0 1.3-.1 1.9-.4l4.8-3.2c.32-.25.63-.5.97-.75.71-.55 1.5-1.16 2.53-2.05l8.6-9.6 '
                    '5.7-8.3c.6-.9.8-1.9.6-2.9l-.2-1.4 3.6-1v13l-3.8 8-15 10-38 25-11-1-10.2 1-38-25-15-10-3.8-8v-13l3.6 '
                    '1-.2 1.4c-.2 1 0 2 .6 2.9l5.7 8.3 8.6 9.6c1.02.89 1.82 1.5 2.53 2.05.34.25.65.5.97.75l4.8 3.2c.6.3 1.3.4 1.9.4l38.5.4Z" '
                    'fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else { // solitaire 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M255 194.5c-2.9 2-6.7 2-9.6 0l-46.4-31.6c-5.2-3.6-4.9-11.4.6-14.4l10-5.6c1.3-.7 2.7-1.1 '
                    '4.2-1.1h72.8c1.5 0 2.9.4 4.2 1.1l10 5.6c5.5 3.1 5.8 10.9.6 14.4l-46.4 31.6Z" fill="url(#b)"/>'
                    '<path d="m249.9 196.3 5-11.4-3.2-22.9-.8-8.7h-2.8l-.8 8.7-2.54 22.9 5.14 11.4Z" fill="',
                    rp.bandcol,
                    '"/>'
                    '<path d="m245.9 202.4-5.4.5-46.9-33.8c-2.4-1.7-3.9-5.2-3.7-7.4l.9-4.1c0-.1 0-.1.1-.4l1.7-4 3.5-.2-.7 '
                    '1.9c-.3.9-.2 1.8-.1 2.8v.5c.3 1.6 1.8 3 3.2 3.9l39.4 25.6c2.7 1.8 5.88 0 6.98-3.1l7.92 18 1.1.1 5.2.5 '
                    '47.2-34c2.4-1.7 3.9-5.2 3.7-7.4l-.9-4.1c0-.1 0-.1-.1-.4l-1.7-4-3.5-.2.7 1.9c.3.9.2 1.8.1 '
                    '2.8v.5c-.3 1.6-1.8 3-3.2 3.9l-39.4 25.6c-2.7 1.8-6.12-.1-7.12-3.2l-4 8.9-3.48 9" fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            }
        }        

        return (buf, rp);
    }

    // ============ OVERRIDES ============

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Updates tokenId's wearer and seed to update background
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (!(from == address(0x0) || to == address(0x0))) {
            uint256 prevBg = _wearerSeed[tokenId] % 335;
            _wearerSeed[tokenId] = randSeed(to, tokenId, 13999234923493293432397);
            uint256 thisBg = _wearerSeed[tokenId] % 335;
            uint256 thisBg30 = thisBg + 30;
            uint256 prevBg30 = prevBg + 30;
            if ((thisBg > prevBg ? thisBg30 - prevBg30 : prevBg30 - thisBg30) < 30) {
                _wearerSeed[tokenId] += 65;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        (bytes memory svgBuf, RingParams memory rp) = getSvg(tokenId);

        // Attributes 
        string memory bandcol = rp.band_idx == 0 ? "Rose gold" : rp.band_idx == 1 ? "Platinum" : "Gold";
        string memory gemcol;
        string memory cutname;
        {
            if (rp.cut_idx == 0) {
                gemcol = "Holographic";
                cutname = "Ethereum";
            } else {
                gemcol = string(abi.encodePacked("hsl(", toString(rp.gemcol_h), ", ", toString(rp.gemcol_s), "%, ", toString(rp.gemcol_l), "%)"));
                cutname = rp.cut_idx == 1 ? "Round" : rp.cut_idx == 2 ? "Emerald" : "Solitaire";
            }
        }

        string memory metadata_attr = string(
            abi.encodePacked(
                'attributes": [{"trait_type": "Cut", "value": "',
                cutname,
                '"},',
                '{"trait_type": "Band color", "value": "',
                bandcol,
                '"},',
                '{"trait_type": "Background color", "value": "hsl(',
                toString(rp.bgcol_h),
                ", ",
                toString(rp.bgcol_s),
                "%, 50%)",
                '"},',
                '{"trait_type": "Gem color", "value": "',
                gemcol,
                '"}',
                "]"
            )
        );

        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(   
                    '{"name": "0xCarat #',
                    toString(tokenId),
                    '", "description": "A fully on-chain ring to celebrate on-chain love.", "image": "data:image/svg+xml;base64,',
                    Base64.encode(svgBuf),
                    '","',
                    metadata_attr,
                    "}"
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

/// @notice These contract definitions are used to create a reference to the OpenSea ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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