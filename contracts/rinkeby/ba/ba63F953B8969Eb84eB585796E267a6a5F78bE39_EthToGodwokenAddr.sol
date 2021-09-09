/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.2;

contract EthToGodwokenAddr {
    function convert(address eth_addr) public returns (address) {
        uint256[1] memory input;
        input[0] = uint256(uint160(address(eth_addr)));
        uint256[1] memory output;
        assembly {
            if iszero(call(not(0), 0xf3, 0x0, input, 0x20, output, 0x20)) {
                revert(0x0, 0x0)
            }
        }
        return address(uint160(output[0]));
    }
}