/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity 0.8.6;

contract MintyProxy {
    address private constant IMPL = 0x4F29Cc056D5363261C1FA81234768E87E98dd5F4;

    constructor() {
        assembly {
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, IMPL)
        }
    }

    /// @dev From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/proxy/Proxy.sol
    fallback() external payable {
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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x780e9d63;
    }
    
}