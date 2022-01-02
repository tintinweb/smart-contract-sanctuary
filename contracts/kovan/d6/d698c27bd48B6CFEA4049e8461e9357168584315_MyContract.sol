/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.8.7;

contract MyContract {
    uint number;

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setNumber(uint _number) public {
        number = _number;
    }
}