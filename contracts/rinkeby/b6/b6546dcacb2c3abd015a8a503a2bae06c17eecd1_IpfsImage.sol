// SPDX-License-Identifier: MIT

import "./Administrable.sol";

pragma solidity ^0.8.0;

contract IpfsImage is Administrable {
	bytes prefix = 'https://infura-ipfs.io/ipfs/';
	
	function setPrefix(bytes calldata value) public {
		require(msg.sender == admin);
		
		prefix = value;
	}
	
	function imageOf(uint cid) public view returns (bytes memory) {
		return abi.encodePacked(prefix, IPFSCID.encode(cid));
	}
}

library IPFSCID {
	bytes constant chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
	uint112 constant Offset1 = 0x172c151325290607391d2c391b24;
	uint constant Offset0 = 0x2225180a020b291b260929391d1b31222525202804120031280917120b280400;
	
	function encode(uint value) internal pure returns (bytes memory result) {
		result = abi.encodePacked(Offset1, Offset0);
		
		uint l = result.length;
		uint carry = 0;
		uint v;
		
		uint i = l-1;
		while(true) {
			v = (value%58 + uint(uint8(result[i])) + carry);
			value /= 58;
			
			carry = v>=58 ? 1 : 0;
			v %= 58;
			result[i] = chars[v];
			
			if(i==0) break;
			--i;
		}
	}
}