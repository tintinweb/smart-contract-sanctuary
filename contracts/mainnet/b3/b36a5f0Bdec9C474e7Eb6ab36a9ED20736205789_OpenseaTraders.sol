/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

/*

 ██████╗ ███████╗████████╗
██╔═══██╗██╔════╝╚══██╔══╝
██║   ██║███████╗   ██║   
██║   ██║╚════██║   ██║   
╚██████╔╝███████║   ██║   
 ╚═════╝ ╚══════╝   ╚═╝    

Opensea Traders
An ERC-20 and NFT airdrop for everyone that traded via Opensea in Q1 2021.

Website: https://openseatraders.io/
Created by sol_dev

*/
pragma solidity ^0.5.17;

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
}

interface Factory {
	function createPair(address, address) external returns (address);
}

interface Pair {
	function token0() external view returns (address);
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Metadata {
	string public name = "Opensea Traders NFT";
	string public symbol = "OSTNFT";
	function contractURI() external pure returns (string memory) {
		return "https://api.openseatraders.io/metadata";
	}
	function baseTokenURI() public pure returns (string memory) {
		return "https://api.openseatraders.io/token/";
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
				_uri[i] = byte(uint8(_dec) + 48);
			}
		}
		return string(_uri);
	}
}

contract OST {

	uint256 constant private UINT_MAX = uint256(-1);

	string constant public name = "Opensea Traders";
	string constant public symbol = "OST";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		Router router;
		Pair pair;
		address controller;
		bool weth0;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	constructor() public {
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.controller = msg.sender;
	}

	function mint(address _receiver, uint256 _amount) external {
		require(msg.sender == info.controller);
		info.totalSupply += _amount;
		info.users[_receiver].balance += _amount;
		emit Transfer(address(0x0), _receiver, _amount);
	}


	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		uint256 _allowance = allowance(_from, msg.sender);
		require(_allowance >= _tokens);
		if (_allowance != UINT_MAX) {
			info.users[_from].allowance[msg.sender] -= _tokens;
		}
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 ostReserve, uint256 userBalance, uint256 userLPBalance) {
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		ostReserve = info.weth0 ? _res1 : _res0;
		userBalance = balanceOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_to].balance += _tokens;
		emit Transfer(_from, _to, _tokens);
		return true;
	}
}

contract OpenseaTraders {

	struct User {
		uint256[] list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
	}

	struct Token {
		address owner;
		address approved;
	}

	struct Info {
		bytes32 merkleRoot;
		uint256 totalSupply;
		mapping(uint256 => uint256) claimedBitMap;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		OST ost;
		Metadata metadata;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Claimed(uint256 indexed index, address indexed account, uint256 indexed tokenId);


	constructor(bytes32 _merkleRoot) public {
		info.ost = new OST();
		info.metadata = new Metadata();
		info.owner = msg.sender;
		info.merkleRoot = _merkleRoot;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		// Developer Bonus
		info.ost.mint(msg.sender, 1e22); // 10,000 OST
		_mint(msg.sender);
	}

	function setOwner(address _owner) external {
		require(msg.sender == info.owner);
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external {
		require(msg.sender == info.owner);
		info.metadata = _metadata;
	}


	function claim(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof) external {
		require(!isClaimed(_index));
		bytes32 _node = keccak256(abi.encodePacked(_index, _account, _amount));
		require(_verify(_merkleProof, _node));
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		info.claimedBitMap[_claimedWordIndex] = info.claimedBitMap[_claimedWordIndex] | (1 << _claimedBitIndex);
		info.ost.mint(_account, _amount);
		uint256 _tokenId = _mint(_account);
		emit Claimed(_index, _account, _tokenId);
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

	function ostAddress() external view returns (address) {
		return address(info.ost);
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].list.length;
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId != 0 && _tokenId <= totalSupply());
		return info.list[_tokenId].owner;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId != 0 && _tokenId <= totalSupply());
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

	function isClaimed(uint256 _index) public view returns (bool) {
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		uint256 _claimedWord = info.claimedBitMap[_claimedWordIndex];
		uint256 _mask = (1 << _claimedBitIndex);
		return _claimedWord & _mask == _mask;
	}

	function getToken(uint256 _tokenId) public view returns (address tokenOwner, address approved) {
		return (ownerOf(_tokenId), getApproved(_tokenId));
	}

	function getTokens(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i]) = getToken(_tokenIds[i]);
		}
	}

	function getTokensTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, uint256 totalTokens, uint256 totalPages) {
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
		(owners, approveds) = getTokens(tokenIds);
	}

	function getOwnerTokensTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, uint256 totalTokens, uint256 totalPages) {
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
		( , approveds) = getTokens(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _mint(address _receiver) internal returns (uint256 tokenId) {
		tokenId = totalSupply();
		info.totalSupply++;
		info.list[tokenId].owner = _receiver;
		info.users[_receiver].indexOf[tokenId] = info.users[_receiver].list.push(tokenId);
		emit Transfer(address(0x0), _receiver, tokenId);
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		(address _owner, address _approved) = getToken(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(address(0x0), address(0x0), _tokenId);
		}

		uint256 _index = info.users[_from].indexOf[_tokenId] - 1;
		uint256 _moved = info.users[_from].list[info.users[_from].list.length - 1];
		info.users[_from].list[_index] = _moved;
		info.users[_from].indexOf[_moved] = _index + 1;
		info.users[_from].list.length--;
		delete info.users[_from].indexOf[_tokenId];
		info.users[_to].indexOf[_tokenId] = info.users[_to].list.push(_tokenId);
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
}