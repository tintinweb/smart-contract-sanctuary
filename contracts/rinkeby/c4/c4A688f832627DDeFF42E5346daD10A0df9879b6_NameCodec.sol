// SPDX-License-Identifier: MIT

//import "@openzeppelin/contracts/utils/Strings.sol";
import "./Strings.sol";

pragma solidity ^0.8.0;

library NameCodec {
	bytes constant Vowels = 'aiueo';
	bytes constant Consonants = ' kgsztdnhbpmyrwy';
	
	function decodeCon(uint current, uint next) internal pure returns (bytes memory) {
		if(current < 5) {
			return '';
		} else if(current == 16) {
			return 'sh';
		} else if(current == 21) {
			return 'j';
		} else if(current == 26) {
			return 'ch';
		} else if(current == 31 && next < 75) {
			return 'j';
		} else if(current == 27) {
			return 'ts';
		} else if(current == 32) {
			return 'z';
		} else if(current == 42) {
			return 'f';
		} else if(current == 63) {
			return 'n';
		} else if(current == 72) {
			return '';
		} else if(current >= 71) {
			return '';
		}
		
		return abi.encodePacked(Consonants[(current/5)], (next >= 75 ? 'y' : ''));
	}
	function decodeVow(uint current, uint next) internal pure returns (bytes memory) {
		return next >= 75 ? abi.encodePacked(Vowels[next%5]) : abi.encodePacked(Vowels[current%5]);
	}
	
	function decodeKana(uint current, uint next, uint prev) internal pure returns (bytes memory) {
		if(current == 63) return 'n';
		if(current == 72) return next==61 ? bytes('ttsu') : bytes('');
		if(current >= 75) return '';
		if(current == 61) return '';
		
		bytes memory con = decodeCon(current, next);
		if(prev == 72 && con.length>0) {
			if(current == 26) {
				con = abi.encodePacked('t', con);
			} else {
				con = abi.encodePacked(con[0], con);
			}
		}
		return abi.encodePacked(con, decodeVow(current, next));
	}

	function extractKanaCode(uint code) internal pure returns (uint result) {
		result = code&0x7f;
		if(result == 0) {
			result = 61;
		} else if(result <= 61) {
			result -= 1;
		}
	}
	function decodeYomi(uint code) internal pure returns (bytes memory) {
		bytes memory result = '';
		
		uint prev = 61;
		uint current = extractKanaCode(code);
		uint next;

		while(code > 0) {
			code >>= 7;
			next = extractKanaCode(code);
			result = abi.encodePacked(result, decodeKana(current, next, prev));
			
			prev = current;
			current = next;
		}

		result[0] = bytes1(uint8(result[0]) - 0x20);
		
		return result;
	}
	

	function decodeKangi(uint code) internal pure returns (bytes memory result) {
		uint16 u = uint16(code&0x7fff);
		u += u<0x0e00 ? 0x3000 : 0x4000;
		
		result = bytes(Strings.toHexString(u, 2));
		result[0] = '\\';
		result[1] = 'u';
	}
	
	function decode(uint code) public pure returns (string memory kaki, string memory yomi) {
		uint kakiLength = (code&0x03) + 1;
		code >>= 2;
		
		for(uint i=0;i<kakiLength;++i) {
			kaki = string(abi.encodePacked(kaki, decodeKangi(code)));
			code >>= 15;
		}
		
		yomi = string(decodeYomi(code));
	}
}