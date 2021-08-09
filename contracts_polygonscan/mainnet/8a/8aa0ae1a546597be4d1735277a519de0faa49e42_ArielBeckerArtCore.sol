/**
 *Submitted for verification at polygonscan.com on 2021-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns (uint256 balance);
	function ownerOf(uint256 tokenId) external view returns (address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns (address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns (bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;
interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.8.0;
interface IERC721Metadata is IERC721 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;
library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Insufficient balance");
		(bool success, ) = recipient.call{value: amount}("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Insufficient balance!");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
		if(success) {
			return returndata;
		}
		else {
			if(returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			}
			else {
				revert(errorMessage);
			}
		}
	}
}

pragma solidity ^0.8.0;
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.0;
library Strings {
	bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

	function toString(uint256 value) internal pure returns (string memory) {
		if(value == 0) {
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
		if(value == 0) {
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

pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.0;
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	string private _name = "ArielBeckerArt";
	string private _symbol = "ABA";
	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_) {
		//_name = name_;
		//_symbol = symbol_;
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
		require(to != owner, "Not authorized!");
		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			"Not authorized!"
		);
		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId) public view virtual override returns (address) {
		require(_exists(tokenId), "Nonexistent token!");
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

	function transferFrom(address from, address to, uint256 tokenId) public virtual override {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_safeTransfer(from, to, tokenId, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "Attempted transfer to non ERC721Receiver implementer!");
	}

	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return _owners[tokenId] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
		require(_exists(tokenId), "Token does not exist!");
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, "");
	}

	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
			"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(to != address(0), "Zero address");
		require(!_exists(tokenId), "Already minted");
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

	function _transfer(address from, address to, uint256 tokenId) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, "Not authorized!");
		require(to != address(0), "Cannot transfer to zero addy!");
		require(to != address(0), "Cannot transfer to zero addy!");
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

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
		if(to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if(reason.length == 0) {
					revert("ERC721: transfer to non ERC721Receiver implementer");
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		else {
			return true;
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

pragma solidity ^0.8.0;
interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
	function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
	mapping(uint256 => uint256) private _ownedTokensIndex;
	uint256[] private _allTokens;
	mapping(uint256 => uint256) private _allTokensIndex;
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		require(index < ERC721.balanceOf(owner), "Owner index out of bounds");
		return _ownedTokens[owner][index];
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _allTokens.length;
	}

	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		require(index < ERC721Enumerable.totalSupply(), "Global index out of bounds!");
		return _allTokens[index];
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if(from == address(0)) {
			_addTokenToAllTokensEnumeration(tokenId);
		} else if(from != to) {
			_removeTokenFromOwnerEnumeration(from, tokenId);
		}
		if(to == address(0)) {
			_removeTokenFromAllTokensEnumeration(tokenId);
		} else if(to != from) {
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

		if(tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

			_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}

		delete _ownedTokensIndex[tokenId];
		delete _ownedTokens[from][lastTokenIndex];
	}

	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
		uint256 lastTokenIndex = _allTokens.length - 1;
		uint256 tokenIndex = _allTokensIndex[tokenId];
		uint256 lastTokenId = _allTokens[lastTokenIndex];
		_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
		_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		delete _allTokensIndex[tokenId];
		_allTokens.pop();
	}
}

pragma solidity ^0.8.0;
abstract contract Pausable is Context {
	event Paused(address account);
	event Unpaused(address account);
	bool private _paused;

	constructor() {
		_paused = false;
	}

	function paused() public view virtual returns (bool) {
		return _paused;
	}

	modifier whenNotPaused() {
		require(!paused(), "Paused.");
		_;
	}

	modifier whenPaused() {
		require(paused(), "Not paused.");
		_;
	}

	function _pause() internal virtual whenNotPaused {
		_paused = true;
		emit Paused(_msgSender());
	}

	function _unpause() internal virtual whenPaused {
		_paused = false;
		emit Unpaused(_msgSender());
	}
}


pragma solidity ^0.8.0;
abstract contract ERC721Burnable is Context, ERC721 {
	function burn(uint256 tokenId) public virtual {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		// Burn is disabled; send the token to the 0xdead addy instead.
		//_burn(tokenId);
	}
}

pragma solidity ^0.8.0;
abstract contract ERC721Pausable is ERC721, Pausable {
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);
		require(!paused(), "Cannot transfer: token is paused!");
	}
}

pragma solidity ^0.8.0;
interface IAccessControl {
	function hasRole(bytes32 role, address account) external view returns (bool);
	function getRoleAdmin(bytes32 role) external view returns (bytes32);
	function grantRole(bytes32 role, address account) external;
	function revokeRole(bytes32 role, address account) external;
	function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
	struct RoleData {
		mapping(address => bool) members;
		bytes32 adminRole;
	}

	mapping(bytes32 => RoleData) private _roles;

	bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
	event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

	modifier onlyRole(bytes32 role) {
		_checkRole(role, _msgSender());
		_;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
	}

	function hasRole(bytes32 role, address account) public view override returns (bool) {
		return _roles[role].members[account];
	}

	function _checkRole(bytes32 role, address account) internal view {
		if(!hasRole(role, account)) {
			revert(
				string(
					abi.encodePacked(
						"AccessControl: account ",
						Strings.toHexString(uint160(account), 20),
						" is missing role ",
						Strings.toHexString(uint256(role), 32)
					)
				)
			);
		}
	}

	function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
		return _roles[role].adminRole;
	}

	function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
		_grantRole(role, account);
	}

	function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
		_revokeRole(role, account);
	}

	function renounceRole(bytes32 role, address account) public virtual override {
		require(account == _msgSender(), "Can only renounce own roles.");
		_revokeRole(role, account);
	}

	function _setupRole(bytes32 role, address account) internal virtual {
		_grantRole(role, account);
	}

	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
		bytes32 previousAdminRole = getRoleAdmin(role);
		_roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	function _grantRole(bytes32 role, address account) private {
		if(!hasRole(role, account)) {
			_roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
		}
	}

	function _revokeRole(bytes32 role, address account) private {
		if(hasRole(role, account)) {
			_roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
		}
	}
}

pragma solidity ^0.8.0;
library EnumerableSet {
	struct Set {
		bytes32[] _values;
		mapping(bytes32 => uint256) _indexes;
	}

	function _add(Set storage set, bytes32 value) private returns (bool) {
		if(!_contains(set, value)) {
			set._values.push(value);
			set._indexes[value] = set._values.length;
			return true;
		}
		else {
			return false;
		}
	}

	function _remove(Set storage set, bytes32 value) private returns (bool) {
		uint256 valueIndex = set._indexes[value];

		if(valueIndex != 0) {
			uint256 toDeleteIndex = valueIndex - 1;
			uint256 lastIndex = set._values.length - 1;

			if(lastIndex != toDeleteIndex) {
				bytes32 lastvalue = set._values[lastIndex];
				set._values[toDeleteIndex] = lastvalue;
				set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
			}

			set._values.pop();
			delete set._indexes[value];

			return true;
		}
		else {
			return false;
		}
	}

	function _contains(Set storage set, bytes32 value) private view returns (bool) {
		return set._indexes[value] != 0;
	}

	function _length(Set storage set) private view returns (uint256) {
		return set._values.length;
	}

	function _at(Set storage set, uint256 index) private view returns (bytes32) {
		return set._values[index];
	}

	function _values(Set storage set) private view returns (bytes32[] memory) {
		return set._values;
	}

	struct Bytes32Set {
		Set _inner;
	}

	function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
		return _add(set._inner, value);
	}

	function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
		return _remove(set._inner, value);
	}

	function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
		return _contains(set._inner, value);
	}

	function length(Bytes32Set storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
		return _at(set._inner, index);
	}

	function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
		return _values(set._inner);
	}

	struct AddressSet {
		Set _inner;
	}

	function add(AddressSet storage set, address value) internal returns (bool) {
		return _add(set._inner, bytes32(uint256(uint160(value))));
	}

	function remove(AddressSet storage set, address value) internal returns (bool) {
		return _remove(set._inner, bytes32(uint256(uint160(value))));
	}

	function contains(AddressSet storage set, address value) internal view returns (bool) {
		return _contains(set._inner, bytes32(uint256(uint160(value))));
	}

	function length(AddressSet storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(AddressSet storage set, uint256 index) internal view returns (address) {
		return address(uint160(uint256(_at(set._inner, index))));
	}

	function values(AddressSet storage set) internal view returns (address[] memory) {
		bytes32[] memory store = _values(set._inner);
		address[] memory result;

		assembly {
			result := store
		}

		return result;
	}

	struct UintSet {
		Set _inner;
	}

	function add(UintSet storage set, uint256 value) internal returns (bool) {
		return _add(set._inner, bytes32(value));
	}

	function remove(UintSet storage set, uint256 value) internal returns (bool) {
		return _remove(set._inner, bytes32(value));
	}

	function contains(UintSet storage set, uint256 value) internal view returns (bool) {
		return _contains(set._inner, bytes32(value));
	}

	function length(UintSet storage set) internal view returns (uint256) {
		return _length(set._inner);
	}

	function at(UintSet storage set, uint256 index) internal view returns (uint256) {
		return uint256(_at(set._inner, index));
	}

	function values(UintSet storage set) internal view returns (uint256[] memory) {
		bytes32[] memory store = _values(set._inner);
		uint256[] memory result;
		assembly {
			result := store
		}
		return result;
	}
}

pragma solidity ^0.8.0;
interface IAccessControlEnumerable {
	function getRoleMember(bytes32 role, uint256 index) external view returns (address);
	function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
	using EnumerableSet for EnumerableSet.AddressSet;
	mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
		return _roleMembers[role].at(index);
	}

	function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
		return _roleMembers[role].length();
	}

	function grantRole(bytes32 role, address account) public virtual override {
		super.grantRole(role, account);
		_roleMembers[role].add(account);
	}

	function revokeRole(bytes32 role, address account) public virtual override {
		super.revokeRole(role, account);
		_roleMembers[role].remove(account);
	}

	function renounceRole(bytes32 role, address account) public virtual override {
		super.renounceRole(role, account);
		_roleMembers[role].remove(account);
	}

	function _setupRole(bytes32 role, address account) internal virtual override {
		super._setupRole(role, account);
		_roleMembers[role].add(account);
	}
}

pragma solidity ^0.8.0;
library Counters {
	struct Counter {
		uint256 _value;
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		unchecked {
			counter._value += 1;
		}
	}

	function decrement(Counter storage counter) internal {
		uint256 value = counter._value;
		require(value > 0, "Decrement overflow!");
		unchecked {
			counter._value = value - 1;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}

pragma solidity ^0.8.0;
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "Addition overflow!");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "Subtraction overflow!");
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if(a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "Multiplication overflow!");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, "Division by zero!");
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, "Modulo by zero!");
		return a % b;
	}
}

/**
pragma solidity ^0.8.0;
interface IERC2981 is IERC165 {
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
*/
pragma solidity ^0.8.0;
contract ArielBeckerArtCore is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {

	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);

	struct TokenStruc {
		bytes data; // Los datos van aquí.
		string metadata; // Y los metadatos, acá.
	}

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	string private _baseTokenURI = "https://arielbecker.com/arielbeckerart/matic/token.php";
	string private _contractURI = "https://arielbecker.com/arielbeckerart/matic/contract.php";
	string private _contractJSON = '{"name": "Ariel Becker Art","description": "Crazy elucubrations of an Argentinian lunatic.","image": "https://arielbecker.com/arielbeckerart/matic/aba.png","external_link": "https://arielbecker.com/arielbeckerart","seller_fee_basis_points": 1000,"fee_recipient": "0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907"}';
	uint256 private royalties_percentage = 10;
	address private smart_contract_owner;
	Counters.Counter private _tokenIdTracker;
	TokenStruc[] private beckers;

	constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
		name = "ArielBeckerArt";
		symbol = "ABA";
		baseTokenURI = _baseTokenURI;
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(MINTER_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, _msgSender());
		smart_contract_owner = _msgSender();
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		// La URL base debe tener ya la ruta para el token, por ejemplo "https://arielbecker.com/arielbeckerart/matic/token.php"
		require(_tokenId >= 0, "Token ID cannot be less than zero!");
		require(_tokenId < totalSupply(), "Token ID out of bounds!");
		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "?id=", Strings.toString(_tokenId))) : "";
		// Al llamar a este php, el mismo debería obtener los metadatos mediante la función retrieveMetadata
		// acá más abajo y mostrar ese JSON tal cual está guardado.
		// Ejemplo de JSON: https://opensea-creatures-api.herokuapp.com/api/creature/3
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function setcontractURI(string memory _uri) public {
		require(hasRole(MINTER_ROLE, _msgSender()), "Not authorized!");
		_contractURI = _uri;
	}

	function setcontractJSON(string memory _json) public {
		require(hasRole(MINTER_ROLE, _msgSender()), "Not authorized!");
		_contractJSON = _json;
	}

	function setbaseTokenURI(string memory _uri) public {
		require(hasRole(MINTER_ROLE, _msgSender()), "Not authorized!");
		_baseTokenURI = _uri;
	}

	function mint(bytes memory _data, string memory _metadata) public virtual {
		require(hasRole(MINTER_ROLE, _msgSender()), "Not authorized!");
		if(_data.length < 1) revert("We need some data, chump!");
		if(_data.length > 524288) revert("Too much data, chump!");
		beckers.push(TokenStruc(_data, _metadata));
		_mint(_msgSender(), _tokenIdTracker.current());
		_tokenIdTracker.increment();
	}

	// This function returns only the metadata content OF THE CONTRACT
	// Please refer to https://docs.opensea.io/docs/contract-level-metadata as an example on the JSON format and content.
	function retrieveContractMetadata() public view returns (string memory) {
		return _contractJSON;
	}

	// This function returns data and metadata of a given token.
	function retrieveData(uint256 _tokenId) public view returns (bytes memory, string memory) {
		require(_tokenId >= 0, "Token ID cannot be less than zero!");
		require(_tokenId < totalSupply(), "Token ID out of bounds!");
		return(beckers[_tokenId].data, beckers[_tokenId].metadata);
	}

	function pause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "Not authorized!");
		_pause();
	}

	function unpause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "Not authorized!");
		_unpause();
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function hasRoyalties() public pure returns (bool) {
		return true;
	}

	function royaltyAmount() public view returns (uint256) {
		return royalties_percentage;
	}

	function setroyaltyAmount(uint256 newpercentage) public {
		royalties_percentage = newpercentage;
	}

	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltiesAmount) {
		require(_tokenId >= 0, "Token ID cannot be less than zero!");
		require(_tokenId < totalSupply(), "Token ID out of bounds!");
		if(_salePrice > 99) { // Only makes sense to pay royalties if the sell value is more than 100 wei; otherwise, who cares?
			uint256 valorRoyalties = _salePrice.div(100).mul(royalties_percentage);
			return(smart_contract_owner, valorRoyalties);
		}
		else {
			return(smart_contract_owner, 0);
		}
	}

	function royaltiesReceived(address _creator, address _buyer, uint256 _amount) external {
		emit ReceivedRoyalties(_creator, _buyer, _amount);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
		return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
	}
}