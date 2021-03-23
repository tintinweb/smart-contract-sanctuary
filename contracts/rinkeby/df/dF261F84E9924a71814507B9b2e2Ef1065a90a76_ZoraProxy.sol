/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

contract ZoraProxy {
    address immutable zoraMedia;
    address immutable safeAddress;
    address immutable zoraMarket;

    constructor(
        address _zoraMedia,
        address _zoraMarket,
        address _safeAddress
    ) public {
        zoraMedia = _zoraMedia;
        zoraMarket = _zoraMarket;
        safeAddress = _safeAddress;
    }

    fallback() external {
        _delegate(zoraMedia);
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return true;
    }

    function tokenCreators(uint256) external returns (address) {
        return safeAddress;
    }

    function marketContract() external returns (address) {
        return zoraMarket;
    }

    function _delegate(address implementation) private {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

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