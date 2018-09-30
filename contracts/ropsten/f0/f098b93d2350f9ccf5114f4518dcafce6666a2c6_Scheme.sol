pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/* import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; */

contract Scheme is Ownable {
  using SafeMath for uint256;

  uint constant DECIMALS = 1e18;
  uint constant MAX_BUY_AMOUNT = 10 * DECIMALS;
  uint constant MAX_RATE = 2;
  uint constant UT_OF_ETH_RATE = 1000;
  uint ROOT_CODE;
  uint codeIncrement;
  uint public buyAmountTotal;
  uint public awardAmountTotal;

  uint randNonce;

  struct User {
    address addr;
    uint code;
    uint parentCode;

    uint buyAmount;
    uint rate;

    uint userRewardTotal;
    uint userWithdrawTotal;
    uint freeRewardCount;

    uint invite;

    /* uint level1;
    uint level2;
    uint level3;
    uint level4;
    uint level5;
    uint level6; */
  }

  struct Lucy {
    address lucyer0;
    address lucyer1;
    address lucyer2;
    uint lucyBonus0;
    uint lucyBonus1;
    uint lucyBonus2;
  }

  mapping (address => User) users;
  mapping (uint => address) codes;
  mapping (address => bool) blacklist;
  address[] addrs;
  address[] lucyAddrs;
  uint[] allBonuses;
  Lucy[] lucies;

  uint public teamBonusPercent;
  uint public allBonusPercent;
  uint public lucyBonusPercent1;
  uint public lucyBonusPercent2;
  uint public lucyBonusPercent3;
  uint public lucyBonusLimitEth1;
  uint public lucyBonusLimitEth2;
  uint public lucyBonusLimitEth3;

  event Sign(address indexed _from, uint _parentCode);
  event Buy(address indexed _from, uint _value);
  event Reward(address indexed _addr, uint _value);
  event Withdrawal(address indexed _from, uint _value);
  event Exit(address indexed _from, uint _value);
  event ShareBonus(
    address indexed _from,
    uint _amount,
    address _owner,
    uint _teamBonusPercent,
    uint _teamBonus,
    uint _allBonusPercent,
    uint _allBonus
  );

  constructor(uint _rootCode) public {
    teamBonusPercent = 5;
    allBonusPercent = 50;
    lucyBonusPercent1 = 15;
    lucyBonusPercent2 = 10;
    lucyBonusPercent3 = 5;
    lucyBonusLimitEth1 = 8;
    lucyBonusLimitEth2 = 4;
    lucyBonusLimitEth3 = 2;

    ROOT_CODE = _rootCode;
    codeIncrement = _rootCode;

    uint code = _generateCode();
    users[msg.sender] = User(msg.sender, code, ROOT_CODE, MAX_BUY_AMOUNT, MAX_RATE, 0, 0, 0, 0);
    codes[code] = msg.sender;
    addrs.push(msg.sender);
  }

  function sign(uint _parentCode) public {
    address addr = msg.sender;
    require(users[addr].addr == address(0), &#39;The wallet account has been registered.&#39;);
    require(codes[_parentCode] != address(0), &#39;The invitation code does not exist.&#39;);

    uint code = _generateCode();
    users[addr] = User(addr, code, _parentCode, 0, 0, 0, 0, 0, 0);
    codes[code] = addr;
    addrs.push(addr);
    emit Sign(addr, _parentCode);

    // 邀请人数统计
    if (_parentCode != ROOT_CODE) {
      address pAddr = codes[_parentCode];
      User storage pUser = users[pAddr];
      pUser.invite = pUser.invite.add(1);
    }
  }

  function buy() public payable {
    require(!blacklist[msg.sender], &#39;This wallet account is on the blacklist.&#39;);

    address addr = msg.sender;
    uint weiAmount = msg.value;
    require(weiAmount > 0, &#39;The purchase must be greater than zero.&#39;);

    uint buyAmount = users[addr].buyAmount.add(weiAmount);
    require(buyAmount <= MAX_BUY_AMOUNT, &#39;Exceeding the maximum limit.&#39;);

    // 合约总计购买金额
    buyAmountTotal = buyAmountTotal.add(weiAmount);
    // 当前用户购买金额及奖励比率
    users[addr].buyAmount = buyAmount;
    users[addr].rate = _getRate(buyAmount);
    emit Buy(addr, weiAmount);

    // 达到抽奖标准
    if (buyAmount >= lucyBonusLimitEth3.mul(DECIMALS)) {
      lucyAddrs.push(addr);
    }

    // 邀请人奖励
    _rewards(users[addr].parentCode, weiAmount);
  }

  function isExit() public view returns(bool) {
    return blacklist[msg.sender];
  }

  function getUserCount() public view returns(uint) {
    return addrs.length;
  }

  function getUser()
    public
    view
    returns(
      address addr,
      uint code,
      uint parentCode,

      uint buyAmount,
      uint rate,

      uint userRewardTotal,
      uint userWithdrawTotal,
      uint freeRewardCount,

      uint invite

      /* uint level1,
      uint level2,
      uint level3,
      uint level4,
      uint level5,
      uint level6 */
    )
  {
    User storage user = users[msg.sender];

    addr = user.addr;
    code = user.code;
    parentCode = user.parentCode;
    buyAmount = user.buyAmount;
    rate = user.rate;
    userRewardTotal = user.userRewardTotal;
    userWithdrawTotal = user.userWithdrawTotal;
    freeRewardCount = user.freeRewardCount;
    invite = user.invite;
  }

  function getLucy()
    public
    view
    returns(
      address lucyer0,
      address lucyer1,
      address lucyer2,
      uint lucyBonus0,
      uint lucyBonus1,
      uint lucyBonus2
    )
  {
    if (lucies.length > 0) {
      Lucy storage lucy = lucies[lucies.length.sub(1)];

      lucyer0 = lucy.lucyer0;
      lucyer1 = lucy.lucyer1;
      lucyer2 = lucy.lucyer2;
      lucyBonus0 = lucy.lucyBonus0;
      lucyBonus1 = lucy.lucyBonus1;
      lucyBonus2 = lucy.lucyBonus2;
    } else {
      lucyer0 = address(0);
      lucyer1 = address(0);
      lucyer2 = address(0);
      lucyBonus0 = 0;
      lucyBonus1 = 0;
      lucyBonus2 = 0;
    }
  }

  function getAllBonus() public view returns(uint) {
    if (allBonuses.length > 0) {
      return allBonuses[allBonuses.length - 1];
    }
    return 0;
  }

  function safeWithdrawal() public {
    require(!blacklist[msg.sender], &#39;This wallet account is on the blacklist.&#39;);

    User storage user = users[msg.sender];

    uint amount = user.userRewardTotal.sub(user.userWithdrawTotal);
    require(amount > 0, &#39;No cash withdrawals available.&#39;);

    user.userWithdrawTotal = user.userWithdrawTotal.add(amount);
    msg.sender.transfer(amount);
    emit Withdrawal(msg.sender, amount);
  }

  function safeExit() public {
    require(!blacklist[msg.sender], &#39;This wallet account is on the blacklist.&#39;);

    User storage user = users[msg.sender];
    uint buyAmount = user.buyAmount;
    uint userRewardTotal = user.userRewardTotal;
    uint userWithdrawTotal = user.userWithdrawTotal;
    require(userRewardTotal < buyAmount, &#39;Cost recovered.&#39;);

    uint amount = buyAmount.sub(userWithdrawTotal);
    uint unAwardAmountTotal = buyAmountTotal.sub(awardAmountTotal).add(userRewardTotal.sub(userWithdrawTotal));
    require(amount <= unAwardAmountTotal, &#39;Lack of funds.&#39;);

    user.userWithdrawTotal = buyAmount;

    buyAmountTotal = buyAmountTotal.sub(buyAmount);
    awardAmountTotal = awardAmountTotal.sub(userRewardTotal);

    blacklist[user.addr] = true;

    msg.sender.transfer(amount);
    emit Exit(msg.sender, amount);
  }

  function setBonusParams(
    uint _teamBonusPercent,
    uint _allBonusPercent,
    uint _lucyBonusPercent1,
    uint _lucyBonusPercent2,
    uint _lucyBonusPercent3,
    uint _lucyBonusLimitEth1,
    uint _lucyBonusLimitEth2,
    uint _lucyBonusLimitEth3
  )
    public
    onlyOwner
  {
    teamBonusPercent = _teamBonusPercent;
    allBonusPercent = _allBonusPercent;
    lucyBonusPercent1 = _lucyBonusPercent1;
    lucyBonusPercent2 = _lucyBonusPercent2;
    lucyBonusPercent3 = _lucyBonusPercent3;
    lucyBonusLimitEth1 = _lucyBonusLimitEth1;
    lucyBonusLimitEth2 = _lucyBonusLimitEth2;
    lucyBonusLimitEth3 = _lucyBonusLimitEth3;
  }

  function shareBonus() public onlyOwner {
    uint amount = buyAmountTotal.sub(awardAmountTotal);
    require(amount > 0, &#39;No redemption bonus.&#39;);

    // 团队分红 5%
    uint teamBonus = amount.div(100).mul(teamBonusPercent);
    users[owner].userRewardTotal = users[owner].userRewardTotal.add(teamBonus);
    awardAmountTotal = awardAmountTotal.add(teamBonus);
    emit Reward(owner, teamBonus);

    // 全体分红 50%
    uint allBonus = amount.div(100).mul(allBonusPercent);
    _bonusAll(allBonus);
    awardAmountTotal = awardAmountTotal.add(allBonus);
    allBonuses.push(allBonus);

    // 幸运抽奖 3名，根据投入ETH奖励：[2-4)5%、[4-8)10%、[8-10)15%
    if (lucyAddrs.length > 0) {
      _bonusLucy(amount);
    }

    emit ShareBonus(msg.sender, amount, owner, teamBonusPercent, teamBonus, allBonusPercent, allBonus);
  }

  function _bonusLucy(uint _bonusAmount) private {
    Lucy memory lucy = Lucy(address(0), address(0), address(0), 0, 0, 0);

    for (uint i=0; i<3; i++) {
      address addr = _randomLucyAddr();
      User storage user = users[addr];
      uint buyAmount = user.buyAmount;

      uint lucyBonus;
      if (buyAmount >= lucyBonusLimitEth1.mul(DECIMALS)) {
        lucyBonus = _bonusAmount.div(100).mul(lucyBonusPercent1);
      } else if (buyAmount >= lucyBonusLimitEth2.mul(DECIMALS)) {
        lucyBonus = _bonusAmount.div(100).mul(lucyBonusPercent2);
      } else if (buyAmount >= lucyBonusLimitEth3.mul(DECIMALS)) {
        lucyBonus = _bonusAmount.div(100).mul(lucyBonusPercent3);
      }
      user.userRewardTotal = user.userRewardTotal.add(lucyBonus);
      awardAmountTotal = awardAmountTotal.add(lucyBonus);
      emit Reward(addr, lucyBonus);

      if (i == 0) {
        lucy.lucyer0 = addr;
        lucy.lucyBonus0 = lucyBonus;
      } else if (i == 1) {
        lucy.lucyer1 = addr;
        lucy.lucyBonus1 = lucyBonus;
      } else if (i == 2) {
        lucy.lucyer2 = addr;
        lucy.lucyBonus2 = lucyBonus;
      }
    }

    lucies.push(lucy);
  }

  function _randomLucyAddr() private returns(address) {
    uint random = uint(keccak256(abi.encodePacked(now, block.difficulty, randNonce))) % lucyAddrs.length;
    randNonce = randNonce.add(1);

    address addr = lucyAddrs[random];
    if (!blacklist[addr] && users[addr].buyAmount < lucyBonusLimitEth3.mul(DECIMALS)) {
      _randomLucyAddr();
    }

    return addr;
  }

  function _bonusAll(uint _allBonus) private {
    uint len = addrs.length;
    for (uint i=0; i<len; i++) {
      address addr = addrs[i];
      User storage user = users[addr];
      /* if (user.buyAmount > 0) {
        uint bonus = _allBonus.mul(user.buyAmount).div(buyAmountTotal);
        user.userRewardTotal = user.userRewardTotal.add(bonus);
        emit Reward(addr, bonus);
      } */
      uint ut = _getUt(addr);
      uint utTotal = _getUtTotal();
      if (!blacklist[addr] && ut > 0) {
        uint bonus = _allBonus.mul(ut).div(utTotal);
        user.userRewardTotal = user.userRewardTotal.add(bonus);
        emit Reward(addr, bonus);
      }
    }
  }

  function _rewards(uint _parentCode, uint _weiAmount) private {
    address addr = codes[_parentCode];

    if (!blacklist[addr] && _parentCode != ROOT_CODE) {
      User storage user = users[addr];

      // 赠送5次非零奖励（即直接邀请人购买或奖励不为零时）
      if (user.freeRewardCount < 5 && _weiAmount > 0) {
        uint freeAmount = _weiAmount.div(100);
        // 合约已分配奖励总计
        awardAmountTotal = awardAmountTotal.add(freeAmount);

        user.userRewardTotal = user.userRewardTotal.add(freeAmount);
        user.freeRewardCount = user.freeRewardCount.add(1);
        emit Reward(addr, freeAmount);
      }
      // 权益奖励
      uint rewardAmount = 0;
      if (user.rate > 0) {
        rewardAmount = _weiAmount.div(user.rate);
        // 合约已分配奖励总计
        awardAmountTotal = awardAmountTotal.add(rewardAmount);

        user.userRewardTotal = user.userRewardTotal.add(rewardAmount);
        emit Reward(addr, rewardAmount);
      }
    }
  }

  function _getUt(address _addr) private view returns(uint) {
    User storage user = users[_addr];
    return user.buyAmount.mul(UT_OF_ETH_RATE).div(DECIMALS).add(user.invite);
  }

  function _getUtTotal() private view returns(uint) {
    return buyAmountTotal.add(MAX_BUY_AMOUNT).mul(UT_OF_ETH_RATE).div(DECIMALS).add(addrs.length);
  }

  function _getRate(uint _buyAmount) private pure returns(uint) {
    return MAX_BUY_AMOUNT.mul(MAX_RATE).div(_buyAmount);
  }

  function _generateCode() private returns(uint) {
    codeIncrement = codeIncrement.add(1);
    return codeIncrement;
  }

}