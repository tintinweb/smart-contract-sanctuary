/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-13
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract DeploymentFactory{
    event Deployed(address indexed preComputedAddress);

    function memcpy(uint dest, uint src, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length,"substring!");

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }
    
    function stringMemoryTobytes32(string memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }
  
    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < uint8(10)) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function bytes32ToAsciiString(bytes32 _bytes32, uint len) private pure returns (string memory) {
        bytes memory s = new bytes((len*2)+2);
        s[0] = 0x30;
        s[1] = 0x78;
      
        for (uint i = 0; i < len; i++) {
            bytes1 b = bytes1(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2+(2 * i)] = char(hi);
            s[2+(2 * i) + 1] = char(lo);
        }
        return string(s);
    }
    
    function bytesMemoryTobytes32(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }

    
    function shortenByteCode(bytes memory _byteCode) internal pure returns (bytes memory) {
      uint len = _byteCode.length;
      uint newLen = len-(len % 64);
      require((newLen % 64)==0,"shortenByteCode failed");
      
      return substring(_byteCode, 0, newLen);
    }


    // we need bytecode of the contract to be deployed along with the constructor parameters
    function getBytecode() public pure returns (bytes memory){
        return type(TestContract).creationCode;
    }

    //compute the deployment address
    function computeAddress(bytes memory _byteCode, uint256 _salt)public view returns (address ){
        bytes32 hash_ = keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(_byteCode)));
        return address(uint160(uint256(hash_)));
    }

    //deploy the contract and check the event for the deployed address
    function deploy(bytes memory _byteCode, uint256 _salt)public payable{
        address depAddr;

        assembly{
            depAddr:= create2(callvalue(),add(_byteCode,0x20), mload(_byteCode), _salt)
        
        if iszero(extcodesize(depAddr)){
            revert(0,0)
        }

        }
        emit Deployed(depAddr);
    }

}
contract TestContract{
    uint256 storedNumber;

    function increment() public {
        storedNumber++;
    }
}