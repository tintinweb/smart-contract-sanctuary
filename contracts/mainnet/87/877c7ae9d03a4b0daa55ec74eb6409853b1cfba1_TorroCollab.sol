// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./ITorro.sol";

/// @author ORayskiy - @robitnik_TorroDao
contract TorroCollab {

  // Private data.

  uint8 constant private _decimals = 18;

  string private _name;
  string private _symbol;
  ITorro private _token;
  address private _owner;

  // Events.

  // Constructor.

  constructor(address address_) public {
    _name = "Torro DAO Staked";
    _symbol = "TORRO-COLLAB";
    _token = ITorro(address_);
    _owner = msg.sender;
  }

  // Public calls.

  /// @notice Token's name.
  /// @return string name of the token.
  function name() public view returns (string memory) {
    return _name;
  }

  /// @notice Token's symbol.
  /// @return string symbol of the token.
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /// @notice Token's decimals.
  /// @return uint8 demials of the token.
  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  /// @notice Token's total supply.
  /// @return uint256 total supply of the token.
	function totalSupply() public view returns (uint256) {
		return _token.stakedSupply();
	}

  /// @notice Available balance for address.
  /// @param sender_ address to get available balance for.
  /// @return uint256 amount of tokens available for given address.
  function balanceOf(address sender_) public view returns (uint256) {
    return _token.stakedOf(sender_);
  }

  /// @notice Spending allowance.
  /// @param owner_ token owner address.
  /// @param spender_ token spender address.
  /// @return uint256 amount of owner's tokens that spender can use.
  function allowance(address owner_, address spender_) public view returns (uint256) {
    return 0;
  }

  // Public transactions.

  /// @notice Transfer tokens to recipient.
  /// @param recipient_ address of tokens' recipient.
  /// @param amount_ amount of tokens to transfer.
  /// @return bool true if successful.
  function transfer(address recipient_, uint256 amount_) public returns (bool) {
    return false;
  }

  /// @notice Approve spender to spend an allowance.
  /// @param spender_ address that will be allowed to spend specified amount of tokens.
  /// @param amount_ amount of tokens that spender can spend.
  /// @return bool true if successful.
  function approve(address spender_, uint256 amount_) public returns (bool) {
    return false;
  }

  /// @notice Transfers tokens from owner to recipient by approved spender.
  /// @param owner_ address of tokens' owner whose tokens will be spent.
  /// @param recipient_ address of recipient that will recieve tokens.
  /// @param amount_ amount of tokens to be spent.
  /// @return bool true if successful.
  function transferFrom(address owner_, address recipient_, uint256 amount_) public returns (bool) {
    return false;
  }

  /// @notice Increases allowance for given spender.
  /// @param spender_ spender to increase allowance for.
  /// @param addedValue_ extra amount that spender can spend.
  /// @return bool true if successful.
  function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
    return false;
  }

  /// @notice Decreases allowance for given spender.
  /// @param spender_ spender to decrease allowance for.
  /// @param subtractedValue_ removed amount that spender can spend.
  /// @return bool true if successful.
  function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
    return false;
  }

  function setNewToken(address address_) public {
    require(msg.sender == _owner);
    _token = ITorro(address_);
  }
}
