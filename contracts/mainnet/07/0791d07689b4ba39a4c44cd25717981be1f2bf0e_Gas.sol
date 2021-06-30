/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.23;

contract Gas {
    function gas() public view returns (uint256) {
        return gasleft();
    }
}