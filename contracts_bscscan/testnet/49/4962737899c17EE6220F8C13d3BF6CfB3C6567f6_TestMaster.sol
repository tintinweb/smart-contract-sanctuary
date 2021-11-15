// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract TestCreatable {
    uint public x;
    constructor(uint a) payable {
        x = a;
    }
}

contract TestMaster {
    TestCreatable d = new TestCreatable(4); // will be executed as part of C's constructor
    event NewCreatableContract(address indexed sous);

    constructor() {
        emit NewCreatableContract(address(d));
    }
    function createD(uint arg) public {
        TestCreatable newD = new TestCreatable(arg);
        newD.x();
        emit NewCreatableContract(address(newD));
    }
}

