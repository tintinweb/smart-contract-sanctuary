/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

//"SPDX-License-Identifier: UNLICENCED"
pragma solidity ^0.8.4;
contract MeebitIDer{}

contract Deployer {
  function deploy(bytes32 salt) public pure {
      new MeebitIDer{salt: salt};
  }
}