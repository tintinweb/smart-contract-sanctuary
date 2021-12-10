// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface RegERC {
    function mint(address to, uint256 amount) external;
}

contract ClaimTokens {

    uint public FIXED_AMOUNT = 9000000000000000000;

    constructor(){

    }

    function claim() public {
        // V3
        address tokenAddress = 0x84e7122440CB41935749a926be1DC96E2C4A5AA2;
        RegERC(tokenAddress).mint(msg.sender, FIXED_AMOUNT);
    }

    function getRole() public pure returns (bytes32){
        return keccak256("MINTER_ROLE");
    }

}