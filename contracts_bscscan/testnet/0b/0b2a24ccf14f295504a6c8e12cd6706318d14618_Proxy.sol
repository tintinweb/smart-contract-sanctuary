/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Proxy {
    // Modifiers

    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(), "Not proxy owner");
        _;
    }

    // Public Calls

    function proxyOwner() public pure returns (address owner) {
        return(0x067F4523f9D623CCbad3EE7d5DfEFe138894B4a5); // This will be hardcoded and set to the Proxy Admin address
    }

    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(0x2b1ffc369630770908ae8b04282e29044dfb19c5b4378f67d00e0a2ef5f153e2) // 0x2b1ffc369630770908ae8b04282e29044dfb19c5b4378f67d00e0a2ef5f153e2 is some random storage key that will store implementation address
        }
    }

    // Public Transacts

    function changeImplementation(address _implementation)
        public onlyProxyOwner
    {
        _changeImplementation(_implementation);
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable {
        _fallback();
    }

    // Private Transacts

    function _setImplementation(address _newImplementation)
        internal
    {
        assembly {
            sstore(0x2b1ffc369630770908ae8b04282e29044dfb19c5b4378f67d00e0a2ef5f153e2, _newImplementation)
        }
    }

    function _changeImplementation(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    function _delegate() internal {
        assembly {
            let contractLogic := sload(0x2b1ffc369630770908ae8b04282e29044dfb19c5b4378f67d00e0a2ef5f153e2) // 0x2b1ffc369630770908ae8b04282e29044dfb19c5b4378f67d00e0a2ef5f153e2 is some random storage key that will store implementation address

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), contractLogic, 0, calldatasize(), 0, 0)

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

    function _fallback() internal {
        _delegate();
    }
}