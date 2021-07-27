/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity 0.8.4;

contract Exemplo {
    uint number;

    address public owner;

    constructor() {
        owner = address(msg.sender);
    }

    function setNumber(uint _number) external {
        require(owner == address(msg.sender), "ERROR: NOT OWNER");
        number = _number;
    }

    function getNumber() external view returns (uint) {
        return number;
    }

    function changeOwner(address newOwner) external {
        require(owner == address(msg.sender), "ERROR: NOT OWNER");
        owner = newOwner;
    }
}