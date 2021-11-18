/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

pragma solidity 0.5.11; // optimization runs: 65536, version: petersburg


/**
 * @title IndestructibleRegistry
 * @author 0age + flex
 * @notice This contract determines if other contracts are incapable of being
 * destroyed by confirming that they do not contain any SELFDESTRUCT, CALLCODE,
 * or DELEGATECALL opcodes. Just because a contract is determined to potentially
 * be destructible does not necessarily mean that it IS destructible - in other
 * words, the check performed by this contract is contract is quite strict.
 * To register a contract as indestructible in the registry, provide the target
 * contract address to the `registerAsIndestructible` function - it will throw
 * if the contract is potentially destructible. Then, anyone can call the
 * `isRegisteredAsIndestructible` view function to confirm that the contract has
 * been successfully registered as an indestructible contract. You can also call
 * the `isPotentiallyDestructible` view function to perform the destructibility
 * check without actually registering the contract. Note that this registry will
 * likely still apply through the Istanbul hardfork, but future forks may
 * introduce new opcodes or other methods by which contracts can be destroyed;
 * in that case, this registry can no longer be relied on as a safeguard against
 * destructibility.
 */
contract IndestructibleRegistry {
  // Maintain mapping of contracts that have been registered as indestructible.
  mapping (address => bool) private _definitelyIndestructible;

  /**
   * @notice Register a target contract as indestructible. The attempt will
   * revert if no code exists at the supplied target or if the target contract
   * is potentially destructible (i.e. the code has reachable opcodes that could
   * result in the contract being destroyed).
   * @param target address The contract to check and register as indestructible.
   */
  function registerAsIndestructible(address target) external {
    // Ensure that the target contract is not potentially destructible.
    require(
      !_isPotentiallyDestructible(target),
      "Supplied target is potentially destructible."
    );

    // Register the target as definitely indestructible (barring new opcodes).
    _definitelyIndestructible[target] = true;
  }

  /**
   * @notice View function to determine if a target contract has been registered
   * as indestructible.
   * @param target address The contract to check for potential registration as
   * an indestructible contract.
   * @return A boolean signifying successful registration as an indestructable
   * contract.
   */
  function isRegisteredAsIndestructible(
    address target
  ) external view returns (bool registeredAsIndestructible) {
    registeredAsIndestructible = _definitelyIndestructible[target];
  }

  /**
   * @notice View function to perform a scan of a target contract and determine
   * whether it is potentially destructible or not. The call will revert if no
   * code exists at the supplied target.
   * @param target address The contract to check for potential destructibility.
   * @return A boolean signifying whether or not the target contract is
   * potentially destructible.
   */
  function isPotentiallyDestructible(
    address target
  ) external view returns (bool potentiallyDestructible) {
    potentiallyDestructible = _isPotentiallyDestructible(target);
  }

  /**
   * @notice Internal function that performs a scan of a target contract and
   * determines whether it is potentially destructible or not. It first
   * retrieves the runtime code size of the target contract and ensures that it
   * is greater than zero. Then, it retrieves the actual runtime code from the
   * target contract and places it into memory. Next, it iterates over the code,
   * skipping over unreachable code and push data, and ensures no SELFDESTRUCT,
   * DELEGATECALL, or CALLCODE opcodes are present in the code.
   * @param target address The contract to check for potential destructibility.
   * @return A boolean signifying whether or not the target contract is
   * potentially destructible.
   */
  function _isPotentiallyDestructible(
    address target
  ) internal view returns (bool potentiallyDestructible) {
    // Get the size of the target.
    uint256 size;
    assembly { size := extcodesize(target) }
    require(size > 0, "No code at target.");
    
    // Get code at the target and the location data starts and ends in memory.
    uint256 dataStart;
    bytes memory extcode = new bytes(size);
    assembly {
      dataStart := add(extcode, 0x20)
      extcodecopy(target, dataStart, 0, size)
    }
    uint256 dataEnd = dataStart + size;
    require (dataEnd > dataStart, "SafeMath: addition overflow.");
    
    // Look for any reachable, impermissible opcodes.
    bool reachable = true;
    uint256 op;
    for (uint256 i = dataStart; i < dataEnd; i++) {
      // Get the opcode in question.
      assembly { op := shr(0xf8, mload(i)) }
      
      // Check the opcode if it is reachable (i.e. not a constant or metadata).
      if (reachable) {
        // If execution is halted, mark opcodes that follow as unreachable.
        if (
          op == 254 || // invalid
          op == 243 || // return
          op == 253 || // revert
          op == 86  || // jump
          op == 0      // stop
        ) {
          reachable = false;
          continue;
        }

        // If the opcode is a PUSH, skip over the push data.
        if (op > 95 && op < 128) { // pushN
          i += (op - 95);
          continue;
        }
        
        // If opcode is impermissible, return true - potential destructibility!
        if (
          op == 242 || // callcode
          op == 244 || // delegatecall
          op == 255    // selfdestruct
        ) {
          return true; // potentially destructible!
        }
      } else if (op == 91) { // jumpdest
        // Whenever a JUMPDEST is found, mark opcodes that follow as reachable. 
        reachable = true;
      }
    }
  }
}