pragma solidity ^0.4.23;

interface TrueUSD {
    function sponsorGas() external;
}

contract SponsorHelper {
    TrueUSD public trueUSD = TrueUSD(0x0000000000085d4780B73119b644AE5ecd22b376);
    
    function sponsorGas() external {
        trueUSD.sponsorGas();
    }
}