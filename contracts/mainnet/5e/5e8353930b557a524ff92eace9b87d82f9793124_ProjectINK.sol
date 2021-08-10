/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*

 +++      .  .      +++ 
 [email protected]++++   .  .   [email protected]+ 
 [email protected]+.        [email protected]++++ 
   .+++   ++++   +++.   
          [email protected]@+          
. .   . [email protected]@+++ .   . .
.       [email protected][email protected]+       .
     ++++++  ++++++     
     [email protected]+        [email protected]+     
.    ++++      ++++    .
   .  [email protected]+      [email protected]+  .   
  .  .+++.    .+++.  .  
 . .   .        .   . . 
    .    .    .    .    
   .   ..      ..   .   
 .                    . 

Project INK
Collect generative inkblot art inspired by the Rorschach test.

Website: https://project.ink/
Created by sol_dev

*/

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

contract Metadata {
	string public name = "Project INK";
	string public symbol = "INK";
	function contractURI() external pure returns (string memory) {
		return "https://api.project.ink/metadata";
	}
	function baseTokenURI() public pure returns (string memory) {
		return "https://api.project.ink/token/metadata/";
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

contract ProjectINK {

	uint256 constant public MAX_NAME_LENGTH = 32;
	uint256 constant public MAX_SUPPLY = 1921;
	uint256 constant public MINT_COST = 0.05 ether;

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
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		Metadata metadata;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Mint(address indexed owner, uint256 indexed tokenId, bytes32 seed);
	event Rename(address indexed owner, uint256 indexed tokenId, string name);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.metadata = new Metadata();
		info.owner = msg.sender;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		for (uint256 i = 0; i < 10; i++) {
			_mint();
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
			_mint();
		}
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
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

	function getINK(uint256 _tokenId) public view returns (address tokenOwner, address approved, bytes32 seed, string memory tokenName) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getSeed(_tokenId), getName(_tokenId));
	}

	function getINKs(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		seeds = new bytes32[](_length);
		names = new bytes32[](_length);
		for (uint256 i = 0; i < _length; i++) {
			string memory _name;
			(owners[i], approveds[i], seeds[i], _name) = getINK(_tokenIds[i]);
			names[i] = _stringToBytes32(_name);
		}
	}

	function getINKsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names, uint256 totalINKs, uint256 totalPages) {
		require(_limit > 0);
		totalINKs = totalSupply();

		if (totalINKs > 0) {
			totalPages = (totalINKs / _limit) + (totalINKs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalINKs % _limit != 0) {
				_limit = totalINKs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalINKs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, seeds, names) = getINKs(tokenIds);
	}

	function getOwnerINKsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, bytes32[] memory seeds, bytes32[] memory names, uint256 totalINKs, uint256 totalPages) {
		require(_limit > 0);
		totalINKs = balanceOf(_owner);

		if (totalINKs > 0) {
			totalPages = (totalINKs / _limit) + (totalINKs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalINKs % _limit != 0) {
				_limit = totalINKs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalINKs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, seeds, names) = getINKs(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _mint() internal {
		require(totalSupply() < MAX_SUPPLY);
		uint256 _tokenId = info.totalSupply++;
		Token storage _newToken = info.list[_tokenId];
		_newToken.owner = msg.sender;
		bytes32 _seed = keccak256(abi.encodePacked(_tokenId, msg.sender, blockhash(block.number - 1), gasleft()));
		_newToken.seed = _seed;
		uint256 _index = info.users[msg.sender].balance++;
		info.users[msg.sender].indexOf[_tokenId] = _index + 1;
		info.users[msg.sender].list[_index] = _tokenId;
		emit Transfer(address(0x0), msg.sender, _tokenId);
		emit Mint(msg.sender, _tokenId, _seed);
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


	function _stringToBytes32(string memory _in) internal pure returns (bytes32 out) {
		if (bytes(_in).length == 0) {
			return 0x0;
		}
		assembly {
			out := mload(add(_in, 32))
		}
	}
}