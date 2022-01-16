// SPDX-License-Identifier: MIT

import "./Administrable.sol";

pragma solidity ^0.8.0;

contract GivenName is Administrable {
	uint[256] packedCodes;
	
	constructor(bytes memory data) {
		packedCodes = abi.decode(data, (uint[256]));
	}
	
	function putPackedCodes(bytes calldata data) public {
		require(msg.sender == admin);
		
		packedCodes = abi.decode(data, (uint[256]));
	}
	
	function nameCodeOf(uint index) public view returns (uint) {
		index &= 0x03ff;
		
		index = index<512 ? index*2 : 2047-index*2;
		uint code = packedCodes[index/4];
		index %= 4;
		if(index == 0) {
			//code <<= 0;
			code >>= (256-60);
		} else if(index == 1) {
			code <<= (60);
			code >>= (128+60);
		} else if(index == 2) {
			code <<= (128);
			code >>= (256-60);
		} else if(index == 3) {
			code <<= (128+60);
			code >>= (128+60);
		}

		return code;
	}
}