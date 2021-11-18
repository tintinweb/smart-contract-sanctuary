/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Mintable {
    function mint(uint _amount) external returns (bool);
    function transfer(address _to, uint _amount) external returns (bool);
}

contract TestNetMint {
    constructor() {}

    function mint() public {
        Mintable(0x51BC2DfB9D12d9dB50C855A5330fBA0faF761D15).mint(10000e18); // DAI
        Mintable(0x02823f9B469960Bb3b1de0B3746D4b95B7E35543).mint(10000e6); // USDT
        Mintable(0x02823f9B469960Bb3b1de0B3746D4b95B7E35543).mint(10000e6); // USDC
        Mintable(0x9668f5f55f2712Dd2dfa316256609b516292D554).mint(3e18); // ETH
        Mintable(0x9C1DCacB57ADa1E9e2D3a8280B7cfC7EB936186F).mint(1e8); // BTC

        Mintable(0x51BC2DfB9D12d9dB50C855A5330fBA0faF761D15).transfer(msg.sender, 10000e18); // DAI
        Mintable(0x02823f9B469960Bb3b1de0B3746D4b95B7E35543).transfer(msg.sender, 10000e6); // USDT
        Mintable(0x02823f9B469960Bb3b1de0B3746D4b95B7E35543).transfer(msg.sender, 10000e6); // USDC
        Mintable(0x9668f5f55f2712Dd2dfa316256609b516292D554).transfer(msg.sender, 3e18); // ETH
        Mintable(0x9C1DCacB57ADa1E9e2D3a8280B7cfC7EB936186F).transfer(msg.sender, 1e8); // BTC
        Mintable(0x65881118D84006E0a7c5AAd9498C3949a2019e8E).transfer(msg.sender, 100e18); // PiToken
    }
}