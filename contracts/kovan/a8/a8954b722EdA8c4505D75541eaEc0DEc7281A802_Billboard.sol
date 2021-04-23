/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
//import "hardhat/console.sol";

contract Billboard {

    address public admin;

    constructor() {
        admin = msg.sender;
        slotPrices[1] = 1e18;
        slotPrices[2] = 2e18;
        slotPrices[3] = 3e18;
    }

    mapping (uint256 => string) public billboard;
    mapping (uint256 => uint256) public slotPrices;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    function pay(uint256 slotNumber, string memory message) payable external {
      //console.log("msg.value:", msg.value, slotPrices[slotNumber]);
      //console.log("msg.sender", msg.sender);
      require(slotPrices[slotNumber] <= msg.value, "not enough payment");
      //payable(address(msg.sender)).transfer(slotPrices[slotNumber]);
      billboard[slotNumber] = message;

    }

    // fallback() external payable{
    //     console.log("no function matched");
    //     revert("no function matched");
    // }
    receive() external payable {
        //called when the call data is empty
        if (msg.value > 0) {
            revert();
        }
    }
}
/**
 * MIT License
 * ===========
 *
 * Copyright (c) 2020, 2021 Aries Financial
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */