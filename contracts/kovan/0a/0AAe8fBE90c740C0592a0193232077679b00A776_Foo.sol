pragma solidity ^0.8.7;

contract Bar {
    uint s;

    function bar(uint i) public returns (uint) {
        s = s + i;
        return s;
    }
}

contract Foo {
    uint s;
    Bar bar;

    constructor (address a) {
        bar = Bar(a);
    }

    function foo(uint c) public {
        for (uint i = 0; i < c; i++) {
            s = bar.bar(i);
        }

        if (s > 1) {
            s += 1;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}