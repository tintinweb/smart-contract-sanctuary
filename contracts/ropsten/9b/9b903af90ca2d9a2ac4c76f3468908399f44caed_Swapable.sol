/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity 0.6.12;

contract Swapable {
   
    mapping(string => uint256) internal map;

    function add(string memory oldAddress, uint256 balance) public {
        map[oldAddress] = balance;
    }
    
    function check(string memory oldAddress) public view returns (uint256) {
        return map[oldAddress];
    }
}