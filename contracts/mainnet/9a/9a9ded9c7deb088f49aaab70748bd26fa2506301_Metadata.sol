// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./WTFNFT.sol";

interface PriceOracle {
	function getPrice() external view returns (uint256);
}


contract Metadata {
	
	string public name = "fees.wtf NFT";
	string public symbol = "fees.wtf";

	string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	WTFNFT public nft;
	PriceOracle public oracle;

	constructor(WTFNFT _nft) {
		nft = _nft;
		oracle = PriceOracle(0xe89b5B2770Aa1a6BcfAc6F3517510aB8e9146651);
	}

	function setPriceOracle(PriceOracle _oracle) external {
		require(msg.sender == nft.owner());
		oracle = _oracle;
	}


	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		( , , address _user, uint256[7] memory _info) = nft.getToken(_tokenId);
		return rawTokenURI(_user, _info[0], _info[1], _info[2], _info[3], _info[4], _info[5], _info[6], oracle.getPrice());
	}

	function rawTokenURI(address _user, uint256 _totalFees, uint256 _failFees, uint256 _totalGas, uint256 _avgGwei, uint256 _totalDonated, uint256 _totalTxs, uint256 _failTxs, uint256 _price) public pure returns (string memory) {
		string memory _json = string(abi.encodePacked('{"name":"', _trimAddress(_user, 6), '","description":"[fees.wtf](https://fees.wtf) snapshot at block 13916450 for [', _address2str(_user), '](https://etherscan.io/address/', _address2str(_user), ')",'));
		_json = string(abi.encodePacked(_json, '"image":"data:image/svg+xml;base64,', _encode(bytes(getRawSVG(_totalFees, _failFees, _totalGas, _avgGwei, _totalDonated, _totalTxs, _failTxs, _price))), '","attributes":['));
		if (_totalFees > 0) {
			_json = string(abi.encodePacked(_json, '{"trait_type":"Total Fees","value":', _uint2str(_totalFees, 18, 5, false, true), '}'));
			_json = string(abi.encodePacked(_json, ',{"trait_type":"Fail Fees","value":', _uint2str(_failFees, 18, 5, false, true), '}'));
			_json = string(abi.encodePacked(_json, ',{"trait_type":"Total Gas","value":', _uint2str(_totalGas, 0, 0, false, false), '}'));
			_json = string(abi.encodePacked(_json, ',{"trait_type":"Average Gwei","value":', _uint2str(_avgGwei, 9, 5, false, true), '}'));
			_json = string(abi.encodePacked(_json, ',{"trait_type":"Total Transactions","value":', _uint2str(_totalTxs, 0, 0, false, false), '}'));
			_json = string(abi.encodePacked(_json, ',{"trait_type":"Failed Transactions","value":', _uint2str(_failTxs, 0, 0, false, false), '}'));
			_json = string(abi.encodePacked(_json, ',{"display_type":"number","trait_type":"Spender Level","value":', _uint2str(_logn(_totalFees / 1e13, 2), 0, 0, false, false), '}'));
			_json = string(abi.encodePacked(_json, ',{"display_type":"number","trait_type":"Oof Level","value":', _uint2str(_logn(_failFees / 1e13, 2), 0, 0, false, false), '}'));
		}
		if (_totalDonated > 0) {
			_json = string(abi.encodePacked(_json, _totalFees > 0 ? ',' : '', '{"display_type":"number","trait_type":"Donator Level","value":', _uint2str(_logn(_totalDonated / 1e14, 10) + 1, 0, 0, false, false), '}'));
		}
		_json = string(abi.encodePacked(_json, ']}'));
		return string(abi.encodePacked("data:application/json;base64,", _encode(bytes(_json))));
	}

	function getSVG(uint256 _tokenId) public view returns (string memory) {
		uint256[7] memory _info = nft.getTokenCompressedInfo(_tokenId);
		return getRawSVG(_info[0], _info[1], _info[2], _info[3], _info[4], _info[5], _info[6], oracle.getPrice());
	}

	function getRawSVG(uint256 _totalFees, uint256 _failFees, uint256 _totalGas, uint256 _avgGwei, uint256 _totalDonated, uint256 _totalTxs, uint256 _failTxs, uint256 _price) public pure returns (string memory svg) {
		svg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' preserveAspectRatio='xMidYMid meet' viewBox='0 0 512 512' width='100%' height='100%'>"));
		svg = string(abi.encodePacked(svg, "<defs><style type='text/css'>text{text-anchor:middle;alignment-baseline:central;}tspan>tspan{fill:#03a9f4;font-weight:700;}</style></defs>"));
		svg = string(abi.encodePacked(svg, "<rect width='100%' height='100%' fill='#222222' />"));
		svg = string(abi.encodePacked(svg, "<text x='0' y='256' transform='translate(256)' fill='#f0f8ff' font-family='Arial,sans-serif' font-weight='600' font-size='30'>"));
		if (_totalFees > 0) {
			svg = string(abi.encodePacked(svg, unicode"<tspan x='0' dy='-183'>You spent <tspan>Ξ", _uint2str(_totalFees, 18, 5, true, false), "</tspan> on gas</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>before block 13916450.</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>Right now, that's</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'><tspan>$", _uint2str(_totalFees * _price / 1e18, 18, 2, true, true), "</tspan>.</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='70'>You used <tspan>", _uint2str(_totalGas, 0, 0, true, false), "</tspan></tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>gas to send <tspan>", _uint2str(_totalTxs, 0, 0, true, false), "</tspan></tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>transaction", _totalTxs == 1 ? "" : "s", ", with an average</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>price of <tspan>", _uint2str(_avgGwei, 9, 3, true, false), "</tspan> Gwei.</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='70'><tspan>", _uint2str(_failTxs, 0, 0, true, false), "</tspan> of them failed,</tspan>"));
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='35'>costing you <tspan>", _failFees == 0 ? "nothing" : string(abi.encodePacked(unicode"Ξ", _uint2str(_failFees, 18, 5, true, false))), "</tspan>.</tspan></text>"));
		} else {
			svg = string(abi.encodePacked(svg, "<tspan x='0' dy='8'>Did not qualify.</tspan></text>"));
		}
		if (_totalDonated > 0) {
			for (uint256 i = 0; i <= _logn(_totalDonated / 1e14, 10); i++) {
				for (uint256 j = 0; j < 4; j++) {
					string memory _prefix = string(abi.encodePacked("<text x='", j < 2 ? "16" : "496", "' y='", j % 2 == 0 ? "18" : "498", "' font-size='10' transform='translate("));
					svg = string(abi.encodePacked(svg, _prefix, j < 2 ? "" : "-", _uint2str(16 * i, 0, 0, false, false), ")'>", unicode"❤️</text>"));
					if (i > 0) {
						svg = string(abi.encodePacked(svg, _prefix, "0,", j % 2 == 0 ? "" : "-", _uint2str(16 * i, 0, 0, false, false), ")'>", unicode"❤️</text>"));
					}
				}
			}
		}
		svg = string(abi.encodePacked(svg, "<text x='0' y='500' transform='translate(256)' fill='#f0f8ff' font-family='Arial,sans-serif' font-weight='600' font-size='10'><tspan>fees<tspan>.wtf</tspan></tspan></text></svg>"));
	}


	function _logn(uint256 _num, uint256 _n) internal pure returns (uint256) {
		require(_n > 0);
		uint256 _count = 0;
		while (_num > _n - 1) {
			_num /= _n;
			_count++;
		}
		return _count;
	}
	
	function _address2str(address _address) internal pure returns (string memory str) {
		str = "0x";
		for (uint256 i; i < 40; i++) {
			uint256 _hex = (uint160(_address) >> (4 * (39 - i))) % 16;
			bytes memory _char = new bytes(1);
			_char[0] = bytes1(uint8(_hex) + (_hex > 9 ? 87 : 48));
			str = string(abi.encodePacked(str, string(_char)));
		}
	}

	function _trimAddress(address _address, uint256 _padding) internal pure returns (string memory str) {
		require(_padding < 20);
		str = "";
		bytes memory _strAddress = bytes(_address2str(_address));
		uint256 _length = 2 * _padding + 2;
		for (uint256 i = 0; i < 2 * _padding + 2; i++) {
			bytes memory _char = new bytes(1);
			_char[0] = _strAddress[i < _padding + 2 ? i : 42 + i - _length];
			str = string(abi.encodePacked(str, string(_char)));
			if (i == _padding + 1) {
				str = string(abi.encodePacked(str, unicode"…"));
			}
		}
	}
	
	function _uint2str(uint256 _value, uint256 _scale, uint256 _maxDecimals, bool _commas, bool _full) internal pure returns (string memory str) {
		uint256 _d = _scale > _maxDecimals ? _maxDecimals : _scale;
		uint256 _n = _value / 10**(_scale > _d ? _scale - _d : 0);
		if (_n == 0) {
			return "0";
		}
		uint256 _digits = 1;
		uint256 _tmp = _n;
		while (_tmp > 9) {
			_tmp /= 10;
			_digits++;
		}
		_tmp = _digits > _d ? _digits : _d + 1;
		uint256 _offset = (!_full && _tmp > _d + 1 ? _tmp - _d - 1 > _d ? _d : _tmp - _d - 1 : 0);
		for (uint256 i = 0; i < _tmp - _offset; i++) {
			uint256 _dec = i < _tmp - _digits ? 0 : (_n / (10**(_tmp - i - 1))) % 10;
			bytes memory _char = new bytes(1);
			_char[0] = bytes1(uint8(_dec) + 48);
			str = string(abi.encodePacked(str, string(_char)));
			if (i < _tmp - _d - 1) {
				if (_commas && (i + 1) % 3 == (_tmp - _d) % 3) {
					str = string(abi.encodePacked(str, ","));
				}
			} else {
				if (!_full && (_n / 10**_offset) % 10**(_tmp - _offset - i - 1) == 0) {
					break;
				} else if (i == _tmp - _d - 1) {
					str = string(abi.encodePacked(str, "."));
				}
			}
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
}