// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./base/TokenVesting.sol";

contract AdvisorsVesting is TokenVesting {
    uint256 internal constant _DURATION = 270 days;
    uint256 internal constant _INITIAL_RELEASE_PERCENTAGE = 10;

    constructor(
        address _NBLaddress,
        uint256 _start,
        address _beneficiary,
        uint256 _amount
    ) TokenVesting(
        _NBLaddress, 
        _start, 
        _DURATION, 
        _INITIAL_RELEASE_PERCENTAGE, 
        _beneficiary, 
        _amount
    ) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./../IBEP20.sol";

contract TokenVesting {

    IBEP20 public NBL;
    uint256 public start;
    uint256 public duration;
    uint256 public initialReleasePercentage;
    address public beneficiary;
    uint256 public allocatedTokens;
    uint256 public claimedTokens;

    event TokensClaimed(address beneficiary, uint256 value);
    event TokensAllocated(address beneficiary, uint256 value);

    constructor(
        address _NBLaddress,
        uint256 _start,
        uint256 _duration,
        uint256 _initialReleasePercentage,
        address _beneficiary,
        uint256 _amount
    ) {
        NBL = IBEP20(_NBLaddress);
        start = _start;
        duration = _duration;
        beneficiary = _beneficiary;
        initialReleasePercentage = _initialReleasePercentage;
        allocatedTokens = _amount;
        emit TokensAllocated(beneficiary, allocatedTokens);
    }

    function claimTokens() public {
        uint256 claimableTokens = getClaimableTokens();
        require(claimableTokens > 0, "Vesting: no claimable tokens");

        claimedTokens += claimableTokens;
        NBL.transfer(beneficiary, claimableTokens);

        emit TokensClaimed(beneficiary, claimableTokens);
    }

    function getAllocatedTokens() public view returns (uint256 amount) {
        return allocatedTokens;
    }

    function getClaimedTokens() public view returns (uint256 amount) {
        return claimedTokens;
    }

    function getClaimableTokens() public view returns (uint256 amount) {
        uint256 releasedTokens = getReleasedTokensAtTimestamp(block.timestamp);
        return releasedTokens - claimedTokens;
    }

    function getReleasedTokensAtTimestamp(uint256 timestamp) public view returns (uint256 amount) {
        if (timestamp < start) {
            return 0;
        }
        
        uint256 elapsedTime = timestamp - start;

        if (elapsedTime >= duration) {
            return allocatedTokens;
        }

        uint256 initialRelease = allocatedTokens * initialReleasePercentage / 100;
        uint256 remainingTokensAfterInitialRelease = allocatedTokens - initialRelease;
        uint256 subsequentRelease = remainingTokensAfterInitialRelease * elapsedTime / duration;
        uint256 totalReleasedTokens = initialRelease + subsequentRelease;

        return totalReleasedTokens;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
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

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}