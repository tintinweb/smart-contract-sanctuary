// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./libraries/AmountNormalization.sol";
import "./libraries/Deposit.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/Pool.sol";
import "./libraries/SafeERC20.sol";
import {Governed} from "./Governance.sol";
import {IERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

interface IDepositary {
    function deposit(uint256 poolId, uint256 amount) external;

    function withdraw(uint256 poolId, uint256 amount) external;
}

error BaksDAOMagisterAlreadyAdded(address magister);
error BaksDAOMagisterDontAdded(address magister);

contract Depositary is Initializable, Governed, IDepositary {
    using AmountNormalization for IERC20;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using SafeERC20 for IERC20;
    using Pool for Pool.Data;
    using Deposit for Deposit.Data;

    struct Magister {
        bool isActive;
        uint256 createdAt;
        address addr;
        uint256[] depositIds;
    }

    uint256 internal constant ONE = 100e16;

    uint256 public blocksPerYear;

    IERC20 public stablecoin;
    IERC20 public baksDaoVoice;
    IPriceOracle public priceOracle;

    mapping(address => Magister) internal magisters;
    EnumerableAddressSet.Set internal magistersSet;

    Pool.Data[] public pools;

    Deposit.Data[] public deposits;
    mapping(uint256 => mapping(address => uint256)) public depositIds;

    event MagisterAdded(address indexed magister);
    event MagisterRemoved(address indexed magister);

    function initialize(
        uint256 _blocksPerYear,
        IERC20 _stablecoin,
        IERC20 _baksDaoVoice,
        IPriceOracle _priceOracle
    ) external initializer {
        setGovernor(msg.sender);

        blocksPerYear = _blocksPerYear;
        stablecoin = _stablecoin;
        baksDaoVoice = _baksDaoVoice;
        priceOracle = _priceOracle;
    }

    function deposit(uint256 poolId, uint256 amount) external {
        deposit(poolId, amount, address(this));
    }

    function withdraw(uint256 poolId, uint256 amount) external {
        Pool.Data storage p = pools[poolId];
        Deposit.Data storage d = deposits[depositIds[poolId][msg.sender] - 1];

        (
            uint256 depositorReward,
            uint256 depositorBonusReward,
            uint256 magisterReward,
            uint256 magisterBonusReward
        ) = calculateRewards(d.id);

        if (d.magister != address(this)) {
            d.magisterAccruedRewards += magisterReward;
            d.magisterAccruedBonusRewards += magisterBonusReward;
        }
        d.depositorAccruedRewards += depositorReward;
        d.depositorAccruedBonusRewards += depositorBonusReward;

        if (msg.sender == d.magister) {
            stablecoin.safeTransfer(d.magister, d.magisterAccruedRewards);
            baksDaoVoice.safeTransfer(d.magister, d.magisterAccruedBonusRewards);

            d.magisterAccruedRewards -= amount;
            d.magisterAccruedBonusRewards = 0;
        } else {
            uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);

            p.depositToken.safeTransfer(d.depositor, amount);
            stablecoin.safeTransfer(d.depositor, d.depositorAccruedRewards);
            baksDaoVoice.safeTransfer(d.depositor, d.depositorAccruedBonusRewards);

            d.principal -= normalizedAmount;
            d.depositorAccruedRewards = 0;
            d.depositorAccruedBonusRewards = 0;
            d.lastDepositBlock = block.number;
        }

        d.lastInteractionBlock = block.number;
        if (d.principal == 0) {
            d.isActive = false;
            depositIds[poolId][msg.sender] = 0;
        }
    }

    function addMagister(address magister) external onlyGovernor {
        if (magistersSet.contains(magister)) {
            revert BaksDAOMagisterAlreadyAdded(magister);
        }

        if (magistersSet.add(magister)) {
            Magister storage m = magisters[magister];
            m.addr = magister;
            if (m.createdAt == 0) {
                m.createdAt = block.timestamp;
            }
            m.isActive = true;

            emit MagisterAdded(magister);
        }
    }

    function removeMagister(address magister) external onlyGovernor {
        if (!magistersSet.contains(magister)) {
            revert BaksDAOMagisterAlreadyAdded(magister);
        }

        if (magistersSet.remove(magister)) {
            magisters[magister].isActive = false;
            emit MagisterRemoved(magister);
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

    function updatePool(
        uint256 poolId,
        bool isCompounding,
        uint256 depositorApr,
        uint256 magisterApr,
        uint256 depositorBonusApr,
        uint256 magisterBonusApr
    ) external onlyGovernor {
        Pool.Data storage p = pools[poolId];

        p.isCompounding = isCompounding;
        p.depositorApr = depositorApr;
        p.magisterApr = magisterApr;
        p.depositorBonusApr = depositorBonusApr;
        p.magisterBonusApr = magisterBonusApr;
    }

    function getActiveMagisters() external view returns (Magister[] memory activeMagisters) {
        uint256 length = magistersSet.elements.length;
        activeMagisters = new Magister[](length);

        for (uint256 i = 0; i < length; i++) {
            activeMagisters[i] = magisters[magistersSet.elements[i]];
        }
    }

    function deposit(
        uint256 poolId,
        uint256 amount,
        address magister
    ) public {
        if (magister == msg.sender || !(magister == address(this) || magisters[magister].isActive)) {
            revert BaksDAOMagisterDontAdded(magister);
        }

        Pool.Data storage p = pools[poolId];
        p.depositToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);
        if (depositIds[poolId][msg.sender] == 0) {
            uint256 id = deposits.length + 1;
            deposits.push(
                Deposit.Data({
                    id: id,
                    isActive: true,
                    magister: magister,
                    depositor: msg.sender,
                    poolId: poolId,
                    principal: normalizedAmount,
                    depositorAccruedRewards: 0,
                    depositorAccruedBonusRewards: 0,
                    magisterAccruedRewards: 0,
                    magisterAccruedBonusRewards: 0,
                    lastDepositBlock: block.number,
                    lastInteractionBlock: block.number
                })
            );
            depositIds[poolId][msg.sender] = id;
            if (magister != address(this)) {
                magisters[magister].depositIds.push(id);
            }
            return;
        }

        Deposit.Data storage d = deposits[depositIds[poolId][msg.sender] - 1];
        (
            uint256 depositorReward,
            uint256 depositorBonusReward,
            uint256 magisterReward,
            uint256 magisterBonusReward
        ) = calculateRewards(d.id);

        if (d.magister != address(this)) {
            d.magisterAccruedRewards += magisterReward;
            d.magisterAccruedBonusRewards += magisterBonusReward;
        }
        d.depositorAccruedRewards += depositorReward;
        d.depositorAccruedBonusRewards += depositorBonusReward;

        stablecoin.safeTransfer(d.depositor, d.depositorAccruedRewards);
        baksDaoVoice.safeTransfer(d.depositor, d.depositorAccruedBonusRewards);

        d.principal += normalizedAmount;
        d.depositorAccruedRewards = 0;
        d.depositorAccruedBonusRewards = 0;
        d.lastDepositBlock = block.number;
        d.lastInteractionBlock = block.number;
    }

    function calculateRewards(uint256 depositId)
        public
        view
        returns (
            uint256 depositorReward,
            uint256 depositorBonusReward,
            uint256 magisterReward,
            uint256 magisterBonusReward
        )
    {
        Deposit.Data memory d = deposits[depositId - 1];
        Pool.Data memory p = pools[d.poolId];

        uint256 depositTokenPrice = p.depositToken == stablecoin ? ONE : priceOracle.getNormalizedPrice(p.depositToken);
        uint256 totalRewards = d
            .principal
            .mul(p.calculateMultiplier((block.number - d.lastInteractionBlock).mulDiv(ONE, blocksPerYear)))
            .mul(depositTokenPrice);

        uint256 totalApr = p.getTotalApr();
        depositorReward = totalRewards.mulDiv(p.depositorApr, totalApr);
        magisterReward = totalRewards.mulDiv(p.magisterApr, totalApr);

        try priceOracle.getNormalizedPrice(baksDaoVoice) returns (uint256 baksDaoVoicePrice) {
            depositorBonusReward = totalRewards.mulDiv(p.depositorBonusApr.mul(baksDaoVoicePrice), totalApr);
            magisterBonusReward = totalRewards.mulDiv(p.magisterBonusApr.mul(baksDaoVoicePrice), totalApr);
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
        uint256 depositorAccruedRewards;
        uint256 depositorAccruedBonusRewards;
        uint256 magisterAccruedRewards;
        uint256 magisterAccruedBonusRewards;
        uint256 lastDepositBlock;
        uint256 lastInteractionBlock;
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

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

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

    function getDepositsValue(Data memory self) internal view returns (uint256 depositsValue) {
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
        }
    }

    function getTotalApr(Data memory self) internal pure returns (uint256 totalApr) {
        totalApr = self.depositorApr + self.magisterApr + self.depositorBonusApr + self.magisterBonusApr;
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