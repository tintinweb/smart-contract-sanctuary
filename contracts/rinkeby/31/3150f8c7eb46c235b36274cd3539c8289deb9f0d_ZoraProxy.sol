/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

contract ZoraProxy {
    address immutable public zoraMedia;
    address immutable public safeAddress;
    address immutable public zoraMarket;

    mapping(uint256 => address) public tokenCreators;

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

    // add onlyOwner modifier
    function setTokenCreator(uint256 tokenId) external returns (bool) {
        tokenCreators[tokenId] = safeAddress;
        return true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public returns (bool) {
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return true;
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