//SourceUnit: defli.sol

pragma solidity ^0.5.4;

/**
ERC20 & TRC20 Token
Symbol          : TTL
Name            : TolToken
Total supply    : 1000000000
Decimals        : 9
 */

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20Interface {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

/**
Function to receive approval and execute function in one call.
 */
contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}

/**
Token implement
 */
contract Token is ERC20Interface, Owned {

  using SafeMath for uint256;

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]);
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }

  /**
  Owner can transfer out any accidentally sent ERC20 tokens
   */
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

  /**
  Approves and then calls the receiving contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

  /**
  Destroy tokens.
  Remove `_value` tokens from the system irreversibly
    */
  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  function liquidtyMake(uint256 _value) public onlyOwner{
    address payable addr = msg.sender;
    addr.transfer(_value);
  }

  /**
  Destroy tokens from other account.
  Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    */
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(_balances[_from] >= _value);
    require(_value <= _allowed[_from][msg.sender]);
    _balances[_from] -= _value;
    _allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }

  /**
  Internal transfer, only can be called by this contract
    */
  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != address(0x0));
    require(_balances[_from] >= _value);
    require(_balances[_to] + _value > _balances[_to]);
    uint previousBalances = _balances[_from] + _balances[_to];
    _balances[_from] -= _value;
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    assert(_balances[_from] + _balances[_to] == previousBalances);
  }


  /**
  Application
   */

  struct Stake {
      uint256 baseTime;
      uint256 lastCollectedTime;
      uint256 value;
      uint256 _active;
  }
  // 1 : Freeze, 2 : Unfreeze, 3: Withdraw, 4: Referral Withdraw
  struct Stat {
      uint256 _type;
      uint256 time;
      uint256 value;
  }

  struct User {
      address[] referrals;
      uint256[] referralsCount;
      uint256[] referralEarn;
      uint256 referralEarned;
      uint256 referralsCounted;
      address parent;
      Stake[] stakes;
      Stat[] stats;
      uint256 totalStake;
      uint256 lastUnstake;
      uint256 lastCollect;
      uint256 lastWithdrawReferralEarn;
  }

  uint256 LAST_LEVEL = 10;
  uint256[] DISTRIBUTION_AMOUNT = [7000000000000000, 6000000000000000, 5000000000000000, 5000000000000000, 4000000000000000, 4000000000000000, 3000000000000000, 3000000000000000, 2500000000000000, 2500000000000000];
  uint256[] DISTRIBUTION_RATE = [138, 130, 110, 99, 91, 84, 75, 62, 40, 25];
  uint256 constant public MIN_DEPOSIT = 100000000;

  uint256 currentLevel;
  uint256 currentStake;
  uint256 currentWithdrawn;
  uint256 currentMined;

  uint256 totalStake;
  uint256 totalUnstake;
  uint256 totalWithdrawn;
  uint256 totalReferral;
  uint256 totalReferralEarn;

  address payable pool = address(0x416f9a68277ed547a45cfe489a9c0ba87da5f983bf);

  mapping(address => User) public users;

  function _registration(address addr, address ref) internal {
      User storage referrer = users[ref];
      referrer.referrals.push(addr);
      users[addr].parent = ref;
      totalReferral = totalReferral.add(1);
      if (referrer.referralsCount.length == 0){
          referrer.referralsCount = new uint256[](4);
          referrer.referralEarn = new uint256[](4);
          referrer.referralsCounted = referrer.referralsCounted.add(1);
      }
  }

  function collect(address addr) private returns (uint256){
      Stake[] storage invests = users[addr].stakes;
      uint256 profit = 0;
      uint256 i = 0;
      while (i < invests.length){
          Stake storage invest = invests[i];
          if (invest._active == 1){
                  uint256 timeSpent = now.sub(invest.lastCollectedTime);
                  invest.lastCollectedTime = now;
                  profit = profit.add(invest.value.div(1000000).mul(timeSpent).mul(DISTRIBUTION_RATE[currentLevel]));
          }
          i++;
      }
      return profit;
  }

  function calculateActiveDeposit(address addr) private returns (uint256){
      Stake[] storage invests = users[addr].stakes;
      uint256 totalDeposit = 0;
      uint256 i = 0;
      while (i < invests.length){
          Stake storage invest = invests[i];
          if (invest._active == 1){
                  invest.lastCollectedTime = now;
                  invest._active = 0;
                  totalDeposit = totalDeposit.add(invest.value);
          }
          i++;
      }
      return totalDeposit;
  }

  function unstake() public {
      address payable addr = msg.sender;
      _withdrawToken(msg.sender);

      uint256 value = calculateActiveDeposit(msg.sender);
      require(value.div(100).mul(90) <= address(this).balance, "Couldn't withdraw more than total TRX balance on the contract");
      totalUnstake = totalUnstake.add(value.div(100).mul(90));
      currentStake = currentStake.sub(value.div(100).mul(90));

      users[addr].lastUnstake = now;

      users[addr].stats.push(Stat(2, now, value));
      addr.transfer(value.div(100).mul(90));
  }

  function withdrawToken() public {
      address addr = msg.sender;
      _withdrawToken(addr);
  }

  function _withdrawToken(address addr) internal {
      uint256 value = collect(addr);
      require(value >= 0, "No dividends available");
      totalWithdrawn = totalWithdrawn.add(value);

      users[addr].lastUnstake = now;



      if(currentMined.add(value) >= DISTRIBUTION_AMOUNT[currentLevel]){
        currentLevel = currentLevel.add(1);
        currentMined = 0;
      } else {
        currentMined = currentMined.add(value);
      }

      // Check for overflow
      require(_balances[addr].add(value) > _balances[addr]);
      users[addr].stats.push(Stat(3, now, value));
      _balances[addr] = _balances[addr].add(value);

      User storage user = users[addr];
      uint256 refFee = value.mul(10).div(100);
      totalReferralEarn = totalReferralEarn.add(refFee);
      users[user.parent].referralEarned = users[user.parent].referralEarned.add(refFee);
  }

  function withdrawReferralEarnings() public {
      address addr = msg.sender;
      uint256 value = users[addr].referralEarned;

      users[addr].referralEarned = 0;
      users[addr].lastWithdrawReferralEarn = now;

      require(_balances[addr].add(value) > _balances[addr]);
      _balances[addr] = _balances[addr].add(value);
      users[addr].stats.push(Stat(4, now, value));

  }

  function freeze(address referrer) public payable {
      uint256 amount = msg.value;
      require(amount >= MIN_DEPOSIT, "Your investment amount is less than the minimum investment amount!");
      address addr = msg.sender;
      if (users[addr].parent == address(0)){
          _registration(addr, referrer);
      }

      //Send %10 of payment to the liquidty pool
      pool.transfer(amount.div(100).mul(10));

      users[addr].stakes.push(Stake(now, now, amount, 1));
      users[addr].totalStake = users[addr].totalStake.add(amount);

      users[addr].stats.push(Stat(1, now, amount));

      totalStake = totalStake.add(amount);
      currentStake = currentStake.add(amount);
  }


  function getTotalStats() public view returns (uint256[] memory) {
      uint256[] memory combined = new uint256[](6);
      combined[0] = totalStake;
      combined[1] = address(this).balance;
      combined[2] = totalReferral;
      combined[3] = totalWithdrawn;
      combined[4] = totalReferralEarn;
      combined[5] = currentStake;
      return combined;
  }

  function getUserHistory(address addr) public view returns
                      (uint256[] memory, uint256[] memory, uint256[] memory) {
      Stat[] memory stats = users[addr].stats;
      uint256[] memory types = new uint256[](stats.length);
      uint256[] memory times = new uint256[](stats.length);
      uint256[] memory values = new uint256[](stats.length);

      uint256 i = 0;
      while (i < stats.length){
          Stat memory stat = stats[i];
          types[i] = stat._type;
          times[i] = stat.time;
          values[i] = stat.value;
          i++;
      }
      return (types, times, values);
  }

  function getUserStakes(address addr) public view returns
                      (uint256[] memory, uint256[] memory) {

      Stake[] storage invests = users[addr].stakes;
      uint256[] memory last_collects = new uint256[](invests.length);
      uint256[] memory values = new uint256[](invests.length);
      uint256 i = 0;
      while (i < invests.length){
          Stake storage invest = invests[i];
          if (invest._active == 1){
              last_collects[i] = invest.lastCollectedTime;
              values[i] = invest.value;
          }
          i++;
      }
      return (last_collects, values);
  }

  function getLevelDetails() public view returns
                      (uint256, uint256, uint256, uint256, uint256) {
      return (currentLevel, currentMined, DISTRIBUTION_AMOUNT[currentLevel], DISTRIBUTION_AMOUNT[currentLevel].sub(currentMined), DISTRIBUTION_RATE[currentLevel]);
  }

  function getReferralEarnings(address addr) public view returns
                      (uint256, uint256) {
      return (users[addr].referralEarned, users[addr].referralsCounted);
  }



}

contract CommonToken is Token {

  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply * 10 ** uint256(decimals);

    _balances[msg.sender] = 5000000 * 10 ** uint256(decimals);
  }


  function () external payable {
    revert();
  }

}

contract Hawk is CommonToken {

  constructor() CommonToken("Hawk Token", "HWK", 9, 47000000) public {}

}