pragma solidity 0.4.24;

contract XYZ {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function doSomething() external {
        emit SomethingDone(address(this));
    }

    event SomethingDone(address _addr);
}

contract ABC {
    address public owner;

    XYZ xyz_;

    constructor(XYZ _xyz) public {
        xyz_ = _xyz;
        owner = msg.sender;
    }

    function interactWithXYZ() external {
        xyz_.doSomething();
    }
}