/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721Metadata /* is ERC721 */ {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface ERC1155Metadata_URI {
    function uri(uint256 _id) external view returns (string memory);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

abstract contract ERC721 is IERC165, IERC721, ERC721Metadata, ERC1155Metadata_URI, ERC721Enumerable {

    mapping(address => uint) _balances; // owner => balance
    mapping(uint => address) _owners; // tokenId => owner
    mapping(address => mapping(address => bool)) _operatorApprovals; // owner => (operator => allow)
    mapping(uint => address) _tokenApprovals; // tokenId => operator

    string _name;
    string _symbol;
    mapping(uint => string) _tokenURIs; // token => uri

    uint[] _allTokens;
    mapping(uint => uint) _allTokensIndex; // tokenId => index all
    mapping(address => mapping(uint => uint)) _ownedTokens; // owner => (index => tokenId)
    mapping(uint => uint) _ownedTokensIndex; // tokenId => index own

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    function uri(uint256 _id) public override view returns (string memory) {
        return tokenURI(_id);
    }

    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId 
            || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(ERC721Metadata).interfaceId
            || interfaceId == type(ERC1155Metadata_URI).interfaceId
            || interfaceId == type(ERC721Enumerable).interfaceId;
    }

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

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require( to != owner, "approval status for self");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender) , "caller is not token owner or approval for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(ownerOf(tokenId) != address(0), "token is not exists");

        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer to zero address");
        
        address owner = ownerOf(tokenId);
        require(owner == from, "transfer from is not owner");
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approval");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumrarion(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        transferFrom(from, to, tokenId);

        require(_checkOnErc721Received(from, to, tokenId, data), "transfer to non ERC721Receiver");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // == Private or Internal ==
    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        address owner = ownerOf(tokenId);
        emit Approval(owner, to, tokenId);
    }

    function _checkOnErc721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool) {
        if (to.code.length <= 0) return true;

        IERC721TokenReceiver receiver = IERC721TokenReceiver(to);
        try receiver.onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 interfaceId) {
            return interfaceId == type(IERC721TokenReceiver).interfaceId;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC721Receiver implementor");
        }
    }

    function _mint(address to, uint tokenId, string memory uri_) internal {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token is already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri_;

        emit Transfer(address(0), to, tokenId);

        _addTokenToAllEnumeration(tokenId);
        _addTokenToOwnerEnumrarion(to, tokenId);
    }

    function _burn(uint tokenId) internal {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approved");

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _removeTokenFromAllEnumeration(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);
    }

    function totalSupply() public override view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < _allTokens.length, "index out of bounds");

        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < _balances[owner], "index out of bounds");

        return _ownedTokens[owner][index];
    }

    function _addTokenToAllEnumeration(uint tokenId) private {
        _allTokens.push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length - 1;
    }

    function _addTokenToOwnerEnumrarion(address owner, uint tokenId) private {
        uint index = _balances[owner] - 1;
        _ownedTokens[owner][index] = tokenId;
        _ownedTokensIndex[tokenId] = index;
    }

    function _removeTokenFromOwnerEnumeration(address owner, uint tokenId) private {
        uint tokenIndex = _ownedTokensIndex[tokenId];
        uint tokenIndexLast = _balances[owner];

        if (tokenIndex < tokenIndexLast) {
            uint tokenIdLast = _ownedTokens[owner][tokenIndexLast];

            _ownedTokens[owner][tokenIndex] = tokenIdLast;
            _ownedTokensIndex[tokenIdLast] = tokenIndex;
        }

        delete _ownedTokens[owner][tokenIndexLast];
        delete _ownedTokensIndex[tokenId];
    }

    function _removeTokenFromAllEnumeration(uint tokenId) private {
        uint tokenIndex = _allTokensIndex[tokenId];
        uint tokenIndexLast = _allTokens.length - 1;
        uint tokenIdLast = _allTokens[tokenIndexLast];

        _allTokens[tokenIndex] = tokenIdLast;
        _allTokensIndex[tokenIdLast] = tokenIndex;

        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }
}

contract INFT is ERC721 {
    constructor() ERC721("INF Collectible", "INFT") {

    }

    function create(uint tokenId, string memory uri) public {
        _mint(msg.sender, tokenId, uri);
    }

    function burn(uint tokenId) public {
        _burn(tokenId);
    }
}