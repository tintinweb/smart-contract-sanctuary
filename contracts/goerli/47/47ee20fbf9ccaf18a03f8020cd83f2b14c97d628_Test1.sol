pragma solidity ^0.8.0;

import "./console.sol";



contract Test1 {

    constructor() {
        console.log("test1 constructor", address(this));
    }

    function foo() public {
        console.log("foo");
    }

    function destroy() public {
        console.log("test1 destroy");
        selfdestruct(payable(0));
    }
}