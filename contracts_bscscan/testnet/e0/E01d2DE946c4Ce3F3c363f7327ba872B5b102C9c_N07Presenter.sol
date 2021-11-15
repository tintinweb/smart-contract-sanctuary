// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ITokenPresenter.sol";
import "./interfaces/IBurnable.sol";
import "./utils/AntiWhale.sol";
import "./utils/CoinDexTools.sol";
import "./utils/EmergencyWithdraw.sol";
import "./utils/RewardSharing.sol";
import "./utils/TradingGuard.sol";

// solhint-disable max-states-count use-forbidden-name
contract N07Presenter is
  ITokenPresenter,
  EmergencyWithdraw,
  AntiWhale,
  TradingGuard,
  CoinDexTools,
  RewardSharing,
  ReentrancyGuardUpgradeable
{
  struct Info {
    address addr;
    uint percentage;
    // side => 0: disable tax, 1: tax buy, 2: tax sell, 3: tax transfer,
    // 4: buy && sell, 5: buy && transfer, 6: sell && transfer, 7: all type
    uint side;
    bool isAdded;
    uint index;
  }

  address public token; // Main token
  mapping(address => bool) public isExcludedFromFees; // Excluded from fee address

  Info public lpInfo;
  uint public lpPending;
  Info public teamInfo;
  address[] public rewardTokens;
  mapping(address => Info) public rewardInfo;
  address[] public users;
  mapping(address => bool) public isUserAdded;
  uint public burnPercentage;
  uint public totalTax;

  // Check address is in blacklist
  mapping(address => bool) public isInBlacklist;

  /**
   * @dev Upgradable initializer
   */
  function __N07Presenter_init() public initializer {
    __Ownable_init();
    __CoinDexTools_init();
    __ReentrancyGuard_init();
  }

  /**
   * @dev setup the presenter, only call by owner
   * @param _token address of the main token
   * @param _router address of router exchange (Pancakeswap)
   * @param _burnPercentage burn percentage
   * @param _lpInfo lp info
   * @param _teamInfo team info
   * @param _rewardTokens array of tokens to add
   * @param _excludedAccounts list of excluded accounts
   */
  function setup(
    address _token,
    address _router,
    uint _burnPercentage,
    Info memory _lpInfo,
    Info memory _teamInfo,
    Info[] memory _rewardTokens,
    address[] memory _excludedAccounts
  ) public onlyOwner {
    token = _token;
    router = _router;
    burnPercentage = _burnPercentage;

    IPancakeRouter02 router_ = IPancakeRouter02(router);
    IPancakeFactory factory_ = IPancakeFactory(router_.factory());
    address lpAddress_ = factory_.getPair(token, router_.WETH());
    if (lpAddress_ == address(0)) {
      lpAddress_ = factory_.createPair(token, router_.WETH());
    }

    // Liquidity
    addOrUpdateLPInfo(lpAddress_, _lpInfo.percentage, _lpInfo.side);

    // Team
    addOrUpdateTeam(_teamInfo.addr, _teamInfo.percentage, _teamInfo.side);

    // Reward tokens
    for (uint i; i < _rewardTokens.length; i++) {
      Info memory info_ = _rewardTokens[i];
      addOrUpdateRewardToken(info_.addr, info_.percentage, info_.side);
    }

    // Exclude addresses
    excludeFromFees(address(this), true);
    excludeFromFees(owner(), true);
    excludeFromFees(deadAddress, true);
    for (uint i; i < _excludedAccounts.length; i++) {
      excludeFromFees(_excludedAccounts[i], true);
    }

    // Guard
    updateTradingConfig(TradingConfig(true, 0, 0), 1); // Block buy
    updateTradingConfig(TradingConfig(true, 0, 0), 2); // Block sell
  }

  /**
   * @dev set the main token
   * @param _token address of main token
   */
  function setToken(address _token) public onlyOwner {
    token = _token;
  }

  /**
   * @dev set the zero Address
   * @param _deadAddress address of zero
   */
  function setDeadAddress(address _deadAddress) external override onlyOwner {
    deadAddress = _deadAddress;
    isExcludedFromFees[_deadAddress] = true;
  }

  /**
   * @dev Override: Check this use is excluded from reward
   */
  function _isExcludedFromReward(address _userAddress) internal view override returns (bool) {
    return (isExcludedFromFees[_userAddress] || _userAddress == lpInfo.addr || _userAddress == router);
  }

  /**
   * @dev function to exclude a account from tax
   * @param _account account to exclude
   * @param _excluded state of excluded account true or false
   */
  function excludeFromFees(address _account, bool _excluded) public onlyOwner {
    require(isExcludedFromFees[_account] != _excluded, "N07Presenter: Excluded");
    isExcludedFromFees[_account] = _excluded;
  }

  /**
   * @dev function to block a account
   * @param _account account to exclude
   * @param _blocked state of excluded account true or false
   */
  function addToBlacklist(address _account, bool _blocked) public onlyOwner {
    require(isInBlacklist[_account] != _blocked, "N07Presenter: Blocked");
    isInBlacklist[_account] = _blocked;
  }

  /**
   * @dev set the burn percentage
   * @param _burnPercentage burn percentage
   */
  function setBurnPercentage(uint _burnPercentage) external onlyOwner {
    burnPercentage = _burnPercentage;
  }

  /**
   * @dev add or update liquidity provider token
   * @param _addr address of token
   * @param _percentage tax percentage of token
   * @param _side side
   */
  function addOrUpdateLPInfo(
    address _addr,
    uint _percentage,
    uint _side
  ) public onlyOwner {
    lpInfo.addr = _addr;
    lpInfo.percentage = _percentage;
    lpInfo.side = _side;
  }

  /**
   * @dev add or update team
   * @param _addr address of team
   * @param _percentage tax percentage of team
   * @param _side side
   */
  function addOrUpdateTeam(
    address _addr,
    uint _percentage,
    uint _side
  ) public onlyOwner {
    teamInfo.addr = _addr;
    teamInfo.percentage = _percentage;
    teamInfo.side = _side;
    isExcludedFromFees[_addr] = true;
  }

  /**
   * @dev get the tokens Length
   */
  function getRewardTokensLength() public view returns (uint) {
    return rewardTokens.length;
  }

  /**
   * @dev get the reward token list
   */
  function getRewardTokenList() external view returns (Info[] memory) {
    uint length = rewardTokens.length;
    Info[] memory allTokens = new Info[](length);
    for (uint i = 0; i < length; i++) {
      allTokens[i] = rewardInfo[rewardTokens[i]];
    }
    return allTokens;
  }

  /**
   * @dev add or update buy back/reward token
   * @param _addr address of token
   * @param _percentage tax percentage of token
   * @param _side side
   */
  function addOrUpdateRewardToken(
    address _addr,
    uint _percentage,
    uint _side
  ) public onlyOwner {
    Info storage info_ = rewardInfo[_addr];

    info_.addr = _addr;
    info_.percentage = _percentage;
    info_.side = _side;
    if (info_.isAdded == false) {
      info_.isAdded = true;
      info_.index = getRewardTokensLength();
      rewardTokens.push(_addr);

      addPool(_percentage);
    } else {
      updatePool(info_.index, _percentage);
    }
  }

  /**
   * @dev delist token
   * @param _tokenAddress address of token
   */
  function delistRewardToken(address _tokenAddress) external onlyOwner {
    Info storage info_ = rewardInfo[_tokenAddress];
    info_.side = 0;
  }

  /**
   * @dev get the users Length
   */
  function getUsersLength() external view returns (uint) {
    return users.length;
  }

  /**
   * @dev return users paging
   */
  function getUsersPaging(uint _offset, uint _limit)
    public
    view
    returns (
      address[] memory _users,
      uint _nextOffset,
      uint _total
    )
  {
    uint totalUsers = users.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    address[] memory values = new address[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = users[_offset + i];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /**
   * @dev add unregistered users/stakers
   * @param _from from address
   * @param _to to address
   */
  function _addUser(address _from, address _to) internal {
    if (isUserAdded[_from] == false) {
      users.push(_from);
      isUserAdded[_from] = true;
    }

    if (isUserAdded[_to] == false) {
      users.push(_to);
      isUserAdded[_to] = true;
    }
  }

  /**
   * @dev this is the main function to distribute the tokens call from only main token via external app
   * @param _trigger trigger address
   * @param _from from address
   * @param _to to address
   * @param _amount amount of tokens
   */
  function receiveTokens(
    address _trigger,
    address _from,
    address _to,
    uint256 _amount
  ) public override returns (bool) {
    require(_msgSender() == token, "N07Presenter: Token only");
    require(!isWhale(_from, _to, _amount), "Error: No time for whales!");
    if (_from != owner() && _to != owner()) {
      require(!isInBlacklist[_from] && !isInBlacklist[_to], "Error: Address is blocked!");
    }

    _addUser(_from, _to);

    // Transaction type detail
    bool[9] memory flags;
    // Trigger from router
    //bool isViaRouter = _trigger == router;
    flags[0] = _trigger == router;
    // Trigger from lp pair
    //bool isViaLP = _trigger == lpInfo.addr;
    flags[1] = _trigger == lpInfo.addr;
    // Check is to user = _to not router && not lp
    //bool isToUser = (_to != lpInfo.addr && _to != router);
    flags[2] = (_to != lpInfo.addr && _to != router);
    // Check is from user = _from not router && not lp
    //bool isFromUser = (_from != lpInfo.addr && _from != router);
    flags[3] = (_from != lpInfo.addr && _from != router);
    // In case remove LP
    //bool isRemoveLP = (_from == lpInfo.addr && _to == router) || (_from == router && isToUser);
    flags[4] = (_from == lpInfo.addr && _to == router) || (_from == router && flags[2]);
    // In case buy: LP transfer to user directly
    //bool isBuy = isViaLP && _from == lpInfo.addr && isToUser;
    flags[5] = flags[1] && _from == lpInfo.addr && flags[2];
    // In case sell (Same with add LP case): User send to LP via router (using transferFrom)
    //bool isSell = isViaRouter && (isFromUser && _to == lpInfo.addr);
    flags[6] = flags[0] && (flags[3] && _to == lpInfo.addr);
    // In case normal transfer
    //bool isTransfer = !isBuy && !isSell && !isRemoveLP;
    flags[7] = !flags[5] && !flags[6] && !flags[4];
    // Exclude from fees
    //bool isExcluded = isExcludedFromFees[_from] || isExcludedFromFees[_to];
    flags[8] = isExcludedFromFees[_from] || isExcludedFromFees[_to];

    // Logic
    if (flags[8] || flags[4]) {
      if (isExcludedFromFees[_from] && !isExcludedFromFees[_to] && flags[2]) {
        // In case: owner send to user, same with buy case
        _taxCollectorFull(_from, _to, _amount, 1, true);
      } else if (!isExcludedFromFees[_from] && isExcludedFromFees[_to] && flags[3]) {
        // In case: user send to owner, same with sell case
        _taxCollectorFull(_from, _to, _amount, 2, true);
      } else {
        IERC20(token).transfer(_to, _amount);
      }
    } else {
      if (flags[7]) {
        if (!transferConfig.enabled || (transferConfig.maxAmount >= _amount && transferConfig.minAmount <= _amount)) {
          _taxCollectorNormal(_from, _to, _amount, 0);
        } else {
          return false;
        }
      } else if (flags[5]) {
        if (!buyConfig.enabled || (buyConfig.maxAmount >= _amount && buyConfig.minAmount <= _amount)) {
          _taxCollectorNormal(_from, _to, _amount, 1);
        } else {
          return false;
        }
      } else if (flags[6]) {
        // Remove tax, but consider 2 cases here:
        // (1): normal sell via psc => transfer all remaining reward to team
        // (2): claim case -> this contract trigger sell internally
        bool isClaim_ = _from == address(this);
        if (isClaim_) {
          IERC20(token).transfer(_to, _amount);
        } else {
          if (!sellConfig.enabled || (sellConfig.maxAmount >= _amount && sellConfig.minAmount <= _amount)) {
            _taxCollectorNormal(_from, _to, _amount, 2);
          } else {
            return false;
          }
        }
      }
    }
    return true;
  }

  /**
   * @dev update all portion reward
   * @param _from from address
   * @param _to to address
   * @param _amount amount of tokens
   * @param _code transfer type: 0: transfer, 1: buy, 2: sell
   */
  function _taxCollectorNormal(
    address _from,
    address _to,
    uint _amount,
    uint _code
  ) internal {
    _taxCollectorFull(_from, _to, _amount, _code, false);
  }

  /**
   * @dev update all portion reward
   * @param _from from address
   * @param _to to address
   * @param _amount amount of tokens
   * @param _code transfer type: 0: transfer, 1: buy, 2: sell
   * @param _isTaxLess in case owner send to user or vice versa, not apply tax but save total staked
   */
  function _taxCollectorFull(
    address _from,
    address _to,
    uint _amount,
    uint _code,
    bool _isTaxLess
  ) internal nonReentrant {
    uint txTax_ = 0;
    // Reflections
    for (uint i; i < rewardTokens.length; i++) {
      Info storage pool_ = rewardInfo[rewardTokens[i]];
      if (pool_.side > 0 && (_isTaxLess || _checkSide(pool_.side, _code))) {
        (uint _tax, ) = _updatePortion(pool_.index, _from, _to, _amount, _code, _isTaxLess);
        if (_tax > 0) {
          txTax_ += _tax;
        }
      }
    }

    if (!_isTaxLess) {
      // Team
      if (_checkSide(teamInfo.side, _code)) {
        uint teamTax_ = (_amount * teamInfo.percentage) / RATE_NOMINATOR;
        if (teamTax_ > 0) {
          txTax_ += teamTax_;
          // solhint-disable reentrancy
          IERC20(token).transfer(teamInfo.addr, teamTax_);
        }
      }

      // LP
      if (_checkSide(lpInfo.side, _code)) {
        uint lpTax_ = (_amount * lpInfo.percentage) / RATE_NOMINATOR;
        if (lpTax_ > 0) {
          txTax_ += lpTax_;
          lpPending += lpTax_;
        }
      }

      // Burn
      uint burnTax_ = (_amount * burnPercentage) / RATE_NOMINATOR;
      if (burnTax_ > 0) {
        txTax_ += burnTax_;
        IBurnable(token).burn(burnTax_);
      }
    }

    // Transfer
    if (_amount > txTax_) {
      totalTax += txTax_;
      // solhint-disable reentrancy
      IERC20(token).transfer(_to, _amount - txTax_);
    }
  }

  /**
   * @dev check apply tax or not by Side
   * @param _code transfer type: 0: transfer, 1: buy, 2: sell
   * @param _side Info side
   */
  function _checkSide(uint _side, uint _code) internal pure returns (bool) {
    // _side => 0: disable tax, 1: tax buy, 2: tax sell, 3: tax transfer,
    // 4: buy && sell, 5: buy && transfer, 6: sell && transfer, 7: all type
    return
      (_side == 1 && _code == 1) ||
      (_side == 2 && _code == 2) ||
      (_side == 3 && _code == 0) ||
      (_side == 4 && (_code == 1 || _code == 2)) ||
      (_side == 5 && (_code == 0 || _code == 1)) ||
      (_side == 6 && (_code == 0 || _code == 2)) ||
      (_side == 7);
  }

  /**
   * @dev claim pending reward
   */
  function claim() external {
    // Withdraw reward
    uint bal_ = IERC20(token).balanceOf(address(this));
    for (uint i; i < rewardTokens.length; i++) {
      Info storage pool_ = rewardInfo[rewardTokens[i]];
      uint reward_ = _withdrawPendingReward(pool_.index, _msgSender());
      if (reward_ > bal_) {
        reward_ = bal_;
      }
      if (reward_ > 0) {
        _swapTokensForTokens(token, rewardTokens[i], reward_, _msgSender(), false);
        bal_ -= reward_;
      }
    }
    // Add LP
    solvePendingLP();
  }

  /**
   * @dev solve pending LP
   */
  function solvePendingLP() public {
    uint bal_ = IERC20(token).balanceOf(address(this));
    uint pend_ = lpPending;
    if (pend_ > bal_) {
      pend_ = bal_;
    }
    if (pend_ > 0) {
      _swapAndLiquify(token, pend_, owner());
      lpPending = 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TradingGuard is OwnableUpgradeable {
  // Config structure
  struct TradingConfig {
    bool enabled;
    uint maxAmount;
    uint minAmount;
  }

  TradingConfig public buyConfig;
  TradingConfig public sellConfig;
  TradingConfig public transferConfig;

  /**
   * @dev update trading config
   * @param _config TradingConfig object
   * @param _code 0: transfer, 1: buy, otherwise: sell
   */
  function updateTradingConfig(TradingConfig memory _config, uint _code) public onlyOwner {
    TradingConfig storage config;
    if (_code == 0) config = transferConfig;
    else if (_code == 1) config = buyConfig;
    else config = sellConfig;

    config.enabled = _config.enabled;
    config.maxAmount = _config.maxAmount;
    config.minAmount = _config.minAmount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @author nhancv
// @title Reward sharing implementation -
// see https://github.com/nhancv/nideas/blob/main/RewardSharing.pdf
// solhint-disable
contract RewardSharing is OwnableUpgradeable {
  uint internal constant RATE_NOMINATOR = 10000;
  uint internal constant PRECISION_FACTOR = 1e36;

  // Pool structure
  struct PoolInfo {
    uint l; // Last portion map index
    mapping(uint => uint) r; // Portion reward mapping
    mapping(address => uint) urc; // User’s reward accumulation
    mapping(address => uint) up; // User’s portion reward offset
    mapping(address => uint) ud; // User’s debt
    mapping(address => uint) ub; // User’s balance
    uint t; // Total staked
    uint pool; // Total pool reward
    uint distributed; // Distributed reward
    uint fee; // fee percent, ex: 100 mean 1%
  }

  // Pool array
  PoolInfo[] public pools;

  /**
   * @dev get the pools Length
   */
  function getPoolsLength() public view returns (uint) {
    return pools.length;
  }

  /**
   * @dev remove pool
   * @param _fee fee of pool
   */
  function addPool(uint _fee) public virtual onlyOwner {
    uint256 idx_ = getPoolsLength();
    pools.push();

    PoolInfo storage info_ = pools[idx_];
    info_.fee = _fee;
  }

  /**
   * @dev update pool
   * @param _index index of pool
   * @param _fee pool fee
   */
  function updatePool(uint _index, uint _fee) public virtual onlyOwner {
    PoolInfo storage info_ = pools[_index];
    info_.fee = _fee;
  }

  /**
   * @dev remove pool
   * @param _index index of pool
   */
  function removePool(uint _index) public virtual onlyOwner {
    delete pools[_index];
  }

  /**
   * @dev update pool config
   * @param _index index of pool
   * @param _totalStaked total staked
   * @param _poolReward total pool reward
   * @param _distributed distributed reward
   * @param _fee fee percent, ex: 100 mean 1%
   */
  function updatePoolConfig(
    uint _index,
    uint _totalStaked,
    uint _poolReward,
    uint _distributed,
    uint _fee
  ) public virtual onlyOwner {
    PoolInfo storage info_ = pools[_index];
    info_.t = _totalStaked;
    info_.pool = _poolReward;
    info_.distributed = _distributed;
    info_.fee = _fee;
  }

  /**
   * @dev update pool's last portion index
   * @param _index index of pool
   * @param _portionIndex portion map last index
   */
  function updatePoolPortionIndex(uint _index, uint _portionIndex) public virtual onlyOwner {
    PoolInfo storage info_ = pools[_index];
    info_.l = _portionIndex;
  }

  /**
   * @dev update pool portion map data
   * @param _index index of pool
   * @param _offset portion reward offset
   * @param _data portion reward mapping
   */
  function updatePoolPortionMap(
    uint _index,
    uint _offset,
    uint[] memory _data
  ) public virtual onlyOwner {
    uint dataLength_ = _data.length;
    require(dataLength_ > 0, "Empty");
    PoolInfo storage info_ = pools[_index];
    info_.l = _offset + dataLength_ - 1;
    for (uint i = 0; i < dataLength_; i++) {
      info_.r[_offset + i] = _data[i];
    }
  }

  /**
   * @dev update pool user's data
   * @param _users user's address list
   * @param _urc user’s reward accumulation
   * @param _up user’s portion reward offset
   * @param _ud user’s debt
   * @param _ub user’s balance
   */
  function updatePoolUsersData(
    uint _index,
    address[] memory _users,
    uint[] memory _urc,
    uint[] memory _up,
    uint[] memory _ud,
    uint[] memory _ub
  ) public virtual onlyOwner {
    uint dataLength_ = _users.length;
    require(dataLength_ > 0, "Empty");
    PoolInfo storage info_ = pools[_index];
    for (uint i = 0; i < dataLength_; i++) {
      info_.urc[_users[i]] = _urc[i];
      info_.up[_users[i]] = _up[i];
      info_.ud[_users[i]] = _ud[i];
      info_.ub[_users[i]] = _ub[i];
    }
  }

  /**
   * @dev update portion reward. Call this function before real transfer token
   * @param _index pool index
   * @param _fromAddress from address
   * @param _toAddress to address
   * @param _amount amount of tokens
   * @param _code transfer type: 0: transfer, 1: buy, 2: sell
   * @param _isTaxLess in case owner send to user or vice versa, not apply tax but save total staked
   */
  function _updatePortion(
    uint _index,
    address _fromAddress,
    address _toAddress,
    uint _amount,
    uint _code,
    bool _isTaxLess
  ) internal virtual returns (uint, uint) {
    PoolInfo storage info_ = pools[_index];

    address tp_;
    uint tax_ = 0;
    if (!_isTaxLess) tax_ = (info_.fee * _amount) / RATE_NOMINATOR;
    uint afterTax_ = _amount - tax_;
    info_.pool = info_.pool + tax_;

    if (_code == 1) {
      info_.t = info_.t + afterTax_;
      tp_ = _toAddress;
    } else if (_code == 0) {
      if (info_.t >= tax_) info_.t = info_.t - tax_;
      tp_ = _toAddress;

      info_.urc[_fromAddress] = info_.urc[_fromAddress] + getPortionReward(_index, _fromAddress);
      info_.up[_fromAddress] = info_.l + 1;
    } else {
      if (info_.t >= _amount) info_.t = info_.t - _amount;
      tp_ = _fromAddress;
    }

    // Update user offset and portion first
    info_.urc[tp_] = info_.urc[tp_] + getPortionReward(_index, tp_);
    info_.up[tp_] = info_.l + 1;

    // Update reward portion
    uint t_ = 0;
    if (info_.t > 0) t_ = (tax_ * PRECISION_FACTOR) / info_.t;
    info_.r[info_.l + 1] = info_.r[info_.l] + t_;
    info_.l = info_.l + 1;

    // Update user balance
    _updateBalance(_index, _fromAddress, address(this), tax_);
    _updateBalance(_index, _fromAddress, _toAddress, afterTax_);

    return (tax_, afterTax_);
  }

  /**
   * @dev Update user balance
   */
  function _updateBalance(
    uint _index,
    address _fromAddress,
    address _toAddress,
    uint _amount
  ) internal virtual {
    PoolInfo storage info_ = pools[_index];
    if (info_.ub[_fromAddress] >= _amount) {
      info_.ub[_fromAddress] -= _amount;
    } else {
      info_.ub[_fromAddress] = 0;
    }

    info_.ub[_toAddress] += _amount;
  }

  /**
   * @dev Check this use is excluded from reward
   */
  function _isExcludedFromReward(address) internal view virtual returns (bool) {
    return false;
  }

  /**
   * @dev Get user balance. Return 0 if user is excluded from reward
   */
  function _userBalance(uint _index, address _userAddress) internal view virtual returns (uint) {
    if (_isExcludedFromReward(_userAddress)) return 0;
    PoolInfo storage info_ = pools[_index];
    return info_.ub[_userAddress];
  }

  /**
   * @dev Get user portion reward function
   */
  function getPortionReward(uint _index, address _userAddress) public view virtual returns (uint) {
    PoolInfo storage info_ = pools[_index];
    uint portion = info_.up[_userAddress];
    if (portion == 0) {
      portion = 1;
    }
    if (info_.r[info_.l] >= info_.r[portion - 1]) {
      return (info_.r[info_.l] - info_.r[portion - 1]) * _userBalance(_index, _userAddress);
    }
    return 0;
  }

  /**
   * @dev Get user max reward function
   */
  function getMaxReward(uint _index, address _userAddress) public view virtual returns (uint) {
    PoolInfo storage info_ = pools[_index];
    return (getPortionReward(_index, _userAddress) + info_.urc[_userAddress]) / PRECISION_FACTOR;
  }

  /**
   * @dev Get user’s pending reward amount function
   */
  function getPendingReward(uint _index, address _userAddress) public view virtual returns (uint) {
    PoolInfo storage info_ = pools[_index];
    uint total_ = getMaxReward(_index, _userAddress);
    if (total_ > info_.ud[_userAddress]) {
      return total_ - info_.ud[_userAddress];
    }
    return 0;
  }

  /**
   * @dev Withdraw user’s pending reward amount function.
   * This function get pending reward and update user debt after withdraw
   * Need implement new withdraw function in main contract.
   * Call this function to get reward and send token as your logic
   */
  function _withdrawPendingReward(uint _index, address _userAddress) internal virtual returns (uint) {
    uint reward_ = getPendingReward(_index, _userAddress);
    PoolInfo storage info_ = pools[_index];
    info_.distributed += reward_;
    info_.ud[_userAddress] += reward_;
    return reward_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) public view onlyOwner returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(owner(), getTokenBalance(_tokenAddress));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";

contract CoinDexTools is OwnableUpgradeable {
  address public router;
  address public deadAddress;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event SwapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  );

  /**
   * @dev Upgradable initializer
   */
  function __CoinDexTools_init() internal virtual initializer {
    deadAddress = 0x000000000000000000000000000000000000dEaD;
  }

  /**
   * @dev set exchange router
   * @param _router address of main token
   */
  function setRouter(address _router) external virtual onlyOwner {
    router = _router;
  }

  /**
   * @dev set the zero Address
   * @param _deadAddress address of zero
   */
  function setDeadAddress(address _deadAddress) external virtual onlyOwner {
    deadAddress = _deadAddress;
  }

  /**
   * @dev swap tokens. Auto swap to ETH directly if _tokenAddressTo == weth
   * @param _tokenAddressFrom address of from token
   * @param _tokenAddressTo address of to token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   * @param _keepWETH For _tokenAddressTo == weth, _keepWETH = true if you want to keep output WETH instead of ETH native
   */
  function _swapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  ) internal virtual {
    IERC20(_tokenAddressFrom).approve(router, _tokenAmount);

    address weth = IPancakeRouter02(router).WETH();
    bool isNotToETH = _tokenAddressTo != weth;
    address[] memory path;
    if (isNotToETH) {
      path = new address[](3);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
      path[2] = _tokenAddressTo;
    } else {
      path = new address[](2);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
    }

    // Make the swap
    if (isNotToETH || _keepWETH) {
      IPancakeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    } else {
      IPancakeRouter02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    }

    emit SwapTokensForTokens(_tokenAddressFrom, _tokenAddressTo, _tokenAmount, _to, _keepWETH);
  }

  /**
   * @dev swap tokens to ETH
   * @param _tokenAddress address of from token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapTokensForETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    _swapTokensForTokens(_tokenAddress, IPancakeRouter02(router).WETH(), _tokenAmount, _to, false);
  }

  /**
   * @dev add liquidity in pair
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _ethAmount amount of eth tokens
   * @param _to recipient
   */
  function _addLiquidityETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    uint256 _ethAmount,
    address _to
  ) internal virtual {
    // approve token transfer to cover all possible scenarios
    IERC20(_tokenAddress).approve(router, _tokenAmount);

    // add the liquidity
    IPancakeRouter02(router).addLiquidityETH{ value: _ethAmount }(
      address(_tokenAddress),
      _tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      _to,
      block.timestamp
    );
  }

  /**
   * @dev swap tokens and add liquidity
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapAndLiquify(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    // split the contract balance into halves
    uint256 half = _tokenAmount / 2;
    if (half > 0) {
      uint256 otherHalf = _tokenAmount - half;

      // capture the contract's current ETH balance.
      // this is so that we can capture exactly the amount of ETH that the
      // swap creates, and not make the liquidity event include any ETH that
      // has been manually sent to the contract
      uint256 initialBalance = address(this).balance;

      // swap tokens for ETH
      _swapTokensForETH(_tokenAddress, half, address(this));

      // how much ETH did we just swap into?
      uint256 swappedETHAmount = address(this).balance - initialBalance;

      // add liquidity to dex
      if (swappedETHAmount > 0) {
        _addLiquidityETH(_tokenAddress, otherHalf, swappedETHAmount, _to);
        emit SwapAndLiquify(half, swappedETHAmount, otherHalf);
      }
    }
  }

  /**
   * @dev burn by transfer to dead address
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   */
  function _burnByDeadAddress(address _tokenAddress, uint256 _tokenAmount) internal virtual {
    IERC20(_tokenAddress).transfer(deadAddress, _tokenAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AntiWhale is OwnableUpgradeable {
  uint256 public startDate;
  uint256 public endDate;
  uint256 public limitWhale;
  bool public antiWhaleActivated;

  /**
   * @dev activate antiwhale
   */
  function activateAntiWhale() public onlyOwner {
    require(antiWhaleActivated == false, "Already activated");
    antiWhaleActivated = true;
  }

  /**
   * @dev deactivate antiwhale
   */
  function deActivateAntiWhale() public onlyOwner {
    require(antiWhaleActivated == true, "Already activated");
    antiWhaleActivated = false;
  }

  /**
   * @dev set antiwhale settings
   * @param _startDate start date of the antiwhale
   * @param _endDate end date of the antiwhale
   * @param _limitWhale limit amount of antiwhale
   */
  function setAntiWhale(
    uint256 _startDate,
    uint256 _endDate,
    uint256 _limitWhale
  ) public onlyOwner {
    startDate = _startDate;
    endDate = _endDate;
    limitWhale = _limitWhale;
    antiWhaleActivated = true;
  }

  /**
   * @dev check if antiwhale is enable and amount should be less than to whale in specify duration
   * @param _from from address
   * @param _to to address
   * @param _amount amount to check antiwhale
   */
  function isWhale(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (bool) {
    if (_from == owner() || _to == owner() || antiWhaleActivated == false || _amount <= limitWhale) return false;

    if (block.timestamp >= startDate && block.timestamp <= endDate) return true;

    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITokenPresenter {
  function receiveTokens(
    address trigger,
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeRouter01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBurnable {
  function burn(uint amount) external;

  function burnFrom(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

