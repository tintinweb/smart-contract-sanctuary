/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity ^0.5.0;

contract Ownable {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () internal {
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

library Roles {
	struct Role {
		mapping (address => bool) bearer;
	}

	function add(Role storage role, address account) internal {
		require(!has(role, account), "Roles: account already has role");
		role.bearer[account] = true;
	}

	function remove(Role storage role, address account) internal {
		require(has(role, account), "Roles: account does not have role");
		role.bearer[account] = false;
	}

	function has(Role storage role, address account) internal view returns (bool) {
		require(account != address(0), "Roles: account is the zero address");
		return role.bearer[account];
	}
}

contract SignerRole {
	using Roles for Roles.Role;

	event SignerAdded(address indexed account);
	event SignerRemoved(address indexed account);

	Roles.Role private _signers;

	constructor () internal {
		_addSigner(msg.sender);
	}

	modifier onlySigner() {
		require(isSigner(msg.sender), "SignerRole: caller does not have the Signer role");
		_;
	}

	function isSigner(address account) public view returns (bool) {
		return _signers.has(account);
	}

	function addSigner(address account) public onlySigner {
		_addSigner(account);
	}

	function renounceSigner() public {
		_removeSigner(msg.sender);
	}

	function _addSigner(address account) internal {
		_signers.add(account);
		emit SignerAdded(account);
	}

	function _removeSigner(address account) internal {
		_signers.remove(account);
		emit SignerRemoved(account);
	}
}

interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) public view returns (uint256 balance);
	function ownerOf(uint256 tokenId) public view returns (address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) public;
	function transferFrom(address from, address to, uint256 tokenId) public;
	function approve(address to, uint256 tokenId) public;
	function getApproved(uint256 tokenId) public view returns (address operator);
	function setApprovalForAll(address operator, bool _approved) public;
	function isApprovedForAll(address owner, address operator) public view returns (bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
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
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, "SafeMath: division by zero");
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, "SafeMath: modulo by zero");
		return a % b;
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}
}

library Counters {
	using SafeMath for uint256;

	struct Counter {
		uint256 _value;
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		counter._value += 1;
	}

	function decrement(Counter storage counter) internal {
		counter._value = counter._value.sub(1);
	}
}

contract ERC165 is IERC165 {
	bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
	mapping(bytes4 => bool) private _supportedInterfaces;

	constructor () internal {
		// Derived contracts need only register support for their own interfaces,
		// we register support for ERC165 itself here
		_registerInterface(_INTERFACE_ID_ERC165);
	}

	function supportsInterface(bytes4 interfaceId) external view returns (bool) {
		return _supportedInterfaces[interfaceId];
	}

	function _registerInterface(bytes4 interfaceId) internal {
		require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
		_supportedInterfaces[interfaceId] = true;
	}
}

contract ERC721 is ERC165, IERC721 {
	using SafeMath for uint256;
	using Address for address;
	using Counters for Counters.Counter;
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	mapping (uint256 => address) private _tokenOwner;
	mapping (uint256 => address) private _tokenApprovals;
	mapping (address => Counters.Counter) private _ownedTokensCount;
	mapping (address => mapping (address => bool)) private _operatorApprovals;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	constructor () public {
		_registerInterface(_INTERFACE_ID_ERC721);
	}

	function balanceOf(address owner) public view returns (uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return _ownedTokensCount[owner].current();
	}

	function ownerOf(uint256 tokenId) public view returns (address) {
		address owner = _tokenOwner[tokenId];
		require(owner != address(0), "ERC721: owner query for nonexistent token");
		return owner;
	}

	function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(to != owner, "ERC721: approval to current owner");
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
			"ERC721: approve caller is not owner nor approved for all"
		);
		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	function getApproved(uint256 tokenId) public view returns (address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");
		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address to, bool approved) public {
		require(to != msg.sender, "ERC721: approve to caller");
		_operatorApprovals[msg.sender][to] = approved;
		emit ApprovalForAll(msg.sender, to, approved);
	}

	function isApprovedForAll(address owner, address operator) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenId) public {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
		_transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
		transferFrom(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _exists(uint256 tokenId) internal view returns (bool) {
		address owner = _tokenOwner[tokenId];
		return owner != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
		require(_exists(tokenId), "ERC721: operator query for nonexistent token");
		address owner = ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function _mint(address to, uint256 tokenId) internal {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenId), "ERC721: token already minted");
		_tokenOwner[tokenId] = to;
		_ownedTokensCount[to].increment();
		emit Transfer(address(0), to, tokenId);
	}

	function _burn(address owner, uint256 tokenId) internal {
		require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");
		_clearApproval(tokenId);
		_ownedTokensCount[owner].decrement();
		_tokenOwner[tokenId] = address(0);
		emit Transfer(owner, address(0), tokenId);
	}

	function _burn(uint256 tokenId) internal {
		_burn(ownerOf(tokenId), tokenId);
	}

	function _transferFrom(address from, address to, uint256 tokenId) internal {
		require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
		require(to != address(0), "ERC721: transfer to the zero address");
		_clearApproval(tokenId);
		_ownedTokensCount[from].decrement();
		_ownedTokensCount[to].increment();
		_tokenOwner[tokenId] = to;
		emit Transfer(from, to, tokenId);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
		if(!to.isContract()) {
			return true;
		}
		bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
		return (retval == _ERC721_RECEIVED);
	}

	function _clearApproval(uint256 tokenId) private {
		if(_tokenApprovals[tokenId] != address(0)) {
			_tokenApprovals[tokenId] = address(0);
		}
	}
}

contract IERC721Metadata is IERC721 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Burnable is ERC721 {
	function burn(uint256 tokenId) public {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
		_burn(tokenId);
	}
}

contract IERC721Enumerable is IERC721 {
	function totalSupply() public view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
	function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
	mapping(address => uint256[]) private _ownedTokens;
	mapping(uint256 => uint256) private _ownedTokensIndex;
	uint256[] private _allTokens;
	mapping(uint256 => uint256) private _allTokensIndex;
	bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

	constructor () public {
		// register the supported interface to conform to ERC721Enumerable via ERC165
		_registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
		return _ownedTokens[owner][index];
	}

	function totalSupply() public view returns (uint256) {
		return _allTokens.length;
	}

	function tokenByIndex(uint256 index) public view returns (uint256) {
		require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
		return _allTokens[index];
	}

	function _transferFrom(address from, address to, uint256 tokenId) internal {
		super._transferFrom(from, to, tokenId);
		_removeTokenFromOwnerEnumeration(from, tokenId);
		_addTokenToOwnerEnumeration(to, tokenId);
	}

	function _mint(address to, uint256 tokenId) internal {
		super._mint(to, tokenId);
		_addTokenToOwnerEnumeration(to, tokenId);
		_addTokenToAllTokensEnumeration(tokenId);
	}

	function _burn(address owner, uint256 tokenId) internal {
		super._burn(owner, tokenId);
		_removeTokenFromOwnerEnumeration(owner, tokenId);
		_ownedTokensIndex[tokenId] = 0;
		_removeTokenFromAllTokensEnumeration(tokenId);
	}

	function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
		return _ownedTokens[owner];
	}

	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		_ownedTokensIndex[tokenId] = _ownedTokens[to].length;
		_ownedTokens[to].push(tokenId);
	}

	function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
		_allTokensIndex[tokenId] = _allTokens.length;
		_allTokens.push(tokenId);
	}

	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
		uint256 tokenIndex = _ownedTokensIndex[tokenId];

		if(tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
			_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}
		_ownedTokens[from].length--;
	}

	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
		uint256 lastTokenIndex = _allTokens.length.sub(1);
		uint256 tokenIndex = _allTokensIndex[tokenId];
		uint256 lastTokenId = _allTokens[lastTokenIndex];

		_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
		_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		_allTokens.length--;
		_allTokensIndex[tokenId] = 0;
	}
}

contract ERC721Base is ERC721, ERC721Enumerable {
	string public name;
	string public symbol;
	string public tokenURIPrefix;
	mapping(uint256 => string) private _tokenURIs;
	bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

	constructor (string memory _name, string memory _symbol, string memory _tokenURIPrefix) public {
		name = _name;
		symbol = _symbol;
		tokenURIPrefix = _tokenURIPrefix;
		_registerInterface(_INTERFACE_ID_ERC721_METADATA);
	}

	function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
		tokenURIPrefix = _tokenURIPrefix;
	}

	function tokenURI(uint256 tokenId) external view returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return strConcat(tokenURIPrefix, _tokenURIs[tokenId]);
	}

	function _setTokenURI(uint256 tokenId, string memory uri) internal {
		require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
		_tokenURIs[tokenId] = uri;
	}

	function _burn(address owner, uint256 tokenId) internal {
		super._burn(owner, tokenId);
		if(bytes(_tokenURIs[tokenId]).length != 0) {
			delete _tokenURIs[tokenId];
			// ToDo: añadir acá una funcionalidad que elimine los datos onchain en el indice dado.
		}
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory bab = new bytes(_ba.length + _bb.length);
		uint k = 0;
		for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
		for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
		return string(bab);
	}
}

pragma solidity ^0.5.7;

library Strings {
	function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		bytes memory _bd = bytes(_d);
		bytes memory _be = bytes(_e);
		string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
		bytes memory babcde = bytes(abcde);
		uint k = 0;
		for(uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for(uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		for(uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
		for(uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
		for(uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
		return string(babcde);
	}

	function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, _d, "");
	}

	function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, "", "");
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		return strConcat(_a, _b, "", "", "");
	}

	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if(_i == 0) {
				return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
				len++;
				j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (_i != 0) {
				bstr[k--] = byte(uint8(48 + _i % 10));
				_i /= 10;
		}
		return string(bstr);
	}

	function compareStrings(string memory a, string memory b) public view returns (bool) {
		return(keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	}
}

/**
-----------------------------[ ArielBeckerArt core ]----------------------------
**/
pragma solidity ^0.5.0;

contract BeckerCore is Ownable, ERC721, IERC721Metadata, ERC721Burnable, ERC721Base, SignerRole {
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	/**
	"documentType" stores an index of an enumeration of several document types:
	0: raw (pure binary).
	1: image (PNG, JPEG, GIF, etc).
	2: plain text.
	3. markdown text.
	4. LaTeX.
	*/

	string mybaseTokenURI = "https://arielbecker.com/foo";
	string licenseURI = "https://creativecommons.org/choose/zero/";
	string json_attributes = "{}";
	string public name = "ArielBeckerArt";
	string public symbol = "ABA";
	uint256 mintPrice = 0;
	uint256 documentType = 0;
	uint256 royalties_percentage = 10;
	address smart_contract_owner;

	struct ArielBeckerArt {
		string name;
		bytes data;
		address artist;
		uint256 date;
		uint256 documentType;
		string json_attributes;
	}

	ArielBeckerArt[] private beckers;

	event Create(address indexed creator, string name, string symbol);
	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);
	event MintedArielBeckerArt(uint256 indexed id, address indexed minter, string name, bytes data, uint256 document_type, string json_metadata);

	constructor() public ERC721Base(name, symbol, mybaseTokenURI) {
		smart_contract_owner = msg.sender;
		_registerInterface(_INTERFACE_ID_ERC2981);
		emit Create(smart_contract_owner, name, symbol);
		//_addSigner(smart_contract_owner);
	}

	function addSigner(address account) public onlyOwner {
		_addSigner(account);
	}

	function removeSigner(address account) public onlyOwner {
		_removeSigner(account);
	}

	function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
		_setTokenURIPrefix(tokenURIPrefix);
	}

	function mint(string memory _name, bytes memory _data, uint256 _documentType, string memory _json) public onlyOwner payable returns (uint) {
		require(msg.sender == msg.sender, "Only the owner can mint, chump!");
		if(_data.length < 1) revert("We need some data, chump!");
		if(_data.length > 524288) revert("Too much data, chump!");

		uint256 id_new_token = beckers.push(ArielBeckerArt(_name, _data, msg.sender, block.timestamp, _documentType, _json));

		_mint(msg.sender, id_new_token);
		_setTokenURI(id_new_token, baseTokenURI());
		emit MintedArielBeckerArt(id_new_token, msg.sender, _name, _data, _documentType, _json);

		return id_new_token;
	}

	function retrieve(uint256 _id) public view returns (string memory, bytes memory, address, uint256, uint256, string memory) {
		require(_id < 0, "Token ID cannot be less than zero!");
		return(beckers[_id - 1].name, beckers[_id - 1].data, beckers[_id - 1].artist, beckers[_id - 1].date, beckers[_id - 1].documentType, beckers[_id - 1].json_attributes);
	}

	function retrieveContent(uint256 _id) public view returns (bytes memory) {
		require(_id < 0, "Token ID cannot be less than zero!");
		return beckers[_id - 1].data;
	}

	function retrieveMetadata(uint256 _id) public view returns (string memory) {
		require(_id < 0, "Token ID cannot be less than zero!");
		return beckers[_id -1].json_attributes;
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return Strings.strConcat(
			baseTokenURI(),
			Strings.uint2str(_tokenId)
		);
	}

	function getlicenseURI() external view returns (string memory) {
		return licenseURI;
	}

	function setbaseTokenURI(string memory _uri) public onlyOwner {
		mybaseTokenURI = _uri;
	}

	function setLicenseURI(string memory _uri) public onlyOwner {
		licenseURI = _uri;
	}

	function withdraw() external onlyOwner {
		msg.sender.transfer(address(this).balance);
	}

	function setMintPrice(uint256 _price) external onlyOwner {
		mintPrice = _price;
	}

	function baseTokenURI() public view returns (string memory) {
		return mybaseTokenURI;
	}

	function hasRoyalties() public pure returns (bool) {
		return true;
	}

	function royaltyAmount() public view returns (uint256) {
		return royalties_percentage;
	}

	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltiesAmount) {
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

	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		if(interfaceID == _INTERFACE_ID_ERC2981) {
			return true;
		}
	}
}