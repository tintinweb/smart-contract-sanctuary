/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// File: encode.sol


// Creator: @Dreadnaugh

pragma solidity 0.8.11;

contract Bridge {

    mapping (address=>uint) lastBlock;

    event key(bytes code, uint counter, bytes32 myKey);

    constructor(){
    }

    function encode(address to, uint amount, uint blockNumber) external {
        bytes32 hash = blockhash(blockNumber);
        require(hash != 0, "Transaction timeout!");
        require(block.number != lastBlock[to], "Please wait to request a withdraw again.");
        bytes32 myKey;
        uint counter = (uint(keccak256(abi.encodePacked(blockhash(blockNumber - 1)))) % 10);
        bytes memory code;

        if (counter < 3){
            code = abi.encodePacked(to, amount, hash);
        } else if (counter < 6){
            code = abi.encodePacked(amount, to, hash);
        } else if (counter < 9){
            code = abi.encodePacked(hash, amount, to);
        } else{
           code = abi.encodePacked(hash, to, amount);
        }

        myKey = keccak256(code);

        lastBlock[to] = block.number;
        emit key(code, counter, myKey);
    }

}