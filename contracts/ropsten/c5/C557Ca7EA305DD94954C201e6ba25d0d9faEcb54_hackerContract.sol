pragma solidity ^0.4.21;

import './fiTest.sol';

contract hackerContract is IName {
    event info(address indexed _addr, bytes20 indexed _b20, bytes20 indexed _b201);
    event info1(bytes20 indexed _b20, uint256 indexed _i);

    fiChallenge ficContract = fiChallenge(0xC819dB73ef397F731Cf32e4FE37F8a15023EB746);
    
    function name() external view returns (bytes32) {
        return bytes32("smarx");
    }
    
    function tryAuthenticate1() public {
        ficContract.authenticate1();
    }
    
    function tryAuthenticate2() public {
        ficContract.authenticate2();
    }
    
    function showSender() public view returns (address) {
        return ficContract.msgSender();
    }
    
    function isBadCode1(address _addr) public pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }
    
    function isBadCode2(address _addr) public {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            emit info(address(addr & mask), bytes20(addr & mask), id);
            if (addr & mask == id) {
                emit info1(addr & mask, i);
            }
            mask <<= 4;
            id <<= 4;
        }
    }
    
}