/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*      
       /|  /|   
   ___//__//__  
  '--//--//---' 
 ___//__//__    
'--//--//---'   
  |/  |/        

HashGlyphs
100% on-chain and immutable artistic interpretations of keccak256 hashes, visualized through random walks.

Website: https://hashglyphs.com/
Created by sol_dev

*/

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract HashGlyphs {

	uint256 constant public MAX_NAME_LENGTH = 32;
	uint256 constant public MAX_SUPPLY = 2048;
	uint256 constant public MINT_COST = 0.05 ether;
	uint256 constant private DEPTH = 85;
	uint256 constant private GRID_TO_LINE = 20;
	uint256 constant private PADDING = 1;
	bytes3 constant private DEFAULT_BG_COLOR = bytes3(0x000000);
	bytes4 constant private DEFAULT_LINE_COLOR = bytes4(0xffffffff);

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
		bytes3 bgColor;
		bytes4 lineColor;
		string name;
	}

	struct Info {
		uint256 totalSupply;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		address owner;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Mint(address indexed owner, uint256 indexed tokenId, bytes32 seed);
	event RecolorBackground(address indexed owner, uint256 indexed tokenId, bytes3 color);
	event RecolorLine(address indexed owner, uint256 indexed tokenId, bytes4 color);
	event Rename(address indexed owner, uint256 indexed tokenId, string name);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}

	modifier _onlyTokenOwner(uint256 _tokenId) {
		require(msg.sender == ownerOf(_tokenId));
		_;
	}


	constructor() {
		info.owner = msg.sender;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		for (uint256 i = 0; i < 10; i++) {
			_mint(DEFAULT_BG_COLOR, DEFAULT_LINE_COLOR);
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
		mintManyWithColors(_tokens, DEFAULT_BG_COLOR, DEFAULT_LINE_COLOR);
	}

	function mintWithColors(bytes3 _bgColor, bytes4 _lineColor) public payable {
		mintManyWithColors(1, _bgColor, _lineColor);
	}

	function mintManyWithColors(uint256 _tokens, bytes3 _bgColor, bytes4 _lineColor) public payable {
		require(_tokens > 0);
		uint256 _cost = _tokens * MINT_COST;
		require(msg.value >= _cost);
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(_bgColor, _lineColor);
		}
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}
	
	function setBackgroundColor(uint256 _tokenId, bytes3 _color) external _onlyTokenOwner(_tokenId) {
		info.list[_tokenId].bgColor = _color;
		emit RecolorBackground(msg.sender, _tokenId, _color);
	}
	
	function setLineColor(uint256 _tokenId, bytes4 _color) external _onlyTokenOwner(_tokenId) {
		info.list[_tokenId].lineColor = _color;
		emit RecolorLine(msg.sender, _tokenId, _color);
	}
	
	function rename(uint256 _tokenId, string calldata _newName) external _onlyTokenOwner(_tokenId) {
		require(bytes(_newName).length <= MAX_NAME_LENGTH);
		info.list[_tokenId].name = _newName;
		emit Rename(msg.sender, _tokenId, _newName);
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


	function name() external pure returns (string memory) {
		return "HashGlyphs";
	}

	function symbol() external pure returns (string memory) {
		return "#";
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		string memory _json = string(abi.encodePacked('{"name":"Glyph #', _uint2str(_tokenId), '","description":"100% on-chain and immutable artistic interpretations of keccak256 hashes, visualized through random walks.",'));
		_json = string(abi.encodePacked(_json, '"image":"data:image/svg+xml;base64,', _encode(bytes(getSVG(_tokenId))), '","attributes":['));
		( , uint256 _width, uint256 _height, , , uint256 _streak, uint256 _turns, uint256 _overlaps) = getTokenSettings(_tokenId);
		_json = string(abi.encodePacked(_json, '{"trait_type":"Width","value":', _uint2str(_width), '},'));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Height","value":', _uint2str(_height), '},'));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Streak","value":', _uint2str(_streak), '},'));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Turns","value":', _uint2str(_turns), '},'));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Overlaps","value":', _uint2str(_overlaps), '}]}'));
		return string(abi.encodePacked("data:application/json;base64,", _encode(bytes(_json))));
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

	function getBackgroundColor(uint256 _tokenId) public view returns (bytes3) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].bgColor;
	}

	function getLineColor(uint256 _tokenId) public view returns (bytes4) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].lineColor;
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

	function getSVG(uint256 _tokenId) public view returns (string memory) {
		return getSVGRaw(getSeed(_tokenId), getBackgroundColor(_tokenId), getLineColor(_tokenId));
	}

	function getSVGRaw(bytes32 _seed, bytes3 _bgColor, bytes4 _lineColor) public pure returns (string memory svg) {
		(int256[2][DEPTH + 1] memory _path, uint256 _width, uint256 _height, int256 _minX, int256 _minY, , , ) = getSettings(_seed);
		svg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' preserveAspectRatio='xMidYMid meet' viewBox='0 0 ", _uint2str((_width + 2 * PADDING) * GRID_TO_LINE), " ", _uint2str((_height + 2 * PADDING) * GRID_TO_LINE), "'>"));
		svg = string(abi.encodePacked(svg, "<rect width='100%' height='100%' fill='", _col2str(_bgColor), "' /><g fill='none' stroke='", _cola2str(_lineColor), "' stroke-width='1' stroke-linecap='round'>"));
		string memory _svgPath = "";
		for (uint256 i = 1; i < _path.length; i++) {
			_svgPath = string(abi.encodePacked(_svgPath, "<path d='M", _uint2str((PADDING + uint256(_path[i - 1][0] - _minX)) * GRID_TO_LINE), " ", _uint2str((PADDING + uint256(_path[i - 1][1] - _minY)) * GRID_TO_LINE), "L", _uint2str((PADDING + uint256(_path[i][0] - _minX)) * GRID_TO_LINE), " ", _uint2str((PADDING + uint256(_path[i][1] - _minY)) * GRID_TO_LINE), "' />"));
		}
		svg = string(abi.encodePacked(svg, _svgPath, "</g></svg>"));
	}

	function getTokenSettings(uint256 _tokenId) public view returns (int256[2][DEPTH + 1] memory path, uint256 width, uint256 height, int256 minX, int256 minY, uint256 streak, uint256 turns, uint256 overlaps) {
		(path, width, height, minX, minY, streak, turns, overlaps) = getSettings(getSeed(_tokenId));
	}

	function getSettings(bytes32 _seed) public pure returns (int256[2][DEPTH + 1] memory path, uint256 width, uint256 height, int256 minX, int256 minY, uint256 streak, uint256 turns, uint256 overlaps) {
		uint256 n = uint256(keccak256(abi.encodePacked("HashGlyph:", _seed)));
		int256[2][2] memory _minMax;
		uint256[3] memory _streak;
		_streak[0] = 8;
		uint256 _lastDir = 8;
		turns = 0;
		overlaps = 0;
		for (uint256 i = 1; i <= DEPTH; i++) {
			uint256 _dir = n % 8;
			n /= 8;
			path[i][0] = path[i - 1][0] + (_dir > 0 && _dir < 4 ? int256(1) : _dir > 4 ? -1 : int256(0));
			path[i][1] = path[i - 1][1] + (_dir < 2 || _dir == 7 ? -1 : _dir > 2 && _dir < 6 ? int256(1) : int256(0));

			_minMax[0][0] = _min(_minMax[0][0], path[i][0]);
			_minMax[0][1] = _max(_minMax[0][1], path[i][0]);
			_minMax[1][0] = _min(_minMax[1][0], path[i][1]);
			_minMax[1][1] = _max(_minMax[1][1], path[i][1]);

			if (_streak[0] != _dir) {
				_streak[0] = _dir;
				_streak[2] = _max(_streak[2], _streak[1]);
				_streak[1] = 1;
			} else {
				_streak[1]++;
			}

			if (_dir != _lastDir && _dir != (_lastDir + 4) % 8) {
				turns++;
			}
			_lastDir = _dir;

			for (uint256 j = 1; j < i; j++) {
				if ((path[i][0] == path[j][0] && path[i - 1][0] == path[j - 1][0] && path[i][1] == path[j][1] && path[i - 1][1] == path[j - 1][1]) || (path[i][0] == path[j - 1][0] && path[i - 1][0] == path[j][0] && path[i][1] == path[j - 1][1] && path[i - 1][1] == path[j][1])) {
					overlaps++;
					break;
				}
			}
		}
		minX = _minMax[0][0];
		minY = _minMax[1][0];
		width = uint256(_minMax[0][1] - minX);
		height = uint256(_minMax[1][1] - minY);
		streak = _max(_streak[2], _streak[1]);
	}

	function getGlyph(uint256 _tokenId) public view returns (address tokenOwner, address approved, bytes32 seed, bytes3 bgColor, bytes4 lineColor, string memory tokenName) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getSeed(_tokenId), getBackgroundColor(_tokenId), getLineColor(_tokenId), getName(_tokenId));
	}

	function getGlyphs(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes3[] memory bgColors, bytes4[] memory lineColors, bytes32[] memory names) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		seeds = new bytes32[](_length);
		bgColors = new bytes3[](_length);
		lineColors = new bytes4[](_length);
		names = new bytes32[](_length);
		for (uint256 i = 0; i < _length; i++) {
			string memory _name;
			(owners[i], approveds[i], seeds[i], bgColors[i], lineColors[i], _name) = getGlyph(_tokenIds[i]);
			names[i] = _str2b32(_name);
		}
	}

	function getGlyphsTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bytes3[] memory bgColors, bytes4[] memory lineColors, bytes32[] memory names, uint256 totalGlyphs, uint256 totalPages) {
		require(_limit > 0);
		totalGlyphs = totalSupply();

		if (totalGlyphs > 0) {
			totalPages = (totalGlyphs / _limit) + (totalGlyphs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalGlyphs % _limit != 0) {
				_limit = totalGlyphs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalGlyphs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, seeds, bgColors, lineColors, names) = getGlyphs(tokenIds);
	}

	function getOwnerGlyphsTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory tokenIds, address[] memory approveds, bytes32[] memory seeds, bytes3[] memory bgColors, bytes4[] memory lineColors, bytes32[] memory names, uint256 totalGlyphs, uint256 totalPages) {
		require(_limit > 0);
		totalGlyphs = balanceOf(_owner);

		if (totalGlyphs > 0) {
			totalPages = (totalGlyphs / _limit) + (totalGlyphs % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalGlyphs % _limit != 0) {
				_limit = totalGlyphs % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalGlyphs - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, seeds, bgColors, lineColors, names) = getGlyphs(tokenIds);
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 ownerBalance) {
		return (totalSupply(), balanceOf(_owner));
	}


	function _mint(bytes3 _bgColor, bytes4 _lineColor) internal {
		require(msg.sender == tx.origin);
		require(totalSupply() < MAX_SUPPLY);
		uint256 _tokenId = info.totalSupply++;
		Token storage _newToken = info.list[_tokenId];
		_newToken.owner = msg.sender;
		bytes32 _seed = keccak256(abi.encodePacked(_tokenId, msg.sender, blockhash(block.number - 1), gasleft()));
		_newToken.seed = _seed;
		_newToken.bgColor = _bgColor;
		_newToken.lineColor = _lineColor;
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


	function _str2b32(string memory _in) internal pure returns (bytes32 out) {
		if (bytes(_in).length == 0) {
			return 0x0;
		}
		assembly {
			out := mload(add(_in, 32))
		}
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

	function _col2str(bytes3 _color) internal pure returns (string memory) {
		bytes memory _out = new bytes(7);
		for (uint256 i = 0; i < _out.length; i++) {
			if (i == 0) {
				_out[i] = bytes1(uint8(35));
			} else {
				uint8 _hex = uint8(uint24(_color >> (4 * (_out.length - i - 1))) & 15);
				_out[i] = bytes1(_hex + (_hex > 9 ? 87 : 48));
			}
		}
		return string(_out);
	}

	function _cola2str(bytes4 _color) internal pure returns (string memory) {
		bytes memory _out = new bytes(9);
		for (uint256 i = 0; i < _out.length; i++) {
			if (i == 0) {
				_out[i] = bytes1(uint8(35));
			} else {
				uint8 _hex = uint8(uint32(_color >> (4 * (_out.length - i - 1))) & 15);
				_out[i] = bytes1(_hex + (_hex > 9 ? 87 : 48));
			}
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

	function _encode(bytes memory _data) internal pure returns (string memory result) {
		if (_data.length == 0) return '';
		string memory _table = TABLE;
		uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
		result = new string(_encodedLen + 32);

		assembly {
			mstore(result, _encodedLen)
			let tablePtr := add(_table, 1)
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

	function _min(int256 a, int256 b) internal pure returns (int256) {
		return a < b ? a : b;
	}

	function _max(int256 a, int256 b) internal pure returns (int256) {
		return a > b ? a : b;
	}

	function _max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}
}