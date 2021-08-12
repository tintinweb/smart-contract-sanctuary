/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;



// Part: IOwnable

interface IOwnable {
  function acceptOwnership() external;
}

// File: TimelockProposal.sol

contract TimelockProposal {

  function execute() external {

    // FeeConverter
    IOwnable(0x59C88e46a0Cc337cee7Ce9c453e5E518f944cA05).acceptOwnership();

    // FeeRecipient
    IOwnable(0x487502F921BA3DADAcF63dBF7a57a978C241B72C).acceptOwnership();

    // MasterPool
    IOwnable(0x3220269e3CfA62270F4d0e5c4245D7b6a0079777).acceptOwnership();

    // RewardDistribution
    IOwnable(0x0fD91A3F5F3D79AfC95bf756Fea351b1F51A668c).acceptOwnership();

    // Controller
    IOwnable(0x45ee906E9CFAE0aabDB194D6180A3A119D4376C4).acceptOwnership();

    // InterestRateModel
    IOwnable(0x1FfD9e1c038773d1C61dFeB0CDb5aFd2D8F28C97).acceptOwnership();

    // UniswapV3Oracle
    IOwnable(0x3D619bc03014917d3B27B3B86452346af36e58de).acceptOwnership();
  }
}