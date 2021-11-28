/**
 *Submitted for verification at arbiscan.io on 2021-11-27
*/

pragma solidity 0.5.11;

contract Blah {
    bytes32 public y;
    function abc(bytes32 x) public {
        y = sha256(abi.encodePacked(x));
    }
}