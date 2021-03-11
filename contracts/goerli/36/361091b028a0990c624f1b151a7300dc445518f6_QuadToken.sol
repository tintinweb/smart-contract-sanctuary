pragma solidity ^0.4.18;

import "./StandardToken.sol";


/**
 * @title QuadToken
 * @dev VERC20 Token, where all Quad tokens are pre-assigned to the creator.
 * Token transfer and transferFrom are enabled only after owners permission
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract QuadToken is StandardToken {

  string public constant name = "TriangleProtocol"; // solium-disable-line uppercase
  string public constant symbol = "TRI"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function QuadToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

}