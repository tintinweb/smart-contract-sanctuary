// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./libraries/AmountNormalization.sol";
import "./libraries/Deposit.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/Magister.sol";
import "./libraries/Pool.sol";
import "./libraries/SafeERC20.sol";
import {Governed} from "./Governance.sol";
import {IERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

error BaksDAOMagisterAlreadyWhitelisted(address magister);
error BaksDAOMagisterBlacklisted(address magister);
error BaksDAOOnlyDepositorOrMagisterAllowed();
error BaksDAOWithdrawAmountExceedsPrincipal();
error BaksDAOWithdrawAmountExceedsAccruedRewards();

contract Depositary is Initializable, Governed {
    using AmountNormalization for IERC20;
    using Deposit for Deposit.Data;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using Magister for Magister.Data;
    using Pool for Pool.Data;
    using SafeERC20 for IERC20;

    uint256 internal constant ONE = 100e16;

    IPriceOracle public priceOracle;
    IERC20 public stablecoin;
    IERC20 public bonusToken;

    // TODO: Add `set` functions and events
    uint256 public earlyWithdrawalPeriod;
    uint256 public earlyWithdrawalFee;

    mapping(address => Magister.Data) public magisters;
    EnumerableAddressSet.Set internal magistersSet;

    Pool.Data[] public pools;

    Deposit.Data[] public deposits;
    mapping(uint256 => mapping(address => uint256)) public currentDepositIds;

    event MagisterWhitelisted(address indexed magister);
    event MagisterBlacklisted(address indexed magister);

    function initialize(
        IERC20 _stablecoin,
        IERC20 _bonusToken,
        IPriceOracle _priceOracle
    ) external initializer {
        setGovernor(msg.sender);

        earlyWithdrawalPeriod = 72 hours;
        earlyWithdrawalFee = 1e15; // 0,1 %

        stablecoin = _stablecoin;
        bonusToken = _bonusToken;
        priceOracle = _priceOracle;

        // Add guard pool and deposit
        deposits.push(
            Deposit.Data({
                id: 0,
                isActive: false,
                depositor: address(0),
                magister: address(0),
                poolId: 0,
                principal: 0,
                depositorTotalAccruedRewards: 0,
                depositorWithdrawnRewards: 0,
                magisterTotalAccruedRewards: 0,
                magisterWithdrawnRewards: 0,
                createdAt: block.timestamp,
                lastDepositAt: block.timestamp,
                lastInteractionAt: block.timestamp,
                closedAt: block.timestamp
            })
        );

        pools.push(
            Pool.Data({
                id: 0,
                depositToken: IERC20(address(0)),
                priceOracle: priceOracle,
                isCompounding: false,
                depositsAmount: 0,
                depositorApr: 0,
                magisterApr: 0,
                depositorBonusApr: 0,
                magisterBonusApr: 0
            })
        );
    }

    function deposit(uint256 poolId, uint256 amount) external {
        deposit(poolId, amount, address(this));
    }

    function withdraw(uint256 depositId, uint256 amount) external {
        Deposit.Data storage d = deposits[depositId];
        Pool.Data storage p = pools[d.poolId];

        if (!(msg.sender == d.depositor || msg.sender == d.magister)) {
            revert BaksDAOOnlyDepositorOrMagisterAllowed();
        }

        uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);

        accrueRewards(d.id);
        (
            uint256 depositorReward,
            uint256 depositorBonusReward,
            uint256 magisterReward,
            uint256 magisterBonusReward
        ) = splitRewards(d.poolId, d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards, normalizedAmount);

        if (msg.sender == d.magister) {
            if (normalizedAmount > d.magisterTotalAccruedRewards - d.magisterWithdrawnRewards) {
                revert BaksDAOWithdrawAmountExceedsAccruedRewards();
            }
            stablecoin.safeTransfer(d.magister, magisterReward);
            bonusToken.safeTransfer(d.magister, magisterBonusReward);

            d.magisterWithdrawnRewards += normalizedAmount;
        } else {
            uint256 a = normalizedAmount;
            if (a > d.principal) {
                revert BaksDAOWithdrawAmountExceedsPrincipal();
            }

            if (p.isCompounding && block.timestamp < d.lastDepositAt + earlyWithdrawalPeriod) {
                a = a.mul(ONE - earlyWithdrawalFee);
            }

            p.depositToken.safeTransfer(d.depositor, a);
            stablecoin.safeTransfer(d.depositor, depositorReward);
            bonusToken.safeTransfer(d.depositor, depositorBonusReward);

            p.depositsAmount -= a;
            d.principal -= normalizedAmount;
            d.depositorWithdrawnRewards += d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
        }

        d.lastInteractionAt = block.timestamp;
        if (d.principal == 0) {
            d.isActive = false;
            d.closedAt = block.timestamp;
            currentDepositIds[d.poolId][msg.sender] = 0;
        }
    }

    function whitelistMagister(address magister) external onlyGovernor {
        if (magistersSet.contains(magister)) {
            revert BaksDAOMagisterAlreadyWhitelisted(magister);
        }

        if (magistersSet.add(magister)) {
            Magister.Data storage m = magisters[magister];
            m.addr = magister;
            if (m.createdAt == 0) {
                m.createdAt = block.timestamp;
            }
            m.isActive = true;

            emit MagisterWhitelisted(magister);
        }
    }

    function blacklistMagister(address magister) external onlyGovernor {
        if (!magistersSet.contains(magister)) {
            revert BaksDAOMagisterBlacklisted(magister);
        }

        if (magistersSet.remove(magister)) {
            magisters[magister].isActive = false;
            emit MagisterBlacklisted(magister);
        }
    }

    function addPool(
        IERC20 depositToken,
        bool isCompounding,
        uint256 depositorApr,
        uint256 magisterApr,
        uint256 depositorBonusApr,
        uint256 magisterBonusApr
    ) external onlyGovernor {
        uint256 poolId = pools.length;
        pools.push(
            Pool.Data({
                id: poolId,
                depositToken: depositToken,
                priceOracle: priceOracle,
                isCompounding: isCompounding,
                depositsAmount: 0,
                depositorApr: depositorApr,
                magisterApr: magisterApr,
                depositorBonusApr: depositorBonusApr,
                magisterBonusApr: magisterBonusApr
            })
        );
    }

    function getActiveMagisters() external view returns (Magister.Data[] memory activeMagisters) {
        uint256 length = magistersSet.elements.length;
        activeMagisters = new Magister.Data[](length);

        for (uint256 i = 0; i < length; i++) {
            activeMagisters[i] = magisters[magistersSet.elements[i]];
        }
    }

    function getMagisterDepositIds(address magister) external view returns (uint256[] memory) {
        return magisters[magister].depositIds;
    }

    function getTotalValueLocked() external view returns (uint256 totalValueLocked) {
        for (uint256 i = 0; i < pools.length; i++) {
            totalValueLocked += pools[i].getDepositsValue();
        }
    }

    function deposit(
        uint256 poolId,
        uint256 amount,
        address magister
    ) public {
        if (magister == msg.sender || !(magister == address(this) || magisters[magister].isActive)) {
            revert BaksDAOMagisterBlacklisted(magister);
        }

        Pool.Data storage p = pools[poolId];
        p.depositToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);
        p.depositsAmount += normalizedAmount;

        if (currentDepositIds[poolId][msg.sender] == 0) {
            uint256 id = deposits.length;
            deposits.push(
                Deposit.Data({
                    id: id,
                    isActive: true,
                    magister: magister,
                    depositor: msg.sender,
                    poolId: poolId,
                    principal: normalizedAmount,
                    depositorTotalAccruedRewards: 0,
                    depositorWithdrawnRewards: 0,
                    magisterTotalAccruedRewards: 0,
                    magisterWithdrawnRewards: 0,
                    createdAt: block.timestamp,
                    lastDepositAt: block.timestamp,
                    lastInteractionAt: block.timestamp,
                    closedAt: 0
                })
            );

            currentDepositIds[poolId][msg.sender] = id;
            if (magister != address(this)) {
                magisters[magister].depositIds.push(id);
            }
        } else {
            Deposit.Data storage d = deposits[currentDepositIds[poolId][msg.sender]];
            accrueRewards(d.id);

            uint256 r = d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
            (uint256 depositorRewards, uint256 depositorBonusRewards, , ) = splitRewards(d.poolId, r, 0);
            stablecoin.safeTransfer(d.depositor, depositorRewards);
            bonusToken.safeTransfer(d.depositor, depositorBonusRewards);

            d.principal += normalizedAmount;
            d.depositorWithdrawnRewards += r;
            d.lastDepositAt = block.timestamp;
            d.lastInteractionAt = block.timestamp;
        }
    }

    function getRewards(uint256 depositId) public view returns (uint256 depositorRewards, uint256 magisterRewards) {
        Deposit.Data memory d = deposits[depositId];

        (uint256 dr, uint256 mr) = calculateRewards(depositId);
        depositorRewards = dr + d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
        magisterRewards = mr + d.magisterTotalAccruedRewards - d.magisterWithdrawnRewards;
    }

    function accrueRewards(uint256 depositId) internal {
        (uint256 depositorRewards, uint256 magisterRewards) = calculateRewards(depositId);

        Deposit.Data storage d = deposits[depositId];
        if (d.magister != address(this) && magisters[d.magister].isActive) {
            d.magisterTotalAccruedRewards += magisterRewards;
            magisters[d.magister].totalIncome += magisterRewards;
        }

        d.depositorTotalAccruedRewards += depositorRewards;
        if (magisters[msg.sender].isActive) {
            magisters[d.magister].totalIncome += depositorRewards;
        }
    }

    function calculateRewards(uint256 depositId)
        internal
        view
        returns (uint256 depositorRewards, uint256 magisterRewards)
    {
        Deposit.Data memory d = deposits[depositId];
        Pool.Data memory p = pools[d.poolId];

        uint256 totalRewards = d.principal.mul(
            p.calculateMultiplier((block.timestamp - d.lastInteractionAt).mulDiv(ONE, 365 days))
        );
        uint256 totalApr = p.getTotalApr();

        depositorRewards = totalRewards.mulDiv(p.getDepositorApr(), totalApr);
        magisterRewards = totalRewards.mulDiv(p.getMagisterApr(), totalApr);
    }

    function splitRewards(
        uint256 poolId,
        uint256 _depositorRewards,
        uint256 _magisterRewards
    )
        internal
        view
        returns (
            uint256 depositorRewards,
            uint256 depositorBonusRewards,
            uint256 magisterRewards,
            uint256 magisterBonusRewards
        )
    {
        Pool.Data memory p = pools[poolId];

        uint256 depositorTotalApr = p.getDepositorApr();
        uint256 magisterTotalApr = p.getMagisterApr();
        uint256 depositTokenPrice = p.depositToken == stablecoin ? ONE : priceOracle.getNormalizedPrice(p.depositToken);

        uint256 depositorAccruedRewards = _depositorRewards.mul(depositTokenPrice);
        uint256 magisterAccruedRewards = _magisterRewards.mul(depositTokenPrice);

        depositorRewards = depositorAccruedRewards.mulDiv(p.depositorApr, depositorTotalApr);
        magisterRewards = magisterAccruedRewards.mulDiv(p.magisterApr, magisterTotalApr);

        try priceOracle.getNormalizedPrice(bonusToken) returns (uint256 bonusTokenPrice) {
            depositorBonusRewards = depositorAccruedRewards.mulDiv(
                p.depositorBonusApr.mul(bonusTokenPrice),
                depositorTotalApr
            );
            magisterBonusRewards = magisterAccruedRewards.mulDiv(
                p.magisterBonusApr.mul(bonusTokenPrice),
                magisterTotalApr
            );
        } catch {}
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";
import "./../libraries/FixedPointMath.sol";

/// @notice Thrown when oracle doesn't provide price for `token` token.
/// @param token The address of the token contract.
error PriceOracleTokenUnknown(IERC20 token);
/// @notice Thrown when oracle provide stale price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleStalePrice(IERC20 token, uint256 price);
/// @notice Thrown when oracle provide negative, zero or in other ways invalid price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleInvalidPrice(IERC20 token, int256 price);

interface IPriceOracle {
    /// @notice Gets normalized to 18 decimals price for the `token` token.
    /// @param token The address of the token contract.
    /// @return normalizedPrice Normalized price.
    function getNormalizedPrice(IERC20 token) external view returns (uint256 normalizedPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";

library AmountNormalization {
    uint8 internal constant DECIMALS = 18;

    function normalizeAmount(IERC20 self, uint256 denormalizedAmount) internal view returns (uint256 normalizedAmount) {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return denormalizedAmount * scale;
        }
        return denormalizedAmount;
    }

    function denormalizeAmount(IERC20 self, uint256 normalizedAmount)
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return normalizedAmount / scale;
        }
        return normalizedAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Deposit {
    using FixedPointMath for uint256;

    struct Data {
        uint256 id;
        bool isActive;
        address depositor;
        address magister;
        uint256 poolId;
        uint256 principal;
        uint256 depositorTotalAccruedRewards;
        uint256 depositorWithdrawnRewards;
        uint256 magisterTotalAccruedRewards;
        uint256 magisterWithdrawnRewards;
        uint256 createdAt;
        uint256 lastDepositAt;
        uint256 lastInteractionAt;
        uint256 closedAt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library EnumerableAddressSet {
    struct Set {
        address[] elements;
        mapping(address => uint256) indexes;
    }

    function add(Set storage self, address element) internal returns (bool) {
        if (contains(self, element)) {
            return false;
        }

        self.elements.push(element);
        self.indexes[element] = self.elements.length;

        return true;
    }

    function remove(Set storage self, address element) internal returns (bool) {
        uint256 elementIndex = indexOf(self, element);
        if (elementIndex == 0) {
            return false;
        }

        uint256 indexToRemove = elementIndex - 1;
        uint256 lastIndex = count(self) - 1;
        if (indexToRemove != lastIndex) {
            address lastElement = self.elements[lastIndex];
            self.elements[indexToRemove] = lastElement;
            self.indexes[lastElement] = elementIndex;
        }
        self.elements.pop();
        delete self.indexes[element];

        return true;
    }

    function indexOf(Set storage self, address element) internal view returns (uint256) {
        return self.indexes[element];
    }

    function contains(Set storage self, address element) internal view returns (bool) {
        return indexOf(self, element) != 0;
    }

    function count(Set storage self) internal view returns (uint256) {
        return self.elements.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    uint256 internal constant HALF_SCALE = 5e17;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;
    uint256 internal constant LOG2_E = 1_442695040888963407;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp(uint256 x) internal pure returns (uint256 result) {
        if (x >= 133_084258667509499441) {
            revert FixedPointMathExpArgumentTooBig(x);
        }

        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Magister {
    using FixedPointMath for uint256;

    struct Data {
        bool isActive;
        uint256 createdAt;
        address addr;
        uint256 totalIncome;
        uint256[] depositIds;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./Deposit.sol";
import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Pool {
    using FixedPointMath for uint256;

    struct Data {
        uint256 id;
        IERC20 depositToken;
        IPriceOracle priceOracle;
        bool isCompounding;
        uint256 depositsAmount;
        uint256 depositorApr;
        uint256 magisterApr;
        uint256 depositorBonusApr;
        uint256 magisterBonusApr;
    }

    uint256 internal constant ONE = 100e16;

    function getDepositsValue(Data memory self) internal view returns (uint256 depositsValue) {
        if (self.depositsAmount == 0) {
            return 0;
        }

        uint256 depositTokenPrice = self.priceOracle.getNormalizedPrice(self.depositToken);
        depositsValue = self.depositsAmount.mul(depositTokenPrice);
    }

    function calculateMultiplier(Data memory self, uint256 partOfYearDeposited)
        internal
        pure
        returns (uint256 multiplier)
    {
        uint256 totalApr = getTotalApr(self);
        if (!self.isCompounding) {
            multiplier = totalApr.mul(partOfYearDeposited);
        } else {
            multiplier = FixedPointMath.exp(totalApr.mul(partOfYearDeposited)) - ONE;
        }
    }

    function getDepositorApr(Data memory self) internal pure returns (uint256 depositorApr) {
        depositorApr = self.depositorApr + self.depositorBonusApr;
    }

    function getMagisterApr(Data memory self) internal pure returns (uint256 magisterApr) {
        magisterApr = self.magisterApr + self.magisterBonusApr;
    }

    function getTotalApr(Data memory self) internal pure returns (uint256 totalApr) {
        totalApr = getDepositorApr(self) + getMagisterApr(self);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";
import "./Address.sol";

error SafeERC20NoReturnData();

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IERC20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeERC20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeERC20NoReturnData();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Address.sol";

error EIP1967ImplementationIsNotContract(address implementation);
error ContractAlreadyInitialized();
error OnlyProxyCallAllowed();
error OnlyCurrentImplementationAllowed();

library EIP1967 {
    using Address for address;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed newImplementation);

    function upgradeTo(address newImplementation) internal {
        if (!newImplementation.isContract()) {
            revert EIP1967ImplementationIsNotContract(newImplementation);
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);
    }

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Proxy {
    using Address for address;

    constructor(address implementation, bytes memory data) {
        EIP1967.upgradeTo(implementation);
        implementation.delegateCall(data, "Proxy: construction failed");
    }

    receive() external payable {
        delegateCall();
    }

    fallback() external payable {
        delegateCall();
    }

    function delegateCall() internal {
        address implementation = EIP1967.getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

abstract contract Upgradeable {
    address private immutable self = address(this);

    modifier onlyProxy() {
        if (address(this) == self) {
            revert OnlyProxyCallAllowed();
        }
        if (EIP1967.getImplementation() != self) {
            revert OnlyCurrentImplementationAllowed();
        }
        _;
    }

    function upgradeTo(address newImplementation) public virtual onlyProxy {
        EIP1967.upgradeTo(newImplementation);
    }
}

abstract contract Initializable {
    bool private initializing;
    bool private initialized;

    modifier initializer() {
        if (!initializing && initialized) {
            revert ContractAlreadyInitialized();
        }

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
}