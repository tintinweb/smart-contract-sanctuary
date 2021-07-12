/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.8.0;


contract simpleTG {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function simple(uint16 x, uint16 y) public pure returns(uint16) {
        return (x + y);
    }
}