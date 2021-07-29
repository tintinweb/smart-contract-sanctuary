/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

contract Metadata {
	string public name = "Yat NFT (preview)";
	string public symbol = "Yats";
	function contractURI() external pure returns (string memory) {
		return "";
	}
	function baseTokenURI() public pure returns (string memory) {
		return "https://a.yat.fyi/nft_transfers/metadata/";
	}
	function tokenURI(uint256 _tokenId) external pure returns (string memory) {
		bytes memory _base = bytes(baseTokenURI());
		uint256 _digits = 1;
		uint256 _n = _tokenId;
		while (_n > 9) {
			_n /= 10;
			_digits++;
		}
		bytes memory _uri = new bytes(_base.length + _digits);
		for (uint256 i = 0; i < _uri.length; i++) {
			if (i < _base.length) {
				_uri[i] = _base[i];
			} else {
				uint256 _dec = (_tokenId / (10**(_uri.length - i - 1))) % 10;
				_uri[i] = bytes1(uint8(_dec) + 48);
			}
		}
		return string(_uri);
	}
}

contract YAT {

	address constant private USE_GLOBAL_SIGNER = address(type(uint160).max);

	struct User {
		uint256 balance;
		mapping(uint256 => uint256) list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
	}

	struct Token {
		address owner;
		address cosigner;
		address approved;
		address pointsTo;
		address resolvesTo;
		string token;
		uint256 records;
		mapping(uint256 => bytes32) keys;
		mapping(bytes32 => string) values;
		mapping(bytes32 => uint256) indexOf;
		uint256 nonce;
	}

	struct Info {
		uint256 totalSupply;
		mapping(uint256 => Token) list;
		mapping(bytes32 => uint256) idOf;
		mapping(bytes32 => string) dictionary;
		mapping(address => string) resolve;
		mapping(address => User) users;
		Metadata metadata;
		address owner;
		address signer;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Transfer(address indexed from, address indexed to, bytes32 indexed tokenHash, string token);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Mint(bytes32 indexed tokenHash, uint256 indexed tokenId, address indexed account, string token);
	event Burn(bytes32 indexed tokenHash, uint256 indexed tokenId, address indexed account, string token);
	event RecordUpdated(bytes32 indexed tokenHash, address indexed manager, bytes32 indexed keyHash, string token, string key, string value);
	event RecordAdded(bytes32 indexed tokenHash, address indexed manager, bytes32 indexed keyHash, string token, string key);
	event RecordDeleted(bytes32 indexed tokenHash, address indexed manager, bytes32 indexed keyHash, string token, string key);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}

	modifier _onlyTokenOwner(uint256 _tokenId) {
		require(msg.sender == ownerOf(_tokenId));
		_;
	}

	modifier _onlyTokenOwnerOrCosigner(uint256 _tokenId) {
		require(msg.sender == ownerOf(_tokenId) || msg.sender == cosignerOf(_tokenId));
		_;
	}


	constructor(address _signer) {
		info.metadata = new Metadata();
		info.owner = msg.sender;
		info.signer = _signer;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setSigner(address _signer) external _onlyOwner {
		info.signer = _signer;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}


	function mint(string calldata _token, address _account, uint256 _expiry, bytes memory _signature) external {
		require(block.timestamp < _expiry);
		require(_verifyMint(_token, _account, _expiry, _signature));
		_mint(_token, _account);
	}

	/**
     *  "Soft-burns" the NFT by transferring the token to the contract address.
    **/
	function burn(uint256 _tokenId) external _onlyTokenOwner(_tokenId) {
		_transfer(msg.sender, address(this), _tokenId);
		emit Burn(hashOf(tokenOf(_tokenId)), _tokenId, msg.sender, tokenOf(_tokenId));
	}
	
	function setCosigner(address _cosigner, uint256 _tokenId) public _onlyTokenOwner(_tokenId) {
		info.list[_tokenId].cosigner = _cosigner;
	}

	function resetCosigner(uint256 _tokenId) external {
		setCosigner(USE_GLOBAL_SIGNER, _tokenId);
	}

	function revokeCosigner(uint256 _tokenId) external {
		setCosigner(address(0x0), _tokenId);
	}
	
	function setPointsTo(address _pointsTo, uint256 _tokenId) public _onlyTokenOwner(_tokenId) {
		info.list[_tokenId].pointsTo = _pointsTo;
	}
	
	function resolveTo(address _resolvesTo, uint256 _tokenId) public _onlyTokenOwner(_tokenId) {
		_updateResolvesTo(_resolvesTo, _tokenId);
	}

	function unresolve(uint256 _tokenId) external {
		resolveTo(address(0x0), _tokenId);
	}

	function updateRecord(uint256 _tokenId, string memory _key, string memory _value, bytes memory _signature) external {
		require(_verifyRecordUpdate(_tokenId, _key, _value, info.list[_tokenId].nonce++, _signature));
		_updateRecord(_tokenId, _key, _value);
	}

	function updateRecord(uint256 _tokenId, string memory _key, string memory _value) public _onlyTokenOwnerOrCosigner(_tokenId) {
		_updateRecord(_tokenId, _key, _value);
	}

	function deleteRecord(uint256 _tokenId, string memory _key) external {
		updateRecord(_tokenId, _key, "");
	}

	function deleteAllRecords(uint256 _tokenId) external _onlyTokenOwnerOrCosigner(_tokenId) {
		_deleteAllRecords(_tokenId);
	}
	
	function approve(address _approved, uint256 _tokenId) external _onlyTokenOwner(_tokenId) {
		info.list[_tokenId].approved = _approved;
		emit Approval(msg.sender, _approved, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		info.users[msg.sender].approved[_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) external {
		_transfer(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
		_transfer(_from, _to, _tokenId);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == 0x150b7a02);
		}
	}


	function name() external view returns (string memory) {
		return info.metadata.name();
	}

	function symbol() external view returns (string memory) {
		return info.metadata.symbol();
	}

	function contractURI() external view returns (string memory) {
		return info.metadata.contractURI();
	}

	function baseTokenURI() external view returns (string memory) {
		return info.metadata.baseTokenURI();
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function signer() public view returns (address) {
		return info.signer;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].balance;
	}

	function resolve(address _account) public view returns (string memory) {
		return info.resolve[_account];
	}

	function reverseResolve(string memory _token) public view returns (address) {
		return info.list[idOf(_token)].resolvesTo;
	}

	function hashOf(string memory _token) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_token));
	}

	function idOf(string memory _token) public view returns (uint256) {
		bytes32 _hash = hashOf(_token);
		require(info.idOf[_hash] != 0);
		return info.idOf[_hash] - 1;
	}

	function tokenOf(uint256 _tokenId) public view returns (string memory) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].token;
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].owner;
	}

	function cosignerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		address _cosigner = info.list[_tokenId].cosigner;
		if (_cosigner == USE_GLOBAL_SIGNER) {
			_cosigner = signer();
		}
		return _cosigner;
	}

	function pointsTo(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].pointsTo;
	}

	function nonceOf(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].nonce;
	}

	function recordsOf(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].records;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].approved;
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function getKey(bytes32 _hash) public view returns (string memory) {
		return info.dictionary[_hash];
	}

	function getRecord(string memory _token, string memory _key) public view returns (string memory) {
		return getRecord(idOf(_token), _key);
	}

	function getRecord(uint256 _tokenId, string memory _key) public view returns (string memory) {
		bytes32 _hash = keccak256(abi.encodePacked(_key));
		return getRecord(_tokenId, _hash);
	}

	function getRecord(uint256 _tokenId, bytes32 _hash) public view returns (string memory) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].values[_hash];
	}

	function getFullRecord(uint256 _tokenId, bytes32 _hash) public view returns (string memory, string memory) {
		return (getKey(_hash), getRecord(_tokenId, _hash));
	}

	function getRecords(uint256 _tokenId, bytes32[] memory _hashes) public view returns (bytes32[] memory values, bool[] memory trimmed) {
		require(_tokenId < totalSupply());
		uint256 _length = _hashes.length;
		values = new bytes32[](_length);
		trimmed = new bool[](_length);
		for (uint256 i = 0; i < _length; i++) {
			string memory _value = info.list[_tokenId].values[_hashes[i]];
			values[i] = _stringToBytes32(_value);
			trimmed[i] = bytes(_value).length > 32;
		}
	}

	function getRecordsTable(uint256 _tokenId, uint256 _limit, uint256 _page, bool _isAsc) public view returns (bytes32[] memory hashes, bytes32[] memory keys, bool[] memory keysTrimmed, bytes32[] memory values, bool[] memory valuesTrimmed, uint256 totalRecords, uint256 totalPages) {
		require(_limit > 0);
		totalRecords = recordsOf(_tokenId);

		if (totalRecords > 0) {
			totalPages = (totalRecords / _limit) + (totalRecords % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalRecords % _limit != 0) {
				_limit = totalRecords % _limit;
			}

			hashes = new bytes32[](_limit);
			keys = new bytes32[](_limit);
			keysTrimmed = new bool[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				hashes[i] = info.list[_tokenId].keys[_isAsc ? _offset + i : totalRecords - _offset - i - 1];
				string memory _key = getKey(hashes[i]);
				keys[i] = _stringToBytes32(_key);
				keysTrimmed[i] = bytes(_key).length > 32;
			}
		} else {
			totalPages = 0;
			hashes = new bytes32[](0);
			keys = new bytes32[](0);
			keysTrimmed = new bool[](0);
		}
		(values, valuesTrimmed) = getRecords(_tokenId, hashes);
	}

	function getYAT(string memory _token) public view returns (uint256 tokenId, address tokenOwner, address tokenCosigner, address pointer, address approved, uint256 nonce, uint256 records) {
		tokenId = idOf(_token);
		( , tokenOwner, tokenCosigner, pointer, approved, nonce, records) = getYAT(tokenId);
	}

	function getYAT(uint256 _tokenId) public view returns (string memory token, address tokenOwner, address tokenCosigner, address pointer, address approved, uint256 nonce, uint256 records) {
		return (tokenOf(_tokenId), ownerOf(_tokenId), cosignerOf(_tokenId), pointsTo(_tokenId), getApproved(_tokenId), nonceOf(_tokenId), recordsOf(_tokenId));
	}

	function getYATs(uint256[] memory _tokenIds) public view returns (bytes32[] memory tokens, address[] memory owners, address[] memory cosigners, address[] memory pointers, address[] memory approveds) {
		uint256 _length = _tokenIds.length;
		tokens = new bytes32[](_length);
		owners = new address[](_length);
		cosigners = new address[](_length);
		pointers = new address[](_length);
		approveds = new address[](_length);
		for (uint256 i = 0; i < _length; i++) {
			string memory _token;
			(_token, owners[i], cosigners[i], pointers[i], approveds[i], , ) = getYAT(_tokenIds[i]);
			tokens[i] = _stringToBytes32(_token);
		}
	}

	function getYATsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, bytes32[] memory tokens, address[] memory owners, address[] memory cosigners, address[] memory pointers, address[] memory approveds, uint256 totalYATs, uint256 totalPages) {
		require(_limit > 0);
		totalYATs = totalSupply();

		if (totalYATs > 0) {
			totalPages = (totalYATs / _limit) + (totalYATs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalYATs % _limit != 0) {
				_limit = totalYATs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalYATs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(tokens, owners, cosigners, pointers, approveds) = getYATs(tokenIds);
	}

	function getOwnerYATsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, bytes32[] memory tokens, address[] memory cosigners, address[] memory pointers, address[] memory approveds, uint256 totalYATs, uint256 totalPages) {
		require(_limit > 0);
		totalYATs = balanceOf(_owner);

		if (totalYATs > 0) {
			totalPages = (totalYATs / _limit) + (totalYATs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalYATs % _limit != 0) {
				_limit = totalYATs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalYATs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(tokens, , cosigners, pointers, approveds) = getYATs(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _mint(string memory _token, address _account) internal {
		uint256 _tokenId;
		bytes32 _hash = hashOf(_token);
		if (info.idOf[_hash] == 0) {
			_tokenId = info.totalSupply++;
			info.idOf[_hash] = _tokenId + 1;
			Token storage _newToken = info.list[_tokenId];
			_newToken.owner = _account;
			_newToken.cosigner = USE_GLOBAL_SIGNER;
			_newToken.token = _token;
			uint256 _index = info.users[_account].balance++;
			info.users[_account].indexOf[_tokenId] = _index + 1;
			info.users[_account].list[_index] = _tokenId;
			emit Transfer(address(0x0), _account, _tokenId);
			emit Transfer(address(0x0), _account, _hash, _token);
		} else {
			_tokenId = idOf(_token);
			info.list[_tokenId].approved = msg.sender;
			_transfer(address(this), _account, _tokenId);
		}
		emit Mint(_hash, _tokenId, _account, _token);
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		address _owner = ownerOf(_tokenId);
		address _approved = getApproved(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		info.list[_tokenId].cosigner = USE_GLOBAL_SIGNER;
		info.list[_tokenId].pointsTo = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(_to, address(0x0), _tokenId);
		}
		_updateResolvesTo(address(0x0), _tokenId);
		_deleteAllRecords(_tokenId);

		uint256 _index = info.users[_from].indexOf[_tokenId] - 1;
		uint256 _moved = info.users[_from].list[info.users[_from].balance - 1];
		info.users[_from].list[_index] = _moved;
		info.users[_from].indexOf[_moved] = _index + 1;
		info.users[_from].balance--;
		delete info.users[_from].indexOf[_tokenId];
		uint256 _newIndex = info.users[_to].balance++;
		info.users[_to].indexOf[_tokenId] = _newIndex + 1;
		info.users[_to].list[_newIndex] = _tokenId;
		emit Transfer(_from, _to, _tokenId);
		emit Transfer(_from, _to, hashOf(tokenOf(_tokenId)), tokenOf(_tokenId));
	}

	function _updateResolvesTo(address _resolvesTo, uint256 _tokenId) internal {
		if (_resolvesTo == address(0x0)) {
			delete info.resolve[info.list[_tokenId].resolvesTo];
			info.list[_tokenId].resolvesTo = _resolvesTo;
		} else {
			require(bytes(resolve(_resolvesTo)).length == 0);
			require(info.list[_tokenId].resolvesTo == address(0x0));
			info.resolve[_resolvesTo] = tokenOf(_tokenId);
			info.list[_tokenId].resolvesTo = _resolvesTo;
		}
	}

	function _updateRecord(uint256 _tokenId, string memory _key, string memory _value) internal {
		require(bytes(_key).length > 0);
		bytes32 _hash = keccak256(abi.encodePacked(_key));
		if (bytes(getKey(_hash)).length == 0) {
			info.dictionary[_hash] = _key;
		}

		Token storage _token = info.list[_tokenId];
		if (bytes(_value).length == 0) {
			_deleteRecord(_tokenId, _key, _hash);
		} else {
			if (_token.indexOf[_hash] == 0) {
				uint256 _index = _token.records++;
				_token.indexOf[_hash] = _index + 1;
				_token.keys[_index] = _hash;
				emit RecordAdded(hashOf(tokenOf(_tokenId)), msg.sender, hashOf(_key), tokenOf(_tokenId), _key);
			}
			_token.values[_hash] = _value;
		}
		emit RecordUpdated(hashOf(tokenOf(_tokenId)), msg.sender, hashOf(_key), tokenOf(_tokenId), _key, _value);
	}

	function _deleteRecord(uint256 _tokenId, string memory _key, bytes32 _hash) internal {
		Token storage _token = info.list[_tokenId];
		require(_token.indexOf[_hash] != 0);
		uint256 _index = _token.indexOf[_hash] - 1;
		bytes32 _moved = _token.keys[_token.records - 1];
		_token.keys[_index] = _moved;
		_token.indexOf[_moved] = _index + 1;
		_token.records--;
		delete _token.indexOf[_hash];
		delete _token.values[_hash];
		emit RecordDeleted(hashOf(tokenOf(_tokenId)), msg.sender, hashOf(_key), tokenOf(_tokenId), _key);
	}

	function _deleteAllRecords(uint256 _tokenId) internal {
		Token storage _token = info.list[_tokenId];
		while (_token.records > 0) {
			bytes32 _hash = _token.keys[_token.records - 1];
			_deleteRecord(_tokenId, getKey(_hash), _hash);
		}
	}


	function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
	}

	function _splitSignature(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
		require(_signature.length == 65);
		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
	}

	function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
		(bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
		return ecrecover(_ethSignedMessageHash, v, r, s);
	}

	function _verifyMint(string calldata _token, address _account, uint256 _expiry, bytes memory _signature) internal view returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked("gogo", _token, _account, _expiry));
		return _recoverSigner(_getEthSignedMessageHash(_hash), _signature) == signer();
	}

	function _verifyRecordUpdate(uint256 _tokenId, string memory _key, string memory _value, uint256 _nonce, bytes memory _signature) internal view returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(_tokenId, _key, _value, _nonce));
		address _signer = _recoverSigner(_getEthSignedMessageHash(_hash), _signature);
		return _signer == ownerOf(_tokenId) || _signer == cosignerOf(_tokenId);
	}

	function _stringToBytes32(string memory _in) internal pure returns (bytes32 out) {
		if (bytes(_in).length == 0) {
			return 0x0;
		}
		assembly {
			out := mload(add(_in, 32))
		}
	}
}