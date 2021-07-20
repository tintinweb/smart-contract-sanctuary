/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity 0.8.4;
contract Test {
    uint256[3] public a;
    
    function set(uint256 i) public {
        a[i] = block.number;
    }
}