// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Base64.sol";


contract womacitypassports is ERC721 {

    // todo, change to UF specific owner.
    address public owner = 0x3f0E6A8aD71e7D3f912014855f40a0114201e63F; // for OpenSea storefront integration. no effect on contract.
    address payable public collector; // Untitled Frontier collection address

    uint256 public elitePassportsSupply;
    uint256 public premiumPassportsSupply;
    

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    struct Passport {
        uint256 nr;
        address sponsored;
    }

    // tokenId => Passport
    mapping(uint256 => Passport) public passports;

    // 16 palettes
    string[4][16] palette = [
        ["#B6F7B6", "#C9DEF2", "#F1B87E", "#81ADD9"],
        ["#F4F9F9", "#CCF2F4", "#AAAAAA", "#A4EBF3"],
        ["#3ABEFF", "#E87EA1", "#EBB3A9", "#EEEBD0"],
        ["#EEE5E9", "#8FA6CB", "#4D5061", "#E7E247"],
        ["#9CEAEF", "#C4FFF9", "#000009", "#C8B8DB"],
        ["#FFE2D1", "#86CD82", "#BC82D9", "#A0EEC0"],
        ["#CFD4C5", "#EECFD4", "#E6ADEC", "#C287E8"],
        ["#E4FBFF", "#B8B5FF", "#7868E6", "#EDEEF7"],
        ["#DDDDDD", "#F9F3F3", "#F25287", "#F7D9D9"],
        ["#BEDCFA", "#98ACF8", "#DA9FF9", "#B088F9"],
        ["#C4FFF9", "#9CEAEF", "#68D8D6", "#3DCCC7"],
        ["#F8F1FF", "#DECDF5", "#6991B5", "#B3949C"],
        ["#A3A3A3", "#92DCE5", "#52DEE5", "#EEE5E9"],
        ["#F9B9B7", "#F5D491", "#F06C9B", "#96C9DC"],
        ["#FF858D", "#FFD4D4", "#FF9FE5", "#8DA5E2"],
        ["#F4F4ED", "#B3E9F2", "#B388EB", "#72DDF7"]
    
    ];

       string[64] missions = [
        "BUILD",
        "TRAINS",
        "FORESTS",
        "DREAMS",
        "LIVE",
        "AVATARS",
        "HEALTH",
        "EXPLORE",
        "TEMENOS",
        "WATER",
        "AIR",
        "MEDICALS",
        "REPAIR",
        "EPHEROS",
        "GERUSIA",
        "LOGOTHETES",
        "AIRCRAFTS",
        "SPACECRAFTS",
        "PLANETS",
        "CHEMICAL",
        "MAINTANANCE",
        "SPY",
        "CRYPTO",
        "NUCLEAR",
        "SECURITY",
        "ANIMALS",
        "RESEARCH",
        "SOCIAL",
        "SPACE",
        "SOLIDUS",
        "FIELD",
        "BACKOFFICE",
        "PILOT",
        "BORDERS",
        "EDUCATION",
        "CODING",
        "DRONES",
        "PRISONS",
        "AIRPORTS",
        "SUBWAYS",
        "HIGHWAYS",
        "RADARS",
        "POLITICS",
        "IMPROVISE",
        "THREATS",
        "ROBOTS",
        "PLANTS",
        "EMERGENCY",
        "IKRANS",
        "INFRASTRUCTURE",
        "PRODUCTION",
        "SUPPLY CHAIN",
        "ENVIRONMENT",
        "SEAWAYS",
        "ANALYSIS",
        "SOFTWARE",
        "HARDWARE",
        "MINES",
        "BLOCKCHAIN",
        "AUTONOMOUS VEHICLES",
        "ANDROID",
        "AMBASSADOR",
        "TERMINATORS"
    ];

    // Skyscraper Barcode
    struct Skyscraper {
        string h; // height
        string a1; // dash array #1
        string a2; // dash array #2
        string a3; // dash array #3
    }
    
   
    constructor (string memory name_, string memory symbol_, address payable collector_, uint256 startDate_, uint256 endDate_) ERC721(name_, symbol_) {
        collector = collector_;
        startDate = startDate_;
        endDate = endDate_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory passportType = "ELITE";
        if(passports[tokenId].sponsored != 0x0000000000000000000000000000000000000000) {
            passportType = "PREMIUM";
            
        }

        string memory name = string(abi.encodePacked(passportType, ' PASSPORT #',toString(passports[tokenId].nr)));
        string memory description = "Onchain woma city passport.The passport holder is a woma city founder and has priority to benefit to all opportunities of the city. https://woma.city";
        string memory image = generateBase64Image(tokenId);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        return Base64.encode(bytes(generateImage(tokenId)));
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 pIndex = toUint8(hash,0)/16; 
        uint256 rIndex = toUint8(hash,1)/4; 

        /* this is broken into functions to avoid stack too deep errors */
        string memory paletteSection = generatePaletteSection(tokenId, pIndex);
        string memory skyscraper = generateSkyscrapers(hash, pIndex);

        string memory class = 'ELITE'; // for elite
        if(passports[tokenId].sponsored != 0x0000000000000000000000000000000000000000) {
            class = 'PREMIUM'; // for premium
        
        }

        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="500" height="500" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">',
                paletteSection,
                skyscraper,
                '<text x="240" y="53" class="small">woma.city</text>',
                '<text x="15" y="80" class="medium">GRADE:',class,'</text>',
                '<text x="15" y="95" class="medium">ID: #',toString(passports[tokenId].nr),'</text>',
                '<text x="15" y="110" class="medium">MISSION:</text>',
                '<rect x="15" y="115" width="205" height="20" rx="5" style="fill:white;opacity:0.5"/>',
                '<text x="17" y="128" class="medium">TO ',missions[rIndex],'</text>',
                '<text x="15" y="190" class="small">ISSUED BY: </text>',
                '<rect x="15" y="196" width="205" height="14"  rx="5" style="fill:white;opacity:0.5"/>',
                '<text x="17" y="205" style="font-size:8px">',toHexString(uint160(passports[tokenId].sponsored), 20),'</text>',
                '<rect x="15" y="249" width="205" height="32" rx="5" style="fill:white;opacity:0.5"/>',
                '<text x="17" y="255" class="tiny">The passport holder is a woma city founder and has  </text>',
                '<text x="17" y="265" class="tiny">priority to benefit to all opportunities of the city. </text>',
                '<text x="17" y="275" class="tiny">If destroyed the owner will be delisted.</text>',
                '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:6px; } .small {font-size: 10px;} .medium {font-size: 12px;} .large {font-size: 16px;}</style>',
                '</svg>'
            )
        );
    }

    function generatePaletteSection(uint256 tokenId, uint256 pIndex) internal view returns (string memory) {
        return string(abi.encodePacked(
                '<rect width="300" height="300" rx="10" style="fill:',palette[pIndex][0],'"/>',
                '<rect y="62" width="300" height="222" rx="10" style="fill:',palette[pIndex][1],'"/>',
                '<rect y="106" width="300" height="124" style="fill:',palette[pIndex][3],'"/>',
                '<circle cx="150" cy="167" r="80" stroke="white" stroke-width="1.3" style="fill:',palette[pIndex][2],'"/>',
                '<text x="15" y="30" class="large">WOMA CITY PASSPORT</text>',
                '<text x="17" y="53" class="small" opacity="0.7">',substring(toString(tokenId),0,24),'</text>',
                '<circle cx="270.5" cy="25.33" r="18" stroke="black" fill="black" stroke-width="0.6" opacity="1"/>',
                '<circle cx="270.5" cy="25.33" r="16" stroke="white" fill="transparent" stroke-width="1" opacity="1"/>',
                '<path d="m262,37.21049l8.49985,-15.58304l8.49985,15.58304l-16.9997,0z" stroke="#ff66c4" fill="transparent" stroke-width="1" opacity="1"/>',
                '<path transform="rotate(180 270.167 30.7915)" d="m261.66667,38.58304l8.49985,-15.58304l8.49985,15.58304l-16.9997,0z"  stroke="#5ce1e6" fill="transparent" stroke-width="1" opacity="1"/>',
                '<circle cx="267" cy="17" r="3" stroke="#5ce1e6" fill="transparent" stroke-width="1" opacity="1"/>',
                '<circle cx="274" cy="17" r="3" stroke="#ff66c4" fill="transparent" stroke-width="1" opacity="1"/>',
                '<path  d="m101.73803,229.74756l47.66596,-82.99879l47.66596,82.99879l-95.33192,0z" stroke="white" fill="transparent" stroke-width="2" opacity="0.6"/>'
                '<path transform="rotate(180 149.666 193.499)"  d="m102,234.99878l47.66596,-82.99878l47.66596,82.99878l-95.33192,0z"  stroke="white" fill="transparent" stroke-width="2" opacity="0.6"/>'
                '<circle cx="132.2" cy="130" r="16" stroke="white" fill="transparent" stroke-width="2" opacity="0.6"/>',
                '<circle cx="166.5" cy="130" r="16" stroke="white" fill="transparent" stroke-width="2" opacity="0.6"/>'
                 
           )
        );
    }

    function generateSkyscraper(bytes memory hash, uint256 i) internal pure returns (Skyscraper memory skyscraper) {
        skyscraper.h = toString(90 + (toUint8(hash,i)/4)); // 64
        skyscraper.a1 = toString(toUint8(hash,i+1)/16); // 16
        skyscraper.a2 = toString(toUint8(hash,i+2)/16); // 16
        skyscraper.a3 = toString(toUint8(hash,i+3)/16); // 16
    }

    function generateSkyscraperSVG(Skyscraper memory skyscraper, string memory x, uint256 pIndex, uint256 p) internal view returns (string memory) {
        return string(abi.encodePacked(
            '<line x1="',x,'" y1="',skyscraper.h,'" x2="',x,'" y2="300" stroke="',palette[pIndex][p],'" stroke-width="10" stroke-dasharray="',skyscraper.a1,' ',skyscraper.a2,' ',skyscraper.a3,'"/>'
        ));
    }

    function generateSkyscrapers(bytes memory hash, uint256 pIndex) internal view returns (string memory) {
        Skyscraper memory sky1 = generateSkyscraper(hash,2);
        Skyscraper memory sky2 = generateSkyscraper(hash,6);
        Skyscraper memory sky3 = generateSkyscraper(hash,10);
        Skyscraper memory sky4 = generateSkyscraper(hash,14);
        Skyscraper memory sky5 = generateSkyscraper(hash,18);

        string memory sky2svg = generateSkyscraperSVG(sky2, "245", pIndex, 2);
        string memory sky3svg = generateSkyscraperSVG(sky3, "255", pIndex, 0);
        string memory sky4svg = generateSkyscraperSVG(sky4, "265", pIndex, 3);

        return string(
            abi.encodePacked(
                '<line x1="235" y1="',sky1.h,'" x2="235" y2="300" stroke="white" stroke-width="10" stroke-dasharray="',sky1.a1,' ',sky1.a2,' ',sky1.a3,'"/>',
                sky2svg,
                sky3svg,
                sky4svg,
                '<line x1="275" y1="',sky5.h,'" x2="275" y2="300" stroke="black" stroke-width="10" stroke-dasharray="',sky5.a1,' ',sky5.a2,' ',sky5.a3,'"/>'
            )
        );
    }

        function mintPassport() public payable returns (uint256 tokenId) {
        require(block.timestamp > startDate, "NOT_STARTED");
        require(block.timestamp < endDate, "ENDED");
        require(msg.value >= 10 ether, 'MORE ETH NEEDED'); 

        Passport memory passport;
        
        if(msg.value >= 40 ether) { 
            premiumPassportsSupply += 1;
            require(premiumPassportsSupply <= 2999, "MAX_PR_REACHED_2999");
            passport.nr = premiumPassportsSupply;
            passport.sponsored = msg.sender;
        } else { // don't need to check MATIC amount here since it is checked in the require above
            elitePassportsSupply += 1;
            passport.nr = elitePassportsSupply;
        }

        tokenId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        passports[tokenId] = passport;

        super._mint(msg.sender, tokenId);
    }

    function withdrawETH() public {
        require(msg.sender == collector, "NOT_COLLECTOR");
        collector.transfer(address(this).balance);
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
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

    bytes16 private constant _ALPHABET = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "HEX_L");
        return string(buffer);
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}