/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./FieldFacet/Dibbler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title Budget Facet
**/
contract BudgetFacet is Dibbler {

    using SafeMath for uint256;

    function budgetSow(uint256 amount) public returns (uint256) {
        require(isBudget(msg.sender), "Budget: sender must be budget.");
        bean().burnFrom(msg.sender, amount);

        decreaseSoil(amount);

        return _sowNoSoil(amount, msg.sender);
    }

    function isBudget(address account) public view returns (bool) {
        return s.isBudget[account];
    }

    function decreaseSoil(uint256 amount) private {
        uint256 soil = s.f.soil;
        if (soil > amount) s.f.soil = soil.sub(amount);
        else if (soil > 0) s.f.soil = 0;
    }
}

/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../../../C.sol";
import "../../../interfaces/IBean.sol";
import "../../../libraries/Decimal.sol";
import "../../../libraries/LibCheck.sol";

/**
 * @author Publius
 * @title Dibbler
**/
contract Dibbler {

    using SafeMath for uint256;
    using SafeMath for uint32;
    using Decimal for Decimal.D256;

    AppStorage internal s;
    uint32 private constant MAX_UINT32 = 2**32-1;

    event Sow(address indexed account, uint256 index, uint256 beans, uint256 pods);

    /**
     * Shed
    **/

    function _sow(uint256 amount, address account) internal returns (uint256) {
        require(amount > 0, "Field: Must purchase non-zero amount.");
        s.f.soil = s.f.soil.sub(amount, "Field: Not enough outstanding Soil.");
        uint256 pods = beansToPods(amount, s.w.yield);
        sowPlot(account, amount, pods);
        s.f.pods = s.f.pods.add(pods);
        saveSowTime();
        return pods;
    }

    function _sowNoSoil(uint256 amount, address account) internal returns (uint256) {
        require(amount > 0, "Field: Must purchase non-zero amount.");
        uint256 pods = beansToPods(amount, s.w.yield);
        sowPlot(account, amount, pods);
        s.f.pods = s.f.pods.add(pods);
        saveSowTime();
        return pods;
    }

    function sowPlot(address account, uint256 beans, uint256 pods) internal {
        s.a[account].field.plots[s.f.pods] = pods;
        emit Sow(account, s.f.pods, beans, pods);
    }

    function beansToPods(uint256 beanstalks, uint256 y) internal pure returns (uint256) {
        Decimal.D256 memory rate = Decimal.ratio(y, 100).add(Decimal.one());
        return Decimal.from(beanstalks).mul(rate).asUint256();
    }

    function bean() internal view returns (IBean) {
        return IBean(s.c.bean);
    }

    function saveSowTime() private {
        uint256 totalBeanSupply = bean().totalSupply();
        if (s.f.soil >= totalBeanSupply.div(C.getComplexWeatherDenominator())) return;

        uint256 sowTime = block.timestamp.sub(s.season.timestamp);
        s.w.nextSowTime = uint32(sowTime);
        uint96 soilPercent = uint96(s.f.soil.mul(1e18).div(totalBeanSupply));
        if (!s.w.didSowBelowMin) s.w.didSowBelowMin = true;

        if (
            soilPercent <= C.getUpperBoundPodRate().mul(s.w.lastSoilPercent).asUint256() &&
            !s.w.didSowFaster &&
            s.w.lastSowTime != MAX_UINT32 &&
            s.w.lastDSoil != 0
        ) {
            uint256 deltaSoil = s.w.startSoil.sub(s.f.soil);
            if (Decimal.ratio(deltaSoil, s.w.lastDSoil).greaterThan(C.getLowerBoundDPD())) {
                uint256 fasterTime =
                    s.w.lastSowTime > C.getSteadySowTime() ?
                    s.w.lastSowTime.sub(C.getSteadySowTime()) :
                    0;
                if (sowTime < fasterTime) s.w.didSowFaster = true;
                else s.w.lastSowTime = MAX_UINT32;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Beanstalk.
**/
library C {

    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Chain
    uint256 private constant CHAIN_ID = 1; // Mainnet

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour

    // Sun
    uint256 private constant HARVESET_PERCENTAGE = 5e17; // 50%

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 5e16; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 15e16; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 25e16; // 25%

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 95e16; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 105e16; // 105%

    uint256 private constant STEADY_SOW_TIME = 60; // 1 minute
    uint256 private constant RAIN_TIME = 24; // 24 seasons = 1 day

    // Governance
    uint32 private constant GOVERNANCE_PERIOD = 168; // 168 seasons = 7 days
    uint32 private constant GOVERNANCE_EMERGENCY_PERIOD = 86400; // 1 day
    uint256 private constant GOVERNANCE_PASS_THRESHOLD = 5e17; // 1/2
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR = 2; // 2/3
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR = 3; // 2/3
    uint32 private constant GOVERNANCE_EXPIRATION = 24; // 24 seasons = 1 day
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 1e15; // 0.1%
    uint256 private constant BASE_COMMIT_INCENTIVE = 1e8; // 100 beans
    uint256 private constant MAX_PROPOSITIONS = 5;

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 1e8; // 100 beans
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant SEEDS_PER_LP_BEAN = 4;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Field
    uint256 private constant MAX_SOIL_DENOMINATOR = 4; // 25%
    uint256 private constant COMPLEX_WEATHER_DENOMINATOR = 1000; // 0.1%


    /**
     * Getters
    **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getGovernancePeriod() internal pure returns (uint32) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceEmergencyPeriod() internal pure returns (uint32) {
        return GOVERNANCE_EMERGENCY_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernancePassThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PASS_THRESHOLD});
    }

    function getGovernanceEmergencyThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR,GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR);
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getCommitIncentive() internal pure returns (uint256) {
        return BASE_COMMIT_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getComplexWeatherDenominator() internal pure returns (uint256) {
        return COMPLEX_WEATHER_DENOMINATOR;
    }

    function getMaxSoilDenominator() internal pure returns (uint256) {
        return MAX_SOIL_DENOMINATOR;
    }

    function getHarvestPercentage() internal pure returns (uint256) {
        return HARVESET_PERCENTAGE;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE,1e18);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND,1e18);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND,1e18);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND,1e18);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND,1e18);
    }

    function getSteadySowTime() internal pure returns (uint256) {
        return STEADY_SOW_TIME;
    }

    function getRainTime() internal pure returns (uint256) {
        return RAIN_TIME;
    }

    function getMaxPropositions() internal pure returns (uint256) {
      return MAX_PROPOSITIONS;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getSeedsPerLPBean() internal pure returns (uint256) {
        return SEEDS_PER_LP_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
      return STALK_PER_BEAN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
      return STALK_PER_BEAN/SEEDS_PER_LP_BEAN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

}

/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title Bean Interface
**/
abstract contract IBean is IERC20 {

    function burn(uint256 amount) public virtual;
    function burnFrom(address account, uint256 amount) public virtual;
    function mint(address account, uint256 amount) public virtual returns (bool);

}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./LibAppStorage.sol";
import "../interfaces/IBean.sol";

/**
 * @author Publius
 * @title Check Library verifies Beanstalk's balances are correct.
**/
library LibCheck {

    using SafeMath for uint256;

    function beanBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            IBean(s.c.bean).balanceOf(address(this)) >=
                s.f.harvestable.sub(s.f.harvested).add(s.bean.deposited).add(s.bean.withdrawn),
            "Check: Bean balance fail."
        );
    }

    function lpBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            IUniswapV2Pair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited.add(s.lp.withdrawn),
            "Check: LP balance fail."
        );
    }

    function balanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            IBean(s.c.bean).balanceOf(address(this)) >=
                s.f.harvestable.sub(s.f.harvested).add(s.bean.deposited).add(s.bean.withdrawn),
            "Check: Bean balance fail."
        );
        require(
            IUniswapV2Pair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited.add(s.lp.withdrawn),
            "Check: LP balance fail."
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Beanstalk's state.
**/
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Beanstalk.
**/
contract Account {

    struct Field {
        mapping(uint256 => uint256) plots;
        mapping(address => uint256) podAllowances;
    }

    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
    }

    struct SeasonOfPlenty {
        uint256 base;
        uint256 roots;
        uint256 basePerRoot;
    }

    struct State {
        Field field;
        AssetSilo bean;
        AssetSilo lp;
        Silo s;
        uint32 lockedUntil;
        uint32 lastUpdate;
        uint32 lastSop;
        uint32 lastRain;
        uint32 lastSIs;
        SeasonOfPlenty sop;
        uint256 roots;
    }
}

contract Storage {
    struct Contracts {
        address bean;
        address pair;
        address pegPair;
        address weth;
    }

    // Field

    struct Field {
        uint256 soil;
        uint256 pods;
        uint256 harvested;
        uint256 harvestable;
    }

    // Governance

    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 endTotalRoots;
    }

    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    struct Governance {
        uint32[] activeBips;
        uint32 bipIndex;
        mapping(uint32 => DiamondCut) diamondCuts;
        mapping(uint32 => mapping(address => bool)) voted;
        mapping(uint32 => Bip) bips;
    }

    // Silo

    struct AssetSilo {
        uint256 deposited;
        uint256 withdrawn;
    }

    struct IncreaseSilo {
        uint256 beans;
        uint256 stalk;
    }

    struct V1IncreaseSilo {
        uint256 beans;
        uint256 stalk;
        uint256 roots;
    }

    struct SeasonOfPlenty {
        uint256 weth;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
    }

    // Season

    struct Oracle {
        bool initialized;
        uint256 cumulative;
        uint256 pegCumulative;
        uint32 timestamp;
        uint32 pegTimestamp;
    }

    struct Rain {
        uint32 start;
        bool raining;
        uint256 pods;
        uint256 roots;
    }

    struct Season {
        uint32 current;
        uint32 sis;
        uint256 start;
        uint256 period;
        uint256 timestamp;
    }

    struct Weather {
        uint256 startSoil;
        uint256 lastDSoil;
        uint96 lastSoilPercent;
        uint32 lastSowTime;
        uint32 nextSowTime;
        uint32 yield;
        bool didSowBelowMin;
        bool didSowFaster;
    }

    struct Fundraiser {
        address payee;
        address token;
        uint256 total;
        uint256 remaining;
    }
}

struct AppStorage {
    uint8 index;
    int8[32] cases;
    bool paused;
    uint128 pausedAt;
    Storage.Season season;
    Storage.Contracts c;
    Storage.Field f;
    Storage.Governance g;
    Storage.Oracle o;
    Storage.Rain r;
    Storage.Silo s;
    uint256 depreciated1;
    Storage.Weather w;
    Storage.AssetSilo bean;
    Storage.AssetSilo lp;
    Storage.IncreaseSilo si;
    Storage.SeasonOfPlenty sop;
    Storage.V1IncreaseSilo v1SI;
    uint256 unclaimedRoots;
    uint256 v2SIBeans;
    mapping (uint32 => uint256) sops;
    mapping (address => Account.State) a;
    uint32 bip0Start;
    uint32 hotFix3Start;
    mapping (uint32 => Storage.Fundraiser) fundraisers;
    uint32 fundraiserIndex;
    mapping (address => bool) isBudget;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}