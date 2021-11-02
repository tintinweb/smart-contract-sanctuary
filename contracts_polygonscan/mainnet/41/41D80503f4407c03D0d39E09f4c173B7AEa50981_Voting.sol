// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "../utils/Ownable.sol";
import "../token/ERC20.sol";
import "../interfaces/IVoting.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev Implementation of the {IVoting} interface.
 */
contract Voting is IVoting, Context, Ownable {
  using SafeMathUint for uint256;
  using SafeMathUint for uint8;

  ERC20 _votingToken;

  // Struct for voting options
  // id - unique option ID
  // description - arbitrary description
  // totalVotes - total amount of votes collected for this option so far
  struct IssueOption {
    uint256 id;
    bytes32 description;
    uint256 totalVotes;
  }

  // Struct for voting issues
  // description - arbitrary description
  // endTimestamp - when the issue expires (in seconds since Unix epoch)
  // issueOptions - contains all the available voting options on this issue
  // issueOptionsAmount - amount of issue options, helps to iterate through `issueOptions`
  struct Issue {
    string description;
    uint256 endTimestamp;
    mapping(uint256 => IssueOption) issueOptions;
    uint256 issueOptionsAmount;
  }

  mapping(uint256 => Issue) private issues;
  mapping(uint256 => mapping(address => uint256)) private votes;
  uint256 private lastIssueIndex;
  uint256 private lastIssueOptionId;

  /**
   * @dev Sets the {ERC20} `votingToken` which tokens
   * determine a vote weight and are locked until the election ends.
   */
  constructor(ERC20 votingToken) {
    _votingToken = votingToken;
  }

  /**
   * @dev See {IVoting-token}.
   */
  function token() external override view returns (address) {
    return address(_votingToken);
  }

  /**
   * @dev See {IVoting-createIssue}.
   */
  function createIssue(
    string calldata description,
    uint256 duration,
    bytes32[] calldata options
  ) external override onlyOwner returns (uint256) {
    uint256 endTimestamp = block.timestamp.add(duration);
    issues[lastIssueIndex].issueOptionsAmount = options.length;
    issues[lastIssueIndex].description = description;
    issues[lastIssueIndex].endTimestamp = endTimestamp;
    for (uint256 i = 0; i < options.length; i++) {
      issues[lastIssueIndex].issueOptions[i] = IssueOption({
        id: lastIssueOptionId++,
        description: options[i],
        totalVotes: 0
      });
    }

    emit LogIssueCreated(lastIssueIndex, description, endTimestamp);
    return lastIssueIndex++;
  }

  /**
   * @dev See {IVoting-vote}.
   */
  function vote(
    uint256 amount,
    uint256 issueIndex,
    uint8 optionIndex
  ) external override isValidIssue(issueIndex) {
    Issue storage targetIssue = issues[issueIndex];
    require(
      block.timestamp <= targetIssue.endTimestamp,
      "Voting: issue voting has been finished already"
    );

    require(optionIndex < targetIssue.issueOptionsAmount, "Voting: passed the wrong option index");

    require(
      _votingToken.transferFrom(_msgSender(), address(this), amount),
      "Voting: voting tokens required"
    );

    votes[targetIssue.issueOptions[optionIndex].id][_msgSender()] = votes[targetIssue
      .issueOptions[optionIndex]
      .id][_msgSender()]
      .add(amount);
    targetIssue.issueOptions[optionIndex].totalVotes = targetIssue.issueOptions[optionIndex]
      .totalVotes
      .add(amount);

    emit LogVoteAccepted(issueIndex, optionIndex, amount);
  }

  /**
   * @dev See {IVoting-withdrawVotedTokens}.
   *
   * Requirements:
   *
   * - voting issue at `issueIndex` should have a timestamp
   * `endTimestamp` that is already reached.
   * - the caller must have a non-withdrawn votes on this issue.
   * - {ERC20} `_votingToken` should call {transfer} successfully.
   */
  function withdrawVotedTokens(uint256 issueIndex) external override isValidIssue(issueIndex) {
    Issue storage targetIssue = issues[issueIndex];
    require(
      block.timestamp > targetIssue.endTimestamp,
      "Voting: issue voting hasn't been finished already"
    );

    uint256 votedTokens;
    for (uint256 i = 0; i < targetIssue.issueOptionsAmount; i++) {
      votedTokens = votedTokens.add(votes[targetIssue.issueOptions[i].id][_msgSender()]);
      votes[targetIssue.issueOptions[i].id][_msgSender()] = 0;
    }

    require(votedTokens > 0, "Voting: haven't voted or withdrawn tokens already");

    require(_votingToken.transfer(_msgSender(), votedTokens), "Voting: transfer failed");
  }

  /**
   * @dev See {IVoting-recentIssueIndexes}.
   */
  function recentIssueIndexes(uint256 amountToRetrieve, uint256 offset)
    external
    override
    view
    returns (uint256[] memory)
  {
    uint256 offsetIssueAmount = lastIssueIndex.sub(offset);
    if (amountToRetrieve > offsetIssueAmount) {
      amountToRetrieve = offsetIssueAmount;
    }
    uint256[] memory issueIndexes = new uint256[](amountToRetrieve);

    uint256 retrieved;
    for (uint256 i = lastIssueIndex.sub(1).sub(offset); i >= 0; i--) {
      issueIndexes[retrieved] = i;
      if (++retrieved >= amountToRetrieve) {
        break;
      }
    }

    return (issueIndexes);
  }

  /**
   * @dev See {IVoting-issueDetails}.
   */
  function issueDetails(uint256 issueIndex)
    external
    override
    view
    returns (
      string memory,
      uint256,
      uint256
    )
  {
    return (
      issues[issueIndex].description,
      issues[issueIndex].endTimestamp,
      issues[issueIndex].issueOptionsAmount
    );
  }

  /**
   * @dev See {IVoting-issueOptions}.
   */
  function issueOptions(uint256 issueIndex)
    external
    override
    view
    isValidIssue(issueIndex)
    returns (bytes32[] memory, uint256[] memory)
  {
    Issue storage targetIssue = issues[issueIndex];
    bytes32[] memory optionDescriptions = new bytes32[](targetIssue.issueOptionsAmount);
    uint256[] memory optionTotalVotes = new uint256[](targetIssue.issueOptionsAmount);

    for (uint256 i = 0; i < targetIssue.issueOptionsAmount; i++) {
      optionDescriptions[i] = targetIssue.issueOptions[i].description;
      optionTotalVotes[i] = targetIssue.issueOptions[i].totalVotes;
    }

    return (optionDescriptions, optionTotalVotes);
  }

  /**
   * @dev Checks if `issueIndex` points to the existing voting issue.
   */
  modifier isValidIssue(uint256 issueIndex) {
    require(issueIndex <= lastIssueIndex.sub(1), "Voting: passed the wrong issue index");
    _;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./Context.sol";

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
  event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = _msgSender();
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_msgSender() == _owner, "Ownable: only contract owner can call this function.");
    _;
  }

  /**
   * @dev Checks if transaction sender account is an owner.
   */
  function isOwner() external view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit LogOwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this;
    return msg.data;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Functions revert instead of returning `false` on failure.
 * This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * The non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
  using SafeMathUint for uint256;

  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 internal _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeMint();
    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
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

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any token mint.
   */
  function _beforeMint() internal virtual {}
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMathUint` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUint {
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  /**
   * @dev Converts an unsigned integer to a signed integer,
   * Reverts when convertation overflows.
   *
   * Requirements:
   *
   * - Operation cannot overflow.
   */
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0, "SafeMath: convertation overflow");
    return b;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Interface of the voting smart contract that locks
 * {ERC20} voting token while election process is not finished.
 */
interface IVoting {
  /**
   * @dev Emitted when the new voting issue becomes available at `issueIndex` with
   * specified `issueDescription` and `issueEndTimestamp`.
   */
  event LogIssueCreated(uint256 issueIndex, string issueDescription, uint256 issueEndTimestamp);

  /**
   * @dev Emitted when the new vote for option `optionIndex` with weight `amount`
   * was accepted for the issue identified by `issueIndex`.
   */
  event LogVoteAccepted(uint256 issueIndex, uint8 optionIndex, uint256 amount);

  /**
   * @dev {ERC20} voting token that determines a vote weight and
   * becomes locked until the election ends.
   */
  function token() external view returns (address);

  /**
   * @dev Creates a new voting issue from a `description`, `duration`
   * and an array of `options`, returns the issue index.
   */
  function createIssue(
    string calldata description,
    uint256 duration,
    bytes32[] calldata options
  ) external returns (uint256);

  /**
   * @dev Creates the new vote for option `optionIndex` with weight `amount`
   * for the issue identified by `issueIndex`, locks `amount` of {token}.
   */
  function vote(
    uint256 amount,
    uint256 issueIndex,
    uint8 optionIndex
  ) external;

  /**
   * @dev Returns all the tokens used for voting on the issue at `issueIndex`
   * back to the voter.
   */
  function withdrawVotedTokens(uint256 issueIndex) external;

  /**
   * @dev Returns `amountToRetrieve` of the latest voting issues,
   * shifted by `offset` (may be used for pagination).
   */
  function recentIssueIndexes(uint256 amountToRetrieve, uint256 offset)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Returns issue's description, end timestamp and amount of available options.
   */
  function issueDetails(uint256 issueIndex)
    external
    view
    returns (
      string memory,
      uint256,
      uint256
    );

  /**
   * @dev Returns issue options' descriptions and total votes per each.
   */
  function issueOptions(uint256 issueIndex)
    external
    view
    returns (bytes32[] memory, uint256[] memory);
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

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
  function allowance(address owner, address spender) external view returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}