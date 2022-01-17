/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// File: encode.sol


// Creator: @Dreadnaugh

pragma solidity 0.8.11;

contract Bridge {

    mapping (address=>uint) lastBlock;

    event key(bytes code, bytes32 myKey, bytes32 hash);

    constructor(){
    }

    function encode(address to, uint amount, uint blockNumber) external {
        bytes32 hash = blockhash(blockNumber);
        require(hash != 0, "Transaction timeout!");
        require(block.number != lastBlock[to], "Please wait to request a withdraw again.");
        bytes32 myKey;
        bytes memory code;

        code = abi.encodePacked(to, amount, hash);

        myKey = keccak256(code);

        lastBlock[to] = block.number;
        emit key(code, myKey, hash);
    }

}