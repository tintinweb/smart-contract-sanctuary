/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
// Created by petdomaa100

pragma solidity 0.8.10;


library Address {
	function isContract(address account) internal view returns(bool) {
		uint256 size;

		assembly {
			size := extcodesize(account)
		}

		return size > 0;
	}
}

library Strings {
	function toString(uint256 value) internal pure returns(string memory) {
		if (value == 0) return "0";

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


interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


	function balanceOf(address owner) external view returns(uint256 balance);

	function ownerOf(uint256 tokenId) external view returns(address owner);

	function safeTransferFrom(address from, address to, uint256 tokenId) external;

	function transferFrom(address from, address to, uint256 tokenId) external;

	function approve(address to, uint256 tokenId) external;

	function getApproved(uint256 tokenId) external view returns(address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns(bool);

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns(uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns(uint256);
}

abstract contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	constructor() {
		_owner = msg.sender;
	}

	function owner() public view virtual returns(address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == msg.sender, "Ownable: Caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: New owner is the zero address");

		address oldOwner = _owner;
		_owner = newOwner;

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

abstract contract ERC721 is ERC165, IERC721, IERC721Metadata {
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


	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");

		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];

		require(owner != address(0), "ERC721: owner query for nonexistent token");

		return owner;
	}

	function name() public view virtual override returns(string memory) {
		return _name;
	}

	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();

		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
	}

	function _baseURI() internal view virtual returns(string memory) {
		return "";
	}

	function approve(address to, uint256 tokenID) public virtual override {
		address tokenOwner = ERC721.ownerOf(tokenID);

		require(to != tokenOwner, "ERC721: approval to current owner");
		require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

		_approve(to, tokenID);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != msg.sender, "ERC721: approve to caller");

		_operatorApprovals[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenID);
	}

	function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_safeTransfer(from, to, tokenID, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
		_transfer(from, to, tokenID);

		require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _exists(uint256 tokenID) internal view virtual returns(bool) {
		return _owners[tokenID] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenID) internal view virtual returns(bool) {
		require(_exists(tokenID), "ERC721: operator query for nonexistent token");

		address owner = ERC721.ownerOf(tokenID);

		return (spender == owner || getApproved(tokenID) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenID) internal virtual {
		_safeMint(to, tokenID, "");
	}

	function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
		_mint(to, tokenID);

		require(
			_checkOnERC721Received(address(0), to, tokenID, _data),
			"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	function _mint(address to, uint256 tokenID) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenID), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenID);

		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(address(0), to, tokenID);
	}

	function _burn(uint256 tokenID) internal virtual {
		address owner = ERC721.ownerOf(tokenID);

		_beforeTokenTransfer(owner, address(0), tokenID);
		_approve(address(0), tokenID);

		_balances[owner] -= 1;
		delete _owners[tokenID];

		emit Transfer(owner, address(0), tokenID);
	}

	function _transfer(address from, address to, uint256 tokenID) internal virtual {
		require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer of token that is not own");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenID);
		_approve(address(0), tokenID);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(from, to, tokenID);
	}

	function _approve(address to, uint256 tokenID) internal virtual {
		_tokenApprovals[tokenID] = to;

		emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns(bool) {
		if ( to.isContract() ) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenID, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) revert("ERC721: transfer to non ERC721Receiver implementer");

				else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		
		else return true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
	mapping(uint256 => uint256) private _ownedTokensIndex;

	uint256[] private _allTokens;
	mapping(uint256 => uint256) private _allTokensIndex;


	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns(bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

		return _ownedTokens[owner][index];
	}

	function totalSupply() public view virtual override returns(uint256) {
		return _allTokens.length;
	}

	function tokenByIndex(uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");

		return _allTokens[index];
	}

	function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) _addTokenToAllTokensEnumeration(tokenId);

		else if (from != to) _removeTokenFromOwnerEnumeration(from, tokenId);

		if (to == address(0)) _removeTokenFromAllTokensEnumeration(tokenId);

		else if (to != from) _addTokenToOwnerEnumeration(to, tokenId);
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



contract ExampleNFTcontract is ERC721Enumerable, Ownable {
	bool public paused;


	constructor() ERC721("Example NFT Contract", "NFT") {
		paused = true;
	}


	function mint() public payable {
		uint256 supply = totalSupply();

		require(!paused, "Minting is currently disabled!");


		_safeMint(msg.sender, supply + 1);
	}

	function flipPausedState() public onlyOwner {
		paused = !paused;
	}
}