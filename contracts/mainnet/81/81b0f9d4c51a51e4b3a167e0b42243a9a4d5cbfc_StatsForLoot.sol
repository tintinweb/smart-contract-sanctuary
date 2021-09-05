/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 ___  ____  __  ____  ___ 
/ __)(_  _)(  )(_  _)/ __)
\__ \  )(  /__\  )(  \__ \
(___/ (__)(_)(_)(__) (___/
Stats (for Loot)
100% on-chain and easily extendable character statistics, made for the Loot metaverse.

Created by sol_dev

*/

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

contract StatsForLoot {

	uint256 constant public MAX_SUPPLY = 8000;
	uint256 constant public MINT_COST = 0.02 ether;

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
	}

	struct Info {
		uint256 totalSupply;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		address owner;
	}
	Info private info;

	string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
	string[] private stats = ["Strength", "Dexterity", "Constitution", "Wisdom", "Intelligence", "Charisma"];
	string[] private shortStats = ["STR", "DEX", "CON", "WIS", "INT", "CHA"];

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	event Mint(address indexed owner, uint256 indexed tokenId, bytes32 seed);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
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


	function name() external pure returns (string memory) {
		return "Stats (for Loot)";
	}

	function symbol() external pure returns (string memory) {
		return "STAT";
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory out) {
		out = "data:application/json;base64,";
		string memory _json = string(abi.encodePacked('{"name":"STAT #', _uint2str(_tokenId), '","description":"100% on-chain and easily extendable character statistics, made for the Loot metaverse.",'));
		_json = string(abi.encodePacked(_json, '"image":"data:image/svg+xml;base64,', _encode(bytes(getSVG(_tokenId))), '","attributes":['));
		uint256[8] memory _settings = getSettingsCompressed(getSeed(_tokenId));
		for (uint256 i = 0; i < stats.length; i++) {
			_json = string(abi.encodePacked(_json, '{"trait_type":"', stats[i], '","value":', _uint2str(_settings[i]), '},'));
		}
		_json = string(abi.encodePacked(_json, '{"trait_type":"Modifier","value":"', stats[_settings[6]], '"},'));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Modifier Value","value":', _uint2str(_settings[7]), '}]}'));
		out = string(abi.encodePacked(out, _encode(bytes(_json))));
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

	function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function getSVG(uint256 _tokenId) public view returns (string memory svg) {
		uint256[8] memory _settings = getSettingsCompressed(getSeed(_tokenId));
		uint256 _modifierIndex = _settings[6];
		uint256 _modifierAmount = _settings[7];
		svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>text { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
		for (uint256 i = 0; i < stats.length; i++) {
			svg = string(abi.encodePacked(svg, '<text x="10" y="', _uint2str(20 * (i + 1)), '">', stats[i], ': ', _uint2str(_settings[i])));
			if (i == _modifierIndex) {
				svg = string(abi.encodePacked(svg, " (+", _uint2str(_modifierAmount), ")"));
			}
			svg = string(abi.encodePacked(svg, "</text>"));
		}
		svg = string(abi.encodePacked(svg, '<text x="10" y="150">Modifier: ', shortStats[_modifierIndex], " +", _uint2str(_modifierAmount), "</text></svg>"));
	}

	function getTokenSettings(uint256 _tokenId) public view returns (uint256 strength, uint256 dexterity, uint256 constitution, uint256 wisdom, uint256 intelligence, uint256 charisma, uint256 modifierIndex, uint256 modifierAmount) {
		(strength, dexterity, constitution, wisdom, intelligence, charisma, modifierIndex, modifierAmount) = getSettings(getSeed(_tokenId));
	}

	function getSettings(bytes32 _seed) public pure returns (uint256 strength, uint256 dexterity, uint256 constitution, uint256 wisdom, uint256 intelligence, uint256 charisma, uint256 modifierIndex, uint256 modifierAmount) {
		bytes32 _rand = keccak256(abi.encodePacked("Stats:", _seed));
		(_rand, strength) = _rollDice(_rand);
		(_rand, dexterity) = _rollDice(_rand);
		(_rand, constitution) = _rollDice(_rand);
		(_rand, wisdom) = _rollDice(_rand);
		(_rand, intelligence) = _rollDice(_rand);
		(_rand, charisma) = _rollDice(_rand);
		_rand = keccak256(abi.encodePacked(_rand));
		modifierIndex = uint256(_rand) % 6;
		_rand = keccak256(abi.encodePacked(_rand));
		modifierAmount = 10 - _sqrt(uint256(_rand) % 100);
	}

	function getSettingsCompressed(bytes32 _seed) public pure returns (uint256[8] memory data) {
		(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]) = getSettings(_seed);
	}

	function getStrength(uint256 _tokenId) external view returns (uint256 strength) {
		(strength, , , , , , , ) = getTokenSettings(_tokenId);
	}

	function getDexterity(uint256 _tokenId) external view returns (uint256 dexterity) {
		( , dexterity, , , , , , ) = getTokenSettings(_tokenId);
	}

	function getConstitution(uint256 _tokenId) external view returns (uint256 constitution) {
		( , , constitution, , , , , ) = getTokenSettings(_tokenId);
	}

	function getWisdom(uint256 _tokenId) external view returns (uint256 wisdom) {
		( , , , wisdom, , , , ) = getTokenSettings(_tokenId);
	}

	function getIntelligence(uint256 _tokenId) external view returns (uint256 intelligence) {
		( , , , , intelligence, , , ) = getTokenSettings(_tokenId);
	}

	function getCharisma(uint256 _tokenId) external view returns (uint256 charisma) {
		( , , , , , charisma, , ) = getTokenSettings(_tokenId);
	}

	function getModifier(uint256 _tokenId) external view returns (uint256 modifierIndex, uint256 modifierAmount) {
		( , , , , , , modifierIndex, modifierAmount) = getTokenSettings(_tokenId);
	}

	function getStat(uint256 _tokenId) public view returns (address tokenOwner, address approved, bytes32 seed, uint256[8] memory data) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getSeed(_tokenId), getSettingsCompressed(getSeed(_tokenId)));
	}

	function getStats(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bytes32[] memory seeds, uint256[8][] memory datas) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		seeds = new bytes32[](_length);
		datas = new uint256[8][](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], seeds[i], datas[i]) = getStat(_tokenIds[i]);
		}
	}

	function getStatsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bytes32[] memory seeds, uint256[8][] memory datas, uint256 totalStats, uint256 totalPages) {
		require(_limit > 0);
		totalStats = totalSupply();

		if (totalStats > 0) {
			totalPages = (totalStats / _limit) + (totalStats % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalStats % _limit != 0) {
				_limit = totalStats % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalStats - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, seeds, datas) = getStats(tokenIds);
	}

	function getOwnerStatsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, bytes32[] memory seeds, uint256[8][] memory datas, uint256 totalStats, uint256 totalPages) {
		require(_limit > 0);
		totalStats = balanceOf(_owner);

		if (totalStats > 0) {
			totalPages = (totalStats / _limit) + (totalStats % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalStats % _limit != 0) {
				_limit = totalStats % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalStats - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, seeds, datas) = getStats(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _mint() internal {
		require(msg.sender == tx.origin);
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


	function _uint2str(uint256 _value) internal pure returns (string memory) {
		uint256 _digits = 1;
		uint256 _n = _value;
		while (_n > 9) {
			_n /= 10;
			_digits++;
		}
		bytes memory _out = new bytes(_digits);
		for (uint256 i = 0; i < _out.length; i++) {
			uint256 _dec = (_value / (10**(_out.length - i - 1))) % 10;
			_out[i] = bytes1(uint8(_dec) + 48);
		}
		return string(_out);
	}

	function _sqrt(uint256 _n) internal pure returns (uint256 result) {
		uint256 _tmp = (_n + 1) / 2;
		result = _n;
		while (_tmp < result) {
			result = _tmp;
			_tmp = (_n / _tmp + _tmp) / 2;
		}
	}

	function _rollDice(bytes32 _rand) internal pure returns (bytes32 rand, uint256 result) {
		result = 0;
		rand = _rand;
		for (uint256 i = 0; i < 3; i++) {
			rand = keccak256(abi.encodePacked(rand));
			result += uint256(rand) % 6 + 1;
		}
	}

	function _encode(bytes memory _data) internal pure returns (string memory) {
		if (_data.length == 0) return '';
		string memory table = TABLE;
		uint256 encodedLen = 4 * ((_data.length + 2) / 3);
		string memory result = new string(encodedLen + 32);

		assembly {
			mstore(result, encodedLen)
			let tablePtr := add(table, 1)
			let dataPtr := _data
			let endPtr := add(dataPtr, mload(_data))
			let resultPtr := add(result, 32)

			for {} lt(dataPtr, endPtr) {}
			{
			   dataPtr := add(dataPtr, 3)
			   let input := mload(dataPtr)
			   mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
			   resultPtr := add(resultPtr, 1)
			   mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
			   resultPtr := add(resultPtr, 1)
			   mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
			   resultPtr := add(resultPtr, 1)
			   mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
			   resultPtr := add(resultPtr, 1)
			}
			switch mod(mload(_data), 3)
			case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
			case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
		}
		return result;
	}
}