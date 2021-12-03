/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.6.7;

contract MyFirstContract {
    uint256 number;

    function changeNumber(uint256 _num) public {
        number = _num;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}