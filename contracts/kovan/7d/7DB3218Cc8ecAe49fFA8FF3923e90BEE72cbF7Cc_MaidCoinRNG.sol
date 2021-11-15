// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/IRNG.sol";

contract MockRNGCaller {
    IRNG public rng;
    uint256 public lastNumber;

    constructor(IRNG _rng) {
        rng = _rng;
    }

    function test(uint256 seed) external {
        lastNumber = rng.generateRandomNumber(seed, msg.sender);
    }
}

contract MaidCoinRNG is IRNG {
    bytes private a;
    uint256 private nonce = 0;
    
    constructor() {
        a = type(MockRNGCaller).runtimeCode;
    }

    function generateRandomNumber(uint256 seed, address sender) external override returns (uint256) {
        nonce += 1;

        uint256 temp = uint256(keccak256(abi.encodePacked(seed,tx.origin,a,block.timestamp,gasleft()))) % 6;
        if(temp == 1) return r1(address(this), sender, seed, true);
        if(temp == 2) return r2(msg.sender, sender, seed, false);
        if(temp == 3) return r3(tx.origin, sender, seed, true);
        if(temp == 4) return r4(block.coinbase, sender, seed, false);
        if(temp == 5) return r5(tx.origin, sender, seed, true);
        if(temp == 0) return r6(msg.sender, sender, seed, false);
    }

    function fakeGenerateRandomNumber(uint256 seed, address sender) external returns (uint256) {
        nonce += 1;

        uint256 temp = uint256(keccak256(abi.encodePacked(a,seed,blockhash(seed + 4321),nonce,block.timestamp,gasleft()))) % 6;
        if(temp == 1) return r3(sender, address(this), seed, false);
        if(temp == 2) return r6(sender, address(this), seed, true);
        if(temp == 3) return r5(sender, block.coinbase, seed, true);
        if(temp == 4) return r2(sender, address(this), seed, false);
        if(temp == 5) return r4(sender, block.coinbase, seed, true);
        if(temp == 0) return r1(sender, msg.sender, seed, false);
    }

    function r1(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,nonce,a,block.timestamp,sender,seed,z)));
    }
    
    function r2(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,nonce,a,sender,seed,z,block.difficulty)));
    }
    
    function r3(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,blockhash(block.number - 21),nonce,a,sender,seed,z)));
    }
    
    function r4(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,nonce,a,seed,z,gasleft(),sender)));
    }
    
    function r5(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,a,sender,seed,z,block.difficulty,nonce,block.timestamp)));
    }
    
    function r6(address z, address sender, uint256 seed, bool v) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(v,block.timestamp,a,gasleft(),sender,nonce,seed,z)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRNG {
    function generateRandomNumber(uint256 seed, address sender) external returns (uint256);
}

