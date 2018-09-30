pragma solidity 0.4.24;
pragma experimental "v0.5.0";

contract Vesting {
    address public controllerAddr;

    constructor(address _controllerAddr) public {
        controllerAddr = _controllerAddr;
    }
}