/**
 *Submitted for verification at Etherscan.io on 2021-09-26
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

	string private _name = "Clockchains v0.1";
	string private _symbol = "CHCLOCKS";
	address[365] private _owners;
	bool private _postBigBang = false;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_) {}

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
		require(_postBigBang == true, "Attempted to peek before Big Bang.");
		address owner = _owners[tokenId];
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
		require(1 == 2, "Disabled function!");
	}

	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		require(1 == 2, "Disabled function!");
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(1 == 2, "Disabled function!");
	}

	function _bigbang() internal virtual {
		address[365] memory _tempMem;
		for(uint256 i = 0; i < 365; i++) {
			_tempMem[i] = 0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907;
		}
		_owners = _tempMem;
		_balances[_msgSender()] = 365;
	}

	function _burn(uint256 tokenId) internal virtual {
		// Instead of messing everything by removing the index, we just transfer the asset to the burn addy.
		address from = ERC721.ownerOf(tokenId);
		address to = address(0);

		require(ERC721.ownerOf(tokenId) == from, "Not authorized!"); // Only the owner can burn its own token.

		_beforeTokenTransfer(from, to, tokenId);
		_approve(address(0), tokenId);
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(from, to, tokenId);
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


	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		require(index < ERC721.balanceOf(owner), "Owner index out of bounds");
		return _ownedTokens[owner][index];
	}

	function totalSupply() public view virtual override returns (uint256) {
		return 365;
	}

	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		require(index < ERC721Enumerable.totalSupply(), "Global index out of bounds!");
		return index;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		uint256 length = ERC721.balanceOf(to);
		_ownedTokens[to][length] = tokenId;
		_ownedTokensIndex[tokenId] = length;
	}

	function _addTokenToAllTokensEnumeration(uint256 tokenId) public {}

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

	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {}
}

pragma solidity ^0.8.0;
abstract contract ERC721Burnable is Context, ERC721 {
	function burn(uint256 tokenId) public virtual {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized!");
		_burn(tokenId);
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


pragma solidity ^0.8.0;

contract IERC2309  {
	event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

pragma solidity ^0.8.0;
contract Clockchains is Context, ERC721Enumerable, ERC721Burnable, IERC2309 {

	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);

	// Clockchainz should include the following properties:
	// ----------------------------------------------------

	// There are 365 clockchainz in total.
	// Rarity: is given by an index ranging from 1 to 6:
	// 1 is unique
	// 2 is ultrarare (5 of them)
	// 3 is Kello (25 of them)
	// 4 is rad (60 of them)
	// 5 is cool (120 of them)
	// 6 is common (154).

	// Unique clock show a lunar calendar, date, time, and has a unique shade of gold for background and a reddish/orange glowing hue for the lamps.
	// Ultrarare clocks show a lunar calendar among the time and date, with a silver background and a “Star Wars” red hue for the lamps.
	// Kello clocks will show date and time with a black background and a golden hue for the lamps.
	// Rad clocks will show date and time with a black background and a Star Wars red hue for the lamps, divided in 5 different red hues (so 5 different hues, 12 each hue = 60)
	// Cool clocks will show only the date, with a white background and phosphor green hues for lamps (10 different hues, 12 per hue = 120).
	// Common clocks will show only the date, with 11 possible colors for bg, and 11 possible colors for lamps. (14 * 11 = 154).

	// Each clock will show a serial number. The order will be, for token index:
	// 0: Unique.
	// 1 to 5: Ultrarare.
	// 6 to 30: Kello
	// 31 to 90: Rad.
	// 91 to 210: Cool.
	// 211 to 365: Common.

	// Also, we will introduce a kind of macro for the minting. It will be harrowing
	// to have to mint 365 tokens manually, so we can use a function that will do it
	// for us: function BigBang.

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	// Default URIs
	string private _baseTokenURI = "https://arielbecker.com/Clockchains/token.php";
	string private _contractURI = "https://arielbecker.com/Clockchains/contract.php";
	string private _contractJSON = '{"name": "Clockchains","description": "365 onchain-stored clocks!","image": "https://arielbecker.com/Clockchains/cc.png","external_link": "https://arielbecker.com/Clockchains","seller_fee_basis_points": 1000,"fee_recipient": "0xC12Df5F402A8B8BEaea49ed9baD9c95fCcbfE907"}';

	string private _htmlTemplate = '';

	// Royalties
	uint256 private royalties_percentage = 12;

	// Other internal values
	address private smart_contract_owner;
	Counters.Counter private _tokenIdTracker;
	bool private _preBigBang = true;

	constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
		name = "Clockchains v0.1";
		symbol = "CHCLOCKS";
		baseTokenURI = _baseTokenURI;
		smart_contract_owner = _msgSender();
	}

	function ownerOf(uint256 tokenId) public view virtual override returns (address) {
		address temp = super.ownerOf(tokenId);
		if(temp == address(0)) {
			return smart_contract_owner;
		}
		else {
			return temp;
		}
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_tokenId >= 0, "Token ID cannot be less than zero!");
		require(_tokenId < totalSupply(), "Token ID out of bounds!");
		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "?id=", Strings.toString(_tokenId))) : "";
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function setContractURI(string memory _uri) public {
		require(_msgSender() == smart_contract_owner, "Not authorized!");
		_contractURI = _uri;
	}

	function setContractJSON(string memory _json) public {
		require(_msgSender() == smart_contract_owner, "Not authorized!");
		_contractJSON = _json;
	}

	function setBaseTokenURI(string memory _uri) public {
		require(_msgSender() == smart_contract_owner, "Not authorized!");
		_baseTokenURI = _uri;
	}

	function setHTMLTemplate(string memory _html) public {
		require(_msgSender() == smart_contract_owner, "Not authorized!");
		_htmlTemplate = _html;
	}

	function MassMint() public virtual {
		require(_msgSender() == smart_contract_owner, "Not authorized!");
		require(_preBigBang == true, "Big Bang already happened!");

		_bigbang();
		_preBigBang = false;

		emit ConsecutiveTransfer(0, 364, address(0), smart_contract_owner);
	}

	// This function returns only the metadata content OF THE CONTRACT
	// Please refer to https://docs.opensea.io/docs/contract-level-metadata as an example on the JSON format and content.
	function retrieveContractMetadata() public view returns (string memory) {
		return _contractJSON;
	}

	// This function returns data and metadata of a given token.
	function retrieveData(uint256 _tokenId) public view returns (string memory, string memory) {
		require(_tokenId >= 0, "Token ID cannot be less than zero!");
		require(_tokenId < totalSupply(), "Token ID out of bounds!");

		string memory data = _htmlTemplate;
		string memory metadata = '';

		if(_tokenId == 0) { //unique
			metadata = '{"attributes":[{"trait_type":"Rarity","value":"Unique"},{"trait_type":"Foreground","value":"#D9391E"},{"trait_type":"Background","value":"#A58B38"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"Yes"},{"trait_type":"Lunar phase","value": "Yes"}]}';
		}
		else if(_tokenId > 0 && _tokenId < 6) { //ultrarare
			metadata = '{"attributes":[{"trait_type":"Rarity","value":"Ultrarare"},{"trait_type":"Foreground","value":"#9C0C18"},{"trait_type":"Background","value":"#B2B2B2"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"Yes"},{"trait_type":"Lunar phase","value": "Yes"}]}';
		}
		else if(_tokenId > 5 && _tokenId < 31) { //kello
			metadata = '{"attributes":[{"trait_type":"Rarity","value":"Kello"},{"trait_type":"Foreground","value":"#A58B38"},{"trait_type":"Background","value":"#171717"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"Yes"},{"trait_type":"Lunar phase","value": "No"}]}';
		}
		else if(_tokenId > 30 && _tokenId < 91) { //Rad
			metadata = '{"attributes":[{"trait_type":"Rarity","value":"Rad"},{"trait_type":"Foreground","value":"#9C0C18"},{"trait_type":"Background","value":"#171717"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"Yes"},{"trait_type":"Lunar phase","value": "No"}]}';
		}
		else if(_tokenId > 90 && _tokenId < 211) { //Cool
			metadata = '{"attributes":[{"trait_type":"Rarity","value":"Rad"},{"trait_type":"Foreground","value":"#4EBF27"},{"trait_type":"Background","value":"#DEDEDE"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"No"},{"trait_type":"Lunar phase","value": "No"}]}';
		}
		else if(_tokenId > 210 && _tokenId < 366) { //Common
			// Common clocks will show only the date, with 11 possible colors for bg, and 11 possible colors for lamps. (14 * 11 = 154).

			uint div = (((_tokenId - 211) / 14) + 1); // number between 1 and 11.
			string memory fgc = '#E37700';
			string memory bgc = '#211094';
			if(div == 2) {
				fgc = '#E39500';
				bgc = '#4C1094';
			}
			else if(div == 3) {
				fgc = '#E3BD00';
				bgc = '#701094';
			}
			else if(div == 4) {
				fgc = '#97E300';
				bgc = '#941067';
			}
			else if(div == 5) {
				fgc = '#00E30A';
				bgc = '#94101B';
			}
			else if(div == 6) {
				fgc = '#00E339';
				bgc = '#943410';
			}
			else if(div == 7) {
				fgc = '#DA00E3';
				bgc = '#946A10';
			}
			else if(div == 8) {
				fgc = '#E30094';
				bgc = '#7E9410';
			}
			else if(div == 9) {
				fgc = '#E30057';
				bgc = '#589410';
			}
			else if(div == 10) {
				fgc = '#E33C00';
				bgc = '#109464';
			}
			else if(div == 11) {
				fgc = '#E35300';
				bgc = '#107094';
			}

			metadata = string(abi.encodePacked('{"attributes":[{"trait_type":"Rarity","value":"Common"},{"trait_type":"Foreground","value":"', fgc, '"},{"trait_type":"Background","value":"', bgc, '"},{"trait_type": "Date","value":"Yes"},{"trait_type":"Time","value":"No"},{"trait_type":"Lunar phase","value": "No"}]}'));
		}
		else {
			revert("Index out of bounds!");
		}

		return(data, metadata);
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
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

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
		return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
	}
}

/**
 *
 * Compile with 0.8.6+commit.11564f7e and optimization to 200. MIT License.

Constructor arguments, ABI-encoded:

0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

*/