/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

/*
 ___ _ _    _    _ _      
| _ (_) |__| |__(_) |_ ___
|   / | '_ \ '_ \ |  _(_-<
|_|_\_|_.__/_.__/_|\__/__/
A unique set of 1,000 collectable and tradable frog themed NFTs.

Website: https://ribbits.xyz/
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
	string public name = "Ribbits";
	string public symbol = "RBT";
	function contractURI() external pure returns (string memory) {
		return "https://api.ribbits.xyz/metadata";
	}
	function baseTokenURI() public pure returns (string memory) {
		return "https://api.ribbits.xyz/ribbit/metadata/";
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

contract WrappedRibbits {

	uint256 constant private UINT_MAX = uint256(-1);

	string constant public name = "Wrapped Ribbits";
	string constant public symbol = "wRBT";
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
		Ribbits ribbits;
		bool weth0;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	constructor(Ribbits _ribbits) public {
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.ribbits = _ribbits;
	}

	function wrap(uint256[] calldata _tokenIds) external {
		uint256 _count = _tokenIds.length;
		require(_count > 0);
		for (uint256 i = 0; i < _count; i++) {
			info.ribbits.transferFrom(msg.sender, address(this), _tokenIds[i]);
		}
		uint256 _amount = _count * 1e18;
		info.totalSupply += _amount;
		info.users[msg.sender].balance += _amount;
		emit Transfer(address(0x0), msg.sender, _amount);
	}

	function unwrap(uint256[] calldata _tokenIds) external returns (uint256 totalUnwrapped) {
		uint256 _count = _tokenIds.length;
		require(balanceOf(msg.sender) >= _count * 1e18);
		totalUnwrapped = 0;
		for (uint256 i = 0; i < _count; i++) {
			if (info.ribbits.ownerOf(_tokenIds[i]) == address(this)) {
				info.ribbits.transferFrom(address(this), msg.sender, _tokenIds[i]);
				totalUnwrapped++;
			}
		}
		require(totalUnwrapped > 0);
		uint256 _cost = totalUnwrapped * 1e18;
		info.totalSupply -= _cost;
		info.users[msg.sender].balance -= _cost;
		emit Transfer(msg.sender, address(0x0), _cost);
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

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 wrbtReserve, uint256 userRibbits, bool userApproved, uint256 userBalance, uint256 userLPBalance) {
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		wrbtReserve = info.weth0 ? _res1 : _res0;
		userRibbits = info.ribbits.balanceOf(_user);
		userApproved = info.ribbits.isApprovedForAll(_user, address(this));
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

contract Ribbits {

	uint256 constant private MAX_NAME_LENGTH = 32;
	uint256 constant private TOTAL_RIBBITS = 1000;
	uint256 constant private CLAIM_COST = 0.1 ether;

	struct User {
		uint256[] list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
	}

	struct Ribbit {
		bool claimed;
		address owner;
		address approved;
		string name;
	}

	struct Info {
		mapping(uint256 => Ribbit) list;
		mapping(address => User) users;
		Metadata metadata;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	string constant public compositeHash = "11df1dfb29760fdf721b68137825ebbf350a69f92ac50a922088f0240e62e0d3";

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Rename(address indexed owner, uint256 indexed tokenId, string name);


	constructor() public {
		info.metadata = new Metadata();
		info.owner = msg.sender;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		// Initial Claims
		address _receiver = msg.sender;
		_claim(77,  _receiver);
		_claim(114, _receiver);
		_claim(168, _receiver);
		_claim(172, _receiver);
		_claim(173, _receiver);
		_claim(210, _receiver);
		_claim(275, _receiver);
		_claim(285, _receiver);
		_claim(595, _receiver);
		_claim(726, _receiver);

		_receiver = 0xcb4BfcF57aee5e8ad825Cde1012fEe1cC62d8e4c;
		_claim(368, _receiver);
		_claim(737, _receiver);
		_claim(751, _receiver);
		_claim(895, _receiver);
		_claim(49,  _receiver);
		_claim(242, _receiver);
		_claim(391, _receiver);

		_receiver = 0x8F83Eb7ABb2bCf57347298d9BF09A2d284190643;
		_claim(534, _receiver);
		_claim(729, _receiver);
		_claim(35,  _receiver);
		_claim(55,  _receiver);
		_claim(68,  _receiver);
		_claim(621, _receiver);
		_claim(796, _receiver);
		_claim(971, _receiver);
		_claim(167, _receiver);
		_claim(152, _receiver);
		_claim(202, _receiver);
		_claim(205, _receiver);
		_claim(221, _receiver);
		_claim(283, _receiver);
		_claim(299, _receiver);
		_claim(309, _receiver);
		_claim(325, _receiver);
		_claim(341, _receiver);
		_claim(367, _receiver);
		_claim(393, _receiver);
		_claim(405, _receiver);
		_claim(452, _receiver);
		_claim(485, _receiver);
		_claim(507, _receiver);
		_claim(526, _receiver);
		_claim(542, _receiver);
		_claim(609, _receiver);
		_claim(723, _receiver);
		_claim(500, _receiver);
		_claim(16,  _receiver);
		_claim(46,  _receiver);
		_claim(79,  _receiver);

		_claim(822, 0xACE5BeedDDc24dec659eeEcb21A3C21F5576e3C9);
		_claim(934, 0xface14522b18BE412e9DB0E1570Be94Cb9af0A88);
		_claim(894, 0xFADE7bB65A1e06D11B3F099b225ddC7C8Ae65967);
		_claim(946, 0xC0015CfE8C0e00423E2D84853E5A9052EdcdF8b2);
		_claim(957, 0xce1179C2e69edBaCaB52485a75C0Ae4a979b0919);
		_claim(712, 0xea5e37c75383331a1de5b7f7f1a93Ef080b319Be);
		_claim(539, 0xD1CEbD1Ad772c8A6dD05eCdFA0ae776a9266032c);
		_claim(549, 0xFEED4873Ab0D642dD4b694EdA6FF90cD732fE4C9);
		_claim(364, 0xCafe59428b2946FBc128fd6C36cb1Ec1443AeD6C);
		_claim(166, 0xb01d89cb608b46a9EB697ee11e2df6313BCbEb20);
		_claim(547, 0x1eadc5E9A94e61BFe4819274aBBEE1e23805bA38);
		_claim(515, 0xF01D2ba4F31161Bb89e7Ab3cf443AaA38426dC65);
		_claim(612, 0xF00Da17Fd777Bf2ae536816C016fF1593F9CDDC3);
	}

	function setOwner(address _owner) external {
		require(msg.sender == info.owner);
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external {
		require(msg.sender == info.owner);
		info.metadata = _metadata;
	}

	function ownerWithdraw() external {
		require(msg.sender == info.owner);
		uint256 _balance = address(this).balance;
		require(_balance > 0);
		msg.sender.transfer(_balance);
	}


	function claim(uint256 _tokenId) external payable {
		claimFor(_tokenId, msg.sender);
	}

	function claimFor(uint256 _tokenId, address _receiver) public payable {
		uint256[] memory _tokenIds = new uint256[](1);
		address[] memory _receivers = new address[](1);
		_tokenIds[0] = _tokenId;
		_receivers[0] = _receiver;
		claimManyFor(_tokenIds, _receivers);
	}

	function claimMany(uint256[] calldata _tokenIds) external payable returns (uint256) {
		uint256 _count = _tokenIds.length;
		address[] memory _receivers = new address[](_count);
		for (uint256 i = 0; i < _count; i++) {
			_receivers[i] = msg.sender;
		}
		return claimManyFor(_tokenIds, _receivers);
	}

	function claimManyFor(uint256[] memory _tokenIds, address[] memory _receivers) public payable returns (uint256 totalClaimed) {
		uint256 _count = _tokenIds.length;
		require(_count > 0 && _count == _receivers.length);
		require(msg.value >= CLAIM_COST * _count);
		totalClaimed = 0;
		for (uint256 i = 0; i < _count; i++) {
			if (!getClaimed(_tokenIds[i])) {
				_claim(_tokenIds[i], _receivers[i]);
				totalClaimed++;
			}
		}
		require(totalClaimed > 0);
		uint256 _cost = CLAIM_COST * totalClaimed;
		if (msg.value > _cost) {
			msg.sender.transfer(msg.value - _cost);
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

	function totalSupply() public pure returns (uint256) {
		return TOTAL_RIBBITS;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].list.length;
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

	function getName(uint256 _tokenId) public view returns (string memory) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].name;
	}

	function getClaimed(uint256 _tokenId) public view returns (bool) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].claimed;
	}

	function tokenByIndex(uint256 _index) external pure returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function getRibbit(uint256 _tokenId) public view returns (address tokenOwner, address approved, string memory tokenName, bool claimed) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getName(_tokenId), getClaimed(_tokenId));
	}

	function getRibbits(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bool[] memory claimeds) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		claimeds = new bool[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], , claimeds[i]) = getRibbit(_tokenIds[i]);
		}
	}

	function getRibbitsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bool[] memory claimeds, uint256 totalRibbits, uint256 totalPages) {
		require(_limit > 0);
		totalRibbits = totalSupply();

		if (totalRibbits > 0) {
			totalPages = (totalRibbits / _limit) + (totalRibbits % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalRibbits % _limit != 0) {
				_limit = totalRibbits % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = (_isAsc ? _offset + i : totalRibbits - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, claimeds) = getRibbits(tokenIds);
	}

	function getOwnerRibbitsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, uint256 totalRibbits, uint256 totalPages) {
		require(_limit > 0);
		totalRibbits = balanceOf(_owner);

		if (totalRibbits > 0) {
			totalPages = (totalRibbits / _limit) + (totalRibbits % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalRibbits % _limit != 0) {
				_limit = totalRibbits % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalRibbits - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, ) = getRibbits(tokenIds);
	}

	function allClaimeds() external view returns (bool[] memory claimeds) {
		uint256 _length = totalSupply();
		claimeds = new bool[](_length);
		for (uint256 i = 0; i < _length; i++) {
			claimeds[i] = getClaimed(i);
		}
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		(address _owner, address _approved, , ) = getRibbit(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(address(0x0), address(0x0), _tokenId);
		}

		uint256 _index = info.users[_from].indexOf[_tokenId] - 1;
		uint256 _movedRibbit = info.users[_from].list[info.users[_from].list.length - 1];
		info.users[_from].list[_index] = _movedRibbit;
		info.users[_from].indexOf[_movedRibbit] = _index + 1;
		info.users[_from].list.length--;
		delete info.users[_from].indexOf[_tokenId];
		info.users[_to].indexOf[_tokenId] = info.users[_to].list.push(_tokenId);
		emit Transfer(_from, _to, _tokenId);
	}

	function _claim(uint256 _tokenId, address _receiver) internal {
		require(!getClaimed(_tokenId));
		info.list[_tokenId].claimed = true;
		info.list[_tokenId].owner = _receiver;
		info.users[_receiver].indexOf[_tokenId] = info.users[_receiver].list.push(_tokenId);
		emit Transfer(address(0x0), _receiver, _tokenId);
	}
}