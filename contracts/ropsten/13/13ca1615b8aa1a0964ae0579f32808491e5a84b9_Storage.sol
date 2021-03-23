/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity >=0.4.22 <0.7.0;

contract Storage {

    uint256 number;

    function set(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        return number;
    }
}