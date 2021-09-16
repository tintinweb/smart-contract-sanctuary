/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract AAA {
    event Log(string name);

    function foo() public virtual {
        emit Log("A.foo is called");
    }

    function bar() public virtual {
        emit Log("A.bar is called");
    }
}
contract BBB is AAA {
    function foo() public virtual override {
        emit Log("B.foo is called");
        AAA.foo();
    }

    function bar() public virtual override {
        emit Log("B.bar called");
        super.bar();
    }
}

contract CCC is AAA {
    function foo() public virtual override {
        emit Log("C.foo called");
        AAA.foo();
    }

    function bar() public virtual override {
        emit Log("C.bar is called");
        super.bar();
    }
}

contract DDD is BBB, CCC {
    // Try:
    // - Call D.foo and check the transaction logs.
    //   Although D inherits A, B and C, it only called C and then A.
    // - Call D.bar and check the transaction logs
    //   D called C, then B, and finally A.
    //   Although super was called twice (by B and C) it only called A once.

    function foo() public override(BBB, CCC) {
        super.foo();
    }

    function bar() public override(BBB, CCC) {
        super.bar();
    }
}