// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/utils/Create2.sol";

contract Redeployer {
    event Redeployed(
        address indexed contract_,
        address indexed address_,
        bytes32 salt,
        uint256 amount,
        bytes argumentsOverride
    );

    event Test(bytes bytecode);

    function redeploy(
        address contract_,
        bytes32 salt,
        uint256 amount,
        bytes memory argumentsOverride
    ) public returns (address result) {
        require(argumentsOverride.length % 0x20 == 0, "Invalid arguments overriding format");
        bytes memory bytecode;
        assembly {
            let size := extcodesize(contract_)
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(bytecode, size)
            extcodecopy(contract_, add(bytecode, 0x20), 0, size)
        }
        require(bytecode.length > 0, "Not a contract");
        require(bytecode.length >= argumentsOverride.length, "Invalid arguments overriding length");
        uint256 words = argumentsOverride.length / 0x20;
        for (uint256 wordIndex = 0; wordIndex < words; wordIndex++) {
            assembly {
                let argOffset := add(add(argumentsOverride, 0x20), mul(0x20, wordIndex))
                mstore(add(add(bytecode, 0x20), mul(0x20, wordIndex)), mload(argOffset))
            }
        }
        result = Create2.deploy(amount, salt, bytecode);
        emit Redeployed(contract_, result, salt, amount, argumentsOverride);
        emit Test(bytecode);
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

