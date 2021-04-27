/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;

contract Calculator {
    function add (uint256 num_1, uint256 num_2) public view returns(uint256) {
        return(num_1 + num_2);
    }
    function minus (int256 num_1, int256 num_2) public view returns(int256) {
        return(num_1 - num_2);
    }
    function multiple (uint256 num_1, uint256 num_2) public view returns(uint256) {
        return(num_1 * num_2);
    }
    function division (uint256 num_1, uint256 num_2) public view returns(uint256) {
        return(num_1 / num_2);
    }
}