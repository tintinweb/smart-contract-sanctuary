pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/utils/Create2.sol";

contract FerrumDeployer {
    uint256 constant EXTERNAL_HASH = 0x0ddafcd8600839ce553cacb17e362c83ea42ccfd1e8c8b3cb4d075124196dfc0;
    uint256 constant INTERNAL_HASH = 0x27fd0863a54f729686099446389b11108e6e34e7364d1f8e38a43e1661a07f3a;
    event Deployed(address);
    function deploy(bytes32 salt, bytes calldata bytecode)
    external returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, INTERNAL_HASH, msg.sender)
        );
        address deployed = Create2.deploy(0, _data, bytecode);
        emit Deployed(deployed);
        return deployed;
    }

    /**
     * @dev Use this method if you want to incorporate the sender address in the contract address.
     */
    function deployFromContract(bytes32 salt, address deployer, bytes calldata bytecode)
    external returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, EXTERNAL_HASH, deployer)
        );
        address deployed = Create2.deploy(0, _data, bytecode);
        emit Deployed(deployed);
        return deployed;
    }

    function computeAddressFromContract(bytes32 salt, bytes32 bytecodeHash, address deployer)
    external pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, EXTERNAL_HASH, deployer)
        );
        return Create2.computeAddress(_data, bytecodeHash, deployer);
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
    external view returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, INTERNAL_HASH, deployer)
        );
        return Create2.computeAddress(_data, bytecodeHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return address(uint256(_data));
    }
}