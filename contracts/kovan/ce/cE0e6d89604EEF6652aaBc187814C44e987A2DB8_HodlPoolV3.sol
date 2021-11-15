//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./extensions/ERC721EnumerableForOwner.sol";
import "./extensions/IWETH.sol";

/*
 * @title Token pools that allow different ERC20 tokens (assets) and ETH deposits 
 * and withdrawals with penalty and bonus mechanisms that incentivise long term holding. 
 * The initial penalty and commitment time are chosen at the time of the deposit by
 * the user.
 * The deposits into this contract are transferrable and immutable ERC721 tokens.
 * There are two bonus types for each pool - holding bonus (to incetivise holding), 
 * and commitment bonus (to incetivise commiting to penalties & time).
 * Each ERC20 asset has one independent pool. i.e. all accounting is separate.
 * ERC20 tokens may have fee-on-transfer or dynamic supply mechanisms, and for these
 * kinds of tokens this contract tracks everything as "shares of initial deposits". 
 * @notice The mechanism rules:
 * - A depositor is committing for "commitment period" and an "initial penalty percent" 
 *   of his choice (within allowed ranges). After the commitment period the
 *   deposit can be withdrawn with its share of both of the bonus pools.
 * - The two bonus pools are populated from the penalties for early withdrawals,
 *   which are withdrawals done before a deposit's commitment period is elapsed.
 * - The penalties are split in half and added to both bonus pools (isolated per asset): 
 *   Hold bonus pool and Commit bonus pool.
 * - The share of the bonus pools is equal to the share of the bonus points (hold-points 
 *   and commit-points) for the deposit at the time of withdrawal relative to the other
 *   deposits in the pool.
 * - Hold points are calculated as amount of asset x seconds held. So more tokens
 *   held for longer add more points - and increase the bonus share. This bonus is
 *   independent of commitment or penalties. The points keep increasing after commitment period
 *   is over.
 * - Commit points are calculated as amount of asset x seconds committed to penalty.
 *   These points depend only on commitment time and commitment penalty 
 *   at the time of the deposit.
 * - Withdrawal before commitment period is not entitled to any part of the bonus
 *   and is instead "slashed" with a penalty (that is split between the bonuses pools).
 * - The penalty percent is decreasing with time from the chosen
 *   initialPenaltyPercent to 0 at the end of the commitPeriod. 
 * - Each deposit has a separate ERC721 tokenId with the usual tranfer mechanics. So
 *   multiple deposits for same owner and asset but with different commitment
 *   parameters can co-exist independently.
 * - Deposits can be deposited for another account as beneficiary,
 *   so e.g. a team / DAO can deposit its tokens for its members to withdraw.
 * - Only the deposit "owner" can use the withdrawal functionality, so ERC721 approvals 
 *   allow transfers, but not the withdrawals.
 *
 * @dev 
 * 1. For safety and clarity, the withdrawal functionality is split into 
 * two methods, one for withdrawing with penalty, and the other one for withdrawing
 * with bonus.
 * 2. The ERC20 token and ETH functionality is split into separate methods.
 * The total deposits shares are tracked per token contract in 
 * depositSums, bonuses in bonusSums.
 * 3. Deposit for self depositFor are split into separate methods
 * for clarity.
 * 4. For tokens with dynamic supply mechanisms and fee on transfer all internal
 * calculations are done using the "initial desposit amounts" as fair shares, and
 * upon withdrawal are translated to actual amounts of the contract's token balance.
 * This means that for these tokens the actual amounts received are depends on their
 * mechanisms (because the amount is unknown before actual transfers).
 * 5. To reduce RPC calls and simplify interface, all the deposit and pool views are
 * batched in depositDetails and poolDetails which return arrays of values.
 * 6. To prevent relying on tracking deposit, withdrawal, and transfer events
 * depositsOfOwner view shows all deposits owned by a particular owner.
 * 7. The total of a pool's hold points are updated incrementally on each interaction
 * with a pool using the depositsSum in that pool for that period. If can only happen
 * once per block because it depends on the time since last update.
 * 8. TokenURI returns a JSON string with just name and description metadata.
 *
 * @author artdgn (@github)
 */
contract HodlPoolV3 is ERC721EnumerableForOwner {

  using SafeERC20 for IERC20;
  using Strings for uint;

  /// @dev state variables for a deposit in a pool
  struct Deposit {
    address asset;
    uint40 time;
    uint16 initialPenaltyPercent;
    uint40 commitPeriod;
    uint amount;
  }

  /// @dev state variables for a token pool
  struct Pool {
    uint depositsSum;  // sum of all current deposits
    uint holdBonusesSum;  // sum of hold bonus pool
    uint commitBonusesSum;  // sum of commit bonus pool
    uint totalHoldPoints;  // sum of hold-points 
    uint totalHoldPointsUpdateTime;  //  time of the latest hold-points update
    uint totalCommitPoints;  // sum of commit-points
  }
  
  /// @notice minimum initial percent of penalty
  uint public immutable minInitialPenaltyPercent;  

  /// @notice minimum commitment period for a deposit
  uint public immutable minCommitPeriod;

  /// @notice compatibility with ERC20 for e.g. viewing in metamask
  uint public constant decimals = 0;

  /// @notice WETH token contract this pool is using for handling ETH
  // slither-disable-next-line naming-convention
  address public immutable WETH;

  /// @dev tokenId incremted counter
  uint internal nextTokenId = 1;

  /// @dev deposit data for each tokenId
  mapping(uint => Deposit) deposits;

  /// @dev pool state for each token contract address
  ///   default values are all zeros, no need to init
  // slither-disable-next-line uninitialized-state
  mapping(address => Pool) pools;

  /*
   * @param asset ERC20 token address for the deposited asset
   * @param account address that has made the deposit
   * @param amount size of new deposit, or deposit increase
   * @param amountReceived received balance after transfer (actual deposit)
   *  which may be different due to transfer-fees and other token shenanigans
   * @param time timestamp from which the commitment period will be counted
   * @param initialPenaltyPercent initial penalty percent for the deposit
   * @param commitPeriod commitment period in seconds for the deposit
   * @param tokenId deposit ERC721 tokenId
   */
  event Deposited(
    address indexed asset, 
    address indexed account, 
    uint amount, 
    uint amountReceived, 
    uint time,
    uint initialPenaltyPercent,
    uint commitPeriod,
    uint tokenId
  );

  /*
   * @param asset ERC20 token address for the withdrawed asset
   * @param account address that has made the withdrawal
   * @param amount amount sent out to account as withdrawal
   * @param depositAmount the original amount deposited
   * @param penalty the penalty incurred for this withdrawal
   * @param holdBonus the hold-bonus included in this withdrawal
   * @param commitBonus the commit-bonus included in this withdrawal
   * @param timeHeld the time in seconds the deposit was held
   */
  event Withdrawed(
    address indexed asset,
    address indexed account, 
    uint amount, 
    uint depositAmount, 
    uint penalty, 
    uint holdBonus,
    uint commitBonus,
    uint timeHeld
  );

  /// @dev checks commitment params are within allowed ranges
  modifier validCommitment(uint initialPenaltyPercent, uint commitPeriod) {
    require(initialPenaltyPercent >= minInitialPenaltyPercent, "penalty too small"); 
    require(initialPenaltyPercent <= 100, "initial penalty > 100%"); 
    require(commitPeriod >= minCommitPeriod, "commitment period too short");
    require(commitPeriod <= 4 * 365 days, "commitment period too long");
    _;
  }

  /*
   * @param _minInitialPenaltyPercent the minimum penalty percent for deposits
   * @param _minCommitPeriod the minimum time in seconds for commitPeriod of a deposit
   * @param _WETH wrapped ETH contract address this pool will be using for ETH
  */
  constructor (
    uint _minInitialPenaltyPercent, 
    uint _minCommitPeriod, 
    address _WETH
  ) 
    ERC721("HodlBonusPool V3", "HodlPoolV3") 
  {
    require(_minInitialPenaltyPercent > 0, "no min penalty"); 
    require(_minInitialPenaltyPercent <= 100, "minimum initial penalty > 100%"); 
    require(_minCommitPeriod >= 10 seconds, "minimum commitment period too short");
    require(_minCommitPeriod <= 4 * 365 days, "minimum commitment period too long");
    require(_WETH != address(0), "WETH address can't be 0x0");
    minInitialPenaltyPercent = _minInitialPenaltyPercent;
    minCommitPeriod = _minCommitPeriod;
    WETH = _WETH;
  }

  /// @notice contract doesn't support sending ETH directly
  receive() external payable {
    require(
      msg.sender == WETH, 
      "no receive() except from WETH contract, use depositETH()");
  }

  /* * * * * * * * * * *
   * 
   * Public transactions
   * 
   * * * * * * * * * * *
  */

  /*
   * @notice adds a deposit into its asset pool and mints an ERC721 token
   * @param asset address of ERC20 token contract
   * @param amount of token to deposit
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   * @return ERC721 tokenId of this deposit   
   */
  function deposit(
    address asset, 
    uint amount, 
    uint initialPenaltyPercent,
    uint commitPeriod
  ) public
    validCommitment(initialPenaltyPercent, commitPeriod) 
    returns (uint tokenId)
  {
    require(amount > 0, "empty deposit");

    // interal accounting update
    tokenId = _depositAndMint(
      asset, 
      msg.sender,
      amount,
      initialPenaltyPercent, 
      commitPeriod
    );

    // this contract's balance before the transfer
    uint beforeBalance = IERC20(asset).balanceOf(address(this));

    // transfer
    IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

    // what was actually received, this amount is only used in the event and 
    // not used for any internal accounting so reentrancy from transfer is not
    // a substantial risk
    uint amountReceived = IERC20(asset).balanceOf(address(this)) - beforeBalance;

    // because we want to know how much was received, reentrancy-*events* is low-risk
    // slither-disable-next-line reentrancy-events
    emit Deposited(
      asset,
      msg.sender, 
      amount, 
      amountReceived, 
      block.timestamp, 
      initialPenaltyPercent, 
      commitPeriod,
      tokenId
    );
  }

  /*
   * @notice payable method for depositing ETH with same logic as deposit(), 
   * adds a deposit into WETH asset pool and mints an ERC721 token
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   * @return ERC721 tokenId of this deposit
   */
  function depositETH(
    uint initialPenaltyPercent,
    uint commitPeriod
  ) public
    validCommitment(initialPenaltyPercent, commitPeriod) 
    payable
    returns (uint tokenId)
  {
    require(msg.value > 0, "empty deposit");

    // interal accounting update
    tokenId = _depositAndMint(
      WETH, 
      msg.sender,
      msg.value,
      initialPenaltyPercent, 
      commitPeriod
    );

    emit Deposited(
      WETH, 
      msg.sender, 
      msg.value, 
      msg.value, 
      block.timestamp, 
      initialPenaltyPercent, 
      commitPeriod,
      tokenId
    );

    // note: no share vs. balance accounting for WETH because it's assumed to
    // exactly correspond to actual deposits and withdrawals (no fee-on-transfer etc)
    IWETH(WETH).deposit{value: msg.value}();
  }

  /*
   * @notice adds a deposit, mints an ERC721 token, and transfers
   * its ownership to another account
   * @param account that will be the owner of this deposit (can withdraw)
   * @param asset address of ERC20 token contract
   * @param amount of token to deposit
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   * @return ERC721 tokenId of this deposit   
   */
  function depositFor(
    address account,
    address asset, 
    uint amount, 
    uint initialPenaltyPercent,
    uint commitPeriod
  ) external
    validCommitment(initialPenaltyPercent, commitPeriod) 
    returns (uint tokenId) {
    tokenId = deposit(asset, amount, initialPenaltyPercent, commitPeriod);
    _transfer(msg.sender, account, tokenId);
  }

  /*
   * @notice adds an ETH deposit, mints an ERC721 token, and transfers
   * its ownership to another account
   * @param account that will be the owner of this deposit (can withdraw)
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   * @return ERC721 tokenId of this deposit
   */
  function depositETHFor(
    address account,
    uint initialPenaltyPercent,
    uint commitPeriod
  ) external payable
    validCommitment(initialPenaltyPercent, commitPeriod) 
    returns (uint tokenId) {
    tokenId = depositETH(initialPenaltyPercent, commitPeriod);
    _transfer(msg.sender, account, tokenId);
  }
  
  /*
   * @param tokenId ERC721 tokenId of the deposit to withdraw
   * @notice withdraw the full deposit with the proportional shares of bonus pools.
   *   will fail for early withdawals (for which there is another method)
   * @dev checks that the deposit is non-zero
   */
  function withdrawWithBonus(uint tokenId) external {
    require(
      _timeLeft(deposits[tokenId]) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdrawERC20(tokenId);
  }

  /// @notice withdraw ETH with bonus with same logic as withdrawWithBonus()
  function withdrawWithBonusETH(uint tokenId) external {
    require(
      _timeLeft(deposits[tokenId]) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenaltyETH()"
    );
    _withdrawETH(tokenId);
  }

  /*
   * @param tokenId ERC721 tokenId of the deposit to withdraw
   * @notice withdraw the deposit with any applicable penalty. Will withdraw 
   * with any available bonus if penalty is 0 (commitment period elapsed).
   */
  function withdrawWithPenalty(uint tokenId) external {
    _withdrawERC20(tokenId);
  }

  /// @notice withdraw ETH with penalty with same logic as withdrawWithPenalty()
  function withdrawWithPenaltyETH(uint tokenId) external {
    _withdrawETH(tokenId);
  }

  /* * * * * * * *
   * 
   * Public views
   * 
   * * * * * * * *
  */

  /*
   * @param tokenId ERC721 tokenId of a deposit
   * @return array of 12 values corresponding to the details of the deposit:
   *  0. asset - asset address converted to uint
   *  1. owner - deposit owner
   *  2. balance - original deposit(s) value
   *  3. timeLeftToHold - time in seconds until deposit can be withdrawed 
   *     with bonus and no penalty
   *  4. penalty - penalty if withdrawed now
   *  5. holdBonus - hold-bonus if withdrawed now (if possible to withdraw with bonus)
   *  6. commitBonus - commit-bonus if withdrawed now (if possible to withdraw with bonus)
   *  7. holdPoints - current amount of hold-point
   *  8. commitPoints - current amount of commit-point
   *  9. initialPenaltyPercent - initial penalty percent (set at time od deposit)
   *  10. currentPenaltyPercent - current penalty percent (penalty percent if withdrawed now)
   *  11. commitPeriod - commitment period set at the time of deposit
   */
  function depositDetails(
    uint tokenId
  ) external view returns (uint[12] memory) {
    Deposit storage dep = deposits[tokenId];
    Pool storage pool = pools[dep.asset];
    address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
    return [
      uint(uint160(dep.asset)),  // asset
      uint(uint160(owner)),  // account owner
      _sharesToAmount(dep.asset, dep.amount),  // balance
      _timeLeft(dep),  // timeLeftToHold
      _sharesToAmount(dep.asset, _depositPenalty(dep)),  // penalty
      _sharesToAmount(dep.asset, _holdBonus(pool, dep)),  // holdBonus
      _sharesToAmount(dep.asset, _commitBonus(pool, dep)),  // commitBonus
      _holdPoints(dep),  // holdPoints
      _commitPoints(dep),  // commitPoints
      dep.initialPenaltyPercent,  // initialPenaltyPercent
      _currentPenaltyPercent(dep),  // currentPenaltyPercent
      dep.commitPeriod  // commitPeriod
    ];
  }

  /*
   * @param asset address of ERC20 token contract
   * @return array of 5 values corresponding to the details of the pool:
   *  0. depositsSum - sum of current deposits
   *  1. holdBonusesSum - sum of tokens to be distributed as hold bonuses
   *  2. commitBonusesSum - sum of tokens to be distributed as commitment bonuses
   *  3. totalHoldPoints - sum of hold-points of all current deposits
   *  4. totalCommitPoints - sum of commit-points of all current deposits
   */
  function poolDetails(address asset) external view returns (uint[5] memory) {
    Pool storage pool = pools[asset];
    return [
      _sharesToAmount(asset, pool.depositsSum),  // depositsSum
      _sharesToAmount(asset, pool.holdBonusesSum),  // holdBonusesSum
      _sharesToAmount(asset, pool.commitBonusesSum),  // commitBonusesSum
      _totalHoldPoints(pool),  // totalHoldPoints
      pool.totalCommitPoints  // totalCommitPoints
    ];
  }

  /*
   * @param account address of an owner account
   * @return two arrays of the deposits owned by this account:
   *  0. array of deposits' tokenIds
   *  1. array of deposits' data (Deposit struct)
   */
  function depositsOfOwner(
    address account
  ) external view returns (
      uint[] memory tokenIds, 
      Deposit[] memory accountDeposits
  ) {
    uint balance = balanceOf(account);
    tokenIds = new uint[](balance);
    accountDeposits = new Deposit[](balance);
    for (uint i; i < balance; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(account, i);
      accountDeposits[i] = deposits[tokenIds[i]];
    }
  }

  /*
   * @param tokenId ERC721 tokenId of a deposit
   * @return string with metadata JSON containing the NFT's name and description
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721: nonexistent token");
      Deposit storage dep = deposits[tokenId];
      return string(abi.encodePacked(
        '{"name":"Hodl-bonus-pool deposit, tokenId: ', 
        tokenId.toString(),
        '", "description":"ERC20 asset address: ',
        (uint(uint160(dep.asset))).toHexString(20),
        '\\nDeposited amount: ',
        dep.amount.toString(),
        ' wei (of token)\\nDeposited at: ',
        uint(dep.time).toString(),
        ' seconds unix epoch\\nInitial penalty percent: ',
        uint(dep.initialPenaltyPercent).toString(),
        '%\\nCommitment period: ',
        uint(dep.commitPeriod).toString(),
        ' seconds"}'
      ));
    }

  /* * * * * * * * * * * *
   * 
   * Internal transactions
   * 
   * * * * * * * * * * * *
  */

  /// @dev the order of calculations is important for correct accounting
  function _depositAndMint(
    address asset, 
    address account,
    uint amount, 
    uint initialPenaltyPercent, 
    uint commitPeriod
  ) internal returns (uint tokenId) {
    // get token id and increment
    tokenId = nextTokenId++;

    // mint token
    _mint(account, tokenId);

    // add deposit data
    deposits[tokenId] = Deposit({
      asset: asset,
      time: uint40(block.timestamp),
      initialPenaltyPercent: uint16(initialPenaltyPercent),
      commitPeriod: uint40(commitPeriod),
      amount: amount
    });

    // pool state update
    _addDepositToPool(asset, deposits[tokenId]);
  }

  /// @dev pool state update for new deposit
  function _addDepositToPool(address asset, Deposit storage dep) internal {
    Pool storage pool = pools[asset];
    // update pool's total hold time due to passage of time
    // because the deposits sum is going to change
    _updatePoolHoldPoints(pool);
    // WARNING: the deposits sum needs to be updated after the hold-points
    // for the passed time were updated
    pool.depositsSum += dep.amount;    
    pool.totalCommitPoints += _commitPoints(dep);
  }

  // this happens on every pool interaction (so every withdrawal and deposit to that pool)
  function _updatePoolHoldPoints(Pool storage pool) internal {
    // add points proportional to amount held in pool since last update
    pool.totalHoldPoints = _totalHoldPoints(pool);    
    pool.totalHoldPointsUpdateTime = block.timestamp;
  }  
  
  function _withdrawERC20(uint tokenId) internal {
    address asset = deposits[tokenId].asset;
    address account = ownerOf(tokenId);
    require(account == msg.sender, "not deposit owner");
    uint amountOut = _amountOutAndBurn(tokenId);
    // WARNING: asset and account must be set before token is burned
    IERC20(asset).safeTransfer(account, amountOut);
  }

  function _withdrawETH(uint tokenId) internal {
    address account = ownerOf(tokenId);
    require(account == msg.sender, "not deposit owner");
    require(deposits[tokenId].asset == WETH, "not an ETH / WETH deposit");
    
    uint amountOut = _amountOutAndBurn(tokenId);

    IWETH(WETH).withdraw(amountOut);
    // WARNING: account must be set before token is burned
    // - call is used because if contract is withdrawing it may need more gas than what .transfer sends
    // slither-disable-next-line low-level-calls
    (bool success, ) = payable(account).call{value: amountOut}("");
    require(success);
  }

  /// @dev the order of calculations is important for correct accounting
  function _amountOutAndBurn(uint tokenId) internal returns (uint amountOut) {
    // WARNING: deposit is only read here and is not updated until it's removal
    Deposit storage dep = deposits[tokenId];
    address asset = dep.asset;

    Pool storage pool = pools[asset];
    // update pool hold-time points due to passage of time
    // WARNING: failing to do so will break hold-time holdBonus calculation
    _updatePoolHoldPoints(pool);

    // calculate penalty & bunus before making changes
    uint penalty = _depositPenalty(dep);
    uint holdBonus = 0;
    uint commitBonus = 0;
    uint withdrawShare = dep.amount - penalty;
    if (penalty == 0) {
      // only get any bonuses if no penalty
      holdBonus =  _holdBonus(pool, dep);
      commitBonus =  _commitBonus(pool, dep);
      withdrawShare += holdBonus + commitBonus;
    }
    
    // WARNING: get amount here before state is updated
    amountOut = _sharesToAmount(asset, withdrawShare);

    // WARNING: emit event here with all the needed data, before pool state updates
    // affect shareToAmount calculations    
    emit Withdrawed(
      asset,
      ownerOf(tokenId),
      amountOut, 
      dep.amount, 
      _sharesToAmount(asset, penalty), 
      _sharesToAmount(asset, holdBonus), 
      _sharesToAmount(asset, commitBonus), 
      _timeHeld(dep.time)
    );

    // pool state update
    // WARNING: shares calculations need to happen before this update
    // because the depositSum changes    
    _removeDepositFromPool(pool, dep, penalty, holdBonus, commitBonus);
    
    // deposit update: remove deposit
    // WARNING: note that removing the deposit before this line will 
    // change "dep" because it's used by reference and will affect the other
    // computations for pool state updates (e.g. hold points)    
    delete deposits[tokenId];   

    // burn token
    _burn(tokenId);
  }

  /// @dev pool state update for removing a deposit
  function _removeDepositFromPool(
    Pool storage pool, Deposit storage dep, uint penalty, uint holdBonus, uint commitBonus
  ) internal {
    // update total deposits
    pool.depositsSum -= dep.amount;        
    // remove the acrued hold-points for this deposit
    pool.totalHoldPoints -= _holdPoints(dep);
    // remove the commit-points
    pool.totalCommitPoints -= _commitPoints(dep);
        
    if (penalty == 0 && (holdBonus > 0 || commitBonus > 0)) {
      pool.holdBonusesSum -= holdBonus;
      // update commitBonus pool
      pool.commitBonusesSum -= commitBonus;  
    } else {
      // update hold-bonus pool: split the penalty into two parts
      // half for hold bonuses, half for commit bonuses
      pool.holdBonusesSum += penalty / 2;
      // update commitBonus pool
      pool.commitBonusesSum += (penalty - (penalty / 2));
    }
  }

  /* * * * * * * * *
   * 
   * Internal views
   * 
   * * * * * * * * *
  */

  function _timeHeld(uint time) internal view returns (uint) {
    return block.timestamp - time;
  }

  function _timeLeft(Deposit storage dep) internal view returns (uint) {
    uint timeHeld = _timeHeld(dep.time);
    return (timeHeld >= dep.commitPeriod) ? 0 : (dep.commitPeriod - timeHeld);
  }

  function _holdPoints(Deposit storage dep) internal view returns (uint) {
    // points proportional to amount held since deposit start    
    return dep.amount * _timeHeld(dep.time);
  }

  function _commitPoints(Deposit storage dep) internal view returns (uint) {
    // points proportional to amount held since deposit start    
    // triangle area of commitpent time and penalty
    return (
      dep.amount * dep.initialPenaltyPercent * dep.commitPeriod
      / 100 / 2
    );
  }

  function _currentPenaltyPercent(Deposit storage dep) internal view returns (uint) {
    uint timeLeft = _timeLeft(dep);
    if (timeLeft == 0) { // no penalty
      return 0;
    } else {
      // current penalty percent is proportional to time left
      uint curPercent = (dep.initialPenaltyPercent * timeLeft) / dep.commitPeriod;
      // add 1 to compensate for rounding down unless when below initial amount
      return curPercent < dep.initialPenaltyPercent ? curPercent + 1 : curPercent;
    }
  }

  function _depositPenalty(Deposit storage dep) internal view returns (uint) {
    uint timeLeft = _timeLeft(dep);
    if (timeLeft == 0) {  // no penalty
      return 0;
    } else {
      // order important to prevent rounding to 0
      return (
        (dep.amount * dep.initialPenaltyPercent * timeLeft) 
        / dep.commitPeriod)  // can't be zero
        / 100;
    }
  }

  function _holdBonus(Pool storage pool, Deposit storage dep) internal view returns (uint) {
    // share of bonus is proportional to hold-points of this deposit relative
    // to total hold-points in the pool
    // order important to prevent rounding to 0
    uint denom = _totalHoldPoints(pool);  // don't divide by 0
    uint holdPoints = _holdPoints(dep);
    return denom > 0 ? ((pool.holdBonusesSum * holdPoints) / denom) : 0;
  }

  function _commitBonus(Pool storage pool, Deposit storage dep) internal view returns (uint) {
    // share of bonus is proportional to commit-points of this deposit relative
    // to all other commit-points in the pool
    // order important to prevent rounding to 0
    uint denom = pool.totalCommitPoints;  // don't divide by 0
    uint commitPoints = _commitPoints(dep);
    return denom > 0 ? ((pool.commitBonusesSum * commitPoints) / denom) : 0;
  }

  function _totalHoldPoints(Pool storage pool) internal view returns (uint) {
    uint elapsed = block.timestamp - pool.totalHoldPointsUpdateTime;
    // points proportional to amount held in pool since last update
    return pool.totalHoldPoints + (pool.depositsSum * elapsed);
  }

  /// @dev translates deposit shares to actual token amounts - which can be different 
  /// from the initial deposit amount for tokens with funky fees and supply mechanisms.
  function _sharesToAmount(address asset, uint share) internal view returns (uint) {
    if (share == 0) {  // gas savings
      return 0;
    }
    // all tokens that belong to this contract are either 
    // in deposits or in the two bonuses pools
    Pool storage pool = pools[asset];
    uint totalShares = pool.depositsSum + pool.holdBonusesSum + pool.commitBonusesSum;
    if (totalShares == 0) {  // don't divide by zero
      return 0;  
    } else {
      // it's safe to call external balanceOf here because 
      // it's a view (and this method is also view)
      uint actualBalance = IERC20(asset).balanceOf(address(this));      
      return actualBalance * share / totalShares;
    }
  }

  // remove super implementation
  function _baseURI() internal view virtual override returns (string memory) {}  
      
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @dev reduced scope of "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
///   only enumeration for owner is kept, enumeration for whole contract is removed (gas savings)
abstract contract ERC721EnumerableForOwner is ERC721 {
    // Mapping from owner to mapping of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens mapping
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @dev interface for interacting with WETH (wrapped ether) for handling ETH
/// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH {
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

