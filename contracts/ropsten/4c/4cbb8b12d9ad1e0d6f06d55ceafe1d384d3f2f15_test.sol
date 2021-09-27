/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.0;

contract test {
    uint256[] private arr;
    
    function add(uint256 n) public {
        arr.push(n);
    }
    
    function del(uint256 pos) public {
        delete arr[pos];
    }
    
    function getl() public view returns (uint256) {
        return arr.length;
    }
    
    function getarr() public view returns (uint256[] memory) {
        return arr;
    }
}