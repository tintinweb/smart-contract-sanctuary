/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Oracle {
    uint public rand; 
    address admin; 
    
    
    constructor() public {
        admin = msg.sender;  
    }
    
    function feedRandomness(uint _rand) external {
        require(msg.sender == admin);
        rand = _rand; 
    }
}

contract RandomNumber {
    Oracle oracle; 
    uint nonce;
    event LogData(uint amount);

    constructor(address oracleAddress) public {
        oracle = Oracle(oracleAddress);
    }
    
    function randModulus(uint mod) public returns(uint) {
        uint rand = _randModulus(mod);
        return rand; 
    }
    
    function _randModulus(uint mod) public returns(uint) {
        uint rand =  uint(keccak256(abi.encodePacked(nonce, oracle.rand() ,now, block.difficulty, msg.sender))) % mod;
        nonce++; 
         emit LogData(rand + 1);
        return rand + 1; 
    }
}