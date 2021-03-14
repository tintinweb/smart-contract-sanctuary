/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
// License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

// File @sushiswap/bentobox-sdk/contracts/[email protected]
// License-Identifier: MIT

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// File @sushiswap/bentobox-sdk/contracts/[email protected]
// License-Identifier: MIT

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// File @sushiswap/bentobox-sdk/contracts/[email protected]
// License-Identifier: MIT

interface IStrategy {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// File @sushiswap/bentobox-sdk/contracts/[email protected]
// License-Identifier: MIT

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// File contracts/interfaces/IOracle.sol
// License-Identifier: MIT

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}
struct AccrueInfo {
    uint64 interestPerSecond;
    uint64 lastAccrued;
    uint128 feesEarnedFraction;
}

interface IKashiPair {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function accrue() external;
    function accrueInfo() external view returns (AccrueInfo memory info);
    function addAsset(address to, bool skim, uint256 share) external returns (uint256 fraction);
    function addCollateral(address to, bool skim, uint256 share) external;
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function asset() external view returns (IERC20);
    function balanceOf(address) external view returns (uint256);
    function bentoBox() external view returns (IBentoBoxV1);
    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);
    function claimOwnership() external;
    function collateral() external view returns (IERC20);
    function cook(uint8[] calldata actions, uint256[] calldata values, bytes[] calldata datas) external payable returns (uint256 value1, uint256 value2);
    function decimals() external view returns (uint8);
    function exchangeRate() external view returns (uint256);
    function feeTo() external view returns (address);
    function getInitData(IERC20 collateral_, IERC20 asset_, address oracle_, bytes calldata oracleData_) external pure returns (bytes memory data);
    function init(bytes calldata data) external payable;
    function isSolvent(address user, bool open) external view returns (bool);
    function liquidate(address[] calldata users, uint256[] calldata borrowParts, address to, address swapper, bool open) external;
    function masterContract() external view returns (address);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function oracle() external view returns (IOracle);
    function oracleData() external view returns (bytes memory);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function removeAsset(address to, uint256 fraction) external returns (uint256 share);
    function removeCollateral(address to, uint256 share) external;
    function repay(address to, bool skim, uint256 part) external returns (uint256 amount);
    function setFeeTo(address newFeeTo) external;
    function setSwapper(address swapper, bool enable) external;
    function swappers(address) external view returns (bool);
    function symbol() external view returns (string memory);
    function totalAsset() external view returns (Rebase memory total);
    function totalBorrow() external view returns (Rebase memory total);
    function totalCollateralShare() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function updateExchangeRate() external returns (bool updated, uint256 rate);
    function userBorrowPart(address) external view returns (uint256);
    function userCollateralShare(address) external view returns (uint256);
    function withdrawFees() external;
}

/// @dev This contract provides useful helper functions for `KashiPair`.
contract KashiPairHelper {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    uint256 public constant APY_PRECISION = 1e8;
    uint256 private constant PROTOCOL_FEE_LEFTOVER = 90000; // 100% - 10%
    uint256 private constant PROTOCOL_FEE_DIVISOR = 1e5;

    /// @dev Helper function to calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    function getCollateralSharesForBorrowPart(IKashiPair kashiPair, uint256 borrowPart) public view returns (uint256) {
        // Taken from KashiPair
        uint256 EXCHANGE_RATE_PRECISION = 1e18;
        uint256 LIQUIDATION_MULTIPLIER = 112000; // add 12%
        uint256 LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

        Rebase memory totalBorrow = kashiPair.totalBorrow();
        uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);

        return
            kashiPair.bentoBox().toShare(
                kashiPair.collateral(),
                borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(kashiPair.exchangeRate()) /
                    (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                false
            );
    }

    struct KashiPairInfo {
        IERC20 collateral;
        string collateralSymbol;
        uint8 collateralDecimals;
        IERC20 asset;
        string assetSymbol;
        uint8 assetDecimals;
        IOracle oracle;
        bytes oracleData;
    }

    function getPairs(IKashiPair[] calldata addresses) public view returns (KashiPairInfo[] memory) {
        KashiPairInfo[] memory pairs = new KashiPairInfo[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            pairs[i].collateral = addresses[i].collateral();
            pairs[i].collateralSymbol = IERC20(addresses[i].collateral()).safeSymbol();
            pairs[i].collateralDecimals = IERC20(addresses[i].collateral()).safeDecimals();
            pairs[i].asset = addresses[i].asset();
            pairs[i].assetSymbol = IERC20(addresses[i].asset()).safeSymbol();
            pairs[i].assetDecimals = IERC20(addresses[i].asset()).safeDecimals();
            pairs[i].oracle = addresses[i].oracle();
            pairs[i].oracleData = addresses[i].oracleData();
        }
        return pairs;
    }

    struct PairPollInfo {
        uint256 suppliedPairCount;
        uint256 borrowPairCount;
    }

    struct PairPoll {
        uint256 totalCollateralAmount;
        uint256 userCollateralAmount;
        uint256 totalAssetAmount;
        uint256 userAssetAmount;
        uint256 totalBorrowAmount;
        uint256 userBorrowAmount;
        uint256 currentExchangeRate;
        uint256 oracleExchangeRate;
        AccrueInfo accrueInfo;
        uint256 assetAPR;
        uint256 borrowAPR;
    }

    function pollPairs(address who, IKashiPair[] calldata addresses) public view returns (PairPollInfo memory, PairPoll[] memory) {
        PairPollInfo memory info;
        PairPoll[] memory pairs = new PairPoll[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IBentoBoxV1 bentoBox = IBentoBoxV1(addresses[i].bentoBox());
            {
                pairs[i].totalCollateralAmount = bentoBox.toAmount(addresses[i].collateral(), addresses[i].totalCollateralShare(), false);
                pairs[i].userCollateralAmount = bentoBox.toAmount(addresses[i].collateral(), addresses[i].userCollateralShare(who), false);
            }
            {
                Rebase memory totalAsset;
                {
                    totalAsset = addresses[i].totalAsset();
                    pairs[i].totalAssetAmount = bentoBox.toAmount(addresses[i].asset(), totalAsset.elastic, false);
                }
                pairs[i].userAssetAmount = bentoBox.toAmount(addresses[i].asset(), totalAsset.toElastic(addresses[i].balanceOf(who), false), false);
                if(pairs[i].userAssetAmount > 0) {
                    info.suppliedPairCount += 1;
                }
            }
            {
                {
                    pairs[i].currentExchangeRate = addresses[i].exchangeRate();
                    (, pairs[i].oracleExchangeRate) = addresses[i].oracle().peek(addresses[i].oracleData());
                    pairs[i].accrueInfo = addresses[i].accrueInfo();
                }
                Rebase memory totalBorrow = addresses[i].totalBorrow();
                pairs[i].totalBorrowAmount = totalBorrow.elastic;
                pairs[i].userBorrowAmount = totalBorrow.toElastic(addresses[i].userBorrowPart(who), false);
                if(pairs[i].userBorrowAmount > 0) {
                    info.borrowPairCount += 1;
                }
            }
            {
                uint256 _totalBorrowAmount = pairs[i].totalBorrowAmount == 0 ? 1 : pairs[i].totalBorrowAmount; 
                uint256 yearlyInterest = _totalBorrowAmount.mul(pairs[i].accrueInfo.interestPerSecond).mul(365 days);
                pairs[i].assetAPR = yearlyInterest.mul(APY_PRECISION).mul(PROTOCOL_FEE_LEFTOVER) / _totalBorrowAmount.add(pairs[i].totalAssetAmount).mul(PROTOCOL_FEE_DIVISOR).mul(1e18);
                pairs[i].borrowAPR = yearlyInterest.mul(APY_PRECISION) / _totalBorrowAmount.mul(1e18);
            }
        }

        return (info, pairs);

    }

}