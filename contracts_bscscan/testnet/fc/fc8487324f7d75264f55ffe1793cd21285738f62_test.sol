/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

pragma solidity ^0.8.7;

contract test {
    function sliceUint(bytes memory bs, uint256 start) public returns(uint256){
        require(bs.length >= start + 32,"slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs,add(0x20, start)))
        }
        return x;
    }
}