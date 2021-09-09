/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.4.26;

contract Callator {
    function doCall(address con, bytes calldata) public returns (bool result) {
        result = con.call(calldata);
    }
}