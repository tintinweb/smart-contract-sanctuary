/**
 *Submitted for verification at Etherscan.io on 2021-03-19
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
library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet
    
    /* Supply */
    uint256 private constant INITIAL_SUPPLY = 5e24; // 5M Tokens => mint plenty, burn most

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PRICE = 154e16; // 1.54 USDC (targeting 4.5% inflation)

    /* Oracle */
    address private constant USDC = address(0xd6121c3F38645F587cd032D61935aaaaA8812679); // TESTING
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 DSD -> 100M DSDS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant EPOCH_OFFSET = 1;
    uint256 private constant EPOCH_START = 1621194229; 
    uint256 private constant EPOCH_PERIOD = 60; // TESTING 1min

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 1; // TESTING -> adjust to be timewise the same as in dsd
    uint256 private constant GOVERNANCE_QUORUM = 15e16; // 15%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs -> adjust to be timewise the same as in dsd

    /* DAO */
    uint256 private constant MAX_ADVANCE_INCENTIVE = 1e21; // $1000
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 2; // TESTING 

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 2; // TESTING

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 5; // TESTING
    uint256 private constant DEBT_RATIO_CAP = 35e16; // 35%
    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 50e16; // 50%
    uint256 private constant COUPON_REDEMPTION_PENALTY_DECAY = 60;  // TESTING 1min

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 1622459126733e3; // set 1.62%
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 24661e15; // 24661 > Max expansion at ~1.40
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 25e15; // 2.5 %
    uint256 private constant COUPON_SUPPLY_CHANGE_DIVISOR = 16e18; // 16 > Max expansion at 1.40
    uint256 private constant NEGATIVE_SUPPLY_CHANGE_DIVISOR = 5e18; // 5 > Max negative expansion at 0.9
    uint256 private constant ORACLE_POOL_RATIO = 55; // 55%
    uint256 private constant TREASURY_RATIO = 3; // 3%

    /* Deployed */      
    address private constant TREASURY_ADDRESS = address(0x000000000000000000000000000000000000dEaD); // TODO  // TESTING

    /* PID controlled FOT */
    uint32 private constant INTEGRAL_WEIGHTS_FOT_0 = 5; // weight gets slightly heavier towards present
    uint32 private constant INTEGRAL_WEIGHTS_FOT_1 = 6;
    uint32 private constant INTEGRAL_WEIGHTS_FOT_2 = 7;
    uint32 private constant INTEGRAL_WEIGHTS_FOT_3 = 8;
    uint32 private constant INTEGRAL_WEIGHTS_FOT_4 = 9;
    int256 private constant COEFF_P_FOT = 2e17; // 0.2
    int256 private constant COEFF_I_FOT = 2e17; // 0.2
    int256 private constant COEFF_D_FOT = 8e17; // 0.8

    /* Fee Pool */
    bool private constant AUTOMATIC_LIQUIDITY_PROVIDING_ENABLED = false; 
    uint256 private constant MIN_TOKENS_FOR_LP = 2e21; // 2000 Token
    uint256 private constant LIQUIDITY_PROVIDING_RATIO = 5e17; // 50%
    
    /* Other */
    uint256 private constant FLAT_FEE = 1e16; // 1%
    
    /**
     * Getters
     */
    function getInitialSupply() internal pure returns (uint256) {
        return INITIAL_SUPPLY;
    }

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: EPOCH_OFFSET,
            start: EPOCH_START,
            period: EPOCH_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
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

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getMaxAdvanceIncentive() internal pure returns (uint256) {
        return MAX_ADVANCE_INCENTIVE;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    
    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }

    function getCouponRedemptionPenaltyDecay() internal pure returns (uint256) {
        return COUPON_REDEMPTION_PENALTY_DECAY;
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getCouponSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_DIVISOR});
    }

    function getNegativeSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: NEGATIVE_SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getIntegralWeightsFot() internal pure returns (uint32[] memory)
    {
        uint32[] memory integralWeightsFot = new uint32[](5);
        integralWeightsFot[0] = INTEGRAL_WEIGHTS_FOT_0;
        integralWeightsFot[1] = INTEGRAL_WEIGHTS_FOT_1;
        integralWeightsFot[2] = INTEGRAL_WEIGHTS_FOT_2;
        integralWeightsFot[3] = INTEGRAL_WEIGHTS_FOT_3;
        integralWeightsFot[4] = INTEGRAL_WEIGHTS_FOT_4;
        return integralWeightsFot; 
    }

    function getFlatFee() internal pure returns (uint256)
    {
        return FLAT_FEE;
    }

    function getCoeffPFot() internal pure returns (int256)
    {
       return COEFF_P_FOT;
    }

    function getCoeffIFot() internal pure returns (int256)
    {
       return COEFF_I_FOT;
    }

    function getCoeffDFot() internal pure returns (int256)
    {
       return COEFF_D_FOT;
    }

    function automaticLiquidityProvidingEnabled() internal pure returns (bool)
    {
        return AUTOMATIC_LIQUIDITY_PROVIDING_ENABLED;
    }
    
    function getMinTokensForLp() internal pure returns (uint256)
    {
        return MIN_TOKENS_FOR_LP;
    }

    function getLiquidityProvidingRatio() internal pure returns (uint256)
    {
        return LIQUIDITY_PROVIDING_RATIO;
    }

}

/*
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

    // 1/(3(1-R)^2)-1/3
    function curve(Decimal.D256 memory debtRatio) private pure returns (Decimal.D256 memory) {
        return Decimal.one().div(
            Decimal.from(3).mul((Decimal.one().sub(debtRatio)).pow(2))
        ).sub(Decimal.ratio(1, 3));
    }

    // 1/(3(1-R)(1-R'))-1/3
    function curveMean(
        Decimal.D256 memory lower,
        Decimal.D256 memory upper
    ) private pure returns (Decimal.D256 memory) {
        if (lower.equals(upper)) {
            return curve(lower);
        }

        return Decimal.one().div(
            Decimal.from(3).mul(Decimal.one().sub(upper)).mul(Decimal.one().sub(lower))
        ).sub(Decimal.ratio(1, 3));
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/**
     * @title Ownable
     * @dev The Ownable contract has an owner address, and provides basic authorization control
     * functions, this simplifies the implementation of "user permissions".
     */
contract ImpOwnable is Initializable {
      address private _owner;
    
    
      event OwnershipRenounced(address indexed previousOwner);
      event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
      );
    
    
      /**
       * @dev The Ownable constructor sets the original `owner` of the contract to the sender
       * account.
       */
       modifier setOwner() {
        _owner = msg.sender;
        _;
      }
    
      /**
       * @return the address of the owner.
       */
      function owner() public view returns(address) {
        return _owner;
      }
    
      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
        require(isOwner());
        _;
      }
    
      /**
       * @return true if `msg.sender` is the owner of the contract.
       */
      function isOwner() public view returns(bool) {
        return msg.sender == _owner;
      }
    
      /**
       * @dev Allows the current owner to relinquish control of the contract.
       * @notice Renouncing to ownership will leave the contract without an owner.
       * It will not be possible to call the functions with the `onlyOwner`
       * modifier anymore.
       */
      function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
      }
    
      /**
       * @dev Allows the current owner to transfer control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       */
      function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
      }
    
      /**
       * @dev Transfers control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       */
      function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
      }
    
      uint256[50] private ______gap;
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
contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
    function permanentlyEnableFees() public;
    function setExemptSender(address sender, bool exempt) public;
    function setExemptRecipient(address recipient, bool exempt) public;
    function setFlatFee(uint256 flatFee_) public;
    function setStabilizingFee(uint256 stabilizingFee_) public;
    function setFeePool(address feePool_) public;
}

/*
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
contract IOracle {
    function setup() public;
    function capture() public returns (Decimal.D256 memory, bool);
    function pair() external view returns (address);
}

/*
    Copyright 2021 Control Loop Devs

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
interface IFeePool {
    function burn(uint256 amount) external; 
    function provideLiquidity(uint256 amount, uint256 callerReward) external;
}

/*
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
        mapping(address => uint256) couponAllowances;
        uint256 fluidUntil;
        uint256 lockedUntil;
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
        uint256 expiration;
        uint256[] expiring;
    }

    struct State {
        uint256 bonded;
        Decimal.D256 priceAtStart;
        Coupons coupons;
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

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
        address pool;
        IFeePool feePool;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 redeemable;
        uint256 debt;
        uint256 coupons;
    }

    struct Configurables {
        uint256 bootstrappingPeriod;
        uint256 advanceIncentive;
        uint256 epochStart;
    }

    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;
        Configurables configurables;

        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(address => Candidate.State) candidates;
    }

    struct State13 {
        mapping(address => mapping(uint256 => uint256)) couponUnderlyingByAccount;
        uint256 couponUnderlying;
        Decimal.D256 price;
    }
}

contract State {
    Storage.State _state;

    // DIP-13
    Storage.State13 _state13;
}

/*
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
contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "Flopsy Stake";
    }

    function symbol() public view returns (string memory) {
        return "FS";
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

    function feePool() public view returns (IFeePool) {
        return _state.provider.feePool;
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

    function totalCouponUnderlying() public view returns (uint256) {
        return _state13.couponUnderlying;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().sub(totalDebt());
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

    function balanceOfCoupons(address account, uint256 epoch) public view returns (uint256) {
        if (outstandingCoupons(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch];
    }

    function balanceOfCouponUnderlying(address account, uint256 epoch) public view returns (uint256) {
        return _state13.couponUnderlyingByAccount[account][epoch];
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address account) public view returns (uint256) {
        return _state.accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
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
        Constants.EpochStrategy memory current = Constants.getEpochStrategy();
        current.start = _state.configurables.epochStart;

        return epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy) private view returns (uint256) {
        return blockTimestamp()
            .sub(strategy.start)
            .div(strategy.period)
            .add(strategy.offset);
    }

    function priceAtEpochStart(uint256 epoch_) public view  returns (Decimal.D256 memory) {
        require(epoch_ <= epoch(), "requested epoch not reached");
        return _state.epochs[epoch()].priceAtStart;
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function outstandingCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.outstanding;
    }

    function couponsExpiration(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiration;
    }

    function expiringCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiring.length;
    }

    function expiringCouponsAtIndex(uint256 epoch, uint256 i) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiring[i];
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= _state.configurables.bootstrappingPeriod;
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

    /**
     * misc
    */
    function getAdvanceIncentive() public view returns (uint256) {
        return _state.configurables.advanceIncentive;
    }
    
}

/*
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
contract Setters is State, Getters, ImpOwnable {
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

    function incrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].add(amount);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.add(amount);
        _state.balance.coupons = _state.balance.coupons.add(amount);
    }

    function incrementBalanceOfCouponUnderlying(address account, uint256 epoch, uint256 amount) internal {
        _state13.couponUnderlyingByAccount[account][epoch] = _state13.couponUnderlyingByAccount[account][epoch].add(amount);
        _state13.couponUnderlying = _state13.couponUnderlying.add(amount);
    }

    function decrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount, string memory reason) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].sub(amount, reason);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.sub(amount, reason);
        _state.balance.coupons = _state.balance.coupons.sub(amount, reason);
    }

    function decrementBalanceOfCouponUnderlying(address account, uint256 epoch, uint256 amount, string memory reason) internal {
        _state13.couponUnderlyingByAccount[account][epoch] = _state13.couponUnderlyingByAccount[account][epoch].sub(amount, reason);
        _state13.couponUnderlying = _state13.couponUnderlying.sub(amount, reason);
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

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = totalSupply();
    }

    function initializeCouponsExpiration(uint256 epoch, uint256 expiration) internal {
        _state.epochs[epoch].coupons.expiration = expiration;
        _state.epochs[expiration].coupons.expiring.push(epoch);
    }

    function eliminateOutstandingCoupons(uint256 epoch) internal {
        uint256 outstandingCouponsForEpoch = outstandingCoupons(epoch);
        if(outstandingCouponsForEpoch == 0) {
            return;
        }
        _state.balance.coupons = _state.balance.coupons.sub(outstandingCouponsForEpoch);
        _state.epochs[epoch].coupons.outstanding = 0;
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

    /**
    * Misc
    */
    function setBootstrappingPeriod(uint256 period) internal {
        _state.configurables.bootstrappingPeriod = period;
    }

    function setAdvanceIncentive(uint256 incentive) public onlyOwner() {
        require(Constants.getMaxAdvanceIncentive() >= incentive, "advance incentive is too large");
        _state.configurables.advanceIncentive = incentive;
    }

    function setEpochStart() internal {
        _state.configurables.epochStart = block.timestamp;
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
contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function setPrice(Decimal.D256 memory price) internal {
        _state13.price = price;
        _state.epochs[epoch()].priceAtStart = price;
    }

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        if (!bootstrappingAt(epoch())) {
            increaseDebt(amount);
        }

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(amount, "Comptroller: not enough outstanding debt");

        balanceCheck();
    }

    function redeemToAccount(address account, uint256 amount, uint256 couponAmount) internal {
        dollar().mint(account, amount);

        if (couponAmount != 0) {
            dollar().transfer(account, couponAmount);
            decrementTotalRedeemable(couponAmount, "Comptroller: not enough redeemable balance");
        }

        balanceCheck();
    }

    function burnRedeemable(uint256 amount) internal {
        dollar().burn(amount);
        decrementTotalRedeemable(amount, "Comptroller: not enough redeemable balance");

        balanceCheck();
    }

    function increaseDebt(uint256 amount) internal returns (uint256) {
        incrementTotalDebt(amount);
        uint256 lessDebt = resetDebt(Constants.getDebtRatioCap()); // only let debt increase up to the point where debt ratio is exceeded, if thats the case lower the amount

        balanceCheck();

        return lessDebt > amount ? 0 : amount.sub(lessDebt); // give back the amount that the debt was actually increased by
    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount, "Comptroller: not enough debt");

        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) { // called by Market and Regulator
        // 0-a. Pay out to Pool
        uint256 poolReward = newSupply.mul(Constants.getOraclePoolRatio()).div(100);
        mintToPool(poolReward);

        // 0-b. Pay out to Treasury
        uint256 treasuryReward = newSupply.mul(Constants.getTreasuryRatio()).div(100);
        mintToTreasury(treasuryReward);

        uint256 rewards = poolReward.add(treasuryReward);
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

        // 2. Payout to DAO
        if (totalBonded() == 0) {
            newSupply = 0;
        }
        if (newSupply > 0) {
            mintToDAO(newSupply);
        }

        balanceCheck();

        return (newRedeemable, newSupply.add(rewards));
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
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()),
            FILE,
            "Inconsistent balances"
        );
    }

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToTreasury(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(Constants.getTreasuryAddress(), amount);
        }
    }

    function mintToPool(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(pool(), amount);
        }
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);

        balanceCheck();
    }
}

/*
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
contract Market is Comptroller, Curve {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Market";

    event CouponExpiration(uint256 indexed epoch, uint256 couponsExpired, uint256 lessRedeemable, uint256 lessDebt, uint256 newBonded);
    event CouponPurchase(address indexed account, uint256 indexed epoch, uint256 dollarAmount, uint256 couponAmount);
    event CouponRedemption(address indexed account, uint256 indexed epoch, uint256 amount, uint256 couponAmount);
    event CouponBurn(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponTransfer(address indexed from, address indexed to, uint256 indexed epoch, uint256 value);
    event CouponApproval(address indexed owner, address indexed spender, uint256 value);

    function step() internal {
        // Expire prior coupons
        for (uint256 i = 0; i < expiringCoupons(epoch()); i++) { // in most cases this loop runs only once
            expireCouponsForEpoch(expiringCouponsAtIndex(epoch(), i));
        }

        // Record expiry for current epoch's coupons
        uint256 expirationEpoch = epoch().add(Constants.getCouponExpiration());
        initializeCouponsExpiration(epoch(), expirationEpoch);
    }

    function expireCouponsForEpoch(uint256 epoch) private { // expire coupons issued in the given epoch
        uint256 couponsForEpoch = outstandingCoupons(epoch);
        (uint256 lessRedeemable, uint256 newBonded) = (0, 0);

        eliminateOutstandingCoupons(epoch);

        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable > totalCoupons) { // if there is more than enough dollars in redeemable 
            lessRedeemable = totalRedeemable.sub(totalCoupons);
            burnRedeemable(lessRedeemable); // first "burn" them
            (, newBonded) = increaseSupply(lessRedeemable); // then remint them to pool, treasury and DAO
        }

        emit CouponExpiration(epoch, couponsForEpoch, lessRedeemable, 0, newBonded);
    }

    function couponPremium(uint256 amount) public view returns (uint256) {
        return calculateCouponPremium(dollar().totalSupply(), totalDebt(), amount);
    }

    function couponRedemptionPenalty(uint256 couponEpoch, uint256 couponAmount) public view returns (uint256) {
        uint timeIntoEpoch = block.timestamp % Constants.getEpochStrategy().period;
        uint couponAge = epoch().sub(couponEpoch, "Market: Future couponEpoch");

        if (couponAge >= Constants.getCouponExpiration()) {
            return 0;
        }

        uint couponEpochDecay = Constants.getCouponRedemptionPenaltyDecay() * (Constants.getCouponExpiration() - couponAge) / Constants.getCouponExpiration();

        if (timeIntoEpoch >= couponEpochDecay) {
            return 0;
        }

        Decimal.D256 memory couponEpochInitialPenalty = Constants.getInitialCouponRedemptionPenalty().div(Decimal.D256({value: Constants.getCouponExpiration() })).mul(Decimal.D256({value: Constants.getCouponExpiration() - couponAge}));

        Decimal.D256 memory couponEpochDecayedPenalty = couponEpochInitialPenalty.div(Decimal.D256({value: couponEpochDecay})).mul(Decimal.D256({value: couponEpochDecay - timeIntoEpoch}));

        return Decimal.D256({value: couponAmount}).mul(couponEpochDecayedPenalty).value;
    }

    function migrateCoupons(uint256 couponEpoch) external {
        require(balanceOfCouponUnderlying(msg.sender, couponEpoch) == 0, "Market: Already migrated");

        uint256 balanceOfCoupons = _state.accounts[msg.sender].coupons[couponEpoch];
        uint256 couponUnderlying = balanceOfCoupons.div(2);

        if (outstandingCoupons(couponEpoch) == 0) {
            // coupons have expired
            _state.accounts[msg.sender].coupons[couponEpoch] = 0;
        } else {
            // coupons have not expired
            decrementBalanceOfCoupons(msg.sender, couponEpoch, couponUnderlying, "Market: Insufficient coupon balance");
        }

        incrementBalanceOfCouponUnderlying(msg.sender, couponEpoch, couponUnderlying);

        emit CouponRedemption(msg.sender, couponEpoch, 0, couponUnderlying);
        emit CouponPurchase(msg.sender, couponEpoch, couponUnderlying, 0);
    }

    function purchaseCoupons(uint256 amount) external returns (uint256) {
        Require.that(
            amount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        Require.that(
            totalDebt() >= amount,
            FILE,
            "Not enough debt"
        );

        uint256 epoch = epoch();

        // coupon total (deposit + premium)
        uint256 balanceOfCoupons = amount.add(couponPremium(amount));

        // split total by 1/2
        uint256 couponUnderlying = balanceOfCoupons.div(2);

        // 1/2 can expire
        incrementBalanceOfCoupons(msg.sender, epoch, couponUnderlying);

        // 1/2 can always be reclaimed
        incrementBalanceOfCouponUnderlying(msg.sender, epoch, couponUnderlying);

        burnFromAccount(msg.sender, amount);

        emit CouponPurchase(msg.sender, epoch, amount, couponUnderlying);

        return couponUnderlying;
    }

    function redeemCoupons(uint256 couponEpoch, uint256 amount) external {
        require(_state13.price.greaterThan(Decimal.one()), "Market: not in expansion");
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(amount != 0, "Market: Amount too low");

        uint256 couponAmount = balanceOfCoupons(msg.sender, couponEpoch)
            .mul(amount).div(balanceOfCouponUnderlying(msg.sender, couponEpoch), "Market: No underlying");

        uint256 totalAmount = couponAmount.add(amount);

        // penalty burn will be applied to premium and underlying
        uint256 burnAmount = couponRedemptionPenalty(couponEpoch, totalAmount);

        if (couponAmount != 0) {
            decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");

            // reduce premium by redemption penalty
            couponAmount = couponAmount - burnAmount.mul(couponAmount).div(totalAmount);
        }

        decrementBalanceOfCouponUnderlying(msg.sender, couponEpoch, amount, "Market: Insufficient coupon underlying balance");

        // reduce underlying by redemption penalty
        amount = amount - burnAmount.mul(amount).div(totalAmount);

        redeemToAccount(msg.sender, amount, couponAmount);

        if (burnAmount != 0) {
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, amount, couponAmount);
    }

    function redeemCoupons(uint256 couponEpoch, uint256 amount, uint256 minOutput) external {
        require(_state13.price.greaterThan(Decimal.one()), "Market: not in expansion");
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(amount != 0, "Market: Amount too low");

        uint256 couponAmount = balanceOfCoupons(msg.sender, couponEpoch)
            .mul(amount).div(balanceOfCouponUnderlying(msg.sender, couponEpoch), "Market: No underlying");

        uint256 totalAmount = couponAmount.add(amount);

        // penalty burn will be applied to premium and underlying
        uint256 burnAmount = couponRedemptionPenalty(couponEpoch, totalAmount);

        if (couponAmount != 0) {
            decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");

            // reduce premium by redemption penalty
            couponAmount = couponAmount - burnAmount.mul(couponAmount).div(totalAmount);
        }

        decrementBalanceOfCouponUnderlying(msg.sender, couponEpoch, amount, "Market: Insufficient coupon underlying balance");

        // reduce underlying by redemption penalty
        amount = amount - burnAmount.mul(amount).div(totalAmount);

        Require.that(
            couponAmount.add(amount) >= minOutput,
            FILE,
            "Insufficient output amount"
        );

        redeemToAccount(msg.sender, amount, couponAmount);

        if (burnAmount != 0) {
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, amount, couponAmount);
    }

    function approveCoupons(address spender, uint256 amount) external {
        require(spender != address(0), "Market: Coupon approve to the zero address");

        updateAllowanceCoupons(msg.sender, spender, amount);

        emit CouponApproval(msg.sender, spender, amount);
    }

    function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external {
        require(sender != address(0), "Market: Coupon transfer from the zero address");
        require(recipient != address(0), "Market: Coupon transfer to the zero address");

        decrementBalanceOfCoupons(sender, epoch, amount, "Market: Insufficient coupon balance");
        incrementBalanceOfCoupons(recipient, epoch, amount);

        if (msg.sender != sender && allowanceCoupons(sender, msg.sender) != uint256(-1)) {
            decrementAllowanceCoupons(sender, msg.sender, amount, "Market: Insufficient coupon approval");
        }

        emit CouponTransfer(sender, recipient, epoch, amount);
    }
}

/*
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
contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 price, uint256 newRedeemable, uint256 lessDebt, uint256 newBonded);
    event SupplyDecrease(uint256 indexed epoch, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();

        setPrice(price);

        if (price.greaterThan(Decimal.one())) {
            growSupply(price);
            return;
        }

        if (price.lessThan(Decimal.one())) {
            shrinkSupply(price);
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function shrinkSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(Decimal.one().sub(price).div(Constants.getNegativeSupplyChangeDivisor()), price);
        uint256 newDebt = delta.mul(totalNet()).asUint256();
        uint256 cappedNewDebt = increaseDebt(newDebt);

        emit SupplyDecrease(epoch(), price.value, cappedNewDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price) private {
        uint256 lessDebt = resetDebt(Decimal.zero());

        Decimal.D256 memory supplyChangeDivisor = Constants.getSupplyChangeDivisor();

        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable < totalCoupons) {
            supplyChangeDivisor = Constants.getCouponSupplyChangeDivisor();
        }

        Decimal.D256 memory delta = limit(price.sub(Decimal.one()).div(supplyChangeDivisor), price);
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 newBonded) = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), price.value, newRedeemable, lessDebt, newBonded);
    }

    function limit(Decimal.D256 memory delta, Decimal.D256 memory price) private view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getSupplyChangeLimit();
        
        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (price.greaterThan(Decimal.one()) && (totalRedeemable < totalCoupons)) {
            supplyChangeLimit = Constants.getCouponSupplyChangeLimit();
        }

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
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
        unfreeze(msg.sender);

        uint256 balance = totalBonded() == 0 ?
            value.mul(Constants.getInitialStakeMultiple()) :
            value.mul(totalSupply()).div(totalBonded()); // conversion: dollar->staking; user gets share of all existing stake coins according to the ratio of his bonded Dollars to all bonded Dollars
        incrementBalanceOf(msg.sender, balance);
        incrementTotalBonded(value);
        decrementBalanceOfStaged(msg.sender, value, "Bonding: insufficient staged balance");

        emit Bond(msg.sender, epoch().add(1), balance, value);
    }

    /** 
    *  parameter value in staking token
    */
    function unbond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 staged = value.mul(balanceOfBonded(msg.sender)).div(balanceOf(msg.sender)); // conversion: staking->dollar; ugly way to write: value * totalBonded() / totalSupply
        incrementBalanceOfStaged(msg.sender, staged);
        decrementTotalBonded(staged, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, value, "Bonding: insufficient balance");

        emit Unbond(msg.sender, epoch().add(1), value, staged);
    }

    /**
    *  parameter value in dollar token
    */
    function unbondUnderlying(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 balance = value.mul(totalSupply()).div(totalBonded()); // conversion: dollar->staking;
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
        require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cant set a proxy impl to EOA");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

/*
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
            epochTime() > epoch().add(Constants.getGovernanceEmergencyDelay()),
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
        return stake.greaterThan(Constants.getGovernanceProposalThreshold());
    }
}

// ported from openzeppelin v3.0.0
/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

/*
    Copyright 2021 controll loop developers

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY coeffIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// ported openzeppelin contract from newer version
contract PidController {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // all parameters should be given "fixed point style" given "fixed point" style 
    function pid(
        int256[] memory values,
        int256 setPoint, 
        uint32[] memory integralWeights, // weights are used for averaging => no need for decimals; less bits to make casting to signed type safe
        int256 coeffP, 
        int256 coeffI, 
        int256 coeffD,
        uint8 decimals // decimals for all other parameters, needs to be >= 1 because it is used as divisor; less bits to make casting to signed type safe
    )
        internal  
        returns (int256) 
    {
//        require(values.length >= 2, "ge 2 vals needed to calc d");
//        require(values.length == integralWeights.length, "vals & integralWeights need same length");
//        require(decimals >= 1, "pid: decs must be ge 1"); // else there are divisions by zero
//        require(decimals < 75, "pid: decs must be st 75"); // to fit 10^decimals into uint248

        int256[] memory errors = new int256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            errors[i] = values[i].sub(setPoint);
        }

        return pidImpl(
            errors,
            integralWeights,
            coeffP,
            coeffI,
            coeffD,
            decimals
            );
    }
    

    function pidImpl(
        int256[] memory errors, 
        uint32[] memory integralWeights,
        int256 coeffP, 
        int256 coeffI, 
        int256 coeffD,
        uint8 decimals
    )   
        private 
        pure 
        returns (int256) 
    {
        uint256 most_recent = errors.length.sub(1);

        int256 proportional = errors[most_recent].mul(coeffP);
        int256 integral = weightedAverage(errors, integralWeights).mul(coeffI);
        int256 derivative = errors[most_recent].sub(errors[most_recent.sub(1)]).mul(coeffD);

        return proportional.add(integral).add(derivative).div(int256(10**uint248(decimals))); // return value still subject to decimals, only divided once
    }

    // decimal agnostic
    function weightedAverage(int256[] memory values, uint32[] memory weights) private pure returns (int256) {
        int256 weightedSum = 0;
        uint256 sumOfWeights = 0;
        for (uint256 i = 0; i < values.length; i++) {
            weightedSum = weightedSum.add(values[i].mul(int256(weights[i])));
            sumOfWeights = sumOfWeights.add(uint256(weights[i]));
        }
        require(sumOfWeights <= (~uint256(0) >> 1), "sumOfWeights to large"); // sumOfWeights (uint256) to large to fit in int256
        return weightedSum.div(int256(sumOfWeights));
    }

}

/*
    Copyright 2021 Control Loop Devs

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
contract FeeController is Setters, PidController {
    using SafeMath for uint256;

    bytes32 private constant FILE = "FeeController";

    function step() internal {
        if(priceAtEpochStart(epoch()).greaterThan(Decimal.one())) { // no stabilizing fee if price is $1 or above
            dollar().setStabilizingFee(0);
        } else { // get Fee rates from PID controller
            int256 stabilizingFee = - pid(
                lastEpochsPrices(uint248(5)),
                1e18, // $1 target price
                Constants.getIntegralWeightsFot(),
                Constants.getCoeffPFot(),
                Constants.getCoeffIFot(),
                Constants.getCoeffDFot(),
                18 
            );
            if (stabilizingFee >= int256(0)) {
                dollar().setStabilizingFee(uint256(stabilizingFee));
            }
        }

        // liquidity providing
        uint256 accumulatedFees = dollar().balanceOf(address(feePool()));
        if (accumulatedFees >= Constants.getMinTokensForLp() &&
            Constants.automaticLiquidityProvidingEnabled())
        {
            feePool().provideLiquidity(accumulatedFees.mul(Constants.getLiquidityProvidingRatio()).div(1e18), 100e18);
        }
    }

    // numEpochs = 1 means current epoch, 2 means current and the one before...
    function lastEpochsPrices(uint248 numEpochs) internal view returns (int256[] memory) {
        require(numEpochs > 0, "numEpochs must be gt 0");
        int256[] memory prices = new int256[](numEpochs);
        for (uint256 i = 0; i < numEpochs; i++) {
            int256 epoch_ = int256(epoch()) - int256(numEpochs) + 1 + int256(i); 
            if (epoch_ > int256(0)) {
                prices[i] = int256(priceAtEpochStart(uint256(epoch_)).value);
            } else { // if there are not enough recorded epochs, yet
                prices[i] = int256(1e18); // pad with $1 prices
            }
        }
        return prices;
    }
}

/*
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
contract Implementation is State, Bonding, Market, Regulator, Govern, FeeController {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    constructor() public {
        //Ownable.init();
    }

    function initialize() initializer setOwner public {
        // no incentives for initial deployment
        dollar().mint(tx.origin, Constants.getInitialSupply()); 
    }

    function advance() public incentivized {
        require(epoch() > 0, "start first");

        Bonding.step(); // increments epoch
        Regulator.step(); // sets price
        Market.step();
        FeeController.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function start(uint256 bootstrappingPeriod) public onlyOwner {
        setBootstrappingPeriod(bootstrappingPeriod);
        setEpochStart();

        // advance
        Bonding.step(); // increments epoch
        Regulator.step(); // sets price
        Market.step();
        FeeController.step();

        dollar().permanentlyEnableFees();
        dollar().setFlatFee(Constants.getFlatFee());
        dollar().setFeePool(address(feePool()));

        emit Advance(epoch(), block.number, block.timestamp);
    }

    modifier incentivized {
        // Mint advance reward to sender
        uint256 incentive = getAdvanceIncentive();
        mintToAccount(msg.sender, incentive);
        emit Incentivization(msg.sender, incentive);
        _;
    }
}