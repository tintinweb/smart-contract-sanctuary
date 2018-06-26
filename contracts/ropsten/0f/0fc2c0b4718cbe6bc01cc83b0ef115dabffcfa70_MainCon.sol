pragma solidity 0.4.24;

contract MainCon {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function doSomething() external returns(uint) {
        return(10);
    }
}