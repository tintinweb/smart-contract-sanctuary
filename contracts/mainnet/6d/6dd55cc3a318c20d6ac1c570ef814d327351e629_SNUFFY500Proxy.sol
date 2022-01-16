// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*

            O
            _
     ---\ _|.|_ /---
      ---|  |  |---
         |_/ \_|
          |   |
          |   |
          |___|
           | |
           / \

       SNUFFY 500

*/

import "ICxipRegistry.sol";

// sha256(abi.encodePacked('eip1967.CxipRegistry.SNUFFY500Proxy')) == 0x173e062e35414a9e4a78473136b46649bf11b541b977af37c24fdf9b93fd2b26
contract SNUFFY500Proxy {
    fallback() external payable {
        // sha256(abi.encodePacked('eip1967.CxipRegistry.SNUFFY500')) == 0x760d8fd549489d03ac3713df7691c6343992aa824c4e75d3d990e8a5f46d8619
        address _target = ICxipRegistry(0xC267d41f81308D7773ecB3BDd863a902ACC01Ade).getCustomSource(0x760d8fd549489d03ac3713df7691c6343992aa824c4e75d3d990e8a5f46d8619);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}