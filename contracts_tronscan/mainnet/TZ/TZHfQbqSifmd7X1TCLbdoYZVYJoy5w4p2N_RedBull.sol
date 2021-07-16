//SourceUnit: TrxRedBull.sol

pragma solidity >=0.5.10;

library SafeMath {

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
     *
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y 
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}

contract RedBull {

  using SafeMath for uint256;
  
  struct User {

    bool exist;

    address superiorAddr;

    uint balance;

    uint directRevenue;

    uint staticIncome;

    uint actualStaticIncome;

    uint dynamicIncome;

    uint actualDynamicIncome;

    uint depositAmount;

    uint actualDepositAmount;

    uint recommendQuantity;

    uint totalPerformance;
  }

  address public owner;
  
  address wallet;
  
  address[] shareholders = new address[](5);

  address[] allUsers;

  uint dayTime = 86400;
  
  uint round = 1; 

  uint public rounding = 1;

  uint private totalDeposit;

  uint private totalWithdrawal;

  uint private vertexPct = 6;

  uint8[] ref_bonuses;
  
  mapping(uint => uint) public roundMap;

  mapping(uint => uint) private roundNumberMap;

  mapping(uint => uint) private indexMap;
  
  mapping(address => User) public userMap;

  mapping(address => uint) shareholderPctMap;

  constructor() public {
    owner = address(0x0785c58a866522655874b8295fA1A2AAe92053bc);
    wallet = address(0xE7ce8BCf8538B9cF5174FFC4efedb3F74d28385E);
    roundMap[round] = block.timestamp.add(dayTime);
    shareholders[0] = address(0xad05a8350F9acc903aC3D33d9bf36b8531A2DBCF);
    shareholders[1] = address(0x28626Eac60fac329c49C14701D354e44c350F767);
    shareholders[2] = address(0x791552fD6395216D1983587C04b50d6aFcb7dDeb);
    shareholders[3] = address(0x93805e7d5f26243fF7504eA35A1069EEC7Ad23F1);
    shareholders[4] = address(0x27c711D9b4B178505d666656bA092F80b2076fBF);
    shareholderPctMap[shareholders[0]] = 20;
    shareholderPctMap[shareholders[1]] = 33;
    shareholderPctMap[shareholders[2]] = 7;
    shareholderPctMap[shareholders[3]] = 5;
    shareholderPctMap[shareholders[4]] = 15;
    ref_bonuses.push(20);
    ref_bonuses.push(10);
    ref_bonuses.push(10);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(5);
    ref_bonuses.push(10);
    ref_bonuses.push(10);
    ref_bonuses.push(20);
  }
  
  function register(address _addr, address _superiorAddr) private {
    if(!userMap[_addr].exist) {
      if (!userMap[_superiorAddr].exist) {
        _superiorAddr = address(0);
      }
      User memory player = User({
        exist: true,
        superiorAddr: _superiorAddr,
        balance: 0,
        directRevenue: 0,
        staticIncome: 0,
        actualStaticIncome: 0,
        dynamicIncome: 0,
        actualDynamicIncome: 0,
        depositAmount: 0,
        actualDepositAmount: 0,
        recommendQuantity: 0,
        totalPerformance: 0
      });
      allUsers.push(_addr);
      userMap[_addr] = player;
      if(_superiorAddr != address(0))
        userMap[_superiorAddr].recommendQuantity++;
    }
  }

  function deposit(address _superiorAddr) external payable {
    uint _trx = msg.value;
    require(_trx >= 5e8 && userMap[msg.sender].depositAmount.add(_trx) <= 1e12, "Bad amount");
    register(msg.sender, _superiorAddr);
    
    uint _now = block.timestamp;
    
    if(_now < roundMap[round]) {
        core(msg.sender, _trx);
    } else {
        endRound(msg.sender, _trx);
    }
  }
  
  function core(address addr, uint _trx) private {
    uint amount0 = _trx.mul(3).div(100);
    userMap[wallet].balance = userMap[wallet].balance.add(amount0);

    for(uint i = 0; i < shareholders.length; i++) {
      uint amount1 = _trx.mul(shareholderPctMap[shareholders[i]]).div(1000);
      userMap[shareholders[i]].balance = userMap[shareholders[i]].balance.add(amount1);
    }

    if(userMap[addr].superiorAddr != address(0)) { 
      uint amount2 = _trx.mul(20).div(100);
      userMap[userMap[addr].superiorAddr].balance = userMap[userMap[addr].superiorAddr].balance.add(amount2);
      userMap[userMap[addr].superiorAddr].directRevenue = userMap[userMap[addr].superiorAddr].directRevenue.add(amount2);
    }

    address superiorAddr = userMap[addr].superiorAddr;
    for(int i = 0; i < 15; i++) {
      if(superiorAddr == address(0)) break;
      userMap[superiorAddr].totalPerformance = userMap[superiorAddr].totalPerformance.add(_trx);
      superiorAddr = userMap[superiorAddr].superiorAddr;
    }
    
    userMap[owner].balance = userMap[owner].balance.add(_trx.mul(vertexPct).div(100));
    userMap[addr].depositAmount = userMap[addr].depositAmount.add(_trx);
    userMap[addr].actualDepositAmount = userMap[addr].actualDepositAmount.add(_trx);

    totalDeposit = totalDeposit.add(_trx);
  }
  
  function endRound(address addr, uint _trx) private {
    roundNumberMap[round] = allUsers.length;
    round++;
    roundMap[round] = block.timestamp.add(dayTime);
    core(addr, _trx);
  }

  function setVertexPct(uint pct) external {
    require(owner == msg.sender, "Insufficient permissions");
    vertexPct = pct;
  }

  function calcIncome(address addr, uint income) private view returns(uint _income, bool result) {
    uint maximumProfit = userMap[addr].depositAmount.mul(3);
    uint settlementIncome = userMap[addr].staticIncome.add(userMap[addr].dynamicIncome);
    if(settlementIncome.add(income) >= maximumProfit) {
      _income = maximumProfit.sub(settlementIncome);
      result = true;
    } else {
      _income = income;
      result = false;
    }
  }

  function updateIncome(address addr) private {
    uint income = userMap[addr].depositAmount.mul(3).div(100);
    (uint _income, bool result0) = calcIncome(addr, income);
    if(_income > 0) {
      if(result0) {
        userMap[addr].staticIncome = 0;
        userMap[addr].dynamicIncome = 0;
        userMap[addr].depositAmount = 0;
      } else {
        userMap[addr].staticIncome = userMap[addr].staticIncome.add(_income);
      }
      userMap[addr].balance = userMap[addr].balance.add(_income);
      userMap[addr].actualStaticIncome = userMap[addr].actualStaticIncome.add(income);
      address superiorAddr = userMap[addr].superiorAddr;
      for(uint i = 0; i < ref_bonuses.length; i++) {
        if(superiorAddr == address(0)) break;
        if(userMap[superiorAddr].recommendQuantity >= i + 1) {
          uint bonus = _income * ref_bonuses[i] / 100;
          (uint _bonus, bool result1) = calcIncome(superiorAddr, bonus);
          if(_bonus > 0) {
            if(result1) {
              userMap[superiorAddr].staticIncome = 0;
              userMap[superiorAddr].dynamicIncome = 0;
              userMap[superiorAddr].depositAmount = 0;
            } else {
              userMap[superiorAddr].dynamicIncome = userMap[superiorAddr].dynamicIncome.add(_bonus);
            }
            userMap[superiorAddr].balance = userMap[superiorAddr].balance.add(_bonus);
            userMap[superiorAddr].actualDynamicIncome = userMap[superiorAddr].actualDynamicIncome.add(bonus);
          }
        } 
        superiorAddr = userMap[superiorAddr].superiorAddr;
      }
    }
  }

  function needIncomeUpdate() private view returns(bool result) {
    uint _now = block.timestamp;
    result = (roundMap[round] < _now && rounding == round) || rounding < round ? true : false;
  }

  function massUpdateIncomes() external {
    require(owner == msg.sender, "Insufficient permissions");
    require(needIncomeUpdate(), "Updated");
    if(roundNumberMap[rounding] == 0) {
      if(allUsers.length == 0){
        rounding++;
      }else{
        roundNumberMap[rounding] = allUsers.length;
      }
    }
    for(uint i = indexMap[rounding]; i < roundNumberMap[rounding]; i++) {
      updateIncome(allUsers[i]);
      indexMap[rounding]++;
      if(indexMap[rounding] >= roundNumberMap[rounding]){
        rounding++;
      }else if(indexMap[rounding].mod(10) == 0) {
        break;
      }
    }
  }

  function withdraw(uint _amount) external {
    require(userMap[msg.sender].balance >= _amount, "Withdrawal failed");
    userMap[msg.sender].balance = userMap[msg.sender].balance.sub(_amount);
    totalWithdrawal = totalWithdrawal.add(_amount);
    bool flag = msg.sender != owner;
    for(uint i = 0; i < shareholders.length; i++) {
      if(msg.sender == shareholders[i]) {
        flag = false;
      }
    }
    if(flag) {
      _amount = _amount.sub(_amount.mul(20).div(100));
    }
    
    msg.sender.transfer(_amount);
  }

  function globalInfo() external view returns(bool _needUpdate, uint _usersLength, uint _totalDeposit, uint _totalWithdrawal, uint _round) {
    _needUpdate = needIncomeUpdate();
    _usersLength = allUsers.length;
    _totalDeposit = totalDeposit;
    _totalWithdrawal = totalWithdrawal;
    _round = round;
  }

}