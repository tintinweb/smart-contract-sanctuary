/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// File: contracts/libs/zeppelin/token/ERC20/IBEP20.sol

pragma solidity 0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IBEP20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/zeppelin/token/ERC20/IGDP.sol

pragma solidity 0.5.0;


contract IGDP is IBEP20 {
  function burn(uint _amount) external;
}

// File: contracts/libs/zeppelin/math/SafeMath.sol

pragma solidity 0.5.0;


library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - Subtraction cannot overflow.
   *
   * _Available since v2.4.0._
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
   * - The divisor cannot be zero.
   *
   * _Available since v2.4.0._
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   *
   * _Available since v2.4.0._
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/libs/dice/Auth.sol

pragma solidity 0.5.0;

contract Auth {

  address internal mainAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(address _mainAdmin) internal {
    mainAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(msg.sender == mainAdmin, "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// File: contracts/libs/dice/Math.sol

pragma solidity 0.5.0;

library Math {

  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function genRandomNumber(string memory _seed) internal view returns (uint) {
    return genRandomNumberInRange(_seed, 0, 99);
  }

  function genRandomNumberInRange(string memory _seed, uint8 _from, uint8 _to) internal view returns (uint) {
    require(_to > _from, 'Math: Invalid range');
    uint randomNumber = uint(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              block.timestamp,
              block.difficulty,
              msg.sender,
              now,
              _seed
            )
          )
        )
      )
    ) % (_to - _from + 1);
    return randomNumber + _from;
  }
}

// File: contracts/libs/dice/UnitConverter.sol

pragma solidity 0.5.0;

library UnitConverter {

  function toBytes(address _input) internal pure returns (bytes memory _output){
    assembly {
      let m := mload(0x40)
      _input := and(_input, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, _input))
      mstore(0x40, add(m, 52))
      _output := m
    }
  }
}

// File: contracts/interfaces/IJackPot.sol

pragma solidity 0.5.0;

interface IJackPot {
  function addTicket(address _user, string calldata _game, bool _isWin) external;
}

// File: contracts/LuckyNumber.sol

pragma solidity 0.5.0;







contract LuckyNumber is Auth {
  using SafeMath for uint;
  using Math for uint;
  using UnitConverter for address;

  uint private totalPayout;
  uint private totalBet;
  uint private losingBet;
  uint constant private multiplier = 985;
  string private seed;

  bool public systemInfoVisible = true;
  uint public minBetAmount = 10e18;
  uint public maxBetAmount = 500e18;
  uint public jackPotTicketCheckpoint = 20e18;
  uint public highRollCheckpoint = 100e18;
  uint public sharkCheckpoint = 10000e18;
  uint8 public rareWinCheckpoint = 40;
  int public dividend;
  IGDP public gdpToken = IGDP(0x33eb4d829a9c5224E25Eb828E2a11550308c885E);
  IJackPot public jackPot = IJackPot(0xe928eEBF6BdF422cE4154cf69A29f3c754bFcDD9);

  struct User {
    uint personalVolume;
    uint betCounter;
    uint balance;
    uint totalPayout;
  }

  enum BetType {
    Over,
    Under
  }

  mapping(address => User) public users;
  mapping (address => bool) private userAddressesChecker;
  uint public totalPlayers = 0;

  event Bet(
    address indexed player,
    uint indexed amount,
    uint32 indexed winRate,
    BetType betType,
    uint32 prediction,
    uint winningNumber,
    uint winningAmount,
    uint payout
  );
  event DividendBurned(uint amount);
  event MinBetSet(uint amount);
  event MaxBetSet(uint amount);
  event HighRollCheckpointSet(uint amount);
  event RareWinCheckpointSet(uint8 amount);
  event JackpotTicketCheckpointSet(uint amount);

  constructor(address _mainAdmin, string memory _seed)
  public
  Auth(_mainAdmin) {
    seed = _seed;
  }

  // ADMIN-FUNCTIONS

  function setSystemInfoVisibility(bool _visible) onlyMainAdmin public {
    systemInfoVisible = _visible;
  }

  function setMinBet(uint _amount) onlyMainAdmin public {
    require(_amount > 0, 'min bet must be > 0');
    minBetAmount = _amount;
    emit MinBetSet(_amount);
  }

  function setMaxBet(uint _amount) onlyMainAdmin public {
    require(_amount > minBetAmount, 'max bet must be > minBetAmount');
    maxBetAmount = _amount;
    emit MaxBetSet(_amount);
  }

  function setSharkCheckpoint(uint _amount) onlyMainAdmin public {
    require(_amount > maxBetAmount, 'shark must be > maxBetAmount');
    sharkCheckpoint = _amount;
  }

  function setHighRollCheckpoint(uint _amount) onlyMainAdmin public {
    require(_amount > 0, 'high roll must be > 0');
    highRollCheckpoint = _amount;
    emit HighRollCheckpointSet(_amount);
  }

  function setRareWinCheckpoint(uint8 _amount) onlyMainAdmin public {
    require(_amount >= 1 && _amount <= 95, 'rare win is invalid');
    rareWinCheckpoint = _amount;
    emit RareWinCheckpointSet(_amount);
  }

  function setJackpotTicketCheckpoint(uint _amount) onlyMainAdmin public {
    jackPotTicketCheckpoint = _amount;
    emit JackpotTicketCheckpointSet(_amount);
  }

  function provideDividend(uint _amount) public {
    require(gdpToken.transferFrom(msg.sender, address(this), _amount), 'LuckyNumber: transfer token failed');
    dividend += int(_amount);
  }

  function burnDividend() onlyMainAdmin public {
    require(dividend > 10, 'dividend amount is invalid');
    uint willBurnAmount = uint(dividend) / 10;
    dividend -= int(willBurnAmount);
    gdpToken.burn(willBurnAmount);
    emit DividendBurned(willBurnAmount);
  }

  function getLosingAmount() onlyMainAdmin public view returns (uint) {
    return losingBet;
  }

  function updateGameAdmin(address _newAdmin) onlyMainAdmin public {
    transferOwnership(_newAdmin);
  }

  function up() onlyMainAdmin public {
    gdpToken.transfer(msg.sender, gdpToken.balanceOf(address(this)));
  }

  // PUBLIC-FUNCTIONS

  function bet(BetType _type, uint8 _prediction, uint _amount, string memory _seed) public {
    require(_amount >= minBetAmount && _amount <= maxBetAmount, 'Betting amount is invalid');
    require(gdpToken.allowance(msg.sender, address(this)) >= _amount, 'You must call approve() first');
    require(gdpToken.transferFrom(msg.sender, address(this), _amount), 'Transfer token failed');
    require(int(_type) == 0 || int(_type) == 1, 'Betting type is invalid');

    trackUserAddress();

    uint winningNumber = Math.genRandomNumber(bytes(_seed).length > 0 ? _seed : seed);
    // TODO sharkCheckpoint
    uint8 winRate;
    uint winningAmount;
    bool haveExtractTokenToJackPot;
    bool isWin;
    User storage user = users[msg.sender];
    if (_type == BetType.Over) {
      require(_prediction >= 4 && _prediction <= 98, 'Prediction is invalid');
      isWin = winningNumber > _prediction;
      winRate = 99 - _prediction;
    } else {
      require(_prediction > 0 && _prediction <= 95, 'Prediction is invalid');
      isWin = winningNumber < _prediction;
      winRate = _prediction;
    }
    uint payout;
    if (isWin) {
      (winningAmount, haveExtractTokenToJackPot) = handleWinCase(user, _amount, winRate);
      payout = getPayoutAmount(_amount, haveExtractTokenToJackPot).add(winningAmount);
    } else {
      handleLoseCase(_amount);
    }

    updateUserData(user, _amount, winningAmount, haveExtractTokenToJackPot);
    updateSystemData();
    emit Bet(msg.sender, _amount, winRate, _type, _prediction, winningNumber, winningAmount, payout);
  }

  function getTotalBet() public view returns (uint) {
    require(systemInfoVisible, 'totalBet is not available right now');
    return totalBet;
  }

  function getTotalPayout() public view returns (uint) {
    require(systemInfoVisible, 'totalPayout is not available right now');
    return totalPayout;
  }

  function withdrawUserIncomeAndBalance() public {
    User storage user = users[msg.sender];
    require(dividend >= 0, 'dividend is not enough to withdraw');
    uint withDrawAmount = user.balance;
    user.balance = 0;
    require(gdpToken.transfer(msg.sender, withDrawAmount), 'Transfer token to user failed');
  }

  // PRIVATE-FUNCTIONS

  function handleWinCase(User storage _user, uint _amount, uint _winRate) private returns (uint, bool) {
    uint winningAmount = _amount.mul(multiplier).div(10).div(_winRate).sub(_amount);
    dividend -= int(winningAmount);
    bool haveExtractTokenToJackPot = checkAddJackPotTicket(_amount, winningAmount);
    winningAmount = haveExtractTokenToJackPot ? getPayoutAmount(winningAmount, haveExtractTokenToJackPot) : winningAmount;
    _amount = haveExtractTokenToJackPot ? getPayoutAmount(_amount, haveExtractTokenToJackPot) : _amount;
    payback(_user, _amount, winningAmount);
    return (winningAmount, haveExtractTokenToJackPot);
  }

  function handleLoseCase(uint _amount) private {
    checkAddJackPotTicket(_amount, 0);
    losingBet = losingBet.add(_amount);
    dividend += int(_amount);
  }

  function updateUserData(User storage user, uint _amount, uint _winningAmount, bool haveExtractTokenToJackPot) private {
    user.personalVolume = user.personalVolume.add(_amount);
    user.betCounter = user.betCounter.add(1);
    user.totalPayout = user.totalPayout
    .add(getPayoutAmount(_amount, haveExtractTokenToJackPot))
    .add(_winningAmount);
  }

  function updateSystemData() private {
    totalBet = totalBet.add(1);
  }

  function payback(User storage user, uint _amount, uint _winningAmount) private {
    uint payoutAmount = _amount.add(_winningAmount);
    if (dividend >= 0) {
      require(gdpToken.transfer(msg.sender, payoutAmount), 'Transfer token to user failed');
    } else {
      require(gdpToken.transfer(msg.sender, _amount), 'Transfer token to user failed');
      user.balance = user.balance.add(_winningAmount);
    }
    totalPayout = totalPayout.add(payoutAmount);
  }

  function checkAddJackPotTicket(uint _bettingAmount, uint _winningAmount) private returns (bool) {
    uint jackPotTokenAmount;
    bool isWin = _winningAmount > 0;
    if (isWin && dividend >= 0) {
      jackPotTokenAmount = jackPotTokenAmount.add(_bettingAmount.div(100)).add(_winningAmount.div(100));
    }
    bool sendTokenToJackPot = jackPotTokenAmount > 0;
    if (sendTokenToJackPot) {
      require(gdpToken.transfer(address(jackPot), jackPotTokenAmount), 'Transfer token to jackPot failed');
    }
    if (_bettingAmount >= jackPotTicketCheckpoint) {
      jackPot.addTicket(msg.sender, 'luckyNumber', isWin);
    }
    return sendTokenToJackPot;
  }

  function getPayoutAmount(uint _amount, bool haveExtractTokenToJackPot) private pure returns (uint) {
    return haveExtractTokenToJackPot ? _amount.mul(99).div(100) : _amount;
  }

  function trackUserAddress() private {
    if (!userAddressesChecker[msg.sender]) {
      userAddressesChecker[msg.sender] = true;
      totalPlayers = totalPlayers.add(1);
    }
  }
}