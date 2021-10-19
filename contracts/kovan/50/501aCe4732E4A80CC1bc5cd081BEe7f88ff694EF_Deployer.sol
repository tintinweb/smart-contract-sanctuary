// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from EIP-2470
// https://etherscan.io/address/0xce0042B868300000d44A59004Da54A005ffdcf9f#code
pragma solidity 0.8.6;

import "./interface/IDeployer.sol";


/**
 * @title Deployer
 * @notice Exposes `CREATE2` (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author solace.fi
 */
contract Deployer is IDeployer {

    /**
     * @notice Deploys `initcode` using `salt` for defining the deterministic address.
     * @param initcode Initialization code.
     * @param salt Arbitrary value to modify resulting address.
     * @return createdContract Created contract address.
     */
    function deploy(bytes memory initcode, bytes32 salt) external override returns (address payable createdContract) {
        return _deploy(initcode, salt);
    }

    /**
     * @notice Deploys `initcodes` using `salts` for defining the deterministic address.
     * @param initcodes Initialization codes.
     * @param salts Arbitrary values to modify resulting addresses.
     * @return createdContracts Created contract addresses.
     */
    function deployMultiple(bytes[] memory initcodes, bytes32[] memory salts) external override returns (address payable[] memory createdContracts) {
        uint256 length = initcodes.length;
        require(length == salts.length, "length mismatch");
        createdContracts = new address payable[](length);
        for(uint256 i = 0; i < length; i++) {
            createdContracts[i] = _deploy(initcodes[i], salts[i]);
        }
        return createdContracts;
    }

    /**
     * @notice Deploys `initcode` using `salt` for defining the deterministic address.
     * @param initcode Initialization code.
     * @param salt Arbitrary value to modify resulting address.
     * @return createdContract Created contract address.
     */
    function _deploy(bytes memory initcode, bytes32 salt) internal returns (address payable createdContract) {
        assembly {
            createdContract := create2(0, add(initcode, 0x20), mload(initcode), salt)
        }
        require(createdContract != address(0x0), "invalid initcode");
        emit ContractDeployed(createdContract);
        return createdContract;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from EIP-2470
// https://etherscan.io/address/0xce0042B868300000d44A59004Da54A005ffdcf9f#code
pragma solidity 0.8.6;

/**
 * @title IDeployer
 * @notice Exposes `CREATE2` (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author solace.fi
 */
interface IDeployer {

    /// @notice Emitted when a contract is deployed.
    event ContractDeployed(address createdContract);

    /**
     * @notice Deploys `initcode` using `salt` for defining the deterministic address.
     * @param initcode Initialization code.
     * @param salt Arbitrary value to modify resulting address.
     * @return createdContract Created contract address.
     */
    function deploy(bytes memory initcode, bytes32 salt) external returns (address payable createdContract);

    /**
     * @notice Deploys multiple contracts.
     * @param initcodes Initialization codes.
     * @param salts Arbitrary values to modify resulting addresses.
     * @return createdContracts Created contract addresses.
     */
    function deployMultiple(bytes[] memory initcodes, bytes32[] memory salts) external returns (address payable[] memory createdContracts);
}