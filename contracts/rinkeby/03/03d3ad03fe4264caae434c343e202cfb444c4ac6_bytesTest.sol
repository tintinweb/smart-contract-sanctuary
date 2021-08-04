/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract bytesTest {
    
    bytes public byteTest = abi.encodePacked(bytes32(0), bytes32(0));
    bytes4 public myBytes = 0x00ff0000;
    bytes32 public bytesFull = bytes32(uint256(2**256-1));
    bytes public fourQuartersFull = abi.encode(bytesFull,bytesFull,bytesFull,bytesFull);
    
    
    uint256[1024] public decoded;
    
    function shiftRight() public returns (bytes4) {
        myBytes = myBytes >> 1;
        
        return myBytes;
    }
    
    function shiftLeft() public returns (bytes4) {
        myBytes = myBytes << 1;
        
        return myBytes;
    }
    
    function shiftByteRight() public returns (bytes4) {
        myBytes = myBytes >> 8;
        
        return myBytes;
    }
    
    function shiftByteLeft() public returns (bytes4) {
        myBytes = myBytes << 8;
        
        return myBytes;
    }
    
    // Returns a decoded array of 8 pixels from the encoded bytes1 format (0x00-0xff)
    function decodePixelSegment(bytes1 encodedSegment) public pure returns (uint256[8] memory) {
        uint8 encodedSegmentBinary = uint8(encodedSegment);
        
        uint256[8] memory encodedSegmentBinaryArray;
        uint256 n = encodedSegmentBinary;
        
        for (uint8 i = 0; i < 8; i++) {
            encodedSegmentBinaryArray[7 - i] = (n % 2 == 1) ? uint256(1) : uint256(0);
            n /= 2;
        }

        return encodedSegmentBinaryArray;
    }
    
    // Decode the 16x16 matrix
    function decodePixelMatrixFull() public {
        
        bytes memory toDecode = fourQuartersFull;
        
		for (uint256 q = 0; q < 4; q++) {
    		for (uint256 i = 0; i < 32; i++) {
    		    for (uint256 j = 0; j < 8; j++) {
                    decoded[q*32*8+i*8+j] = decodePixelSegment(toDecode[i*q])[j];
    		    }
    		}
		}
    }
    
    // Decode the 16x16 matrix
    function decodePixelMatrixFullReadOnly() public view returns(uint256[1024] memory) {
        
        bytes memory toDecode = fourQuartersFull;
        uint256[1024] memory localDecoded;
        
		for (uint256 q = 0; q < 4; q++) {
    		for (uint256 i = 0; i < 32; i++) {
    		    for (uint256 j = 0; j < 8; j++) {
                    localDecoded[q*32*8+i*8+j] = decodePixelSegment(toDecode[i*q])[j];
    		    }
    		}
		}
		
		return localDecoded;
    }
    
    // Decode the 16x16 matrix
    function decodePixelMatrixSmall() public {
        
        bytes memory toDecode = abi.encode(bytesFull);
        
		for (uint256 i = 0; i < 32; i++) {
		    for (uint256 j = 0; j < 8; j++) {
                decoded[i*8+j] = decodePixelSegment(toDecode[i])[j];
		    }
		}
        
    }
}