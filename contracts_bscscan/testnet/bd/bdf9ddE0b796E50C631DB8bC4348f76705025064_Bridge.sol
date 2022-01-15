/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// File: encode.sol


// Creator: @Dreadnaugh

pragma solidity 0.8.11;

contract Bridge {

    mapping (address=>uint) lastBlock;

    event key(bytes32 myKey);

    constructor(){
    }

    function encode(address to, uint amount, uint blockNumber) external {
        bytes32 hash = blockhash(blockNumber);
        require(hash != 0, "Transaction timeout!");
        require(block.number != lastBlock[to], "Please wait to request a withdraw again.");
        bytes32 myKey;
        uint counter = (uint(keccak256(abi.encodePacked(blockhash(blockNumber - 1)))) % 10);

        if (counter < 3){
            myKey = keccak256(abi.encodePacked(to, amount, hash));
        } else if (counter < 6){
            myKey = keccak256(abi.encodePacked(amount, to, hash));
        } else if (counter < 9){
            myKey = keccak256(abi.encodePacked(hash, amount, to));
        } else{
            myKey = keccak256(abi.encodePacked(hash, to, amount));
        }

        lastBlock[to] = block.number;
        emit key(myKey);
    }

}