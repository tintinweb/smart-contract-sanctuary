// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    CallExecutor.sol :: 0x26e0a2EC2B79Ac3E9E0A8c52bCc76E8BbB843499
 *    etherscan.io verified 2021-12-01
 */ 

/**
 * @dev Used as a proxy for call execution to obscure msg.sender of the
 * caller. msg.sender will be the address of the CallExecutor contract.
 *
 * Instances of Proxy (user account contracts) use CallExecutor to execute
 * unsigned data calls without exposing themselves as msg.sender. Users can
 * sign messages that allow public unsigned data execution via CallExecutor
 * without allowing public calls to be executed directly from their Proxy
 * contract.
 *
 * This is implemented specifically for swap calls that allow unsigned data
 * execution. If unsigned data was executed directly from the Proxy contract,
 * an attacker could make a call that satisfies the swap required conditions
 * but also makes other malicious calls that rely on msg.sender. Forcing all
 * unsigned data execution to be done through a CallExecutor ensures that an
 * attacker cannot impersonate the users's account.
 *
 */
contract CallExecutor {
  /**
   * @dev A payable function that executes a call with `data` on the
   * contract address `to`
   *
   * Sets value for the call to `callvalue`, the amount of Eth provided with
   * the call
   */
  function proxyCall(address to, bytes memory data) external payable {
    // execute `data` on execution contract address `to`
    assembly {
      let result := call(gas(), to, callvalue(), add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}