/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract MintyProxy {
    uint256[9] private _other;
    string private _baseURI = "ipfs://";

    // An existing deployment of [Minty](https://github.com/yusefnapora/minty)
    address private constant IMPL = 0x712185A269f2DDe32936AEfa2eED8BDDdB72541e;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L21-L26
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    constructor() {
        // To advertise that this contract is a proxy
        assembly {
            sstore(_IMPLEMENTATION_SLOT, IMPL)
        }
    }

    // Delegates the current call to IMPL
    // This function does not return to its internall call site, it will return directly to the external caller.
    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/proxy/Proxy.sol
    function _delegate() private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), IMPL, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Delegate mintToken to IMPL, but only if token is being minted to caller.
    function mintToken(address owner, string calldata metadataURI) external returns (uint256) {
        require(owner == msg.sender, "Can only mint to self");
        _delegate();
    }    

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Handle supportsInterface in this contract without delegation,
    // so that it can work without requiring interfaceId values to be in contract storage.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
            || interfaceId == _INTERFACE_ID_ERC721
            || interfaceId == _INTERFACE_ID_ERC721_METADATA
            || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE;
    }
    
    // Delegate all other calls to IMPL
    fallback() external {
        _delegate();
    }
}