// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/utils/Create2.sol";

contract Redeployer {
    event Redeployed(
        address indexed contract_,
        address indexed address_,
        bytes32 salt,
        uint256 amount,
        bytes prefix,
        bytes arguments
    );

    function generateBytecode(
        address contract_,
        bytes memory prefix,
        bytes memory arguments
    ) public view returns (bytes memory code) {
        require(arguments.length % 0x20 == 0, "Invalid arguments length");
        bytes memory bytecode;
        assembly {
            let prefixSize := mload(prefix)
            let bytecodeSize := extcodesize(contract_)
            let argumentsSize := mload(arguments)
            let totalSize := add(prefixSize, add(bytecodeSize, argumentsSize))
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(totalSize, 0x3f), not(0x1f))))
            mstore(bytecode, totalSize)
            extcodecopy(contract_, add(bytecode, add(prefixSize, 0x20)), 0, bytecodeSize)
            for {
                let i := 0
            } lt(i, argumentsSize) {
                i := add(i, 0x20)
            } {
                mstore(add(bytecode, add(0x20, add(i, bytecodeSize))), mload(add(arguments, add(0x20, i))))
            }
            for {
                let i := 0
            } lt(i, prefixSize) {
                i := add(i, 0x20)
            } {
                mstore(add(bytecode, add(0x20, i)), mload(add(prefix, add(0x20, i))))
            }
        }
        require(bytecode.length > arguments.length, "Not a contract");
        return bytecode;
    }

    function redeploy(
        address contract_,
        bytes32 salt,
        uint256 amount,
        bytes memory prefix,
        bytes memory arguments
    ) public returns (address result) {
        bytes memory bytecode = generateBytecode(contract_, prefix, arguments);
        result = Create2.deploy(amount, salt, bytecode);
        emit Redeployed(contract_, result, salt, amount, prefix, arguments);
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

