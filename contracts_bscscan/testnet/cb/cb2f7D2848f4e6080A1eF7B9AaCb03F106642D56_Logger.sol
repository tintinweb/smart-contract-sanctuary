//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Logger {

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    constructor() {}

    function emitLog() public {
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(this);
        tokenAddresses[1] = address(this);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        emit LogEvent(
            address(this), 
            msg.sender, 
            "ActionDeposit", 
            abi.encode(address(this), tokenAddresses, amounts, tokenAddresses, amounts, block.number));
    }

}

