// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract PuulAccessControl is AccessControl {
  using SafeERC20 for IERC20;

  bytes32 constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  bytes32 constant ROLE_MEMBER = keccak256("ROLE_MEMBER");
  bytes32 constant ROLE_MINTER = keccak256("ROLE_MINTER");
  bytes32 constant ROLE_EXTRACT = keccak256("ROLE_EXTRACT");
  bytes32 constant ROLE_HARVESTER = keccak256("ROLE_HARVESTER");
  
  constructor () public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "!admin");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(ROLE_MINTER, msg.sender), "!minter");
    _;
  }

  modifier onlyExtract() {
    require(hasRole(ROLE_EXTRACT, msg.sender), "!extract");
    _;
  }

  modifier onlyHarvester() {
    require(hasRole(ROLE_HARVESTER, msg.sender), "!harvester");
    _;
  }

  modifier onlyDefaultAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!default_admin");
    _;
  }

  function _setup(bytes32 role, address user) internal {
    if (msg.sender != user) {
      _setupRole(role, user);
      revokeRole(role, msg.sender);
    }
  }

  function _setupDefaultAdmin(address admin) internal {
    _setup(DEFAULT_ADMIN_ROLE, admin);
  }

  function _setupAdmin(address admin) internal {
    _setup(ROLE_ADMIN, admin);
  }

  function setupDefaultAdmin(address admin) external onlyDefaultAdmin {
    _setupDefaultAdmin(admin);
  }

  function setupAdmin(address admin) external onlyAdmin {
    _setupAdmin(admin);
  }

  function setupMinter(address admin) external onlyMinter {
    _setup(ROLE_MINTER, admin);
  }

  function setupExtract(address admin) external onlyExtract {
    _setup(ROLE_EXTRACT, admin);
  }

  function setupHarvester(address admin) external onlyHarvester {
    _setup(ROLE_HARVESTER, admin);
  }

  function _tokenInUse(address /*token*/) virtual internal view returns(bool) {
    return false;
  }

  function extractStuckTokens(address token, address to) onlyExtract external {
    require(token != address(0) && to != address(0));
    // require(!_tokenInUse(token)); // TODO add back after beta
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (balance > 0)
      IERC20(token).safeTransfer(to, balance);
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import './PuulAccessControl.sol';

contract Whitelist is PuulAccessControl {
  using Address for address;

  bool _startWhitelist;
  mapping (address => bool) _whitelist;
  mapping (address => bool) _blacklist;

  constructor () public {}

  modifier onlyWhitelist() {
    require(!_blacklist[msg.sender] && (!_startWhitelist || _whitelist[msg.sender]), "!whitelist");
    _;
  }

  function stopWhitelist() onlyHarvester external {
    _startWhitelist = false;
  }

  function startWhitelist() onlyHarvester external {
    _startWhitelist = true;
  }

  function addWhitelist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _whitelist[c] = true;
  }
  
  function removeWhitelist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _whitelist[c] = false;
  }
  
  function addBlacklist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _blacklist[c] = true;
  }
  
  function removeBlacklist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _blacklist[c] = false;
  }
  
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IFarm {
  function earn() external;
  function harvest() external;
  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IFarmRewards {
  function rewards() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import '../access/PuulAccessControl.sol';
import "../utils/Console.sol";

contract Fees is PuulAccessControl, ReentrancyGuard {
  using SafeMath for uint256;

  address _currency;
  address _reward;
  uint256 _rewardFee;
  address _withdrawal;
  uint256 _withdrawalFee;
  address _helper;

  uint256 constant FEE_BASE = 10000;
  
  constructor (address helper, address withdrawal, uint256 withdrawalFee, address reward, uint256 rewardFee) public {
    _helper = helper;
    _reward = reward;
    _rewardFee = rewardFee;
    _withdrawal = withdrawal;
    _withdrawalFee = withdrawalFee;

    _setupRole(ROLE_ADMIN, msg.sender);
  }

  function setupRoles(address admin) onlyDefaultAdmin external {
    _setupAdmin(admin);
    _setupDefaultAdmin(admin);
  }

  function currency() external view returns (address) {
    return _currency;
  }

  function helper() external view returns (address) {
    return _helper;
  }

  function reward() external view returns (address) {
    return _reward;
  }

  function withdrawal() external view returns (address) {
    return _withdrawal;
  }

  function setHelper(address help) onlyAdmin external {
    _helper = help;
  }

  function setCurrency(address curr) onlyAdmin external {
    _currency = curr;
  }

  function setRewardFee(address to, uint256 fee) onlyAdmin external {
    _reward = to;
    _rewardFee = fee;
  }

  function setWithdrawalFee(address to, uint256 fee) onlyAdmin external {
    _withdrawal = to;
    _withdrawalFee = fee;
  }

  function _calcFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return amount.mul(fee).div(FEE_BASE);
  }

  function _calcWithdrawalFee(uint256 amount) internal view returns (uint256) {
    return _withdrawalFee == 0 || _withdrawal == address(0) ? 0 : _calcFee(amount, _withdrawalFee);
  }

  function _calcRewardFee(uint256 amount) internal view returns (uint256) {
    return _rewardFee == 0 || _reward == address(0) ? 0 : _calcFee(amount, _rewardFee);
  }

  function getRewardFee() external view returns (uint256) {
    return _rewardFee;
  }

  function rewardFee(uint256 amount) external view returns (uint256) {
    return _calcRewardFee(amount);
  }

  function getWithdrawalFee() external view returns (uint256) {
    return _withdrawalFee;
  }

  function withdrawalFee(uint256 amount) external view returns (uint256) {
    return _calcWithdrawalFee(amount);
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../utils/Console.sol";
import "../token/ERC20/ERC20.sol";
import "../fees/Fees.sol";
import '../farm/IFarm.sol';
import './IPoolFarm.sol';
import './PuulRewards.sol';
import './Limits.sol';

contract EarnPool is ERC20, ReentrancyGuard, PuulRewards, IPoolFarm {
  using Address for address;
  using SafeMath for uint256;
  using Arrays for uint256[];
  using SafeERC20 for IERC20;

  Fees _fees;
  Limits _limits;
  mapping (IERC20 => uint256) _rewardExtra;
  mapping (IERC20 => uint256) _accSharePrices;
  mapping (address => mapping (IERC20 => uint256)) _owedRewards;
  mapping (address => mapping (IERC20 => uint256)) _debtSharePrices;

  bool _allowAll;
  bool _initialized;

  uint256 precision = 1e18;
  uint256 constant MIN_PRICE_PER_SHARE = 10;

  modifier onlyMember() {
    require(isMember(msg.sender), '!member');
    _;
  }

  modifier onlyWithdrawal() {
    require((address(_fees) != address(0) && msg.sender == _fees.withdrawal() || hasRole(ROLE_ADMIN, msg.sender) || hasRole(ROLE_HARVESTER, msg.sender)), '!withdrawer');
    _;
  }

  function isMember(address member) internal view returns(bool) {
    return member != address(0) && (_allowAll == true || hasRole(ROLE_MEMBER, member));
  }

  constructor (string memory name, string memory symbol, bool allowAll, address fees) public ERC20(name, symbol) {
    if (fees != address(0))
      _fees = Fees(fees);
    _allowAll = allowAll;
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setupRoles(address defaultAdmin, address admin, address extract, address harvester, address minter) onlyDefaultAdmin external {
    _setupRoles(defaultAdmin, admin, extract, harvester, minter);
  }

  function _setupRoles(address defaultAdmin, address admin, address extract, address harvester, address minter) internal {
    _setup(ROLE_EXTRACT, extract);
    _setup(ROLE_MINTER, minter);
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(defaultAdmin);
  }

  function mint(address to, uint256 amount) external onlyMinter {
    _mint(to, amount);
  }

  function addMember(address member) onlyAdmin external {
    _setupRole(ROLE_MEMBER, member);
  }

  function getFees() external view returns(address) {
    return address(_fees);
  }

  function setFees(address fees) onlyMinter external {
    _fees = Fees(fees);
  }

  function setLimits(address limits) onlyAdmin external {
    _limits = Limits(limits);
  }

  function getLimits() external view returns(address) {
    return address(_limits);
  }

  function initialize() onlyAdmin nonReentrant external returns(bool success) {
    if (_initialized) return false;
    _initialized = _initialize();
    return _initialized;
  }

  function _initialize() virtual internal returns(bool) {
    return true;
  }

  function earn() onlyHarvester nonReentrant virtual external {
    _earn();
  }

  function unearn() onlyHarvester nonReentrant virtual external {}

  function harvest() onlyHarvester nonReentrant virtual external {
    _harvest();
    _earn();
  }

  function harvestOnly() onlyHarvester nonReentrant virtual external {
    _harvest();
  }

  function _earn() virtual internal { }
  function _unearn(uint256 amount) virtual internal { }

  /* Trying out function parameters for a functional map */
  function mapToken(IERC20[] storage self, function (IERC20) view returns (uint256) f) internal view returns (uint256[] memory r) {
    uint256 len = self.length;
    r = new uint[](len);
    for (uint i = 0; i < len; i++) {
      r[i] = f(self[i]);
    }
  }

  function balanceOfToken(IERC20 token) internal view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function _harvest() internal virtual {
    uint256[] memory prev = mapToken(_rewards, balanceOfToken);
    _harvestRewards();
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 tokenSupply = token.balanceOf(address(this)).sub(prev[i], 'tokenSupply<0');
      _rewardTotals[token] = _rewardTotals[token].add(tokenSupply);
      _updateRewardSharePrice(token, tokenSupply);
    }
  }

  function _updateRewardSharePrice(IERC20 token, uint256 tokenSupply) internal {
    uint256 supply = totalSupply();
    uint256 extra = _rewardExtra[token];
    if (extra > 0) {
      tokenSupply = tokenSupply.add(extra);
      _rewardExtra[token] = 0;
    }
    if (tokenSupply == 0) return; // Nothing to do
    uint256 pricePerShare = supply > 0 ? (tokenSupply * precision).div(supply) : 0;
    if (pricePerShare < MIN_PRICE_PER_SHARE) {
      // Console.log('pricePerShare < min', pricePerShare);
      pricePerShare = 0;
    }
    _accSharePrices[token] = pricePerShare.add(_accSharePrices[token]);
    if (pricePerShare == 0) {
      _rewardExtra[token] = tokenSupply.add(_rewardExtra[token]);
    } else {
      uint256 rounded = pricePerShare.mul(supply).div(precision);
      if (rounded < tokenSupply) {
        // Console.log('rounded', tokenSupply - rounded);
        _rewardExtra[token] = _rewardExtra[token].add(tokenSupply - rounded);
      }
    }
  }

  // function rewardExtras() onlyHarvester external view returns(uint256[] memory totals) {
  //   totals = new uint256[](_rewards.length);
  //   for (uint256 i = 0; i < _rewards.length; i++) {
  //     totals[i] = _rewardExtra[_rewards[i]];
  //   }
  // }

  function owedRewards() external view returns(uint256[] memory rewards) {
    rewards = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      rewards[i] = owed[token];
    }
  }

  function getPendingRewards(address sender) onlyHarvester external view returns(uint256[] memory totals) {
    totals = _pendingRewards(sender);
  }

  function pendingRewards() external view returns(uint256[] memory totals) {
    totals = _pendingRewards(msg.sender);
  }

  function _pendingRewards(address sender) internal view returns(uint256[] memory totals) {
    uint256 amount = balanceOf(sender);
    totals = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage owed = _owedRewards[sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      totals[i] = owed[_rewards[i]];
    }
    mapping (IERC20 => uint256) storage debt = _debtSharePrices[sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 debtSharePrice = debt[token];
      uint256 currentSharePrice = _accSharePrices[token];
      totals[i] += ((currentSharePrice - debtSharePrice) * amount).div(precision);
    }
  }

  function addReward(address token) onlyAdmin external override virtual {
    if (_addReward(token)) {
      uint256 tokenSupply = IERC20(token).balanceOf(address(this));
      _updateRewardSharePrice(IERC20(token), tokenSupply);
    }
  }

  function rewardAdded(address token) onlyFarm external override virtual {
    if (_addReward(token)) {
      uint256 tokenSupply = IERC20(token).balanceOf(address(this));
      _updateRewardSharePrice(IERC20(token), tokenSupply);
    }
  }

  event Deposit(address, uint);
  function _deposit(uint256 amount) internal virtual {
    if (address(_limits) != address(0)) 
      _limits.checkLimits(msg.sender, address(this), amount);
    _mint(msg.sender, amount);
    emit Deposit(msg.sender, amount);
  }

  function _updateRewards(address user, uint256 amount, bool updateDebt) internal {
    mapping (IERC20 => uint256) storage owed = _owedRewards[user];
    mapping (IERC20 => uint256) storage debt = _debtSharePrices[user];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 debtSharePrice = debt[token];
      uint256 currentSharePrice = _accSharePrices[token];
      owed[token] += ((currentSharePrice - debtSharePrice) * amount).div(precision);
      if (updateDebt) {
        debt[token] = currentSharePrice;
      }
    }
  }

  function _splitWithdrawal(uint256 amount, address account) internal view returns(uint256 newAmount, uint256 feeAmount, address withdrawal) {
    withdrawal = address(_fees) == address(0) ? address(0) : _fees.withdrawal();
    if (withdrawal == account) // no fees for withdrawer
      withdrawal = address(0);
    feeAmount = withdrawal == address(0) ? 0 : _fees.withdrawalFee(amount);
    newAmount = amount - feeAmount;
  }

  function _mint(address account, uint256 amount) internal override {
    require(isMember(account), '!member');
    uint256 balance = _balances[account];
    _updateRewards(account, balance, true);

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = balance.add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal override {
    require(isMember(account), '!member');
    _updateRewards(account, amount, false);

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _burnWithFee(address account, uint256 amount) internal returns (uint256) {
    require(isMember(account), '!member');
    _updateRewards(account, amount, false);

    _beforeTokenTransfer(account, address(0), amount);

    (uint256 newAmount, uint256 feeAmount, address withdrawal) = _splitWithdrawal(amount, account);
    require(newAmount + feeAmount == amount, '_burnWithFee bad amount');

    if (withdrawal != address(0))
      _updateRewards(withdrawal, _balances[withdrawal], true);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    if (withdrawal != address(0))
      _balances[withdrawal] = _balances[withdrawal].add(feeAmount);
    _totalSupply = _totalSupply.sub(newAmount);

    if (withdrawal != address(0))
      emit Transfer(address(0), withdrawal, feeAmount);
    emit Transfer(account, address(0), amount);

    return newAmount;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(isMember(sender), '!member');
    require(isMember(recipient), '!member');
    _updateRewards(sender, amount, false);

    _beforeTokenTransfer(sender, recipient, amount);

    (uint256 newAmount, uint256 feeAmount, address withdrawal) = _splitWithdrawal(amount, sender);
    require(newAmount + feeAmount == amount, 'transfer bad amount');
    _updateRewards(recipient, _balances[recipient], true);
    
    if (withdrawal != address(0)) {
      _updateRewards(withdrawal, _balances[withdrawal], true);
      _balances[withdrawal] = _balances[withdrawal].add(feeAmount);
    }
    _balances[recipient] = _balances[recipient].add(newAmount);
    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

    emit Transfer(sender, recipient, newAmount);
    if (withdrawal != address(0))
      emit Transfer(sender, withdrawal, feeAmount);
  }

  function _harvestRewards() virtual internal { }

  function updateRewards() nonReentrant external {
    _updateRewards(msg.sender, balanceOf(msg.sender), true);
  }

  function updateAndClaim() nonReentrant external override {
    _updateRewards(msg.sender, balanceOf(msg.sender), true);
    _claim();
  }

  function claim() nonReentrant external override {
    _claim();
  }

  function _claim() internal virtual {
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 amount = owed[token];
      owed[token] = 0;
      safeTransferReward(token, msg.sender, amount);
    }
  }

  event Withdraw(address, uint);
  function withdrawAll() nonReentrant external virtual {
    _withdraw(balanceOf(msg.sender));
  }

  function withdraw(uint256 amount) nonReentrant external virtual {
    require(amount <= balanceOf(msg.sender));
    _withdraw(amount);
  }

  function withdrawFees() onlyWithdrawal nonReentrant virtual external {
    _withdrawFees();
  }

  function _withdrawFees() virtual internal returns(uint256 amount) {
    require(address(_fees) != address(0));
    address withdrawer = _fees.withdrawal();
    amount = balanceOf(withdrawer);
    _unearn(amount);
    _burn(withdrawer, amount);
  }

  function _withdraw(uint256 amount) virtual internal returns(uint256 afterFee) {
    afterFee = _burnWithFee(msg.sender, amount);
    _unearn(afterFee);
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return PuulRewards._tokenInUse(token);
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPool {
  function rewardAdded(address token) external;
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPoolFarm {
  function claim() external;
  function updateAndClaim() external;
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPoolFarmExtended {
  function claimToToken(address token, uint256[] memory amounts, uint256[] memory mins) external;
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import '../access/PuulAccessControl.sol';
import "../utils/Console.sol";

contract Limits is PuulAccessControl, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct LimitValues {
    uint256 minPuul;
    uint256 minPuulStake;
    uint256 minDeposit;
    uint256 maxDeposit;
    uint256 maxTotal;
  }

  address _puul;
  address _puulStake;
  mapping (address => LimitValues) _limits;

  constructor (address puul, address puulStake) public {
    _puul = puul;
    _puulStake = puulStake;
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
  }

  function setupRoles(address defaultAdmin, address admin, address harvester) onlyDefaultAdmin external {
    _setupRoles(defaultAdmin, admin, harvester);
  }

  function _setupRoles(address defaultAdmin, address admin, address harvester) internal {
    _setup(ROLE_ADMIN, admin);
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(defaultAdmin);
  }

  function setMinPuul(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minPuul = value;
  }

  function setMinPuulStake(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minPuulStake = value;
  }

  function setMinDeposit(address pool, uint256 value) onlyHarvester external {
    _limits[pool].minDeposit = value;
  }

  function setMaxDeposit(address pool, uint256 value) onlyHarvester external {
    _limits[pool].maxDeposit = value;
  }

  function setMaxTotal(address pool, uint256 value) onlyHarvester external {
    _limits[pool].maxTotal = value;
  }

  function checkLimits(address sender, address pool, uint256 amount) external view {
    uint256 minPuul = _limits[pool].minPuul;
    if (minPuul > 0)
      require(IERC20(_puul).balanceOf(sender) >= minPuul, '!minPuul');
    uint256 minPuulStake = _limits[pool].minPuulStake;
    if (minPuulStake > 0)
      require(IERC20(_puulStake).balanceOf(sender) >= minPuulStake, '!minPuulStake');
    uint256 minDeposit = _limits[pool].minDeposit;
    if (minDeposit > 0)
      require(amount >= minDeposit, '!minDeposit');
    uint256 maxDeposit = _limits[pool].maxDeposit;
    if (maxDeposit > 0)
      require(amount <= maxDeposit, '!maxDeposit');
    uint256 maxTotal = _limits[pool].maxTotal;
    if (maxTotal > 0)
      require(amount.add(IERC20(pool).totalSupply()) <= maxTotal, '!maxTotal');
  }

  function getMinPuul(address pool) view external returns(uint256) {
    return _limits[pool].minPuul;
  }

  function getMinPuulStake(address pool) view external returns(uint256) {
    return _limits[pool].minPuulStake;
  }

  function getMinDeposit(address pool) view external returns(uint256) {
    return _limits[pool].minDeposit;
  }

  function getMaxDeposit(address pool) view external returns(uint256) {
    return _limits[pool].maxDeposit;
  }

  function getMaxTotal(address pool) view external returns(uint256) {
    return _limits[pool].maxTotal;
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '../access/PuulAccessControl.sol';
import "../utils/Console.sol";
import './IPool.sol';
import '../farm/IFarm.sol';
import '../farm/IFarmRewards.sol';

contract PuulRewards is PuulAccessControl, IPool, IFarmRewards {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IFarm _farm;
  IERC20[] _rewards;
  mapping (IERC20 => uint256) _rewardsMap;
  mapping (IERC20 => uint256) _rewardTotals;

  modifier onlyFarm() virtual {
    require(msg.sender == address(_farm), '!farm');
    _;
  }

  function _addRewards(address[] memory rewards) internal {
    for (uint256 i = 0; i < rewards.length; i++) {
      _addReward(rewards[i]);
    }
  }

  function setFarm(address farm) onlyAdmin external {
    _farm = IFarm(farm);
    address[] memory rewards = IFarmRewards(address(_farm)).rewards();
    for (uint256 i = 0; i < rewards.length; i++) {
      _addReward(rewards[i]);
    }
  }

  function getFarm() external view returns(address) {
    return address(_farm);
  }

  function addReward(address token) onlyAdmin external virtual {
    _addReward(token);
  }

  function _getRewards() internal view returns(address[] memory result) {
    result = new address[](_rewards.length);
    for (uint256 i = 0; i < _rewards.length; i++) {
      result[i] = address(_rewards[i]);
    }
  }

  function rewards() external view override returns(address[] memory result) {
    return _getRewards();
  }

  function rewardAdded(address token) onlyFarm external override virtual {
    _addReward(token);
  }

  function safeTransferReward(IERC20 reward, address dest, uint256 amount) internal returns(uint256) {
    // in case there is a tiny rounding error
    uint256 remaining = _rewardTotals[reward];
    if (remaining < amount)
      amount = remaining;
    _rewardTotals[reward] = remaining - amount;
    if (amount > 0) {
      uint256 bef = reward.balanceOf(dest);
      reward.safeTransfer(dest, amount);
      uint256 aft = reward.balanceOf(dest);
      amount = aft.sub(bef, '!reward');
    }
    return amount;
  }

  function rewardTotals() onlyHarvester external view returns(uint256[] memory totals) {
    totals = new uint256[](_rewards.length);
    for (uint256 i = 0; i < _rewards.length; i++) {
      totals[i] = _rewardTotals[_rewards[i]];
    }
  }

  function _addReward(address token) internal returns(bool) {
    IERC20 erc = IERC20(token);
    if (_rewardsMap[erc] == 0) {
      _rewards.push(erc);
      _rewardsMap[erc] = _rewards.length;
      return true;
    }
    return false;
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return _rewardsMap[IERC20(token)] != 0;
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import './EarnPool.sol';
import './IPoolFarmExtended.sol';
import '../protocols/uniswap-v2/UniswapHelper.sol';

contract TokenBase is EarnPool, IPoolFarmExtended {
  using Address for address;
  using SafeMath for uint256;
  using Arrays for uint256[];
  using SafeERC20 for IERC20;

  UniswapHelper _helper;

  constructor (string memory name, string memory symbol, address fees, address helper) public EarnPool(name, symbol, true, fees) {
    _helper = UniswapHelper(helper);
  }

  function setHelper(address helper) onlyAdmin external {
    require(helper != address(0));
    _helper = UniswapHelper(helper);
  }

  function _harvestRewards() internal override {
    if (address(_farm) != address(0)) {
      _farm.harvest();
    }
  }

  function claimToToken(
    address to, 
    uint[] memory amounts,
    uint[] memory min
  ) external nonReentrant override {
    require(amounts.length == _rewards.length, 'amounts!=rewards');
    require(min.length == amounts.length, 'min!=rewards');
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 amount = amounts[i];
      if (amount > 0) {
        uint256 rem = owed[token];
        require(amount <= rem, 'bad amount');
        owed[token] = rem.sub(amount);
        if (address(token) == to) {
          safeTransferReward(token, msg.sender, amount);
        } else {
          require(_helper.pathExists(address(token), to), 'bad token');
          string memory path = Path.path(address(token), to);
          amount = safeTransferReward(token, address(_helper), amount);
          if (amount > 0) {
            _helper.swap(path, amount, min[i], msg.sender);
          }
        }

      }
    }
  }

  function withdrawAll() nonReentrant external override virtual {
  }

  function withdraw(uint256 /* amount */) nonReentrant external override virtual {
  }

  function withdrawFees() onlyWithdrawal nonReentrant override virtual external {
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return EarnPool._tokenInUse(token);
  }

}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import '../TokenBase.sol';

contract PuulToken is TokenBase {
  constructor (address helper, address mintTo) public TokenBase('PUUL Token', 'PUUL', address(0), helper) {
    _mint(mintTo, 100000 ether);
  }
}

// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import '../../protocols/uniswap-v2/interfaces/IUniswapV2Pair.sol';
import '../../protocols/uniswap-v2/interfaces/IUniswapV2Factory.sol';
import '../../protocols/uniswap-v2/interfaces/IUniswapV2Router02.sol';
import '../../access/Whitelist.sol';
import '../../utils/Console.sol';

contract UniswapHelper is Whitelist, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping (bytes32 => uint) _hasPath;
  mapping (bytes32 => mapping (uint => address)) _paths;

  IUniswapV2Factory public constant UNI_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  IUniswapV2Router02 public constant UNI_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  uint256 public constant MIN_AMOUNT = 5;
  uint256 public constant MIN_SWAP_AMOUNT = 1000; // should be ok for most coins
  uint256 public constant MIN_SLIPPAGE = 1; // .01%
  uint256 public constant MAX_SLIPPAGE = 1000; // 10%
  uint256 public constant SLIPPAGE_BASE = 10000;

   constructor () public {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
  }

  function setupRoles(address admin, address harvester) onlyDefaultAdmin external {
    _setup(ROLE_HARVESTER, harvester);
    _setupDefaultAdmin(admin);
  }

  function addPath(string memory name, address[] memory path) onlyHarvester external {
    bytes32 key = keccak256(abi.encodePacked(name));
    require(_hasPath[key] == 0, 'path exists');
    require(path.length > 0, 'invalid path');

    _hasPath[key] = path.length;
    mapping (uint => address) storage spath = _paths[key];
    for (uint i = 0; i < path.length; i++) {
      spath[i] = path[i];
    }
  }

  function removePath(string memory name) onlyHarvester external {
    bytes32 key = keccak256(abi.encodePacked(name));
    uint length = _hasPath[key];
    require(length > 0, 'path not found exists');

    _hasPath[key] = 0;
    mapping (uint => address) storage spath = _paths[key];
    for (uint i = 0; i < length; i++) {
      spath[i] = address(0);
    }
  }

  function pathExists(address from, address to) external view returns(bool) {
    string memory name = Path.path(from, to);
    bytes32 key = keccak256(abi.encodePacked(name));
    uint256 length = _hasPath[key];
    if (length == 0) return false;
    address first = _paths[key][0];
    if (from != first) return false;
    address last = _paths[key][length - 1];
    if (to != last) return false;
    return true;
  }

  function _removeLiquidityDeflationary(address tokenA, address tokenB, uint256 amount, uint256 minA, uint256 minB) internal returns (uint256 amountA, uint256 amountB) {
    uint256 befA = IERC20(tokenA).balanceOf(address(this));
    uint256 befB = IERC20(tokenB).balanceOf(address(this));
    UNI_ROUTER.removeLiquidity(tokenA, tokenB, amount, minA, minB, address(this), now.add(1800));
    uint256 aftA = IERC20(tokenA).balanceOf(address(this));
    uint256 aftB = IERC20(tokenB).balanceOf(address(this));
    amountA = aftA.sub(befA, 'deflat');
    amountB = aftB.sub(befB, 'deflat');
  }

  function withdrawToToken(address token, uint256 amount, address dest, IUniswapV2Pair pair, uint256 minA, uint256 minB, uint256 slippageA, uint256 slippageB) onlyWhitelist nonReentrant external {
    address token0 = pair.token0();
    address token1 = pair.token1();
    IERC20(address(pair)).safeApprove(address(UNI_ROUTER), 0);
    IERC20(address(pair)).safeApprove(address(UNI_ROUTER), amount * 2);
    (uint amount0, uint amount1) = _removeLiquidityDeflationary(token0, token1, amount, minA, minB);
    if (token == token0) {
      IERC20(token0).safeTransfer(dest, amount0);
    } else {
      _swapWithSlippage(token0, token, amount0, slippageA, dest);
    }
    if (token == token1) {
      IERC20(token1).safeTransfer(dest, amount1);
    } else {
      _swapWithSlippage(token1, token, amount1, slippageB, dest);
    }
  }

  function _swapWithSlippage(address from, address to, uint256 amount, uint256 slippage, address dest) internal returns(uint256 swapOut) {
    string memory path = Path.path(from, to);
    uint256 out = _estimateOut(from, to, amount);
    uint256 min = amountWithSlippage(out, slippage);
    swapOut = _swap(path, amount, min, dest);
  }

  function swap(string memory name, uint256 amount, uint256 minOut, address dest) onlyWhitelist nonReentrant external returns (uint256 swapOut) {
    swapOut = _swap(name, amount, minOut, dest);
  }

  function _swap(string memory name, uint256 amount, uint256 minOut, address dest) internal returns (uint256 swapOut) {
    bytes32 key = keccak256(abi.encodePacked(name));
    uint256 length = _hasPath[key];
    require(length > 0, Console.concat('path not found ', name));

    // Copy array
    address[] memory swapPath = new address[](length);
    for (uint i = 0; i < length; i++) {
      swapPath[i] = _paths[key][i];
    }

    IERC20 token = IERC20(swapPath[0]);
    IERC20 to = IERC20(swapPath[swapPath.length - 1]);
    token.safeApprove(address(UNI_ROUTER), 0);
    token.safeApprove(address(UNI_ROUTER), amount * 2);
    uint256 bef = to.balanceOf(dest);
    UNI_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, minOut, swapPath, dest, now.add(1800));
    uint256 aft = to.balanceOf(dest);
    swapOut = aft.sub(bef, '!swapOut');
  }

  function amountWithSlippage(uint256 amount, uint256 slippage) internal pure returns (uint256 out) {
    out = slippage == 0 ? 0 : amount.sub(amount.mul(slippage).div(SLIPPAGE_BASE));
  }

  function getAmountOut(IUniswapV2Pair pair, address token, uint256 amount) external view returns (uint256 optimal) {
    optimal = _getAmountOut(pair, token, amount);
  }

  function _getAmountOut(IUniswapV2Pair pair, address token, uint256 amount) internal view returns (uint256 optimal) {
    uint256 reserve0;
    uint256 reserve1;
    if (pair.token0() == token) {
      (reserve0, reserve1, ) = pair.getReserves();
    } else {
      (reserve1, reserve0, ) = pair.getReserves();
    }
    optimal = UNI_ROUTER.getAmountOut(amount, reserve0, reserve1);
  }

  function quote(IUniswapV2Pair pair, address token, uint256 amount) external view returns (uint256 optimal) {
    optimal = _quote(pair, token, amount);
  }

  function _quote(IUniswapV2Pair pair, address token, uint256 amount) internal view returns (uint256 optimal) {
    uint256 reserve0;
    uint256 reserve1;
    if (pair.token0() == token) {
      (reserve0, reserve1, ) = pair.getReserves();
    } else {
      (reserve1, reserve0, ) = pair.getReserves();
    }
    optimal = UNI_ROUTER.quote(amount, reserve0, reserve1);
  }

  function _estimateOut(address from, address to, uint256 amount) internal view returns (uint256 swapOut) {
    string memory path = Path.path(from, to);
    bytes32 key = keccak256(abi.encodePacked(path));
    uint256 length = _hasPath[key];
    require(length > 0, Console.concat('path not found ', path));

    swapOut = amount;
    for (uint i = 0; i < length - 1; i++) {
      address first = _paths[key][i];
      IUniswapV2Pair pair = IUniswapV2Pair(UNI_FACTORY.getPair(first, _paths[key][i + 1]));
      require(address(pair) != address(0), 'swap pair not found');
      swapOut = _getAmountOut(pair, first, swapOut);
    }
  }

  function estimateOut(address from, address to, uint256 amount) external view returns (uint256 swapOut) {
    require(amount > 0, '!amount');
    swapOut = _estimateOut(from, to, amount);
  }

  function estimateOuts(address[] memory pairs, uint256[] memory amounts) external view returns (uint256[] memory swapOut) {
    require(pairs.length.div(2) == amounts.length, 'pairs!=amounts');
    swapOut = new uint256[](amounts.length);
    for (uint256 i = 0; i < pairs.length; i+=2) {
      uint256 ai = i.div(2);
      swapOut[ai] = _estimateOut(pairs[i], pairs[i+1], amounts[ai]);
    }
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function totalSupply() external view returns(uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;
import "../token/ERC20/ERC20.sol";

library Path {
  function path(address from, address to) internal view returns(string memory) {
    string memory symbol = ERC20(from).symbol();
    string memory symbolTo = ERC20(to).symbol();
    return string(abi.encodePacked(symbol, '/', symbolTo));
  }
}

library Console {
  bool constant PROD = true;

  function concat(string memory a, string memory b) internal pure returns(string memory)
  {
    return string(abi.encodePacked(a, b));
  }

  function concat(string memory a, string memory b, string memory c) internal pure returns(string memory)
  {
    return string(abi.encodePacked(a, b, c));
  }

  event LogBalance(string, uint);
  function logBalance(address token, address to) internal {
    if (PROD) return;
    emit LogBalance(ERC20(token).symbol(), ERC20(token).balanceOf(to));
  }

  function logBalance(string memory s, address token, address to) internal {
    if (PROD) return;
    emit LogBalance(string(abi.encodePacked(s, '/', ERC20(token).symbol())), ERC20(token).balanceOf(to));
  }

  event LogUint(string, uint);
  function log(string memory s, uint x) internal {
    if (PROD) return;
    emit LogUint(s, x);
  }

  function log(string memory s, string memory t, uint x) internal {
    if (PROD) return;
    emit LogUint(concat(s, t), x);
  }
    
  function log(string memory s, string memory t, string memory u, uint x) internal {
    if (PROD) return;
    emit LogUint(concat(s, t, u), x);
  }
    
  event LogInt(string, int);
  function log(string memory s, int x) internal {
    if (PROD) return;
    emit LogInt(s, x);
  }
  
  event LogBytes(string, bytes);
  function log(string memory s, bytes memory x) internal {
    if (PROD) return;
    emit LogBytes(s, x);
  }
  
  event LogBytes32(string, bytes32);
  function log(string memory s, bytes32 x) internal {
    if (PROD) return;
    emit LogBytes32(s, x);
  }

  event LogAddress(string, address);
  function log(string memory s, address x) internal {
    if (PROD) return;
    emit LogAddress(s, x);
  }

  event LogBool(string, bool);
  function log(string memory s, bool x) internal {
    if (PROD) return;
    emit LogBool(s, x);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

