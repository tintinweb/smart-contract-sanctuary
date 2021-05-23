/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

/*
You can use Play editor with any contract.
Paste it in the editor and wait for the preview to start interacting with it.

**To interact with the contract you will need a Metamask extension.
*/


pragma solidity 0.5.12;

contract SimpleStorage {

    uint8 storedData;

    function set(uint8 x) public {
        storedData = x;
    }

    function get() public view returns (uint8) {
        return storedData;
    }

}