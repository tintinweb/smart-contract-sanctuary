/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

pragma solidity ^0.8.7;

contract test {

    uint256 public c;

    function zhuanhuan(uint256 a,uint256 b) public {
        c = (a * (10**18)) + b;
    }

    function getbyuint16() public view returns(uint256 chuyishideliucifang, uint256 uint16jieduan) {
        return (c/10**18,uint16(c));
    }

    function getbyuint8() public view returns(uint256 chuyishideliucifang, uint256 uint8jieduan) {
        return (c/10**18,uint8(c));
    }

}