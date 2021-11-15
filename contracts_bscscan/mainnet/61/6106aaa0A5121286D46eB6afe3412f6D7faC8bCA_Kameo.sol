// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

error GovernedOnlyGovernorAllowedToCall();

error GovernedOnlyGovernorOrManagerAllowedToCall();

error GovernedOnlyPendingGovernorAllowedToCall();

error GovernedGovernorZeroAddress();

error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    address public manager;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    event ManagementTransited(address indexed manager, address indexed newManager);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    modifier onlyGovernorOrManager() {
        if (!(msg.sender == governor || msg.sender == manager)) {
            revert GovernedOnlyGovernorOrManagerAllowedToCall();
        }
        _;
    }

    constructor(address _manager) {
        governor = msg.sender;
        manager = _manager;
        emit PendingGovernanceTransition(address(0), governor);
        emit GovernanceTransited(address(0), governor);
        emit ManagementTransited(address(0), _manager);
    }

    function transitGovernance(address newGovernor) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        emit PendingGovernanceTransition(governor, newGovernor);
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function transitManagement(address newManager) external onlyGovernor {
        manager = newManager;
        emit ManagementTransited(manager, newManager);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./interfaces/ISyrupPool.sol";
import "./interfaces/PancakeSwap.sol";
import "./libraries/AmountNormalization.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeBEP20.sol";
import "./Governance.sol";

error KameoSyrupPoolAlreadyAdded(ISyrupPool syrupPool);

error KameoSyrupPoolIsNotAdded(ISyrupPool syrupPool);

error KameoWrongStakedToken(IBEP20 stakedToken);

contract Kameo is Governed, ReentrancyGuard {
    using AmountNormalization for IBEP20;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 internal constant ONE = 100e16;
    uint256 internal constant BLOCKS_PER_YEAR = 10512000;

    IPancakeSwapRouter public immutable pancakeSwapRouter;
    IBEP20 public immutable wrappedNativeCurrency;
    IBEP20 public immutable stakedToken;

    uint256 public slippageTolerance = 5e15; // 0.5 %
    uint256 public swapDeadline = 20 minutes;

    EnumerableAddressSet.Set internal syrupPools;

    event Stake(ISyrupPool indexed syrupPool, uint256 amount);
    event Harvest(ISyrupPool indexed syrupPool, uint256 amount);
    event Unstake(ISyrupPool indexed syrupPool, uint256 amount);
    event Withdrawal(uint256 amount);

    event SyrupPoolAdded(ISyrupPool indexed syrupPool);
    event SyrupPoolRemoved(ISyrupPool indexed syrupPool);

    event SlippageToleranceUpdated(uint256 slippageTolerance, uint256 newSlippageTolerance);
    event SwapDeadlineUpdated(uint256 swapDeadline, uint256 newSwapDeadline);

    modifier syrupPoolAdded(ISyrupPool syrupPool) {
        if (!syrupPools.contains(address(syrupPool))) {
            revert KameoSyrupPoolIsNotAdded(syrupPool);
        }
        _;
    }

    constructor(
        IPancakeSwapRouter _pancakeSwapRouter,
        IBEP20 _wrappedNativeCurrency,
        IBEP20 _stakedToken,
        address _manager
    ) Governed(_manager) {
        pancakeSwapRouter = _pancakeSwapRouter;
        wrappedNativeCurrency = _wrappedNativeCurrency;
        stakedToken = _stakedToken;
    }

    function harvest(ISyrupPool syrupPool) external onlyGovernorOrManager {
        syrupPool.withdraw(0);
        uint256 liquifiedAmount = liquify(syrupPool);
        if (liquifiedAmount > 0) {
            stake(syrupPool, liquifiedAmount);
        }
    }

    function unstake(ISyrupPool syrupPool, uint256 amount) external onlyGovernorOrManager {
        syrupPool.withdraw(amount);
        liquify(syrupPool);
        emit Unstake(syrupPool, amount);
    }

    function withdraw(uint256 amount) external onlyGovernor {
        stakedToken.safeTransfer(msg.sender, amount);
        emit Withdrawal(amount);
    }

    function addSyrupPool(ISyrupPool syrupPool) external onlyGovernor {
        address syrupPoolAddress = address(syrupPool);

        if (syrupPools.contains(syrupPoolAddress)) {
            revert KameoSyrupPoolAlreadyAdded(syrupPool);
        }

        if (syrupPool.stakedToken() != stakedToken) {
            revert KameoWrongStakedToken(syrupPool.stakedToken());
        }

        if (syrupPools.add(syrupPoolAddress)) {
            syrupPool.stakedToken().approve(syrupPoolAddress, type(uint256).max);
            syrupPool.rewardToken().approve(address(pancakeSwapRouter), type(uint256).max);

            emit SyrupPoolAdded(syrupPool);
        }
    }

    function removeSyrupPool(ISyrupPool syrupPool) external onlyGovernor syrupPoolAdded(syrupPool) {
        address syrupPoolAddress = address(syrupPool);
        if (syrupPools.remove(syrupPoolAddress)) {
            syrupPool.stakedToken().approve(syrupPoolAddress, 0);
            syrupPool.rewardToken().approve(address(pancakeSwapRouter), 0);

            emit SyrupPoolRemoved(syrupPool);
        }
    }

    function setSlippageTolerance(uint256 newSlippageTolerance) external onlyGovernor {
        emit SlippageToleranceUpdated(slippageTolerance, newSlippageTolerance);
        slippageTolerance = newSlippageTolerance;
    }

    function setSwapDeadline(uint256 newSwapDeadline) external onlyGovernor {
        emit SwapDeadlineUpdated(swapDeadline, newSwapDeadline);
        swapDeadline = newSwapDeadline;
    }

    function getSyrupPools() external view returns (address[] memory) {
        return syrupPools.elements;
    }

    function getStakedAmount(ISyrupPool syrupPool) external view returns (uint256 stakedAmount) {
        (stakedAmount, ) = syrupPool.userInfo(address(this));
    }

    function getPendingRewardsInStakedToken(ISyrupPool syrupPool)
        external
        view
        returns (uint256 pendingRewardsInStakedToken)
    {
        uint256 pendingRewards = getPendingRewards(syrupPool);

        address[] memory path = new address[](3);
        path[0] = address(syrupPool.rewardToken());
        path[1] = address(wrappedNativeCurrency);
        path[2] = address(syrupPool.stakedToken());

        uint256[] memory amounts = pancakeSwapRouter.getAmountsOut(pendingRewards, path);
        pendingRewardsInStakedToken = amounts[amounts.length - 1];
    }

    function calculateSyrupPoolApr(ISyrupPool syrupPool) external view returns (uint256 apr) {
        uint256 stakedAmount = syrupPool.stakedToken().normalizeAmount(
            syrupPool.stakedToken().balanceOf(address(syrupPool))
        );
        uint256 annualizedRewards = syrupPool.rewardPerBlock() * BLOCKS_PER_YEAR;

        IPancakeSwapPair rewardTokenWrappedNativeCurrencyPair = pancakeSwapRouter.factory().getPair(
            syrupPool.rewardToken(),
            wrappedNativeCurrency
        );
        IPancakeSwapPair stakedTokenWrappedNativeCurrencyPair = pancakeSwapRouter.factory().getPair(
            syrupPool.stakedToken(),
            wrappedNativeCurrency
        );

        (uint256 reserveA, uint256 reserveB, ) = rewardTokenWrappedNativeCurrencyPair.getReserves();
        uint256 wrappedNativeCurrencyAmount = address(wrappedNativeCurrency) < address(syrupPool.rewardToken())
            ? pancakeSwapRouter.quote(annualizedRewards, reserveB, reserveA)
            : pancakeSwapRouter.quote(annualizedRewards, reserveA, reserveB);

        (reserveA, reserveB, ) = stakedTokenWrappedNativeCurrencyPair.getReserves();
        annualizedRewards = syrupPool.stakedToken().normalizeAmount(
            address(wrappedNativeCurrency) < address(syrupPool.stakedToken())
                ? pancakeSwapRouter.quote(wrappedNativeCurrencyAmount, reserveA, reserveB)
                : pancakeSwapRouter.quote(wrappedNativeCurrencyAmount, reserveB, reserveA)
        );

        apr = annualizedRewards.div(stakedAmount);
    }

    function stake(ISyrupPool syrupPool, uint256 amount) public onlyGovernorOrManager syrupPoolAdded(syrupPool) {
        syrupPool.deposit(amount);
        emit Stake(syrupPool, amount);
    }

    function liquify(ISyrupPool syrupPool) public onlyGovernorOrManager returns (uint256 liquifiedAmount) {
        uint256 rewardTokenBalance = syrupPool.rewardToken().balanceOf(address(this));
        if (rewardTokenBalance > 0) {
            address[] memory path = new address[](3);
            path[0] = address(syrupPool.rewardToken());
            path[1] = address(wrappedNativeCurrency);
            path[2] = address(syrupPool.stakedToken());

            uint256[] memory amounts = pancakeSwapRouter.getAmountsOut(rewardTokenBalance, path);
            uint256 normalizedAmountOut = stakedToken.normalizeAmount(amounts[amounts.length - 1]);

            amounts = pancakeSwapRouter.swapExactTokensForTokens(
                rewardTokenBalance,
                stakedToken.denormalizeAmount(normalizedAmountOut.mul(ONE - slippageTolerance)),
                path,
                address(this),
                block.timestamp + swapDeadline
            );
            liquifiedAmount = amounts[amounts.length - 1];
            emit Harvest(syrupPool, amounts[amounts.length - 1]);
        }
    }

    function getPendingRewards(ISyrupPool syrupPool) public view returns (uint256 pendingRewards) {
        pendingRewards = syrupPool.pendingReward(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IBEP20 {
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

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IBEP20.sol";

interface ISyrupPool {
    function deposit(uint256 amount) external;

    function emergencyWithdraw() external;

    function withdraw(uint256 amount) external;

    function accTokenPerShare() external view returns (uint256);

    function bonusEndBlock() external view returns (uint256);

    function lastRewardBlock() external view returns (uint256);

    function pendingReward(address user) external view returns (uint256);

    function poolLimitPerUser() external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function rewardToken() external view returns (IBEP20);

    function stakedToken() external view returns (IBEP20);

    function startBlock() external view returns (uint256);

    function userInfo(address user) external view returns (uint256 amount, uint256 rewardDebt);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IBEP20.sol";

interface IPancakeSwapPair is IBEP20 {
    function token0() external view returns (IBEP20);

    function token1() external view returns (IBEP20);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IPancakeSwapFactory {
    function getPair(IBEP20 tokenA, IBEP20 tokenB) external view returns (IPancakeSwapPair pair);
}

interface IPancakeSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function factory() external view returns (IPancakeSwapFactory factory);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./../interfaces/IBEP20.sol";

library AmountNormalization {
    uint8 internal constant DECIMALS = 18;

    function normalizeAmount(IBEP20 self, uint256 denormalizedAmount) internal view returns (uint256 normalizedAmount) {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return denormalizedAmount * scale;
        }
        return denormalizedAmount;
    }

    function denormalizeAmount(IBEP20 self, uint256 normalizedAmount)
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

error ReentrancyGuardReentrantCall();

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private status;

    modifier nonReentrant() {
        if (status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }

    constructor() {
        status = NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./../interfaces/IBEP20.sol";
import "./Address.sol";

error SafeBEP20NoReturnData();

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IBEP20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeBEP20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeBEP20NoReturnData();
            }
        }
    }
}

