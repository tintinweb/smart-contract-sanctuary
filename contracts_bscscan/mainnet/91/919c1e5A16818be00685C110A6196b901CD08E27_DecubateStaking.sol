//** Decubate Staking Contract */
//** Author Aceson */

pragma solidity ^0.8.10;

//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libraries/InterestHelper.sol";
import "./interfaces/IDecubateStaking.sol";
import "./interfaces/IDecubateNFT.sol";

contract DecubateStaking is Ownable, InterestHelper, IDecubateStaking {
  using SafeMath for uint256;
  using SafeMath for uint16;

  struct User {
    uint256 totalInvested;
    uint256 totalWithdrawn;
    uint256 lastPayout;
    uint256 depositTime;
    uint256 totalClaimed;
  }

  IDecubateNFT public nftContract;
  address private feeAddress; //Address which receives fee
  uint8 private feePercent; //Percentage of fee deducted (/1000)
  uint32 private timeGap; //Time interval between price update

  mapping(uint256 => mapping(address => User)) public users;
  mapping(uint256 => uint256[2]) public priceBuffer;

  // /**
  //  *
  //  * @dev PoolInfo reflects the info of each pools
  //  *
  //  * If APY is 12%, we provide 12 as input. lockPeriodInDays
  //  * would be the number of days which the claim is locked.
  //  * So if we want to lock claim for 1 month, lockPeriodInDays would be 30.
  //  *
  //  * @param {apy} Percentage of yield produced by the pool
  //  * @param {nftMultiplier} Multiplier for apy if user holds nft
  //  * @param {lockPeriodInDays} Amount of time claim will be locked
  //  * @param {totalDeposit} Total deposit in the pool
  //  * @param {hardCap} hardCap of the pool
  //  * @param {endDate} ending time of pool in unix timestamp
  //  * @param {inputToken} Token deposited onto the pool
  //  * @param {rewardToken} Token received as reward
  //  * @param {ratio} Price difference between input and output token
  //  * @param {isRewardAboveInput} Price difference between input and output token
  //  *
  //  */
  Pool[] public poolInfo;

  event Stake(address indexed addr, uint256 amount, uint256 time);
  event Claim(address indexed addr, uint256 amount, uint256 time);
  event Reinvest(address indexed addr, uint256 amount, uint256 time);
  event Unstake(address indexed addr, uint256 amount, uint256 time);
  event RatioUpdated(uint256 _pid, uint256 newRatio);

  constructor(address _nft) {
    nftContract = IDecubateNFT(_nft);
    feeAddress = msg.sender;
    feePercent = 5;
    timeGap = 24 hours;
  }

  receive() external payable {
    revert("BNB deposit not supported");
  }

  /**
   *
   * @dev add new period to the pool, only available for owner
   *
   */
  function add(
    uint256 _apy,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    address _tradesAgainst,
    PoolToken memory _inputToken,
    PoolToken memory _rewardToken,
    uint256 _hardCap
  ) external override onlyOwner {
    poolInfo.push(
      Pool({
        apy: _apy,
        nft: NFTMultiplier({
          active: _isUsed,
          startIdx: _startIdx,
          endIdx: _endIdx,
          multiplier: _multiplier
        }),
        lockPeriodInDays: _lockPeriodInDays,
        hardCap: _hardCap,
        totalDeposit: 0,
        endDate: _endDate,
        inputToken: _inputToken,
        rewardToken: _rewardToken,
        ratio: 1,
        tradesAgainst: _tradesAgainst,
        lastUpdatedTime: 0,
        isRewardAboveInput: false
      })
    );

    uint256 poolIndex = poolLength() - 1;

    updateRatio(poolIndex);
  }

  /**
   *
   * @dev update the given pool's Info
   *
   */
  function set(
    uint256 _pid,
    uint256 _apy,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    address _tradesAgainst,
    uint256 _hardCap
  ) external override onlyOwner {
    require(_pid < poolLength(), "Invalid pool Id");

    Pool storage pool = poolInfo[_pid];
    NFTMultiplier storage nft = pool.nft;

    pool.apy = _apy;
    pool.lockPeriodInDays = _lockPeriodInDays;
    pool.endDate = _endDate;
    pool.tradesAgainst = _tradesAgainst;
    pool.hardCap = _hardCap;

    nft.active = _isUsed;
    nft.multiplier = _multiplier;
    nft.startIdx = _startIdx;
    nft.endIdx = _endIdx;
  }

  function setNftContract(address _nft) external onlyOwner {
    nftContract = IDecubateNFT(_nft);
  }

  /**
   *
   * @dev update the given pool's tokens
   *
   */
  function setTokens(
    uint256 _pid,
    PoolToken memory _inputToken,
    PoolToken memory _rewardToken
  ) external override onlyOwner {
    require(_pid < poolLength(), "Invalid pool Id");

    poolInfo[_pid].inputToken = _inputToken;
    poolInfo[_pid].rewardToken = _rewardToken;
  }

  /**
   *
   * @dev Allow owner to transfer token from contract
   *
   * @param {address} contract address of corresponding token
   * @param {uint256} amount of token to be transferred
   *
   * This is a generalized function which can be used to transfer any accidentally
   * sent (including DCB) out of the contract to wowner
   *
   */
  function transferToken(address _addr, uint256 _amount) external onlyOwner returns (bool) {
    IERC20 token = IERC20(_addr);
    bool success = token.transfer(address(owner()), _amount);
    return success;
  }

  /**
   *
   * @dev depsoit tokens to staking for reward allocation
   *
   * @param {_pid} Id of the pool
   * @param {_amount} Amount to be staked
   *
   * @return {bool} Status of stake
   *
   */
  function stake(uint256 _pid, uint256 _amount) external override returns (bool) {
    Pool memory pool = poolInfo[_pid];
    IERC20 token = IERC20(pool.inputToken.addr);

    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Decubate : Set allowance first!"
    );

    bool success = token.transferFrom(msg.sender, address(this), _amount);
    require(success, "Decubate : Transfer failed");

    _claim(_pid, msg.sender);

    _stake(_pid, msg.sender, _amount);

    return success;
  }

  /**
   *
   * @dev withdraw tokens from Staking
   *
   * @param {_pid} id of the pool
   * @param {_amount} amount to be unstaked
   *
   * @return {bool} Status of stake
   *
   */
  function unStake(uint256 _pid, uint256 _amount) external override returns (bool) {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = poolInfo[_pid];

    require(user.totalInvested >= _amount, "You don't have enough funds");

    require(canUnstake(_pid, msg.sender), "Stake still in locked state");

    _claim(_pid, msg.sender);

    pool.totalDeposit = pool.totalDeposit.sub(_amount);
    user.totalInvested = user.totalInvested.sub(_amount);

    safeTransfer(pool.inputToken.addr, msg.sender, _amount);

    emit Unstake(msg.sender, _amount, block.timestamp);

    return true;
  }

  /**
   *
   * @dev update fee values
   *
   */
  function updateFeeValues(uint8 _feePercent, address _feeWallet) external onlyOwner {
    feePercent = _feePercent;
    feeAddress = _feeWallet;
  }

  /**
   *
   * @dev update time gap
   *
   */
  function updateTimeGap(uint32 newValue) external onlyOwner {
    timeGap = newValue;
  }

  /**
   *
   * @dev claim accumulated reward reward for a single pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} status of claim
   */

  function claim(uint256 _pid) public override returns (bool) {
    _claim(_pid, msg.sender);

    return true;
  }

  /**
   *
   * @dev claim accumulated  reward from all pools
   *
   * Beware of gas fee!
   *
   */
  function claimAll() public override returns (bool) {
    uint256 len = poolInfo.length;

    for (uint256 pid = 0; pid < len; ++pid) {
      _claim(pid, msg.sender);
    }

    return true;
  }

  /**
   *
   * @dev Update ratio of a given pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} Status of update
   */
  function updateRatio(uint256 _pid) public returns (bool) {
    _updateRatio(_pid);

    return true;
  }

  /**
   *
   * @dev Update ratio of all pools
   *
   * Beware of gas fee!
   *
   */
  function updateRatioAll() public returns (bool) {
    uint256 len = poolInfo.length;

    for (uint256 pid = 0; pid < len; ++pid) {
      _updateRatio(pid);
    }

    return true;
  }

  /**
   *
   * @dev check whether user can Unstake or not
   *
   * @param {_pid}  id of the pool
   * @param {_addr} address of the user
   *
   * @return {bool} Status of Unstake
   *
   */

  function canUnstake(uint256 _pid, address _addr) public view override returns (bool) {
    User storage user = users[_pid][_addr];
    Pool storage pool = poolInfo[_pid];

    return (block.timestamp >= user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
  }

  /**
   *
   * @dev check whether user have NFT multiplier
   *
   * @param _pid  id of the pool
   * @param _addr address of the user
   *
   * @return multi Value of multiplier
   *
   */

  function calcMultiplier(uint256 _pid, address _addr) public view override returns (uint16 multi) {
    NFTMultiplier memory nft = poolInfo[_pid].nft;

    if (nft.active && ownsCorrectNFT(_addr, _pid)) {
      multi = nft.multiplier;
    } else {
      multi = 10;
    }
  }

  /**
   *
   * @dev get length of the pools
   *
   * @return {uint256} length of the pools
   *
   */
  function poolLength() public view override returns (uint256) {
    return poolInfo.length;
  }

  /**
   *
   * @dev get info of all pools
   *
   * @return {PoolInfo[]} Pool info struct
   *
   */
  function getPools() public view returns (Pool[] memory) {
    return poolInfo;
  }

  function payout(uint256 _pid, address _addr) public view override returns (uint256 value) {
    User memory user = users[_pid][_addr];
    Pool memory pool = poolInfo[_pid];

    uint256 from = user.lastPayout > user.depositTime ? user.lastPayout : user.depositTime;
    uint256 to = block.timestamp > pool.endDate ? pool.endDate : block.timestamp;

    uint256 multiplier = calcMultiplier(_pid, _addr);

    if (from < to) {
      uint256 rayValue = yearlyRateToRay((pool.apy * 10**18) / 1000);
      value = (accrueInterest(user.totalInvested, rayValue, to.sub(from))).sub(user.totalInvested);
    }

    if (pool.isRewardAboveInput) {
      value = value.div(pool.ratio).mul(multiplier).div(10);
    } else {
      value = value.mul(pool.ratio).mul(multiplier).div(10);
    }

    uint8 iToken = IERC20Metadata(pool.inputToken.addr).decimals();
    uint8 rToken = IERC20Metadata(pool.rewardToken.addr).decimals();

    if (iToken > rToken) {
      value = value.div(10**(iToken - rToken));
    } else if (rToken > iToken) {
      value = value.mul(10**(rToken - iToken));
    }

    return value;
  }

  function ownsCorrectNFT(address _addr, uint256 _pid) public view returns (bool) {
    NFTMultiplier memory nft = poolInfo[_pid].nft;

    uint256[] memory ids = nftContract.walletOfOwner(_addr);
    for (uint256 i = 0; i < ids.length; i++) {
      if (ids[i] >= nft.startIdx && ids[i] <= nft.endIdx) {
        return true;
      }
    }
    return false;
  }

  function _claim(uint256 _pid, address _addr) internal {
    User storage user = users[_pid][_addr];
    Pool memory pool = poolInfo[_pid];

    _updateRatio(_pid);

    uint256 amount = payout(_pid, _addr);

    if (amount > 0) {
      if (feePercent > 0) {
        uint256 feeAmount = amount.mul(feePercent).div(1000);
        safeTransfer(pool.rewardToken.addr, feeAddress, feeAmount);
        amount = amount.sub(feeAmount);
      }

      safeTransfer(pool.rewardToken.addr, _addr, amount);

      user.lastPayout = block.timestamp;
      user.totalWithdrawn = user.totalWithdrawn.add(amount);
      user.totalClaimed = user.totalClaimed.add(amount);
    }

    emit Claim(_addr, amount, block.timestamp);
  }

  function _stake(
    uint256 _pid,
    address _sender,
    uint256 _amount
  ) internal {
    User storage user = users[_pid][_sender];
    Pool storage pool = poolInfo[_pid];

    uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));

    require(block.timestamp <= stopDepo, "Staking is disabled for this pool");
    require(pool.totalDeposit + _amount <= pool.hardCap, "Pool is full");

    user.totalInvested = user.totalInvested.add(_amount);
    pool.totalDeposit = pool.totalDeposit.add(_amount);
    user.lastPayout = block.timestamp;
    user.depositTime = block.timestamp;

    emit Stake(_sender, _amount, block.timestamp);
  }

  /**
   *
   * @dev safe  transfer function, require to have enough reward to transfer
   *
   */
  function safeTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) internal {
    IERC20 token = IERC20(_token);
    uint256 bal = token.balanceOf(address(this));

    require(bal >= _amount, "Not enough funds in treasury");

    token.transfer(_to, _amount);
  }

  function _updateRatio(uint256 _pid) internal {
    Pool storage pool = poolInfo[_pid];

    if (pool.endDate > block.timestamp && pool.lastUpdatedTime + timeGap <= block.timestamp) {
      //skipping expired pools

      (uint256 input, uint256 reward) = getPrices(_pid);
      uint32 timeElapsed = uint32(block.timestamp) - pool.lastUpdatedTime;

      uint256 priceInputAverage = (input - priceBuffer[_pid][0]) / timeElapsed;
      uint256 priceRewardAverage = (reward - priceBuffer[_pid][1]) / timeElapsed;

      IERC20Metadata iToken = IERC20Metadata(pool.inputToken.addr);
      IERC20Metadata rToken = IERC20Metadata(pool.rewardToken.addr);

      // Price of 1 input token in BNB
      uint256 priceOfInput = priceInputAverage.mul(10**(iToken.decimals()));
      // Price of 1 reward token in BNB
      uint256 priceOfReward = priceRewardAverage.mul(10**(rToken.decimals()));

      if (priceOfInput > priceOfReward) {
        pool.ratio = priceOfInput / priceOfReward;
        pool.isRewardAboveInput = false;
      } else {
        pool.ratio = priceOfReward / priceOfInput;
        pool.isRewardAboveInput = true;
      }

      priceBuffer[_pid][0] = input;
      priceBuffer[_pid][1] = reward;

      pool.lastUpdatedTime = uint32(block.timestamp);

      emit RatioUpdated(_pid, pool.ratio);
    }
  }

  /**
   *
   * @dev Fetching price from AMM for calculating ratio
   *
   */
  function getPrices(uint256 _pid) internal view returns (uint256 priceInput, uint256 priceReward) {
    Pool memory pool = poolInfo[_pid];

    priceInput = getTokenPrice(pool.inputToken, pool.tradesAgainst);
    priceReward = getTokenPrice(pool.rewardToken, pool.tradesAgainst);
  }

  /**
   *
   * @dev Fetching cumulative price of token
   *
   */
  function getTokenPrice(PoolToken memory _token, address against) internal view returns (uint256) {
    IUniswapV2Router02 router = IUniswapV2Router02(_token.router);
    IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

    address _pair = factory.getPair(_token.addr, against);
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);

    bool tokenIsToken0 = _token.addr == pair.token0();

    (uint256 price0, uint256 price1, ) = UniswapV2OracleLibrary.currentCumulativePrices(_pair);

    return tokenIsToken0 ? price0 : price1;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract DSMath {
  uint256 internal constant WAD = 10**18;
  uint256 internal constant RAY = 10**27;

  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// Using DSMath from DappHub https://github.com/dapphub/ds-math
// More info on DSMath and fixed point arithmetic in Solidity:
// https://medium.com/dapphub/introducing-ds-math-an-innovative-safe-math-library-d58bc88313da

/**
 * @title Interest
 * @author Nick Ward
 * @dev Uses DSMath's wad and ray math to implement (approximately)
 * continuously compounding interest by calculating discretely compounded
 * interest compounded every second.
 */
contract InterestHelper is DSMath {
  /**
   * @dev Uses an approximation of continuously compounded interest
   * (discretely compounded every second)
   * @param _principal The principal to calculate the interest on.
   *   Accepted in wei.
   * @param _rate The interest rate. Accepted as a ray representing
   *   1 + the effective interest rate per second, compounded every
   *   second. As an example:
   *   I want to accrue interest at a nominal rate (i) of 5.0% per year
   *   compounded continuously. (Effective Annual Rate of 5.127%).
   *   This is approximately equal to 5.0% per year compounded every
   *   second (to 8 decimal places, if max precision is essential,
   *   calculate nominal interest per year compounded every second from
   *   your desired effective annual rate). Effective Rate Per Second =
   *   Nominal Rate Per Second compounded every second = Nominal Rate
   *   Per Year compounded every second * conversion factor from years
   *   to seconds
   *   Effective Rate Per Second = 0.05 / (365 days/yr * 86400 sec/day)
   *                             = 1.5854895991882 * 10 ** -9
   *   The value we want to send this function is
   *   1 * 10 ** 27 + Effective Rate Per Second * 10 ** 27
   *   = 1000000001585489599188229325
   *   This will return 5.1271096334354555 Dai on a 100 Dai principal
   *   over the course of one year (31536000 seconds)
   * @param _age The time period over which to accrue interest. Accepted
   *   in seconds.
   * @return The new principal as a wad. Equal to original principal +
   *   interest accrued
   */
  function accrueInterest(
    uint256 _principal,
    uint256 _rate,
    uint256 _age
  ) public pure returns (uint256) {
    return rmul(_principal, rpow(_rate, _age));
  }

  /**
   * @dev Takes in the desired nominal interest rate per year, compounded
   *   every second (this is approximately equal to nominal interest rate
   *   per year compounded continuously). Returns the ray value expected
   *   by the accrueInterest function
   * @param _rateWad A wad of the desired nominal interest rate per year,
   *   compounded continuously. Converting from ether to wei will effectively
   *   convert from a decimal value to a wad. So 5% rate = 0.05
   *   should be input as yearlyRateToRay( 0.05 ether )
   * @return 1 * 10 ** 27 + Effective Interest Rate Per Second * 10 ** 27
   */
  function yearlyRateToRay(uint256 _rateWad) public pure returns (uint256) {
    return add(wadToRay(1 ether), rdiv(wadToRay(_rateWad), weiToRay(365 * 86400)));
  }

  //// Fixed point scale factors
  // wei -> the base unit
  // wad -> wei * 10 ** 18. 1 ether = 1 wad, so 0.5 ether can be used
  //      to represent a decimal wad of 0.5
  // ray -> wei * 10 ** 27

  // Go from wad (10**18) to ray (10**27)
  function wadToRay(uint256 _wad) internal pure returns (uint256) {
    return mul(_wad, 10**9);
  }

  // Go from wei to ray (10**27)
  function weiToRay(uint256 _wei) internal pure returns (uint256) {
    return mul(_wei, 10**27);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDecubateStaking {
  struct NFTMultiplier {
    bool active;
    uint16 multiplier;
    uint16 startIdx;
    uint16 endIdx;
  }

  struct PoolToken {
    address addr;
    address router;
  }

  struct Pool {
    uint256 apy;
    NFTMultiplier nft;
    uint256 lockPeriodInDays;
    uint256 totalDeposit;
    uint256 hardCap;
    uint256 endDate;
    PoolToken inputToken;
    PoolToken rewardToken;
    uint256 ratio;
    address tradesAgainst;
    uint32 lastUpdatedTime;
    bool isRewardAboveInput;
  }

  function add(
    uint256 _apy,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    address _tradesAgainst,
    PoolToken memory _inputToken,
    PoolToken memory _rewardToken,
    uint256 _hardCap
  ) external;

  function set(
    uint256 _pid,
    uint256 _apy,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    address _tradesAgainst,
    uint256 _hardCap
  ) external;

  function setTokens(
    uint256 _pid,
    PoolToken memory _inputToken,
    PoolToken memory _rewardToken
  ) external;

  function stake(uint256 _pid, uint256 _amount) external returns (bool);

  function unStake(uint256 _pid, uint256 _amount) external returns (bool);

  function updateFeeValues(uint8 _feePercent, address _feeWallet) external;

  function updateTimeGap(uint32 newValue) external;

  function claim(uint256 _pid) external returns (bool);

  function claimAll() external returns (bool);

  function updateRatio(uint256 _pid) external returns (bool);

  function updateRatioAll() external returns (bool);

  function poolInfo(uint256)
    external
    view
    returns (
      uint256 apy,
      NFTMultiplier memory nft,
      uint256 lockPeriodInDays,
      uint256 totalDeposit,
      uint256 hardCap,
      uint256 endDate,
      PoolToken memory inputToken,
      PoolToken memory rewardToken,
      uint256 ratio,
      address tradesAgainst,
      uint32 lastUpdatedTime,
      bool isRewardAboveInput
    );

  function users(uint256, address)
    external
    view
    returns (
      uint256 totalInvested,
      uint256 totalWithdrawn,
      uint256 lastPayout,
      uint256 depositTime,
      uint256 totalClaimed
    );

  function canUnstake(uint256 _pid, address _addr) external view returns (bool);

  function calcMultiplier(uint256 _pid, address _addr) external view returns (uint16 multi);

  function poolLength() external view returns (uint256);

  function payout(uint256 _pid, address _addr) external view returns (uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDecubateNFT {
  function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}