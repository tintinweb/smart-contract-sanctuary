/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// File: Cow/PreSale/IPancakePair.sol



pragma solidity ^0.8.0;

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
// File: Cow/PreSale/test/TestPancakePair.sol



pragma solidity ^0.8.0;


contract TestPancakePair is IPancakePair {
    function getReserves() external pure returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (116729630729004375191481032,249364880256621537138050,1641452219);
    }
}