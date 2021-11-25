//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC20/ERC20Standards.sol";

library Config {
  uint256 constant fee_721_mint = 0.2 ether;
  uint256 constant fee_721_burn = 0.3 ether;
  uint256 constant fee_20 = 0.0001 ether;
  uint256 constant fee_223 = 0.00001 ether;
  uint256 constant fee_1155_mint = 0.02 ether;
  uint256 constant fee_1155_burn = 0.03 ether;
  uint256 constant fee_777 = 0.00001 ether;
}

contract MasterERC20Standards is Ownable {
  ERC20Standards[] private childrenERC20Standards;
  
  function createTokenERC20(
    string[] memory _types,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) external payable {
    require(
      keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked(("")))
    );
    require(
      keccak256(abi.encodePacked((symbol))) != keccak256(abi.encodePacked(("")))
    );

    require(
      msg.value >= Config.fee_20,
      "ERC20:value must be greater than 0.0001"
    );

    ERC20Standards child = new ERC20Standards(
      msg.sender,
      _types,
      name,
      symbol,
      decimal,
      initialSupply * 10**uint8(decimal),
      _cap
    );
    childrenERC20Standards.push(child);
  }

  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ERC20Standards is ERC20 {
  uint256 private cap_;
  mapping(bytes32 => uint32) private types;

  constructor(
    address _owner,
    string[] memory _types,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) ERC20(name, symbol, decimal) {
    require(_owner != address(0));
    for (uint256 index = 0; index < _types.length; index++) {
      types[keccak256(abi.encodePacked(_types[index]))] == 1;
    }
    cap_ = _cap * 10**uint8(decimal);
    _mint(_owner, initialSupply);
    transferOwnership(_owner);
  }

  modifier checkTypes(bytes32 _type) {
    if (types[_type] == 1) {
      _;
    }
  }

  //@dev Mintable
  function mint(address to, uint256 amount)
    public
    payable
    virtual
    checkTypes(keccak256(abi.encodePacked("Mintable")))
  {
    _mint(to, amount);

    if (types[keccak256(abi.encodePacked('Governance'))] == 1) {
      _moveDelegates(address(0), _delegates[to], amount);
    }
  }

  function cap() public view virtual returns (uint256) {
    return cap_;
  }

  function _mint(address account, uint256 amount) internal virtual override {
    require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
    super._mint(account, amount);
  }

  // @dev Burnable
  function burn(uint256 amount)
    public
    virtual
    checkTypes(keccak256(abi.encodePacked("Burnable")))
  {
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount)
    public
    virtual
    checkTypes(keccak256(abi.encodePacked("Burnable")))
  {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

  // @dev Pausable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override checkTypes(keccak256(abi.encodePacked('Pausable'))) {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable: token transfer while paused");
  }

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

  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  function delegate(address delegatee) external checkTypes(keccak256(abi.encodePacked('Governance'))) {
    return _delegate(msg.sender, delegatee);
  }

  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external checkTypes(keccak256(abi.encodePacked('Governance'))) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../libraries/Context.sol";
import "../../libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../../access/Ownable.sol";

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
  function paused() public view virtual returns (bool) {
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
    require(!paused(), "Pausable: paused");
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
    require(paused(), "Pausable: not paused");
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

contract ERC20 is
  Context,
  IERC20,
  IERC20Metadata,
  Ownable,
  Pausable
{
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
    virtual
    returns (bool)
  {
    require(account != address(0), "ERC20: withdrawal from the zero address");

    uint256 accountBalance = _balances[account];
    require(
      accountBalance >= amount,
      "ERC20: withdrawal amount exceeds balance"
    );

    _balances[account] = accountBalance - amount;

    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
    return true;
  }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";

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