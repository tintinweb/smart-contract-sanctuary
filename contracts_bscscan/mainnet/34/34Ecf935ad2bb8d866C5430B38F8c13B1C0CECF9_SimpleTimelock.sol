/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBEP20 {
  // @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of tokens owned by `account`.
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `value` tokens are moved from one account (`from`) to  another (`to`). Note that `value` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 value);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleTimelock {

  IBEP20 _token;
  address _beneficiary;
  uint256 _releaseTime;
  uint256 _releasedOn;
  bool _releasingTokens;

  event ReleasedTokens(
    IBEP20 tokenAddress,
    address to,
    uint256 amount
  );

  constructor(
    uint256 releaseTime,
    address beneficiary,
    IBEP20 tokenAddress
  ) {
    _beneficiary = beneficiary;
    _releaseTime = releaseTime;
    _token = tokenAddress;
  }

  function getToken() external view returns(IBEP20) {
    return _token;
  }

  function getBeneficiary() external view returns(address) {
    return _beneficiary;
  }

  function getReleaseDate() external view returns(uint256) {
    return _releaseTime;
  }

  function getReleasedOn() external view returns(uint256) {
    return _releasedOn;
  }

  function blockTime() external view returns(uint256) {
    return block.timestamp;
  }

  function timeLeft() external view returns(uint256) {
    if(block.timestamp < _releaseTime)
      return _releaseTime - block.timestamp;

    return 0;
  }

  function lockStatus() external view returns(bool) {
    return block.timestamp >= _releaseTime;
  }

  function release() external {
    require(block.timestamp >= _releaseTime, "TIMELOCK: locktime has not run out yet.");
    require(_releasingTokens == false, "TIMELOCK: release in progress...");

    uint256 contractBalance = _lockedTokens();

    require(contractBalance > 0, "TIMELOCK: balance of contract is 0.");

    _releasingTokens = true;

    _token.transfer(_beneficiary, contractBalance);
    emit ReleasedTokens(_token, _beneficiary, contractBalance);
    
    _releasedOn = block.timestamp;

    _releasingTokens = false;
  }

  // Wrapping internal functions
  function lockedTokens() external view returns(uint256) {
    return _lockedTokens();
  }

  // Internal - fetches locked balance by querying contract address at token
  function _lockedTokens() internal view returns(uint256) {
    return _token.balanceOf(address(this));
  }

}