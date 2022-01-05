pragma solidity ^0.4.23;

import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./Blacklisted.sol";


/**
 * @title HUMToken
 * @dev ERC20 HUMToken.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract SRTToken is MintableToken, BurnableToken, Blacklisted {

  string public constant name = "Smart Reward Token"; // solium-disable-line uppercase
  string public constant symbol = "SRT"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase, // 18 decimals is the strongly suggested default, avoid changing it

  uint256 public constant INITIAL_SUPPLY = 15000000000 * (10 ** uint256(decimals)); // 1,250,000,000 HUM

  bool public isUnlocked = false;
  
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
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