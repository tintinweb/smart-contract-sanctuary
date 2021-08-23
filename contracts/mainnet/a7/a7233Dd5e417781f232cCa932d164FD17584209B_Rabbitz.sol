/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

 ___      _    _    _ _      
| _ \__ _| |__| |__(_) |_ ___
|   / _` | '_ \ '_ \ |  _|_ /
|_|_\__,_|_.__/_.__/_|\__/__|
A unique set of 1,000 collectable and tradable rabbit themed NFTs.

Website: https://rabbitz.xyz/
Created by sol_dev

*/

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

contract Metadata {
	string public name = "Rabbitz";
	string public symbol = "RBZ";
	function contractURI() external pure returns (string memory) {
		return "https://api.rabbitz.xyz/metadata";
	}
	function baseTokenURI() public pure returns (string memory) {
		return "https://api.rabbitz.xyz/rabbit/metadata/";
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

contract Rabbitz {

	uint256 constant public MAX_NAME_LENGTH = 32;
	uint256 constant public MAX_SUPPLY = 1000;
	uint256 constant public MINTABLE_SUPPLY = 473;
	uint256 constant public MINT_COST = 0.15 ether;

	struct User {
		uint256 balance;
		mapping(uint256 => uint256) list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
	}

	struct Token {
		address owner;
		address approved;
		bytes32 seed;
		string name;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalMinted;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		mapping(uint256 => uint256) claimedBitMap;
		bytes32 merkleRoot;
		Metadata metadata;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Claimed(uint256 indexed index, address indexed account, uint256 amount);
	event Mint(address indexed owner, uint256 indexed tokenId, bytes32 seed);
	event Rename(address indexed owner, uint256 indexed tokenId, string name);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(bytes32 _merkleRoot) {
		info.metadata = new Metadata();
		info.merkleRoot = _merkleRoot;
		info.owner = msg.sender;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		for (uint256 i = 0; i < 10; i++) {
			_mint(msg.sender);
		}
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}

	function ownerWithdraw() external _onlyOwner {
		uint256 _balance = address(this).balance;
		require(_balance > 0);
		payable(msg.sender).transfer(_balance);
	}

	
	receive() external payable {
		mintMany(msg.value / MINT_COST);
	}
	
	function mint() external payable {
		mintMany(1);
	}

	function mintMany(uint256 _tokens) public payable {
		require(_tokens > 0);
		uint256 _cost = _tokens * MINT_COST;
		require(msg.value >= _cost);
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(msg.sender);
		}
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}

	function claim(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof) external {
		require(!isClaimed(_index));
		bytes32 _node = keccak256(abi.encodePacked(_index, _account, _amount));
		require(_verify(_merkleProof, _node));
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		info.claimedBitMap[_claimedWordIndex] = info.claimedBitMap[_claimedWordIndex] | (1 << _claimedBitIndex);
		for (uint256 i = 0; i < _amount; i++) {
			_create(_account);
		}
		emit Claimed(_index, _account, _amount);
	}
	
	function rename(uint256 _tokenId, string calldata _newName) external {
		require(bytes(_newName).length <= MAX_NAME_LENGTH);
		require(msg.sender == ownerOf(_tokenId));
		info.list[_tokenId].name = _newName;
		emit Rename(msg.sender, _tokenId, _newName);
	}
	
	function approve(address _approved, uint256 _tokenId) external {
		require(msg.sender == ownerOf(_tokenId));
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

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalMinted() public view returns (uint256) {
		return info.totalMinted;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].balance;
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].owner;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].approved;
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function getSeed(uint256 _tokenId) public view returns (bytes32) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].seed;
	}

	function getName(uint256 _tokenId) public view returns (string memory) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].name;
	}

	function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function isClaimed(uint256 _index) public view returns (bool) {
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		uint256 _claimedWord = info.claimedBitMap[_claimedWordIndex];
		uint256 _mask = (1 << _claimedBitIndex);
		return _claimedWord & _mask == _mask;
	}

	function getRabbit(uint256 _tokenId) public view returns (address tokenOwner, address approved, bytes32 seed, string memory tokenName) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getSeed(_tokenId), getName(_tokenId));
	}

	function getRabbits(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		seeds = new bytes32[](_length);
		names = new bytes32[](_length);
		for (uint256 i = 0; i < _length; i++) {
			string memory _name;
			(owners[i], approveds[i], seeds[i], _name) = getRabbit(_tokenIds[i]);
			names[i] = _stringToBytes32(_name);
		}
	}

	function getRabbitsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names, uint256 totalRabbits, uint256 totalPages) {
		require(_limit > 0);
		totalRabbits = totalSupply();

		if (totalRabbits > 0) {
			totalPages = (totalRabbits / _limit) + (totalRabbits % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalRabbits % _limit != 0) {
				_limit = totalRabbits % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalRabbits - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, seeds, names) = getRabbits(tokenIds);
	}

	function getOwnerRabbitsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names, uint256 totalRabbits, uint256 totalPages) {
		require(_limit > 0);
		totalRabbits = balanceOf(_owner);

		if (totalRabbits > 0) {
			totalPages = (totalRabbits / _limit) + (totalRabbits % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalRabbits % _limit != 0) {
				_limit = totalRabbits % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalRabbits - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, seeds, names) = getRabbits(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 minted, uint256 ownerBalance) {
		return (totalSupply(), totalMinted(), balanceOf(_owner));
	}


	function _mint(address _user) internal {
		require(totalMinted() < MINTABLE_SUPPLY);
		info.totalMinted++;
		_create(_user);
	}
	
	function _create(address _user) internal {
		require(totalSupply() < MAX_SUPPLY);
		uint256 _tokenId = info.totalSupply++;
		Token storage _newToken = info.list[_tokenId];
		_newToken.owner = _user;
		bytes32 _seed = keccak256(abi.encodePacked(_tokenId, _user, blockhash(block.number - 1), gasleft()));
		_newToken.seed = _seed;
		uint256 _index = info.users[_user].balance++;
		info.users[_user].indexOf[_tokenId] = _index + 1;
		info.users[_user].list[_index] = _tokenId;
		emit Transfer(address(0x0), _user, _tokenId);
		emit Mint(_user, _tokenId, _seed);
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		address _owner = ownerOf(_tokenId);
		address _approved = getApproved(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(address(0x0), address(0x0), _tokenId);
		}

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
	}


	function _verify(bytes32[] memory _proof, bytes32 _leaf) internal view returns (bool) {
		bytes32 _computedHash = _leaf;
		for (uint256 i = 0; i < _proof.length; i++) {
			bytes32 _proofElement = _proof[i];
			if (_computedHash <= _proofElement) {
				_computedHash = keccak256(abi.encodePacked(_computedHash, _proofElement));
			} else {
				_computedHash = keccak256(abi.encodePacked(_proofElement, _computedHash));
			}
		}
		return _computedHash == info.merkleRoot;
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