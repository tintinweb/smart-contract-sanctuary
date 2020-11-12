// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

/**
 * @title An Ether or token balance scanner
 * @author Maarten Zuidhoorn
 * @author Luit Hollander
 */
contract BalanceScanner {
  /**
   * @notice Get the Ether balance for all addresses specified
   * @param addresses The addresses to get the Ether balance for
   * @return balances The Ether balance for all addresses in the same order as specified
   */
  function etherBalances(address[] calldata addresses) external view returns (uint256[] memory balances) {
    balances = new uint256[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = addresses[i].balance;
    }
  }

  /**
   * @notice Get the ERC-20 token balance of `token` for all addresses specified
   * @dev This does not check if the `token` address specified is actually an ERC-20 token
   * @param addresses The addresses to get the token balance for
   * @param token The address of the ERC-20 token contract
   * @return balances The token balance for all addresses in the same order as specified
   */
  function tokenBalances(address[] calldata addresses, address token)
    external
    view
    returns (uint256[] memory balances)
  {
    balances = new uint256[](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = tokenBalance(addresses[i], token);
    }
  }

  /**
   * @notice Get the ERC-20 token balances for multiple contracts, for multiple addresses
   * @dev This does not check if the `token` address specified is actually an ERC-20 token
   * @param addresses The addresses to get the token balances for
   * @param contracts The addresses of the ERC-20 token contracts
   * @return balances The token balances in the same order as the addresses specified
   */
  function tokensBalances(address[] calldata addresses, address[] calldata contracts)
    external
    view
    returns (uint256[][] memory balances)
  {
    balances = new uint256[][](addresses.length);

    for (uint256 i = 0; i < addresses.length; i++) {
      balances[i] = tokensBalance(addresses[i], contracts);
    }
  }

  /**
   * @notice Get the ERC-20 token balance from multiple contracts for a single owner
   * @param owner The address of the token owner
   * @param contracts The addresses of the ERC-20 token contracts
   * @return balances The token balances in the same order as the addresses specified
   */
  function tokensBalance(address owner, address[] calldata contracts) public view returns (uint256[] memory balances) {
    balances = new uint256[](contracts.length);

    for (uint256 i = 0; i < contracts.length; i++) {
      balances[i] = tokenBalance(owner, contracts[i]);
    }
  }

  /**
    * @notice Get the ERC-20 token balance for a single contract
    * @param owner The address of the token owner
    * @param token The address of the ERC-20 token contract
    * @return balance The token balance, or zero if the address is not a contract, or does not implement the `balanceOf`
      function
  */
  function tokenBalance(address owner, address token) private view returns (uint256 balance) {
    uint256 size = codeSize(token);

    if (size > 0) {
      (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", owner));
      if (success) {
        (balance) = abi.decode(data, (uint256));
      }
    }
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