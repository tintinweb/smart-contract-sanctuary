//** Decubate Staking Contract */
//** Author Vipin */

//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/InterestHelper.sol";
import "./interfaces/IDecubateMasterChef.sol";

pragma solidity ^0.8.8;

interface IDecubateNFT {
  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory);
}

contract DecubateMasterChef is Ownable, InterestHelper, IDecubateMasterChef {
  using SafeMath for uint256;
  using SafeMath for uint16;

  /**
   *
   * @dev PoolInfo reflects the info of each pools
   *
   * If APY is 12%, we provide 120 as input. lockPeriodInDays
   * would be the number of days which the claim is locked.
   * So if we want to lock claim for 1 month, lockPeriodInDays would be 30.
   *
   * @param {apy} Percentage of yield produced by the pool
   * @param {nft} Multiplier for apy if user holds nft
   * @param {lockPeriodInDays} Amount of time claim will be locked
   * @param {totalDeposit} Total deposit in the pool
   * @param {startDate} starting time of pool
   * @param {endDate} ending time of pool in unix timestamp
   * @param {minContrib} Minimum amount to be staked
   * @param {maxContrib} Maximum amount that can be staked
   * @param {hardCap} Maximum amount a pool can hold
   * @param {token} Token used as deposit/reward
   *
   */

  struct Pool {
    uint256 apy;
    NFTMultiplier nft;
    uint256 lockPeriodInDays;
    uint256 totalDeposit;
    uint256 startDate;
    uint256 endDate;
    uint256 minContrib;
    uint256 maxContrib;
    uint256 hardCap;
    address token;
  }

  IDecubateNFT public nftContract;
  address public compounderContract; //Auto compounder
  address private feeAddress; //Address which receives fee
  uint8 private feePercent; //Percentage of fee deducted (/1000)

  mapping(uint256 => mapping(address => User)) public users;

  Pool[] public poolInfo;

  event Stake(address indexed addr, uint256 amount, uint256 time);
  event Claim(address indexed addr, uint256 amount, uint256 time);
  event Reinvest(address indexed addr, uint256 amount, uint256 time);
  event Unstake(address indexed addr, uint256 amount, uint256 time);

  constructor(address _nft) {
    nftContract = IDecubateNFT(_nft);
    feeAddress = msg.sender;
    feePercent = 5;
  }

  receive() external payable {
    revert("BNB deposit not supported");
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
    uint256 _minContrib,
    uint256 _maxContrib,
    uint256 _hardCap,
    address _token
  ) public override onlyOwner {
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
        totalDeposit: 0,
        startDate: block.timestamp,
        endDate: _endDate,
        minContrib: _minContrib,
        maxContrib: _maxContrib,
        hardCap: _hardCap,
        token: _token
      })
    );

    _stake(poolLength() - 1, compounderContract, 0, false); //Mock deposit for compounder
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
    uint256 _minContrib,
    uint256 _maxContrib,
    uint256 _hardCap,
    address _token
  ) public override onlyOwner {
    require(_pid < poolLength(), "Invalid pool Id");

    NFTMultiplier storage nft = poolInfo[_pid].nft;

    poolInfo[_pid].apy = _apy;
    poolInfo[_pid].lockPeriodInDays = _lockPeriodInDays;
    poolInfo[_pid].endDate = _endDate;
    poolInfo[_pid].minContrib = _minContrib;
    poolInfo[_pid].maxContrib = _maxContrib;
    poolInfo[_pid].hardCap = _hardCap;
    poolInfo[_pid].token = _token;

    nft.active = _isUsed;
    nft.multiplier = _multiplier;
    nft.startIdx = _startIdx;
    nft.endIdx = _endIdx;
  }

  /**
   *
   * @dev depsoit tokens to staking for TOKEN allocation
   *
   * @param {_pid} Id of the pool
   * @param {_amount} Amount to be staked
   *
   * @return {bool} Status of stake
   *
   */
  function stake(uint256 _pid, uint256 _amount)
    external
    override
    returns (bool)
  {
    Pool memory pool = poolInfo[_pid];
    IERC20 token = IERC20(pool.token);

    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Decubate : Set allowance first!"
    );

    bool success = token.transferFrom(msg.sender, address(this), _amount);
    require(success, "Decubate : Transfer failed");

    reinvest(_pid);

    _stake(_pid, msg.sender, _amount, false);

    return success;
  }

  function _stake(
    uint256 _pid,
    address _sender,
    uint256 _amount,
    bool _isReinvest
  ) internal {
    User storage user = users[_pid][_sender];
    Pool storage pool = poolInfo[_pid];

    if (!_isReinvest && _sender != compounderContract) {
      require(
        _amount >= pool.minContrib &&
          _amount.add(user.total_invested) <= pool.maxContrib,
        "Invalid amount!"
      );
      user.depositTime = block.timestamp;
    }

    require(pool.totalDeposit.add(_amount) <= pool.hardCap, "Pool is full");

    uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));

    require(block.timestamp <= stopDepo, "Staking is disabled for this pool");

    user.total_invested = user.total_invested.add(_amount);
    pool.totalDeposit = pool.totalDeposit.add(_amount);
    user.lastPayout = block.timestamp;

    emit Stake(_sender, _amount, block.timestamp);
  }

  /**
   *
   * @dev claim accumulated TOKEN reward for a single pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} status of claim
   */

  function claim(uint256 _pid) public override returns (bool) {
    require(canClaim(_pid, msg.sender), "Reward still in locked state");

    _claim(_pid, msg.sender);

    return true;
  }

  /**
   *
   * @dev Reinvest accumulated TOKEN reward for a single pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} status of reinvest
   */

  function reinvest(uint256 _pid) public override returns (bool) {
    uint256 amount = payout(_pid, msg.sender);
    if (amount > 0) {
      _stake(_pid, msg.sender, amount, true);
      emit Reinvest(msg.sender, amount, block.timestamp);
    }

    return true;
  }

  /**
   *
   * @dev Reinvest accumulated TOKEN reward for all pools
   *
   * @return {bool} status of reinvest
   */

  function reinvestAll() public override returns (bool) {
    uint256 len = poolInfo.length;
    for (uint256 pid = 0; pid < len; ++pid) {
      reinvest(pid);
    }

    return true;
  }

  /**
   *
   * @dev claim accumulated TOKEN reward from all pools
   *
   * Beware of gas fee!
   *
   */
  function claimAll() public override returns (bool) {
    uint256 len = poolInfo.length;

    for (uint256 pid = 0; pid < len; ++pid) {
      if (canClaim(pid, msg.sender)) {
        _claim(pid, msg.sender);
      }
    }

    return true;
  }

  /**
   *
   * @dev check whether user can claim or not
   *
   * @param {_pid}  id of the pool
   * @param {_addr} address of the user
   *
   * @return {bool} Status of claim
   *
   */

  function canClaim(uint256 _pid, address _addr)
    public
    view
    override
    returns (bool)
  {
    User storage user = users[_pid][_addr];
    Pool storage pool = poolInfo[_pid];

    if (msg.sender == compounderContract) {
      return true;
    }

    return (block.timestamp >=
      user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
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

  function calcMultiplier(uint256 _pid, address _addr)
    public
    view
    override
    returns (uint16 multi)
  {
    NFTMultiplier memory nft = poolInfo[_pid].nft;

    if (
      nft.active && ownsCorrectNFT(_addr, _pid) && _addr != compounderContract
    ) {
      multi = nft.multiplier;
    } else {
      multi = 10;
    }
  }

  function ownsCorrectNFT(address _addr, uint256 _pid)
    public
    view
    returns (bool)
  {
    NFTMultiplier memory nft = poolInfo[_pid].nft;

    uint256[] memory ids = nftContract.walletOfOwner(_addr);
    for (uint256 i = 0; i < ids.length; i++) {
      if (ids[i] >= nft.startIdx && ids[i] <= nft.endIdx) {
        return true;
      }
    }
    return false;
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
  function unStake(uint256 _pid, uint256 _amount)
    public
    override
    returns (bool)
  {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = poolInfo[_pid];

    require(user.total_invested >= _amount, "You don't have enough funds");

    require(canClaim(_pid, msg.sender), "Stake still in locked state");

    _claim(_pid, msg.sender);

    safeTOKENTransfer(pool.token, msg.sender, _amount);

    pool.totalDeposit = pool.totalDeposit.sub(_amount);
    user.total_invested = user.total_invested.sub(_amount);

    emit Unstake(msg.sender, _amount, block.timestamp);

    return true;
  }

  /**
   *
   * @dev Handle NFT boost of users from compounder
   *
   * @param {_pid} id of the pool
   * @param {_user} user eligible for NFT boost
   * @param {_rewardAmount} Amount of rewards generated
   *
   * @return {uint256} Status of stake
   *
   */
  function handleNFTMultiplier(
    uint256 _pid,
    address _user,
    uint256 _rewardAmount
  ) external override returns (uint256) {
    require(msg.sender == compounderContract, "Only for compounder");
    uint16 multi = calcMultiplier(_pid, _user);

    uint256 multipliedAmount = _rewardAmount.mul(multi).div(10).sub(
      _rewardAmount
    );

    if (multipliedAmount > 0) {
      safeTOKENTransfer(poolInfo[_pid].token, _user, multipliedAmount);
    }

    return multipliedAmount;
  }

  function _claim(uint256 _pid, address _addr) internal {
    User storage user = users[_pid][_addr];
    Pool memory pool = poolInfo[_pid];

    uint256 amount = payout(_pid, _addr);

    if (amount > 0) {
      user.total_withdrawn = user.total_withdrawn.add(amount);

      uint256 feeAmount = amount.mul(feePercent).div(1000);

      safeTOKENTransfer(pool.token, feeAddress, feeAmount);

      amount = amount.sub(feeAmount);

      safeTOKENTransfer(pool.token, _addr, amount);

      user.lastPayout = block.timestamp;

      user.totalClaimed = user.totalClaimed.add(amount);
    }

    emit Claim(_addr, amount, block.timestamp);
  }

  function payout(uint256 _pid, address _addr)
    public
    view
    override
    returns (uint256 value)
  {
    User storage user = users[_pid][_addr];
    Pool storage pool = poolInfo[_pid];

    uint256 from = user.lastPayout > user.depositTime
      ? user.lastPayout
      : user.depositTime;
    uint256 to = block.timestamp > pool.endDate
      ? pool.endDate
      : block.timestamp;

    uint256 multiplier = calcMultiplier(_pid, _addr);

    if (from < to) {
      uint256 rayValue = yearlyRateToRay((pool.apy * 10**18) / 1000);
      value = (accrueInterest(user.total_invested, rayValue, to.sub(from))).sub(
          user.total_invested
        );
    }

    value = value.mul(multiplier).div(10);

    return value;
  }

  /**
   *
   * @dev safe TOKEN transfer function, require to have enough TOKEN to transfer
   *
   */
  function safeTOKENTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) internal {
    IERC20 token = IERC20(_token);
    uint256 tokenBal = token.balanceOf(address(this));

    if (_amount > tokenBal) {
      token.transfer(_to, tokenBal);
    } else {
      token.transfer(_to, _amount);
    }
  }

  /**
   *
   * @dev update fee values
   *
   */
  function updateFeeValues(uint8 _feePercent, address _feeWallet)
    external
    onlyOwner
  {
    feePercent = _feePercent;
    feeAddress = _feeWallet;
  }

  /**
   *
   * @dev update compounder contract
   *
   */
  function updateCompounder(address _compounder) external override onlyOwner {
    compounderContract = _compounder;
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
  function transferToken(address _addr, uint256 _amount)
    external
    onlyOwner
    returns (bool)
  {
    IERC20 token = IERC20(_addr);
    bool success = token.transfer(address(owner()), _amount);
    return success;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
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
    function rpow(uint x, uint n) internal pure returns (uint z) {
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

    //// Fixed point scale factors
    // wei -> the base unit
    // wad -> wei * 10 ** 18. 1 ether = 1 wad, so 0.5 ether can be used
    //      to represent a decimal wad of 0.5
    // ray -> wei * 10 ** 27

    // Go from wad (10**18) to ray (10**27)
    function wadToRay(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 9);
    }

    // Go from wei to ray (10**27)
    function weiToRay(uint _wei) internal pure returns (uint) {
        return mul(_wei, 10 ** 27);
    } 


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
    *   Effective Rate Per Second = 0.05 / (365 days/yr * 86400 sec/day) = 1.5854895991882 * 10 ** -9
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
    function accrueInterest(uint _principal, uint _rate, uint _age) public pure returns (uint) {
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
    function yearlyRateToRay(uint _rateWad) public pure returns (uint) {
        return add(wadToRay(1 ether), rdiv(wadToRay(_rateWad), weiToRay(365*86400)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDecubateMasterChef {
  struct NFTMultiplier {
    bool active;
    uint16 multiplier;
    uint16 startIdx;
    uint16 endIdx;
  }

  /**
   *
   * @dev User reflects the info of each user
   *
   *
   * @param {total_invested} how many tokens the user staked
   * @param {total_withdrawn} how many tokens withdrawn so far
   * @param {lastPayout} time at which last claim was done
   * @param {depositTime} Time of last deposit
   * @param {totalClaimed} Total claimed by the user
   *
   */
  struct User {
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 lastPayout;
    uint256 depositTime;
    uint256 totalClaimed;
  }

  function poolInfo(uint256)
    external
    view
    returns (
      uint256 apy,
      NFTMultiplier memory nft,
      uint256 lockPeriodInDays,
      uint256 totalDeposit,
      uint256 startDate,
      uint256 endDate,
      uint256 minContrib,
      uint256 maxContrib,
      uint256 hardCap,
      address token
    );

  function users(uint256, address)
    external
    view
    returns (
      uint256 total_invested,
      uint256 total_withdrawn,
      uint256 lastPayout,
      uint256 depositTime,
      uint256 totalClaimed
    );

  function poolLength() external view returns (uint256);

  function add(
    uint256 _apy,
    uint16 _multiplier,
    uint16 startIdx,
    uint16 endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    uint256 _minContrib,
    uint256 _maxContrib,
    uint256 _hardCap,
    address token
  ) external;

  function set(
    uint256 _pid,
    uint256 _apy,
    uint16 _multiplier,
    uint16 startIdx,
    uint16 endIdx,
    uint256 _lockPeriodInDays,
    bool _isUsed,
    uint256 _endDate,
    uint256 _minContrib,
    uint256 _maxContrib,
    uint256 _hardCap,
    address token
  ) external;

  function stake(uint256 _pid, uint256 _amount) external returns (bool);

  function claim(uint256 _pid) external returns (bool);

  function reinvest(uint256 _pid) external returns (bool);

  function reinvestAll() external returns (bool);

  function claimAll() external returns (bool);

  function canClaim(uint256 _pid, address _addr) external view returns (bool);

  function calcMultiplier(uint256 _pid, address _addr)
    external
    view
    returns (uint16);

  function unStake(uint256 _pid, uint256 _amount) external returns (bool);

  function handleNFTMultiplier(uint256 _pid, address _user, uint256 _rewardAmount) external returns (uint256) ;

  function updateCompounder(address _compounder) external;

  function payout(uint256 _pid, address _addr)
    external
    view
    returns (uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
}