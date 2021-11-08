//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleStorageUpgrade {
    uint storedData;

    event Change(string message, uint newVal);

    function set(uint x) public {
        require(x<5000, "Sould be less than 5000");
        storedData = x;
        emit Change("set", x);
    }
    function get() public view returns (uint) {
        return storedData;
    }
}