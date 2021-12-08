pragma solidity ^0.5.15;

library TestLibrary {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }

    function libID() pure external returns (string memory) {
        return "0x71bAC73c889116942a5A50A31CAe4400820D3455";
    }
}