/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity >=0.4.23;

contract Test {
    function soul(address usr)
        external view
        returns (bytes32 tag)
    {
        assembly { tag := extcodehash(usr) }
    }
}