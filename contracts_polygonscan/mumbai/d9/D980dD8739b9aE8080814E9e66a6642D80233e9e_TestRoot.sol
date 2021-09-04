/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEggCarton {
    function test(bytes memory message) external;
}

contract TestRoot {
    bytes32 public constant MAKE_EGG = keccak256("MAKE_EGG");
    bytes32 public constant FIND_TRAITS = keccak256("FIND_TRAITS");
    IEggCarton eggCarton;

    constructor(address carton){
        eggCarton = IEggCarton(carton);
    }

    function makeEgg(address recevier, uint babyID, uint mom, uint dad) external {
        bytes memory message = abi.encode(MAKE_EGG, abi.encode(recevier, babyID, mom, dad));
        eggCarton.test(message);
    }

    function findTraits(address caller, uint babyID, uint mom, uint dad) external {
        bytes memory message = abi.encode(FIND_TRAITS, abi.encode(caller, babyID, mom, dad));
        eggCarton.test(message);
    }
}