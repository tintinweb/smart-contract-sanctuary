/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// Ł.club LCL LGE Contract
// Fixed Supply Immutable Liquidity Generation Event Contract
//
// Copyright (C) 2021 Ł.club
//
// Telegram: t.me/LCLclub
//
// Internet: Ł.club
//           LCL.eth.link

// SPDX-License-Identifier: GPL3

pragma solidity ^0.8.8;

interface LCL {
    function balanceOf(address usr) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

contract LGE {
    LCL public lcl;

    address public         lclToken  = 0x6C648aDE3354161B29B8a8eFB50B9D802edA55AF;
    address public         lclFaucet = 0xe9aba52b7Fc54c28942A8D55024fF20C8660255F;
    address payable public lclSink;

    uint public            start;
    uint public            end;

    event   Deposit(address indexed dst, uint wad);

    constructor() {
        lcl = LCL(lclToken);
        lclSink = payable(lclFaucet);

        start = 1636665671; // Thu Nov 11 2021 21:21:11 GMT+0000
        end = start + 6 days;
    }

    function restart() public {
        require(msg.sender == lclFaucet);

        start = block.timestamp;
        end = start + 6 days;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        require(block.timestamp >= start && block.timestamp < end);

        uint prx = 21000000000000;
        uint wad = msg.value;

        require(wad >= prx);
        
        uint base = 10 ** 18;
        uint val = wad * base / prx;

        (bool success, bytes memory data) = lclSink.call{value: wad}("");

        require(success);
        lcl.transferFrom(lclFaucet, msg.sender, val);

        emit Deposit(msg.sender, msg.value);
    }
}