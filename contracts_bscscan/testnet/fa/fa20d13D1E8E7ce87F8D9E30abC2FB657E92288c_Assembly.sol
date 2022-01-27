pragma solidity ^0.5.16;

import "./lib/Memory.sol";

contract Assembly {
    // function test() external pure returns (uint sum){
    //     assembly {
    //         sum := 1
    //     }

    // }
    // bytes public constant INIT_CONSENSUS_STATE_BYTES =
    //     hex"42696e616e63652d436861696e2d4e696c650000000000000000000000000000000000000000000229eca254b3859bffefaf85f4c95da9fbd26527766b784272789c30ec56b380b6eb96442aaab207bc59978ba3dd477690f5c5872334fc39e627723daa97e441e88ba4515150ec3182bc82593df36f8abb25a619187fcfab7e552b94e64ed2deed000000e8d4a51000";

    // uint256 public addr;
    // uint256 public len;

    // function fullTest(uint256 _pointer,uint256 num) external {
    //     bytes memory bts = INIT_CONSENSUS_STATE_BYTES;
    //     assembly{
    //         let xxx := add(bts, /*BYTES_HEADER_SIZE*/num)
    //         sstore(_pointer,xxx)
    //     }
    // }
    //  function fullTest2(uint256 num) external pure returns(uint256 _res){
    //     bytes memory bts = INIT_CONSENSUS_STATE_BYTES;
    //     assembly{
    //         _res := add(bts, /*BYTES_HEADER_SIZE*/num)
            
    //     }
    // }
    // function fullTest3(uint256 num) external pure returns(uint256 _res){
    //     bytes memory bts = INIT_CONSENSUS_STATE_BYTES;

    //     assembly{
    //         _res := add(bts, /*BYTES_HEADER_SIZE*/num)
            
    //     }
    // }

    // function czTest() external returns (uint256 _addrr,uint256 _lenn){
    //     (_addrr, _lenn) = Memory.fromBytes(INIT_CONSENSUS_STATE_BYTES);
    // }

    // function byteLength(bytes calldata _b) external pure returns (uint256) {
    //     return _b.length;
    // }

    // function gg() external pure returns (bytes memory) {
    //     return
    //         hex"42696e616e63652d436861696e2d4e696c650000000000000000000000000000000000000000000229eca254b3859bffefaf85f4c95da9fbd26527766b784272789c30ec56b380b6eb96442aaab207bc59978ba3dd477690f5c5872334fc39e627723daa97e441e88ba4515150ec3182bc82593df36f8abb25a619187fcfab7e552b94e64ed2deed000000e8d4a51000";
    // }
    // function w() external pure returns (address){
    //     bytes20  x = hex"12345678ff0102";
    //     return address(x);
    // }
 
    // function combineToFunctionPointer(uint newSelector) public pure returns (uint _test) {
    //     assembly {
    //         _test := newSelector
    //     }
    // }
    // function mstore(uint256 _pointer,uint256 _data) external {
    //     assembly {
    //         mstore(_pointer,_data)
    //     }
    // }
    // function sstore(uint256 _pointer,uint256 _data) external {
    //     assembly {
    //         sstore(_pointer,_data)
    //     }
    // }
    // function mload(uint256 _pointer) external view returns(uint256 _res){
    //     assembly {
    //         _res := mload(_pointer)
    //     }
    // }
    // function sload(uint256 _pointer) external view returns(uint256 _res){
    //     assembly {
    //         _res := sload(_pointer)
    //     }
    // }

    function byteTest() external view returns(uint256){
        bytes1 b = hex"10";
        return b.length;
    }
    function byteTest2() external view returns(bytes1){
        bytes1 x = hex"10";
        return x;
    }
}

pragma solidity ^0.5.16;

library Memory {

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }
}