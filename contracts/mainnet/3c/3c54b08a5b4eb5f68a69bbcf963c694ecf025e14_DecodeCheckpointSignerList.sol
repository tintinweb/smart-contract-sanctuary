/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecodeCheckpointSignerList {
    
    // Slice specified number of bytes from arbitrary length byte array, starting from certain index
    function slice(bytes memory payload, uint256 start, uint256 length) internal pure returns (bytes memory) {

        require(length + 31 >= length, "slice_overflow");
        require(start + length >= start, "slice_overflow");
        require(payload.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {

            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(length, 31)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(payload, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }

        }

        return tempBytes;
        
    }
    
    // Given input data for transaction invoking `submitHeaderBlock(bytes data, bytes sigs)`
    // attempts to extract out data & signature fields
    //
    // Note: Function signature is also included in `payload` i.e. first 4 bytes, which will be
    // stripped out 👇
    function decodeIntoDataAndSignature(bytes calldata payload) internal pure returns (bytes memory, bytes memory) {

        return abi.decode(slice(payload, 4, payload.length - 4), (bytes, bytes));

    }
    
    // Given 👆 function call for extracting `data` from transaction input data
    // has succeeded, votehash can be computed, which was signed by these check point signers
    function computeVoteHash(bytes memory payload) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked(hex"01", payload));

    }
    
    // Passing transaction input data of `submitHeaderBlock(bytes data, bytes sigs)` function
    // call, it attempts to figure out what are those signers who signer this checkpoint
    //
    // Note: Sending checkpoint from Matic Network ( L2 ) to Ethereum Network ( L1 )
    // is nothing but calling `submitHeaderBlock(bytes data, bytes sigs)`, defined
    // in RootChain contract, deployed on Ethereum Network, with proper arguments, by some validator.
    //
    // RootChain :
    //      0x2890bA17EfE978480615e330ecB65333b880928e [ Goerli ]
    //      0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287 [ Ethereum Mainnet ]
    function decode(bytes calldata payload) external pure returns (address[] memory) {
        
        (bytes memory data, bytes memory sigs) = decodeIntoDataAndSignature(payload);
        bytes32 voteHash = computeVoteHash(data);

        address[] memory signers = new address[](sigs.length / 65);
        uint256 count = 0;
      
        for(uint256 i = 0; i < sigs.length; i += 65) {
  
            bytes memory sig = slice(sigs, i, 65);
          
            bytes32 r;
            bytes32 s;
            uint8 v;
          
            assembly {
              
                r := mload(add(sig, 32))
                s := mload(add(sig, 64))
                v := and(mload(add(sig, 65)), 255)

            }

            if (v < 27) v += 27;

            signers[count++] = ecrecover(voteHash, v, r, s);

        }
      
        return signers;

    }

}