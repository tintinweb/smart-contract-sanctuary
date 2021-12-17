// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
_______________________________________________,╥▄▓█████________________________
________________________________________╓▄▄▄▒└    └╙▀▀██▌_______________________
_________________________________,-≤░░╙▀███████▓▄▄ ,»ⁿ"_└_______________________
__________________________,▄▓▓████▓▄░░░░░┐╙╙▀█▀▀╙└______________________________
_____________________ ▓▒░░░░│╙▀▀███████▀"_______________________________________
______________________║█╬╬Å▄▄░░╚²"└¬____________________________________________
_______________________▓▒░░░╚▓,_________________________________________________
_______________________█▒░▒▒▒░╠╦''╓▓████▀││││,▓████▀│░░░▄▓▌_____________________
_______________________█▓╬╩╩╩╩╬╬▓█████╙'░░│▄█████▀│░░│▄███▌_____________________
_______________________▀▀▄▄▄▄▄▓█████▄▄▄▄▄▓█████▄▄▄▄▄█████▀¬_____________________
_________________________███████████████████████████████▌_______________________
_________________________██▓▓███████ bt3gl █████████████▌_______________________
_________________________███████████████████████████████▌_______________________
_________________________██▓▓███ FilmmakerDAO ██████████▌_______________________
_________________________███████████████████████████████▌_______________________
_________________________▓██████████▓████████╫██████████`_______________________
__________________________└▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀_________________________
______________________________________________________________________________*/


import {ERC721} from "../utils/ERC721.sol";
import {Ownable} from "../utils/Ownable.sol";
import {SafeMath} from "../utils/SafeMath.sol";
import {Address} from "../utils/Address.sol";
import {Base64} from "../utils/Base64.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {ERC721Enumerable} from "../utils/ERC721Enumerable.sol";



contract FilmmakerDAO is ERC721Enumerable, ReentrancyGuard, Ownable {

    string[] private genres = [
        "chick flick ",
        "comedy ",
        "action ",
        "fantasy ",
        "horror ",
        "romance ",
        "western ",
        "thriller ",
        "rom-com ",
        "drama ",
        "romantic thriller ",
        "black comedy ",
        "anime ",
        "mumblecore ",
        "musical ",
        "korean new wave ",
        "acid western ",
        "Dogme 95 ",
        "french new wave ",
        "italian neo realism ",
        "pulp ",
        "noir ",
        "screwball comedy ",
        "epic ",
        "psychological thriller ",
        "torture porn ",
        "snuff ",
        "samurai ",
        "wuXia ",
        "bollywood ",
        "gangster ",
        "courtroom ",
        "mockumentary ",
        "monster "
    ];

    string[] private medium = [
        "short film,",
        "feature film,",
        "episodic,",
        "limited series,",
        "podcast,",
        "VR film,",
        "narrative audio,",
        "IMAX film,",
        "Tik Tok video,",
        "NFT video collection,",
        "teleplay,",
        "Youtube series",
        "theatre production,"
    ];

    string[] private cities = [
        "London,",
        "New York,",
        "Los Angeles,",
        "Atlanta,",
        "Miami,",
        "Buenos Aires,",
        "Curitiba,",
        "Lisbon,",
        "Berlin,",
        "New Orleans,",
        "Detroit,",
        "New Zealand,",
        "Australia,",
        "Marfa,",
        "Bucharest,",
        "Hong Kong,",
        "Jackson,",
        "Budapest,",
        "Sao Paulo,",
        "Lagos,",
        "Paris,",
        "Tokyo,",
        "Barcelona,",
        "Goa,",
        "Rio de Janeiro,",
        "Atlantis,",
        "New Orleans,",
        "Middle Earth,",
        "Shaghai,",
        "Kyoto,",
        "Mars,"
    ];

    string[] private archetypes = [
        " lover ",
        " witch ",
        " hero ",
        " magician ",
        " outlaw ",
        " shaman ",
        " teenager ",
        " writer ",
        " monarch ",
        " guy next door ",
        " supervillain ",
        " anarchist ",
        " nihilist ",
        " poet ",
        " dude ",
        " nomad ",
        " anti-hero ",
        " Dark Lord ",
        " Wojak ",
        " Ohmie ",
        " Soyjak ",
        " Pepe ",
        " Tetranode ",
        " Sisyphus ",
        " God ",
        " pixie girl ",
        " Timothee type ",
        " clown ",
        " superhero "
    ];

    string[] private verbs = [
        " steals  ",
        " kisses ",
        " runs away from ",
        " fights against ",
        " escapes with ",
        " falls on ",
        " thinks about ",
        " drives away from ",
        " tries to kidnap  ",
        " makes love with ",
        " walks away from ",
        " writes about ",
        " yells at ",
        " eats a piece of ",
        " plays with ",
        " jumps into ",
        " sings with ",
        " dances with ",
        " sleeps with ",
        " flirts with ",
        " marries ",
        " messes around with ",
        " dreams about "
    ];

    string[] private objects = [
        "a stunning painting",
        "a shinning diamond",
        "a bag full of money",
        "a tiny skateboard",
        "a dead phone",
        "an empty coffee cup",
        "a can of diet coke",
        "a large red axe",
        "a toy gun",
        "a small plastic bird",
        "a broken lighter",
        "a giant bowtie",
        "a golf cart",
        "a bowl full of pasta",
        "an old laptop",
        "a map to a treasure",
        "a trash can",
        "an incriminating photo",
        "a shiny watch",
        "a purple doll",
        "a half doobie",
        "a giant ugly sweater",
        "a jug full of drugs",
        "a Magick book",
        "a teddy bear",
        "a poisoned apple",
        "a green balloon"
    ];

    string[] private titles = [
        "acclaimed",
        "recognized",
        "Youtube famous",
        "renowned",
        "a BAFTA winner",
        "a Golden Globe winner",
        "a DGA Award winner",
        "distinguished",
        "Instagram famous",
        "Twitter popular",
        "an Independent Spirit winner",
        "a MTV Awards winner",
        "respected",
        "an Oscar winner",
        "Teen Choice Awards winner",
        "famed",
        "a rockstar"
    ];

    string[] private adjetives = [
        "adorable ",
        "vivid ",
        "aggressive ",
        "annoying ",
        "awful ",
        "intense ",
        "clever ",
        "cheerful ",
        "charming ",
        "courageous ",
        "cruel ",
        "defiant ",
        "disturbed ",
        "brilliant ",
        "delightful ",
        "dark ",
        "cute ",
        "terrible ",
        "silly ",
        "grotesque ",
        "grumpy ",
        "hilarious ",
        "horrible ",
        "glorious ",
        "magnificent ",
        "naughty ",
        "repulsive ",
        "wicked ",
        "sexy ",
        "ingenious ",
        "genius ",
        "dark ",
        "heroic ",
        "intrepid ",
        "romantic ",
        "mad ",
        "stoned ",
        "funny ",
        "spooky ",
        "sad ",
        "powerful ",
        "raging ",
        "creepy "
    ];

    string[] private locations = [
        "under a bridge.",
        "in some park.",
        "in the mall.",
        "in the kitchen.",
        "at Starbucks.",
        "in the airport.",
        "in the church.",
        "in the school.",
        "in the supermarket.",
        "in the Metaverse.",
        "in a desert.",
        "in a forest.",
        "in a bathroom.",
        "in a shower.",
        "in a jungle.",
        "in a deli.",
        "at the therapist's office.",
        "at the mother in law's bedroom.",
        "in a golf course.",
        "in a bowling alley.",
        "at the DMV.",
        "at McDonald's.",
        "at 7-Eleven."
    ];

    string[] private colors = [
        "#33E0FF",
        "#FFF033",
        "#33FF8D",
        "#FF33D4",
        "#FF8D33",
        "#EE5967",
        "#726EB2"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getGenres(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "A", genres);
    }

    function getMediums(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "AB", medium);
    }

    function getCities(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABC", cities);
    }

    function getArchetypes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCD", archetypes);
    }

    function getVerbs(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCDE", verbs);
    }

    function getObjects(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCDEF", objects);
    }

    function getLocations(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCDEFG", locations);
    }

    function getAdjectives(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCDEFGI", adjetives);
    }

    function getTitles(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABCDEFGIH", titles);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function getColor(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COLORS", colors);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[27] memory parts;
        string memory idstr = toString(tokenId);

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.cool {fill: ';
        parts[1] = getColor(tokenId);
        parts[2] = '; } .base { fill: white; font-family: arial; font-size: 12px; </style><rect width="100%" height="100%" fill="black" /><text x="40" y="100" class="cool">';
        parts[3] = 'You are filmmaker #';
        parts[4] = idstr;
        parts[5] = '</text><text x="40" y="140" class="base">';
        parts[6] = 'You are ';
        parts[7] = getTitles(tokenId);
        parts[8] = ' for your ';
        parts[9] = '</text><text x="40" y="160" class="base">';
        parts[10] = getGenres(tokenId);
        parts[11] = getMediums(tokenId);
        parts[12] = '</text><text x="40" y="180" class="base">';
        parts[13] = 'particularly for that ';
        parts[14] = getAdjectives(tokenId+137);
        parts[15] = ' scene in ';
        parts[16] = getCities(tokenId);
        parts[17] = '</text><text x="40" y="200" class="base">';
        parts[18] = ' when the ';
        parts[19] = getAdjectives(tokenId);
        parts[20] = getArchetypes(tokenId);
        parts[21] = '</text><text x="40" y="220" class="base">';
        parts[22] = getVerbs(tokenId);
        parts[23] = getObjects(tokenId);
        parts[24] = '</text><text x="40" y="240" class="base">';
        parts[25] = getLocations(tokenId);
        parts[26] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]));
        output = string(abi.encodePacked(output, parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18]));
        output = string(abi.encodePacked(output, parts[19], parts[20], parts[21], parts[22], parts[23], parts[24], parts[25], parts[26]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Filmmaker #', toString(tokenId), '", "description": "The Storytelling card collection is the FilmmakerDAO generative storytelling NFT series for season 0. It is a randomized story generated and stored on-chain. We thought Loot was a great project to spur further creative thought, and we hope Filmmakers can carry on that idea. Feel free to use your Storyteller Card in any way you want!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function mint(uint256 tokenId)
        public
        payable
        isCorrectPrice(SALE_PRICE)
        {
        require(tokenId > 0 && tokenId < 1338, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 1337 && tokenId < 1999, "Reserved Token ID");
        _safeMint(owner(), tokenId);
    }

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

    constructor() ERC721("Storyteller Card", "FILMMAKER") Ownable() {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "../utils/Strings.sol";
import {Address} from "../utils/Address.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/ERC165.sol";
import {IERC165} from "../utils/IERC165.sol";
import {IERC721, IERC721Metadata, IERC721Receiver} from "../utils/IERC721.sol";


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "approval to current story-owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "approved query for nonexistent story-card");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "approve to story-caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "transfer to non ERC721Receiver"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "transfer not own");
        require(to != address(0), "transfer to 0 address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("transfer to non-Receiver");
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Context} from "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    uint256 public constant SALE_PRICE = 0.05 ether;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier isCorrectPrice(uint256 price) {
        require(
            msg.value >= price, "Not enough ETH sent: check price.");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
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


library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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

            if (returndata.length > 0) {
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
pragma solidity ^0.8.4;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
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
pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721} from "../utils/IERC721.sol";
import {ERC721} from "../utils/ERC721.sol";
import {IERC165} from "../utils/IERC165.sol";


interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Strings {
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

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC165} from "../utils/IERC165.sol";


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC165} from "../utils/IERC165.sol";


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}