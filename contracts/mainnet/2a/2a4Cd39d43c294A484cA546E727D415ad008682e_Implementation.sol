/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


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

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Dynamic Dollar Devs, based on the works of the Empty Set Squad

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
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant TARGET_SUPPLY = 25e24; // 25M DAIQ
    uint256 private constant BOOTSTRAPPING_PRICE = 154e16; // 1.54 DAI (targeting 4.5% inflation)

    /* Oracle */
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 DAI

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 DAIQ -> 100M DAIQS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 minPeriod;
        uint256 maxPeriod;
    }

    uint256 private constant EPOCH_OFFSET = 86400; //1 day
    uint256 private constant EPOCH_MIN_PERIOD = 1800; //30 minutes
    uint256 private constant EPOCH_MAX_PERIOD = 7200; //2 hours

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 13;
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 3; // 3 epochs

    /* DAO */
    uint256 private constant DAI_ADVANCE_INCENTIVE_CAP = 150e18; //150 DAI
    uint256 private constant ADVANCE_INCENTIVE = 100e18; // 100 DAIQ
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 24; // 24 epochs fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 12; // 12 epochs fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 360;
    uint256 private constant DEBT_RATIO_CAP = 40e16; // 40%
    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 50e16; // 50%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 12e18; // 12
    uint256 private constant SUPPLY_CHANGE_LIMIT = 10e16; // 10%
    uint256 private constant ORACLE_POOL_RATIO = 30; // 30%

    /**
     * Getters
     */
    function getDAIAddress() internal pure returns (address) {
        return DAI;
    }

    function getPairAddress() internal pure returns (address) {
        return address(0x26B4B107dCe673C00D59D71152136327cF6dFEBf);
    }

    function getMultisigAddress() internal pure returns (address) {
        return address(0x7c066d74dd5ff4E0f3CB881eD197d49C96cA1771);
    }

    function getMarketingMultisigAddress() internal pure returns (address) {
        return address(0x0BCbDfd1ab7c2cBb6a8612f3300f214a779cb520);
    }

    function getLotteryAddress() internal pure returns (address) {
        return address(0x8Ee5b95C5676224bDb70115996F8674024355590);
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: EPOCH_OFFSET,
            minPeriod: EPOCH_MIN_PERIOD,
            maxPeriod: EPOCH_MAX_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingTarget() internal pure returns (Decimal.D256 memory) {
        return Decimal.from(TARGET_SUPPLY);
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
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

    function getDaiAdvanceIncentiveCap() internal pure returns (uint256) {
        return DAI_ADVANCE_INCENTIVE_CAP;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    
    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return 5; //5% to treasury
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Curve {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function calculateCouponPremium(
        uint256 totalSupply,
        uint256 totalDebt,
        uint256 amount,
        Decimal.D256 memory price,
        uint256 expirationPeriod
    ) internal pure returns (uint256) {
        return couponPremium(totalSupply, totalDebt, price, expirationPeriod).mul(amount).asUint256();
    }

    function couponPremium(
        uint256 totalSupply,
        uint256 totalDebt,
        Decimal.D256 memory price,
        uint256 expirationPeriod
    ) private pure returns (Decimal.D256 memory) {
        Decimal.D256 memory debtRatioUpperBound = Constants.getDebtRatioCap();

        Decimal.D256 memory debtRatio = Decimal.ratio(totalDebt, totalSupply);

        debtRatio = debtRatio.greaterThan(debtRatioUpperBound)
            ? debtRatioUpperBound
            : debtRatio;

        if (expirationPeriod > 1000)
            return lowRiskPremium(debtRatio, price, expirationPeriod);
        
        if (expirationPeriod > 100)
            return mediumRiskPremium(debtRatio, price, expirationPeriod);

        return highRiskPremium(debtRatio, price, expirationPeriod);
    }

    //R * (1 - P) *  2.2 / (1 + (T - 1) * 0.0001)
    function lowRiskPremium(Decimal.D256 memory debtRatio, Decimal.D256 memory price, uint256 expirationPeriod) private pure returns (Decimal.D256 memory) {
        return multiplier(debtRatio, price).mul(
            Decimal.D256({ value: 2.2e18 }).div(
                Decimal.one().add(Decimal.D256({ value: 1e14 }).mul(expirationPeriod - 1))
            )
        );
    }

    //R * (1 - P) * 6 /(1 + (T - 1) * 0.002)
    function mediumRiskPremium(Decimal.D256 memory debtRatio, Decimal.D256 memory price, uint256 expirationPeriod) private pure returns (Decimal.D256 memory) {
        return multiplier(debtRatio, price).mul(
            Decimal.D256({ value: 6e18 }).div(
                Decimal.one().add(Decimal.D256({ value: 2e15 }).mul(expirationPeriod - 1))
            )
        );
    }

    //R * (1 - P) * 10 /(1 + (T - 1) * 0.01)
    function highRiskPremium(Decimal.D256 memory debtRatio, Decimal.D256 memory price, uint256 expirationPeriod) private pure returns (Decimal.D256 memory) {
        return multiplier(debtRatio, price).mul(
            Decimal.D256({ value: 10e18 }).div(
                Decimal.one().add(Decimal.D256({ value: 1e16 }).mul(expirationPeriod - 1))
            )
        );
    }

    //R * (1 - P)
    function multiplier(Decimal.D256 memory debtRatio, Decimal.D256 memory price) private pure returns (Decimal.D256 memory) {
        return debtRatio.mul(Decimal.one().sub(price));
    }
}

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

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract IOracle {
    function setup() public;
    function capture() public returns (Decimal.D256 memory, bool);
    function pair() external view returns (address);
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 balance;
        mapping(uint256 => uint256) coupons;
        mapping(address => uint256) couponAllowances; //unused since DAIQIP-3
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}

contract Bootstrapping {
    struct State {
        uint256 contributions;
    }
}

contract Epoch {
    struct Global {
        uint256 current;
        uint256 currentStart;
        uint256 currentPeriod;
        uint256 bootstrapping;
        uint256 daiAdvanceIncentive;
        bool shouldDistributeDAI;
    }

    struct Coupons {
        uint256 outstanding; //unused since DAIQIP-3
        uint256 expiration; //unused since DAIQIP-3
        uint256[] expiring; //unused since DAIQIP-3
    }

    struct State {
        uint256 bonded;
        Coupons coupons; //unused since DAIQIP-3
    }
}

contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => Vote) votes;
        bool initialized;
    }
}

contract Era {
    enum Status {
        EXPANSION,
        NEUTRAL,
        DEBT
    }

    struct State {
        Status status;
        uint256 start;
    }

}

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
        address pool;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 redeemable;
        uint256 debt;
        uint256 coupons;
    }

    struct State {
        Epoch.Global epoch;
        Bootstrapping.State bootstrapping;
        Balance balance;
        Provider provider;

        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(address => Candidate.State) candidates;
    }

    struct State3 {
        mapping(address => mapping(uint256 => uint256)) couponExpirationsByAccount;
        mapping(uint256 => uint256) expiringCouponsByEpoch;
    }

    struct State6 {
        //storing twap for every epoch, in case we want to do something fancy in the future (e.g. calculating volatility)
        mapping(uint256 => Decimal.D256) twapPerEpoch;
    }

    struct State8 {
        Era.State era;
    }
}

contract State {
    Storage.State _state;

    //DAIQIP-3
    Storage.State3 _state3;
    
    //DAIQIP-6
    Storage.State6 _state6;

    //DAIQIP-8
    Storage.State8 _state8;
}

interface ILottery {
    function newGame(uint256[] calldata prizes) external;
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "DAIQ Stake";
    }

    function symbol() public view returns (string memory) {
        return "DAIQS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _state.accounts[account].balance;
    }

    function totalSupply() public view returns (uint256) {
        return _state.balance.supply;
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

    function pool() public view returns (address) {
        return _state.provider.pool;
    }

    function lottery() public view returns (ILottery) {
        return ILottery(Constants.getLotteryAddress());
    }

    function dai() public view returns (IERC20) {
        return IERC20(Constants.getDAIAddress());
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalDebt() public view returns (uint256) {
        return _state.balance.debt;
    }

    function totalRedeemable() public view returns (uint256) {
        return _state.balance.redeemable;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().sub(totalDebt());
    }

    function treasury() public view returns (address) {
        return Constants.getMultisigAddress();
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        return totalBonded().mul(balanceOf(account)).div(totalSupply);
    }

    function balanceOfCoupons(address account, uint256 _epoch) public view returns (uint256) {
        uint256 expiration = couponExpirationForAccount(account, _epoch);
        
        if (expiration > 0 && epoch() >= expiration) {
            return 0;
        }

        return _state.accounts[account].coupons[_epoch];
    }

    function couponExpirationForAccount(address account, uint256 epoch) public view returns (uint256) {
        return _state3.couponExpirationsByAccount[account][epoch];
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function allowanceCoupons(address owner, address spender) public view returns (uint256) {
        return _state.accounts[owner].couponAllowances[spender];
    }

    /**
    * Epoch
    */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        return block.timestamp >= nextEpochStart()
            ? epoch().add(1)
            : epoch();
    }

    function timeInEpoch() public view returns (uint256) {
        return block.timestamp.sub(_state.epoch.currentStart);
    }

    function timeLeftInEpoch() public view returns (uint256) {
        if (block.timestamp > nextEpochStart()) 
            return 0;

        return nextEpochStart().sub(block.timestamp);
    }

    function currentEpochDuration() public view returns (uint256) {
        return _state.epoch.currentPeriod;
    }

    function nextEpochStart() public view returns (uint256) {
        return _state.epoch.currentStart.add(_state.epoch.currentPeriod);
    }

    function twapAtEpoch(uint256 epoch) public view returns (uint256) {
        return _state6.twapPerEpoch[epoch].value;
    }

    function currentEpochStart() public view returns (uint256) {
        return _state.epoch.currentStart;
    }

    function expiringCoupons(uint256 epoch) public view returns (uint256) {
        return _state3.expiringCouponsByEpoch[epoch];
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    function bootstrappingPeriod() public view returns (uint256) {
        return 0;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= bootstrappingPeriod();
    }

    function daiAdvanceIncentive() public view returns (uint256) {
        return _state.epoch.daiAdvanceIncentive;
    }

    function shouldDistributeDAI() public view returns (bool) {
        return _state.epoch.shouldDistributeDAI;
    }

    function era() public view returns (Era.Status, uint256) {
        return (_state8.era.status, _state8.era.start);
    }

    /**
    * FixedSwap
    */

    function totalContributions() public view returns (uint256) {
        return _state.bootstrapping.contributions;
    }

    /**
     * Governance
     */

    function recordedVote(address account, address candidate) public view returns (Candidate.Vote) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(address candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(address candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(address candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Setters is State, Getters {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * ERC20 Interface
     */

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    /**
     * Global
     */

    function incrementTotalBonded(uint256 amount) internal {
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementTotalBonded(uint256 amount, string memory reason) internal {
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.add(amount);
    }

    function decrementTotalDebt(uint256 amount, string memory reason) internal {
        _state.balance.debt = _state.balance.debt.sub(amount, reason);
    }

    function setDebtToZero() internal {
        _state.balance.debt = 0;
    }

    function incrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.add(amount);
    }

    function decrementTotalRedeemable(uint256 amount, string memory reason) internal {
        _state.balance.redeemable = _state.balance.redeemable.sub(amount, reason);
    }

    function setEra(Era.Status era, uint256 start) internal {
        _state8.era.status = era;
        _state8.era.start = start;
    }

    /**
     * Account
     */

    function incrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.add(amount);
        _state.balance.supply = _state.balance.supply.add(amount);

        emit Transfer(address(0), account, amount);
    }

    function decrementBalanceOf(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.sub(amount, reason);
        _state.balance.supply = _state.balance.supply.sub(amount, reason);

        emit Transfer(account, address(0), amount);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount, uint256 expiration) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].add(amount); //Adds coupons to user's balance
        _state.balance.coupons = _state.balance.coupons.add(amount); //increments total outstanding coupons
        _state3.couponExpirationsByAccount[account][epoch] = expiration; //sets the expiration epoch for the user's coupons
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].add(amount); //Increments the number of expiring coupons in epoch
    }

    function decrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount, string memory reason) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].sub(amount, reason);
        uint256 expiration = _state3.couponExpirationsByAccount[account][epoch];
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].sub(amount, reason);
        _state.balance.coupons = _state.balance.coupons.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getDAOExitLockupEpochs());
    }

    function updateAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] = amount;
    }

    function decrementAllowanceCoupons(address owner, address spender, uint256 amount, string memory reason) internal {
        _state.accounts[owner].couponAllowances[spender] =
            _state.accounts[owner].couponAllowances[spender].sub(amount, reason);
    }

    /**
     * Epoch
     */

    function setDAIAdvanceIncentive(uint256 value) internal {
        _state.epoch.daiAdvanceIncentive = value;
    }

    function shouldDistributeDAI(bool should) internal {
        _state.epoch.shouldDistributeDAI = should;
    }

    function setBootstrappingPeriod(uint256 epochs) internal {
        _state.epoch.bootstrapping = epochs;
    }

    function initializeEpochs() internal {
        _state.epoch.currentStart = block.timestamp;
        _state.epoch.currentPeriod = Constants.getEpochStrategy().offset;
    }

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
        _state.epoch.currentStart = _state.epoch.currentStart.add(_state.epoch.currentPeriod);
    }
    
    function storePrice(uint256 epoch, Decimal.D256 memory price) internal {
        _state6.twapPerEpoch[epoch] = price;
    }

    function adjustPeriod(Decimal.D256 memory price) internal {
        Decimal.D256 memory normalizedPrice;
        if (price.greaterThan(Decimal.one())) 
            normalizedPrice = Decimal.one().div(price);
        else
            normalizedPrice = price;
        
        Constants.EpochStrategy memory epochStrategy = Constants.getEpochStrategy();
        
        _state.epoch.currentPeriod = normalizedPrice
            .mul(epochStrategy.maxPeriod.sub(epochStrategy.minPeriod))
            .add(epochStrategy.minPeriod)
            .asUint256();
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = totalSupply();
    }

    function expireCoupons(uint256 epoch) internal {
        _state.balance.coupons = _state.balance.coupons.sub( _state3.expiringCouponsByEpoch[epoch]);
        _state3.expiringCouponsByEpoch[epoch] = 0;
    }

    /**
    * FixedSwap
    */

    function incrementContributions(uint256 amount) internal {
        _state.bootstrapping.contributions = _state.bootstrapping.contributions.add(amount);
    }

    function decrementContributions(uint256 amount) internal {
        _state.bootstrapping.contributions = _state.bootstrapping.contributions.sub(amount);
    }

    /**
     * Governance
     */

    function createCandidate(address candidate, uint256 period) internal {
        _state.candidates[candidate].start = epoch();
        _state.candidates[candidate].period = period;
    }

    function recordVote(address account, address candidate, Candidate.Vote vote) internal {
        _state.candidates[candidate].votes[account] = vote;
    }

    function incrementApproveFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.add(amount);
    }

    function decrementApproveFor(address candidate, uint256 amount, string memory reason) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.sub(amount, reason);
    }

    function incrementRejectFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.add(amount);
    }

    function decrementRejectFor(address candidate, uint256 amount, string memory reason) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.sub(amount, reason);
    }

    function placeLock(address account, address candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate).add(periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(address candidate) internal {
        _state.candidates[candidate].initialized = true;
    }
}

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

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);

        if (!bootstrappingAt(epoch())) 
            increaseDebt(amount);

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(amount, "Comptroller: not enough outstanding debt");

        balanceCheck();
    }

    function redeemToAccount(address account, uint256 amount) internal {
        dollar().transfer(account, amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function burnRedeemable(uint256 amount) internal {
        dollar().burn(amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function increaseDebt(uint256 amount) internal {
        incrementTotalDebt(amount);
        resetDebt(Constants.getDebtRatioCap());

        balanceCheck();
    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount, "Comptroller: not enough debt");

        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256, uint256, uint256) {
        (uint256 newRedeemable, uint256 lessDebt, uint256 poolReward, uint256 treasuryReward) = (0, 0, 0, 0);

        // 1. True up redeemable pool
        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable < totalCoupons) {

            // Get new redeemable coupons
            newRedeemable = totalCoupons.sub(totalRedeemable);
            // Pad with Pool's and Treasury's potential cut
            newRedeemable = newRedeemable.mul(100).div(SafeMath.sub(100, SafeMath.add(Constants.getOraclePoolRatio(), Constants.getTreasuryRatio())));
            // Cap at newSupply
            newRedeemable = newRedeemable > newSupply ? newSupply : newRedeemable;
            // Determine Pool's final cut
            poolReward = newRedeemable.mul(Constants.getOraclePoolRatio()).div(100);
            // Determine Treasury's final cut
            treasuryReward = newRedeemable.mul(Constants.getTreasuryRatio()).div(100);
            // Determine Redeemable's final cut
            newRedeemable = newRedeemable.sub(poolReward).sub(treasuryReward);
            
            mintToPool(poolReward);
            mintToTreasury(treasuryReward);
            mintToRedeemable(newRedeemable);

            newSupply = newSupply.sub(poolReward);
            newSupply = newSupply.sub(treasuryReward);
            newSupply = newSupply.sub(newRedeemable);
        }

        // 2. Eliminate debt
        uint256 totalDebt = totalDebt();
        if (newSupply > 0 && totalDebt > 0) {
            lessDebt = totalDebt > newSupply ? newSupply : totalDebt;
            decreaseDebt(lessDebt);

            newSupply = newSupply.sub(lessDebt);
        }

        // 3. Payout to bonded
        if (totalBonded() == 0) {
            newSupply = 0;
        }
        if (newSupply > 0) {
            treasuryReward = treasuryReward.add(mintToBonded(newSupply));
            newSupply = newSupply.sub(treasuryReward);
        }

        return (newRedeemable, lessDebt, newSupply + poolReward, treasuryReward);
    }

    function resetDebt(Decimal.D256 memory targetDebtRatio) internal {
        uint256 targetDebt = targetDebtRatio.mul(dollar().totalSupply()).asUint256();
        uint256 currentDebt = totalDebt();

        if (currentDebt > targetDebt) {
            uint256 lessDebt = currentDebt.sub(targetDebt);
            decreaseDebt(lessDebt);
        }
    }

    function balanceCheck() private {
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()),
            FILE,
            "Inconsistent balances"
        );
    }

    function mintToBonded(uint256 amount) private returns (uint256) {
        Require.that(
            totalBonded() > 0,
            FILE,
            "Cant mint to empty pool"
        );

        uint256 poolAmount = amount.mul(Constants.getOraclePoolRatio()).div(100);
        uint256 treasuryAmount = amount.mul(Constants.getTreasuryRatio()).div(100);
        uint256 daoAmount = amount > poolAmount.add(treasuryAmount) ? amount.sub(poolAmount).sub(treasuryAmount) : 0;

        mintToPool(poolAmount);
        mintToTreasury(treasuryAmount);
        mintToDAO(daoAmount);

        balanceCheck();

        return treasuryAmount;
    }

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToPool(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(pool(), amount);
        }
    }

    function mintToTreasury(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(treasury(), amount);
        }
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);

        balanceCheck();
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Market is Comptroller, Curve {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Market";

    event CouponExpiration(uint256 indexed epoch, uint256 couponsExpired, uint256 lessRedeemable, uint256 lessDebt, uint256 newBonded, uint256 newTreasury);
    event CouponPurchase(address indexed account, uint256 indexed epoch, uint256 dollarAmount, uint256 couponAmount);
    event CouponRedemption(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponBurn(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponTransfer(address indexed from, address indexed to, uint256 indexed epoch, uint256 value);
    event CouponApproval(address indexed owner, address indexed spender, uint256 value);

    function step() internal {
        expireCouponsForEpoch(epoch());
    }

    function expireCouponsForEpoch(uint256 epoch) private {
        uint256 expiredAmount = expiringCoupons(epoch);
        (uint256 lessRedeemable, uint256 lessDebt, uint256 newBonded, uint256 newTreasury) = (0, 0, 0, 0);

        expireCoupons(epoch);

        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable > totalCoupons) {
            lessRedeemable = totalRedeemable.sub(totalCoupons);
            burnRedeemable(lessRedeemable);
            (, lessDebt, newBonded, newTreasury) = increaseSupply(lessRedeemable);
        }

        emit CouponExpiration(epoch, expiredAmount, lessRedeemable, lessDebt, newBonded, newTreasury);
    }
    
    function couponPremium(uint256 amount, uint256 expirationPeriod) public view returns (uint256) {
        return calculateCouponPremium(dollar().totalSupply(), totalDebt(), amount, _state6.twapPerEpoch[epoch()], expirationPeriod > 2 ? expirationPeriod - 2 : 1);
    }

    function couponRedemptionPenalty(uint256 couponEpoch, uint256 couponAmount, uint256 expirationPeriod) public view returns (uint256) {
        uint timeIntoEpoch = timeInEpoch();
        uint couponAge = epoch() - couponEpoch;

        uint couponEpochDecay = currentEpochDuration().div(2) * (expirationPeriod - couponAge) / expirationPeriod;

        if(timeIntoEpoch > couponEpochDecay) {
            return 0;
        }

        Decimal.D256 memory couponEpochInitialPenalty = Constants.getInitialCouponRedemptionPenalty().div(Decimal.D256({value: expirationPeriod })).mul(Decimal.D256({value: expirationPeriod - couponAge}));
        Decimal.D256 memory couponEpochDecayedPenalty = couponEpochInitialPenalty.div(Decimal.D256({value: couponEpochDecay})).mul(Decimal.D256({value: couponEpochDecay - timeIntoEpoch}));

        return Decimal.D256({value: couponAmount}).mul(couponEpochDecayedPenalty).value;
    }

    //updates coupons to DAIQIP-3
    function updateCoupons(uint256 _epoch, uint256 expirationPeriod) external {
        uint256 balance = balanceOfCoupons(msg.sender, _epoch);

        Require.that(
            balance > 0,
            FILE,
            "No coupons"
        );

        Require.that(
            couponExpirationForAccount(msg.sender, _epoch) == 0,
            FILE,
            "Coupons already updated"
        );

        uint256 expiration = _epoch.add(expirationPeriod);

        Require.that(
            epoch() < expiration && expirationPeriod <= 100000,
            FILE,
            "Invalid expiration"
        );

        uint256 bonus = balance.div(100);
        uint256 newBalance = balance.add(bonus);
        
        _state.accounts[msg.sender].coupons[_epoch] = newBalance;
        _state.balance.coupons = _state.balance.coupons.add(bonus);
        _state3.couponExpirationsByAccount[msg.sender][_epoch] = expiration;
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].add(newBalance);
    }

    function purchaseCoupons(uint256 dollarAmount, uint256 expirationPeriod) external returns (uint256) {
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

        Require.that(
            expirationPeriod > 2 && expirationPeriod <= 100000,
            FILE,
            "Invalid expiration period"
        );

        Require.that(
            balanceOfCoupons(msg.sender, epoch()) == 0 || couponExpirationForAccount(msg.sender, epoch()) > 0,
            FILE,
            "Coupons not updated"
        );

        Require.that(
            couponExpirationForAccount(msg.sender, epoch()) == 0 || couponExpirationForAccount(msg.sender, epoch()) == epoch().add(expirationPeriod),
            FILE,
            "Cannot set different expiration"
        );

        uint256 epoch = epoch();
        uint256 couponAmount = dollarAmount.add(couponPremium(dollarAmount, expirationPeriod));
        burnFromAccount(msg.sender, dollarAmount);
        incrementBalanceOfCoupons(msg.sender, epoch, couponAmount, epoch.add(expirationPeriod));

        emit CouponPurchase(msg.sender, epoch, dollarAmount, couponAmount);

        return couponAmount;
    }

    function redeemCoupons(uint256 couponEpoch, uint256 couponAmount) external {
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(balanceOfCoupons(msg.sender, couponEpoch) > couponAmount, "Market: Insufficient coupon balance");
        require(couponExpirationForAccount(msg.sender, couponEpoch) > 0, "Market: Coupons not updated");

        decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");

        uint burnAmount = couponRedemptionPenalty(couponEpoch, couponAmount, couponExpirationForAccount(msg.sender, couponEpoch).sub(couponEpoch));
        uint256 redeemAmount = couponAmount - burnAmount;
        
        redeemToAccount(msg.sender, redeemAmount);

        if(burnAmount > 0){
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, redeemAmount);
    }

    function redeemCoupons(uint256 couponEpoch, uint256 couponAmount, uint256 minOutput) external {
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(balanceOfCoupons(msg.sender, couponEpoch) >= couponAmount, "Market: Insufficient coupon balance");
        require(couponExpirationForAccount(msg.sender, couponEpoch) > 0, "Market: Coupons not updated");

        decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");
        
        uint burnAmount = couponRedemptionPenalty(couponEpoch, couponAmount, couponExpirationForAccount(msg.sender, couponEpoch).sub(couponEpoch));
        uint256 redeemAmount = couponAmount - burnAmount;

        Require.that(
            redeemAmount >= minOutput,
            FILE,
            "Insufficient output amount"
        );
        
        redeemToAccount(msg.sender, redeemAmount);

        if(burnAmount > 0){
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, redeemAmount);
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 epochPeriod, uint256 price, uint256 newRedeemable, uint256 lessDebt, uint256 newBonded, uint256 newTreasury);
    event SupplyDecrease(uint256 indexed epoch, uint256 epochPeriod, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch, uint256 epochPeriod);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();
        adjustPeriod(price);
        storePrice(epoch(), price);

        (Era.Status currentEra,) = era();

        if (price.greaterThan(Decimal.one())) {
            if (currentEra != Era.Status.EXPANSION)
                setEra(Era.Status.EXPANSION, epoch());
            setDebtToZero();
            growSupply(price);
            return;
        }

        if (price.lessThan(Decimal.one())) {
            if (currentEra != Era.Status.DEBT)
                setEra(Era.Status.DEBT, epoch());
            decrementTotalRedeemable(totalRedeemable(), "Blockchain broke???????");
            shrinkSupply(price);
            return;
        }

        if (currentEra != Era.Status.NEUTRAL)
                setEra(Era.Status.NEUTRAL, epoch());

        emit SupplyNeutral(epoch(), currentEpochDuration());
    }

    function shrinkSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(Decimal.one().sub(price));
        uint256 newDebt = delta.mul(totalNet()).asUint256();
        increaseDebt(newDebt);

        emit SupplyDecrease(epoch(), currentEpochDuration(), price.value, newDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(price.sub(Decimal.one()).div(Constants.getSupplyChangeDivisor()));
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 lessDebt, uint256 newBonded, uint256 newTreasury) = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), currentEpochDuration(), price.value, newRedeemable, lessDebt, newBonded, newTreasury);
    }

    function limit(Decimal.D256 memory delta) internal view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getSupplyChangeLimit();

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function oracleCapture() internal returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }
        if (!valid) {
            return Decimal.one();
        }

        return price;
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Permission is Setters {

    bytes32 private constant FILE = "Permission";

    // Can modify account state
    modifier onlyFrozenOrFluid(address account) {
        Require.that(
            statusOf(account) != Account.Status.Locked,
            FILE,
            "Not frozen or fluid"
        );

        _;
    }

    // Can participate in balance-dependant activities
    modifier onlyFrozenOrLocked(address account) {
        Require.that(
            statusOf(account) != Account.Status.Fluid,
            FILE,
            "Not frozen or locked"
        );

        _;
    }

    modifier onlyPool(address account) {
        Require.that(
            _state.provider.pool == account,
            FILE,
            "Account isn't pool"
        );

        _;
    }

    modifier onlyLottery(address account) {
        Require.that(
            account == Constants.getLotteryAddress(),
            FILE,
            "Account isn't the lottery"
        );
        _;
    }

    modifier initializer() {
        Require.that(
            !isInitialized(implementation()),
            FILE,
            "Already initialized"
        );

        initialized(implementation());

        _;
    }
}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Bonding is Setters, Permission {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Bonding";

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);

    function step() internal {
        Require.that(
            epochTime() > epoch(),
            FILE,
            "Still current epoch"
        );

        snapshotTotalBonded();
        incrementEpoch();
    }

    function deposit(uint256 value) external {
        Require.that(
            value > 0,
            FILE,
            "Insufficient deposit amount"
        );

        dollar().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozenOrLocked(msg.sender) {
        dollar().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Bonding: insufficient staged balance");

        emit Withdraw(msg.sender, value);
    }

    function bond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        bondInternal(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Bonding: insufficient staged balance");
    }

    function bondFromPool(address account, uint256 value) external onlyFrozenOrFluid(account) onlyPool(msg.sender) {
        //no need to check if we actually received the expected amount since this function can only be called by the pool
        bondInternal(account, value);
    }

    function bondInternal(address account, uint256 value) internal {
        unfreeze(account);

        uint256 balance = totalBonded() == 0 ?
            value.mul(Constants.getInitialStakeMultiple()) :
            value.mul(totalSupply()).div(totalBonded());
        incrementBalanceOf(account, balance);

        incrementTotalBonded(value);

        emit Bond(account, epoch().add(1), balance, value);
    }

    function unbond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 staged = value.mul(balanceOfBonded(msg.sender)).div(balanceOf(msg.sender));
        incrementBalanceOfStaged(msg.sender, staged);
        decrementTotalBonded(staged, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, value, "Bonding: insufficient balance");

        emit Unbond(msg.sender, epoch().add(1), value, staged);
    }

    function unbondUnderlying(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 balance = value.mul(totalSupply()).div(totalBonded());
        incrementBalanceOfStaged(msg.sender, value);
        decrementTotalBonded(value, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, balance, "Bonding: insufficient balance");

        emit Unbond(msg.sender, epoch().add(1), balance, value);
    }
}

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

/*
    Copyright 2018-2019 zOS Global Limited
    Copyright 2020 Dynamic Dollar Devs, based on the works of the Empty Set Squad

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

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Govern is Setters, Permission, Upgradeable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Govern";

    event Proposal(address indexed candidate, address indexed account, uint256 indexed start, uint256 period);
    event Vote(address indexed account, address indexed candidate, Candidate.Vote vote, uint256 bonded);
    event Commit(address indexed account, address indexed candidate);

    function vote(address candidate, Candidate.Vote vote) external onlyFrozenOrLocked(msg.sender) {
        Require.that(
            balanceOf(msg.sender) > 0,
            FILE,
            "Must have stake"
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

        uint256 bonded = balanceOf(msg.sender);
        Candidate.Vote recordedVote = recordedVote(msg.sender, candidate);
        if (vote == recordedVote) {
            return;
        }

        if (recordedVote == Candidate.Vote.REJECT) {
            decrementRejectFor(candidate, bonded, "Govern: Insufficient reject");
        }
        if (recordedVote == Candidate.Vote.APPROVE) {
            decrementApproveFor(candidate, bonded, "Govern: Insufficient approve");
        }
        if (vote == Candidate.Vote.REJECT) {
            incrementRejectFor(candidate, bonded);
        }
        if (vote == Candidate.Vote.APPROVE) {
            incrementApproveFor(candidate, bonded);
        }

        recordVote(msg.sender, candidate, vote);
        placeLock(msg.sender, candidate);

        emit Vote(msg.sender, candidate, vote, bonded);
    }

    function commit(address candidate) external {
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
            Decimal.ratio(votesFor(candidate), totalBondedAt(endsAfter)).greaterThan(Constants.getGovernanceQuorum()),
            FILE,
            "Must have quorom"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function emergencyCommit(address candidate) external {
        Require.that(
            isNominated(candidate),
            FILE,
            "Not nominated"
        );

        Require.that(
            block.timestamp > currentEpochStart().add(currentEpochDuration().mul(Constants.getGovernanceEmergencyDelay())),
            FILE,
            "Epoch synced"
        );

        Require.that(
            Decimal.ratio(approveFor(candidate), totalSupply()).greaterThan(Constants.getGovernanceSuperMajority()),
            FILE,
            "Must have super majority"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function canPropose(address account) private view returns (bool) {
        if (totalBonded() == 0) {
            return false;
        }

        Decimal.D256 memory stake = Decimal.ratio(balanceOf(account), totalSupply());
        return stake.greaterThan(Decimal.ratio(5, 1000)); // 0.5%
    }
}

contract Bootstrapper is Comptroller {

    bytes32 private constant FILE = "Bootstrapper";

    event Swap(address indexed sender, uint256 amount, uint256 contributions);
    event Incentivization(address indexed account, uint256 amount);
    event DAIIncentivization(address indexed account, uint256 amount);
    event MixedIncentivization(address indexed account, uint256 daiqAmount, uint256 daiAmount);

    function step() internal {
        if (epoch() == 0) {
            uint256 bootstrapInflation = Constants.getBootstrappingPrice().sub(Decimal.one()).div(Constants.getSupplyChangeDivisor()).value;
            uint256 supply = dollar().totalSupply().mul(1e18);
            uint256 supplyTarget = Constants.getBootstrappingTarget().value;
            uint256 epochs = 0;

            if (supply > 0)
                while(supply < supplyTarget) {
                    supply = supply + supply * bootstrapInflation / 1e18;
                    epochs ++;
                }

            setBootstrappingPeriod(epochs > 0 ? epochs - 1 : 0);

            uint256 daiIncentive = epochs > 0 ? totalContributions().div(epochs) : Constants.getDaiAdvanceIncentiveCap();
            setDAIAdvanceIncentive(
                daiIncentive > 0
                    ? daiIncentive > Constants.getDaiAdvanceIncentiveCap()
                        ? Constants.getDaiAdvanceIncentiveCap()
                        : daiIncentive
                    : Constants.getAdvanceIncentive()
            );

            shouldDistributeDAI(true);
        }

        if (shouldDistributeDAI()) {
            uint256 balance = dai().balanceOf(address(this));
            uint256 incentive = daiAdvanceIncentive();

            if (balance > incentive) {
                dai().transfer(msg.sender, incentive);
                emit DAIIncentivization(msg.sender, incentive);
            }
            else {
                uint256 daiqIncentive = incentive.sub(balance);
                dai().transfer(msg.sender, balance);
                mintToAccount(msg.sender, daiqIncentive);
                emit MixedIncentivization(msg.sender, daiqIncentive, balance);
                
                shouldDistributeDAI(false);
            }
        }
        else {
            // Mint advance reward to sender
            uint256 incentive = Constants.getAdvanceIncentive();
            mintToAccount(msg.sender, incentive);
            emit Incentivization(msg.sender, incentive);
        }
    }
}

interface IVault {
    
    function submitTransaction(address destination, uint value, bytes calldata data) external returns (uint);

}

/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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
contract Implementation is State, Bonding, Market, Regulator, Govern, Bootstrapper {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);

    function initialize() initializer public {
        dai().transfer(msg.sender, 150e18);  //150 DAI to committer
        //Mint 100k DAIQ to Boot Finance treasury
        dollar().mint(address(0x03Df4ADDfB568b338f6a0266f30458045bbEFbF2), 100000e18);
        //1800 to deployer
        dai().transfer(0xf751033D4e6864a88Be93E36258246F26AEf577c, 1800e18);
    }

    function advance() external {
        Bootstrapper.step();
        Bonding.step();
        Regulator.step();
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function requestDAI(address recipient, uint256 amount) external onlyLottery(msg.sender) {
        IVault(treasury()).submitTransaction(
            address(dai()),
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipient,
                amount
            )
        );
    }

    function transactionExecuted(uint256 transactionId) external {

    }

    function transactionFailed(uint256 transactionId) external {

    }
}