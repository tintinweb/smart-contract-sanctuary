/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface ILosslessController {
  function beforeTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function beforeTransferFrom(
    address msgSender,
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function beforeApprove(
    address sender,
    address spender,
    uint256 amount
  ) external;

  function beforeIncreaseAllowance(
    address msgSender,
    address spender,
    uint256 addedValue
  ) external;

  function beforeDecreaseAllowance(
    address msgSender,
    address spender,
    uint256 subtractedValue
  ) external;

  function afterApprove(
    address sender,
    address spender,
    uint256 amount
  ) external;

  function afterTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function afterTransferFrom(
    address msgSender,
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function afterIncreaseAllowance(
    address sender,
    address spender,
    uint256 addedValue
  ) external;

  function afterDecreaseAllowance(
    address sender,
    address spender,
    uint256 subtractedValue
  ) external;
}

contract AAGToken is Context, IERC20 {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  string private constant NAME = "AAG";
  string private constant SYMBOL = "AAG";

  address public recoveryAdmin;
  address private recoveryAdminCanditate;
  bytes32 private recoveryAdminKeyHash;
  address public admin;
  uint256 public timelockPeriod;
  uint256 public losslessTurnOffTimestamp;
  bool public isLosslessTurnOffProposed;
  bool public isLosslessOn = true;
  ILosslessController private lossless;

  event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event RecoveryAdminChangeProposed(address indexed candidate);
  event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event LosslessTurnOffProposed(uint256 turnOffDate);
  event LosslessTurnedOff();
  event LosslessTurnedOn();

  uint256 private constant _TOTAL_SUPPLY = 1000000000e18; // Initial supply 1 000 000 000
  bool private initialPoolClaimed = false;

  constructor(
    address admin_,
    address recoveryAdmin_,
    uint256 timelockPeriod_,
    address lossless_,
    bool losslessOn
  ) {
    _mint(address(this), _TOTAL_SUPPLY);
    admin = admin_;
    recoveryAdmin = recoveryAdmin_;
    timelockPeriod = timelockPeriod_;
    isLosslessOn = losslessOn;
    lossless = ILosslessController(lossless_);
  }

  // AAG unlocked tokens claiming

  function claimTokens() public onlyRecoveryAdmin {
    require(initialPoolClaimed == false, "Already claimed");
    initialPoolClaimed = true;
    _transfer(address(this), admin, _TOTAL_SUPPLY);
  }

  // --- LOSSLESS modifiers ---

  modifier lssAprove(address spender, uint256 amount) {
    if (isLosslessOn) {
      lossless.beforeApprove(_msgSender(), spender, amount);
      _;
      lossless.afterApprove(_msgSender(), spender, amount);
    } else {
      _;
    }
  }

  modifier lssTransfer(address recipient, uint256 amount) {
    if (isLosslessOn) {
      lossless.beforeTransfer(_msgSender(), recipient, amount);
      _;
      lossless.afterTransfer(_msgSender(), recipient, amount);
    } else {
      _;
    }
  }

  modifier lssTransferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) {
    if (isLosslessOn) {
      lossless.beforeTransferFrom(_msgSender(), sender, recipient, amount);
      _;
      lossless.afterTransferFrom(_msgSender(), sender, recipient, amount);
    } else {
      _;
    }
  }

  modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
    if (isLosslessOn) {
      lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
      _;
      lossless.afterIncreaseAllowance(_msgSender(), spender, addedValue);
    } else {
      _;
    }
  }

  modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
    if (isLosslessOn) {
      lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
      _;
      lossless.afterDecreaseAllowance(_msgSender(), spender, subtractedValue);
    } else {
      _;
    }
  }

  modifier onlyRecoveryAdmin() {
    require(_msgSender() == recoveryAdmin, "ERC20: Must be recovery admin");
    _;
  }

  // --- LOSSLESS management ---

  function getAdmin() external view returns (address) {
    return admin;
  }

  function transferOutBlacklistedFunds(address[] calldata from) external {
    require(_msgSender() == address(lossless), "ERC20: Only lossless contract");
    for (uint256 i = 0; i < from.length; i++) {
      _transfer(from[i], address(lossless), balanceOf(from[i]));
    }
  }

  function setLosslessAdmin(address newAdmin) public onlyRecoveryAdmin {
    emit AdminChanged(admin, newAdmin);
    admin = newAdmin;
  }

  function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) public onlyRecoveryAdmin {
    recoveryAdminCanditate = candidate;
    recoveryAdminKeyHash = keyHash;
    emit RecoveryAdminChangeProposed(candidate);
  }

  function acceptRecoveryAdminOwnership(bytes memory key) external {
    require(_msgSender() == recoveryAdminCanditate, "ERC20: Must be canditate");
    require(keccak256(key) == recoveryAdminKeyHash, "ERC20: Invalid key");
    emit RecoveryAdminChanged(recoveryAdmin, recoveryAdminCanditate);
    recoveryAdmin = recoveryAdminCanditate;
  }

  function proposeLosslessTurnOff() public onlyRecoveryAdmin {
    losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
    isLosslessTurnOffProposed = true;
    emit LosslessTurnOffProposed(losslessTurnOffTimestamp);
  }

  function executeLosslessTurnOff() public onlyRecoveryAdmin {
    require(isLosslessTurnOffProposed, "ERC20: TurnOff not proposed");
    require(losslessTurnOffTimestamp <= block.timestamp, "ERC20: Time lock in progress");
    isLosslessOn = false;
    isLosslessTurnOffProposed = false;
    emit LosslessTurnedOff();
  }

  function executeLosslessTurnOn() public onlyRecoveryAdmin {
    isLosslessTurnOffProposed = false;
    isLosslessOn = true;
    emit LosslessTurnedOn();
  }

  // --- ERC20 methods ---

  function name() public view virtual returns (string memory) {
    return NAME;
  }

  function symbol() public view virtual returns (string memory) {
    return SYMBOL;
  }

  function decimals() public view virtual returns (uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override lssTransfer(recipient, amount) returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override lssAprove(spender, amount) returns (bool) {
    require((amount == 0) || (_allowances[_msgSender()][spender] == 0), "ERC20: Cannot change non zero allowance");
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override lssTransferFrom(sender, recipient, amount) returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual lssIncreaseAllowance(spender, addedValue) returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual lssDecreaseAllowance(spender, subtractedValue) returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
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
}