/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity >=0.4.23;

interface SpotLike {
    function file(bytes32 ilk, bytes32 what, address pip_) external;
}

contract SetSpot {
    function run() external {
        SpotLike(0xFA6388B7980126C2d7d0c5FC02949a2fF40F95DE).file("MATIC-A", "pip", 0x0B80158520d75868019579D109e5C3B10085663E);
        SpotLike(0xFA6388B7980126C2d7d0c5FC02949a2fF40F95DE).file("ETH-A", "pip", 0x5CadE8b6f31f01A7c4aBB2B551A836606e1c8063);
    }
}