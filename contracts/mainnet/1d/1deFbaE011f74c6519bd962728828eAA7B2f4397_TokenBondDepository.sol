// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;

  function pushManagement(address newOwner_) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {
  address internal _owner;
  address internal _newOwner;

  event OwnershipPushed(
    address indexed previousOwner,
    address indexed newOwner
  );
  event OwnershipPulled(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipPushed(address(0), _owner);
  }

  function policy() public view override returns (address) {
    return _owner;
  }

  modifier onlyPolicy() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceManagement() public virtual override onlyPolicy {
    emit OwnershipPushed(_owner, address(0));
    _owner = address(0);
  }

  function pushManagement(address newOwner_)
    public
    virtual
    override
    onlyPolicy
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipPushed(_owner, newOwner_);
    _newOwner = newOwner_;
  }

  function pullManagement() public virtual override {
    require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
    emit OwnershipPulled(_owner, _newOwner);
    _owner = _newOwner;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
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
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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
    return _functionCallWithValue(target, data, 0, errorMessage);
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

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
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

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
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

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

  function addressToString(address _address)
    internal
    pure
    returns (string memory)
  {
    bytes32 _bytes = bytes32(uint256(_address));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

interface IERC20 {
  function decimals() external view returns (uint8);

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

abstract contract ERC20 is IERC20 {
  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
    keccak256("ERC20Token");

  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 internal _totalSupply;

  string internal _name;

  string internal _symbol;

  uint8 internal _decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
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
    _transfer(msg.sender, recipient, amount);
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
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
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

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account_, uint256 ammount_) internal virtual {
    require(account_ != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(this), account_, ammount_);
    _totalSupply = _totalSupply.add(ammount_);
    _balances[account_] = _balances[account_].add(ammount_);
    emit Transfer(address(this), account_, ammount_);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
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
    address from_,
    address to_,
    uint256 amount_
  ) internal virtual {}
}

interface IERC2612Permit {
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function nonces(address owner) external view returns (uint256);
}

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public DOMAIN_SEPARATOR;

  constructor() {
    uint256 chainID;
    assembly {
      chainID := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );
  }

  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "Permit: expired deadline");

    bytes32 hashStruct = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        amount,
        _nonces[owner].current(),
        deadline
      )
    );

    bytes32 _hash = keccak256(
      abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
    );

    address signer = ecrecover(_hash, v, r, s);
    require(
      signer != address(0) && signer == owner,
      "ZeroSwapPermit: Invalid signature"
    );

    _nonces[owner].increment();
    _approve(owner, spender, amount);
  }

  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

library FullMath {
  function fullMul(uint256 x, uint256 y)
    private
    pure
    returns (uint256 l, uint256 h)
  {
    uint256 mm = mulmod(x, y, uint256(-1));
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = d & -d;
    d /= pow2;
    l /= pow2;
    l += h * ((-pow2) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;
    require(h < d, "FullMath::mulDiv: overflow");
    return fullDiv(l, h, d);
  }
}

library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= uint144(-1)) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface ITreasury {
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external returns (bool);

  function updateReserve(address _token, uint256 _amount) external;

  function valueOfToken(address _token, uint256 _amount)
    external
    view
    returns (uint256 value_);

  function mintRewards(address _recipient, uint256 _amount) external;
}

interface IStaking {
  function stake(uint256 _amount, address _recipient) external returns (bool);
}

interface IStakingHelper {
  function stake(uint256 _amount, address _recipient) external;
}

contract TokenBondDepository is Ownable {
  using FixedPoint for *;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ======== EVENTS ======== */

  event BondCreated(
    uint256 deposit,
    uint256 indexed payout,
    uint256 indexed expires,
    uint256 indexed priceInUSD
  );
  event BondRedeemed(
    address indexed recipient,
    uint256 payout,
    uint256 remaining
  );
  event BondPriceChanged(
    uint256 indexed priceInUSD,
    uint256 indexed internalPrice,
    uint256 indexed debtRatio
  );
  event ControlVariableAdjustment(
    uint256 initialBCV,
    uint256 newBCV,
    uint256 adjustment,
    bool addition
  );

  /* ======== STATE VARIABLES ======== */

  address public immutable DMND; // token given as payment for bond
  address public immutable principle; // token used to create bond
  address public immutable treasury; // mints DMND when receives principle
  address public DAO; // receives profit share from bond
  address public partnerDAO; // receives profit share from bond

  AggregatorV3Interface internal priceFeed;

  address public staking; // to auto-stake payout
  address public stakingHelper; // to stake and claim if no staking warmup
  bool public useHelper;

  Terms public terms; // stores terms for new bonds
  Adjust public adjustment; // stores adjustment to BCV data

  mapping(address => Bond) public bondInfo; // stores bond information for depositors

  uint256 public totalDebt; // total value of outstanding bonds; used for pricing
  uint256 public lastDecay; // reference block for debt decay

  /* ======== STRUCTS ======== */

  // Info for creating new bonds
  struct Terms {
    uint256 controlVariable; // scaling variable for price
    uint256 vestingTerm; // in blocks
    uint256 minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
    uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
    uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    uint256 feePartner; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
  }

  // Info for bond holder
  struct Bond {
    uint256 payout; // DMND remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
  }

  // Info for incremental adjustments to control variable
  struct Adjust {
    bool add; // addition or subtraction
    uint256 rate; // increment
    uint256 target; // BCV when adjustment finished
    uint256 buffer; // minimum length (in blocks) between adjustments
    uint256 lastBlock; // block when last adjustment made
  }

  /* ======== INITIALIZATION ======== */

  constructor(
    address _DMND,
    address _principle,
    address _treasury,
    address _DAO,
    address _partnerDAO,
    address _feed
  ) {
    require(_DMND != address(0));
    DMND = _DMND;
    require(_principle != address(0));
    principle = _principle;
    require(_treasury != address(0));
    treasury = _treasury;
    require(_DAO != address(0));
    DAO = _DAO;
    require(_partnerDAO != address(0));
    partnerDAO = _partnerDAO;
    require(_feed != address(0));
    priceFeed = AggregatorV3Interface(_feed);
  }

  /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _vestingTerm uint
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _maxDebt uint
   *  @param _initialDebt uint
   */
  function initializeBondTerms(
    uint256 _controlVariable,
    uint256 _vestingTerm,
    uint256 _minimumPrice,
    uint256 _maxPayout,
    uint256 _maxDebt,
    uint256 _initialDebt,
    uint256 _fee,
    uint256 _feePartner
  ) external onlyPolicy {
    terms = Terms({
      controlVariable: _controlVariable,
      vestingTerm: _vestingTerm,
      minimumPrice: _minimumPrice,
      maxPayout: _maxPayout,
      maxDebt: _maxDebt,
      fee: _fee,
      feePartner: _feePartner
    });
    totalDebt = _initialDebt;
    lastDecay = block.number;
  }

  /* ======== POLICY FUNCTIONS ======== */

  enum PARAMETER {
    VESTING,
    PAYOUT,
    DEBT,
    FEE,
    FEEPARTNER
  }

  /**
   *  @notice set parameters for new bonds
   *  @param _parameter PARAMETER
   *  @param _input uint
   */
  function setBondTerms(PARAMETER _parameter, uint256 _input)
    external
    onlyPolicy
  {
    if (_parameter == PARAMETER.VESTING) {
      // 0
      require(_input >= 10000, "Vesting must be longer than 36 hours");
      terms.vestingTerm = _input;
    } else if (_parameter == PARAMETER.PAYOUT) {
      // 1
      require(_input <= 1000, "Payout cannot be above 1 percent");
      terms.maxPayout = _input;
    } else if (_parameter == PARAMETER.DEBT) {
      // 2
      terms.maxDebt = _input;
    } else if (_parameter == PARAMETER.FEE) {
      // 3
      terms.fee = _input;
    } else if (_parameter == PARAMETER.FEEPARTNER) {
      // 4
      terms.feePartner = _input;
    }
  }

  /**
   *  @notice set control variable adjustment
   *  @param _addition bool
   *  @param _increment uint
   *  @param _target uint
   *  @param _buffer uint
   */
  function setAdjustment(
    bool _addition,
    uint256 _increment,
    uint256 _target,
    uint256 _buffer
  ) external onlyPolicy {
    require(
      _increment <= terms.controlVariable.mul(25).div(1000),
      "Increment too large"
    );

    adjustment = Adjust({
      add: _addition,
      rate: _increment,
      target: _target,
      buffer: _buffer,
      lastBlock: block.number
    });
  }

  /**
   *  @notice set contract for auto stake
   *  @param _staking address
   *  @param _helper bool
   */
  function setStaking(address _staking, bool _helper) external onlyPolicy {
    require(_staking != address(0));
    if (_helper) {
      useHelper = true;
      stakingHelper = _staking;
    } else {
      useHelper = false;
      staking = _staking;
    }
  }

  /* ======== USER FUNCTIONS ======== */

  /**
   *  @notice deposit bond
   *  @param _amount uint
   *  @param _maxPrice uint
   *  @param _depositor address
   *  @return uint
   */
  function deposit(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) external returns (uint256) {
    require(_depositor != address(0), "Invalid address");

    decayDebt();
    require(totalDebt <= terms.maxDebt, "Max capacity reached");

    uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
    uint256 nativePrice = _bondPrice();

    require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

    uint256 value = ITreasury(treasury).valueOfToken(principle, _amount);
    uint256 payout = payoutFor(value); // payout to bonder is computed

    require(payout >= 10000000, "Bond too small"); // must be > 0.01 DMND ( underflow protection )
    require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

    // profits are calculated
    uint256 fee = payout.mul(terms.fee).div(10000);
    uint256 feePartner = payout.mul(terms.feePartner).div(10000);

    /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
    IERC20(principle).safeTransferFrom(msg.sender, treasury, _amount);

    ITreasury(treasury).updateReserve(principle, value);
    ITreasury(treasury).mintRewards(
      address(this),
      payout.add(fee).add(feePartner)
    );

    if (fee != 0) {
      IERC20(DMND).safeTransfer(DAO, fee);
    }

    if (feePartner != 0) {
      IERC20(DMND).safeTransfer(partnerDAO, feePartner);
    }

    // total debt is increased
    totalDebt = totalDebt.add(value);

    // depositor info is stored
    bondInfo[_depositor] = Bond({
      payout: bondInfo[_depositor].payout.add(payout),
      vesting: terms.vestingTerm,
      lastBlock: block.number,
      pricePaid: priceInUSD
    });

    // indexed events are emitted
    emit BondCreated(
      _amount,
      payout,
      block.number.add(terms.vestingTerm),
      priceInUSD
    );
    emit BondPriceChanged(bondPriceInUSD(), _bondPrice(), debtRatio());

    adjust(); // control variable is adjusted
    return payout;
  }

  /**
   *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint
   */
  function redeem(address _recipient, bool _stake) external returns (uint256) {
    Bond memory info = bondInfo[_recipient];
    uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

    if (percentVested >= 10000) {
      // if fully vested
      delete bondInfo[_recipient]; // delete user info
      emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
      return stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
    } else {
      // if unfinished
      // calculate payout vested
      uint256 payout = info.payout.mul(percentVested).div(10000);

      // store updated deposit info
      bondInfo[_recipient] = Bond({
        payout: info.payout.sub(payout),
        vesting: info.vesting.sub(block.number.sub(info.lastBlock)),
        lastBlock: block.number,
        pricePaid: info.pricePaid
      });

      emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
      return stakeOrSend(_recipient, _stake, payout);
    }
  }

  /* ======== INTERNAL HELPER FUNCTIONS ======== */

  /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   *  @return uint
   */
  function stakeOrSend(
    address _recipient,
    bool _stake,
    uint256 _amount
  ) internal returns (uint256) {
    if (!_stake) {
      // if user does not want to stake
      IERC20(DMND).transfer(_recipient, _amount); // send payout
    } else {
      // if user wants to stake
      if (useHelper) {
        // use if staking warmup is 0
        IERC20(DMND).approve(stakingHelper, _amount);
        IStakingHelper(stakingHelper).stake(_amount, _recipient);
      } else {
        IERC20(DMND).approve(staking, _amount);
        IStaking(staking).stake(_amount, _recipient);
      }
    }
    return _amount;
  }

  /**
   *  @notice makes incremental adjustment to control variable
   */
  function adjust() internal {
    uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
    if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
      uint256 initial = terms.controlVariable;
      if (adjustment.add) {
        terms.controlVariable = terms.controlVariable.add(adjustment.rate);
        if (terms.controlVariable >= adjustment.target) {
          adjustment.rate = 0;
        }
      } else {
        terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
        if (terms.controlVariable <= adjustment.target) {
          adjustment.rate = 0;
        }
      }
      adjustment.lastBlock = block.number;
      emit ControlVariableAdjustment(
        initial,
        terms.controlVariable,
        adjustment.rate,
        adjustment.add
      );
    }
  }

  /**
   *  @notice reduce total debt
   */
  function decayDebt() internal {
    totalDebt = totalDebt.sub(debtDecay());
    lastDecay = block.number;
  }

  /* ======== VIEW FUNCTIONS ======== */

  /**
   *  @notice determine maximum bond size
   *  @return uint
   */
  function maxPayout() public view returns (uint256) {
    return IERC20(DMND).totalSupply().mul(terms.maxPayout).div(100000);
  }

  /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
  function payoutFor(uint256 _value) public view returns (uint256) {
    return FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e14);
  }

  /**
   *  @notice calculate current bond premium
   *  @return price_ uint
   */
  function bondPrice() public view returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).div(1e5);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    }
  }

  /**
   *  @notice calculate current bond price and remove floor if above
   *  @return price_ uint
   */
  function _bondPrice() internal returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).div(1e5);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    } else if (terms.minimumPrice != 0) {
      terms.minimumPrice = 0;
    }
  }

  /**
   *  @notice get asset price from chainlink
   */
  function assetPrice() public view returns (int256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
  }

  /**
   *  @notice converts bond price to DAI value
   *  @return price_ uint
   */
  function bondPriceInUSD() public view returns (uint256 price_) {
    price_ = bondPrice().mul(uint256(assetPrice())).mul(1e6);
  }

  /**
   *  @notice calculate current ratio of debt to DMND supply
   *  @return debtRatio_ uint
   */
  function debtRatio() public view returns (uint256 debtRatio_) {
    uint256 supply = IERC20(DMND).totalSupply();
    debtRatio_ = FixedPoint
      .fraction(currentDebt().mul(1e9), supply)
      .decode112with18()
      .div(1e18);
  }

  /**
   *  @notice debt ratio in same terms as reserve bonds
   *  @return uint
   */
  function standardizedDebtRatio() external view returns (uint256) {
    return debtRatio().mul(uint256(assetPrice())).div(1e8); // ETH feed is 8 decimals
  }

  /**
   *  @notice calculate debt factoring in decay
   *  @return uint
   */
  function currentDebt() public view returns (uint256) {
    return totalDebt.sub(debtDecay());
  }

  /**
   *  @notice amount to decay total debt by
   *  @return decay_ uint
   */
  function debtDecay() public view returns (uint256 decay_) {
    uint256 blocksSinceLast = block.number.sub(lastDecay);
    decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
    if (decay_ > totalDebt) {
      decay_ = totalDebt;
    }
  }

  /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint
   */
  function percentVestedFor(address _depositor)
    public
    view
    returns (uint256 percentVested_)
  {
    Bond memory bond = bondInfo[_depositor];
    uint256 blocksSinceLast = block.number.sub(bond.lastBlock);
    uint256 vesting = bond.vesting;

    if (vesting > 0) {
      percentVested_ = blocksSinceLast.mul(10000).div(vesting);
    } else {
      percentVested_ = 0;
    }
  }

  /**
   *  @notice calculate amount of DMND available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint
   */
  function pendingPayoutFor(address _depositor)
    external
    view
    returns (uint256 pendingPayout_)
  {
    uint256 percentVested = percentVestedFor(_depositor);
    uint256 payout = bondInfo[_depositor].payout;

    if (percentVested >= 10000) {
      pendingPayout_ = payout;
    } else {
      pendingPayout_ = payout.mul(percentVested).div(10000);
    }
  }

  function setDAOs(address _DAO, address _partnerDAO) external onlyPolicy {
    DAO = _DAO;
    partnerDAO = _partnerDAO;
  }

  /* ======= AUXILLIARY ======= */

  /**
   *  @notice allow anyone to send lost tokens (excluding principle or DMND) to the DAO
   *  @return bool
   */
  function recoverLostToken(address _token) external returns (bool) {
    require(_token != DMND);
    require(_token != principle);
    IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    return true;
  }
}