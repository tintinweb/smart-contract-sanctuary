// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC777.sol";

contract ERC777MintGovernance is ERC777 {
  // @dev Governance
  mapping(address => address) internal _delegates;
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
  mapping(address => uint32) public numCheckpoints;
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  mapping(address => uint256) public nonces;

  // @dev Delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  mapping(bytes32 => uint32) private types;
  uint256 private _cap;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 cap_,
    address _owner
  ) ERC777(name, symbol, decimal, new address[](0)) {
    transferOwnership(_owner);
    _cap = cap_ * 10**uint8(decimal);
    _mint(_owner, initialSupply, "", "");
    _moveDelegates(address(0), _delegates[_owner], initialSupply);
  }

  //@dev Mintable
  function mint(
    address account,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) public virtual {
    require(owner() == _msgSender(), "ERC777: caller is not owner");
    require(
      ERC777.totalSupply() + amount <= cap(),
      "ERC777Capped: cap exceeded"
    );
    _mint(account, amount, userData, operatorData);
    _moveDelegates(address(0), _delegates[account], amount);
  }

  function _mint(
    address account,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal virtual override {
    require(ERC777.totalSupply() + amount <= cap(), "ERC777Capped: cap exceeded");
    super._mint(account, amount, userData, operatorData);
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  //@dev governance
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

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

  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

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
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying (not scaled);
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

  function _move(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;

    emit Sent(operator, from, to, amount, userData, operatorData);
    emit Transfer(from, to, amount);

    _moveDelegates(address(0), _delegates[to], amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC777.sol";
import "./interfaces/IERC777Recipient.sol";
import "./interfaces/IERC777Sender.sol";
import "./interfaces/IERC20.sol";
import "../../libraries/Context.sol";
import "./introspection/IERC1820Registry.sol";
import "../../libraries/SafeMath.sol";
import "../../libraries/Address.sol";
import "../../access/Owner.sol";
import "../../security/Pausable.sol";

contract ERC777 is Context, IERC777, IERC20, Pausable, Ownable {
  using Address for address;
  using SafeMath for uint256;

  IERC1820Registry internal constant _ERC1820_REGISTRY =
    IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  mapping(address => uint256) public _balances;

  uint256 public _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimal;

  bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
    keccak256("ERC777TokensSender");
  bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
    keccak256("ERC777TokensRecipient");

  // This isn't ever read from - it's only used to respond to the defaultOperators query.
  address[] private _defaultOperatorsArray;

  // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
  mapping(address => bool) private _defaultOperators;

  // For each account, a mapping of its operators and revoked default operators.
  mapping(address => mapping(address => bool)) private _operators;
  mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

  // ERC20-allowances
  mapping(address => mapping(address => uint256)) private _allowances;

  /**
   * @dev `defaultOperators` may be an empty array.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimal_,
    address[] memory defaultOperators_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimal = decimal_;
    _defaultOperatorsArray = defaultOperators_;
    for (uint256 i = 0; i < defaultOperators_.length; i++) {
      _defaultOperators[defaultOperators_[i]] = true;
    }

    // register interfaces
    _ERC1820_REGISTRY.setInterfaceImplementer(
      address(this),
      keccak256("ERC777Token"),
      address(this)
    );
    _ERC1820_REGISTRY.setInterfaceImplementer(
      address(this),
      keccak256("ERC20Token"),
      address(this)
    );
  }

  /**
   * @dev See {IERC777-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC777-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {ERC20-decimals}.
   *
   * Always returns 18, as per the
   * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
   */
  function decimals() public view virtual returns (uint8) {
    return _decimal;
  }

  /**
   * @dev See {IERC777-granularity}.
   *
   * This implementation always returns `1`.
   */
  function granularity() public view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @dev See {IERC777-totalSupply}.
   */
  function totalSupply()
    public
    view
    virtual
    override(IERC20, IERC777)
    returns (uint256)
  {
    return _totalSupply;
  }

  /**
   * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
   */
  function balanceOf(address tokenHolder)
    public
    view
    virtual
    override(IERC20, IERC777)
    returns (uint256)
  {
    return _balances[tokenHolder];
  }

  /**
   * @dev See {IERC777-send}.
   *
   * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
   */
  function send(
    address recipient,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    _send(_msgSender(), recipient, amount, data, "", true);
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
   * interface if it is a contract.
   *
   * Also emits a {Sent} event.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    require(recipient != address(0), "ERC777: transfer to the zero address");

    address from = _msgSender();

    _callTokensToSend(from, from, recipient, amount, "", "");

    _move(from, from, recipient, amount, "", "");

    _callTokensReceived(from, from, recipient, amount, "", "", false);

    return true;
  }

  /**
   * @dev See {IERC777-burn}.
   *
   * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
   */
  function burn(uint256 amount, bytes memory data)
    public
    virtual
    override
  {
    require(owner() == _msgSender(), "ERC777: caller is not owner");
    _burn(_msgSender(), amount, data, "");
  }

  /**
   * @dev See {IERC777-isOperatorFor}.
   */
  function isOperatorFor(address operator, address tokenHolder)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      operator == tokenHolder ||
      (_defaultOperators[operator] &&
        !_revokedDefaultOperators[tokenHolder][operator]) ||
      _operators[tokenHolder][operator];
  }

  /**
   * @dev See {IERC777-authorizeOperator}.
   */
  function authorizeOperator(address operator) public virtual override {
    require(_msgSender() != operator, "ERC777: authorizing self as operator");

    if (_defaultOperators[operator]) {
      delete _revokedDefaultOperators[_msgSender()][operator];
    } else {
      _operators[_msgSender()][operator] = true;
    }

    emit AuthorizedOperator(operator, _msgSender());
  }

  /**
   * @dev See {IERC777-revokeOperator}.
   */
  function revokeOperator(address operator) public virtual override {
    require(operator != _msgSender(), "ERC777: revoking self as operator");

    if (_defaultOperators[operator]) {
      _revokedDefaultOperators[_msgSender()][operator] = true;
    } else {
      delete _operators[_msgSender()][operator];
    }

    emit RevokedOperator(operator, _msgSender());
  }

  /**
   * @dev See {IERC777-defaultOperators}.
   */
  function defaultOperators()
    public
    view
    virtual
    override
    returns (address[] memory)
  {
    return _defaultOperatorsArray;
  }

  /**
   * @dev See {IERC777-operatorSend}.
   *
   * Emits {Sent} and {IERC20-Transfer} events.
   */
  function operatorSend(
    address sender,
    address recipient,
    uint256 amount,
    bytes memory data,
    bytes memory operatorData
  ) public virtual override {
    require(
      isOperatorFor(_msgSender(), sender),
      "ERC777: caller is not an operator for holder"
    );
    _send(sender, recipient, amount, data, operatorData, true);
  }

  /**
   * @dev See {IERC777-operatorBurn}.
   *
   * Emits {Burned} and {IERC20-Transfer} events.
   */
  function operatorBurn(
    address account,
    uint256 amount,
    bytes memory data,
    bytes memory operatorData
  ) public virtual override {
    require(
      isOperatorFor(_msgSender(), account),
      "ERC777: caller is not an operator for holder"
    );
    _burn(account, amount, data, operatorData);
  }

  /**
   * @dev See {IERC20-allowance}.
   *
   * Note that operator and allowance concepts are orthogonal: operators may
   * not have allowance, and accounts with allowance may not be operators
   * themselves.
   */
  function allowance(address holder, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[holder][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Note that accounts cannot have allowance issued by their operators.
   */
  function approve(address spender, uint256 value)
    public
    virtual
    override
    returns (bool)
  {
    address holder = _msgSender();
    _approve(holder, spender, value);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Note that operator and allowance concepts are orthogonal: operators cannot
   * call `transferFrom` (unless they have allowance), and accounts with
   * allowance cannot call `operatorSend` (unless they are operators).
   *
   * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
   */
  function transferFrom(
    address holder,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    require(recipient != address(0), "ERC777: transfer to the zero address");
    require(holder != address(0), "ERC777: transfer from the zero address");

    address spender = _msgSender();

    _callTokensToSend(spender, holder, recipient, amount, "", "");

    _move(spender, holder, recipient, amount, "", "");

    uint256 currentAllowance = _allowances[holder][spender];
    require(
      currentAllowance >= amount,
      "ERC777: transfer amount exceeds allowance"
    );
    _approve(holder, spender, currentAllowance - amount);

    _callTokensReceived(spender, holder, recipient, amount, "", "", false);

    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * If a send hook is registered for `account`, the corresponding function
   * will be called with `operator`, `data` and `operatorData`.
   *
   * See {IERC777Sender} and {IERC777Recipient}.
   *
   * Emits {Minted} and {IERC20-Transfer} events.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - if `account` is a contract, it must implement the {IERC777Recipient}
   * interface.
   */
  function _mint(
    address account,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal virtual {
    _mint(account, amount, userData, operatorData, true);
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * If `requireReceptionAck` is set to true, and if a send hook is
   * registered for `account`, the corresponding function will be called with
   * `operator`, `data` and `operatorData`.
   *
   * See {IERC777Sender} and {IERC777Recipient}.
   *
   * Emits {Minted} and {IERC20-Transfer} events.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - if `account` is a contract, it must implement the {IERC777Recipient}
   * interface.
   */
  function _mint(
    address account,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData,
    bool requireReceptionAck
  ) internal virtual {
    require(account != address(0), "ERC777: mint to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), account, amount);

    // Update state variables
    _totalSupply += amount;
    _balances[account] += amount;

    _callTokensReceived(
      operator,
      address(0),
      account,
      amount,
      userData,
      operatorData,
      requireReceptionAck
    );

    emit Minted(operator, account, amount, userData, operatorData);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Send tokens
   * @param from address token holder address
   * @param to address recipient address
   * @param amount uint256 amount of tokens to transfer
   * @param userData bytes extra information provided by the token holder (if any)
   * @param operatorData bytes extra information provided by the operator (if any)
   * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
   */
  function _send(
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData,
    bool requireReceptionAck
  ) internal virtual {
    require(from != address(0), "ERC777: send from the zero address");
    require(to != address(0), "ERC777: send to the zero address");

    address operator = _msgSender();

    _callTokensToSend(operator, from, to, amount, userData, operatorData);

    _move(operator, from, to, amount, userData, operatorData);

    _callTokensReceived(
      operator,
      from,
      to,
      amount,
      userData,
      operatorData,
      requireReceptionAck
    );
  }

  /**
   * @dev Burn tokens
   * @param from address token holder address
   * @param amount uint256 amount of tokens to burn
   * @param data bytes extra information provided by the token holder
   * @param operatorData bytes extra information provided by the operator (if any)
   */
  function _burn(
    address from,
    uint256 amount,
    bytes memory data,
    bytes memory operatorData
  ) internal virtual {
    require(from != address(0), "ERC777: burn from the zero address");

    address operator = _msgSender();

    _callTokensToSend(operator, from, address(0), amount, data, operatorData);

    _beforeTokenTransfer(operator, from, address(0), amount);

    // Update state variables
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _totalSupply -= amount;

    emit Burned(operator, from, amount, data, operatorData);
    emit Transfer(from, address(0), amount);
  }

  function _move(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal virtual {
    _beforeTokenTransfer(operator, from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;

    emit Sent(operator, from, to, amount, userData, operatorData);
    emit Transfer(from, to, amount);
  }

  /**
   * @dev See {ERC20-_approve}.
   *
   * Note that accounts cannot have allowance issued by their operators.
   */
  function _approve(
    address holder,
    address spender,
    uint256 value
  ) internal {
    require(holder != address(0), "ERC777: approve from the zero address");
    require(spender != address(0), "ERC777: approve to the zero address");

    _allowances[holder][spender] = value;
    emit Approval(holder, spender, value);
  }

  /**
   * @dev Call from.tokensToSend() if the interface is registered
   * @param operator address operator requesting the transfer
   * @param from address token holder address
   * @param to address recipient address
   * @param amount uint256 amount of tokens to transfer
   * @param userData bytes extra information provided by the token holder (if any)
   * @param operatorData bytes extra information provided by the operator (if any)
   */
  function _callTokensToSend(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) private {
    address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(
      from,
      _TOKENS_SENDER_INTERFACE_HASH
    );
    if (implementer != address(0)) {
      IERC777Sender(implementer).tokensToSend(
        operator,
        from,
        to,
        amount,
        userData,
        operatorData
      );
    }
  }

  /**
   * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
   * tokensReceived() was not registered for the recipient
   * @param operator address operator requesting the transfer
   * @param from address token holder address
   * @param to address recipient address
   * @param amount uint256 amount of tokens to transfer
   * @param userData bytes extra information provided by the token holder (if any)
   * @param operatorData bytes extra information provided by the operator (if any)
   * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
   */
  function _callTokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData,
    bool requireReceptionAck
  ) private {
    address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(
      to,
      _TOKENS_RECIPIENT_INTERFACE_HASH
    );
    if (implementer != address(0)) {
      IERC777Recipient(implementer).tokensReceived(
        operator,
        from,
        to,
        amount,
        userData,
        operatorData
      );
    } else if (requireReceptionAck) {
      require(
        !to.isContract(),
        "ERC777: token recipient contract has no implementer for ERC777TokensRecipient"
      );
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes
   * calls to {send}, {transfer}, {operatorSend}, minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the smallest part of the token that is not divisible. This
   * means all token operations (creation, movement and destruction) must have
   * amounts that are a multiple of this number.
   *
   * For most token contracts, this value will equal 1.
   */
  function granularity() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by an account (`owner`).
   */
  function balanceOf(address owner) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * If send or receive hooks are registered for the caller and `recipient`,
   * the corresponding functions will be called with `data` and empty
   * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
   *
   * Emits a {Sent} event.
   *
   * Requirements
   *
   * - the caller must have at least `amount` tokens.
   * - `recipient` cannot be the zero address.
   * - if `recipient` is a contract, it must implement the {IERC777Recipient}
   * interface.
   */
  function send(
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Destroys `amount` tokens from the caller's account, reducing the
   * total supply.
   *
   * If a send hook is registered for the caller, the corresponding function
   * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
   *
   * Emits a {Burned} event.
   *
   * Requirements
   *
   * - the caller must have at least `amount` tokens.
   */
  function burn(uint256 amount, bytes calldata data) external;

  /**
   * @dev Returns true if an account is an operator of `tokenHolder`.
   * Operators can send and burn tokens on behalf of their owners. All
   * accounts are their own operator.
   *
   * See {operatorSend} and {operatorBurn}.
   */
  function isOperatorFor(address operator, address tokenHolder)
    external
    view
    returns (bool);

  /**
   * @dev Make an account an operator of the caller.
   *
   * See {isOperatorFor}.
   *
   * Emits an {AuthorizedOperator} event.
   *
   * Requirements
   *
   * - `operator` cannot be calling address.
   */
  function authorizeOperator(address operator) external;

  /**
   * @dev Revoke an account's operator status for the caller.
   *
   * See {isOperatorFor} and {defaultOperators}.
   *
   * Emits a {RevokedOperator} event.
   *
   * Requirements
   *
   * - `operator` cannot be calling address.
   */
  function revokeOperator(address operator) external;

  /**
   * @dev Returns the list of default operators. These accounts are operators
   * for all token holders, even if {authorizeOperator} was never called on
   * them.
   *
   * This list is immutable, but individual holders may revoke these via
   * {revokeOperator}, in which case {isOperatorFor} will return false.
   */
  function defaultOperators() external view returns (address[] memory);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
   * be an operator of `sender`.
   *
   * If send or receive hooks are registered for `sender` and `recipient`,
   * the corresponding functions will be called with `data` and
   * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
   *
   * Emits a {Sent} event.
   *
   * Requirements
   *
   * - `sender` cannot be the zero address.
   * - `sender` must have at least `amount` tokens.
   * - the caller must be an operator for `sender`.
   * - `recipient` cannot be the zero address.
   * - if `recipient` is a contract, it must implement the {IERC777Recipient}
   * interface.
   */
  function operatorSend(
    address sender,
    address recipient,
    uint256 amount,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the total supply.
   * The caller must be an operator of `account`.
   *
   * If a send hook is registered for `account`, the corresponding function
   * will be called with `data` and `operatorData`. See {IERC777Sender}.
   *
   * Emits a {Burned} event.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   * - the caller must be an operator for `account`.
   */
  function operatorBurn(
    address account,
    uint256 amount,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );

  event Minted(
    address indexed operator,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );

  event Burned(
    address indexed operator,
    address indexed from,
    uint256 amount,
    bytes data,
    bytes operatorData
  );

  event AuthorizedOperator(
    address indexed operator,
    address indexed tokenHolder
  );

  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
  /**
   * @dev Called by an {IERC777} token contract whenever tokens are being
   * moved or created into a registered account (`to`). The type of operation
   * is conveyed by `from` being the zero address or not.
   *
   * This call occurs _after_ the token contract's state is updated, so
   * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
   *
   * This function may revert to prevent the operation from being executed.
   */
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
  /**
   * @dev Called by an {IERC777} token contract whenever a registered holder's
   * (`from`) tokens are about to be moved or destroyed. The type of operation
   * is conveyed by `to` being the zero address or not.
   *
   * This call occurs _before_ the token contract's state is updated, so
   * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
   *
   * This function may revert to prevent the operation from being executed.
   */
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
  /**
   * @dev Sets `newManager` as the manager for `account`. A manager of an
   * account is able to set interface implementers for it.
   *
   * By default, each account is its own manager. Passing a value of `0x0` in
   * `newManager` will reset the manager to this initial state.
   *
   * Emits a {ManagerChanged} event.
   *
   * Requirements:
   *
   * - the caller must be the current manager for `account`.
   */
  function setManager(address account, address newManager) external;

  /**
   * @dev Returns the manager for `account`.
   *
   * See {setManager}.
   */
  function getManager(address account) external view returns (address);

  /**
   * @dev Sets the `implementer` contract as ``account``'s implementer for
   * `interfaceHash`.
   *
   * `account` being the zero address is an alias for the caller's address.
   * The zero address can also be used in `implementer` to remove an old one.
   *
   * See {interfaceHash} to learn how these are created.
   *
   * Emits an {InterfaceImplementerSet} event.
   *
   * Requirements:
   *
   * - the caller must be the current manager for `account`.
   * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
   * end in 28 zeroes).
   * - `implementer` must implement {IERC1820Implementer} and return true when
   * queried for support, unless `implementer` is the caller. See
   * {IERC1820Implementer-canImplementInterfaceForAddress}.
   */
  function setInterfaceImplementer(
    address account,
    bytes32 _interfaceHash,
    address implementer
  ) external;

  /**
   * @dev Returns the implementer of `interfaceHash` for `account`. If no such
   * implementer is registered, returns the zero address.
   *
   * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
   * zeroes), `account` will be queried for support of it.
   *
   * `account` being the zero address is an alias for the caller's address.
   */
  function getInterfaceImplementer(address account, bytes32 _interfaceHash)
    external
    view
    returns (address);

  /**
   * @dev Returns the interface hash for an `interfaceName`, as defined in the
   * corresponding
   * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
   */
  function interfaceHash(string calldata interfaceName)
    external
    pure
    returns (bytes32);

  /**
   * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
   * @param account Address of the contract for which to update the cache.
   * @param interfaceId ERC165 interface for which to update the cache.
   */
  function updateERC165Cache(address account, bytes4 interfaceId) external;

  /**
   * @notice Checks whether a contract implements an ERC165 interface or not.
   * If the result is not cached a direct lookup on the contract address is performed.
   * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
   * {updateERC165Cache} with the contract address.
   * @param account Address of the contract to check.
   * @param interfaceId ERC165 interface to check.
   * @return True if `account` implements `interfaceId`, false otherwise.
   */
  function implementsERC165Interface(address account, bytes4 interfaceId)
    external
    view
    returns (bool);

  /**
   * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
   * @param account Address of the contract to check.
   * @param interfaceId ERC165 interface to check.
   * @return True if `account` implements `interfaceId`, false otherwise.
   */
  function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId)
    external
    view
    returns (bool);

  event InterfaceImplementerSet(
    address indexed account,
    bytes32 indexed interfaceHash,
    address indexed implementer
  );

  event ManagerChanged(address indexed account, address indexed newManager);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
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
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Context.sol";

contract Pausable is Context {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function checkPaused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!checkPaused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(checkPaused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}