/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed to, uint indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);    
    
    function balanceOf(address owner) external view returns (uint);
    function ownerOf(uint tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function approve(address to, uint tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}

interface IERC1155Metadata_URI {
    function uri(uint tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint);
    function tokenByIndex(uint index) external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint);
}

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes memory data) external returns(bytes4);
}

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC721Enumerable, IERC1155Metadata_URI {
    
    //Strings
    using Strings for uint;
    using Strings for address;

    //IERC721
    mapping(uint => address) _owners;
    mapping(address => uint) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    //IERC721Enumerable
    uint256[] private _allTokens;    
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;    
    mapping(uint256 => uint256) private _ownedTokensIndex;        
    
    //IERC721Metadata
    string _name;
    string _symbol;
    
    mapping(uint256 => string) _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns(string memory) {
        return _name;
    }

    function symbol() public override view returns(string memory) {
        return _symbol;
    }

    function tokenURI(uint tokenId) public override virtual view returns (string memory) {
        return _tokenURIs[tokenId];
    }    

    //IERC1155Metadata_URI
    function uri(uint tokenId) public override virtual view returns (string memory) {        
        return tokenURI(tokenId);
    }     

    //IERC165
    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return 
            interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId            
            || interfaceId == type(IERC721Enumerable).interfaceId
            || interfaceId == type(IERC1155Metadata_URI).interfaceId;            
    }              

    //IERC721
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "owner is zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "token is not exists");
        return owner;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function approve(address to, uint tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "approval status for self");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "caller is not token owner or approval for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_owners[tokenId] != address(0), "token is not exists");
        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint tokenId) public override {        
        require(from != address(0), "tranfer from zero address");
        require(to != address(0), "transfer to zero address");

        address owner = ownerOf(tokenId);
        require(owner == from, "transfer from is not token owner");
        
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approved");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;                        
        
        emit Transfer(from, to, tokenId);

        //IERC721Enumerable
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {        
        transferFrom(from, to, tokenId);

        require(_checkOnERC721Received(from, to, tokenId, data), "transfer to non ERC721Receiver implementer");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    //IERC721Enumerable
    function totalSupply() public override view returns (uint) {
        return _allTokens.length;
    }

    function tokenByIndex(uint index) public override view returns (uint) {
        require(index < _allTokens.length, "index out of bounds");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index) public override view returns (uint) {
        require(index < _balances[owner], "index out of bounds");
        return _ownedTokens[owner][index];
    }

    //====== Private or Internal Function ==============    
    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        address owner = ownerOf(tokenId);
        emit Approval(owner, to, tokenId);
    }    

    function _mint(address to, uint tokenId, string memory uri_) internal {
        require(to != address(0), "mint to zero address");        
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;        
        _tokenURIs[tokenId] = uri_;

        emit Transfer(address(0), to, tokenId);

        //IERC721Enumerable       
        _addTokenToAllEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }   

    function _safeMint(address to, uint tokenId, string memory uri_, bytes memory data) internal {        
        _mint(to, tokenId, uri_);

        require(_checkOnERC721Received(address(0), to, tokenId, data), "mint to non ERC721Receiver implementer");
    } 

    function _safeMint(address to, uint tokenId, string memory uri_) internal {
        _safeMint(to, tokenId, uri_, "");
    }

    function _burn(uint tokenId) internal {        
        address owner = ownerOf(tokenId);        
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approved");

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];

        emit Transfer(owner, address(0), tokenId);

        //IERC721Enumerable
        _removeTokenFromAllEnumeration(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);        
    }    

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool) {
        if (to.code.length <= 0) return true;

        IERC721TokenReceiver receiver = IERC721TokenReceiver(to);        
        try receiver.onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 interfaceId) {
            return interfaceId == type(IERC721TokenReceiver).interfaceId;
        } catch Error(string memory reason) {
            revert(reason);            
        } catch {
            revert("transfer to non ERC721Receiver implementer");
        }        
    }

    //IERC721Enumerable
    function _addTokenToAllEnumeration(uint tokenId) private {
        _allTokens.push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length - 1;
    }

    function _addTokenToOwnerEnumeration(address owner, uint tokenId) private {
        uint index = _balances[owner] - 1;
        _ownedTokens[owner][index] = tokenId;
        _ownedTokensIndex[tokenId] = index;
    }
    
    function _removeTokenFromAllEnumeration(uint tokenId) private {
        uint tokenIndex = _allTokensIndex[tokenId];
        uint tokenIndexLast = _allTokens.length - 1;
        uint tokenIdLast = _allTokens[tokenIndexLast];

        _allTokens[tokenIndex] = tokenIdLast;
        _allTokensIndex[tokenIdLast] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function _removeTokenFromOwnerEnumeration(address owner, uint tokenId) private {
        uint tokenIndex = _ownedTokensIndex[tokenId];
        uint tokenIndexLast = _balances[owner];

        if (tokenIndex < tokenIndexLast) {
            uint tokenIdLast = _ownedTokens[owner][tokenIndexLast];

            _ownedTokens[owner][tokenIndex] = tokenIdLast;
            _ownedTokensIndex[tokenIdLast] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[owner][tokenIndexLast];
    }
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

contract INFT is ERC721 {

    constructor() ERC721("INF Collectibles", "INFT") {
        
    }

    function create(string memory uri) public {
        uint tokenId = totalSupply();
        _safeMint(msg.sender, tokenId, uri);
    }

    function burn(uint tokenId) public {
        _burn(tokenId);
    }
}