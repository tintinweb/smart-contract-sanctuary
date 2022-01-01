/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
Let's say Alice can see the code of Foo and Bar but not Mal.
It is obvious to Alice that Foo.callBar() executes the code inside Bar.log().
However Eve deploys Foo with the address of Mal, so that calling Foo.callBar()
will actually execute the code at Mal.
*/

/*
1. Eve deploys Mal
2. Eve deploys Foo with the address of Mal
3. Alice calls Foo.callBar() after reading the code and judging that it is
   safe to call.
4. Although Alice expected Bar.log() to be execute, Mal.log() was executed.
*/

contract MAIN {
    A _a;

    constructor(address _v) {
        _a = A(_v);
    }

    function call() public {
        _a.log();
    }
}

contract A {
    event Log(string message);

    function log() public {
        emit Log("A was called");
    }
}


contract B {
    event Log(string message);

    function log() public {
        emit Log("B was called");
    }
}