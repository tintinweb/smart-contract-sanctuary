/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller isn't the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: the new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
        require(success, "Address: unable to send value, recipient may have reverted");
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


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


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
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index is out of bounds");
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

interface HolderInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Pupi is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public price = 10000000000000000; //0.01 ETH

    address public holdersAddress = 0xA28aA564C639C8Ed6ceCFad258223dBF0071Dd07;
    HolderInterface public holderContract = HolderInterface(holdersAddress);
 
    string[] private randomLines = [
        "rain falls hard",
        "men are pigs",
        "green like summer",
        "red like tulips",
        "purple like mother's blouse",
        "orange like a samba",
        "hear thine calling",
        "the body of man",
        "who for but to wit",
        "after a new moon",
        "who among us",
        "softly but for wherefor what",
        "make me",
        "on a lost highway",
        "made to be broken",
        "it was dark",
        "my knees shook",
        "my boots quaked",
        "teach me o womanly spirit ",
        "big girls don't cry",
        "are we dancer?",
        "and atlas wept",
        "thine kingdom cum",
        "viva la vida"
    ];
    string[] private followedByAnother = [ // or followed by a noun
        "for if not now",
        "like i always say",
        "my father said to me",
        "my mother said to me"
    ];

    string[] private followedByNoun = [
        "and filled with ",
        "i yearn for",
        "i lust after",
        "i feel like",
        "i taste of",
        "i smell of",
        "show me how to",
        "smells like",
        "blue is the color of",
        "or is that just",
        "i met a boy named",
        "i met a girl named",
        "my mother's name was",
        "my father's name was",
        "feels like"
    ];

    string[] private randomNouns = [
        "my fragile appendage",
        "my glistening ovaries",
        "my shimmering organ",
        "my pulsing womb",
        "my orgasmic harp",
        "the well of my body",
        "my quivering spear",
        "my girlish grapevine",
        "tulips in the rain",
        "cannibals",
        "jade egg",
        "glass houses",
        "sisyphus",
        "prostate",
        "baguette",
        "urine",
        "blood",
        "smegma",
        "sombrero",
        "play misty for me",
        "disk jockey",
        "halogen lamp",
        "gustavo",
        "portuguese men",
        "shredded wheat",
        "porcelain",
        "sprained ankle",
        "matisiyahu",
        "grandfather",
        "grandmother",
        "father",
        "mother",
        "uncle",
        "aunt",
        "shark week",
        "my lovely lady hump",
        "placenta",
        "bush",
        "sausage machine",
        "pasta maker",
        "pesto",
        "broken headlights",
        "poo sandwich",
        "cement truck",
        "dump truck",
        "pilgrim's lament",
        "smokey and the bandit",
        "foreskin",
        "foreskin troubles",
        "amadeus",
        "emptiness",
        "fullness",
        "horniness",
        "californication",
        "ice cube orgasm",
        "my first love",
        "pants tent",
        "my mother's boyfriend",
        "(borat voice) my wife",
        "my womb",
        "gabagool",
        "italian people",
        "pina coladas"
    ];

    string[] private nftNouns = [
        "my wife's boyfriend",
        "vitalik",
        "bored ape",
        "punk",
        "penguin",
        "cool cat",
        "wgmi",
        "ngmi",
        "wagmi",
        "afaik"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getRandomLine(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RANDOM", randomLines);
    }
    
    function getFollowedByAnother(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FANOTHER", followedByAnother);
    }
    
    function getFollowedByNoun(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FNOUN", followedByNoun);
    }
    
    function getRandomNoun(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RNOUN", randomNouns);
    }

    function getNftNoun(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NFTNOUN", nftNouns);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(output));
        return output;
    }

    function decideSize(uint256 tokenId) internal pure returns (uint) {
        uint256 rand = random(string(abi.encodePacked("SIZE", toString(tokenId))));
        uint size = rand % 3;
        return size;
    }

    function getOption(uint256 tokenId, uint size, uint item) public pure returns (uint) {
        uint256 rand = random(string(abi.encodePacked("SIZE", toString(tokenId), item)));
        return rand % size;
    }

    function conditionalFunctionCall(string memory strFunc, uint256 tokenId) public view returns (string memory returnVal) {
        if (keccak256(abi.encodePacked(strFunc)) == keccak256(abi.encodePacked("randomLines"))) {
            return getRandomLine(tokenId);
        }
        if (keccak256(abi.encodePacked(strFunc)) == keccak256(abi.encodePacked("followedByAnother"))) {
            return getFollowedByAnother(tokenId);
        }
        if (keccak256(abi.encodePacked(strFunc)) == keccak256(abi.encodePacked("followedByNoun"))) {
            return getFollowedByNoun(tokenId);
        }
        if (keccak256(abi.encodePacked(strFunc)) == keccak256(abi.encodePacked("randomNouns"))) {
            return getRandomNoun(tokenId);
        }
        if (keccak256(abi.encodePacked(strFunc)) == keccak256(abi.encodePacked("nftNouns"))) {
            return getNftNoun(tokenId);
        }
    }

    function followedByChecker(string memory prev, string[] memory all, string[] memory fNoun, string[] memory fAll, uint256 tokenId, uint item, bool lastItem) public pure returns (string memory) {
        if (lastItem == true) {
            return all[getOption(tokenId, all.length, item)];
        }
        if (keccak256(abi.encodePacked(prev))  == keccak256(abi.encodePacked("followedByAnother"))) {
            return fAll[getOption(tokenId, fAll.length, item)];
        } else if (keccak256(abi.encodePacked(prev))  == keccak256(abi.encodePacked("followedByNoun"))) {
            return fNoun[getOption(tokenId, fNoun.length, item)];
        } else {
            return all[getOption(tokenId, all.length, item)];
        }
    }

    function generateCalls(uint256 tokenId, uint size) public pure returns (string[] memory calls) {
        string[] memory allOptions = new string[](5);
        allOptions[0] = "randomLines";
        allOptions[1] = "followedByAnother";
        allOptions[2] = "followedByNoun";
        allOptions[3] = "randomNouns";
        allOptions[4] = "nftNouns";

        string[] memory nounOptions = new string[](2);
        nounOptions[0] = "randomNouns";
        nounOptions[1] = "nftNouns";

        string[] memory followedByOptions = new string[](3);
        followedByOptions[0] = "randomLines";
        followedByOptions[1] = "randomNouns";
        followedByOptions[2] = "nftNouns";

        
        if (size == 2) {
            calls  = new string[](2);
            string memory init = allOptions[getOption(tokenId, allOptions.length, 1)];
            calls[0] = init;
            calls[1] = followedByChecker(init, allOptions, nounOptions, followedByOptions, tokenId, 2, true);
            return calls;
        }
        if (size == 3) {
            calls = new string[](3);
            string memory init = allOptions[getOption(tokenId, allOptions.length, 1)];
            calls[0] = init;
            string memory second = followedByChecker(init, allOptions, nounOptions, followedByOptions, tokenId, 2, false);
            calls[1] = second;
            calls[2] = followedByChecker(second, allOptions, nounOptions, followedByOptions, tokenId, 3, true);
            return calls;
        }
        if (size == 4) {
            calls = new string[](4);
            string memory init = allOptions[getOption(tokenId, allOptions.length, 1)];
            calls[0] = init;
            string memory second = followedByChecker(init, allOptions, nounOptions, followedByOptions, tokenId, 2, false);
            calls[1] = second;
            string memory third = followedByChecker(second, allOptions, nounOptions, followedByOptions, tokenId, 3, false);
            calls[2] = third;
            calls[3] = followedByChecker(third, allOptions, nounOptions, followedByOptions, tokenId, 4, true);
            return calls;
        }
        if (size == 5) {
            calls = new string[](5);
            string memory init = allOptions[getOption(tokenId, allOptions.length, 1)];
            calls[0] = init;
            string memory second = followedByChecker(init, allOptions, nounOptions, followedByOptions, tokenId, 2, false);
            calls[1] = second;
            string memory third = followedByChecker(second, allOptions, nounOptions, followedByOptions, tokenId, 3, false);
            calls[2] = third;
            string memory fourth = followedByChecker(third, allOptions, nounOptions, followedByOptions, tokenId, 4, false);
            calls[3] = fourth;
            calls[4] = followedByChecker(fourth, allOptions, nounOptions, followedByOptions, tokenId, 5, true);
            return calls;
        }


    }

    



    function tokenURI(uint256 tokenId) override public view returns (string memory output) {
        uint size = decideSize(tokenId);
        size += 2;
        string[] memory calls =  generateCalls(tokenId, size);
        string[] memory parts = new string[](10);
        uint partsLen = 0;
        uint256 startY = 20;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        partsLen += 1;
        for (uint i = 0; i < size; i++) {
            parts[partsLen] = conditionalFunctionCall(calls[i], tokenId);
            partsLen += 1;
            if (i == size - 1) {
                startY += 40;
                parts[partsLen] = string(abi.encodePacked('</text><text x="10" y="', toString(startY), '" class="base">'));
                partsLen += 1;
                parts[partsLen] = '- pupi kaur';
                partsLen += 1;
                parts[partsLen] = '</text></svg>';
            } else {
                startY += 40;
                parts[partsLen] = string(abi.encodePacked('</text><text x="10" y="', toString(startY), '" class="base">'));
            }
            partsLen += 1;
        }
        if (size == 2) {
            output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "poem #', toString(tokenId), '", "description": "pupi kaur poetry \n is a collection of \n 10,000 very-serious on-chain poems \n -pupi kaur", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
        }
        if (size == 3) {
            output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "poem #', toString(tokenId), '", "description": "pupi kaur poetry \n is a collection of \n 10,000 very-serious on-chain poems \n -pupi kaur", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
        }
        if (size == 4) {
            output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
            output = string(abi.encodePacked(output, parts[9], parts[10]));
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "poem #', toString(tokenId), '", "description": "pupi kaur poetry \n is a collection of \n 10,000 very-serious on-chain poems \n -pupi kaur", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
        }
        if (size == 5) {
            output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
            output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12]));
            
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "poem #', toString(tokenId), '", "description": "pupi kaur poetry \n is a collection of \n 10,000 very-serious on-chain poems \n -pupi kaur", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
        }


    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 0 && tokenId <= 10000, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] < 10000, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
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
    
    constructor() ERC721("Pupi Kaur", "PUPI") Ownable() {}
}

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