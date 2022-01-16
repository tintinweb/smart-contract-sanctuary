// SPDX-License-Identifier: MIT

import "./Administrable.sol";

pragma solidity ^0.8.0;

contract Surname is Administrable {
	uint[256][4] packedCodes;
	
	function putPackedCodes(uint index, bytes calldata data) public {
		require(msg.sender == admin);
		
		packedCodes[index] = abi.decode(data, (uint[256]));
	}
	
	function nameCodeOf(uint index) public view returns (uint) {
		index &= 0x0fff;
		
		index = index<2048 ? index*2 : 8191-index*2;
		uint i = index >> 2;
		uint countBit = (index<40) ? 31 : ((index<344) ? 46 : 60);
		uint code = packedCodes[i/256][i%256];
		index &= 3;
		if(index == 0) {
			//code <<= 0;
			code >>= (256-countBit);
		} else if(index == 1) {
			code <<= (countBit);
			code >>= (128+countBit);
		} else if(index == 2) {
			code <<= (128);
			code >>= (256-countBit);
		} else if(index == 3) {
			code <<= (128+countBit);
			code >>= (128+countBit);
		}

		return code;
	}
}