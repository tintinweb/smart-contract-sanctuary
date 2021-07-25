/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity 0.8.6;

contract MintyProxy {
    uint256[1] private _supportedInterfaces;
    uint256[1] private _holderTokens;
    uint256[2] private _tokenOwners;
    uint256[1] private _tokenApprovals;
    uint256[1] private _operatorApprovals;
    uint256[1] private _name;
    uint256[1] private _symbol;
    uint256[1] private _tokenURIs;
    string private _baseURI = "ipfs://";
    uint256[1] private _tokenIds;
    
    address private constant IMPL = 0x4F29Cc056D5363261C1FA81234768E87E98dd5F4;

    constructor() {
        assembly {
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, IMPL)
        }
    }

    /// @dev From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/proxy/Proxy.sol
    fallback() external {
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
    
}