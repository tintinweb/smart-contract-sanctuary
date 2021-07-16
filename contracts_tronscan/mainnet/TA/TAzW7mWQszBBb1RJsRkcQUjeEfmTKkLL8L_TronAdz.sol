//SourceUnit: TronAdz.sol

/*
 * 
 *   TRONADZ - TronAdz is first ever decentralized blockchain-based advertising smart contract that allows you to earn up to 1.20% per day by putting your funds into the smart contract.
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://tronadz.com                                        │
 *   │                                                                       │  
 *   │   Telegram Public Group: https://t.me/TronAdzofficial                 |                     
 *   |   YouTube: https://www.youtube.com/channel/UCt-YjbUXMmRG7ChNGAt5bQw   |
 *   |   E-mail: admin@tronadz.com                                           |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [INSTRUCTION]
 *
How to start earning with Tronadz 

There are four ways to earn from TronAdz. You can start with as little as 100TRX. There is no referral requirement to earn from first two methods.
Passive Earnings 
By depositing funds to our smart contract, you will be able to receive a daily profit of 1% without doing anything. All earnings are paid every 24 hours.
Surfing pool 
Tronadz is first ever decentralized blockchain-based advertising smart contract that offers its users +0.20% more earnings if you surf 10 websites every  24 hours on our surfing page. This helps the smart contract gain more revenue from advertisements which goes directly to the smart contract as an external revenue. If you surf 10 websites daily, your will earn 1% from passive  +0.20% surfing pool bonus which brings your earnings to 1.20% daily.
Commission Based Earnings
You can earn massive referral commissions if you bring your teams to TronAdz . Our smart contract offers massive commissions up to 15 levels deep .
Level 1 -  30%       Level 2 -  20%
Level 3 -  15%       Level 4 -  10%
 Level 5 -  10%       Level 6 -  8%
Level7 -  8%       Level – 8  8%
Level 9 -  8%         Level 10 -  8%
Level 11 - 5% upto  Level 15 -  5%

You will also earn 10% commission from your referral purchase of any advertisement service.
Earning Caps of 360%
The smart contract is written so that if a user has earned 360% of his total deposits, his earnings will be stopped until another deposit is made, regardless of whether a user earns that 360% from referral commissions or from passive income or the surfing pool. This limit is placed to ensure the sustainability and longevity of the smart contract.

Daily Top Sponsor Commission
Daily top referrer pool - 5% of all deposits goes to the daily pool.

Pool activates when reaches 20000 TRX, 
10% of the pool is shared among the top 5 sponsors, 90% rolls over to the next day to increase the pool.

Distribution of the 10%  -
 1st -  30%
 2nd -  25%
 3rd -  20%
 4th -  15%
 5th - 10%
*/

pragma solidity >=0.4.25;

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract TronAdz {
  using SafeMath for uint256;

  struct User {
    address wallet;
    uint referrerCount;
    address parent;
    uint256 maxPayout;
    //uint256 payouts;
    uint256 refPayouts;
    uint256 adsPayouts;
    uint256 withdrawed;
    uint256 deposited;
    uint256 totalDeposited;
    uint256 totalWithdrawed;
    uint256 deposit_time;
    uint256 pool_bonus;
    uint256 pool_bonus_withdrawed;
    address[] referrals;
    uint256 oldBalance;
  }

  address private admin;
  address private defaulParent;
  address private operator;

  uint256 public totalFees;

  uint256 public totalWithdrawed;

  uint256 public freeTrxBalance;
  mapping (address => uint256) public freeTrxPayments;  

  mapping (address => address) public parents;
  mapping (address => User) public users;

  mapping(uint8 => uint8) public refPercents;

  event TX(string _type, address indexed _addr, address indexed _parent, uint256 _amount, uint8 _level, uint256 _time);

  uint8[] public pool_bonuses;
  uint40 public pool_last_draw = uint40(block.timestamp);
  uint256 public pool_cycle;
  uint256 public pool_balance;
  mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
  mapping(uint8 => address) public pool_top;

  uint256 ether = 1e6;

  uint256 payoutPeriod = 1 days;
  uint256 payoutCount = 360;

  modifier isAdmin(){
    require(msg.sender == admin);
    _;
  }

  modifier isOperator(){
    require(msg.sender == admin || msg.sender==operator);
    _;
  }

  constructor() public {
    admin = msg.sender;
    operator = msg.sender;

    refPercents[1] = 30;
    refPercents[2] = 20;
    refPercents[3] = 15;
    refPercents[4] = 10;
    refPercents[5] = 10;
    refPercents[6] = 8;
    refPercents[7] = 8;
    refPercents[8] = 8;
    refPercents[9] = 8;
    refPercents[10] = 8;

    for(uint8 i = 11; i <= 15; i++){
      refPercents[i] = 5;
    }

    pool_bonuses.push(30);
    pool_bonuses.push(25);
    pool_bonuses.push(20);
    pool_bonuses.push(15);
    pool_bonuses.push(10);

    defaulParent = msg.sender;
  }
  
  function maxPayoutAmount(uint256 _amount) view internal returns(uint256) {
        return _amount * payoutCount / 100;
  }

  function deposit(address _parent, address _forAddress) public payable {
    address _addr = _forAddress==address(0) ? msg.sender : _forAddress;
    address parentAddress = _parent == address(0) ? defaulParent : _parent;
    uint256 _amount = msg.value;

    if(parentAddress == _addr){
      parentAddress = address(0); //avoid loop
    }

    // require(users[_addr].deposit_time <= 0 ||
    //     balanceOfAddr(_addr) >= maxPayoutAmount(users[_addr].deposited),
    //     "Already exists");
    
    //require(balanceOfAddr(_addr)- users[_addr].withdrawed <= (10*ether), 
    //  "Please withdraw current funds first.");

    if(users[_addr].deposit_time > 0){
      uint256 amount = balanceOfAddr(_addr) - users[_addr].withdrawed;
      
      uint256 ndays = (block.timestamp - users[_addr].deposit_time) / payoutPeriod;
      if(ndays > payoutCount){
        ndays = payoutCount;
      }

      uint currentBalance = balanceOfAddr(_addr);
      uint256 oldBalanceTemp = currentBalance >= users[_addr].maxPayout ? 
        users[_addr].oldBalance.add(users[_addr].deposited * (ndays / 100))
        :
        currentBalance.sub(users[_addr].refPayouts).sub(
          users[_addr].adsPayouts
        );

      if(amount > 0){
        withdraw(msg.sender, 0);
      }
      
      users[_addr].oldBalance = oldBalanceTemp; 
    }
    

    users[_addr].deposited += _amount;
    //users[_addr].withdrawed = 0;
    
    //users[_addr].adsPayouts = 0;
    users[_addr].deposit_time = uint40(block.timestamp);
    users[_addr].totalDeposited += _amount;
    users[_addr].maxPayout = maxPayoutAmount(users[_addr].deposited);
        

    if(users[_addr].parent == address(0) && parentAddress!=address(0)){
      users[_addr].parent = parentAddress;
      parents[_addr] = parentAddress;
    }

    _poolDeposit(_addr, _amount);
    if(pool_last_draw + payoutPeriod < block.timestamp) {
      _drawPool();
    }
    emit TX("Deposit", _addr, parentAddress, _amount, 0, now);
  }

  function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit TX("PoolPayout", pool_top[i], address(0), win, 0, now);
        }
        
        for(i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
  }

  function _poolDeposit(address _addr, uint256 _amount) private {
        pool_balance += _amount.mul(5).div(100);

        address upline = users[_addr].parent;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        uint8 j = 0;
        uint8 k = 0;
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(k = uint8(pool_bonuses.length - 1); k > i; k--) {
                    pool_top[k] = pool_top[k - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
  }

  function adsDeposit(address _forAddress, address _parent) public payable{
      address _addr = _forAddress == address(0) ? msg.sender : _forAddress;
      address parent = _parent==address(0) ? admin : _parent;
      uint256 amount = msg.value;

      emit TX("AdsPurchaseCommision", parent, _addr, amount.mul(10).div(100), 0, now);

      parent.transfer(amount.mul(10).div(100));

      emit TX("PurchaseAds", _addr, parent, amount, 0, now);
  }

  function clickAdsDeposit(address _forAddress, address _parent) public payable{
      address _addr = _forAddress == address(0) ? msg.sender : _forAddress;
      address parent = _parent==address(0) ? admin : _parent;
      uint256 amount = msg.value;

      emit TX("ClickAdsPurchaseCommision", parent, _addr, amount.mul(10).div(100), 0, now);

      parent.transfer(amount.mul(10).div(100));

      freeTrxBalance += amount.mul(45).div(100);

      emit TX("PurchaseClickAds", _addr, parent, amount, 0, now);
  }

  function withdrawFreeTrx(address _forAddress, uint256 _amount) isOperator public{
    assert(_amount <= freeTrxBalance);
    assert(_forAddress != address(0) );
    freeTrxBalance -= _amount;

    _forAddress.transfer(_amount);
    emit TX("PTCAdsPayment", _forAddress, address(0), _amount, 0, now);
  }

  function WTFees() isOperator public{
    require(totalFees > 0, "zero amount");
    msg.sender.transfer(totalFees);
    totalFees = 0;
  }

  function surfingPayoutAndWithdraw(address _addr, uint256 freeTrx, uint256 
      surfingAmount
    ) isOperator public{

      if(freeTrx > 1*ether){
        withdrawFreeTrx(_addr, freeTrx);
      }
      
      if(users[_addr].deposit_time <= 0){
        return;
      }

      users[_addr].adsPayouts = surfingAmount;
      users[_addr].maxPayout = maxPayoutAmount(users[_addr].deposited);

      withdraw(_addr, 2*ether);
  }


  function() external isAdmin{
    // admin can send ETH to contract
  }


  function balanceOfAddr(address _addr) view public returns(uint256){
      uint256 amount = users[_addr].refPayouts.add(
        users[_addr].adsPayouts
      ).add(
        users[_addr].oldBalance
      ).add(users[_addr].deposited * ((block.timestamp - users[_addr].deposit_time) / payoutPeriod) / 100);
      return amount > users[_addr].maxPayout ?  users[_addr].maxPayout : amount;
  }

  function withdraw(address _forAddress, uint256 fee) public{
    if(pool_last_draw + payoutPeriod < block.timestamp) {
      _drawPool();
    }
    address _addr = _forAddress==address(0) ? msg.sender : _forAddress;
    require(_addr==msg.sender || msg.sender == admin || msg.sender==operator, "adminOnly");

    uint256 amount = balanceOfAddr(_addr) - users[_addr].withdrawed;
    
    // require(
    //   amount.add(users[_addr].pool_bonus).sub(
    //   users[_addr].pool_bonus_withdrawed
    // ) > fee, "zero amount");

    users[_addr].withdrawed += amount;
    users[_addr].totalWithdrawed += amount;

    totalWithdrawed += amount;

    if(amount > 0){
      address refer = _addr;
      for(uint8 i=1; i <=20; i++){
        address parent;
        if(refer != address(0) && parents[refer] != address(0)){
          parent = parents[refer];
          refer = parent;
        }else{
          refer = address(0);
          parent = admin;
        }

        uint256 refAmount = amount.mul(refPercents[i]).div(100);
        users[parent].refPayouts += refAmount;
    
        emit TX("RefferalPayout", parent, _addr, refAmount, i, now);      
      }
    }

    amount = amount.add(users[_addr].pool_bonus).sub(
      users[_addr].pool_bonus_withdrawed
    );

    if(amount < fee || amount <= 0){
      return;
    }

    users[_addr].pool_bonus_withdrawed = users[_addr].pool_bonus;

    _addr.transfer(amount-fee < address(this).balance ? amount-fee :
      address(this).balance
    );
    totalFees += fee;

    //Withdraw(_addr, amount, now);

    emit TX("Withdraw", _addr, address(0), amount, 0, now);
  }

  function updateAdmins(address _operator, address _admin) isAdmin public{
    require(_operator != address(0) && _admin != address(0), "0x0 wallet");
    admin = _admin;
    operator = _operator;
  }

  function updateSettings(uint256 _payoutPeriod,uint256 _payoutCount) isAdmin public{
    payoutCount = _payoutCount;
    payoutPeriod = _payoutPeriod;
  }

  function drawPool() external isAdmin {
    _drawPool();
  }
}