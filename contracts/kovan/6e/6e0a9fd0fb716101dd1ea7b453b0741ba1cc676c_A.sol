/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

/*
範例繼承圖
   A
 /  \
B   C
 \ /
  D
*/

contract A {

    event Log(string message);

    function foo() public virtual {
        emit Log("A.foo called");
    }

    function bar() public virtual {
        emit Log("A.bar called");
    }
}

// 繼承 A, 並覆寫 foo() 及 bar()
contract B is A {
    function foo() public virtual override {
        emit Log("B.foo called");
        // 直接調用父合約方法
        A.foo();
    }

    function bar() public virtual override {
        emit Log("B.bar called");
        // 使用 super 關鍵字調用
        super.bar();
    }
}

contract C is A {
    function foo() public virtual override {
        emit Log("C.foo called");
        A.foo();
    }

    function bar() public virtual override {
        emit Log("C.bar called");
        super.bar();
    }
}

// 多重繼承
// 1. 呼叫 D.foo(), 並檢視交易日誌,
//    會發現雖然 D 繼承自 A、B、C, 但它其實只呼叫了 C 和 A
// 2. 呼叫 D.bar(), 並檢視交易日誌,
//    會發現 D 呼叫 C 然後 B 最後是 A, 雖然 super 方法被呼叫了兩次 (B and C)
//    但其實它只呼叫 A 一次
contract D is B, C {
    // Try:
    // - Call D.foo and check the transaction logs.
    //   Although D inherits A, B and C, it only called C and then A.
    // - Call D.bar and check the transaction logs
    //   D called C, then B, and finally A.
    //   Although super was called twice (by B and C) it only called A once.

    function foo() public override(B, C) {
        super.foo();
    }

    function bar() public override(B, C) {
        super.bar();
    }
}