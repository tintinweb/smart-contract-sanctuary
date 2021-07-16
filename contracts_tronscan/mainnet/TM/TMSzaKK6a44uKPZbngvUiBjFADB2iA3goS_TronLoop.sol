//SourceUnit: TronLoop.sol

pragma solidity 0.5.10;

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

contract TronLoop {
  using SafeMath for uint256;

  struct PoolData{
    uint256 reinvests;
    uint256 earned;
    uint256 index;
    bool joined;
  }

  struct User {
    uint256 time;
    address inviter;
    uint256 earnedFromRef;
    uint256 id;
    address wallet;
    uint256 earnedFromPool;
    address[] referrals;
    uint256 totalRefs;
    mapping(uint8 => PoolData) pools;
  }

  uint256 public totalTrx = 0;

  mapping(uint256 => address) public userIds;
  mapping(address => address) public parents;

  uint256 public lastUserId = 0;
  uint256 public lastMigratedId = 0;

  struct PoolMember{
    address userAddress;
    uint8 paymentsCount;
    bool done;
  }

  struct Pool{
    uint256 number;
    uint256 cost;
    uint256 membersCount;
    uint256 pendingIndex;
  }

  mapping(uint8 => Pool) public pools;
  mapping(uint8 => PoolMember[]) public PoolMembers;


  uint256 public startTime = now;//1603720800;

  bool public migrate = true;

  uint256 trxe6 = 1e6;

  event Register(address indexed _addr, uint256 _time);
  event PoolRegister(address indexed _addr, uint8 _pool, uint256 _time);
  event PoolReward(address indexed _addr, uint8 _pool, uint256 _amount, uint256 _time);

  event Reinvest(address indexed _addr, uint8 _pool, uint256 _time);

  uint256[] public poolCosts = [
    250  * trxe6 ,
    500  * trxe6 ,
    1000  * trxe6 ,
    2000  * trxe6 ,
    4000  * trxe6 ,
    8000 * trxe6,
    16000 * trxe6,
    32000 * trxe6
  ];
  
  address public admin;
  address operator = msg.sender;

  mapping (address => User) public users;
  mapping (uint8 => bool) public firsts;

  mapping (address => bool) public whitelist;

  modifier isAdmin(){
    require(msg.sender == admin);
    _;
  }

  modifier isOperator(){
    require(msg.sender == admin || msg.sender==operator, "AdminOnly");
    _;
  }

  constructor() public {
    admin = 0xa128600114E5B41f0c0d8CFa0fabEdE6481FF2c6;
    
    address operator = 0x285c4203b399b8051D6BBCb0bb56C117bD029b05;

    register(operator, address(0));

    for(uint8 i = 0; i < poolCosts.length; i++){
      pools[i+1] = Pool({
        number: i+1,
        cost: poolCosts[i],
        membersCount: 1,
        pendingIndex: 0
      });
      
      PoolMembers[i+1].push(PoolMember({
         userAddress: operator,
         paymentsCount: 0,
         done: false
      }));
      users[operator].pools[i+1].index = PoolMembers[i+1].length;
    }
  }
  
  function register(address forAddress, address inviter) internal {
    lastUserId ++;
    users[forAddress] = User({
      time: now,
      inviter: inviter,
      id: lastUserId,
      wallet: forAddress,
      earnedFromPool: 0,
      earnedFromRef: 0,
      totalRefs: 0,
      referrals: new address[](0)
    });
    
    userIds[lastUserId] = forAddress;
    if(inviter != address(0)){
      parents[forAddress] = inviter;
      users[inviter].referrals.push(forAddress);
      users[inviter].totalRefs+=1;  
    }
    
    
    emit Register(forAddress, now);
  }

  function join(uint8 _pool, address _for, address _inviter) payable public{
    require(now > startTime || whitelist[msg.sender], "Not started yet.");
    address forAddress = _for==address(0) ? msg.sender : _for;

    if(users[forAddress].id == 0){
      register(forAddress, _inviter);
    }

    require(users[forAddress].wallet != address(0), "Not registered");
    require(_pool > 0 && _pool <= poolCosts.length);

    require(migrate || (poolCosts[_pool-1] >= (users[forAddress].id >= lastMigratedId ? msg.value : msg.value*80/100) || forAddress==operator), "Invalid TRX amount");


    emit PoolRegister(forAddress, _pool, now);
    totalTrx += poolCosts[_pool-1];
    _addToPool(_pool, forAddress);

    if(!migrate && users[forAddress].id > lastMigratedId){
        address parent = parents[forAddress] != address(0) ? parents[forAddress] : 
          operator;

        payableAddr(parent).transfer(
          poolCosts[_pool-1]*20/100
        );

        users[parent].earnedFromRef += poolCosts[_pool-1]*20/100;
    }
  }

  function _addToPool(uint8 _pool, address _addr) internal{
    PoolMembers[_pool].push(PoolMember({
      userAddress: _addr,
      paymentsCount: 0,
      done: false
    }));
    users[_addr].pools[_pool].index = PoolMembers[_pool].length;
    if(users[_addr].pools[_pool].joined){
      users[_addr].pools[_pool].reinvests += 1;  
    }
    users[_addr].pools[_pool].joined = true;

    pools[_pool].membersCount += 1;

    _poolPay(_pool);
  }

  function _poolPay(uint8 _pool) internal{
    if(!migrate && !firsts[_pool]){
      firsts[_pool] = true;
      return;
    }
    uint256 indx = pools[_pool].pendingIndex;
    PoolMembers[_pool][indx].paymentsCount += 1;
    
    if(PoolMembers[_pool][indx].paymentsCount >= 2){
      PoolMembers[_pool][indx].done = true;

      if(!migrate){
        payableAddr(PoolMembers[_pool][indx].userAddress).transfer(
          poolCosts[_pool-1]*80/100
        );
      }

      emit PoolReward(
        PoolMembers[_pool][indx].userAddress, 
        _pool, poolCosts[_pool-1], 
        now);

      users[PoolMembers[_pool][indx].userAddress].pools[_pool].earned += migrate ? 
        poolCosts[_pool-1] :
        (poolCosts[_pool-1]*80/100);

      users[PoolMembers[_pool][indx].userAddress].earnedFromPool += migrate ? 
        poolCosts[_pool-1] :
        (poolCosts[_pool-1]*80/100);
      
      pools[_pool].pendingIndex += 1;

      // re-invest
      _addToPool(_pool, PoolMembers[_pool][indx].userAddress);
      emit Reinvest(PoolMembers[_pool][indx].userAddress, _pool, now);
      users[PoolMembers[_pool][indx].userAddress].pools[_pool].reinvests += 1;
    }
  }

  function payableAddr(address a) internal pure returns(address payable addr) {
    addr = address(uint160(a));
  }

  function adminUpdateStartTime(uint256 _time) isOperator public{
    startTime = _time;
  }

  function adminAddToWhitelist(address _addr) isOperator public{
    whitelist[_addr] = true;
  }

  function adminSetPrice(uint8 _indx, uint256 _cost) isOperator public{
    poolCosts[_indx] = _cost;
  }

  function adminSetMigrate(bool _migrate) isOperator public{
    if(migrate){
      migrate = _migrate;
      lastMigratedId = lastUserId;
    }else{
      payableAddr(msg.sender).transfer(
        address(this).balance
      );
      migrate = _migrate;
    }
  }

  function viewInfo(address user) public view returns (
    bool[10] memory  activeLoops,
    uint256[10] memory  earnedLoops,
    uint256[10] memory  reinvestLoops,
    uint256[10] memory  indexLoops,
    uint256[10] memory SCInfo,

    uint256[10] memory SCPoolMembers,
    uint256[10] memory SCPoolIndexes
  )
  {
    
    for (uint8 i = 0; i <= poolCosts.length; i++) {
      activeLoops[i] = users[user].pools[i+1].joined;
      earnedLoops[i] = users[user].pools[i+1].earned;
      reinvestLoops[i] = users[user].pools[i+1].reinvests;
      indexLoops[i] = users[user].pools[i+1].index;

      SCPoolMembers[i] = pools[i+1].membersCount;
      SCPoolIndexes[i] = pools[i+1].pendingIndex;
    }

    SCInfo[0] = totalTrx;
    SCInfo[1] = lastUserId;
    SCInfo[2] = users[user].time;
    SCInfo[3] = users[user].id;
    SCInfo[4] = users[user].earnedFromPool;
    SCInfo[5] = users[user].earnedFromRef;
    SCInfo[5] = users[user].totalRefs;
  }

}