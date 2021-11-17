// SPDX-License-Identifier: MIT
// Further information: https://eips.ethereum.org/EIPS/eip-1014

pragma solidity ^0.8.4;

import "./Create2.sol";
import "./ERC1820Implementer.sol";
import "./Ownable.sol";
import "./Pausable.sol";


/**
 * @title CREATE2 Deployer Smart Contract
 * @author Pascal Marco Caversaccio, [email protected]
 * @dev Helper smart contract to make easier and safer usage of the 
 * `CREATE2` EVM opcode. `CREATE2` can be used to compute in advance
 * the address where a smart contract will be deployed, which allows
 * for interesting new mechanisms known as 'counterfactual interactions'.
 */

contract Create2Deployer is Ownable, Pausable {

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the 
     * contract will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `value`.
     * - if `value` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy (
        uint256 value,
        bytes32 salt,
        bytes memory code
    ) public whenNotPaused {
        Create2.deploy(value, salt, code);
    }

    /**
     * @dev Deployment of the {ERC1820Implementer}.
     * Further information: https://eips.ethereum.org/EIPS/eip-1820
     */
    function deployERC1820Implementer(uint256 value, bytes32 salt) public whenNotPaused {
        Create2.deploy(value, salt, type(ERC1820Implementer).creationCode);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. 
     * Any change in the `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a 
     * contract located at `deployer`. If `deployer` is this contract's address, returns the
     * same value as {computeAddress}.
     */
    function computeAddressWithDeployer(
        bytes32 salt,
        bytes32 codeHash,
        address deployer
    ) public pure returns (address) {
        return Create2.computeAddress(salt, codeHash, deployer);
    }

    /**
    * @dev Contract can receive ether. However, the only way to transfer this ether is 
    * to call the function `killCreate2Deployer`.
    */
    receive() external payable {}

    /**
     * @dev Triggers stopped state.
     * Requirements: The contract must not be paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Requirements: The contract must be paused.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Destroys the Create2Deployer contract and transfers all ether to a pre-defined payout address.
     * @notice Using the `CREATE2` EVM opcode always allows to redeploy a new smart contract to a  
     * previously seldestructed contract address. However, if a contract creation is attempted, 
     * due to either a creation transaction or the `CREATE`/`CREATE2` EVM opcode, and the destination 
     * address already has either nonzero nonce, or non-empty code, then the creation throws immediately, 
     * with exactly the same behavior as would arise if the first byte in the init code were an invalid opcode. 
     * This applies retroactively starting from genesis.
     */
    function killCreate2Deployer(address payable payoutAddress) public onlyOwner {
        payoutAddress.transfer(address(this).balance);
        selfdestruct(payoutAddress);
    }
}