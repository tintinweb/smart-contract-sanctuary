// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Random.sol";
import "./LootRoom.sol";

library Errors {
    string constant internal OUT_OF_RANGE = "range";
    string constant internal NOT_OWNER = "owner";
    string constant internal ALREADY_CLAIMED = "claimed";
    string constant internal SOLD_OUT = "sold out";
    string constant internal INSUFFICIENT_VALUE = "low ether";
}

contract LootRoomToken is Ownable, Random, ERC721 {
    uint256 constant public AUCTION_BLOCKS = 6650;
    uint256 constant public AUCTION_MINIMUM_START = 1 ether;

    IERC721 immutable private LOOT;
    LootRoom immutable private RENDER;

    mapping (uint256 => bool) private s_ClaimedBags;

    uint256 private s_StartBlock;
    uint256 private s_StartPrice;
    uint256 private s_Lot;

    constructor(LootRoom render, IERC721 loot) ERC721("Loot Room", "ROOM") {
        RENDER = render;
        LOOT = loot;
        _startAuction(0);
    }

    function _generateTokenId() private returns (uint256) {
        return _random() & ~uint256(0xFFFF);
    }

    function _startAuction(uint256 lastPrice) private {
        uint256 oldLot = s_Lot;
        uint256 newLot = oldLot;
        while (newLot == oldLot) {
            // should never need to repeat, but without looping there's a tiny
            // chance the contract gets stuck trying to mint the same token id
            // repeatedly.
            newLot = _generateTokenId();
        }

        s_Lot = newLot;
        s_StartBlock = block.number;
        lastPrice *= 4;
        if (lastPrice < AUCTION_MINIMUM_START) {
            s_StartPrice = AUCTION_MINIMUM_START;
        } else {
            s_StartPrice = lastPrice;
        }
    }

    function getForSale() public view returns (uint256) {
        return s_Lot;
    }

    function getPrice() public view returns (uint256) {
        uint256 currentBlock = block.number - s_StartBlock;
        if (currentBlock >= AUCTION_BLOCKS) {
            return 0;
        } else {
            uint256 startPrice = s_StartPrice;
            uint256 sub = (startPrice * currentBlock) / AUCTION_BLOCKS;
            return startPrice - sub;
        }
    }

    function _buy(uint256 tokenId) private returns (uint256) {
        uint256 lot = s_Lot;
        require(0 == tokenId || tokenId == lot, Errors.SOLD_OUT);

        uint256 price = getPrice();
        require(msg.value >= price, Errors.INSUFFICIENT_VALUE);

        _startAuction(msg.value);

        return lot;
    }

    function safeBuy(uint256 tokenId) external payable returns (uint256) {
        tokenId = _buy(tokenId);
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function buy(uint256 tokenId) external payable returns (uint256) {
        tokenId = _buy(tokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function _claim(uint256 lootTokenId) private returns (uint256) {
        require(0 < lootTokenId && 8001 > lootTokenId, Errors.OUT_OF_RANGE);

        require(!s_ClaimedBags[lootTokenId], Errors.ALREADY_CLAIMED);
        s_ClaimedBags[lootTokenId] = true; // Claim before making any calls out.

        require(LOOT.ownerOf(lootTokenId) == msg.sender, Errors.NOT_OWNER);
        return _generateTokenId() | lootTokenId;
    }

    function safeClaim(uint256 lootTokenId) external returns (uint256) {
        uint256 tokenId = _claim(lootTokenId);
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function claim(uint256 lootTokenId) external returns (uint256) {
        uint256 tokenId = _claim(lootTokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function withdraw(address payable to) external onlyOwner {
        (bool success,) = to.call{value:address(this).balance}("");
        require(success, "failed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return RENDER.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LootRoomErrors {
    string constant internal OUT_OF_RANGE = "out of range";
    string constant internal NO_LOOT = "no loot bag";
}

contract LootRoom {
    // Opinion
    // Size
    // Description
    // Material
    // Biome
    // Containers

    function biomeName(uint8 val) private pure returns (string memory) {
        if (184 >= val) { return "Room"; }
        if (200 >= val) { return "Pit"; }
        if (216 >= val) { return "Lair"; }
        if (232 >= val) { return "Refuge"; }
        if (243 >= val) { return "Shop"; }
        if (254 >= val) { return "Shrine"; }
        return "Treasury";
    }

    function roomType(uint256 tokenId) private pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[0]);
        return biomeName(val);
    }

    function roomMaterial(uint256 tokenId) public pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[1]);

        if (128 >= val) { return "Stone"; }
        if (200 >= val) { return "Wooden"; }
        if (216 >= val) { return "Mud"; }
        if (232 >= val) { return "Brick"; }
        if (243 >= val) { return "Granite"; }
        if (254 >= val) { return "Bone"; }
        return "Marble";
    }

    function roomContainer(
        uint256 tokenId,
        uint256 idx
    ) public pure returns (string memory) {
        require(4 > idx, LootRoomErrors.OUT_OF_RANGE);
        uint8 val = uint8(bytes32(tokenId)[2 + idx]);
        // 2, 3, 4, 5

        if (229 >= val) { return ""; }
        if (233 >= val) { return "Barrel"; }
        if (237 >= val) { return "Basket"; }
        if (240 >= val) { return "Bucket"; }
        if (243 >= val) { return "Chest"; }
        if (245 >= val) { return "Coffer"; }
        if (247 >= val) { return "Pouch"; }
        if (249 >= val) { return "Sack"; }
        if (251 >= val) { return "Crate"; }
        if (253 >= val) { return "Shelf"; }
        if (255 >= val) { return "Box"; }
        return "Strongbox";
    }

    function roomOpinion(uint256 tokenId) public pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[6]);

        if (229 >= val) { return "Unremarkable"; }
        if (233 >= val) { return "Unusual"; }
        if (237 >= val) { return "Interesting"; }
        if (240 >= val) { return "Strange"; }
        if (243 >= val) { return "Bizarre"; }
        if (245 >= val) { return "Curious"; }
        if (247 >= val) { return "Memorable"; }
        if (249 >= val) { return "Remarkable"; }
        if (251 >= val) { return "Notable"; }
        if (253 >= val) { return "Peculiar"; }
        if (255 >= val) { return "Puzzling"; }
        return "Weird";
    }

    function roomSize(uint256 tokenId) public pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[7]);

        if (  0 == val) { return "Infinitesimal"; }
        if (  2 >= val) { return "Microscopic"; }
        if (  4 >= val) { return "Lilliputian"; }
        if (  7 >= val) { return "Minute"; }
        if ( 10 >= val) { return "Minuscule"; }
        if ( 14 >= val) { return "Miniature"; }
        if ( 18 >= val) { return "Teensy"; }
        if ( 23 >= val) { return "Cramped"; }
        if ( 28 >= val) { return "Measly"; }
        if ( 34 >= val) { return "Puny"; }
        if ( 40 >= val) { return "Wee"; }
        if ( 47 >= val) { return "Tiny"; }
        if ( 54 >= val) { return "Baby"; }
        if ( 62 >= val) { return "Confined"; }
        if ( 70 >= val) { return "Undersized"; }
        if ( 79 >= val) { return "Petite"; }
        if ( 88 >= val) { return "Little"; }
        if ( 98 >= val) { return "Cozy"; }
        if (108 >= val) { return "Small"; }

        if (146 >= val) { return "Average-Sized"; }

        if (156 >= val) { return "Good-Sized"; }
        if (166 >= val) { return "Large"; }
        if (175 >= val) { return "Sizable"; }
        if (184 >= val) { return "Big"; }
        if (192 >= val) { return "Oversized"; }
        if (200 >= val) { return "Huge"; }
        if (207 >= val) { return "Extensive"; }
        if (214 >= val) { return "Giant"; }
        if (220 >= val) { return "Enormous"; }
        if (226 >= val) { return "Gigantic"; }
        if (231 >= val) { return "Massive"; }
        if (236 >= val) { return "Immense"; }
        if (240 >= val) { return "Vast"; }
        if (244 >= val) { return "Colossal"; }
        if (247 >= val) { return "Titanic"; }
        if (250 >= val) { return "Humongous"; }
        if (252 >= val) { return "Gargantuan"; }
        if (254 >= val) { return "Monumental"; }

        return "Immeasurable";
    }

    function roomModifier(uint256 tokenId) public pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[8]);

        if ( 15 >= val) { return "Sweltering"; }
        if ( 31 >= val) { return "Freezing"; }
        if ( 47 >= val) { return "Dim"; }
        if ( 63 >= val) { return "Bright"; }
        if ( 79 >= val) { return "Barren"; }
        if ( 95 >= val) { return "Plush"; }
        if (111 >= val) { return "Filthy"; }
        if (127 >= val) { return "Dingy"; }
        if (143 >= val) { return "Airy"; }
        if (159 >= val) { return "Stuffy"; }
        if (175 >= val) { return "Rough"; }
        if (191 >= val) { return "Untidy"; }
        if (207 >= val) { return "Dank"; }
        if (223 >= val) { return "Moist"; }
        if (239 >= val) { return "Soulless"; }
        return "Exotic";
    }

    function exitType(
        uint256 tokenId,
        uint256 direction
    ) public pure returns (string memory) {
        require(4 > direction, LootRoomErrors.OUT_OF_RANGE);
        uint8 val = uint8(bytes32(tokenId)[9 + direction]);
        // 9, 10, 11, 12
        return biomeName(val);
    }

    function exitPassable(
        uint256 tokenId,
        uint256 direction
    ) public pure returns (bool) {
        require(4 > direction, LootRoomErrors.OUT_OF_RANGE);
        uint8 val = uint8(bytes32(tokenId)[13 + direction]);
        // 13, 14, 15, 16
        return 128 > val;
    }

    function lootId(uint256 tokenId) public pure returns (uint256) {
        uint256 lootTokenId = tokenId & 0xFFFF;
        require(0 < lootTokenId && 8001 > lootTokenId, LootRoomErrors.NO_LOOT);
        return lootTokenId;
    }

    function _svgNorth(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<text x='250' y='65' font-size='20px'><tspan>",
            exitType(tokenId, 0),
            "</tspan></text>",
            (exitPassable(tokenId, 0) ?
                "<path d='m250 15 15 26h-30z'/>"
                    : "<rect x='75' y='75' width='350' height='15'/>")

        ));
    }

    function _svgEast(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<text transform='rotate(90)' x='250' y='-435'><tspan>",
            exitType(tokenId, 1),
            "</tspan></text>",
            (exitPassable(tokenId, 1) ?
                "<path d='m483 248-26 15v-30z'/>"
                : "<rect x='410' y='75' width='15' height='350'/>")

        ));
    }

    function _svgSouth(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<text transform='scale(-1)' x='-250' y='-435'><tspan>",
            exitType(tokenId, 2),
            "</tspan></text>",
            (exitPassable(tokenId, 2) ?
                "<path d='m250 481 15-26h-30z'/>"
                : "<rect x='75' y='410' width='350' height='15'/>")
        ));
    }

    function _svgWest(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<text transform='rotate(-90)' x='-250' y='65'><tspan>",
            exitType(tokenId, 3),
            "</tspan></text>",
            (exitPassable(tokenId, 3) ?
                "<path d='m17 248 26 15v-30z'/>"
                : "<rect x='75' y='75' width='15' height='350'/>")
        ));
    }

    function _svgRoom(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<text x='125' y='130' text-align='left' text-anchor='start'><tspan>",
            article(tokenId),
            "</tspan><tspan x='125' dy='25'>",
            roomOpinion(tokenId), "</tspan><tspan x='125' dy='25'>",
            roomSize(tokenId), "</tspan><tspan x='125' dy='25'>",
            roomModifier(tokenId), "</tspan><tspan x='125' dy='25'>",
            roomMaterial(tokenId), "</tspan><tspan x='125' dy='25'>",
            roomType(tokenId), ".</tspan><tspan x='125' dy='25'>&#160;</tspan>"
        ));
    }

    function _svgContainer(
        uint256 tokenId,
        uint256 idx
    ) private pure returns (string memory) {
        string memory container = roomContainer(tokenId, idx);
        if (bytes(container).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(
                "<tspan x='125' dy='25'>", container, "</tspan>\n"
            ));
        }
    }

    function _svgEdges(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(
            _svgNorth(tokenId),
            _svgEast(tokenId),
            _svgSouth(tokenId),
            _svgWest(tokenId)
        ));
    }

    function article(uint256 tokenId) public pure returns (string memory) {
        uint8 val = uint8(bytes32(tokenId)[6]);
        if (237 >= val) { return "An"; }
        return "A";
    }

    function image(uint256 tokenId) public pure returns (string memory) {
        bytes memory start = abi.encodePacked(
            "<?xml version='1.0' encoding='UTF-8'?>"
            "<svg version='1.1' viewBox='0 0 500 500' xmlns='http://www.w3.org/2000/svg' style='background:#000'>"
            "<g fill='#fff' font-size='20px' font-family='serif' text-align='center' text-anchor='middle'>",

            // Edge Indicators
            _svgEdges(tokenId)
        );

        bytes memory end = abi.encodePacked(
            // Room
            _svgRoom(tokenId),

            // I bloody hate the stack...
            _svgContainer(tokenId, 0),
            _svgContainer(tokenId, 1),
            _svgContainer(tokenId, 2),
            _svgContainer(tokenId, 3),

            "</text>"
            "</g>"
            "</svg>"
        );

        return string(abi.encodePacked(start, end));
    }

    function tokenName(uint256 tokenId) public pure returns (string memory) {
        uint256 num = uint256(keccak256(abi.encodePacked(tokenId))) & 0xFFFFFF;

        return string(abi.encodePacked(
            roomOpinion(tokenId),
            " ",
            roomType(tokenId),
            " #",
            Strings.toString(num)
        ));
    }

    function tokenDescription(
        uint256 tokenId
    ) public pure returns (string memory) {
        uint256 c;
        c  = bytes(roomContainer(tokenId, 0)).length == 0 ? 0 : 1;
        c += bytes(roomContainer(tokenId, 1)).length == 0 ? 0 : 1;
        c += bytes(roomContainer(tokenId, 2)).length == 0 ? 0 : 1;
        c += bytes(roomContainer(tokenId, 3)).length == 0 ? 0 : 1;

        string memory containers;
        if (0 == c) {
            containers = "";
        } else if (1 == c) {
            containers = "You find one container.";
        } else {
            containers = string(abi.encodePacked(
                "You find ",
                Strings.toString(c),
                " containers."
            ));
        }

        bytes memory exits = abi.encodePacked(
            exitPassable(tokenId, 0) ? string(abi.encodePacked(" To the North, there is a ", exitType(tokenId, 0), ".")) : "",
            exitPassable(tokenId, 1) ? string(abi.encodePacked(" To the East, there is a ", exitType(tokenId, 1), ".")) : "",
            exitPassable(tokenId, 2) ? string(abi.encodePacked(" To the South, there is a ", exitType(tokenId, 2), ".")) : "",
            exitPassable(tokenId, 3) ? string(abi.encodePacked(" To the West, there is a ", exitType(tokenId, 3), ".")) : ""
        );

        return string(abi.encodePacked(
            article(tokenId),
            " ",
            roomOpinion(tokenId),
            " ",
            roomType(tokenId),
            " with a mostly ",
            roomMaterial(tokenId),
            " construction. Compared to other rooms it is ",
            roomSize(tokenId),
            ", and feels ",
            roomModifier(tokenId),
            ". ",
            containers,
            exits
        ));
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        bytes memory json = abi.encodePacked(
            "{\"description\":\"", tokenDescription(tokenId),"\",\"name\":\"",
            tokenName(tokenId),
            "\",\"attributes\":[{\"trait_type\":\"Opinion\",\"value\":\"",
            roomOpinion(tokenId),
            "\"},{\"trait_type\":\"Size\",\"value\":\"",
            roomSize(tokenId)
        );

        bytes memory json2 = abi.encodePacked(
            "\"},{\"trait_type\":\"Description\",\"value\":\"",
            roomModifier(tokenId),
            "\"},{\"trait_type\":\"Material\",\"value\":\"",
            roomMaterial(tokenId),
            "\"},{\"trait_type\":\"Biome\",\"value\":\"",
            roomType(tokenId),
            "\"}],\"image\":\"data:image/svg+xml;base64,",
            Base64.encode(bytes(image(tokenId))),
            "\"}"
        );

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(json, json2))
        ));
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.6;

abstract contract Random {
    uint256 private s_Previous = 0;

    function _random() internal returns (uint256) {
        // Oh look, random number generation on-chain. What could go wrong?

        unchecked {
            uint256 bitfield;

            for (uint ii = 1; ii < 257; ii++) {
                uint256 bits = uint256(blockhash(block.number - ii));
                bitfield |= bits & (1 << (ii - 1));
            }

            uint256 value = uint256(keccak256(abi.encodePacked(bytes32(bitfield))));
            s_Previous ^= value;

            return uint256(keccak256(abi.encodePacked(s_Previous)));
        }
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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

