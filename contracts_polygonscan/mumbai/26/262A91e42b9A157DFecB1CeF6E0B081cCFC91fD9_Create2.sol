/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: contracts/Factory.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.7.0;

/**
 * Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
contract Create2 {
    /**
     * Deploys a contract using `CREATE2`. The address where the contract
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
    event Payment(address indexed _from, uint _value);
    event Deployed(address addr, uint256 salt);

    fallback () external payable { 
        emit Payment(msg.sender, msg.value);
    }

    function balanceOf() external view returns(uint256) {
        return address(this).balance;
    }

    function deployContract(uint256 salt,bytes memory bytecode) public returns (address) {
        address addr;
        require(bytecode.length != 0, "Create2: bytecode length is zero");

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     * This function is helper function to derive the address of the 
     */
    function computeAddress(uint256 salt, bytes32 bytecodeHash) public view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     * It computes using the four parameter , first one is constant 0xff , address of the deployer (mostly the contract address of the contract from which it is called),
     * salt(It is a random integer value which actually differs the contract address) , Bytecode of the contract to be deployed
     */
    function computeAddress( uint256 salt, bytes32 bytecodeHash, address deployer) public pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}