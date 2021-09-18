/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract BIP3to6 {
    ERC20Like constant BPRO = ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61);

    function execute(address _from) external {
        BPRO.transferFrom(_from, 0xb03927FF2880C3f89f561d8d9c3f7EDF52A0bBB2, 200e21);
        BPRO.transferFrom(_from, 0x3328D5b2CabDF25a9AaD31Ae52f660398c54b6cE, 90e21);
        BPRO.transferFrom(_from, 0xC507A27860C225aaD8CB4a5A32a44d8892288880, 25e21);
        BPRO.transferFrom(_from, 0x9F69BE585d0E635a846df7db15Ad6f7741a9843A, 50e21);        
    }
}