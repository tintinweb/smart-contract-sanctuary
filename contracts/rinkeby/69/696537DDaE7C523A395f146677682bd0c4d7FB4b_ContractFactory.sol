// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev This contract enables creation of assets smart contract instances
 */
contract ContractFactory {

    /**
     * @dev Creates contract instance for whitelisted byteCode
     * @param bytecode contract bytecode
     * @param constructorParams encoded constructor params
     */
    function createContractInstance(bytes memory bytecode, bytes memory constructorParams, bytes32 salt) external returns (address) {
        bytes memory creationBytecode = abi.encodePacked(bytecode, constructorParams);

        address addr;
        assembly {
            addr := create2(0, add(creationBytecode, 0x20), mload(creationBytecode), salt)
        }

        require(isContract(addr), "Contract was not been deployed. Check contract bytecode and contract params");

        return addr;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}