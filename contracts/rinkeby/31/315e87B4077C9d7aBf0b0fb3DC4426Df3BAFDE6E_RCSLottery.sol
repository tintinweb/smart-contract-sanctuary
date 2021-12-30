// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

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
    _transferOwnership(_msgSender());
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
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract RCSLottery is Ownable {
  //constructor() {}

  using SafeMath for uint256;

  // 支援彩池的代币合约
  address public stakeToken= 0x4e2c31A1c277cc73C2384A8742e5D637463F5F40;

  function setstakeToken(address _stakeToken) public onlyOwner {
    stakeToken = _stakeToken;
  }

  // 彩池开奖所需要的总金额
  uint256 public bonusGate = 100000*1e18;

  function setBonusGate(uint256 _bonusGate) public onlyOwner {
    bonusGate = _bonusGate;
  }

  // 每张票多少代币（意味着总票数= 总金额/票价 ）
  uint256 public ticketPrice = 10000*1e18;

  function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
    ticketPrice = _ticketPrice;
  }

  // 几组数字
  uint256 public lottoNumbers = 5;

  function setLottoNumbers(uint256 _lottoNumbers) public onlyOwner {
    lottoNumbers = _lottoNumbers;
  }

  // 数字范围
  uint256 public maxLottoNumber = 32;

  //设定数字上限（不包括0）
  function setMaxLottoNumber(uint256 _maxLottoNumber) public onlyOwner {
    maxLottoNumber = _maxLottoNumber;
  }

  // 手续费率
  uint256 public feePercent = 5;

  //设定手续费
  function setFeePercent(uint256 _feePercent) public onlyOwner {
    feePercent = _feePercent;
  }

  //游戏是否可以开始玩
  bool public isSaleActive = true;

  //设定是否可以开始玩
  function setIsSaleActive(bool _isSaleActive) public onlyOwner {
    isSaleActive = _isSaleActive;
  }

  // 隐私，手续费分配Address（payable）跟分配率，mapping(address=>uint256)
  address[] private feeAllocation;

  //设定分配手续费的Address

  function setFeeAllocation(address _address)
    public
    onlyOwner
    returns (address[] memory)
  {
    feeAllocation.push(_address);
    return feeAllocation;
  }

  //删除分配手续费的Address

  function deleteFeeAllocation(uint256 _key)
    public
    onlyOwner
    returns (address[] memory)
  {
    delete feeAllocation[_key];
    return feeAllocation;
  }

  // 当前期数
  uint256 public currentSerial = 1;
  // 当前票数
  uint256 public currentTicket = 0;
  // 目前累积总额
  uint256 public totalBonus = 0;
  // 上期中奖号码及中奖人，中奖金额
  mapping(uint256 => address[]) public winnerRecordAddress;
  mapping(uint256 => uint256[]) public winnerRecordNumers;
  mapping(uint256 => uint256) public winnerRecordReward;

  // Salt，用来增加乱数复杂度，避免被预测
  uint256 private salt = 0;
  uint256 private nextBlockNumber = block.number;

  function updateSalt() private {
    uint256 _doitornot = dn(salt, 2);
    if (_doitornot == 0 && block.number >= nextBlockNumber) {
      salt = _seed(salt);
    }
    nextBlockNumber += (dn(salt, 30) + 1);
  }

  //取得指定范围的乱数
  function dn(uint256 _salt, uint256 _number) private view returns (uint256) {
    return _seed(_salt) % _number;
  }

  //将随机资料编码成数字
  function _random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  //产生随机种子字
  function _seed(uint256 _salt) internal view returns (uint256 rand) {
    rand = _random(
      string(
        abi.encodePacked(
          block.timestamp,
          blockhash(block.number - 1),
          _salt,
          msg.sender
        )
      )
    );
  }

  struct Ticket {
    address _Player;
    uint256[] _Numbers;
  }
  // A Mapping：序号KEY，address，选号（数组）
  mapping(uint256 => mapping(uint256 => Ticket)) private TicketRecordA;
  // B Mapping：选号（数组）Key，address（数组）
  mapping(uint256 => mapping(uint256 => address[])) private TicketRecordB;
  // C Mapping：address Key，选号（二维数组），记录一个adress买了多少票多少号（方便玩家查询自己买了哪些号）
  mapping(uint256 => mapping(address => uint256[][])) private TicketRecordC;

  //排序
  function insertion(uint256[] memory data)
    internal
    pure
    returns (uint256[] memory)
  {
    uint256 length = data.length;
    for (uint256 i = 1; i < length; i++) {
      uint256 key = data[i];
      uint256 j = i - 1;
      while ((int256(j) >= 0) && (data[j] > key)) {
        data[j + 1] = data[j];
        j--;
      }
      data[j + 1] = key;
    }
    return data;
  }

  function checkNumbers(uint256[] memory _Numbers)
    internal
    view
    returns (bool)
  {
    bool _bool = true;

    uint256 length = _Numbers.length;
    bool[] memory checkUniq = new bool[](maxLottoNumber+1);
    if (length != lottoNumbers) {
      _bool = false;
    } else {
      for (uint256 i = 1; i < length; i++) {
        uint256 key = _Numbers[i];

        if (checkUniq[key] == true || key > maxLottoNumber) {
          _bool = false;
        } else {
          checkUniq[key] = true;
        }
      }
    }
    return _bool;
  }

  //下注
  function bet(uint256[] memory _Numbers) external {
    require(checkNumbers(_Numbers) == true, "Numbers Error");
    require(isSaleActive == true, "Game has not begun yet");
    currentTicket+=1;
    totalBonus+=ticketPrice;
    // mapping(uint256 => mapping(uint256 => Ticket)) private
    uint256[] memory _SortNumber = insertion(_Numbers);
    IERC20(stakeToken).transferFrom(msg.sender, address(this), ticketPrice);
    Ticket memory _Ticket = Ticket(msg.sender, _SortNumber);
    TicketRecordA[currentSerial][currentTicket] = _Ticket;
    // mapping(uint256 => mapping(uint256 => address[])) private
    uint256 _SelectNumber = uint256(keccak256(abi.encodePacked(_SortNumber)));
    TicketRecordB[currentSerial][_SelectNumber].push(msg.sender);
    // mapping(uint256 => mapping(address => uint256[][])) private
    TicketRecordC[currentSerial][msg.sender].push(_SortNumber);

    if ((currentTicket >= (bonusGate / ticketPrice))) {
      prizeOpen();
    }
    updateSalt();
  }

  //开奖发钱
  function prizeOpen() private {
    require((currentTicket >= bonusGate / ticketPrice), "Not yet");
    uint256 _Winner = dn(salt, currentTicket) + 1;
    Ticket memory _WinnerTicket = TicketRecordA[currentSerial][_Winner];
    uint256 _WinnerNumber =
      uint256(keccak256(abi.encodePacked(_WinnerTicket._Numbers)));
    address[] memory _WinnerAddres =
      TicketRecordB[currentSerial][_WinnerNumber];

    uint256 PayoutReward;

    if (IERC20(stakeToken).balanceOf(address(this)) >= totalBonus) {
      PayoutReward = (totalBonus * (100 - feePercent)) / 100;
    } else {
      PayoutReward =
        ((IERC20(stakeToken).balanceOf(address(this))) * (100 - feePercent)) /
        100;
    }
    winnerRecordAddress[currentSerial] = _WinnerAddres;
    winnerRecordNumers[currentSerial] = _WinnerTicket._Numbers;
    winnerRecordReward[currentSerial] = (PayoutReward / _WinnerAddres.length);
    uint256 i = 0;
    while (i < _WinnerAddres.length) {
      IERC20(stakeToken).transfer(
        _WinnerAddres[i],
        PayoutReward / _WinnerAddres.length
      );
      i += 1;
    }

    i = 0;

    PayoutReward = (IERC20(stakeToken).balanceOf(address(this)));
    while (i < feeAllocation.length) {
      IERC20(stakeToken).transfer(
        feeAllocation[i],
        PayoutReward / feeAllocation.length
      );
      i += 1;
    }
    currentSerial+=1;
    currentTicket = 0;
    totalBonus = 0;
  }

  // 读取当期投注资料

  function getNumbers(address _address)
    public
    view
    returns (uint256[][] memory)
  {
    return TicketRecordC[currentSerial][_address];
  }
}