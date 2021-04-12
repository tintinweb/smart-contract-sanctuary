// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./ERC20Burnable.sol";
import "./SafeMathUint.sol";
import "./Ownable.sol";

/**
 * @dev EggToken is a {ERC20} implementation with various extensions
 * and custom functionality.
 */
contract EarlyToken is ERC20Burnable, Ownable {
  using SafeMathUint for uint256;

  /**
   * @dev Sets the values for {name} and {symbol}, allocates the `initialTotalSupply`.
   */
  constructor() ERC20('EarlyToken', 'ERL') {
    _totalSupply = 10000000000*(10**6);
    _balances[_msgSender()] = _balances[_msgSender()].add(_totalSupply);
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }
}