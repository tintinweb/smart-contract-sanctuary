/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal virtual view returns (address) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface RoboDogeCoin {
  function forceEop() external view returns (bool);
  function toggleForceEop() external;
  function reflectionFromToken(uint256 _amount, bool _deductFee) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function tokenFromReflection(uint256 _amount) external view returns (uint256);
  function balanceOf(address _address) external view returns (uint256);
  function mint(uint256 _amount) external;
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferOwnership(address _owner) external;
  function excludeAccount(address _address) external;
  function includeAccount(address _address) external;
  function setReservePool(address _address) external;
  function setLiquidityPoolAddress(address _address, bool _add) external;
  function setThreshold(uint256 _threshold) external;
  function setRule(uint256 _rule) external;
  function setRestrictionDuration(uint256 _minutes) external;
  function toggleLockTransfer() external;
  function lockTransfer() external view returns (bool);
  function lockedTill(address _address) external view returns (uint256);
  function lock(address _address, uint256 _days) external;
  function unlock(address _address) external;
  function setLimit(address _address, uint256 _period, uint256 _rule) external;
  function removeLimit(address _address) external;
  function excludeFromFee(address account) external;
  function includeFromFee(address account) external;
  function setReflectionFee(uint256 fee) external;
  function setLiquidityFee(uint256 fee) external;
  function setCharityFee(uint256 fee) external;
  function setBurnPercent(uint256 fee) external;
  function setMarketingFee(uint256 fee) external;
  function setEarlySellFee(uint256 fee) external;
  function setCharityAddress(address _address) external;
  function setRouterAddress(address _address) external;
  function setLiquidityManager(address _address) external;
  function setMarketingAddress(address _Address) external;
  function PrepareForPreSale() external;
  function afterPreSale() external;
  function withdraw() external;
}

contract RoboDogeStaking is Ownable {
  using SafeMath for uint256;

  struct Stake {
    uint256 tAmount;
    uint256 rAmount;
    uint256 time;
    uint256 period;
    uint256 rate;
    bool isActive;
  }

  mapping(uint256 => uint256) public interestRate;
  mapping(address => Stake[]) public stakes;

  RoboDogeCoin private token;

  uint256 constant private DENOMINATOR = 10000;
  uint256 public rewardsDistributed;
  uint256 public rewardsPending;

  event TokenStaked(address account, uint256 stakeId, uint256 tokenAmount, uint256 timestamp, uint256 period);
  event TokenUnstaked(address account, uint256 tokenAmount, uint256 interest, uint256 timestamp);
  event StakingPeriodUpdated(uint256 period, uint256 rate);
  
  event RuleChanged(uint256 newRule);
  event ThresholdChanged(uint256 newThreshold);
  event RestrictionDurationChanged(uint256 newRestrictionDuration);
  event ForceEopToggle(bool forceEop);
  event LockTransferToggle(bool locked);

  modifier isValidStakeId(address _address, uint256 _id) {
    require(_id < stakes[_address].length, "Id is not valid");
    _;
  }

  constructor(address _address) {
    token = RoboDogeCoin(_address);
    
    interestRate[1] = 250;
    interestRate[6] = 1000;
    interestRate[12] = 3000;
  }

  function stakeToken(uint256 _amount, uint256 _period) external {
    require(interestRate[_period] != 0, "Staking period not valid");

    bool eopStateChanged;

    if (token.forceEop()) {
      eopStateChanged = true;
      token.toggleForceEop();
    }

    uint256 rAmount = token.reflectionFromToken(_amount, false);
    token.transferFrom(msg.sender, address(this), _amount);

    if (eopStateChanged) {
      token.toggleForceEop();
    }

    uint256 stakeId = stakes[msg.sender].length;
    rewardsPending = rewardsPending.add(_amount.mul(interestRate[_period]).div(DENOMINATOR));
    stakes[msg.sender].push(Stake(_amount, rAmount, block.timestamp, _period, interestRate[_period], true));

    emit TokenStaked(msg.sender, stakeId, _amount, block.timestamp, _period);
  }

  function unstakeToken(uint256 _id) external isValidStakeId(msg.sender, _id) {
    require(timeLeftToUnstake(msg.sender, _id) == 0, "Stake duration not over");
    require(stakes[msg.sender][_id].isActive, "Tokens already unstaked");

    Stake storage stake = stakes[msg.sender][_id];

    uint256 tAmount = token.tokenFromReflection(stake.rAmount);
    uint256 interest = stakingReward(msg.sender, _id);

    uint256 balance = token.balanceOf(address(this));
    if (balance < tAmount.add(interest)) {
      token.mint(tAmount.add(interest).sub(balance));
    }

    stake.isActive = false;
    rewardsPending = rewardsPending.sub(interest);
    rewardsDistributed = rewardsDistributed.add(interest);
    token.transfer(msg.sender, tAmount.add(interest));

    emit TokenUnstaked(msg.sender, tAmount, interest, block.timestamp);
  }

  function getStake(address _address, uint256 _id) external view isValidStakeId(_address, _id) returns (Stake memory) {
    return stakes[_address][_id];
  }

  function getAllStakes(address _address) external view returns (Stake[] memory) {
    return stakes[_address];
  }

  function reflectionReceived(address _address, uint256 _id) external view isValidStakeId(_address, _id) returns (uint256) {
    require(stakes[_address][_id].isActive, "Tokens already unstaked");

    Stake memory stake = stakes[_address][_id];

    return (token.tokenFromReflection(stake.rAmount) - stake.tAmount);
  }

  function timeLeftToUnstake(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (uint256) {
    require(stakes[_address][_id].isActive, "Tokens already unstaked");

    Stake memory stake = stakes[_address][_id];
    uint256 unstakeTime = stake.time + stake.period * 30 days;

    return (
      block.timestamp < unstakeTime ? unstakeTime - block.timestamp : 0
    );
  }

  function canUnstake(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (bool) {
    return (timeLeftToUnstake(_address, _id) == 0 && stakes[_address][_id].isActive);
  }

  function stakingReward(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (uint256) {
    Stake memory stake = stakes[_address][_id];

    return stake.tAmount.mul(stake.rate).div(DENOMINATOR);
  }

  function addStakingPeriod(uint256 _period, uint256 _rate) external onlyOwner {
    interestRate[_period] = _rate;

    emit StakingPeriodUpdated(_period, _rate);
  }

  function changeTokenOwnership(address _owner) external onlyOwner {
    token.transferOwnership(_owner);
  }

  function excludeAccount(address account) external onlyOwner {
    token.excludeAccount(account);
  }

  function includeAccount(address account) external onlyOwner {
    token.includeAccount(account);
  }

  function setReservePool(address _address) external onlyOwner {
    token.setReservePool(_address);
  }

  function setLiquidityPoolAddress(address _address, bool _add) external onlyOwner {
    token.setLiquidityPoolAddress(_address, _add);
  }

  function setThreshold(uint256 _threshold) external onlyOwner {
    token.setThreshold(_threshold);

    emit ThresholdChanged(_threshold);
  }

  function setRule(uint256 _rule) external onlyOwner {
    token.setRule(_rule);

    emit RuleChanged(_rule);
  }

  function setRestrictionDuration(uint256 _minutes) external onlyOwner {
    token.setRestrictionDuration(_minutes);

    emit RestrictionDurationChanged(_minutes);
  }

  function toggleForceEop() external onlyOwner {
    token.toggleForceEop();

    emit ForceEopToggle(token.forceEop());
  }

  function toggleLockTransfer() external onlyOwner {
    token.toggleLockTransfer();

    emit LockTransferToggle(token.lockTransfer());
  }

  function lock(address _address, uint256 _days) external onlyOwner {
    require(token.lockedTill(_address) == 0, "Address is already locked");
    token.lock(_address, _days);
  }

  function unlock(address _address) external onlyOwner {
    token.unlock(_address);
  }

  function setLimit(address _address, uint256 _period, uint256 _rule) external onlyOwner {
    token.setLimit(_address, _period, _rule);
  }

  function removeLimit(address _address) external onlyOwner {
    token.removeLimit(_address);
  }

  function excludeFromFee(address account) external onlyOwner {
    token.excludeFromFee(account);
  }

  function includeFromFee(address account) external onlyOwner {
    token.includeFromFee(account);
  }

  function setReflectionFee(uint256 fee) external onlyOwner {
    token.setReflectionFee(fee);
  }

  function setLiquidityFee(uint256 fee) external onlyOwner {
    token.setLiquidityFee(fee);
  }

  function setCharityFee(uint256 fee) external onlyOwner {
    token.setCharityFee(fee);
  }

  function setBurnPercent(uint256 fee) external onlyOwner {
    token.setBurnPercent(fee);
  }

  function setMarketingFee(uint256 fee) external onlyOwner {
    token.setMarketingFee(fee);
  }

  function setEarlySellFee(uint256 fee) external onlyOwner {
    token.setEarlySellFee(fee);
  }

  function setCharityAddress(address _Address) external onlyOwner {
    token.setCharityAddress(_Address);
  }

  function setRouterAddress(address _Address) external onlyOwner {
    token.setRouterAddress(_Address);
  }

  function setLiquidityManager(address _address) external onlyOwner {
    token.setLiquidityManager(_address);
  }

  function setMarketingAddress(address _Address) external onlyOwner {
    token.setMarketingAddress(_Address);
  }

  function PrepareForPreSale() external onlyOwner {
    token.PrepareForPreSale();
  }

  function afterPreSale() external onlyOwner {
    token.afterPreSale();
  }

  receive() external payable {}

  function withdraw() external onlyOwner {
    token.withdraw();
    payable(msg.sender).transfer(address(this).balance);
  }
}