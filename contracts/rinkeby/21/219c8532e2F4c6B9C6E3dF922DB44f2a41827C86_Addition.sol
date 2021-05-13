/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.5.0;

contract Addition {
    int number = -5;

    function add(int x) public {
        number += x;
    }

    function get_num() public view returns (int) {
        return number;
    }
}