/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.4.24;

contract Tests {

    uint[] public testArr;

    event TestBlockHash(uint blockNumber, bytes32 blockhash1, bytes32 blockhash, bool result);

    function encodeTest (uint commitLastBlock, uint commit) pure public returns (bytes , bytes, bytes) {
        bytes memory commitEncode = abi.encodePacked(commit);
        bytes memory commitLastBlockEncode = abi.encodePacked(uint40(commitLastBlock));
        bytes memory message = abi.encodePacked(uint40(commitLastBlock), commit);
        
        return (commitEncode, commitLastBlockEncode, message);
    }
    
    function keakTest (uint commitLastBlock, uint commit) pure public returns (bytes32  , bytes32 , bytes32, uint ) {
        bytes32  commitEncode = keccak256(abi.encodePacked(commit));
        uint  commitUint = uint(keccak256(abi.encodePacked(commit)));
        bytes32  commitLastBlockEncode = keccak256(abi.encodePacked(uint40(commitLastBlock)));
        bytes32  message = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        
        return (commitEncode, commitLastBlockEncode, message, commitUint);
    }

    function signTest (address secretSigner, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s ) pure public returns (address, address, bytes32) {
        bytes32  message = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        address result = ecrecover(message, v, r, s);

        return (result, secretSigner, message);
    }

    function blockNumberTest(bytes32 lastBlockHash) public returns (uint, bytes32, bytes32, bool){//uint, uint40, 
        testArr.push(uint40(block.number));
        uint blockNumber = block.number;
        bool result = (lastBlockHash == blockhash(block.number-1));
        emit TestBlockHash(blockNumber, blockhash(block.number-1), blockhash(block.number), result);
        return ( blockNumber, blockhash(block.number-1), blockhash(block.number), result );
    }


    function newBlock() public returns(uint[]) {
        testArr.push(uint40(block.number));
        return testArr;
    }

}