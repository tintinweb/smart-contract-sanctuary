// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*

       .
      ":"
    ___:____     |"\/"|
  ,'        `.    \  /
  |  O        \___/  |
~^~^~^~^~^~^~^~^~^~^~^~^~

Whales Game | Generative Yield NFTs
Mint tokens and earn KRILL with this new blockchain based game! Battle it out to see who can generate the most yield.

Website: https://whales.game/

*/

interface WhalesGameInterface {
	function getToken(uint256 _tokenId) external view returns (address tokenOwner, address approved, bytes32 seed, bool isWhale);
}


contract Metadata {

	string public name = "Whales Game";
	string public symbol = "WG";

	string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	struct Trait {
		string trait;
		string[] names;
		string[] imgs;
	}

	struct Traits {
		string base;
		Trait[] traits;
	}
	
	struct Info {
		address owner;
		WhalesGameInterface wg;
		Traits whaleTraits;
		Traits fishermanTraits;
		string[] colors;
	}
	Info private info;
	
	
	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(string memory _whaleBase, string memory _fishermenBase, string[] memory _colors) {
		info.owner = msg.sender;
		info.whaleTraits.base = _whaleBase;
		info.fishermanTraits.base = _fishermenBase;
		info.colors = _colors;
	}

	function createTrait(bool _isWhale, string memory _trait, string[] memory _names, string[] memory _imgs) external _onlyOwner {
		require(_names.length > 0 && _names.length == _imgs.length);
		Traits storage _traits = _isWhale ? info.whaleTraits : info.fishermanTraits;
		_traits.traits.push(Trait(_trait, _names, _imgs));
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setWhalesGame(WhalesGameInterface _wg) external _onlyOwner {
		info.wg = _wg;
	}

	function deploySetWhalesGame(WhalesGameInterface _wg) external {
		require(tx.origin == owner() && whalesGameAddress() == address(0x0));
		info.wg = _wg;
	}


	function whalesGameAddress() public view returns (address) {
		return address(info.wg);
	}

	function owner() public view returns (address) {
		return info.owner;
	}
	
	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		( , , bytes32 _seed, bool _isWhale) = info.wg.getToken(_tokenId);
		string memory _json = string(abi.encodePacked('{"name":"', _isWhale ? 'Whale' : 'Fisherman', ' #', _uint2str(_tokenId), '","description":"Some description content...",'));
		_json = string(abi.encodePacked(_json, '"image":"data:image/svg+xml;base64,', _encode(bytes(getRawSVG(_seed, _isWhale))), '","attributes":['));
		_json = string(abi.encodePacked(_json, '{"trait_type":"Type","value":"', _isWhale ? 'Whale' : 'Fisherman', '"}'));
		(string[] memory _traits, string[] memory _values, ) = getRawTraits(_seed, _isWhale);
		for (uint256 i = 0; i < _traits.length; i++) {
			if (keccak256(bytes(_values[i])) != keccak256(bytes("None"))) {
				_json = string(abi.encodePacked(_json, ',{"trait_type":"', _traits[i], '","value":"', _values[i], '"}'));
			}
		}
		_json = string(abi.encodePacked(_json, ']}'));
		return string(abi.encodePacked("data:application/json;base64,", _encode(bytes(_json))));
	}

	function getSVG(uint256 _tokenId) public view returns (string memory) {
		( , , bytes32 _seed, bool _isWhale) = info.wg.getToken(_tokenId);
		return getRawSVG(_seed, _isWhale);
	}

	function getRawSVG(bytes32 _seed, bool _isWhale) public view returns (string memory svg) {
		svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 44 44">'));
		uint256 _colorIndex = uint256(keccak256(abi.encodePacked('color:', _seed))) % info.colors.length;
		svg = string(abi.encodePacked(svg, '<rect width="100%" height="100%" fill="#', info.colors[_colorIndex], '" />'));
		Traits storage _traits = _isWhale ? info.whaleTraits : info.fishermanTraits;
		svg = string(abi.encodePacked(svg, '<image x="6" y="6" width="32" height="32" image-rendering="pixelated" href="data:image/png;base64,', _traits.base, '"/>'));
		( , , uint256[] memory _indexes) = getRawTraits(_seed, _isWhale);
		for (uint256 i = 0; i < _indexes.length; i++) {
			svg = string(abi.encodePacked(svg, '<image x="6" y="6" width="32" height="32" image-rendering="pixelated" href="data:image/png;base64,', _traits.traits[i].imgs[_indexes[i]], '"/>'));
		}
		svg = string(abi.encodePacked(svg, '</svg>'));
	}

	function getTraits(uint256 _tokenId) public view returns (string[] memory traits, string[] memory values) {
		( , , bytes32 _seed, bool _isWhale) = info.wg.getToken(_tokenId);
		(traits, values, ) = getRawTraits(_seed, _isWhale);
	}

	function getRawTraits(bytes32 _seed, bool _isWhale) public view returns (string[] memory traits, string[] memory values, uint256[] memory indexes) {
		bytes32 _last = _seed;
		Traits storage _traits = _isWhale ? info.whaleTraits : info.fishermanTraits;
		uint256 _length = _traits.traits.length;
		traits = new string[](_length);
		values = new string[](_length);
		indexes = new uint256[](_length);
		for (uint256 i = 0; i < _length; i++) {
			_last = keccak256(abi.encodePacked(_last));
			uint256 _index = uint256(_last) % _traits.traits[i].names.length;
			traits[i] = _traits.traits[i].trait;
			values[i] = _traits.traits[i].names[_index];
			indexes[i] = _index;
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
}