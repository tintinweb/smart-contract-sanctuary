//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

contract OneOfXOwners {
    address payable address1;
    address payable address2;

    constructor(address payable addr1, address payable addr2) {
        address1 = addr1;
        address2 = addr2;
    }

    receive() external payable {
        address2.transfer(msg.value / 2);
        address1.transfer(address(this).balance);
    }
}