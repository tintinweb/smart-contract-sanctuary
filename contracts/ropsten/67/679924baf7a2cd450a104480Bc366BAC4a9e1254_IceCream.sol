/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity >=0.5.8;

contract IceCream {
    string public jcp;

    function set(string memory x) public {
        jcp = x;
    }

    function get() public view returns (string memory) {
        return jcp;
    }
}