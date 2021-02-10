/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */

pragma solidity ^0.5.3;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IIssuable.sol";
import "./IDestroyable.sol";
import "./IReassignable.sol";
import "./IIdentifiable.sol";
import "./IContactable.sol";
import "./IRuleEngine.sol";

/**
 * @title CMTA20
 * @dev CMTA20 contract
 *
 * @author Sébastien Krafft - <[email protected]>
 *
 * errors:
 * CM01: Attempt to reassign from an original address which is 0x0
 * CM02: Attempt to reassign to a replacement address is 0x0
 * CM03: Attempt to reassign to replacement address which is the same as the original address
 * CM04: Transfer rejected by Rule Engine 
 * CM05: Attempt to reassign from an original address which does not have any tokens
 * CM06: Cannot call destroy with owner address contained in parameter
 */

 
contract CMTA20 is ERC20, Ownable, Pausable, IContactable, IIdentifiable, IIssuable, IDestroyable, IReassignable {
  using SafeMath for uint256;

  /* Constants */
  uint8 constant TRANSFER_OK = 0;
  uint8 constant TRANSFER_REJECTED_PAUSED = 1;

  string constant TEXT_TRANSFER_OK = "No restriction";
  string constant TEXT_TRANSFER_REJECTED_PAUSED = "All transfers paused";

  string public name;
  string public symbol;
  string public contact;
  mapping (address => bytes) internal identities;
  IRuleEngine public ruleEngine;

  // solium-disable-next-line uppercase
  uint8 constant public decimals = 0;

  constructor(string memory _name, string memory _symbol, string memory _contact) public {
    name = _name;
    symbol = _symbol;
    contact = _contact;
  }

  event LogRuleEngineSet(address indexed newRuleEngine);

  /**
  * Purpose
  * Set optional rule engine by owner
  * 
  * @param _ruleEngine - the rule engine that will approve/reject transfers
  */
  function setRuleEngine(IRuleEngine _ruleEngine) external onlyOwner {
    ruleEngine = _ruleEngine;
    emit LogRuleEngineSet(address(_ruleEngine));
  }

  /**
  * Purpose
  * Set contact point for shareholders
  * 
  * @param _contact - the contact information for the shareholders
  */
  function setContact(string calldata _contact) external onlyOwner {
    contact = _contact;
    emit LogContactSet(_contact);
  }

  /**
  * Purpose
  * Retrieve identity of a potential/actual shareholder
  */
  function identity(address shareholder) external view returns (bytes memory) {
    return identities[shareholder];
  }

  /**
  * Purpose
  * Set identity of a potential/actual shareholder. Can only be called by the potential/actual shareholder himself. Has to be encrypted data.
  * 
  * @param _identity - the potential/actual shareholder identity
  */
  function setMyIdentity(bytes calldata _identity) external {
    identities[msg.sender] = _identity;
  }

  /**
  * Purpose:
  * Issue tokens on the owner address
  *
  * @param _value - amount of newly issued tokens
  */
  function issue(uint256 _value) public onlyOwner {
    _balances[owner] = _balances[owner].add(_value);
    _totalSupply = _totalSupply.add(_value);

    emit Transfer(address(0), owner, _value);
    emit LogIssued(_value);
  }

  /**
  * Purpose:
  * Redeem tokens on the owner address
  *
  * @param _value - amount of redeemed tokens
  */
  function redeem(uint256 _value) public onlyOwner {
    _balances[owner] = _balances[owner].sub(_value);
    _totalSupply = _totalSupply.sub(_value);

    emit Transfer(owner, address(0), _value);
    emit LogRedeemed(_value);
  }

  /**
  * @dev check if _value token can be transferred from _from to _to
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  */
  function canTransfer(address _from, address _to, uint256 _value) public view returns (bool) {
    if (paused()) {
      return false;
    }
    if (address(ruleEngine) != address(0)) {
      return ruleEngine.validateTransfer(_from, _to, _value);
    }
    return true;
  }

  /**
  * @dev check if _value token can be transferred from _from to _to
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  * @return code of the rejection reason
  */
  function detectTransferRestriction (address _from, address _to, uint256 _value) public view returns (uint8) {
    if (paused()) {
      return TRANSFER_REJECTED_PAUSED;
    }
    if (address(ruleEngine) != address(0)) {
      return ruleEngine.detectTransferRestriction(_from, _to, _value);
    }
    return TRANSFER_OK;
  }

  /**
  * @dev returns the human readable explaination corresponding to the error code returned by detectTransferRestriction
  * @param _restrictionCode The error code returned by detectTransferRestriction
  * @return The human readable explaination corresponding to the error code returned by detectTransferRestriction
  */
  function messageForTransferRestriction (uint8 _restrictionCode) external view returns (string memory) {
    if (_restrictionCode == TRANSFER_OK) {
      return TEXT_TRANSFER_OK;
    } else if (_restrictionCode == TRANSFER_REJECTED_PAUSED) {
      return TEXT_TRANSFER_REJECTED_PAUSED;
    } else if (address(ruleEngine) != address(0)) {
      return ruleEngine.messageForTransferRestriction(_restrictionCode);
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    if (address(ruleEngine) != address(0)) {
      require(ruleEngine.validateTransfer(msg.sender, _to, _value), "CM04");
      return super.transfer(_to, _value);
    } else {
      return super.transfer(_to, _value);
    }
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    if (address(ruleEngine) != address(0)) {
      require(ruleEngine.validateTransfer(_from, _to, _value), "CM04");
      return super.transferFrom(_from, _to, _value);
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public whenNotPaused returns (bool)
  {
    return super.increaseAllowance(_spender, _addedValue);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool)
  {
    return super.decreaseAllowance(_spender, _subtractedValue);
  }

  /**
  * Purpose:
  * To withdraw tokens from the original address and
  * transfer those tokens to the replacement address.
  * Use in cases when e.g. investor loses access to his account.
  *
  * Conditions:
  * Throw error if the `original` address supplied is not a shareholder.
  * Only issuer can execute this function.
  *
  * @param original - original address
  * @param replacement - replacement address
    */
  function reassign(address original, address replacement) external onlyOwner whenNotPaused {
    require(original != address(0), "CM01");
    require(replacement != address(0), "CM02");
    require(original != replacement, "CM03");
    uint256 originalBalance = _balances[original];
    require(originalBalance != 0, "CM05");
    _balances[replacement] = _balances[replacement].add(originalBalance);
    _balances[original] = 0;
    emit Transfer(original, replacement, originalBalance);
    emit LogReassigned(original, replacement, originalBalance);
  }

  /**
  * Purpose;
  * To destroy issued tokens.
  *
  * Conditions:
  * Only issuer can execute this function.
  *
  * @param shareholders - list of shareholders
  */
  function destroy(address[] calldata shareholders) external onlyOwner {
    for (uint256 i = 0; i<shareholders.length; i++) {
      require(shareholders[i] != owner, "CM06");
      uint256 shareholderBalance = _balances[shareholders[i]];
      _balances[owner] = _balances[owner].add(shareholderBalance);
      _balances[shareholders[i]] = 0;
      emit Transfer(shareholders[i], owner, shareholderBalance);
    }
    emit LogDestroyed(shareholders);
  }
}