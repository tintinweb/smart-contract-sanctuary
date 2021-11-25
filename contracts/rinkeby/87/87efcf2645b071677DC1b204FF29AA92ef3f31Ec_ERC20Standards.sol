// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ERC20Standards is ERC20 {
  uint256 private cap_;
  string private types;

  constructor(
    address _owner,
    string memory _types,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) ERC20(name, symbol, decimal) {
    require(_owner != address(0));
    types = _types;
    cap_ = _cap * 10**uint8(decimal);
    _mint(_owner, initialSupply);
    transferOwnership(_owner);
  }

  function mint(address to, uint256 amount) public payable virtual {
    require(
      keccak256(abi.encodePacked(types)) ==
        keccak256(abi.encodePacked("Mintable"))
    );
    _mint(to, amount);
    // _moveDelegates(address(0), _delegates[to], amount);
  }

  function cap() public view virtual returns (uint256) {
    require(
      keccak256(abi.encodePacked(types)) ==
        keccak256(abi.encodePacked("Mintable"))
    );
    return cap_;
  }

  function _mint(address account, uint256 amount) internal virtual override {
    require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
    super._mint(account, amount);
  }

  function burn(uint256 amount) public virtual {
    require(
      keccak256(abi.encodePacked(types)) ==
        keccak256(abi.encodePacked("Burnable"))
    );
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
    require(
      keccak256(abi.encodePacked(types)) ==
        keccak256(abi.encodePacked("Mintable"))
    );
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

  // @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).

  // @notice A record of each accounts delegate
  mapping(address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegator The address to get delegatee for
   */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
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
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name())),
        getChainId(),
        address(this)
      )
    );

    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
    );

    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint256) {
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
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256)
  {
    require(blockNumber < block.number, "getPriorVotes: not yet determined");

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

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint256 srcRepNew = srcRepOld - amount;
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint256 dstRepNew = dstRepOld + amount;
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "_writeCheckpoint: block number exceeds 32 bits"
    );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _transferOwnership(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

interface IERC20 {
  //erc2917 and erc20
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function deposit(address account, uint256 amount) external returns (bool);

  function withdrawal(address account, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

library SafeCast {
  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(
      value <= type(uint224).max,
      "SafeCast: value doesn't fit in 224 bits"
    );
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(
      value <= type(uint128).max,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(
      value <= type(uint96).max,
      "SafeCast: value doesn't fit in 96 bits"
    );
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(
      value <= type(uint64).max,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(
      value <= type(uint32).max,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(
      value <= type(uint16).max,
      "SafeCast: value doesn't fit in 16 bits"
    );
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
   * @dev Converts a signed int256 into an unsigned uint256.
   *
   * Requirements:
   *
   * - input must be greater than or equal to 0.
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int128 from int256, reverting on
   * overflow (when the input is less than smallest int128 or
   * greater than largest int128).
   *
   * Counterpart to Solidity's `int128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v3.1._
   */
  function toInt128(int256 value) internal pure returns (int128) {
    require(
      value >= type(int128).min && value <= type(int128).max,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return int128(value);
  }

  /**
   * @dev Returns the downcasted int64 from int256, reverting on
   * overflow (when the input is less than smallest int64 or
   * greater than largest int64).
   *
   * Counterpart to Solidity's `int64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v3.1._
   */
  function toInt64(int256 value) internal pure returns (int64) {
    require(
      value >= type(int64).min && value <= type(int64).max,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return int64(value);
  }

  /**
   * @dev Returns the downcasted int32 from int256, reverting on
   * overflow (when the input is less than smallest int32 or
   * greater than largest int32).
   *
   * Counterpart to Solidity's `int32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v3.1._
   */
  function toInt32(int256 value) internal pure returns (int32) {
    require(
      value >= type(int32).min && value <= type(int32).max,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return int32(value);
  }

  /**
   * @dev Returns the downcasted int16 from int256, reverting on
   * overflow (when the input is less than smallest int16 or
   * greater than largest int16).
   *
   * Counterpart to Solidity's `int16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v3.1._
   */
  function toInt16(int256 value) internal pure returns (int16) {
    require(
      value >= type(int16).min && value <= type(int16).max,
      "SafeCast: value doesn't fit in 16 bits"
    );
    return int16(value);
  }

  /**
   * @dev Returns the downcasted int8 from int256, reverting on
   * overflow (when the input is less than smallest int8 or
   * greater than largest int8).
   *
   * Counterpart to Solidity's `int8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8) {
    require(
      value >= type(int8).min && value <= type(int8).max,
      "SafeCast: value doesn't fit in 8 bits"
    );
    return int8(value);
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(
      value <= uint256(type(int256).max),
      "SafeCast: value doesn't fit in an int256"
    );
    return int256(value);
  }
}

library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) public _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimal;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimal_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimal = decimal_;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimal;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  function deposit(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    require(account != address(0), "ERC20: mint to the zero address");

    _balances[account] += amount;
    _totalSupply = _totalSupply.add(amount);

    emit Transfer(address(0), account, amount);
    return true;
  }

  function withdrawal(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

    _balances[account] = accountBalance - amount;

    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
    return true;
  }
}