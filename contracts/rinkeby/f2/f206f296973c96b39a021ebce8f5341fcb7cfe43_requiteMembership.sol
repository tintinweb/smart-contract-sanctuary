// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Base64.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract requiteMembership is ERC721 {

    // todo, change to RM specific owner.
    address public owner = 0x577c89c8CE79991728EA47FaD9a49C7b1f5Fb2c0;
    address payable public collector; // Requite Membership collection address

    uint256 public premiumMembershipSupply;
    uint256 public deluxeMembershipSupply;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    struct Merbership {
        uint256 nr;
        address sponsored;
    }

    // tokenId => Merbership
    mapping(uint256 => Merbership) public merberships;

    // 16 palettes
    string[4][16] palette = [
        ["#eca3f5", "#fdbaf9", "#b0efeb", "#edffa9"],
        ["#75cfb8", "#bbdfc8", "#f0e5d8", "#ffc478"],
        ["#ffab73", "#ffd384", "#fff9b0", "#ffaec0"],
        ["#94b4a4", "#d2f5e3", "#e5c5b5", "#f4d9c6"],
        ["#f4f9f9", "#ccf2f4", "#a4ebf3", "#aaaaaa"],
        ["#caf7e3", "#edffec", "#f6dfeb", "#e4bad4"],
        ["#f4f9f9", "#f1d1d0", "#fbaccc", "#f875aa"],
        ["#fdffbc", "#ffeebb", "#ffdcb8", "#ffc1b6"],
        ["#f0e4d7", "#f5c0c0", "#ff7171", "#9fd8df"],
        ["#e4fbff", "#b8b5ff", "#7868e6", "#edeef7"],
        ["#ffcb91", "#ffefa1", "#94ebcd", "#6ddccf"],
        ["#bedcfa", "#98acf8", "#b088f9", "#da9ff9"],
        ["#bce6eb", "#fdcfdf", "#fbbedf", "#fca3cc"],
        ["#ff75a0", "#fce38a", "#eaffd0", "#95e1d3"],
        ["#fbe0c4", "#8ab6d6", "#2978b5", "#0061a8"],
        ["#dddddd", "#f9f3f3", "#f7d9d9", "#f25287"]
    ];

    string[64] reasons = [
        "BUILD",
        "TRAIN",
        "SEE",
        "DREAM",
        "LIVE",
        "DANCE",
        "HOPE",
        "ARCHITECT",
        "EXPLORE",
        "EAT",
        "TASTE",
        "SMELL",
        "RUN",
        "BE",
        "MEANDER",
        "WALK",
        "LEAVE",
        "LOVE",
        "REMINISCE",
        "GIVE",
        "ASCEND",
        "MEET",
        "LEARN",
        "ENCOMPASS",
        "MEDITATE",
        "FIND",
        "SEEK",
        "LAUGH",
        "LISTEN",
        "FEEL",
        "TOUCH",
        "FORGIVE",
        "ATONE",
        "ACCEPT",
        "PLAY",
        "SING",
        "DRIVE",
        "CLIMB",
        "PAINT",
        "CODE",
        "PONDER",
        "SLEEP",
        "FLY",
        "CREATE",
        "WRITE",
        "DIRECT",
        "ESCAPE", 
        "FALL",
        "FLOURISH",
        "JAM",
        "IMPROVISE",
        "JUMP",
        "TREAT",
        "GIFT",
        "EXIT",
        "MIX",
        "SAIL",
        "MAKE",
        "SOLVE",
        "SEARCH",
        "THINK",
        "RESEARCH",
        "ADVANCE",
        "REASON"
    ];

    // Skyscraper Barcode
    struct Skyscraper {
        string h; // height
        string a1; // dash array #1
        string a2; // dash array #2
        string a3; // dash array #3
    }
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
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

        string memory merbershipType = "Premium";
        if(merberships[tokenId].sponsored != 0x0000000000000000000000000000000000000000) {
            merbershipType = "Deluxe";
        }

        string memory name = string(abi.encodePacked(merbershipType, ' requite Membership #',toString(merberships[tokenId].nr)));
        string memory description = "Requite Membership NFT";
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
        uint256 pIndex = toUint8(hash,0)/16; // 16 palettes
        uint256 rIndex = toUint8(hash,1)/4; // 64 reasons

        /* this is broken into functions to avoid stack too deep errors */
        string memory paletteSection = generatePaletteSection(tokenId, pIndex);
        string memory skyscraper = generateSkyscrapers(hash, pIndex);

        string memory class = 'PR'; // PR for Premium
        if(merberships[tokenId].sponsored != 0x0000000000000000000000000000000000000000) {
            class = 'DX'; // DX for Deluxe
        }

        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="300" height="300" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">',
                paletteSection,
                skyscraper,
                '<text x="220" y="80" class="small">METAVERSE</text>',
                '<text x="15" y="80" class="medium">EDITION> ',class,'1</text>',
                '<text x="15" y="100" class="medium">ID> ',toString(merberships[tokenId].nr),'</text>',
                '<text x="15" y="120" class="medium">REASON:</text>',
                '<rect x="15" y="125" width="205" height="40" style="fill:white;opacity:0.5"/>',
                '<text x="15" y="140" class="medium">TO ',reasons[rIndex],'</text>',
                '<text x="15" y="190" class="small">SPONSORED BY:</text>',
                '<text x="15" y="205" style="font-size:8px">',toHexString(uint160(merberships[tokenId].sponsored), 20),'</text>',
                '<text x="15" y="230" class="tiny">"Your time is limited, so don\'t waste it living someone</text>',
                '<text x="15" y="240" class="tiny">else\'s life. Don\'t be trapped by dogma - which is living</text>',
                '<text x="15" y="250" class="tiny">with the results of other people\'s thinking". "The best</text>',
                '<text x="15" y="260" class="tiny">and most beautiful things in the world cannot be seen</text>',
                '<text x="15" y="270" class="tiny">or even touched - they must be felt with the heart".</text>',
                '<style>@import url("https://fonts.googleapis.com/css2?family=Pacifico");.svgBody {font-family: "Courier New" }.tiny {font-size:6px; }.small {font-size: 12px;}.medium {font-size: 18px;}.xlarge {font-size: 45px; font-family: "Pacifico", cursive;}</style>',
                '</svg>'
            )
        );
    }

    function generatePaletteSection(uint256 tokenId, uint256 pIndex) internal view returns (string memory) {
        return string(abi.encodePacked(
                '<rect width="300" height="300" rx="10" style="fill:',palette[pIndex][0],'" />',
                '<rect y="205" width="300" height="75" rx="10" style="fill:',palette[pIndex][3],'" />',
                '<rect y="60" width="300" height="115" style="fill:',palette[pIndex][1],'"/>',
                '<rect y="175" width="300" height="40" style="fill:',palette[pIndex][2],'" />',
                '<text x="15" y="25" class="medium">REQUITE MEMBERSHIP</text>',
                '<text x="17" y="50" class="small" opacity="0.5">',substring(toString(tokenId),0,24),'</text>',
                '<circle cx="255" cy="30" r="20" stroke="',palette[pIndex][3],'" fill="black" stroke-width="4" opacity="0.7" />',
                '<text x="243" y="41" class="xlarge" font-family="Pacifico" fill="',palette[pIndex][3],'" stroke="none">r</text>'
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

    function mint() public payable returns (uint256 tokenId) {
        require(block.timestamp > startDate, "NOT_STARTED");
        require(block.timestamp < endDate, "ENDED");
        require(msg.value >= 0.01 ether, 'MORE ETH NEEDED'); //~$20

        Merbership memory merbership;
        
        if(msg.value >= 0.05 ether) { //~$100
            deluxeMembershipSupply += 1;
            require(deluxeMembershipSupply <= 100, "MAX_DX_REACHED_100");
            merbership.nr = deluxeMembershipSupply;
            merbership.sponsored = msg.sender;
        } else { // don't need to check ETH amount here since it is checked in the require above
            premiumMembershipSupply += 1;
            merbership.nr = premiumMembershipSupply;
        }

        tokenId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        merberships[tokenId] = merbership;

        super._mint(msg.sender, tokenId);
    }

    function withdraw() public {
        require(msg.sender == collector, "NOT_COLLECTOR");
        collector.transfer(address(this).balance);
    }
    
    function totalPremiumSupply() public view virtual returns (uint256) {
        return premiumMembershipSupply;
    }

    function totalDeluxeSupply() public view virtual returns (uint256) {
        return deluxeMembershipSupply;
    }

    // GENERIC helpers

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