pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

contract LogicV2 {
    bool initialized;
    uint256 magicNumber;

    function initialize() public {
        require(!initialized, "already initialized");

        magicNumber = 0x42;
        initialized = true;
    }

    function setMagicNumber(uint256 newMagicNumber) public {
        magicNumber = newMagicNumber;
    }

    function getMagicNumber() public view returns (uint256) {
        return magicNumber;
    }

    function doMagic() public {
        magicNumber = magicNumber / 2;
    }
}