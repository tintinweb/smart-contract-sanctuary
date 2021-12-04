// SPDX-License-Identifier: MIT

import "./ERC721.sol";

pragma solidity ^0.8.0;

contract Administrable {
	address admin;
	address nextAdmin;
	
	constructor () {
		admin = msg.sender;
	}
	
	function giveAdmin(address addr) external {
		require(msg.sender == admin);
		
		nextAdmin = addr;
	}
	function takeAdmin() external {
		require(msg.sender == nextAdmin);
		require(msg.sender != address(0));
		
		admin = nextAdmin;
		nextAdmin = address(0);
	}
}

contract Bmp is Administrable, ERC721("PixelMap", "Map") {
	bytes constant BaseHeader = 'Qk0AAAAAAAAAAEoAAAAMAAAAAAAAAAEABAAAAACAAAAAgACAgAAAAICAAIAAgIDAwMCAgID/AAAA/wD//wAAAP//AP8A//////8A';
	uint constant CostUnit = 1e10;
	
	struct Pixel {
		address owner;
		uint8 value;
		uint8 level;
	}
	struct PixelResponse {
		address owner;
		uint8 value;
		uint cost;
	}
	struct Map {
		uint16 width;
		uint16 height;
		bytes content;
	}
	Map[] maps;
	mapping(uint => Pixel) pixels;
	mapping(address => uint) public balances;
	
	function createMap(uint16 w, uint16 h) public {
		require(msg.sender == admin);
		
		require(w%8 == 0);
		require(w > 0);
		require(h > 0);
		
		require(maps.length < 2**128);
		uint tokenId = maps.length;
		_safeMint(msg.sender, tokenId);
		
		uint width = uint(w);
		uint height = uint(h);
		
		maps.push(Map(w, h, BaseHeader));
		Map storage map = maps[tokenId];
		
		uint size = 74 + width*height/2;
		uint contentLength = (size/3)*4;
		if(size%3 > 0) {
			contentLength += 1+size%3;
		}
		
		for(uint i=100;i<contentLength;++i) {
			map.content.push('A');
		}
		
		(map.content[0], map.content[1], map.content[2], map.content[3]) = Base64.encode3u8(0x42, 0x4d, uint8(size));
		(map.content[4], map.content[5], map.content[6], map.content[7]) = Base64.encode3u8(uint8(size>>8), uint8(size>>16), uint8(size>>24));
		
		(map.content[24], map.content[25], map.content[26], map.content[27]) = Base64.encode3u8(uint8(width), uint8(width>>8), uint8(height));
		(map.content[28], map.content[29], map.content[30], map.content[31]) = Base64.encode3u8(uint8(height>>8), 0x01, 0x00);
	}
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
		return string(abi.encodePacked("data:application/json,{", 
			'"name":"', Base64.encodeStr1u24(uint24(tokenId)), '",',
			'"description":"",',
			'"image":"', string(abi.encodePacked('data:image/bmp;base64,', maps[tokenId].content)), '"',
		'}'));
	}
	function getMapSize(uint256 tokenId) public view returns (uint16, uint16) {
		Map storage map = maps[tokenId];
		return (map.width, map.height);
	}
	
	function listPixels(uint256 tokenId) public view returns (PixelResponse[][] memory) {
		require(tokenId < 2**128);
		
		Map storage map = maps[tokenId];
		
		PixelResponse[][] memory result = new PixelResponse[][](map.width);
		
		for(uint x=0; x<map.width; ++x) {
			result[x] = new PixelResponse[](map.height);
			for(uint y=0; y<map.height; ++y) {
				uint pixelId = tokenId<<128 | uint(x)<<16 | uint(y);
				Pixel storage pixel = pixels[pixelId];
				
				result[x][y] = PixelResponse(pixel.owner, pixel.value, (CostUnit<<pixel.level) * 100);
			}
		}
		
		return result;
	}
	
	function getPixel(uint256 tokenId, uint16 x, uint16 y) public view returns (address owner, uint8 value, uint cost) {
		require(tokenId < 2**128);
		uint pixelId = tokenId<<128 | uint(x)<<16 | uint(y);
		Pixel storage pixel = pixels[pixelId];
		
		owner = pixel.owner;
		value = pixel.value;
		cost = (CostUnit << pixel.level) * 100;
	}
	
	function putPixels(uint256 tokenId, bytes calldata packed) public payable {
		uint len = packed.length;
		require(len%5 == 0);
		
		uint fee = msg.value;
		
		uint feeMapOwner = 0;
		uint feeAdmin = 0;
		
		for(uint i=0;i<packed.length;i+=5) {
			uint16 x = (uint16(uint8(packed[i]))<<8) | (uint16(uint8(packed[i+1])));
			uint16 y = (uint16(uint8(packed[i+2]))<<8) | (uint16(uint8(packed[i+3])));
			uint8 value = uint8(packed[i+4]);
			
			putPixelContent(tokenId, x, y, value);
			(address pixelOwner, uint costPixel, uint costMap, uint costAdmin) = putPixelData(tokenId, x, y, value);
			
			if(fee < costPixel) revert();
			fee -= costPixel;
			sendFee(pixelOwner, costPixel);
			
			feeMapOwner += costMap;
			feeAdmin += costAdmin;
		}
		
		if(fee < feeMapOwner) revert();
		fee -= feeMapOwner;
		sendFee(ownerOf(tokenId), feeMapOwner);
		
		if(fee < feeAdmin) revert();
		fee -= feeAdmin;
		sendFee(admin, feeAdmin);
		
		if(fee > 0) {
			sendFee(msg.sender, fee);
			fee = 0;
		}
	}
	function sendFee(address addr, uint value) internal {
		bool result = payable(addr).send(value);
		if(!result) {
			balances[addr] += value;
		}
	}
	function withdrawBalance() external {
		uint value = balances[msg.sender];
		
		payable(msg.sender).call{value:value, gas:gasleft()}('');
		
		balances[msg.sender] -= value;
	}
	
	function estimateCost(uint256 tokenId, bytes calldata packed) public view returns (uint) {
		return estimateCost(tokenId, packed, 0);
	}
	function estimateCost(uint256 tokenId, bytes calldata packed, uint levelAdjust) public view returns (uint cost) {
		require(tokenId < 2**128);

		uint len = packed.length;
		require(len%5 == 0);

		for(uint i=0;i<packed.length;i+=5) {
			uint16 x = (uint16(uint8(packed[i]))<<8) | (uint16(uint8(packed[i+1])));
			uint16 y = (uint16(uint8(packed[i+2]))<<8) | (uint16(uint8(packed[i+3])));

			uint pixelId = tokenId<<128 | uint256(x)<<16 | uint256(y);
			Pixel storage pixel = pixels[pixelId];
			cost += CostUnit << (pixel.level+levelAdjust);
		}
		
		cost *= 100;
	}
	
	function putPixelData(uint256 tokenId, uint16 x, uint16 y, uint8 value) internal returns (address pixelOwner, uint costPixel, uint costMap, uint costAdmin) {
		require(tokenId < 2**128);
		uint pixelId = tokenId<<128 | uint256(x)<<16 | uint256(y);
		Pixel storage pixel = pixels[pixelId];
		
		pixelOwner = (pixel.owner!=address(0)) ? pixel.owner : ownerOf(tokenId);
		uint cost = CostUnit << pixel.level;
		
		costAdmin = cost;
		costMap = cost*2;
		costPixel = cost*97;
		
		pixel.owner = msg.sender;
		pixel.value = value;
		pixel.level++;
	}
	function putPixelContent(uint256 tokenId, uint16 x, uint16 y, uint8 value) internal {
		Map storage map = maps[tokenId];
		
		require(x < map.width);
		require(y < map.height);
		require(value < 16);
		
		uint indexLastBit = 74*8 + (uint(y)*map.width + uint(x))*4 + 3;
		uint indexU6 = (indexLastBit/6);
		uint right = 5-(indexLastBit%6);
		uint16 mask;
		if(right == 0) {
			mask = 0x0ff0;
		} else if(right == 2) {
			mask = 0x0fc3;
		} else if(right == 4) {
			mask = 0x0f0f;
		}
		
		uint16 u12 = Base64.decode1u12(map.content[indexU6-1], map.content[indexU6]);
		u12 &= mask;
		u12 |= uint16(value) << uint16(right);
		
		(map.content[indexU6-1], map.content[indexU6]) = Base64.encode1u12(u12);
	}
}

library Base64 {
	bytes constant chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
	
	function encode1u12(uint16 n) internal pure returns (bytes1, bytes1) {
		return ( chars[(n>>6)&63], chars[(n)&63] );
	}
	function encode1u24(uint24 n) internal pure returns (bytes1, bytes1, bytes1, bytes1) {
		return ( chars[(n>>18)&63], chars[(n>>12)&63], chars[(n>>6)&63], chars[(n)&63] );
	}
	function encode3u8(uint8 a, uint8 b, uint8 c) internal pure returns (bytes1, bytes1, bytes1, bytes1) {
		return Base64.encode1u24( uint24(a)<<16 | uint24(b)<<8 | uint24(c) );
	}
	function encodeStr1u24(uint24 n) internal pure returns (string memory) {
		return string(abi.encodePacked( chars[(n>>18)&63], chars[(n>>12)&63], chars[(n>>6)&63], chars[(n)&63] ));
	}
	
	function decode1u6(bytes1 c) internal pure returns (uint8) {
		if(c == '+') return 62;
		if(c == '/') return 63;
		
		uint8 n = uint8(c);
		if(n >= 0x41 && n <= 0x5a) return (n-0x41);
		if(n >= 0x61 && n <= 0x7a) return (n-0x61+26);
		if(n >= 0x30 && n <= 0x39) return (n-0x30+52);
		
		revert();
	}
	function decode1u12(bytes1 a, bytes1 b) internal pure returns (uint16) {
		return (uint16(Base64.decode1u6(a)) << 6) | uint16(Base64.decode1u6(b));
	}
}