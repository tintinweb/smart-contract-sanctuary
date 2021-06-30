/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.1;

contract randomBlocks {
    event logCA(uint ca);

    function shift(uint num, uint bitsToKeep, uint startingPos) public pure returns (uint) {
        uint shifted;
        shifted = num << (256 - bitsToKeep);
        shifted = shifted >> (256 - bitsToKeep - startingPos);
        return shifted;
    }

    function neighborhood(uint ca, uint k, uint n)public pure returns (uint) {

        uint shifted;

        if(n == (k - 1)){

            shifted = uint(ca >> ((k -1) - 1));
            if( (ca << (256-1) == 2**(256 - 1)) ) shifted += 4;

        }else if(n == 0){

            shifted =  ca << ((k -1) - 1 + (256 - k));
            shifted = shifted >> ((k -1) - 2 + (256 - k));
            if( (ca >= 2**(k - 1))) shifted++;

        }else{

            shifted =  ca << ((k -1) - n - 1 + (256 - k));
            shifted = shifted >> (((k-1) - n - 1) + (n - 1) + (256 - k));

        }

        return shifted;
    }

    function run(uint offset) public {
        uint _rule = block.timestamp % 256;
        uint k = 19;
        uint blockNum = block.number;
        offset = (offset % 255) + 1;
        bytes32 randomHash = blockhash(blockNum - offset);
        uint steps = shift(uint(randomHash), 5, 0);

        uint ca = shift(block.difficulty, 5, 0) + shift(blockNum, 6, 5) + shift(tx.gasprice, 5, 11) + shift(uint(block.coinbase), 3, 16);

        for(uint j =0; j< steps; j++){
            uint copy = ca;
            for(uint i = 0; i < k; i++){
                uint nei =  neighborhood(ca, k, i);
                if(uint(_rule & (1 << nei)) != 0){
                    copy = uint(copy | (1 << i));
                }else{
                    copy = uint(copy & (~(1 << i)));
                }
            }
            ca = copy;
        }
        emit logCA(ca);
    }
}