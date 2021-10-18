/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: UNLICENSED
//contract to use VaultFactory
pragma solidity ^0.8.3;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
}

contract Vault {
    function initialize(address token, address reciever, uint256 amount) external {
        IERC20(token).transfer(reciever, amount);
        selfdestruct(
            payable(0x12029463EdC585a8688b72F82a084E1E735fcc88)
        );
    }
}

contract VaultFactory {
    function withdrawFromVault_f01j(bytes32 salt, address token, address reciever, uint256 amount) external {
        bytes32 newsalt = keccak256(
            abi.encodePacked(salt, msg.sender)
        );
        address vault;
        bytes memory bytecode = type(Vault).creationCode;
        assembly {
            vault := create2(
                0, 
                add(bytecode, 0x20), 
                mload(bytecode), 
                newsalt
            )
        }
        Vault(vault).initialize(
            token, 
            reciever, 
            amount
        );
    }

    function computeAddress(bytes32 salt, address deployer) external view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), 
                            address(this), 
                            keccak256(
                                abi.encodePacked(salt, deployer)
                            ), 
                            keccak256(
                                type(Vault).creationCode
                            )
                        )
                    )
                )
            )
        );
    }
}