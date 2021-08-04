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

// File: contracts/JackPot.sol

pragma solidity 0.5.0;




contract JackPot is Auth {
  using SafeMath for uint;
  using SafeMath for uint32;

  IGDP public gdpToken = IGDP(0xe724279dCB071c3996A1D72dEFCF7124C3C45082);
  mapping(address => bool) public gameContracts;
  uint[] public dividends;
  address[] public tickets;
  uint8 private m = 10;

  modifier onlyGameContracts() {
    require(gameContracts[msg.sender], 'onlyGameContracts');
    _;
  }

  event Drew(
    uint round,
    uint dividend,
    address firstPrizeWinner,
    uint firstPrize,
    address secondPrizeWinner,
    uint secondPrize,
    address thirdPrizeWinner,
    uint thirdPrize
  );
  event TicketAdded(uint indexed round, address user, uint number, string game, bool isWin);

  constructor (address _admin)
  public
  Auth(_admin) {}

  // ADMIN-FUNCTIONS

  function updateGameContract(address _game, bool status) onlyMainAdmin public {
    gameContracts[_game] = status;
  }

  function setM(uint8 _m) onlyMainAdmin public {
    require(_m >= 10 && _m <= 50, "Invalid value");
    m = _m;
  }

  function addTicket(address _user, string memory _game, bool _isWin) onlyGameContracts public {
    tickets.push(_user); // TODO use map instead mapping (uint => uint[]) tickets;
    emit TicketAdded(getTotalRound(), _user, 1000 + tickets.length, _game, _isWin);
  }

  function draw() onlyMainAdmin public {
    uint currentRoundDividend = gdpToken.balanceOf(address(this));
    address firstPrizeWinner;
    address secondPrizeWinner;
    address thirdPrizeWinner;
    (
      firstPrizeWinner,
      secondPrizeWinner,
      thirdPrizeWinner
    ) = pickWinners();
    uint firstPrize;
    uint secondPrize;
    uint thirdPrize;
    if (firstPrizeWinner != address(0x0)) {
      firstPrize = currentRoundDividend.div(2);
      require(gdpToken.transfer(firstPrizeWinner, firstPrize), "Transfer token to 1st winner failed");
    }
    if (secondPrizeWinner != address(0x0)) {
      secondPrize = currentRoundDividend.div(5);
      require(gdpToken.transfer(secondPrizeWinner, secondPrize), "Transfer token to 2nd winner failed");
    }
    if (thirdPrizeWinner != address(0x0)) {
      thirdPrize = currentRoundDividend.div(5);
      require(gdpToken.transfer(thirdPrizeWinner, thirdPrize), "Transfer token to 3rd winner failed");
    }

    emit Drew(
      getTotalRound(),
      currentRoundDividend,
      firstPrizeWinner,
      firstPrize,
      secondPrizeWinner,
      secondPrize,
      thirdPrizeWinner,
      thirdPrize
    );
    dividends.push(currentRoundDividend);
    resetGame();
  }

  function getTotalRound() public view returns (uint) {
    return dividends.length + 1;
  }

  function getTotalTicketsInCurrentRound() public view returns (uint) {
    return tickets.length;
  }

  // PRIVATE FUNCTIONS

  function pickWinners() private view returns (address, address, address) {
    address firstPrizeWinner = pickWinner(address(0x0));
    address secondPrizeWinner = pickWinner(firstPrizeWinner);
    if (firstPrizeWinner != address(0x0) && secondPrizeWinner == firstPrizeWinner) {
      secondPrizeWinner = pickWinner(firstPrizeWinner);
      if (secondPrizeWinner == firstPrizeWinner) {
        secondPrizeWinner = address(0x0);
      }
    }
    address thirdPrizeWinner = pickWinner(secondPrizeWinner);
    if ((firstPrizeWinner != address(0x0) && thirdPrizeWinner == firstPrizeWinner) || (secondPrizeWinner != address(0x0) && thirdPrizeWinner == secondPrizeWinner)) {
      thirdPrizeWinner = pickWinner(secondPrizeWinner);
      if ((firstPrizeWinner != address(0x0) && thirdPrizeWinner == firstPrizeWinner) || (secondPrizeWinner != address(0x0) && thirdPrizeWinner == secondPrizeWinner)) {
        thirdPrizeWinner = address(0x0);
      }
    }
    return (
      firstPrizeWinner,
      secondPrizeWinner,
      thirdPrizeWinner
    );
  }

  function pickWinner(address _seed) private view returns (address) {
    uint32 max = uint32(tickets.length.mul(100 + m).div(100));
    uint randomIndex = genRandomNumber(max, _seed);
    return randomIndex < tickets.length ? tickets[randomIndex] : address(0x0);
  }

  function resetGame() private {
    delete tickets; // out of gas here
  }

  function genRandomNumber(uint32 _max, address _seed) private view returns (uint) {
    return uint(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              block.timestamp,
              block.difficulty,
              msg.sender,
              _seed,
              now
            )
          )
        )
      )
    ) % _max;
  }
}