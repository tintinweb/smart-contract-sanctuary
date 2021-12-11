/**
 *Submitted for verification at FtmScan.com on 2021-12-11
*/

pragma solidity 0.8.10;

contract StaticcallWrapper {
    function fetch(address destination, bytes memory data) external view returns (bool success, bytes memory result) {
        (success, result) = destination.staticcall(data);
    }
}