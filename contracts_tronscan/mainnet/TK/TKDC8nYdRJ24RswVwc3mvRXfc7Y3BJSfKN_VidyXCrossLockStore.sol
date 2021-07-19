//SourceUnit: VidyXCrossLockStore.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.10;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath: addition overflow");

      return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b <= a, errorMessage);
      uint256 c = a - b;

      return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) {
          return 0;
      }

      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");

      return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b > 0, errorMessage);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold

      return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b != 0, errorMessage);
      return a % b;
  }
}

/**
 * @dev A token holder contract that will allow an owner to extract the
 * tokens at any time.
 *
 * There are no restricts on withdrawal amounts or withdrawal times except
 * message source -- only the token owner can initiate a withdrawal. Note
 * that this is distinct behavior from the TRC10Timelock, which allows _anyone_
 * to initiate a withdrawal (to the owner) assuming the timelock has expired.
 * In that case, it is assumed that the owner wants the funds transferred
 * immediately upon release and any account is permitted to do so on their behalf.
 * For a TRC10Store, the owner has some other specific reason for keeping the
 * funds in a contract rather than their own wallet, and is the sole authorizer
 * of their release.
 *
 * One owner is allowed, although this designation can be transferred.
 * If a split between multiple beneficiaries is desired, implement this split
 * in a separate contract and set it as the owner of this one.
 *
 * There is no way to prevent TRC10 tokens of any type from being transferred
 * into this contract (no payable function, including fallback, is invoked for a
 * direct token transfer). To avoid confusion there is no "smart contract" way
 * to fund the store; just transfer tokens. Never transfer a token other than
 * the designated token for this store; it will be unretrievable.
 */
contract TRC10Store {
    using SafeMath for uint;

    // TRC10 basic token being held
    trcToken private _token;
    // token quantity released to owner (total)
    uint256 private _released;

    // owner of store; can retrieve tokens
    address private _owner;

    event Release(address payable to, uint256 amount);
    event OwnerChanged(address from, address to);

    constructor (uint256 token_, address owner_) public {
        _token = token_;
        _owner = owner_;

        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (trcToken) {
        return _token;
    }

    /**
     * @return the owner of the tokens.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return the amount of TRC10 tokens unlocked for the owner (total
     * including amount already released).
     */
    function amountUnlocked() public view returns (uint256) {
      // get the total value ever locked in this contract (present and already released)
      return address(this).tokenBalance(_token).add(_released);
    }

    /**
     * @return the amount of TRC10 token already released to the owner
     */
    function amountReleased() public view returns (uint256) {
      return _released;
    }

    /**
     * Release the indicated amount of TRC10 token to the specified recipient
     * address. Only the owner can make this call, transferring the funds
     * to their own address or another.
     */
    function release(address payable to_, uint256 amount_) external {
        require(msg.sender == _owner, "TRC10Store: only owner can release funds");

        uint256 available = address(this).tokenBalance(_token);
        require(available >= amount_, "TRC10Store: insufficient funds");

        _released = _released.add(amount_);
        emit Release(to_, amount_);

        to_.transferToken(amount_, _token);
    }

    /**
     * @notice Transfers the status of "owner" from the caller to the address
     * specified.
     */
    function transferOwnership(address payable owner_) external {
        require(msg.sender == _owner, "TRC10Store: only owner can transfer status");
        emit OwnerChanged(_owner, owner_);
        _owner = owner_;
    }
}


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens at any time.
 *
 * Useful as a store of value, e.g. as a simple CrossLock corresponding to
 * value stored on a different chain.
 *
 * There is no way to prevent TRC10 tokens of any type from being transferred
 * into this contract (no payable function, including fallback, is invoked for a
 * direct token transfer). To avoid confusion there is no "smart contract" way
 * to fund the timelock; just transfer the tokens.
 */
contract VidyXCrossLockStore is TRC10Store {

    constructor (uint256 token_, address payable beneficiary_)
    TRC10Store (token_, beneficiary_)
    public {
        // super constructor handles everything
    }
}