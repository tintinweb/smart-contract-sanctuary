pragma solidity ^0.4.4;

contract TestContractInterface {
    event Event0(address attr0, uint256 attr1);

    constructor() public {}

    function setAttr0(uint256 _value) external {}
}