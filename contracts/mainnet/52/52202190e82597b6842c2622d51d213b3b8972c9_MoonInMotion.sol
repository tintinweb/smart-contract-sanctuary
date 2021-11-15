// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonInMotion is ERC1155, Ownable {
    struct Date {
        int day;
        int month;
        int year;
    }

    uint256 public constant MOON = 1;
    uint256 public constant BLOOD = 2;
    uint256 public constant HONEY = 3;
    uint256 public constant ORANGE = 4;
    uint256 public constant BLUE = 5;
    uint256 public constant NEON = 6;

    uint constant COMMON_COUNT = 29;
    uint constant UNCOMMON_COUNT = 14;
    uint constant RARE_COUNT = 7;
    uint constant SUPERRARE_COUNT = 3;
    uint constant UNIQUE_COUNT = 1;

    string svg1 = "<svg width='600' height='600' viewBox='0 0 600 600' fill='none' xmlns='http://www.w3.org/2000/svg'><g clip-path='url(#c0)'><rect width='600' height='600' fill='url(#p0)'/><g filter='url(#f0)'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></g><g filter='url(#f1)'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></g><mask id='m0' mask-type='alpha' maskUnits='userSpaceOnUse' x='109' y='109' width='382' height='382'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></mask><g mask='url(#m0)'><g filter='url(#f2)'>";
    string svg2 = "</g></g><defs><filter id='f0' x='-15' y='-15' width='630' height='630' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='62'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.25 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='f1' x='39' y='39' width='522' height='522' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='35'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.0862745 0 0 0 0 0.0823529 0 0 0 0 0.25098 0 0 0 0.24 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='f2' x='105' y='109' width='390' height='390' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='2'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><radialGradient id='p0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(126 116) rotate(45.1872) scale(865.503)'><stop offset='0.255208' stop-color='#160340'/><stop offset='1' stop-color='#356C4B'/></radialGradient><clipPath id='c0'><rect width='600' height='600' fill='white'/></clipPath></defs></svg>";
    
    string svgNeon1 = "<svg width='600' height='600' viewBox='0 0 600 600' fill='none' xmlns='http://www.w3.org/2000/svg'><rect width='600' height='600' fill='#0B1124'/><g filter='url(#f0i)'><circle cx='300' cy='300' r='191' fill='#04050B'/><circle cx='300' cy='300' r='188' stroke='#BD00FF' stroke-width='6'/></g><mask id='m0' mask-type='alpha' maskUnits='userSpaceOnUse' x='109' y='109' width='382' height='382'><circle cx='300' cy='300' r='191' fill='#FCFBEF'/></mask><g mask='url(#m0)'><g filter='url(#f1i)'><circle cx='300' cy='300' r='191' fill='#0B1124'/></g>";
    string svgNeon2 = "<circle cx='300' cy='300' r='188' stroke='#BD00FF' stroke-width='6'/></g><defs><filter id='f0i' x='75' y='75' width='450' height='450' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values ='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.741176 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='16.5'/><feComposite in2='hardAlpha' operator='arithmetic' k2='-1' k3='1'/><feColorMatrix type='matrix' values='0 0 0 0 0.729412 0 0 0 0 0 0 0 0 0 0.984314 0 0 0 1 0'/><feBlend mode='normal' in2='shape' result='effect2_is'/></filter><filter id='f1i' x='75' y='75' width='450' height='450' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0.741176 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='4'/><feGaussianBlur stdDeviation='16.5'/><feComposite in2='hardAlpha' operator='arithmetic' k2='-1' k3='1'/><feColorMatrix type='matrix' values='0 0 0 0 0.729412 0 0 0 0 0 0 0 0 0 0.984314 0 0 0 1 0'/><feBlend mode='normal' in2='shape' result='effect2_is'/></filter><filter id='f2' x='86' y='69' width='462' height='462' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset/><feGaussianBlur stdDeviation='17'/><feComposite in2='hardAlpha' operator='out'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 1 0 0 0 0 0.878431 0 0 0 1 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/><feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/></filter><filter id='is' x='86' y='69' width='462' height='462' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur in='SourceAlpha' stdDeviation='17'></feGaussianBlur><feOffset dy='2' dx='3'></feOffset><feComposite in2='SourceAlpha' operator='arithmetic' k2='-1' k3='1' result='shadowDiff'></feComposite><feFlood flood-color='#00FFE0' flood-opacity='0.75'></feFlood><feComposite in2='shadowDiff' operator='in'></feComposite><feComposite in2='SourceGraphic' operator='over' result='firstfilter'></feComposite><feGaussianBlur in='firstfilter' stdDeviation='3' result='blur2'></feGaussianBlur><feOffset dy='-2' dx='-3'></feOffset><feComposite in2='firstfilter' operator='arithmetic' k2='-1' k3='1' result='shadowDiff'></feComposite><feFlood flood-color='#00FFE0' flood-opacity='0.75'></feFlood><feComposite in2='shadowDiff' operator='in'></feComposite><feComposite in2='firstfilter' operator='over'></feComposite></filter></defs></svg>";
    
    string maskOuterPhases1 = "<g filter='url(#is)'><svg width='191' height='382' x='";
    string maskOuterPhases2 = "' y='109'><circle cx='";
    string maskOuterPhases3 = "' cy='191' r='191' fill='#0E1C4B'/><circle cx='";
    string maskOuterPhases4 = "' cy='191' r='194' stroke='#00FFE0' stroke-width='6'/></svg></g><g filter='url(#f2)'><svg width='382' height='382' x='109' y='109'><ellipse cx='191' cy='191' rx='";
    string maskOuterPhases5 = "' ry='191' fill='#0B1124'/><ellipse cx='191' cy='191' rx='";
    string maskOuterPhases6 = "' ry='194' stroke='#00FFE0' stroke-width='6'/></svg></g><rect x='";
    string maskOuterPhases7 = "' y='109' width='191' height='382' fill='#0B1124'/>";
    
    string maskInnerPhases1 = "<g filter='url(#is)'><svg width='382' height='382' x='109' y='109'><ellipse cx='191' cy='191' rx='";
    string maskInnerPhases2 = "' ry='191' fill='#0E1C4B'/><ellipse cx='191' cy='191' rx='";
    string maskInnerPhases3 = "' ry='194' stroke='#00FFE0' stroke-width='6'/></svg><svg width='191' height='382' x='";
    string maskInnerPhases4 = "' y='109'><circle cx='";
    string maskInnerPhases5 = "' cy='191' r='191' fill='#0E1C4B'/><circle cx='";
    string maskInnerPhases6 = "' cy='191' r='194' stroke='#00FFE0' stroke-width='6'/></svg></g>";
    string[] descriptions = [
            'The Moon is our closest celestial body. During its cycle, we can admire a different look every night.',
            "When the Moon moves into the Earth's shadow, we can all enjoy the spectacle of the Blood Moon. Visible only during full Moon.",
            'When the Sun is high and the Moon is low on the horizon, we can see the Honey Moon.',
            'Once a year in Autumn, at harvesting time, the dust from the crops will filter the moonlight, letting us enjoy the Orange Moon.',
            'The Blue Moon has appeared only a few times in history, thanks to the hashes of erupting volcanoes.',
            'A wise man once said: \\"Transcend your mind and the Neon Moon will rise.\\"'
    ];
    string[] names = ["Moon", "Blood Moon", "Honey Moon", "Orange Moon", "Blue Moon", "Neon Moon"];
    string[] colors = ["#fcfbef", "#ff7474", "#f6ed9e", "#ffa95e", "#9bd1e0"];
    string commonDescription = "\\n\\nThis NFT follows the current lunar phase, shifting it every day, without using any external resource (it's 100% on chain). What you see reflects the visibility of the Moon on ";
    string attributes1 = '"attributes":[{"trait_type":"Frequency","value":"';
    string attributes2 = '"},{"trait_type":"Editions","value":"';
    string attributes3 = '"}]'; 
    constructor () ERC1155 ("mooninmotion") {
        _mint(msg.sender, MOON, COMMON_COUNT, "");
        _mint(msg.sender, HONEY, UNCOMMON_COUNT, "");
        _mint(msg.sender, ORANGE, UNCOMMON_COUNT, "");
        _mint(msg.sender, BLOOD, RARE_COUNT, "");
        _mint(msg.sender, BLUE, SUPERRARE_COUNT, "");
        _mint(msg.sender, NEON, UNIQUE_COUNT, "");
    }


    function calculateRadius(int day) public pure returns (uint radius) {
        int dmod = day % 14;
        int max = 20000;
        int r = (max - (max / 7 * dmod)) / 100;
        
        return uint(r > 0 ? r : r * -1);
    }

    function currentMoonDay(int day, int month, int year) public pure returns (int _day) {
        if(month == 1 || month == 2) {
            month = month + 12;
            year = year - 1;
        }
        
        int fa = 10000;

        int a = year / 100 * fa;
        int b = a / 4 / fa * fa;
        int c = 2 * fa - a + b;
        int e = 3652500 * (year + 4716);
        int f = 306001 * (month + 1);
        int jd = c+ day*fa + e + f - 15245000;
        int daysSinceNew = (jd - 24515495000) / fa;

        int cycle = 2953;
        int newMoonsInt = daysSinceNew * 100000 / cycle;
        int newMoonsDec = newMoonsInt - (newMoonsInt / 1000) * 1000;

        return newMoonsDec * cycle / 100000;
    }

    function timestampToDate(uint timestamp) internal pure returns (Date memory _date) {
        int z = int(timestamp) / 86400 + 719468;
        int era = (z >= 0 ? z : z - 146096) / 146097;
        int doe = z - era * 146097;
        int yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int doy = doe - (365 * yoe + yoe/4 - yoe/100);
        int y = yoe + era * 400;
        int mp = (5 * doy + 2) / 153;
        int m = mp + (mp < 10 ? int(3) : -9);
        int d = doy - (153 * mp + 2)/5 + 1;

        return Date({
            day: d, 
            month: m, 
            year: y}
        );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function generateMoon(int day, string memory color) public view returns (string memory) {
        uint r = calculateRadius(day);
        string memory color1 = (day < 8 || day > 21) ? color : "#231336";
        string memory color2 = (day < 8 || day > 21) ? "#231336" : color;
        
        string memory rectPosition = day < 8 || (day >= 15 && day < 22) ? "109" : "300";

        bytes memory _img = abi.encodePacked(svg1, 
            "<circle cx='300' cy='300' r='191' fill='", 
            color1, 
            "'/></g><ellipse cx='300' cy='300' rx='", 
            uint2str(r), 
            "' ry='200' fill='", 
            color2, 
            "'/><rect x='", 
            rectPosition, 
            "' y='109' width='191' height='382' fill='", color2, "'/>", svg2);

        return(string(abi.encodePacked(_img)));
        
    }

    function generateNeonMoon(int day) public view returns (string memory) {
        uint r = calculateRadius(day);

        bytes memory mask;
        if(day < 8) {
            mask = abi.encodePacked(
                maskOuterPhases1,
                "300",
                maskOuterPhases2,
                "0",
                maskOuterPhases3,
                "0",
                maskOuterPhases4,
                uint2str(r),
                maskOuterPhases5,
                uint2str(r + 4),
                maskOuterPhases6,
                "109",
                maskOuterPhases7
            );
        }
        else if (day < 15) {
            mask = abi.encodePacked(
                maskInnerPhases1,
                uint2str(r),
                maskInnerPhases2,
                uint2str(r + 4),
                maskInnerPhases3,
                "300",
                maskInnerPhases4,
                "0",
                maskInnerPhases5,
                "0",
                maskInnerPhases6
            );
        }
        else if(day < 22) {
            mask = abi.encodePacked(
                maskInnerPhases1,
                uint2str(r),
                maskInnerPhases2,
                uint2str(r + 4),
                maskInnerPhases3,
                "109",
                maskInnerPhases4,
                "191",
                maskInnerPhases5,
                "191",
                maskInnerPhases6
            );
        }
        else {
            mask = abi.encodePacked(
                maskOuterPhases1,
                "109",
                maskOuterPhases2,
                "191",
                maskOuterPhases3,
                "191",
                maskOuterPhases4,
                uint2str(r),
                maskOuterPhases5,
                uint2str(r + 4),
                maskOuterPhases6,
                "300",
                maskOuterPhases7
            );
        }
        
        bytes memory _img = abi.encodePacked(
            svgNeon1, 
            mask,
            svgNeon2);

        return(string(abi.encodePacked(_img)));
        
    }

    function getImage(uint tokenId, int moonDay) public view returns (string memory _image) {
        string memory image;
        if(tokenId != NEON) {
            if (tokenId == BLOOD && moonDay != 14) {
                image = generateMoon(moonDay, colors[MOON - 1]);
            }
            else {
                image = generateMoon(moonDay, colors[tokenId - 1]);
            }
        }
        else {
            image = generateNeonMoon(moonDay);
        }

        return image;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint timestamp = block.timestamp;
        Date memory date = timestampToDate(timestamp);
        int moonDay = currentMoonDay(date.day, date.month, date.year);

        string memory image = getImage(tokenId, moonDay);
        
        string memory name = names[tokenId - 1];
        string memory description = descriptions[tokenId - 1];
        string memory wholeDescription = string(abi.encodePacked(
            commonDescription, 
            uint2str(uint(date.day)), 
            "/", 
            uint2str(uint(date.month)), 
            "/", 
            uint2str(uint(date.year)), 
            "."));

        string memory attributes;
        if(tokenId == MOON) {
            attributes = string(abi.encodePacked(attributes1,"Common", attributes2, "29", attributes3));
        }
        else if(tokenId == ORANGE || tokenId == HONEY) {
            attributes = string(abi.encodePacked(attributes1,"Uncommon", attributes2, "14", attributes3));
        }
        else if(tokenId == BLOOD) {
            attributes = string(abi.encodePacked(attributes1,"Rare", attributes2, "7", attributes3));
        }
        else if(tokenId == BLUE) {
            attributes = string(abi.encodePacked(attributes1,"Super Rare", attributes2, "3", attributes3));
        }
        else {
            attributes = string(abi.encodePacked(attributes1,"N/A", attributes2, "1", attributes3));
        }

        bytes memory json = abi.encodePacked('{"name":"', name, '", "description":"', description, wholeDescription, '",', attributes, ', "created_by":"Inner Space", "image":"', image,'"}');

        return string(abi.encodePacked('data:text/plain,',json));
        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

