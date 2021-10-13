// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IMinerverseMinter.sol";
import "../interfaces/IMinerverseChef.sol";
import "../interfaces/IPriceCalculator.sol";
import "../library/SafeDecimal.sol";

import "../vaults/MinerversePool.sol";

contract DashboardBSC is OwnableUpgradeable {
    using SafeMath for uint;
    using SafeDecimal for uint;

    IPriceCalculator public constant priceCalculator = IPriceCalculator(0xA4FdD98CB3a31675892AA05Af206fc0070003882);

    address public constant WBNB = 0x2CdFAFCbf745F7720EAe97505c8C58CDF68EA197;
    address public constant MVX = 0x383a78C81159e451Bbb40c0B7750156fF1FecF0A;
    address public constant CAKE = 0xc3E0E5fea6f93caa60328a860bD5A18DaFB63e46;
    address public constant VaultCakeToCake = 0x467a4f3C9347b3A6e87bCb38C08EfEE3eBeDCf7f;

    IMinerverseChef private constant minerverseChef = IMinerverseChef(0x3d38d05fE41992C59bA7C519203427B45BFd3752);
    MinerversePool private constant minerversePool = MinerversePool(0x6C2DAcf637C5950245B9A25649f6FE483E541ea4);

    /* ========== STATE VARIABLES ========== */

    mapping(address => PoolConstant.PoolTypes) public poolTypes;
    mapping(address => uint) public pancakePoolIds;
    mapping(address => bool) public perfExemptions;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== Restricted Operation ========== */

    function setPoolType(address pool, PoolConstant.PoolTypes poolType) public onlyOwner {
        poolTypes[pool] = poolType;
    }

    function setPancakePoolId(address pool, uint pid) public onlyOwner {
        pancakePoolIds[pool] = pid;
    }

    function setPerfExemption(address pool, bool exemption) public onlyOwner {
        perfExemptions[pool] = exemption;
    }

    /* ========== View Functions ========== */

    function poolTypeOf(address pool) public view returns (PoolConstant.PoolTypes) {
        return poolTypes[pool];
    }

    /* ========== Utilization Calculation ========== */

    function utilizationOfPool(address pool) public view returns (uint liquidity, uint utilized) {
        return (0, 0);
    }

    /* ========== Profit Calculation ========== */

    function calculateProfit(address pool, address account) public view returns (uint profit, uint profitInBNB) {
        PoolConstant.PoolTypes poolType = poolTypes[pool];
        profit = 0;
        profitInBNB = 0;

        if (poolType == PoolConstant.PoolTypes.MinerverseStake_deprecated) {
            // profit as bnb
            (profit, ) = priceCalculator.valueOfAsset(
                address(minerversePool.rewardsToken()),
                minerversePool.earned(account)
            );
            profitInBNB = profit;
        } else if (poolType == PoolConstant.PoolTypes.Minerverse) {
            // profit as minerverse
            profit = minerverseChef.pendingMinerverse(pool, account);
            (profitInBNB, ) = priceCalculator.valueOfAsset(MVX, profit);
        } else if (
            poolType == PoolConstant.PoolTypes.CakeStake ||
            poolType == PoolConstant.PoolTypes.FlipToFlip ||
            poolType == PoolConstant.PoolTypes.Venus ||
            poolType == PoolConstant.PoolTypes.MinerverseToMinerverse
        ) {
            // profit as underlying
            IStrategy strategy = IStrategy(pool);
            profit = strategy.earned(account);
            (profitInBNB, ) = priceCalculator.valueOfAsset(strategy.stakingToken(), profit);
        } else if (poolType == PoolConstant.PoolTypes.FlipToCake || poolType == PoolConstant.PoolTypes.MinerverseBNB) {
            // profit as cake
            IStrategy strategy = IStrategy(pool);
            profit = strategy.earned(account).mul(IStrategy(strategy.rewardsToken()).priceShare()).div(1e18);
            (profitInBNB, ) = priceCalculator.valueOfAsset(CAKE, profit);
        }
    }

    function profitOfPool(address pool, address account) public view returns (uint profit, uint minerverse) {
        (uint profitCalculated, uint profitInBNB) = calculateProfit(pool, account);
        profit = profitCalculated;
        minerverse = 0;

        if (!perfExemptions[pool]) {
            IStrategy strategy = IStrategy(pool);
            if (strategy.minter() != address(0)) {
                profit = profit.mul(70).div(100);
                minerverse = IMinerverseMinter(strategy.minter()).amountMinerverseToMint(profitInBNB.mul(30).div(100));
            }

            if (strategy.minerverseChef() != address(0)) {
                minerverse = minerverse.add(minerverseChef.pendingMinerverse(pool, account));
            }
        }
    }

    /* ========== TVL Calculation ========== */

    function tvlOfPool(address pool) public view returns (uint tvl) {
        if (poolTypes[pool] == PoolConstant.PoolTypes.MinerverseStake_deprecated) {
            (, tvl) = priceCalculator.valueOfAsset(address(minerversePool.stakingToken()), minerversePool.balance());
        } else {
            IStrategy strategy = IStrategy(pool);
            (, tvl) = priceCalculator.valueOfAsset(strategy.stakingToken(), strategy.balance());

            if (strategy.rewardsToken() == VaultCakeToCake) {
                IStrategy rewardsToken = IStrategy(strategy.rewardsToken());
                uint rewardsInCake = rewardsToken.balanceOf(pool).mul(rewardsToken.priceShare()).div(1e18);
                (, uint rewardsInUSD) = priceCalculator.valueOfAsset(address(CAKE), rewardsInCake);
                tvl = tvl.add(rewardsInUSD);
            }
        }
    }

    /* ========== Pool Information ========== */

    function infoOfPool(address pool, address account) public view returns (PoolConstant.PoolInfo memory) {
        PoolConstant.PoolInfo memory poolInfo;

        IStrategy strategy = IStrategy(pool);
        (uint pBASE, uint pMVX) = profitOfPool(pool, account);
        (uint liquidity, uint utilized) = utilizationOfPool(pool);

        poolInfo.pool = pool;
        poolInfo.balance = strategy.balanceOf(account);
        poolInfo.principal = strategy.principalOf(account);
        poolInfo.available = strategy.withdrawableBalanceOf(account);
        poolInfo.tvl = tvlOfPool(pool);
        poolInfo.utilized = utilized;
        poolInfo.liquidity = liquidity;
        poolInfo.pBASE = pBASE;
        poolInfo.pMVX = pMVX;

        PoolConstant.PoolTypes poolType = poolTypeOf(pool);
        if (poolType != PoolConstant.PoolTypes.MinerverseStake_deprecated && strategy.minter() != address(0)) {
            IMinerverseMinter minter = IMinerverseMinter(strategy.minter());
            poolInfo.depositedAt = strategy.depositedAt(account);
            poolInfo.feeDuration = minter.WITHDRAWAL_FEE_FREE_PERIOD();
            poolInfo.feePercentage = minter.WITHDRAWAL_FEE();
        }

        poolInfo.portfolio = portfolioOfPoolInUSD(pool, account);
        return poolInfo;
    }

    function poolsOf(address account, address[] memory pools) public view returns (PoolConstant.PoolInfo[] memory) {
        PoolConstant.PoolInfo[] memory results = new PoolConstant.PoolInfo[](pools.length);
        for (uint i = 0; i < pools.length; i++) {
            results[i] = infoOfPool(pools[i], account);
        }
        return results;
    }

    /* ========== Portfolio Calculation ========== */

    function stakingTokenValueInUSD(address pool, address account) internal view returns (uint tokenInUSD) {
        PoolConstant.PoolTypes poolType = poolTypes[pool];

        address stakingToken;
        if (poolType == PoolConstant.PoolTypes.MinerverseStake_deprecated) {
            stakingToken = MVX;
        } else {
            stakingToken = IStrategy(pool).stakingToken();
        }

        if (stakingToken == address(0)) return 0;
        (, tokenInUSD) = priceCalculator.valueOfAsset(stakingToken, IStrategy(pool).principalOf(account));
    }

    function portfolioOfPoolInUSD(address pool, address account) internal view returns (uint) {
        uint tokenInUSD = stakingTokenValueInUSD(pool, account);
        (, uint profitInBNB) = calculateProfit(pool, account);
        uint profitInMVX = 0;

        if (!perfExemptions[pool]) {
            IStrategy strategy = IStrategy(pool);
            if (strategy.minter() != address(0)) {
                profitInBNB = profitInBNB.mul(70).div(100);
                profitInMVX = IMinerverseMinter(strategy.minter()).amountMinerverseToMint(profitInBNB.mul(30).div(100));
            }

            if (
                (poolTypes[pool] == PoolConstant.PoolTypes.Minerverse ||
                    poolTypes[pool] == PoolConstant.PoolTypes.MinerverseBNB ||
                    poolTypes[pool] == PoolConstant.PoolTypes.FlipToFlip) && strategy.minerverseChef() != address(0)
            ) {
                profitInMVX = profitInMVX.add(minerverseChef.pendingMinerverse(pool, account));
            }
        }

        (, uint profitBNBInUSD) = priceCalculator.valueOfAsset(WBNB, profitInBNB);
        (, uint profitMVXInUSD) = priceCalculator.valueOfAsset(MVX, profitInMVX);
        return tokenInUSD.add(profitBNBInUSD).add(profitMVXInUSD);
    }

    function portfolioOf(address account, address[] memory pools) public view returns (uint deposits) {
        deposits = 0;
        for (uint i = 0; i < pools.length; i++) {
            deposits = deposits.add(portfolioOfPoolInUSD(pools[i], account));
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./IStrategyCompact.sol";

interface IStrategy is IStrategyCompact {
    // rewardsToken
    function sharesOf(address account) external view returns (uint);

    function deposit(uint _amount) external;

    function withdraw(uint _amount) external;

    /* ========== Interface ========== */

    function depositAll() external;

    function withdrawAll() external;

    function getReward() external;

    function harvest() external;

    function pid() external view returns (uint);

    function totalSupply() external view returns (uint);

    function poolType() external view returns (PoolConstant.PoolTypes);

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint withdrawalFee);
    event ProfitPaid(address indexed user, uint profit, uint performanceFee);
    event MinerversePaid(address indexed user, uint profit, uint performanceFee);
    event Harvested(uint profit);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMinerverseMinter {
    function isMinter(address) external view returns (bool);

    function amountMinerverseToMint(uint bnbProfit) external view returns (uint);

    function amountMinerverseToMintForMinerverseBNB(uint amount, uint duration) external view returns (uint);

    function withdrawalFee(uint amount, uint depositedAt) external view returns (uint);

    function performanceFee(uint profit) external view returns (uint);

    function mintFor(
        address flip,
        uint _withdrawalFee,
        uint _performanceFee,
        address to,
        uint depositedAt
    ) external;

    function mintForMinerverseBNB(
        uint amount,
        uint duration,
        address to
    ) external;

    function minerversePerProfitBNB() external view returns (uint);

    function WITHDRAWAL_FEE_FREE_PERIOD() external view returns (uint);

    function WITHDRAWAL_FEE() external view returns (uint);

    function setMinter(address minter, bool canMint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IMinerverseChef {
    struct UserInfo {
        uint balance;
        uint pending;
        uint rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint allocPoint; // How many allocation points assigned to this pool. MVXs to distribute per block.
        uint lastRewardBlock; // Last block number that MVXs distribution occurs.
        uint accMinerversePerShare; // Accumulated MVXs per share, times 1e12. See below.
    }

    function minerversePerBlock() external view returns (uint);

    function totalAllocPoint() external view returns (uint);

    function vaultInfoOf(address vault) external view returns (VaultInfo memory);

    function vaultUserInfoOf(address vault, address user) external view returns (UserInfo memory);

    function pendingMinerverse(address vault, address user) external view returns (uint);

    function notifyDeposited(address user, uint amount) external;

    function notifyWithdrawn(address user, uint amount) external;

    function safeMinerverseTransfer(address user) external returns (uint);

    function updateRewardsOf(address vault) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function pricesInUSD(address[] memory assets) external view returns (uint[] memory);

    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);

    function priceOfMinerverse() external view returns (uint);

    function priceOfBNB() external view returns (uint);
}

// SPDX-License-Identifier: MIT

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SafeDecimal {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint public constant UNIT = 10**uint(decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function multiply(uint x, uint y) internal pure returns (uint) {
        return x.mul(y).div(UNIT);
    }

    // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/
    function power(uint x, uint n) internal pure returns (uint) {
        uint result = UNIT;
        while (n > 0) {
            if (n % 2 != 0) {
                result = multiply(result, x);
            }
            x = multiply(x, x);
            n /= 2;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/legacy/RewardsDistributionRecipient.sol";
import "../library/legacy/Pausable.sol";
import "../library/bep20/SafeBEP20.sol";
import "../interfaces/legacy/IStrategyHelper.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";

interface IPresale {
    function totalBalance() external view returns (uint);

    function flipToken() external view returns (address);
}

contract MinerversePool is IStrategyLegacy, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */

    IBEP20 public rewardsToken; // minerverse/bnb flip
    IBEP20 public constant stakingToken = IBEP20(0x34904d6Cd1484e649AcB462FFbA176118150E032); // minerverse
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 90 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => bool) private _stakePermission;

    /* ========== PRESALE ============== */
    address private constant presaleContract = 0x641414e2a04c8f8EbBf49eD47cc87dccbA42BF07;
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _presaleBalance;
    uint private constant timestamp2HoursAfterPresaleEnds = 1605585600 + (2 hours);
    uint private constant timestamp90DaysAfterPresaleEnds = 1605585600 + (90 days);

    /* ========== MVX HELPER ========= */

    IStrategyHelper public helper = IStrategyHelper(0xA84c09C1a2cF4918CaEf625682B429398b97A1a0);
    IPancakeRouter02 private constant ROUTER_V1_DEPRECATED = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        rewardsDistribution = msg.sender;

        _stakePermission[msg.sender] = true;
        _stakePermission[presaleContract] = true;

        stakingToken.safeApprove(address(ROUTER_V1_DEPRECATED), 2**256 - 1);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balance() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function presaleBalanceOf(address account) external view returns (uint256) {
        return _presaleBalance[account];
    }

    function principalOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale minerverse after 90 days of presale
            return _balances[account];
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            return _balances[account].sub(_presaleBalance[account]);
        } else {
            uint soldInPresale = IPresale(presaleContract).totalBalance().div(2).mul(3); // mint 150% of presale for making flip token
            uint minerverseSupply = stakingToken.totalSupply().sub(stakingToken.balanceOf(deadAddress));
            if (soldInPresale >= minerverseSupply) {
                return _balances[account].sub(_presaleBalance[account]);
            }
            uint minerverseNewMint = minerverseSupply.sub(soldInPresale);
            if (minerverseNewMint >= soldInPresale) {
                return _balances[account];
            }

            uint lockedRatio = (soldInPresale.sub(minerverseNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = _presaleBalance[account].mul(lockedRatio).div(1e18);
            return _balances[account].sub(lockedBalance);
        }
    }

    function profitOf(address account)
        public
        view
        override
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        )
    {
        _usd = 0;
        _minerverse = 0;
        _bnb = helper.tvlInBNB(address(rewardsToken), earned(account));
    }

    function tvl() public view override returns (uint) {
        uint price = helper.tokenPriceInBNB(address(stakingToken));
        return _totalSupply.mul(price).div(1e18);
    }

    function apy()
        public
        view
        override
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        )
    {
        uint tokenDecimals = 1e18;
        uint __totalSupply = _totalSupply;
        if (__totalSupply == 0) {
            __totalSupply = tokenDecimals;
        }

        uint rewardPerTokenPerSecond = rewardRate.mul(tokenDecimals).div(__totalSupply);
        uint minerversePrice = helper.tokenPriceInBNB(address(stakingToken));
        uint flipPrice = helper.tvlInBNB(address(rewardsToken), 1e18);

        _usd = 0;
        _minerverse = 0;
        _bnb = rewardPerTokenPerSecond.mul(365 days).mul(flipPrice).div(minerversePrice);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function _deposit(uint256 amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "amount");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(_to, amount);
    }

    function deposit(uint256 amount) public override {
        _deposit(amount, msg.sender);
    }

    function depositAll() external override {
        deposit(stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "amount");
        require(amount <= withdrawableBalanceOf(msg.sender), "locked");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() external override {
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            reward = _flipToWBNB(reward);
            IBEP20(ROUTER_V1_DEPRECATED.WETH()).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _flipToWBNB(uint amount) private returns (uint reward) {
        address wbnb = ROUTER_V1_DEPRECATED.WETH();
        (uint rewardMinerverse, ) = ROUTER_V1_DEPRECATED.removeLiquidity(
            address(stakingToken),
            wbnb,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = wbnb;
        ROUTER_V1_DEPRECATED.swapExactTokensForTokens(rewardMinerverse, 0, path, address(this), block.timestamp);

        reward = IBEP20(wbnb).balanceOf(address(this));
    }

    function harvest() external override {}

    function info(address account) external view override returns (UserInfo memory) {
        UserInfo memory userInfo;

        userInfo.balance = _balances[account];
        userInfo.principal = _balances[account];
        userInfo.available = withdrawableBalanceOf(account);

        Profit memory profit;
        (uint usd, uint minerverse, uint bnb) = profitOf(account);
        profit.usd = usd;
        profit.minerverse = minerverse;
        profit.bnb = bnb;
        userInfo.profit = profit;

        userInfo.poolTVL = tvl();

        APY memory poolAPY;
        (usd, minerverse, bnb) = apy();
        poolAPY.usd = usd;
        poolAPY.minerverse = minerverse;
        poolAPY.bnb = bnb;
        userInfo.poolAPY = poolAPY;

        return userInfo;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setRewardsToken(address _rewardsToken) external onlyOwner {
        require(address(rewardsToken) == address(0), "set rewards token already");

        rewardsToken = IBEP20(_rewardsToken);
        IBEP20(_rewardsToken).safeApprove(address(ROUTER_V1_DEPRECATED), 2**256 - 1);
    }

    function setHelper(IStrategyHelper _helper) external onlyOwner {
        require(address(_helper) != address(0), "zero address");
        helper = _helper;
    }

    function setStakePermission(address _address, bool permission) external onlyOwner {
        _stakePermission[_address] = permission;
    }

    function stakeTo(uint256 amount, address _to) external canStakeTo {
        _deposit(amount, _to);
        if (msg.sender == presaleContract) {
            _presaleBalance[_to] = _presaleBalance[_to].add(amount);
        }
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint _balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "reward");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken), "tokenAddress");
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier canStakeTo() {
        require(_stakePermission[msg.sender], "auth");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
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
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../library/PoolConstant.sol";
import "./IVaultController.sol";

interface IStrategyCompact is IVaultController {
    /* ========== Dashboard ========== */

    function balance() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function principalOf(address account) external view returns (uint);

    function withdrawableBalanceOf(address account) external view returns (uint);

    function earned(address account) external view returns (uint);

    function priceShare() external view returns (uint);

    function depositedAt(address account) external view returns (uint);

    function rewardsToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PoolConstant {
    enum PoolTypes {
        MinerverseStake_deprecated, // no perf fee
        MinerverseFlip_deprecated, // deprecated
        CakeStake,
        FlipToFlip,
        FlipToCake,
        Minerverse, // no perf fee
        MinerverseBNB,
        Venus,
        Collateral,
        MinerverseToMinerverse,
        FlipToReward,
        MinerverseV2,
        Qubit,
        bQBT,
        flipToQBT
    }

    struct PoolInfo {
        address pool;
        uint balance;
        uint principal;
        uint available;
        uint tvl;
        uint utilized;
        uint liquidity;
        uint pBASE;
        uint pMVX;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
        uint portfolio;
    }

    struct RelayInfo {
        address pool;
        uint balanceInUSD;
        uint debtInUSD;
        uint earnedInUSD;
    }

    struct RelayWithdrawn {
        address pool;
        address account;
        uint profitInETH;
        uint lossInETH;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVaultController {
    function minter() external view returns (address);

    function minerverseChef() external view returns (address);

    function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RewardsDistributionRecipient is Ownable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "onlyRewardsDistribution");
        _;
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

// SPDX-License-Identifier: MIT

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Pausable is Ownable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    constructor() internal {
        require(owner() != address(0), "Owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        emit PauseChanged(paused);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../IMinerverseMinter.sol";

interface IStrategyHelper {
    function tokenPriceInBNB(address _token) external view returns (uint);

    function cakePriceInBNB() external view returns (uint);

    function bnbPriceInUSD() external view returns (uint);

    function flipPriceInBNB(address _flip) external view returns (uint);

    function flipPriceInUSD(address _flip) external view returns (uint);

    function profitOf(
        IMinerverseMinter minter,
        address _flip,
        uint amount
    )
        external
        view
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        );

    function tvl(address _flip, uint amount) external view returns (uint); // in USD

    function tvlInBNB(address _flip, uint amount) external view returns (uint); // in BNB

    function apy(IMinerverseMinter minter, uint pid)
        external
        view
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        );

    function compoundingAPY(uint pid, uint compoundUnit) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

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
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IStrategyLegacy {
    struct Profit {
        uint usd;
        uint minerverse;
        uint bnb;
    }

    struct APY {
        uint usd;
        uint minerverse;
        uint bnb;
    }

    struct UserInfo {
        uint balance;
        uint principal;
        uint available;
        Profit profit;
        uint poolTVL;
        APY poolAPY;
    }

    function deposit(uint _amount) external;

    function depositAll() external;

    function withdraw(uint256 _amount) external; // MVX STAKING POOL ONLY

    function withdrawAll() external;

    function getReward() external; // MVX STAKING POOL ONLY

    function harvest() external;

    function balance() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function principalOf(address account) external view returns (uint);

    function withdrawableBalanceOf(address account) external view returns (uint); // MVX STAKING POOL ONLY

    function profitOf(address account)
        external
        view
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        );

    //    function earned(address account) external view returns (uint);
    function tvl() external view returns (uint); // in USD

    function apy()
        external
        view
        returns (
            uint _usd,
            uint _minerverse,
            uint _bnb
        );

    /* ========== Strategy Information ========== */
    //    function pid() external view returns (uint);
    //    function poolType() external view returns (PoolTypes);
    //    function isMinter() external view returns (bool, address);
    //    function getDepositedAt(address account) external view returns (uint);
    //    function getRewardsToken() external view returns (address);

    function info(address account) external view returns (UserInfo memory);
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

pragma solidity >=0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity >=0.8.4;

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