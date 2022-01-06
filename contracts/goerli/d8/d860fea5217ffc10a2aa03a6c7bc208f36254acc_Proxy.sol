//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Proxy {
    address owner;
    address implementation;

    constructor(address _implementation) {
        implementation = _implementation;
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(success);
    }

    function changeImplementation(address _implementation) external {
        require(msg.sender == owner);
        implementation = _implementation;
    }

    fallback() external {
        address _impl = implementation;
        // this is standard OpenZeppelin proxy assembly code: 
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol#L23-L44
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

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