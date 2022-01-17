/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

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

abstract contract ReentrancyGuard {

	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;
	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {

		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		_status = _ENTERED; _; _status = _NOT_ENTERED;

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
		//solhint-disable-next-line max-line-length
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
		require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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


//██///////█████//██████//██////██//█████//////██///////█████//██████//███████//
//██//////██///██/██///██/██////██/██///██/////██//////██///██/██///██/██///////
//██//////███████/██████//██////██/███████/////██//////███████/██///██/███████//
//██//////██///██/██///██//██//██//██///██/////██//////██///██/██///██//////██//
//███████/██///██/██///██///████///██///██/////███████/██///██/██████//███████//


contract FlashPokers is ERC721Enumerable, ReentrancyGuard, Ownable {

	uint256 public maxSupply = 5000;
	uint256 public price = 0.05 ether;
	uint256 public maxMint = 10;
	uint256 public numTokensMinted;

	string[8] private baseColors = ['#AE8B61','#DBB181','#E8AA96','#FFC2C2','#EECFA0','#C9CDAF','#D5C6E1','#EAD9D9'];
	string[53] private thirdNames = ['Ace Spade', 'Ace Club', 'Ace Heart', 'Ace Diamond', 'Two Spade', 'Two Club', 'Two Heart', 'Two Diamond', 'Three Spade', 'Three Club', 'Three Heart', 'Three Diamond', 'Four Spade', 'Four Club', 'Four Heart', 'Four Diamond', 'Five Spade', 'Five Club', 'Five Heart', 'Five Diamond', 'Six Spade', 'Six Club', 'Six Heart', 'Six Diamond', 'Seven Spade', 'Seven Club', 'Seven Heart', 'Seven Diamond'];
	string[53] private thirdLayers = [
		'<path fill="#000" d="m29 41h7v2h-7v-2zm2-4h3v4h-3v-4zm-4 6h11v2h-11v-2zm-5-8h21v2h-21v-2zm15 2h5v1h-5v-1zm1 1h3v1h-3v-1zm-27-24h1v2h-1v-2zm1-1h3v2h-3v-2zm3 1h1v2h-1v-2zm-2-2h1v1h-1v-1zm0 3h1v2h-1v-2zm-1 2h3v1h-3v-1zm36 28h3v1h-3v-1zm-1 2h1v2h-1v-2zm4 0h1v2h-1v-2zm-2-1h1v2h-1v-2zm-1 2h3v2h-3v-2zm1 2h1v1h-1v-1zm-1 2h1v5h-1v-5zm2 0h1v5h-1v-5zm-1 4h1v1h-1v-1zm0-2h1v1h-1v-1zm-37-48h1v5h-1v-5zm1 0h2v1h-2v-1zm1 1h1v4h-1v-4zm-1 1h1v1h-1v-1zm9 18h21v2h-21v-2zm2-2h17v2h-17v-2zm2-2h13v2h-13v-2zm2-2h9v2h-9v-2zm2-2h5v2h-5v-2zm1-1h3v1h-3v-1zm1-1h1v1h-1v-1zm-9 21h5v1h-5v-1zm1 1h3v1h-3v-1zm-3-10h23v7h-23v-7z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-39-41h1v5h-1v-5zm1 0h2v1h-2v-1zm1 1h1v4h-1v-4zm-2 1h2v1h-2v-1zm39 49l-1 0l0-5l1 0l0 5zm-1 0l-2 0l0-1l2 0l0 1zm-1-1h-1v-4h1v4zm2-1l-2 0v-1l2 0v1zm-23-25h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1z" />',
		'<path fill="#FF0000" d="m12 6h1v5h-1v-5zm1 0h2v1h-2v-1zm1 1h1v4h-1v-4zm-2 1h2v1h-2v-1zm39 49l-1 0l0-5l1 0l0 5zm-1 0l-2 0l0-1l2 0l0 1zm-1-1h-1v-4h1v4zm2-1l-2 0v-1l2 0v1zm-39-43h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1zm-21-20h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1z" />',
		'<path class="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-18-22h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-19-28h1v5h-1v-5zm1 0h2v1h-2v-1zm1 1h1v4h-1v-4zm-2 1h2v1h-2v-1zm39 49l-1 0l0-5l1 0l0 5zm-1 0l-2 0l0-1l2 0l0 1zm-1-1h-1v-4h1v4zm2-1l-2 0v-1l2 0v1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-39-40h2v1h-2v-1zm2 1h1v1h-1v-1zm-1 1h1v1h-1v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm38 47h-2v-1h2v1zm-2-1h-1v-1h1v1zm1-1h-1v-1h1v1zm1-1h-1v-2h1v2zm-1-1h-2v-1h2v1zm-19-10h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-39-41h2v1h-2v-1zm2 1h1v1h-1v-1zm-1 1h1v1h-1v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm38 47h-2v-1h2v1zm-2-1h-1v-1h1v1zm1-1h-1v-1h1v1zm1-1h-1v-2h1v2zm-1-1h-2v-1h2v1zm-22-9h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-2-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1z" />',
		'<path fill="#FF0000" d="m29 41h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-34h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-19-13h2v1h-2v-1zm2 1h1v1h-1v-1zm-1 1h1v1h-1v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm38 47h-2v-1h2v1zm-2-1h-1v-1h1v1zm1-1h-1v-1h1v1zm1-1h-1v-2h1v2zm-1-1h-2v-1h2v1zm-38-41h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-18-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 22h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-19-42h2v1h-2v-1zm2 1h1v1h-1v-1zm-1 1h1v1h-1v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm38 47h-2v-1h2v1zm-2-1h-1v-1h1v1zm1-1h-1v-1h1v1zm1-1h-1v-2h1v2zm-1-1h-2v-1h2v1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-20-3h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1-21h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1-21h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm-18-13h3v1h-3v-1zm2 1h1v4h-1v-4zm-2 3h2v1h-2v-1zm1-2h1v1h-1v-1zm38 49h-3v-1h3v1zm-2-1h-1v-4h1v4zm2-3l-2 0v-1l2 0v1zm-1 2h-1v-1h1v1z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-23-17h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-2 10h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-2-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-14h3v1h-3v-1zm2 1h1v4h-1v-4zm-2 3h2v1h-2v-1zm1-2h1v1h-1v-1zm38 49h-3v-1h3v1zm-2-1h-1v-4h1v4zm2-3l-2 0v-1l2 0v1zm-1 2h-1v-1h1v1z" />',
		'<path fill="#FF0000" d="m29 41h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-20h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-20h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-19-7h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1zm-38-42h3v1h-3v-1zm2 1h1v4h-1v-4zm-2 3h2v1h-2v-1zm1-2h1v1h-1v-1zm38 49l-3 0l0-1l3 0l0 1zm-2-1h-1v-4h1v4zm2-3l-2 0l0-1l2 0l0 1zm-1 2l-1 0l0-1l1 0l0 1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-18-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-19-42h3v1h-3v-1zm2 1h1v4h-1v-4zm-2 3h2v1h-2v-1zm1-2h1v1h-1v-1zm38 49h-3v-1h3v1zm-2-1h-1v-4h1v4zm2-3l-2 0v-1l2 0v1zm-1 2h-1v-1h1v1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-40-40h1v4h-1v-4zm1 3h3v1h-3v-1zm1-1h1v1h-1v-1zm0 2h1v1h-1v-1zm39 47h-1l0-4h1l0 4zm-1-3h-3v-1h3v1zm-1 1l-1 0l0-1l1 0l0 1zm0-2h-1l0-1h1l0 1zm-28-40h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 24h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm18-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 24h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-15-3h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-11-14h1v4h-1v-4zm1 3h3v1h-3v-1zm1-1h1v1h-1v-1zm0 2h1v1h-1v-1zm39 47h-1l0-4h1l0 4zm-1-3h-3v-1h3v1zm-1 1l-1 0l0-1l1 0l0 1zm0-2h-1l0-1h1l0 1z" />',
		'<path fill="#FF0000" d="m12 12h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1zm-39-42h1v4h-1v-4zm1 3h3v1h-3v-1zm1-1h1v1h-1v-1zm0 2h1v1h-1v-1zm39 47h-1v-4h1v4zm-1-3h-3v-1h3v1zm-1 1h-1v-1h1v1zm0-2h-1v-1l1 0v1zm-30-40h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 22h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm16-6h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-34h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-27-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 22h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm18-34h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 22h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-29-42h1v4h-1v-4zm1 3h3v1h-3v-1zm1-1h1v1h-1v-1zm0 2h1v1h-1v-1zm39 47h-1l0-4h1l0 4zm-1-3h-3v-1h3v1zm-1 1l-1 0l0-1l1 0l0 1zm0-2h-1l0-1h1l0 1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-29-33h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 24h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm10-21h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm9-21h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 24h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm-26-43h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1zm36 42h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-23-17h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm6 10h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-10-14h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1zm36 42h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1z" />',
		'<path fill="#FF0000" d="m12 12h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1zm-30-35h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 22h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm16-6h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-34h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-11 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-18-27h2v1h-2v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1zm0-4h1v1h-1v-1zm37 46h2v1h-2v-1zm-1 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1zm0-4h1v1h-1v-1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-27-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 22h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm18-34h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-9 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm9 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-28-42h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1zm36 42h3v1h-3v-1zm0 1h1v2h-1v-2zm1 1h2v1h-2v-1zm1 1h1v2h-1v-2zm-2 1h2v1h-2v-1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-29-33h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm18-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm-26-43h3v1h-3v-1zm0 1h1v4h-1v-4zm1 3h2v1h-2v-1zm1-2h1v2h-1v-2zm-1 0h1v1h-1v-1zm38 49h-3v-1h3v1zm0-1h-1v-4h1v4zm-1-3h-2v-1h2v1zm-1 2h-1v-2h1v2zm1 0h-1v-1h1v1z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-31-17h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-2 10h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-10-14h3v1h-3v-1zm0 1h1v4h-1v-4zm1 3h2v1h-2v-1zm1-2h1v2h-1v-2zm-1 0h1v1h-1v-1zm38 49h-3v-1h3v1zm0-1h-1v-4h1v4zm-1-3h-2v-1h2v1zm-1 2h-1v-2h1v2zm1 0h-1v-1h1v1z" />',
		'<path fill="#FF0000" d="m12 12h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm38 36h-1v-1h1v1zm-2 0h-1v-1h1v1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1v-1h1v1zm-30-35h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm16-34h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-28-41h3v1h-3v-1zm0 1h1v4h-1v-4zm1 3h2v1h-2v-1zm1-2h1v2h-1v-2zm-1 0h1v1h-1v-1zm38 49l-3 0l0-1l3 0l0 1zm0-1h-1v-4h1v4zm-1-3h-2v-1h2v1zm-1 2l-1 0l0-2l1 0l0 2zm1 0l-1 0l0-1l1 0l0 1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-27-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm18-34h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-28-42h3v1h-3v-1zm0 1h1v4h-1v-4zm1 3h2v1h-2v-1zm1-2h1v2h-1v-2zm-1 0h1v1h-1v-1zm38 49h-3v-1h3v1zm0-1h-1v-4h1v4zm-1-3h-2v-1h2v1zm-1 2h-1v-2h1v2zm1 0h-1v-1h1v1z" />',
		'<path fill="#000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm0 1h1v1h-1v-1zm2 0h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 1h1v1h-1v-1zm-1 1h3v1h-3v-1zm38 34h-1l0-1h1l0 1zm1-1h-3v-1h3v1zm1-1h-5v-1h5v1zm0-1h-1v-1h1v1zm-2 0h-1v-1h1v1zm-2 0h-1l0-1h1v1zm2-1h-1v-1h1v1zm1-1h-3v-1l3 0v1zm-29-33h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm10-28h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm9-14h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm1 9h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm0 1h2v1h-2v-1zm5 0h2v1h-2v-1zm-2 0h1v2h-1v-2zm-1 2h3v1h-3v-1zm-27-43h3v1h-3v-1zm2 1h1v4h-1v-4zm39 50h-3v-1h3v1zm-2-1h-1v-4h1v4z" />',
		'<path fill="#000" d="m12 12h3v1h-3v-1zm-1 1h1v2h-1v-2zm4 0h1v2h-1v-2zm-2 0h1v3h-1v-3zm-1 3h3v1h-3v-1zm39 35h-3v-1h3v1zm1-1h-1l0-2h1l0 2zm-4 0h-1v-2h1v2zm2 0h-1l0-3h1l0 3zm1-3l-3 0v-1l3 0v1zm-23-24h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-10 3h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-2 10h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm14-32h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-18-4h2v3h-2v-3zm2-2h3v2h-3v-2zm3 2h2v3h-2v-3zm-2 0h1v4h-1v-4zm-1 1h1v1h-1v-1zm2 0h1v1h-1v-1zm-2 3h3v1h-3v-1zm-11-14h3v1h-3v-1zm2 1h1v4h-1v-4zm39 50h-3v-1h3v1zm-2-1h-1v-4h1v4z" />',
		'<path fill="#FF0000" d="m12 12h1v1h-1v-1zm2 0h1v1h-1v-1zm-3 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2-9h3v1h-3v-1zm2 1h1v4h-1v-4zm38 44h-1v-1h1v1zm-2 0l-1 0v-1l1 0l0 1zm3-1h-5v-1h5v1zm-1-1h-3v-1h3v1zm-1-1h-1l0-1h1l0 1zm2 9h-3v-1h3v1zm-2-1h-1l0-4h1l0 4zm-30-43h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm7-27h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm7-13h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-2 8h1v1h-1v-1zm4 0h1v1h-1v-1zm-5 1h3v1h-3v-1zm4 0h3v1h-3v-1zm-4 1h7v2h-7v-2zm1 2h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1z" />',
		'<path fill="#FF0000" d="m13 12h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm36 30h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-27-36h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm9-26h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm9-14h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm0 8h1v1h-1v-1zm-1 1h3v1h-3v-1zm-1 1h5v1h-5v-1zm-1 1h7v1h-7v-1zm1 1h5v1h-5v-1zm1 1h3v1h-3v-1zm1 1h1v1h-1v-1zm-29-42h3v1h-3v-1zm2 1h1v4h-1v-4zm39 50h-3v-1h3v1zm-2-1h-1v-4h1v4z" />'];
    struct CardsObject {
		uint256 baseColor;
		uint256 layerThree;
	}

	function randomFlashPoker(uint256 tokenId) internal pure returns (CardsObject memory) {
		
		CardsObject memory FlashPoker;

		FlashPoker.baseColor = getBaseColor(tokenId);
		FlashPoker.layerThree = getLayerThree(tokenId);

		return FlashPoker;
	}
	
	function getTraits(CardsObject memory FlashPoker) internal pure returns (string memory) {
		
		string[6] memory parts;
		
		parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
		if (FlashPoker.layerThree < 12) {
			parts[1] = 'Figure"}, {"trait_type": "Type","value": "Figure"},'; 
		}
		if (FlashPoker.layerThree == 12) {
			parts[2] = 'Vitalik Joker"}, {"trait_type": "Type","value": "Vitalik Joker"},'; 
		}
		if (FlashPoker.layerThree > 13) {
			parts[3] = 'Numerals"}, {"trait_type": "Type","value": "Numerals"},'; 
		}
		parts[4] = ' {"trait_type": "Special","value": "';
		parts[5] = '"}], ';
		
		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
					  output = string(abi.encodePacked(output, parts[5]));
		return output;
	}

	function random(string memory input) internal pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(input)));
	}

	function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
		uint256 rand = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));

		uint256 rn1 = rand % 79;
		uint256 bc = 0;

		if (rn1 >= 10 && rn1 < 20) { bc = 1; }
		if (rn1 >= 20 && rn1 < 30) { bc = 2; }
		if (rn1 >= 30 && rn1 < 40) { bc = 3; }
		if (rn1 >= 40 && rn1 < 50) { bc = 4; }
		if (rn1 >= 50 && rn1 < 60) { bc = 5; }
		if (rn1 >= 60 && rn1 < 70) { bc = 6; }
		if (rn1 >= 70) { bc = 7; }

		return bc;
	}

	function getLayerThree(uint256 tokenId) internal pure returns (uint256) {
		uint256 rand = random(string(abi.encodePacked("LAYER THREE", toString(tokenId))));

		uint256 rn3 = rand % 33;
	uint256 l3 = 0;

	if (rn3 >= 8 && rn3 < 17) { l3 = 1; }
	if (rn3 >= 17 && rn3 < 25) { l3 = 2; }
	if (rn3 >= 25 && rn3 < 33) { l3 = 3; }
		
		return l3;
	}

	function getSVG(CardsObject memory FlashPoker) internal view returns (string memory) {
		string[6] memory parts;

		parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 64 64"><path fill="';
		parts[1] = baseColors[FlashPoker.baseColor];
		parts[2] = '"d="M0 0h64v64H0z"/>';
		parts[3] = '<path fill="black" d="m8 5h1v54h-1v-54zm46 0h1v54h-1v-54zm-45 53h45v1h-45v-1zm-1-54h47v1h-47v-1z" />';
		parts[4] = thirdLayers[FlashPoker.layerThree];
		parts[5] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));

		return output;
	}

	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		CardsObject memory FlashPoker = randomFlashPoker(tokenId);
		string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Larva Lad #', toString(tokenId), '", "description": "Larva Lads are a play on the CryptoPunks and their creators, Larva Labs. The artwork and metadata are fully on-chain and were randomly generated at mint."', getTraits(FlashPoker), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(FlashPoker))), '"}'))));
		json = string(abi.encodePacked('data:application/json;base64,', json));
		return json;
	}

	function mint(address destination, uint256 amountOfTokens) private {
		require(totalSupply() < maxSupply, "All tokens have been minted");
		require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
		require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
		require(amountOfTokens > 0, "Must mint at least one token");
		require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

		for (uint256 i = 0; i < amountOfTokens; i++) {
			uint256 tokenId = numTokensMinted + 1;
			_safeMint(destination, tokenId);
			numTokensMinted += 1;
		}
	}

	function mintForSelf(uint256 amountOfTokens) public payable virtual {
		mint(_msgSender(),amountOfTokens);
	}

	function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
		mint(walletAddress,amountOfTokens);
	}

	function setPrice(uint256 newPrice) public onlyOwner {
		price = newPrice;
	}

	function setMaxMint(uint256 newMaxMint) public onlyOwner {
		maxMint = newMaxMint;
	}

	function withdrawAll() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
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
	
	constructor() ERC721("Larva Lads", "LARVA") Ownable() {}
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