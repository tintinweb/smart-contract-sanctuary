// "SPDX-License-Identifier: MIT"
pragma solidity 0.5.16;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./SaleLib.sol";
import "../vesting/TokenVesting.sol";

contract LimitTokenSale is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint8 private constant PRICE_DECIMALS = 3;
  uint8 private constant TOKEN_DECIMALS = 18;

  IERC20 public saleToken;
  IERC20 public collateralToken;
  TokenVesting public tokenVesting;
  uint256 public maxInvestment = 0;
  
  SaleLib.Round[] public rounds;

  mapping(uint256 => mapping(address => bool))    public claimed;
  mapping(uint256 => mapping(address => uint256)) public balances;
  mapping(uint256 => mapping(address => uint256)) public refunds;
  mapping(uint256 => SaleLib.Resubscription[])    public resubscriptions;
  mapping(uint256 => mapping(address => uint256)) public resubscriptionsBalances;
  
  mapping(address => bool) internal whitelisted;

  event RoundOpened(uint256 _index);
  event RoundFinalized(uint256 _index);

  event Submitted(uint256 round, address beneficiary, uint256 amount);
  event TokenClaimed(uint256 round, address beneficiary, uint256 amount);
  event LeftoverClaimed(uint256 round, address beneficiary, uint256 amount);
  event Resubscribed(uint256 round, address beneficiary, uint256 amount);
  event Recovered(address token, uint256 amount);
  event Withdrawn(uint256 amount);

  constructor(address _saleToken, address _collateralToken, address _tokenVesting) public {
    saleToken = IERC20(_saleToken);
    collateralToken = IERC20(_collateralToken);
    tokenVesting = TokenVesting(_tokenVesting);
  }

  /**
   * @param _beneficiaries  address of beneficiaries to be whitelisted
   *
   * @dev method sets whitelisted beneficiaries
   */
  function whitelist(address[] calldata _beneficiaries) external onlyOwner {
    for(uint8 i = 0; i < _beneficiaries.length; i++) {
      whitelisted[_beneficiaries[i]] = true;
    }
  }

  /**
   * @param _beneficiary  address of beneficiary
   *
   * @dev method checks if beneficiary is whitelisted
   */
  function whitelist(address _beneficiary) external view returns (bool) {
    return whitelisted[_beneficiary];
  }

  /**
   * @param _beneficiaries  addresses of beneficiaries to be revoked
   *
   * @dev method revokes whitelisted beneficiaries
   */
  function revokeWhitelist(address[] calldata _beneficiaries) external onlyOwner {
    for(uint8 i = 0; i < _beneficiaries.length; i++) {
      whitelisted[_beneficiaries[i]] = false;
    }
  }

  /**
   * @param _saleToken        address of sale token
   * @param _collateralToken  address of collateral token
   * @param _tokenVesting     address of token vesting
   *
   * @dev method allows to change sale token, collateral token and token vesting addresses
   */
  function changeAddresses(address _saleToken, address _collateralToken, address _tokenVesting) external onlyOwner {
    saleToken = IERC20(_saleToken);
    collateralToken = IERC20(_collateralToken);
    tokenVesting = TokenVesting(_tokenVesting);
  }

  /**
   * @param _token  address of token to recover
   * @param _amount amount of token to recover
   *
   * @dev method used to recover ERC20
   */
  function recoverERC20(address _token, uint256 _amount) external onlyOwner {
    require(_token != address(saleToken) || _token != address(collateralToken), "LimitTokenSale: cannot recover sale or collateral tokens");
    
    IERC20(_token).safeTransfer(_msgSender(), _amount);
    
    emit Recovered(_token, _amount);
  }

  /**
   * @param _index index of round
   *
   * @dev method open the Round
   */
  function openRound(uint256 _index) external onlyOwner {
    require(_index < rounds.length, "LimitTokenSale: round not defined");
    rounds[_index].state = SaleLib.State.open;

    emit RoundOpened(_index);
  }

  /**
   * @param _index index of round
   *
   * @dev method finalize the Round
   */
  function finalizeRound(uint256 _index) external onlyOwner {
    require(_index < rounds.length, "LimitTokenSale: round not defined");
    rounds[_index].state = SaleLib.State.finalized;

    emit RoundFinalized(_index);
  }

  /**
   * @param _price        price of round token
   * @param _vesting      percent of round tokens sent to vesting pool
   * @param _totalSupply  round total supply
   * @param _pid          vesting pool id
   *
   * @dev method initialize new round
   */
  function initRound(uint256 _price, uint256 _vesting, uint256 _totalSupply, uint8 _pid) external onlyOwner {
    require(_vesting <= 100, "LimitTokenSale: Invalid vesting percent");
    
    saleToken.safeTransferFrom(_msgSender(), address(this), _totalSupply);

    SaleLib.Round memory round = SaleLib.Round({
      state: SaleLib.State.closed,
      price: _price,
      vesting: _vesting,
      totalBalance: 0,
      totalSupply: _totalSupply,
      pid: _pid
    });

    rounds.push(round);
  }

  /**
   * @param _index        index of round
   * @param _price        price of round token
   * @param _vesting      percent of round tokens sent to vesting pool
   * @param _totalSupply  round total supply
   * @param _pid          vesting pool id
   *
   * @dev method sets new parameters to the round
   */
  function updateRound(uint256 _index, uint256 _price, uint256 _vesting, uint256 _totalSupply, uint8 _pid) external onlyOwner {
    require(rounds[_index].state == SaleLib.State.closed, "LimitTokenSale: Sale is already finalized");
    require(_vesting <= 100, "LimitTokenSale: Invalid vesting percent");

    if(rounds[_index].totalSupply < _totalSupply) {
      saleToken.safeTransferFrom(_msgSender(), address(this), _totalSupply.sub(rounds[_index].totalSupply));
    } else {
      saleToken.safeTransfer(_msgSender(), rounds[_index].totalSupply.sub(_totalSupply));
    }

    rounds[_index].price = _price;
    rounds[_index].vesting = _vesting;
    rounds[_index].totalSupply = _totalSupply;
    rounds[_index].pid = _pid;
  }

  /**
   * @param _index index of round
   *
   * @dev method returns round details
   */
  function getRound(uint256 _index) external view returns(SaleLib.State, uint256, uint256, uint256, uint256, uint8) {
    return (rounds[_index].state, rounds[_index].price, rounds[_index].vesting, rounds[_index].totalSupply, rounds[_index].totalBalance, rounds[_index].pid);
  }

  /**
   * @param _index          index of round
   * @param _prices         resubscriptions prices of token
   * @param _totalSupplies  resubscriptions total supplies
   *
   * @dev method initialize new resubscriptions
   */
  function initResubscriptions(uint256 _index, uint256[] calldata _prices, uint256[] calldata _totalSupplies) external onlyOwner {
    require(rounds[_index].state == SaleLib.State.closed, "LimitTokenSale: Round is already open or finalized");
    require(_prices.length == _totalSupplies.length, "LimitTokenSale: Invalid params length");
    
    uint256 totalSupply = 0;
    for(uint256 i = 0; i < _prices.length; i++) {
      SaleLib.Resubscription memory resubscription = SaleLib.Resubscription({
        price: _prices[i],
        totalBalance: 0,
        totalSupply: _totalSupplies[i]
      });
      resubscriptions[_index].push(resubscription);
      totalSupply = totalSupply.add(_totalSupplies[i]);
    }
    saleToken.safeTransferFrom(_msgSender(), address(this), totalSupply);
  }

  /**
   * @param  _roundIndex index of round
   * @param  _index index of round
   *
   * @dev method returns round details
   */
  function getResubscription(uint256 _roundIndex, uint256 _index) external view returns(uint256, uint256, uint256) {
    return (resubscriptions[_roundIndex][_index].price, resubscriptions[_roundIndex][_index].totalSupply, resubscriptions[_roundIndex][_index].totalBalance);
  }

  /**
   * @param _index index of round
   *
   * @dev method returns beneficiaries round overprice
   */
  function roundLeftoverOf(uint256 _index, address _beneficiary) public view returns(uint256) {
    if(rounds[_index].state == SaleLib.State.finalized) {
      uint256 tokenTotal = rounds[_index].totalBalance.mul(uint256(10) ** TOKEN_DECIMALS).div(rounds[_index].price).div(uint256(10) ** PRICE_DECIMALS);
      if(tokenTotal > rounds[_index].totalSupply) {
        uint256 amount = balances[_index][_beneficiary].mul(rounds[_index].totalSupply).div(tokenTotal);
        uint256 leftover = balances[_index][_beneficiary].sub(amount);
        return leftover.sub(refunds[_index][_beneficiary]);
      }
      return 0;
    }
    return 0;
  }

  /**
   * @param _index index of round
   * @param _amount amount of tokens user would like to buy
   *
   * @dev method submits beneficiaries to the sale 
   */
  function submit(uint256 _index, uint256 _amount) external nonReentrant {
    require(whitelisted[_msgSender()], "LimitTokenSale: Beneficiary is not whitelisted");
    require(rounds[_index].state == SaleLib.State.open, "LimitTokenSale: Round is not open");
    
    collateralToken.safeTransferFrom(_msgSender(), address(this), _amount);
    balances[_index][_msgSender()] = _amount;
    rounds[_index].totalBalance = rounds[_index].totalBalance.add(_amount);

    emit Submitted(_index, _msgSender(), _amount);
  }

  /**
   * @param _index index of round
   *
   * @dev method claims beneficiary reward
   */
  function claimToken(uint256 _index, uint256 _refund) external nonReentrant {
    require(rounds[_index].state == SaleLib.State.finalized, "LimitTokenSale: Sale is not finalized");
    require(!claimed[_index][_msgSender()], "LimitTokenSale: Round already claimed");
    require(balances[_index][_msgSender()] > 0, "LimitTokenSale: Beneficiary is not a participant");

    claimed[_index][_msgSender()] = true;

    uint256 tokenAmount = 0;
    uint256 tokenTotal = rounds[_index].totalBalance.mul(uint256(10) ** TOKEN_DECIMALS).div(rounds[_index].price).div(uint256(10) ** PRICE_DECIMALS);
    if(tokenTotal > rounds[_index].totalSupply) {
      uint256 amount = balances[_index][_msgSender()].mul(rounds[_index].totalSupply).div(tokenTotal);
      tokenAmount = amount.mul(uint256(10) ** TOKEN_DECIMALS).div(rounds[_index].price).div(uint256(10) ** PRICE_DECIMALS);
    } else {
      tokenAmount = balances[_index][_msgSender()].mul(uint256(10) ** TOKEN_DECIMALS).div(rounds[_index].price).div(uint256(10) ** PRICE_DECIMALS);
    }

    tokenAmount = tokenAmount.add(resubscriptionsBalances[_index][_msgSender()]);

    if(rounds[_index].vesting > 0) {
      uint256 vestingAmount = tokenAmount.mul(rounds[_index].vesting).div(100);
      tokenAmount = tokenAmount.sub(vestingAmount);
      saleToken.safeTransfer(address(tokenVesting), vestingAmount);
      tokenVesting.addBeneficiary(rounds[_index].pid, _msgSender(), vestingAmount);  
    }
    saleToken.safeTransfer(_msgSender(), tokenAmount);

    if(_refund > 0) {
      uint256 leftover = roundLeftoverOf(_index, _msgSender());
      require(leftover >= _refund, "LimitTokenSale: Too big refund");
      
      refunds[_index][_msgSender()] = refunds[_index][_msgSender()].add(_refund);
      collateralToken.safeTransfer(_msgSender(), _refund);

      emit LeftoverClaimed(_index, _msgSender(), _refund);
    }

    emit TokenClaimed(_index, _msgSender(), tokenAmount);
  }

  /**
   * @param _index index of round
   *
   * @dev method claims beneficiary leftover
   */
  function claimLeftover(uint256 _index, uint256 _refund) external nonReentrant {
    require(rounds[_index].state == SaleLib.State.finalized, "LimitTokenSale: Sale is not finalized");
    require(claimed[_index][_msgSender()], "LimitTokenSale: Round is not claimed yet");
    
    uint256 leftover = roundLeftoverOf(_index, _msgSender());
    require(leftover >= _refund, "LimitTokenSale: Too big refund");

    refunds[_index][_msgSender()] = refunds[_index][_msgSender()].add(_refund);
    collateralToken.safeTransfer(_msgSender(), _refund);

    emit LeftoverClaimed(_index, _msgSender(), _refund);
  }

  /**
   * @param _index        index of round
   * @param _roundIndexes round indexes to resubscribe
   * @param _amounts      amounts of resubscriptions
   *
   * @dev method resubscribe beneficiary over price
   */
  function resubscribe(uint256 _index, uint256[] calldata _roundIndexes, uint256[] calldata _amounts) external nonReentrant {
    require(rounds[_index].state == SaleLib.State.finalized, "LimitTokenSale: Sale is not finalized");
    require(_roundIndexes.length == _amounts.length, "LimitTokenSale: Invalid params length");

    for(uint256 i = 0; i < _roundIndexes.length; i++) {
      require(_index < _roundIndexes[i], "LimitTokenSale: Invalid round index");
     
      uint256 leftover = roundLeftoverOf(_index, _msgSender());
      require(leftover >= _amounts[i], "LimitTokenSale: Not enough leftover to resubscribe");
      refunds[_index][_msgSender()] = refunds[_index][_msgSender()].add(_amounts[i]);
      
      uint256 round = _roundIndexes[i];
      uint256 tokenAmount = _amounts[i].mul(uint256(10) ** TOKEN_DECIMALS).div(resubscriptions[round][_index].price).div(uint256(10) ** PRICE_DECIMALS);
      
      require(resubscriptions[round][_index].totalBalance + tokenAmount <=  resubscriptions[round][_index].totalSupply, "LimitTokenSale: No enough tokens in resubscriptions");
      
      resubscriptions[round][_index].totalBalance = resubscriptions[round][_index].totalBalance.add(tokenAmount);
      resubscriptionsBalances[round][_msgSender()] = resubscriptionsBalances[_index][_msgSender()].add(tokenAmount);

      emit Resubscribed(round, _msgSender(), _amounts[i]);
    }
  }

  /**
   * @param _amount amount of collateral token to withdraw
   *
   * @dev method used to withdraw collateral tokens
   */
  function withdraw(uint256 _amount) external onlyOwner {
    collateralToken.safeTransfer(_msgSender(), _amount);

    emit Withdrawn(_amount);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.5.16;

library SaleLib {
  enum State {
    closed,
    open,
    finalized
  }

  struct Round {
    State state;
    uint256 price;
    uint256 vesting;
    uint256 totalSupply;
    uint256 totalBalance;
    uint8 pid;
  }

  struct Resubscription {
    uint256 price;
    uint256 totalSupply;
    uint256 totalBalance;
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 lockedAmount;
    uint256 withdrawn;
  }

  struct PoolInfo {
    uint8 index;
    string name;
    uint256 startTime;
    uint256 endTime;
    uint256 totalLocked;
  }

  address public sale;
  IERC20 public token;
  PoolInfo[] public lockPools;
  mapping (uint8 => mapping (address => UserInfo)) internal userInfo;

  event Claimed(uint8 pid, address indexed beneficiary, uint256 value);
  event Recovered(address token, uint256 amount);

  modifier onlyOwnerOrSale() {
    require(owner() == msg.sender || sale == msg.sender, "TokenVesting: caller is not the owner or sale");
    _;
  }

  constructor(address _token) public {
    token = IERC20(_token);
  }

  /**
   * @param _sale name of sale
   *
   * @dev method sets sales contract address
   */
  function setSale(address _sale) external onlyOwner {
    sale = _sale;
  }

  /**
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method initialize new vesting pool
   */
  function initVestingPool(string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner() returns(uint8) {
    require(block.timestamp < _startTime, "TokenVesting: invalid pool start time");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    lockPools.push(PoolInfo({
      name: _name,
      startTime: _startTime,
      endTime: _endTime,
      totalLocked: 0,
      index: (uint8)(lockPools.length)
    }));

    return (uint8)(lockPools.length) - 1;
  }

  /**
   * @param _pid        pool id
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method sets new parameters to the vesting pool
   */
  function setVestingPool(uint8 _pid, string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner() {
    require(lockPools[_pid].startTime > block.timestamp, "TokenVesting: pool is already running");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    lockPools[_pid].name = _name;
    lockPools[_pid].startTime = _startTime;
    lockPools[_pid].endTime = _endTime;
  }

  /**
   * @param _pid            pool id
   * @param _beneficiary    new beneficiary
   * @param _lockedAmount   amount to be locked for distribution
   *
   * @dev method adds new beneficiary to the pool
   */
  function addBeneficiary(uint8 _pid, address _beneficiary, uint256 _lockedAmount) external onlyOwnerOrSale() {
    require(_pid < lockPools.length, "TokenVesting: non existing pool");
    require(lockPools[_pid].startTime > block.timestamp, "TokenVesting: pool is already running");

    userInfo[_pid][_beneficiary].lockedAmount = userInfo[_pid][_beneficiary].lockedAmount.add(_lockedAmount);
    lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(userInfo[_pid][_beneficiary].lockedAmount);
  }

  /**
   * @param _pid            pool id
   * @param _beneficiaries  array of beneficiaries
   * @param _lockedAmounts   array of amounts to be locked for distribution
   *
   * @dev method adds new beneficiaries to the pool
   */
  function addBeneficiaryBatches(uint8 _pid, address[] calldata _beneficiaries, uint256[] calldata _lockedAmounts) external onlyOwnerOrSale() {
    require(_beneficiaries.length == _lockedAmounts.length, "TokenVesting: params invalid length");
    require(lockPools[_pid].startTime > block.timestamp, "TokenVesting: pool is already running");
    require(_pid < lockPools.length, "TokenVesting: non existing pool");

    for(uint8 i = 0; i < _beneficiaries.length; i++) {
      address beneficiary = _beneficiaries[i];
      uint256 lockedAmount = _lockedAmounts[i];

      userInfo[_pid][beneficiary].lockedAmount = userInfo[_pid][beneficiary].lockedAmount.add(lockedAmount);
      lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(userInfo[_pid][beneficiary].lockedAmount);
    }
  }

  /**
   * @param _pid  pool id
   *
   * @dev method allows to claim beneficiary locked amount
   */
  function claim(uint8 _pid) external returns(uint256 amount) {
    amount = getReleasableAmount(_pid, msg.sender);
    require (amount > 0, "TokenVesting: can't claim 0 amount");

    userInfo[_pid][msg.sender].withdrawn = userInfo[_pid][msg.sender].withdrawn.add(amount);
    token.safeTransfer(msg.sender, amount);
    
    emit Claimed(_pid, msg.sender, amount);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns amount of releasable funds per beneficiary
   */
  function getReleasableAmount(uint8 _pid, address _beneficiary) public view returns(uint256) {
    return getVestedAmount(_pid, _beneficiary, block.timestamp).sub(userInfo[_pid][_beneficiary].withdrawn);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   * @param _time         time of vesting
   *
   * @dev method returns amount of available for vesting token per beneficiary and time
   */
  function getVestedAmount(uint8 _pid, address _beneficiary, uint256 _time) public view returns(uint256) {
    if (_pid >= lockPools.length){
      return 0;
    }
    
    if(_time < lockPools[_pid].startTime) {
      return 0;
    }

    uint256 lockedAmount = userInfo[_pid][_beneficiary].lockedAmount;
    if (lockedAmount == 0) {
      return 0;
    }

    uint256 vestingDuration = lockPools[_pid].endTime.sub(lockPools[_pid].startTime);
    uint256 timeDuration = _time.sub(lockPools[_pid].startTime);
    uint256 amount = lockedAmount.mul(timeDuration).div(vestingDuration);

    if(amount > lockedAmount){
      amount = lockedAmount;
    }
    return amount;
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns beneficiary details per pool
   */
  function getBeneficiaryInfo(uint8 _pid, address _beneficiary) public view 
    returns(address beneficiary, uint256 totalLocked, uint256 withdrawn, uint256 releasableAmount, uint256 currentTime) {
      beneficiary = _beneficiary;
      currentTime = block.timestamp;

      if(_pid < lockPools.length) {
        totalLocked = userInfo[_pid][_beneficiary].lockedAmount;
        withdrawn = userInfo[_pid][_beneficiary].withdrawn;
        releasableAmount = getReleasableAmount(_pid, _beneficiary);
      }
  }

  /**
   *
   * @dev method returns amount of pools
   */
  function getPoolsCount() external view returns(uint256 poolsCount) {
    return lockPools.length;
  }

  /**
   * @param _pid pool id
   *
   * @dev method returns pool details
   */
  function getPoolInfo(uint8 _pid) external view 
    returns(string memory name, uint256 totalLocked, uint256 startTime, uint256 endTime) {
      if(_pid < lockPools.length) {
        name = lockPools[_pid].name;
        totalLocked = lockPools[_pid].totalLocked;
        startTime = lockPools[_pid].startTime;
        endTime = lockPools[_pid].endTime;
      }
  }

  /**
   *
   * @dev method returns total locked funds
   */
  function getTotalLocked() external view returns(uint256 totalLocked) {
    totalLocked = 0;
    for(uint8 i = 0; i < lockPools.length; i++) {
      totalLocked = totalLocked.add(lockPools[i].totalLocked);
    }
  }

  /**
   * @param _token  token address
   * @param _amount amount to be recovered
   *
   * @dev method allows to recover erc20 tokens
   */
  function recoverERC20(address _token, uint256 _amount) external onlyOwner() {
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Recovered(_token, _amount);
  }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

