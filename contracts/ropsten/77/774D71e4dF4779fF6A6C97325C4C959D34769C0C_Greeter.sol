/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Greeter {
    uint256  private moniPerBitch;

    constructor(uint256  _moniPerBitch) {
        moniPerBitch = _moniPerBitch;
    }

    function gimmiMoniBeatch() public {
        address payable sendTo = payable(msg.sender);

        sendTo.transfer(moniPerBitch);
    }

    receive() external payable {}
}