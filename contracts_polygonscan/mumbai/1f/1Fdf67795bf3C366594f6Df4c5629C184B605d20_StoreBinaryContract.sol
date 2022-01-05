/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

pragma solidity ^0.8;

contract StoreBinaryContract {

    bytes private bin;
    
    function setBin(bytes memory _bin) public {
        bin = _bin;
    }

    function getBin() public view returns (bytes memory) {
        return bin;
    }
}