// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Metadata.sol";

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract WTFNFT {

	struct User {
		uint256 balance;
		mapping(uint256 => uint256) list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
		uint256 tokenIndex;
	}

	struct Token {
		address user;
		address owner;
		address approved;
		uint128 totalFees;
		uint128 failFees;
		uint128 totalGas;
		uint128 avgGwei;
		uint128 totalDonated;
		uint64 totalTxs;
		uint64 failTxs;
	}

	struct Info {
		uint256 totalSupply;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		Metadata metadata;
		address wtf;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	event Mint(address indexed owner, uint256 indexed tokenId, uint256 totalFees, uint256 failFees, uint256 totalGas, uint256 avgGwei, uint256 totalDonated, uint256 totalTxs, uint256 failTxs);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.metadata = new Metadata(this);
		info.wtf = msg.sender;
		info.owner = 0xdEE79eD62B42e30EA7EbB6f1b7A3f04143D18b7F;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}

	
	function mint(address _receiver, uint256 _totalFees, uint256 _failFees, uint256 _totalGas, uint256 _avgGwei, uint256 _totalDonated, uint256 _totalTxs, uint256 _failTxs) public {
		require(msg.sender == wtfAddress());
		uint256 _tokenId = info.totalSupply++;
		info.users[_receiver].tokenIndex = totalSupply();
		Token storage _newToken = info.list[_tokenId];
		_newToken.user = _receiver;
		_newToken.owner = _receiver;
		_newToken.totalFees = uint128(_totalFees);
		_newToken.failFees = uint128(_failFees);
		_newToken.totalGas = uint128(_totalGas);
		_newToken.avgGwei = uint128(_avgGwei);
		_newToken.totalDonated = uint128(_totalDonated);
		_newToken.totalTxs = uint64(_totalTxs);
		_newToken.failTxs = uint64(_failTxs);
		uint256 _index = info.users[_receiver].balance++;
		info.users[_receiver].indexOf[_tokenId] = _index + 1;
		info.users[_receiver].list[_index] = _tokenId;
		emit Transfer(address(0x0), _receiver, _tokenId);
		emit Mint(_receiver, _tokenId, _totalFees, _failFees, _totalGas, _avgGwei, _totalDonated, _totalTxs, _failTxs);
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

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function metadataAddress() public view returns (address) {
		return address(info.metadata);
	}

	function wtfAddress() public view returns (address) {
		return info.wtf;
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].balance;
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].owner;
	}

	function getUser(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].user;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].approved;
	}

	function getTotalFees(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].totalFees;
	}

	function getFailFees(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].failFees;
	}

	function getTotalGas(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].totalGas;
	}

	function getAvgGwei(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].avgGwei;
	}

	function getTotalDonated(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].totalDonated;
	}

	function getTotalTxs(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].totalTxs;
	}

	function getFailTxs(uint256 _tokenId) public view returns (uint256) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].failTxs;
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function tokenIdOf(address _user) public view returns (uint256) {
		uint256 _index = info.users[_user].tokenIndex;
		require(_index > 0);
		return _index - 1;
	}

	function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function getTokenCompressedInfo(uint256 _tokenId) public view returns (uint256[7] memory compressedInfo) {
		compressedInfo[0] = getTotalFees(_tokenId);
		compressedInfo[1] = getFailFees(_tokenId);
		compressedInfo[2] = getTotalGas(_tokenId);
		compressedInfo[3] = getAvgGwei(_tokenId);
		compressedInfo[4] = getTotalDonated(_tokenId);
		compressedInfo[5] = getTotalTxs(_tokenId);
		compressedInfo[6] = getFailTxs(_tokenId);
	}

	function getToken(uint256 _tokenId) public view returns (address tokenOwner, address approved, address user, uint256[7] memory compressedInfo) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getUser(_tokenId), getTokenCompressedInfo(_tokenId));
	}

	function getTokens(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, address[] memory users, uint256[7][] memory compressedInfos) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		users = new address[](_length);
		compressedInfos = new uint256[7][](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], users[i], compressedInfos[i]) = getToken(_tokenIds[i]);
		}
	}

	function getTokensTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, address[] memory users, uint256[7][] memory compressedInfos, uint256 totalTokens, uint256 totalPages) {
		require(_limit > 0);
		totalTokens = totalSupply();

		if (totalTokens > 0) {
			totalPages = (totalTokens / _limit) + (totalTokens % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalTokens % _limit != 0) {
				_limit = totalTokens % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalTokens - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, users, compressedInfos) = getTokens(tokenIds);
	}

	function getOwnerTokensTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, address[] memory users, uint256[7][] memory compressedInfos, uint256 totalTokens, uint256 totalPages) {
		require(_limit > 0);
		totalTokens = balanceOf(_owner);

		if (totalTokens > 0) {
			totalPages = (totalTokens / _limit) + (totalTokens % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalTokens % _limit != 0) {
				_limit = totalTokens % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalTokens - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, users, compressedInfos) = getTokens(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
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
}