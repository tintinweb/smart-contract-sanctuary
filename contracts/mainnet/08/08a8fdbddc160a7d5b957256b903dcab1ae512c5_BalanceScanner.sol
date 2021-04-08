/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/**
 * @title An Ether or token balance scanner
 * @author Maarten Zuidhoorn
 * @author Luit Hollander
 */
contract BalanceScanner {
  struct Result {
    bool success;
    bytes data;
  }

  /**
   * @notice Get the Ether balance for all addresses specified
   * @param addresses The addresses to get the Ether balance for
   * @return results The Ether balance for all addresses in the same order as specified
   */
  function etherBalances(address[] calldata addresses) external view returns (Result[] memory results) {
    results = new Result[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      results[i] = Result(true, abi.encode(addresses[i].balance));
    }
  }

  /**
   * @notice Get the ERC-20 token balance of `token` for all addresses specified
   * @dev This does not check if the `token` address specified is actually an ERC-20 token
   * @param addresses The addresses to get the token balance for
   * @param token The address of the ERC-20 token contract
   * @return results The token balance for all addresses in the same order as specified
   */
  function tokenBalances(address[] calldata addresses, address token) external view returns (Result[] memory results) {
    results = new Result[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      bytes memory data = abi.encodeWithSignature("balanceOf(address)", addresses[i]);
      results[i] = staticCall(token, data, 20000);
    }
  }

  /**
   * @notice Get the ERC-20 token balance from multiple contracts for a single owner
   * @param owner The address of the token owner
   * @param contracts The addresses of the ERC-20 token contracts
   * @return results The token balances in the same order as the addresses specified
   */
  function tokensBalance(address owner, address[] calldata contracts) external view returns (Result[] memory results) {
    results = new Result[](contracts.length);

    bytes memory data = abi.encodeWithSignature("balanceOf(address)", owner);
    for (uint256 i = 0; i < contracts.length; i++) {
      results[i] = staticCall(contracts[i], data, 20000);
    }
  }

  /**
   * @notice Call multiple contracts with the provided arbitrary data
   * @param contracts The contracts to call
   * @param data The data to call the contracts with
   * @return results The raw result of the contract calls
   */
  function call(address[] calldata contracts, bytes[] calldata data) external view returns (Result[] memory results) {
    return call(contracts, data, gasleft());
  }

  /**
   * @notice Call multiple contracts with the provided arbitrary data
   * @param contracts The contracts to call
   * @param data The data to call the contracts with
   * @param gas The amount of gas to call the contracts with
   * @return results The raw result of the contract calls
   */
  function call(
    address[] calldata contracts,
    bytes[] calldata data,
    uint256 gas
  ) public view returns (Result[] memory results) {
    require(contracts.length == data.length, "Length must be equal");
    results = new Result[](contracts.length);

    for (uint256 i = 0; i < contracts.length; i++) {
      results[i] = staticCall(contracts[i], data[i], gas);
    }
  }

  /**
   * @notice Static call a contract with the provided data
   * @param target The address of the contract to call
   * @param data The data to call the contract with
   * @param gas The amount of gas to forward to the call
   * @return result The result of the contract call
   */
  function staticCall(
    address target,
    bytes memory data,
    uint256 gas
  ) private view returns (Result memory) {
    uint256 size = codeSize(target);

    if (size > 0) {
      (bool success, bytes memory result) = target.staticcall{ gas: gas }(data);
      if (success) {
        return Result(success, result);
      }
    }

    return Result(false, "");
  }

  /**
   * @notice Get code size of address
   * @param _address The address to get code size from
   * @return size Unsigned 256-bits integer
   */
  function codeSize(address _address) private view returns (uint256 size) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_address)
    }
  }
}