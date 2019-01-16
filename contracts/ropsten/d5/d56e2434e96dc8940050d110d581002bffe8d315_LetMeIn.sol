pragma solidity ^0.4.19;

contract LetMeIn {
        
    function enter() public{
        
        bytes8 _gateKey;
        uint64 _n;
        
        bytes32 _passcode = "porter concept emergency develop";  
        _n = uint64(keccak256(_passcode, address(this))) ^ uint64(0) - 1;
        _gateKey = bytes8(_n);
        0x7f6E31b58E96Af9204aCc71dA3fF6c576D69e9A1.delegatecall("bytes32 _passcode", _passcode, "bytes8 _gateKey", _gateKey);
        
    }
}