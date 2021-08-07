// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./interfaces/IKeeperNetworkAdapter.sol";
import "./interfaces/IEPoolPeriphery.sol";
import "./interfaces/IEPoolHelper.sol";
import "./interfaces/IEPool.sol";
import "./EPoolLibrary.sol";
import "./utils/ControllerMixin.sol";

contract KeeperNetworkAdapter is ControllerMixin, IKeeperNetworkAdapter {

    uint256 public constant EPOOL_UPKEEP_LIMIT = 10;

    // required for retrieving information about the EPool to be rebalanced
    IEPoolHelper public override ePoolHelper;

    // maintained EPools
    IEPool[] public override ePools;
    mapping (IEPool => IEPoolPeriphery) public peripheryForEPool;

    // safety interval for avoiding bursts of performUpkeep calls
    // should be smaller than EPool.rebalanceInterval
    uint256 public override keeperRebalanceInterval;
    mapping(IEPool => uint256) public override lastKeeperRebalance;

    event AddedEPool(address indexed ePool, address indexed ePoolPeriphery);
    event RemovedEPool(address indexed ePool);
    event SetEPoolHelper(address indexed ePoolHelper);
    event SetKeeperRebalanceInterval(uint256 interval);

    constructor(IController _controller, IEPoolHelper _ePoolHelper) ControllerMixin(_controller) {
        ePoolHelper = _ePoolHelper;
    }

    /**
     * @notice Returns the address of the Controller
     * @return Address of Controller
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(
        address _controller
    ) external override onlyDao("KeeperNetworkAdapter: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Adds an EPool to the list of upkeeps.
     * If the EPoolPeriphery is updated the EPool has to be removed and added again.
     * @dev Can only be called by an authorized sender
     * @param ePool Address of the EPool to be maintained
     * @param ePoolPeriphery Address of the EPoolPeriphery of the EPool
     * @return True on success
     */
    function addEPool(
        IEPool ePool, IEPoolPeriphery ePoolPeriphery
    ) external override onlyDaoOrGuardian("KeeperNetworkAdapter: not dao or guardian") returns (bool) {
        require(ePools.length < EPOOL_UPKEEP_LIMIT - 1, "KeeperNetworkAdapter: too many EPools");
        for (uint256 i = 0; i < ePools.length; i++) {
            require(address(ePool) != address(ePools[i]), "KeeperNetworkAdapter: already registered");
        }
        ePools.push(ePool);
        peripheryForEPool[ePool] = ePoolPeriphery;
        emit AddedEPool(address(ePool), address(ePoolPeriphery));
        return true;
    }

    /**
     * @notice Removes an EPool to the list of upkeeps.
     * @dev Can only be called by an authorized sender
     * @param ePool Address of the EPool to be maintained
     * @return True on success
     */
    function removeEPool(
        IEPool ePool
    ) external override onlyDaoOrGuardian("KeeperNetworkAdapter: not dao or guardian") returns (bool) {
        bool exists;
        uint256 index;
        for (uint256 i = 0; i < ePools.length; i++) {
            if (address(ePool) == address(ePools[i])) {
                (exists, index) = (true, i);
                break;
            }
        }
        require(exists, "KeeperNetworkAdapter: does not exist");
        peripheryForEPool[ePools[index]] = IEPoolPeriphery(address(0));
        for (uint i = index; i < ePools.length - 1; i++) {
            ePools[i] = ePools[i + 1];
        }
        ePools.pop();
        emit RemovedEPool(address(ePool));
        return true;
    }

    /**
     * @notice Updates the EPoolHelper
     * @dev Can only called by an authorized sender
     * @param _ePoolHelper Address of the new EPoolHelper
     * @return True on success
     */
    function setEPoolHelper(
        IEPoolHelper _ePoolHelper
    ) external override onlyDaoOrGuardian("KeeperNetworkAdapter: not dao or guardian") returns (bool) {
        ePoolHelper = _ePoolHelper;
        emit SetEPoolHelper(address(_ePoolHelper));
        return true;
    }

    /**
     * @notice Updates the interval between rebalances triggered by keepers for each EPool
     * @dev Can only called by an authorized sender
     * @param interval Interval in seconds
     * @return True on success
     */
    function setKeeperRebalanceInterval(
        uint256 interval
    ) external override onlyDaoOrGuardian("KeeperNetworkAdapter: not dao or guardian") returns (bool) {
        keeperRebalanceInterval = interval;
        emit SetKeeperRebalanceInterval(interval);
        return true;
    }

    function _shouldRebalance(IEPool ePool) private view returns (bool) {
        IEPoolPeriphery ePoolPeriphery = peripheryForEPool[ePool];
        address keeperSubsidyPool = address(ePoolPeriphery.keeperSubsidyPool());
        (uint256 deltaA, uint256 deltaB, uint256 rChange) = ePoolHelper.delta(ePool);
        uint256 maxFlashSwapSlippage = ePoolPeriphery.maxFlashSwapSlippage();
        bool funded;
        if (rChange == 0) {
            funded = (
                ePool.tokenB().balanceOf(keeperSubsidyPool)
                    >= (uint256(deltaB) * maxFlashSwapSlippage / EPoolLibrary.sFactorI) - uint256(deltaB)
            );
        } else {
            funded = (
                ePool.tokenA().balanceOf(keeperSubsidyPool)
                    >= (uint256(deltaA) * maxFlashSwapSlippage / EPoolLibrary.sFactorI) - uint256(deltaA)
            );

        }
        return (block.timestamp >= lastKeeperRebalance[ePool] + keeperRebalanceInterval && funded);
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        for (uint256 i = 0; i < ePools.length; i++) {
            IEPool ePool = ePools[i];
            if (_shouldRebalance(ePool)) {
                return (true, abi.encode(ePool));
            }
        }
        return (false, new bytes(0));
    }

    function performUpkeep(bytes calldata performData) external override {
        IEPool ePool = abi.decode(performData, (IEPool));
        lastKeeperRebalance[ePool] = block.timestamp;
        peripheryForEPool[ePool].rebalanceWithFlashSwap(ePool, 1e18);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IEPool.sol";
import "./IEPoolHelper.sol";
import "./IEPoolPeriphery.sol";
import "./IKeeperCompatibleInterface.sol";

interface IKeeperNetworkAdapter is KeeperCompatibleInterface {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function ePools(uint256 i) external returns (IEPool);

    function ePoolHelper() external returns (IEPoolHelper);

    function keeperRebalanceInterval() external returns(uint256);

    function lastKeeperRebalance(IEPool ePool) external returns(uint256);

    function addEPool(IEPool _ePool, IEPoolPeriphery ePoolPeriphery) external returns (bool);

    function removeEPool(IEPool _ePool) external returns (bool);

    function setEPoolHelper(IEPoolHelper _ePoolHelper) external returns (bool);

    function setKeeperRebalanceInterval(uint256 interval) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IKeeperSubsidyPool.sol";
import "./IUniswapRouterV2.sol";
import "./IUniswapFactory.sol";
import "./IEPool.sol";

interface IEPoolPeriphery {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function factory() external view returns (address);

    function router() external view returns (address);

    function ePools(address) external view returns (bool);

    function keeperSubsidyPool() external view returns (IKeeperSubsidyPool);

    function maxFlashSwapSlippage() external view returns (uint256);

    function setEPoolApproval(IEPool ePool, bool approval) external returns (bool);

    function setMaxFlashSwapSlippage(uint256 _maxFlashSwapSlippage) external returns (bool);

    function issueForMaxTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountA,
        uint256 deadline
    ) external returns (bool);

    function issueForMaxTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountB,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputA,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputB,
        uint256 deadline
    ) external returns (bool);

    function rebalanceWithFlashSwap(IEPool ePool, uint256 fracDelta) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IEPool.sol";

interface IEPoolHelper {

    function currentRatio(IEPool ePool, address eToken) external view returns(uint256);

    function trancheDelta(IEPool ePool, address eToken)
        external
        view
        returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);

    function delta(IEPool ePool)
        external
        view
        returns (uint256 deltaA, uint256 deltaB, uint256 rChange);

    function eTokenForTokenATokenB(
        IEPool ePool,
        address eToken,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function tokenATokenBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 _totalA
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenB(
        IEPool ePool,
        address eToken,
        uint256 _totalB
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 amountA
    ) external view returns (uint256 amountB);

    function tokenAForTokenB(
        IEPool ePool,
        address eToken,
        uint256 amountB
    ) external view returns (uint256 amountA);

    function totalA(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function totalB(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function feeAFeeBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 feeA, uint256 feeB);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEToken.sol";

interface IEPool {
    struct Tranche {
        IEToken eToken;
        uint256 sFactorE;
        uint256 reserveA;
        uint256 reserveB;
        uint256 targetRatio;
        uint256 rebalancedAt;
    }

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function tokenA() external view returns (IERC20);

    function tokenB() external view returns (IERC20);

    function sFactorA() external view returns (uint256);

    function sFactorB() external view returns (uint256);

    function getTranche(address eToken) external view returns (Tranche memory);

    function getTranches() external view returns(Tranche[] memory _tranches);

    function addTranche(uint256 targetRatio, string memory eTokenName, string memory eTokenSymbol) external returns (bool);

    function getAggregator() external view returns (address);

    function setAggregator(address oracle, bool inverseRate) external returns (bool);

    function rebalanceMode() external view returns (uint256);

    function rebalanceMinRDiv() external view returns (uint256);

    function rebalanceInterval() external view returns (uint256);

    function setRebalanceMode(uint256 mode) external returns (bool);

    function setRebalanceMinRDiv(uint256 minRDiv) external returns (bool);

    function setRebalanceInterval(uint256 interval) external returns (bool);

    function feeRate() external view returns (uint256);

    function cumulativeFeeA() external view returns (uint256);

    function cumulativeFeeB() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external returns (bool);

    function transferFees() external returns (bool);

    function getRate() external view returns (uint256);

    function rebalance(uint256 fracDelta) external returns (uint256 deltaA, uint256 deltaB, uint256 rChange);

    function issueExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function redeemExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IETokenFactory.sol";
import "./interfaces/IEToken.sol";
import "./interfaces/IEPool.sol";
import "./utils/TokenUtils.sol";
import "./utils/Math.sol";

library EPoolLibrary {
    using TokenUtils for IERC20;

    uint256 internal constant sFactorI = 1e18; // internal scaling factor (18 decimals)

    /**
     * @notice Returns the target ratio if reserveA and reserveB are 0 (for initial deposit)
     * currentRatio := (reserveA denominated in tokenB / reserveB denominated in tokenB) with decI decimals
     */
    function currentRatio(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        if (t.reserveA == 0 || t.reserveB == 0) {
            if (t.reserveA == 0 && t.reserveB == 0) return t.targetRatio;
            if (t.reserveA == 0) return 0;
            if (t.reserveB == 0) return type(uint256).max;
        }
        return ((t.reserveA * rate / sFactorA) * sFactorI) / (t.reserveB * sFactorI / sFactorB);
    }

    /**
     * @notice Returns the deviation of reserveA and reserveB from target ratio
     * currentRatio >= targetRatio: release TokenA liquidity and add TokenB liquidity --> rChange = 0
     * currentRatio < targetRatio: add TokenA liquidity and release TokenB liquidity --> rChange = 1
     * deltaA := abs(t.reserveA, (t.reserveB / rate * t.targetRatio)) / (1 + t.targetRatio)
     * deltaB := deltaA * rate
     * rChange := 0 if currentRatio >= targetRatio, 1 if currentRatio < targetRatio
     * rDiv := 1 - (currentRatio / targetRatio)
     */
    function trancheDelta(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        uint256 ratio = currentRatio(t, rate, sFactorA, sFactorB);
        if (ratio < t.targetRatio) {
            (rChange, rDiv) = (1, sFactorI - (ratio * sFactorI / t.targetRatio));
        } else {
            (rChange, rDiv) = (
                0, (ratio == type(uint256).max) ? type(uint256).max : (ratio * sFactorI / t.targetRatio) - sFactorI
            );
        }
        deltaA = (
            Math.abs(t.reserveA, tokenAForTokenB(t.reserveB, t.targetRatio, rate, sFactorA, sFactorB)) * sFactorA
        ) / (sFactorA + (t.targetRatio * sFactorA / sFactorI));
        // (convert to TokenB precision first to avoid altering deltaA)
        deltaB = ((deltaA * sFactorB / sFactorA) * rate) / sFactorI;
        // round to 0 in case of rounding errors
        if (deltaA == 0 || deltaB == 0) (deltaA, deltaB, rChange, rDiv) = (0, 0, 0, 0);
    }

    /**
     * @notice Returns the sum of the tranches total deltas (summed up tranche deltaA and deltaB)
     */
    function delta(
        IEPool.Tranche[] memory ts,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange) {
        int256 totalDeltaA;
        int256 totalDeltaB;
        for (uint256 i = 0; i < ts.length; i++) {
            (uint256 _deltaA, uint256 _deltaB, uint256 _rChange,) = trancheDelta(ts[i], rate, sFactorA, sFactorB);
            if (_rChange == 0) {
                (totalDeltaA, totalDeltaB) = (totalDeltaA - int256(_deltaA), totalDeltaB + int256(_deltaB));
            } else {
                (totalDeltaA, totalDeltaB) = (totalDeltaA + int256(_deltaA), totalDeltaB - int256(_deltaB));
            }
        }
        if (totalDeltaA > 0 && totalDeltaB < 0)  {
            (deltaA, deltaB, rChange) = (uint256(totalDeltaA), uint256(-totalDeltaB), 1);
        } else if (totalDeltaA < 0 && totalDeltaB > 0) {
            (deltaA, deltaB, rChange) = (uint256(-totalDeltaA), uint256(totalDeltaB), 0);
        }
    }

    /**
     * @notice how much EToken can be issued, redeemed for amountA and amountB
     * initial issuance / last redemption: sqrt(amountA * amountB)
     * subsequent issuances / non nullifying redemptions: claim on reserve * EToken total supply
     */
    function eTokenForTokenATokenB(
        IEPool.Tranche memory t,
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256) {
        uint256 amountsA = totalA(amountA, amountB, rate, sFactorA, sFactorB);
        if (t.reserveA + t.reserveB == 0) {
            return (Math.sqrt((amountsA * t.sFactorE / sFactorA) * t.sFactorE));
        }
        uint256 reservesA = totalA(t.reserveA, t.reserveB, rate, sFactorA, sFactorB);
        uint256 share = ((amountsA * t.sFactorE / sFactorA) * t.sFactorE) / (reservesA * t.sFactorE / sFactorA);
        return share * t.eToken.totalSupply() / t.sFactorE;
    }

    /**
     * @notice Given an amount of EToken, how much TokenA and TokenB have to be deposited, withdrawn for it
     * initial issuance / last redemption: sqrt(amountA * amountB) -> such that the inverse := EToken amount ** 2
     * subsequent issuances / non nullifying redemptions: claim on EToken supply * reserveA/B
     */
    function tokenATokenBForEToken(
        IEPool.Tranche memory t,
        uint256 amount,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (t.reserveA + t.reserveB == 0) {
            uint256 amountsA = amount * sFactorA / t.sFactorE;
            (amountA, amountB) = tokenATokenBForTokenA(
                amountsA * amountsA / sFactorA , t.targetRatio, rate, sFactorA, sFactorB
            );
        } else {
            uint256 eTokenTotalSupply = t.eToken.totalSupply();
            if (eTokenTotalSupply == 0) return(0, 0);
            uint256 share = amount * t.sFactorE / eTokenTotalSupply;
            amountA = share * t.reserveA / t.sFactorE;
            amountB = share * t.reserveB / t.sFactorE;
        }
    }

    /**
     * @notice Given amountB, which amountA is required such that amountB / amountA is equal to the ratio
     * amountA := amountBInTokenA * ratio
     */
    function tokenAForTokenB(
        uint256 amountB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountB * sFactorI / sFactorB) * ratio) / rate) * sFactorA / sFactorI;
    }

    /**
     * @notice Given amountA, which amountB is required such that amountB / amountA is equal to the ratio
     * amountB := amountAInTokenB / ratio
     */
    function tokenBForTokenA(
        uint256 amountA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountA * sFactorI / sFactorA) * rate) / ratio) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenA, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := total - (total / (1 + ratio)) == (total * ratio) / (1 + ratio)
     * amountB := (total / (1 + ratio)) * rate
     */
    function tokenATokenBForTokenA(
        uint256 _totalA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = _totalA - (_totalA * sFactorI / (sFactorI + ratio));
        amountB = (((_totalA * sFactorI / sFactorA) * rate) / (sFactorI + ratio)) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenB, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := (total * ratio) / (rate * (1 + ratio))
     * amountB := total / (1 + ratio)
     */
    function tokenATokenBForTokenB(
        uint256 _totalB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = ((((_totalB * sFactorI / sFactorB) * ratio) / (sFactorI + ratio)) * sFactorA) / rate;
        amountB = (_totalB * sFactorI) / (sFactorI + ratio);
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenA
     * totalA := amountA + (amountB / rate)
     */
    function totalA(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalA) {
        return amountA + ((((amountB * sFactorI / sFactorB) * sFactorI) / rate) * sFactorA) / sFactorI;
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenB
     * totalB := amountB + (amountA * rate)
     */
    function totalB(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalB) {
        return amountB + ((amountA * rate / sFactorA) * sFactorB) / sFactorI;
    }

    /**
     * @notice Return the withdrawal fee for a given amount of TokenA and TokenB
     * feeA := amountA * feeRate
     * feeB := amountB * feeRate
     */
    function feeAFeeBForTokenATokenB(
        uint256 amountA,
        uint256 amountB,
        uint256 feeRate
    ) internal pure returns (uint256 feeA, uint256 feeB) {
        feeA = amountA * feeRate / EPoolLibrary.sFactorI;
        feeB = amountB * feeRate / EPoolLibrary.sFactorI;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "../interfaces/IController.sol";

contract ControllerMixin {
    event SetController(address controller);

    IController internal controller;

    constructor(IController _controller) {
        controller = _controller;
    }

    modifier onlyDao(string memory revertMsg) {
        require(msg.sender == controller.dao(), revertMsg);
        _;
    }

    modifier onlyDaoOrGuardian(string memory revertMsg) {
        require(controller.isDaoOrGuardian(msg.sender), revertMsg);
        _;
    }

    modifier issuanceNotPaused(string memory revertMsg) {
        require(controller.pausedIssuance() == false, revertMsg);
        _;
    }

    function _setController(address _controller) internal {
        controller = IController(_controller);
        emit SetController(_controller);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface KeeperCompatibleInterface {
	/**
	 * @notice method that is simulated by the keepers to see if any work actually
	 * needs to be performed. This method does does not actually need to be
	 * executable, and since it is only ever simulated it can consume lots of gas.
	 * @dev To ensure that it is never called, you may want to add the
	 * cannotExecute modifier from KeeperBase to your implementation of this
	 * method.
	 * @param checkData specified in the upkeep registration so it is always the
	 * same for a registered upkeep. This can easily be broken down into specific
	 * arguments using `abi.decode`, so multiple upkeeps can be registered on the
	 * same contract and easily differentiated by the contract.
	 * @return upkeepNeeded boolean to indicate whether the keeper should call
	 * performUpkeep or not.
	 * @return performData bytes that the keeper should call performUpkeep with, if
	 * upkeep is needed. If you would like to encode data to decode later, try
	 * `abi.encode`.
	 */
	function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

	/**
	 * @notice method that is actually executed by the keepers, via the registry.
	 * The data returned by the checkUpkeep simulation will be passed into
	 * this method to actually be executed.
	 * @dev The input to this method should not be trusted, and the caller of the
	 * method should not even be restricted to any single registry. Anyone should
	 * be able call it, and the input should be validated, there is no guarantee
	 * that the data passed in is the performData returned from checkUpkeep. This
	 * could happen due to malicious keepers, racing keepers, or simply a state
	 * change while the performUpkeep transaction is waiting for confirmation.
	 * Always validate the data passed in.
	 * @param performData is the data which was passed back from the checkData
	 * simulation. If it is encoded, it can easily be decoded into other types by
	 * calling `abi.decode`. This data should not be trusted, and should be
	 * validated against the contract's current state.
	 */
	function performUpkeep(bytes calldata performData) external;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEToken is IERC20 {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;


interface IKeeperSubsidyPool {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function setBeneficiary(address beneficiary, bool canRequest) external returns (bool);

    function isBeneficiary(address beneficiary) external view returns (bool);

    function requestSubsidy(address token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {

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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed tokenA, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IEToken.sol";

interface IETokenFactory {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function createEToken(string memory name, string memory symbol) external returns (IEToken);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC20Optional.sol";

library TokenUtils {
    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "TokenUtils: no decimals");
        uint8 _decimals = abi.decode(data, (uint8));
        return _decimals;
    }
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.1;

library Math {

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

/**
 * @dev Interface of the the optional methods of the ERC20 standard as defined in the EIP.
 */
interface IERC20Optional {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

interface IController {

    function dao() external view returns (address);

    function guardian() external view returns (address);

    function isDaoOrGuardian(address sender) external view returns (bool);

    function setDao(address _dao) external returns (bool);

    function setGuardian(address _guardian) external returns (bool);

    function feesOwner() external view returns (address);

    function pausedIssuance() external view returns (bool);

    function setFeesOwner(address _feesOwner) external returns (bool);

    function setPausedIssuance(bool _pausedIssuance) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}