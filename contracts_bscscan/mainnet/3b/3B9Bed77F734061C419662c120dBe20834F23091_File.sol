/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

contract File
{
	string public name;
	string public mime;
	uint256 public fileSize;
	mapping (uint256 => address) public chunks;
	constructor(string memory _name, string memory _mime, address[] memory _chunks)
	{
		name = _name;
		mime = _mime;
		uint256 _fileSize = 0;
		uint256 extSize;
		for(uint i = 0; i < _chunks.length; i++)
		{
			address chunkAddr = _chunks[i];
			chunks[i] = chunkAddr;
			assembly
			{
				extSize := extcodesize(chunkAddr)
			}
			_fileSize += extSize;
		}
		fileSize = _fileSize;
	}

	function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns(string memory)
	{
		return string(abi.encodePacked(a, b, c, d, e));
	}

	function getName() external view returns(string memory)
	{
		return name;
	}

	function getBinary() external view returns(bytes memory)
	{
		bytes memory file = new bytes(fileSize);
		address addr;
		uint chunkNum = 0;
		uint bytesRead = 0;
		uint256 extSize;
		while(bytesRead < fileSize)
		{
			addr = chunks[chunkNum];
			assembly
			{
				extSize := extcodesize(addr)
				extcodecopy(addr, add(add(file, bytesRead), 0x20), 0, extSize)
			}
			chunkNum++;
			bytesRead += extSize;
		}
		return file;
	}

	function getUri() external view returns(string memory)
	{
		uint encodedSize = fileSize / 3;
		if(encodedSize * 3 != fileSize)
			encodedSize++;
		encodedSize *= 4;
		bytes memory encoded = new bytes(encodedSize);
		uint k = 0;
		bytes memory c = new bytes(3);
		uint ci = 0;
		uint chunkNum = 0;
		uint bytesRead = 0;
		address addr;
		uint256 extSize;
		bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
		bytes memory extCode;
		assembly
		{
			extCode := mload(0x40) // Use end of memory as a buffer, but don't claim it as used.
			                       // This operation is dangerous. No memory allocations must be performed
			                       // until we're done with the buffer, and we have no way of enforcing that.
		}
		while(bytesRead < fileSize)
		{
			addr = chunks[chunkNum];

			// Get external code
			assembly
			{
				extSize := extcodesize(addr)
				mstore(extCode, extSize)
				extcodecopy(addr, add(extCode, 0x20), 0, extSize)
			}

			// Encode
			for(uint i = 0; i < extSize; i++)
			{
				c[ci++] = extCode[i];
				if(ci == 3)
				{
					encoded[k++] = alphabet[(uint8(c[0]) >> 2) & 0x3F];
					encoded[k++] = alphabet[((uint8(c[0]) << 4) & 0x30) | ((uint8(c[1]) >> 4) & 0xF)];
					encoded[k++] = alphabet[((uint8(c[1]) << 2) & 0x3C) | ((uint8(c[2]) >> 6) & 0x3)];
					encoded[k++] = alphabet[uint8(c[2]) & 0x3F];
					ci = 0;
				}
			}
			chunkNum++;
			bytesRead += extSize;
		}
		if(ci == 1)
		{
			encoded[k++] = alphabet[(uint8(c[0]) >> 2) & 0x3F];
			encoded[k++] = alphabet[(uint8(c[0]) << 4) & 0x30];
			encoded[k++] = 0x3D;
			encoded[k++] = 0x3D;
		}
		if(ci == 2)
		{
			encoded[k++] = alphabet[(uint8(c[0]) >> 2) & 0x3F];
			encoded[k++] = alphabet[((uint8(c[0]) << 4) & 0x30) | ((uint8(c[1]) >> 4) & 0xF)];
			encoded[k++] = alphabet[(uint8(c[1]) << 2) & 0x3C];
			encoded[k++] = 0x3D;
		}
		string memory uri = string(abi.encodePacked("data:", mime, ";headers=Content-Disposition%3A%20attachment%3B%20filename%3D%22", name, "%22", ";base64,", encoded));
		return uri;
	}
}