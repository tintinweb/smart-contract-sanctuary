pragma solidity ^0.4.23;

import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./Blacklisted.sol";

/**
 * @title Token
 * ERC20 Token.
 * Genesis Token
 */
contract B34R is MintableToken, BurnableToken, Blacklisted {

  string public constant name = "B34R"; // solium-disable-line uppercase
  string public constant symbol = "B34R"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 1000 * 1000 * (1000 ** uint256(decimals)); // initial supply B34R token

  bool public isUnlocked = false;

  /**
   * Constructor that gives msg.sender all of existing tokens.
   */
  constructor(address _wallet) public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[_wallet] = INITIAL_SUPPLY;
    emit Transfer(address(0), _wallet, INITIAL_SUPPLY);
  }

  modifier onlyTransferable() {
    require(isUnlocked || owners[msg.sender] != 0);
    _;
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transfer(_to, _value);
  }

  function unlockTransfer() public onlyOwner {
      isUnlocked = true;
  }

  function lockTransfer() public onlyOwner {
      isUnlocked = false;
  }

}