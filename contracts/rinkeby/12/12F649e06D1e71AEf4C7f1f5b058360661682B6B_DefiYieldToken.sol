// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DefiYieldToken is Ownable {
  uint256 public constant MAX_UINT_256 = 2**256 - 1;
  uint96 public constant MAX_UINT_96 = 2**96 - 1;

  /// @notice EIP-20 token name for this token
  string public constant name = "DefiYield Token";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "DFY";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply = 300_000_000e18; // 300M DefiYield Tokens

  /// @notice Address which may mint new tokens
  address public minter;

  /// @notice The timestamp after which minting may occur
  uint256 public mintingAllowedAfter;

    /// @notice The timestamp after which blacklist will be ignored
  uint256 public blacklistIgnoredAfter;

  /// @notice Address which may blacklist accounts
  address public whitelister;

  /// @notice Minimum time between mints
  uint32 public constant minimumTimeBetweenMints = 1 days * 365;

  /// @notice Cap on the percentage of totalSupply that can be minted at each mint
  uint8 public constant mintCap = 2;

  // Allowance amounts on behalf of others
  mapping (address => mapping (address => uint96)) internal allowances;

  // Official record of token balances for each account
  mapping (address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping (address => address) public delegates;

  // List of blacklisted accounts
  mapping (address => bool) internal blacklist;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping (address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice The EIP-712 typehash for the permit struct used by the contract
  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  /// @notice A record of states for signing / validating signatures
  mapping (address => uint) public nonces;

  /// @notice An event thats emitted when the minter address is changed
  event MinterChanged(address minter, address newMinter);

  /// @notice An event thats emitted when the whitelister address is changed
  event WhitelisterChanged(address whitelister, address newWhitelister);

  /// @notice An event thats emitted when the account added to blacklist
  event AddedToBlacklist(address account);

  /// @notice An event thats emitted when the account removed from blacklist
  event RemovedFromBlacklist(address account);

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /**
    * @notice Construct a new DefiYieldToken token
    * @param account The initial account to grant all the tokens
    * @param minter_ The account with minting ability
    * @param whitelister_ The account with blacklisting ability
    * @param mintingAllowedAfter_ The timestamp after which minting may occur
    * @param blacklistIgnoredAfter_ The timestamp after which blacklist will be ignored
    */
  constructor(address account, address minter_, address whitelister_, uint256 mintingAllowedAfter_, uint256 blacklistIgnoredAfter_) {
    require(mintingAllowedAfter_ >= block.timestamp, "DefiYieldToken::constructor: minting can only begin after deployment");
    require(blacklistIgnoredAfter_ >= block.timestamp, "DefiYieldToken::constructor: blacklist ignoring can only begin after deployment");

    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);

    minter = minter_;
    emit MinterChanged(address(0), minter);

    whitelister = whitelister_;
    emit WhitelisterChanged(address(0), whitelister);

    mintingAllowedAfter = mintingAllowedAfter_;
    blacklistIgnoredAfter = blacklistIgnoredAfter_;
  }

  /**
    * @dev Throws if called by any account other than the owner.
    */
  modifier onlyIfNotBlacklisted(address account) {
      require(block.timestamp > blacklistIgnoredAfter || !blacklist[account], "DefiYieldToken::onlyIfNotBlacklisted: caller is blacklisted");
      _;
  }

  /**
    * @notice Change the minter address
    * @param minter_ The address of the new minter
    */
  function setMinter(address minter_) external onlyOwner {
    minter = minter_;

    emit MinterChanged(minter, minter_);
  }

  /**
    * @notice Change the whitelister address
    * @param whitelister_ The address of the new whitelister
    */
  function setWhitelister(address whitelister_) external onlyOwner {
    whitelister = whitelister_;

    emit WhitelisterChanged(whitelister, whitelister_);
  }

  /**
    * @notice Adds new account to blacklist
    * @param account The address going to be added to blacklist
    */
  function addToBlacklist(address account) external {
    require(msg.sender == whitelister, "DefiYieldToken::addToBlacklist: only the whitelister can add to blacklist");
    blacklist[account] = true;

    emit AddedToBlacklist(account);
  }

  /**
    * @notice Removes account from blacklist
    * @param account The address going to be removed to blacklist
    */
  function removeFromBlacklist(address account) external onlyOwner {
    require(msg.sender == whitelister, "DefiYieldToken::addToBlacklist: only the whitelister can remove from blacklist");
    blacklist[account] = false;

    emit RemovedFromBlacklist(account);
  }

  /**
    * @notice Mint new tokens
    * @param dst The address of the destination account
    * @param rawAmount The number of tokens to be minted
    */
  function mint(address dst, uint256 rawAmount) external {
    require(msg.sender == minter, "DefiYieldToken::mint: only the minter can mint");
    require(block.timestamp >= mintingAllowedAfter, "DefiYieldToken::mint: minting not allowed yet");
    require(dst != address(0), "DefiYieldToken::mint: cannot transfer to the zero address");

    // record the mint
    mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);

    // mint the amount
    uint96 amount = safe96(rawAmount, "DefiYieldToken::mint: amount exceeds 96 bits");
    require(amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "DefiYieldToken::mint: exceeded mint cap");
    totalSupply = safe96(SafeMath.add(totalSupply, amount), "DefiYieldToken::mint: totalSupply exceeds 96 bits");

    // transfer the amount to the recipient
    balances[dst] = add96(balances[dst], amount, "DefiYieldToken::mint: transfer amount overflows");
    emit Transfer(address(0), dst, amount);

    // move delegates
    _moveDelegates(address(0), delegates[dst], amount);
  }

  /**
    * @notice Destroys tokens, reducing the total supply
    * @param rawAmount The amount of tokens to burn
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    * - `account` must have at least `amount` tokens.
    */
  function burn(uint256 rawAmount) external onlyIfNotBlacklisted(_msgSender()) {
    uint96 amount = safe96(rawAmount, "DefiYieldToken::burn: amount exceeds 96 bits");
    balances[msg.sender] = sub96(balances[msg.sender], amount, "DefiYieldToken::burn: amount exceeds balance");
    totalSupply = SafeMath.sub(totalSupply, amount);

    emit Transfer(msg.sender, address(0), amount);

    // move delegates
    _moveDelegates(msg.sender, address(0), amount);
  }

  /**
    * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
    * @param account The address of the account holding the funds
    * @param spender The address of the account spending the funds
    * @return The number of tokens approved
    */
  function allowance(address account, address spender) external view returns (uint) {
    return allowances[account][spender];
  }

  /**
    * @notice Approve `spender` to transfer up to `amount` from `src`
    * @dev This will overwrite the approval amount for `spender`
    *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
    * @param spender The address of the account which may transfer tokens
    * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
    * @return Whether or not the approval succeeded
    */
  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    
    if (rawAmount ==  MAX_UINT_256) {
      amount = MAX_UINT_96;
    } else {
      amount = safe96(rawAmount, "DefiYieldToken::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
    * @notice Triggers an approval from owner to spends
    * @param owner The address to approve from
    * @param spender The address to be approved
    * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
    * @param deadline The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function permit(address owner, address spender, uint256 rawAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    uint96 amount;
    if (rawAmount == MAX_UINT_256) {
      amount = MAX_UINT_96;
    } else {
      amount = safe96(rawAmount, "DefiYieldToken::permit: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "DefiYieldToken::permit: invalid signature");
    require(signatory == owner, "DefiYieldToken::permit: unauthorized");
    require(block.timestamp <= deadline, "DefiYieldToken::permit: signature expired");

    allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  /**
    * @notice Get the number of tokens held by the `account`
    * @param account The address of the account to get the balance of
    * @return The number of tokens held
    */
  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }

  /**
    * @notice Transfer `amount` tokens from `msg.sender` to `dst`
    * @param dst The address of the destination account
    * @param rawAmount The number of tokens to transfer
    * @return Whether or not the transfer succeeded
    */
  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "DefiYieldToken::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  /**
    * @notice Transfer `amount` tokens from `src` to `dst`
    * @param src The address of the source account
    * @param dst The address of the destination account
    * @param rawAmount The number of tokens to transfer
    * @return Whether or not the transfer succeeded
    */
  function transferFrom(address src, address dst, uint256 rawAmount) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "DefiYieldToken::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != MAX_UINT_96) {
      uint96 newAllowance = sub96(spenderAllowance, amount, "DefiYieldToken::transferFrom: transfer amount exceeds spender allowance");
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "DefiYieldToken::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "DefiYieldToken::delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "DefiYieldToken::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96) {
    require(blockNumber < block.number, "DefiYieldToken::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal onlyIfNotBlacklisted(delegator) {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(address src, address dst, uint96 amount) internal onlyIfNotBlacklisted(src) {
    require(src != address(0), "DefiYieldToken::_transferTokens: cannot transfer from the zero address");

    balances[src] = sub96(balances[src], amount, "DefiYieldToken::_transferTokens: transfer amount exceeds balance");
    balances[dst] = add96(balances[dst], amount, "DefiYieldToken::_transferTokens: transfer amount overflows");
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "DefiYieldToken::_moveVotes: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "DefiYieldToken::_moveVotes: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
    uint32 blockNumber = safe32(block.number, "DefiYieldToken::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal view returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 9999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}