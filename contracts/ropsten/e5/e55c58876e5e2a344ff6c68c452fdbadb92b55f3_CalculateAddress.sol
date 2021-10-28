/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract CalculateAddress {
    uint256 private MAX_ITERATIONS = 10_000;
    bytes32 private constant CODE_HASH = 0xd18dde6df339495e9c9d9af27c41786a1f6ccc318f7bb1520d82994d0db89a76;
    
    function calculate(uint256 saltStart, address deployer) public view returns (address) {
        for (uint256 i = saltStart; i < MAX_ITERATIONS; i++) {
            address guess = computeAddress(saltStart, deployer);
            if (isBadCode(guess)){
                return guess;
            }
        }
        
        return address(0);
    }
    
    function computeAddress(uint256 salt, address deployer) internal pure returns (address) {
        return address(
            uint160(uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        deployer,
                        keccak256(abi.encode(salt)),
                        CODE_HASH
                    )
                )
            )
        ));
    }
    
    function isBadCode(address _addr) public pure returns (bool) {
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
}