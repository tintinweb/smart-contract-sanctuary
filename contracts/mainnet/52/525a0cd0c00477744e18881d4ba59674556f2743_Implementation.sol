/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/external/Decimal.sol

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


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

// File: contracts/Constants.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;



library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 84;

    /* Oracle */
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 VSD
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START = 1612324800;
    uint256 private constant CURRENT_EPOCH_PERIOD = 28800;

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 9; // 9 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 8; // 2 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 10e16; // 10%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 VSD
    uint256 private constant EXPANSION_ADVANCE_INCENTIVE = 3e20; // 300 VSD
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 15; // 15 epochs fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 30; // 10 days
    uint256 private constant DEBT_RATIO_CAP = 15e16; // 15%

    /* Regulator */
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
    uint256 private constant SUPPLY_INCREASE_FUND_RATIO = 1500; // 15%
    uint256 private constant SUPPLY_INCREASE_PRICE_THRESHOLD = 105e16; // 1.05
    uint256 private constant SUPPLY_INCREASE_PRICE_TARGET = 1045e15; // 1.045
    uint256 private constant SUPPLY_DECREASE_PRICE_THRESHOLD = 95e16; // 0.95
    uint256 private constant SUPPLY_DECREASE_PRICE_TARGET = 95e16; // 0.95

    /* Collateral */
    uint256 private constant REDEMPTION_RATE = 9500; // 95%
    uint256 private constant FUND_DEV_PCT = 70; // 70%
    uint256 private constant COLLATERAL_RATIO = 9000; // 90%

    /* Deployed */
    address private constant TREASURY_ADDRESS = address(0x3a640b96405eCB10782C130022e1E5a560EBcf11);
    address private constant DEV_ADDRESS = address(0x5bC47D40F69962d1a9Db65aC88f4b83537AF5Dc2);
    address private constant MINTER_ADDRESS = address(0x6Ff1DbcF2996D8960E24F16C193EA42853995d32);
    address private constant GOVERNOR = address(0xB64A5630283CCBe0C3cbF887a9f7B9154aEf38c3);

    /**
     * Getters
     */

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getDaiAddress() internal pure returns (address) {
        return DAI;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getCurrentEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: CURRENT_EPOCH_OFFSET,
            start: CURRENT_EPOCH_START,
            period: CURRENT_EPOCH_PERIOD
        });
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getExpansionAdvanceIncentive() internal pure returns (uint256) {
        return EXPANSION_ADVANCE_INCENTIVE;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyIncreaseFundRatio() internal pure returns (uint256) {
        return SUPPLY_INCREASE_FUND_RATIO;
    }

    function getSupplyIncreasePriceThreshold() internal pure returns (uint256) {
        return SUPPLY_INCREASE_PRICE_THRESHOLD;
    }

    function getSupplyIncreasePriceTarget() internal pure returns (uint256) {
        return SUPPLY_INCREASE_PRICE_TARGET;
    }

    function getSupplyDecreasePriceThreshold() internal pure returns (uint256) {
        return SUPPLY_DECREASE_PRICE_THRESHOLD;
    }

    function getSupplyDecreasePriceTarget() internal pure returns (uint256) {
        return SUPPLY_DECREASE_PRICE_TARGET;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getDevAddress() internal pure returns (address) {
        return DEV_ADDRESS;
    }

    function getMinterAddress() internal pure returns (address) {
        return MINTER_ADDRESS;
    }

    function getFundDevPct() internal pure returns (uint256) {
        return FUND_DEV_PCT;
    }

    function getRedemptionRate() internal pure returns (uint256) {
        return REDEMPTION_RATE;
    }

    function getGovernor() internal pure returns (address) {
        return GOVERNOR;
    }

    function getCollateralRatio() internal pure returns (uint256) {
        return COLLATERAL_RATIO;
    }
}

// File: contracts/dao/Curve.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;





contract Curve {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function calculateCouponPremium(
        uint256 totalSupply,
        uint256 totalDebt,
        uint256 amount
    ) internal pure returns (uint256) {
        return effectivePremium(totalSupply, totalDebt, amount).mul(amount).asUint256();
    }

    function effectivePremium(
        uint256 totalSupply,
        uint256 totalDebt,
        uint256 amount
    ) private pure returns (Decimal.D256 memory) {
        Decimal.D256 memory debtRatio = Decimal.ratio(totalDebt, totalSupply);
        Decimal.D256 memory debtRatioUpperBound = Constants.getDebtRatioCap();

        uint256 totalSupplyEnd = totalSupply.sub(amount);
        uint256 totalDebtEnd = totalDebt.sub(amount);
        Decimal.D256 memory debtRatioEnd = Decimal.ratio(totalDebtEnd, totalSupplyEnd);

        if (debtRatio.greaterThan(debtRatioUpperBound)) {
            if (debtRatioEnd.greaterThan(debtRatioUpperBound)) {
                return curve(debtRatioUpperBound);
            }

            Decimal.D256 memory premiumCurve = curveMean(debtRatioEnd, debtRatioUpperBound);
            Decimal.D256 memory premiumCurveDelta = debtRatioUpperBound.sub(debtRatioEnd);
            Decimal.D256 memory premiumFlat = curve(debtRatioUpperBound);
            Decimal.D256 memory premiumFlatDelta = debtRatio.sub(debtRatioUpperBound);
            return (premiumCurve.mul(premiumCurveDelta)).add(premiumFlat.mul(premiumFlatDelta))
                .div(premiumCurveDelta.add(premiumFlatDelta));
        }

        return curveMean(debtRatioEnd, debtRatio);
    }

    // 1/((1-R)^2)-1
    function curve(Decimal.D256 memory debtRatio) private pure returns (Decimal.D256 memory) {
        return Decimal.one().div(
            (Decimal.one().sub(debtRatio)).pow(2)
        ).sub(Decimal.one());
    }

    // 1/((1-R)(1-R'))-1
    function curveMean(
        Decimal.D256 memory lower,
        Decimal.D256 memory upper
    ) private pure returns (Decimal.D256 memory) {
        if (lower.equals(upper)) {
            return curve(lower);
        }

        return Decimal.one().div(
            (Decimal.one().sub(upper)).mul(Decimal.one().sub(lower))
        ).sub(Decimal.one());
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/token/IDollar.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;



contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}

// File: contracts/oracle/IOracle.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;



contract IOracle {
    function capture() public returns (Decimal.D256 memory, bool);
}

// File: contracts/dao/State.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;






contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 lockedUntil;

        mapping(uint256 => uint256) coupons;
        mapping(address => uint256) couponAllowances;
    }

    struct PoolState {
        uint256 staged;
        uint256 bonded;
        uint256 fluidUntil;
        uint256 rewardDebt;
        uint256 shareDebt;
    }
}

contract Epoch {
    struct Global {
        uint256 start;
        uint256 period;
        uint256 current;
    }

    struct Coupons {
        uint256 outstanding;
        uint256 couponRedeemed;
        uint256 vsdRedeemable;
    }

    struct State {
        uint256 totalDollarSupply;
        Coupons coupons;
    }
}

contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct VoteInfo {
        Vote vote;
        uint256 bondedVotes;
    }

    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => VoteInfo) votes;
        bool initialized;
    }
}

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
    }

    struct Balance {
        uint256 redeemable;
        uint256 clippable;
        uint256 debt;
        uint256 coupons;
    }

    struct PoolInfo {
        uint256 bonded;
        uint256 staged;
        mapping (address => Account.PoolState) accounts;
        uint256 accDollarPerLP; // Accumulated dollar per LP token, times 1e18.
        uint256 accSharePerLP; // Accumulated share per LP token, times 1e18.
        uint256 allocPoint;
        uint256 flags;
    }

    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;

        /*
         * Global state variable
         */
        uint256 totalAllocPoint;
        uint256 collateralRatio;

        mapping(uint256 => Epoch.State) epochs;
        mapping(uint256 => Candidate.State) candidates;
        mapping(address => Account.State) accounts;

        mapping(address => PoolInfo) pools;
        address[] poolList;

        address[] collateralAssetList;
    }
}

contract State {
    Storage.State _state;
}

// File: @uniswap/lib/contracts/libraries/Babylonian.sol

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: contracts/dao/Getters.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;






contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 (only for snapshot voting)
     */

    function name() public view returns (string memory) {
        return "Value Set Dollar Stake";
    }

    function symbol() public view returns (string memory) {
        return "VSDS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOfBondedDollar(account);
    }

    function totalSupply() public view returns (uint256) {
        return totalBondedDollar();
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function usdc() public view returns (address) {
        return Constants.getUsdcAddress();
    }

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function totalBonded(address pool) public view returns (uint256) {
        return _state.pools[pool].bonded;
    }

    function totalStaged(address pool) public view returns (uint256) {
        return _state.pools[pool].staged;
    }

    function totalDebt() public view returns (uint256) {
        return _state.balance.debt;
    }

    function totalRedeemable() public view returns (uint256) {
        return _state.balance.redeemable;
    }

    function totalClippable() public view returns (uint256) {
        return _state.balance.clippable;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().sub(totalDebt());
    }

    function totalBondedDollar() public view returns (uint256) {
        uint256 len = _state.poolList.length;
        uint256 bondedDollar = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            uint256 bondedLP = totalBonded(pool);
            if (bondedLP == 0) {
                continue;
            }

            (uint256 poolBonded, ) = _getDollarReserve(pool, bondedLP);

            bondedDollar = bondedDollar.add(poolBonded);
        }
        return bondedDollar;
    }

    /**
     * Account
     */

    function balanceOfStaged(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].staged;
    }

    function balanceOfBonded(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].bonded;
    }

    function balanceOfBondedDollar(address account) public view returns (uint256) {
        uint256 len = _state.poolList.length;
        uint256 bondedDollar = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            uint256 bondedLP = balanceOfBonded(pool, account);
            if (bondedLP == 0) {
                continue;
            }

            (uint256 reserve, ) = _getDollarReserve(pool, bondedLP);

            bondedDollar = bondedDollar.add(reserve);
        }
        return bondedDollar;
    }

    function balanceOfCoupons(address account, uint256 epoch) public view returns (uint256) {
        if (outstandingCoupons(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch];
    }

    function balanceOfClippable(address account, uint256 epoch) public view returns (uint256) {
        if (redeemableVSDs(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch].mul(redeemableVSDs(epoch)).div(redeemedCoupons(epoch));
    }

    function statusOf(address pool, address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.pools[pool].accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
    }

    function allowanceCoupons(address owner, address spender) public view returns (uint256) {
        return _state.accounts[owner].couponAllowances[spender];
    }

    function pendingReward(address pool) public view returns (uint256 pending) {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];

        if (user.bonded > 0) {
            pending = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18).sub(user.rewardDebt);
        }
    }

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        Constants.EpochStrategy memory current = Constants.getCurrentEpochStrategy();

        return epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy) private view returns (uint256) {
        return blockTimestamp()
            .sub(strategy.start)
            .div(strategy.period)
            .add(strategy.offset);
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function outstandingCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.outstanding;
    }

    function redeemedCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.couponRedeemed;
    }

    function redeemableVSDs(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.vsdRedeemable;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= Constants.getBootstrappingPeriod();
    }

    function totalDollarSupplyAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].totalDollarSupply;
    }

    /**
     * Governance
     */

    function recordedVoteInfo(address account, uint256 candidate) public view returns (Candidate.VoteInfo memory) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(uint256 candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(uint256 candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(uint256 candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * Collateral
     */

    function _getDollarReserve(address pool, uint256 bonded) internal view returns (uint256 reserve, uint256 totalReserve) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pool).getReserves();
        if (IUniswapV2Pair(pool).token0() == address(dollar())) {
            totalReserve = reserve0;
        } else {
            require(IUniswapV2Pair(pool).token1() == address(dollar()), "the pool does not contain dollar");
            totalReserve = reserve1;
        }

        if (bonded == 0) {
            return (0, totalReserve);
        }

        reserve = totalReserve.mul(bonded).div(IUniswapV2Pair(pool).totalSupply());
    }

    function _getSellAndReturnAmount(
        uint256 price,
        uint256 targetPrice,
        uint256 reserve
    ) internal pure returns (uint256 sellAmount, uint256 returnAmount) {
        // price in resolution 1e18
        sellAmount = 0;
        returnAmount = 0;

        uint256 rootPoT = Babylonian.sqrt(price.mul(1e36).div(targetPrice));
        if (rootPoT > 1e18) { // res error
            sellAmount = (rootPoT - 1e18).mul(reserve).div(1e18);
        }

        uint256 rootPT = Babylonian.sqrt(price.mul(targetPrice));
        if (price > rootPT) { // res error
            returnAmount = (price - rootPT).mul(reserve).div(1e18);
        }
        if (sellAmount > returnAmount) { // res error
            sellAmount = returnAmount;
        }
    }

    function _getBuyAmount(uint256 price, uint256 targetPrice, uint256 reserve) internal pure returns (uint256 shouldBuy) {
        shouldBuy = 0;

        uint256 root = Babylonian.sqrt(price.mul(1e36).div(targetPrice));
        if (root < 1e18) { // res error
            shouldBuy = (1e18 - root).mul(reserve).div(1e18);
        }
    }

    function getCollateralRatio() internal view returns (uint256) {
        return _state.collateralRatio;
    }
}

// File: contracts/external/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

// File: contracts/dao/Setters.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;







contract Setters is State, Getters {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claim(address indexed pool, address indexed account, uint256 value);

    /**
     * Global
     */

    function incrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.add(amount);
    }

    function decrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.sub(amount);
    }

    function incrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.add(amount);
    }

    function decrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.sub(amount);
    }

    function decrementTotalClippable(uint256 amount) internal {
        _state.balance.clippable = _state.balance.clippable.sub(amount);
    }

    function incrementTotalClippable(uint256 amount) internal {
        _state.balance.clippable = _state.balance.clippable.add(amount);
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].bonded = _state.pools[pool].accounts[account].bonded.add(amount);
        _state.pools[pool].bonded = _state.pools[pool].bonded.add(amount);
    }

    function decrementBalanceOfBonded(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].bonded = _state.pools[pool].accounts[account].bonded.sub(amount);
        _state.pools[pool].bonded = _state.pools[pool].bonded.sub(amount);
    }

    function incrementBalanceOfStaged(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].staged = _state.pools[pool].accounts[account].staged.add(amount);
        _state.pools[pool].staged = _state.pools[pool].staged.add(amount);
    }

    function decrementBalanceOfStaged(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].staged = _state.pools[pool].accounts[account].staged.sub(amount);
        _state.pools[pool].staged = _state.pools[pool].staged.sub(amount);
    }

    function incrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].add(amount);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.add(amount);
        _state.balance.coupons = _state.balance.coupons.add(amount);
    }

    function decrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].sub(amount);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.sub(amount);
        _state.balance.coupons = _state.balance.coupons.sub(amount);
    }

    function clipRedeemedCoupon(address account, uint256 epoch) internal returns (uint256 vsdRedeemable) {
        uint256 couponRedeemed = _state.accounts[account].coupons[epoch];
        _state.accounts[account].coupons[epoch] = 0;
        // require(_state.epochs[epoch].coupons.outstanding == 0);
        vsdRedeemable = _state.epochs[epoch].coupons.vsdRedeemable.mul(couponRedeemed).div(_state.epochs[epoch].coupons.couponRedeemed);
    }

    function unfreeze(address pool, address account) internal {
        _state.pools[pool].accounts[account].fluidUntil = epoch().add(Constants.getDAOExitLockupEpochs());
    }

    function updateAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] = amount;
    }

    function decrementAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] =
            _state.accounts[owner].couponAllowances[spender].sub(amount);
    }

    /**
     * Epoch
     */

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
    }

    function snapshotDollarTotalSupply() internal {
        _state.epochs[epoch()].totalDollarSupply = dollar().totalSupply();
    }

    function redeemOutstandingCoupons(uint256 epoch) internal returns (uint256 couponRedeemed, uint256 vsdRedeemable) {
        uint256 outstandingCouponsForEpoch = outstandingCoupons(epoch);
        if(outstandingCouponsForEpoch == 0) {
            return (0, 0);
        }
        _state.balance.coupons = _state.balance.coupons.sub(outstandingCouponsForEpoch);

        uint256 totalRedeemable = totalRedeemable();
        vsdRedeemable = outstandingCouponsForEpoch;
        couponRedeemed = outstandingCouponsForEpoch;
        if (totalRedeemable < vsdRedeemable) {
            // Partial redemption
            vsdRedeemable = totalRedeemable;
        }

        _state.epochs[epoch].coupons.couponRedeemed = outstandingCouponsForEpoch;
        _state.epochs[epoch].coupons.vsdRedeemable = vsdRedeemable;
        _state.epochs[epoch].coupons.outstanding = 0;
    }

    /**
     * Governance
     */

    function createCandidate(uint256 candidate, uint256 period) internal {
        _state.candidates[candidate].start = epoch();
        _state.candidates[candidate].period = period;
    }

    function recordVoteInfo(address account, uint256 candidate, Candidate.VoteInfo memory voteInfo) internal {
        _state.candidates[candidate].votes[account] = voteInfo;
    }

    function incrementApproveFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.add(amount);
    }

    function decrementApproveFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.sub(amount);
    }

    function incrementRejectFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.add(amount);
    }

    function decrementRejectFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.sub(amount);
    }

    function placeLock(address account, uint256 candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate).add(periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(uint256 candidate) internal {
        _state.candidates[candidate].initialized = true;
    }

    /**
     * Pool
     */

    function _addPool(address pool) internal {
        uint256 len = _state.poolList.length;
        for (uint256 i = 0; i < len; i++) {
            require(pool != _state.poolList[i], "Must not be added");
        }

        _state.pools[pool].flags = 0x1; // enable flag
        _state.poolList.push(pool);
    }

    function preClaimDollar(address pool) internal {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];
        require((poolInfo.flags & 0x1) == 0x1, "pool is disabled");

        if (user.bonded > 0) {
            uint256 pending = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                // Safe transfer to avoid resolution error.
                uint256 balance = dollar().balanceOf(address(this));
                if (pending > balance) {
                    pending = balance;
                }
                dollar().transfer(msg.sender, pending);

                emit Claim(msg.sender, pool, pending);
            }
        }
    }

    function postClaimDollar(address pool) internal {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];

        user.rewardDebt = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18);
    }

    function _addLiquidity(address pool, address token, address anotherToken, uint256 amount) internal returns (uint256) {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        require(token == token0 || token == token1, "token must in pool");
        require(anotherToken == token0 || anotherToken == token1, "atoken must in pool");

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        (uint256 reserveToken, uint256 reserveAnother) = token == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 anotherAmount = UniswapV2Library.quote(amount, reserveToken, reserveAnother); // throw if reserve is zero

        IERC20(token).safeTransferFrom(msg.sender, pool, amount);
        IERC20(anotherToken).safeTransferFrom(msg.sender, pool, anotherAmount);
        return IUniswapV2Pair(pool).mint(address(this));
    }

    function _sellAndDepositCollateral(uint256 totalSellAmount, uint256 allReserve) internal {
        if (totalSellAmount == 0 || allReserve == 0) {
            return;
        }

        dollar().mint(address(this), totalSellAmount);
        uint256 len = _state.poolList.length;
        uint256 actualSold = 0;
        // Sell to pools according to their reserves
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            address token0 = IUniswapV2Pair(pool).token0();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pool).getReserves();

            uint256 reserveA = token0 == address(dollar()) ? reserve0 : reserve1;
            uint256 reserveB = token0 == address(dollar()) ? reserve1 : reserve0;

            uint256 sellAmount = totalSellAmount
                .mul(reserveA)
                .div(allReserve);
            actualSold = actualSold.add(sellAmount);

            if (reserveA == 0 || sellAmount == 0) {
                // The pool is not ready yet or insufficient lp in pool.
                continue;
            }

            uint256 assetAmount = UniswapV2Library.getAmountOut(
                sellAmount,
                reserveA,
                reserveB
            );

            dollar().transfer(pool, sellAmount);

            // Non-Reentrancy?
            IUniswapV2Pair(pool).swap(
                token0 == address(dollar()) ? 0 : assetAmount,
                token0 == address(dollar()) ? assetAmount : 0,
                address(this),
                new bytes(0)
            );
        }

        // Make sure we don't sell extra
        assert(actualSold <= totalSellAmount);
    }

    /**
     * Collateral
     */

    function _addCollateral(address asset) internal {
        uint256 len = _state.collateralAssetList.length;
        for (uint256 i = 0; i < len; i++) {
            require(asset != _state.collateralAssetList[i], "Must not be added");
        }

        _state.collateralAssetList.push(asset);
    }
}

// File: contracts/external/Require.sol

/*
    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.7;

/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

// File: contracts/dao/Comptroller.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;





contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        increaseDebt(amount);

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        burnFromAccountForDebt(account, amount, amount);
    }

    function burnFromAccountForDebt(address account, uint256 amount, uint256 debtAmount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(debtAmount);

        balanceCheck();
    }
    
    function clipToAccount(address account, uint256 amount) internal {
        dollar().transfer(account, amount);
        decrementTotalClippable(amount);

        balanceCheck();
    }

    function redeemToClippable(uint256 amount) internal {
        decrementTotalRedeemable(amount);
        incrementTotalClippable(amount);

        balanceCheck();
    }

    function setDebt(uint256 amount) internal returns (uint256) {
        _state.balance.debt = amount;
        uint256 lessDebt = resetDebt(Constants.getDebtRatioCap());

        balanceCheck();

        return lessDebt > amount ? 0 : amount.sub(lessDebt);
    }

    function increaseDebt(uint256 amount) internal returns (uint256) {
        incrementTotalDebt(amount);
        uint256 lessDebt = resetDebt(Constants.getDebtRatioCap());

        balanceCheck();

        return lessDebt > amount ? 0 : amount.sub(lessDebt);
    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount);

        balanceCheck();
    }

    function _updateReserve() internal returns (uint256 allReserve) {
        uint256 totalAllocPoint = 0;
        uint256 len = _state.poolList.length;
        allReserve = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            Storage.PoolInfo storage poolInfo = _state.pools[pool];

            uint256 poolReserve;
            (poolInfo.allocPoint, poolReserve) = _getDollarReserve(pool, _state.pools[pool].bonded);
            totalAllocPoint = totalAllocPoint.add(poolInfo.allocPoint);
            allReserve = allReserve.add(poolReserve);
        }
        _state.totalAllocPoint = totalAllocPoint;
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256, uint256) {
        // 0. Pay out to Fund
        uint256 rewards = newSupply.mul(getSupplyIncreaseFundRatio()).div(10000);
        uint256 devReward = rewards.mul(Constants.getFundDevPct()).div(100);
        uint256 treasuryReward = rewards.sub(devReward);
        if (devReward != 0) {
            dollar().mint(Constants.getDevAddress(), devReward);
        }
        if (treasuryReward != 0) {
            dollar().mint(Constants.getTreasuryAddress(), treasuryReward);
        }

        newSupply = newSupply > rewards ? newSupply.sub(rewards) : 0;

        // 1. True up redeemable pool
        uint256 newRedeemable = 0;
        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable < totalCoupons) {
            newRedeemable = totalCoupons.sub(totalRedeemable);
            newRedeemable = newRedeemable > newSupply ? newSupply : newRedeemable;
            mintToRedeemable(newRedeemable);
            newSupply = newSupply.sub(newRedeemable);
        }

        // 2. Payout to LPs
        if (!mintToLPs(newSupply)) {
            newSupply = 0;
        }

        balanceCheck();

        return (newRedeemable, newSupply.add(rewards), newSupply);
    }

    function resetDebt(Decimal.D256 memory targetDebtRatio) internal returns (uint256) {
        uint256 targetDebt = targetDebtRatio.mul(dollar().totalSupply()).asUint256();
        uint256 currentDebt = totalDebt();

        if (currentDebt > targetDebt) {
            uint256 lessDebt = currentDebt.sub(targetDebt);
            decreaseDebt(lessDebt);

            return lessDebt;
        }

        return 0;
    }

    function balanceCheck() private {
        // Require.that(
        //     dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()).add(totalClippable()),
        //     FILE,
        //     "Inconsistent balances"
        // );
    }

    function mintToLPs(uint256 amount) private returns (bool) {
        if (amount == 0) {
            return false;
        }

        if (_state.totalAllocPoint == 0) {
            return false;
        }

        dollar().mint(address(this), amount);
        uint256 len = _state.poolList.length;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            Storage.PoolInfo storage poolInfo = _state.pools[pool];

            if (poolInfo.bonded == 0) {
                continue;
            }
            uint256 poolAmount = amount.mul(poolInfo.allocPoint).div(_state.totalAllocPoint);
            poolInfo.accDollarPerLP = poolInfo.accDollarPerLP.add(poolAmount.mul(1e18).div(poolInfo.bonded));
        }

        return true;
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);

        balanceCheck();
    }

    /* for testing purpose */
    function getSupplyIncreaseFundRatio() internal view returns (uint256) {
        return Constants.getSupplyIncreaseFundRatio();
    }
}

// File: contracts/dao/Market.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;






contract Market is Comptroller, Curve {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Market";

    event CouponRedemption(uint256 indexed epoch, uint256 couponRedeemed, uint256 vsdRedeemable);
    event CouponPurchase(address indexed account, uint256 indexed epochExpire, uint256 dollarAmount, uint256 couponAmount);
    event CouponClip(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponTransfer(address indexed from, address indexed to, uint256 indexed epoch, uint256 value);
    event CouponApproval(address indexed owner, address indexed spender, uint256 value);
    event CouponExtended(address indexed owner, uint256 indexed epoch, uint256 couponAmount, uint256 newCouponAmount, uint256 newExpiration);

    function step() internal {
        // Automatically redeem prior coupons
        redeemCouponsForEpoch(epoch());
    }

    function redeemCouponsForEpoch(uint256 epoch) private {
        (uint256 couponRedeemed, uint256 vsdRedeemable) = redeemOutstandingCoupons(epoch);

        redeemToClippable(vsdRedeemable);

        emit CouponRedemption(epoch, couponRedeemed, vsdRedeemable);
    }

    function couponPremium(uint256 amount) public view returns (uint256) {
        return calculateCouponPremium(dollar().totalSupply(), totalDebt(), amount);
    }

    function purchaseCoupons(uint256 dollarAmount) external returns (uint256) {
        Require.that(
            dollarAmount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        Require.that(
            totalDebt() >= dollarAmount,
            FILE,
            "Not enough debt"
        );

        uint256 epoch = epoch();
        uint256 couponAmount = dollarAmount.add(couponPremium(dollarAmount));
        burnFromAccount(msg.sender, dollarAmount);
        incrementBalanceOfCoupons(msg.sender, epoch.add(Constants.getCouponExpiration()), couponAmount);

        emit CouponPurchase(msg.sender, epoch.add(Constants.getCouponExpiration()), dollarAmount, couponAmount);

        return couponAmount;
    }

    /*
     * @dev Extend the expiration of a coupon by VSDs.
     */
    function extendCoupon(uint256 couponExpireEpoch, uint256 couponAmount, uint256 dollarAmount) external {
        Require.that(
            dollarAmount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        uint256 epoch = epoch();

        decrementBalanceOfCoupons(msg.sender, couponExpireEpoch, couponAmount);
        uint256 liveness = couponAmount.mul(couponExpireEpoch.sub(epoch));

        uint256 debtAmount = totalDebt();
        if (debtAmount > dollarAmount) {
            debtAmount = dollarAmount;
        }
        burnFromAccountForDebt(msg.sender, dollarAmount, debtAmount);

        liveness = liveness.add(dollarAmount.mul(Constants.getCouponExpiration()));

        uint256 newExpiration = liveness.div(couponAmount).add(epoch);
        Require.that(
            newExpiration > epoch,
            FILE,
            "Must new exp. > current epoch"
        );

        incrementBalanceOfCoupons(msg.sender, newExpiration, couponAmount);
        emit CouponExtended(msg.sender, couponExpireEpoch, couponAmount, couponAmount, newExpiration);
    }

    function clipCoupons(uint256 couponExpireEpoch) external {
        Require.that(
            outstandingCoupons(couponExpireEpoch) == 0,
            FILE,
            "Coupon is not redeemed"
        );
        uint256 vsdAmount = clipRedeemedCoupon(msg.sender, couponExpireEpoch);
        clipToAccount(msg.sender, vsdAmount);

        emit CouponClip(msg.sender, couponExpireEpoch, vsdAmount);
    }

    function approveCoupons(address spender, uint256 amount) external {
        Require.that(
            spender != address(0),
            FILE,
            "Coupon approve to 0x0"
        );

        updateAllowanceCoupons(msg.sender, spender, amount);

        emit CouponApproval(msg.sender, spender, amount);
    }

    function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external {
        Require.that(
            sender != address(0),
            FILE,
            "Coupon transfer from 0x0"
        );
        Require.that(
            recipient != address(0),
            FILE,
            "Coupon transfer to 0x0"
        );

        decrementBalanceOfCoupons(sender, epoch, amount);
        incrementBalanceOfCoupons(recipient, epoch, amount);

        if (msg.sender != sender && allowanceCoupons(sender, msg.sender) != uint256(-1)) {
            decrementAllowanceCoupons(sender, msg.sender, amount);
        }

        emit CouponTransfer(sender, recipient, epoch, amount);
    }
}

// File: contracts/dao/Regulator.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;







contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event Incentivization(address indexed account, uint256 amount);
    event SupplyIncrease(uint256 indexed epoch, uint256 price, uint256 newSell, uint256 newRedeemable, uint256 lessDebt, uint256 newSupply, uint256 newReward);
    event SupplyDecrease(uint256 indexed epoch, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();

        uint256 allReserve = _updateReserve();

        if (price.greaterThan(Decimal.D256({value: getSupplyIncreasePriceThreshold()}))) {
            incentivize(msg.sender, Constants.getExpansionAdvanceIncentive());
            growSupply(price, allReserve);
            return;
        }

        incentivize(msg.sender, Constants.getAdvanceIncentive());

        if (price.lessThan(Decimal.D256({value: getSupplyDecreasePriceThreshold()}))) {
            shrinkSupply(price, allReserve);
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function incentivize(address account, uint256 amount) private {
        mintToAccount(account, amount);
        emit Incentivization(account, amount);
    }


    function shrinkSupply(Decimal.D256 memory price, uint256 allReserve) private {
        uint256 newDebt = _getBuyAmount(price.value, getSupplyDecreasePriceTarget(), allReserve);
        uint256 cappedNewDebt = setDebt(newDebt);

        emit SupplyDecrease(epoch(), price.value, cappedNewDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price, uint256 allReserve) private {
        uint256 lessDebt = resetDebt(Decimal.zero());

        (uint256 sellAmount, uint256 returnAmount) = _getSellAndReturnAmount(
            price.value,
            getSupplyIncreasePriceTarget(),
            allReserve
        );
        _sellAndDepositCollateral(sellAmount, allReserve);
        uint256 mintAmount = returnAmount.mul(10000).div(getCollateralRatio());
        (uint256 newRedeemable, uint256 newSupply, uint256 newReward) = increaseSupply(mintAmount.sub(sellAmount));
        emit SupplyIncrease(epoch(), price.value, sellAmount, newRedeemable, lessDebt, newSupply, newReward);
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    /* for testing purpose */
    function getSupplyIncreasePriceThreshold() internal view returns (uint256) {
        return Constants.getSupplyIncreasePriceThreshold();
    }

    function getSupplyIncreasePriceTarget() internal view returns (uint256) {
        return Constants.getSupplyIncreasePriceTarget();
    }

    function getSupplyDecreasePriceThreshold() internal view returns (uint256) {
        return Constants.getSupplyDecreasePriceThreshold();
    }

    function getSupplyDecreasePriceTarget() internal view returns (uint256) {
        return Constants.getSupplyDecreasePriceTarget();
    }
}

// File: contracts/dao/Permission.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;




contract Permission is Setters {

    bytes32 private constant FILE = "Permission";

    // Can modify account state
    modifier onlyFrozenOrFluid(address pool, address account) {
        Require.that(
            statusOf(pool, account) != Account.Status.Locked,
            FILE,
            "Not frozen or fluid"
        );

        _;
    }

    // Can participate in balance-dependant activities
    modifier onlyFrozen(address pool, address account) {
        Require.that(
            statusOf(pool, account) == Account.Status.Frozen,
            FILE,
            "Not frozen"
        );

        _;
    }

    modifier initializer() {
        Require.that(
            !isInitialized(uint256(implementation())),
            FILE,
            "Already initialized"
        );

        initialized(uint256(implementation()));

        _;
    }
}

// File: contracts/dao/Bonding.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;







contract Bonding is Setters, Permission {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Bonding";

    event Deposit(address indexed pool, address indexed account, uint256 value);
    event Withdraw(address indexed pool, address indexed account, uint256 value);
    event Bond(address indexed pool, address indexed account, uint256 start, uint256 value);
    event Unbond(address indexed pool, address indexed account, uint256 start, uint256 value);

    function step() internal {
        Require.that(
            epochTime() > epoch(),
            FILE,
            "Still current epoch"
        );

        snapshotDollarTotalSupply();
        incrementEpoch();
    }

    function addPool(address pool) external {
        Require.that(
            msg.sender == address(this),
            FILE,
            "Must from governance"
        );

        _addPool(pool);
    }

    function claim(address pool) external {
        preClaimDollar(pool);
        postClaimDollar(pool);
    }

    function deposit(address pool, uint256 value) external {
        IERC20(pool).transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(pool, msg.sender, value);

        emit Deposit(pool, msg.sender, value);
    }

    function withdraw(address pool, uint256 value) external onlyFrozen(pool, msg.sender) {
        IERC20(pool).transfer(msg.sender, value);
        decrementBalanceOfStaged(pool, msg.sender, value);

        emit Withdraw(pool, msg.sender, value);
    }

    function bond(address pool, uint256 value) external {
        preClaimDollar(pool);
        unfreeze(pool, msg.sender);

        incrementBalanceOfBonded(pool, msg.sender, value);
        decrementBalanceOfStaged(pool, msg.sender, value);

        emit Bond(pool, msg.sender, epoch().add(1), value);
        postClaimDollar(pool);
    }

    function unbond(address pool, uint256 value) external onlyFrozenOrFluid(pool, msg.sender) {
        preClaimDollar(pool);
        unfreeze(pool, msg.sender);

        incrementBalanceOfStaged(pool, msg.sender, value);
        decrementBalanceOfBonded(pool, msg.sender, value);

        emit Unbond(pool, msg.sender, epoch().add(1), value);
        postClaimDollar(pool);
    }

    function provide(address pool, address token, address another, uint256 amount) external {
        preClaimDollar(pool);

        unfreeze(pool, msg.sender);

        uint256 bondedLP = _addLiquidity(pool, token, another, amount);
        incrementBalanceOfBonded(pool, msg.sender, bondedLP);

        emit Bond(pool, msg.sender, epoch().add(1), bondedLP);
        postClaimDollar(pool);
    }
}

// File: @openzeppelin/upgrades/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/dao/Upgradeable.sol

/*
    Copyright 2018-2019 zOS Global Limited
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;




/**
 * Based off of, and designed to interface with, openzeppelin/upgrades package
 */
contract Upgradeable is State {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    function initialize() public;

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) internal {
        setImplementation(newImplementation);

        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, string(reason));

        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function setImplementation(address newImplementation) private {
        require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: contracts/dao/Govern.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;









contract Govern is Setters, Permission, Upgradeable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Govern";

    event Proposal(uint256 indexed candidate, address indexed account, uint256 indexed start, uint256 period);
    event Vote(address indexed account, uint256 indexed candidate, Candidate.Vote vote, uint256 bondedVotes);
    event Commit(address indexed account, uint256 indexed candidate, bool upgrade);

    /*
     * We allow voting as long as the token is bonded.
     */
    function vote(uint256 candidate, Candidate.Vote vote) external {
        Require.that(
            msg.sender == tx.origin,
            FILE,
            "Must be a user tx"
        );

        if (!isNominated(candidate)) {
            Require.that(
                canPropose(msg.sender),
                FILE,
                "Not enough stake to propose"
            );

            createCandidate(candidate, Constants.getGovernancePeriod());
            emit Proposal(candidate, msg.sender, epoch(), Constants.getGovernancePeriod());
        }

        Require.that(
            epoch() < startFor(candidate).add(periodFor(candidate)),
            FILE,
            "Ended"
        );

        uint256 bondedVotes = balanceOfBondedDollar(msg.sender);
        Candidate.VoteInfo memory recordedVoteInfo = recordedVoteInfo(msg.sender, candidate);
        Candidate.VoteInfo memory newVoteInfo = Candidate.VoteInfo({vote: vote, bondedVotes: bondedVotes});

        if (newVoteInfo.vote == recordedVoteInfo.vote && newVoteInfo.bondedVotes == recordedVoteInfo.bondedVotes) {
            return;
        }

        if (recordedVoteInfo.vote == Candidate.Vote.REJECT) {
            decrementRejectFor(candidate, recordedVoteInfo.bondedVotes);
        }
        if (recordedVoteInfo.vote == Candidate.Vote.APPROVE) {
            decrementApproveFor(candidate, recordedVoteInfo.bondedVotes);
        }
        if (vote == Candidate.Vote.REJECT) {
            incrementRejectFor(candidate, newVoteInfo.bondedVotes);
        }
        if (vote == Candidate.Vote.APPROVE) {
            incrementApproveFor(candidate, newVoteInfo.bondedVotes);
        }

        recordVoteInfo(msg.sender, candidate, newVoteInfo);
        placeLock(msg.sender, candidate);

        emit Vote(msg.sender, candidate, vote, bondedVotes);
    }

    function commit(uint256 candidate) external {
        Require.that(
            isNominated(candidate),
            FILE,
            "Not nominated"
        );

        uint256 endsAfter = startFor(candidate).add(periodFor(candidate)).sub(1);

        Require.that(
            epoch() > endsAfter,
            FILE,
            "Not ended"
        );

        Require.that(
            epoch() <= endsAfter.add(1).add(Constants.getGovernanceExpiration()),
            FILE,
            "Expired"
        );

        Require.that(
            Decimal.ratio(votesFor(candidate), dollar().totalSupply()).greaterThan(Constants.getGovernanceQuorum()),
            FILE,
            "Must have quorom"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        Require.that(
            msg.sender == getGovernor(),
            FILE,
            "Must from governor"
        );

        upgradeTo(address(candidate));

        emit Commit(msg.sender, candidate, true);
    }

    function emergencyCommit(uint256 candidate) external {
        Require.that(
            isNominated(candidate),
            FILE,
            "Not nominated"
        );

        Require.that(
            Decimal.ratio(approveFor(candidate), dollar().totalSupply()).greaterThan(Constants.getGovernanceSuperMajority()),
            FILE,
            "Must have super majority"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        Require.that(
            msg.sender == getGovernor(),
            FILE,
            "Must from governor"
        );

        upgradeTo(address(candidate));

        emit Commit(msg.sender, candidate, true);
    }

    function canPropose(address account) private view returns (bool) {
        Decimal.D256 memory stake = Decimal.ratio(
            balanceOfBondedDollar(account),
            dollar().totalSupply()
        );
        return stake.greaterThan(Constants.getGovernanceProposalThreshold());
    }

    function getGovernor() internal view returns (address) {
        return Constants.getGovernor();
    }
}

// File: contracts/dao/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

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

// File: contracts/dao/Collateral.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;







contract Collateral is Comptroller, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 private constant FILE = "Collateral";

    function redeem(uint256 value) external nonReentrant {
        uint256 actual = value;
        uint256 debt = totalDebt();
        if (debt > value) {
            // if there is debt, redeem at no cost
            debt = value;
        } else {
            // redeem with cost
            actual = value.sub((10000 - Constants.getRedemptionRate()).mul(value.sub(debt)).div(10000));
            uint256 fundReward = value.sub(actual);
            uint256 devReward = fundReward.mul(Constants.getFundDevPct()).div(100);
            uint256 treasuryReward = fundReward.sub(devReward);
            dollar().transferFrom(msg.sender, Constants.getDevAddress(), devReward);
            dollar().transferFrom(msg.sender, Constants.getTreasuryAddress(), treasuryReward);
        }

        uint256 len = _state.collateralAssetList.length;
        uint256 dollarTotalSupply = dollar().totalSupply();
        for (uint256 i = 0; i < len; i++) {
            address addr = _state.collateralAssetList[i];
            IERC20(addr).safeTransfer(
                msg.sender,
                actual.mul(IERC20(addr).balanceOf(address(this))).div(dollarTotalSupply)
            );
        }

        burnFromAccountForDebt(msg.sender, actual, debt);
    }

    function addCollateral(address asset) external {
        Require.that(
            msg.sender == address(this),
            FILE,
            "Must from governance"
        );

        _addCollateral(asset);
    }

    function _getMinterAddress() internal view returns (address) {
        return Constants.getMinterAddress();
    }
}

// File: contracts/dao/Implementation.sol

/*
    Copyright 2020 Empty Set Squad <[email protected]>
    Copyright 2021 vsdcrew <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;









contract Implementation is State, Bonding, Market, Regulator, Govern, Collateral {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);

    function initialize() initializer public {
        /*
        uint256 len = _state.poolList.length;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            Storage.PoolInfo storage poolInfo = _state.pools[pool];
            poolInfo.flags = 0x1;
        }
        */
    }

    function advance() nonReentrant external {
        require (msg.sender == tx.origin, "Must from user");

        Bonding.step();
        Regulator.step();
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

}