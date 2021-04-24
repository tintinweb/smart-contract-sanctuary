// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
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
library SafeMath16 {
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
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
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
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b <= a, errorMessage);
        uint16 c = a - b;

        return c;
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
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint16 c = a * b;
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b > 0, errorMessage);
        uint16 c = a / b;
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../v1/utils/SafeMath16.sol";
import "./utils/SafeMath168.sol";
import "./interfaces/IPlatformV2.sol";
import "./interfaces/IPositionRewardsV2.sol";

contract PlatformV2 is IPlatformV2, Ownable, ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath168 for uint168;

    uint80 public latestOracleRoundId;
    uint32 public latestSnapshotTimestamp;
    bool private canPurgeLatestSnapshot = false;
    bool public emergencyWithdrawAllowed = false;
    bool private purgeSnapshots = true;

    uint8 public maxAllowedLeverage = 1;

    uint168 public constant MAX_FEE_PERCENTAGE = 10000;
    uint256 public constant PRECISION_DECIMALS = 1e10;
    uint256 public constant MAX_CVI_VALUE = 20000;

    uint256 public immutable initialTokenToLPTokenRate;

    IERC20 private token;
    ICVIOracleV3 private cviOracle;
    ILiquidationV2 private liquidation;
    IFeesCalculatorV3 private feesCalculator;
    IFeesCollector internal feesCollector;
    IPositionRewardsV2 private rewards;

    uint256 public lpsLockupPeriod = 3 days;
    uint256 public buyersLockupPeriod = 6 hours;

    uint256 public totalPositionUnitsAmount;
    uint256 public totalFundingFeesAmount;
    uint256 public totalLeveragedTokensAmount;

    address private stakingContractAddress = address(0);
    
    mapping(uint256 => uint256) public cviSnapshots;

    mapping(address => uint256) public lastDepositTimestamp;
    mapping(address => Position) public override positions;

    mapping(address => bool) public revertLockedTransfered;

    constructor(IERC20 _token, string memory _lpTokenName, string memory _lpTokenSymbolName, uint256 _initialTokenToLPTokenRate,
        IFeesCalculatorV3 _feesCalculator,
        ICVIOracleV3 _cviOracle,
        ILiquidationV2 _liquidation) public ERC20(_lpTokenName, _lpTokenSymbolName) {

        token = _token;
        initialTokenToLPTokenRate = _initialTokenToLPTokenRate;
        feesCalculator = _feesCalculator;
        cviOracle = _cviOracle;
        liquidation = _liquidation;
    }

    function deposit(uint256 _tokenAmount, uint256 _minLPTokenAmount) external virtual override nonReentrant returns (uint256 lpTokenAmount) {
        _deposit(_tokenAmount, _minLPTokenAmount);
    }

    function withdraw(uint256 _tokenAmount, uint256 _maxLPTokenBurnAmount) external override nonReentrant returns (uint256 burntAmount, uint256 withdrawnAmount) {
        (burntAmount, withdrawnAmount) = _withdraw(_tokenAmount, false, _maxLPTokenBurnAmount);
    }

    function withdrawLPTokens(uint256 _lpTokensAmount) external override nonReentrant returns (uint256 burntAmount, uint256 withdrawnAmount) {
        require(_lpTokensAmount > 0, "Amount must be positive");
        (burntAmount, withdrawnAmount) = _withdraw(0, true, _lpTokensAmount);
    }

    struct OpenPositionLocals {
        uint256 balance;
        uint256 collateralRatio;
        uint256 marginDebt;
        uint256 positionBalance;
        uint256 latestSnapshot;
        uint256 openPositionFee;
        uint256 minPositionUnitsAmount;
        uint168 buyingPremiumFee;
        uint168 buyingPremiumFeePercentage;
        uint168 tokenAmountToOpenPosition;
        uint256 maxPositionUnitsAmount;
        uint16 cviValue;
    }

    function openPosition(uint168 _tokenAmount, uint16 _maxCVI, uint168 _maxBuyingPremiumFeePercentage, uint8 _leverage) external override virtual nonReentrant returns (uint168 positionUnitsAmount) {
        _openPosition(_tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function closePosition(uint168 _positionUnitsAmount, uint16 _minCVI) external override nonReentrant returns (uint256 tokenAmount) {
        require(_positionUnitsAmount > 0, "Position units not positive");
        require(_minCVI > 0 && _minCVI <= MAX_CVI_VALUE, "Bad min CVI value");

        Position storage position = positions[msg.sender];

        require(position.positionUnitsAmount >= _positionUnitsAmount, "Not enough opened position units");
        require(block.timestamp.sub(position.creationTimestamp) >= buyersLockupPeriod, "Position locked");

        (uint16 cviValue, uint256 latestSnapshot) = updateSnapshots(true);
        require(cviValue >= _minCVI, "CVI too low");

        (uint256 positionBalance, uint256 fundingFees, uint256 marginDebt, bool wasLiquidated) = _closePosition(position, _positionUnitsAmount, latestSnapshot, cviValue);

        // If was liquidated, balance is negative, nothing to return
        if (wasLiquidated) {
            return 0;
        }

        (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAmount) = subtractTotalPositionUnits(_positionUnitsAmount, fundingFees);
        totalPositionUnitsAmount = newTotalPositionUnitsAmount;
        totalFundingFeesAmount = newTotalFundingFeesAmount;
        position.positionUnitsAmount = position.positionUnitsAmount.sub(_positionUnitsAmount);

        uint256 closePositionFee = positionBalance
            .mul(uint256(feesCalculator.calculateClosePositionFeePercent(position.creationTimestamp)))
            .div(MAX_FEE_PERCENTAGE);

        emit ClosePosition(msg.sender, positionBalance.add(fundingFees), closePositionFee.add(fundingFees), position.positionUnitsAmount, position.leverage, cviValue);

        if (position.positionUnitsAmount == 0) {
            delete positions[msg.sender];
        }

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(positionBalance).sub(marginDebt);
        tokenAmount = positionBalance.sub(closePositionFee);

        collectProfit(closePositionFee);
        transferFunds(tokenAmount);
    }

    function _closePosition(Position storage _position, uint256 _positionUnitsAmount, uint256 _latestSnapshot, uint16 _cviValue) private returns (uint256 positionBalance, uint256 fundingFees, uint256 marginDebt, bool wasLiquidated) {
        fundingFees = _calculateFundingFees(cviSnapshots[_position.creationTimestamp], _latestSnapshot, _positionUnitsAmount);
        
        (uint256 currentPositionBalance, bool isPositive, uint256 __marginDebt) = __calculatePositionBalance(_positionUnitsAmount, _position.leverage, _cviValue, _position.openCVIValue, fundingFees);
        
        // Position might be liquidable but balance is positive, we allow to avoid liquidity in such a condition
        if (!isPositive) {
            checkAndLiquidatePosition(msg.sender, false); // Will always liquidate
            wasLiquidated = true;
            fundingFees = 0;
        } else {
            positionBalance = currentPositionBalance;
            marginDebt = __marginDebt;
        }
    }

    function liquidatePositions(address[] calldata _positionOwners) external override nonReentrant returns (uint256 finderFeeAmount) {
        updateSnapshots(true);
        bool liquidationOccured = false;
        for ( uint256 i = 0; i < _positionOwners.length; i++) {
            Position memory position = positions[_positionOwners[i]];

            if (position.positionUnitsAmount > 0) {
                (bool wasLiquidated, uint256 liquidatedAmount, bool isPositive) = checkAndLiquidatePosition(_positionOwners[i], false);

                if (wasLiquidated) {
                    liquidationOccured = true;
                    finderFeeAmount = finderFeeAmount.add(liquidation.getLiquidationReward(liquidatedAmount, isPositive, position.positionUnitsAmount, position.openCVIValue, position.leverage));
                }
            }
        }

        require(liquidationOccured, "No liquidatable position");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(finderFeeAmount);
        transferFunds(finderFeeAmount);
    }

    function setFeesCollector(IFeesCollector _newCollector) external override onlyOwner {
        if (address(feesCollector) != address(0) && address(token) != address(0)) {
            token.approve(address(feesCollector), 0);
        }

        feesCollector = _newCollector;

        if (address(_newCollector) != address(0) && address(token) != address(0)) {
            token.approve(address(_newCollector), uint256(-1));
        }
    }

    function setFeesCalculator(IFeesCalculatorV3 _newCalculator) external override onlyOwner {
        feesCalculator = _newCalculator;
    }

    function setCVIOracle(ICVIOracleV3 _newOracle) external override onlyOwner {
        cviOracle = _newOracle;
    }

    function setRewards(IPositionRewardsV2 _newRewards) external override onlyOwner {
        rewards = _newRewards;
    }

    function setLiquidation(ILiquidationV2 _newLiquidation) external override onlyOwner {
        liquidation = _newLiquidation;
    }

    function setLatestOracleRoundId(uint80 _newOracleRoundId) external override onlyOwner {
        latestOracleRoundId = _newOracleRoundId;
    }
    
    function setLPLockupPeriod(uint256 _newLPLockupPeriod) external override onlyOwner {
        require(_newLPLockupPeriod <= 2 weeks, "Lockup too long");
        lpsLockupPeriod = _newLPLockupPeriod;
    }

    function setBuyersLockupPeriod(uint256 _newBuyersLockupPeriod) external override onlyOwner {
        require(_newBuyersLockupPeriod <= 1 weeks, "Lockup too long");
        buyersLockupPeriod = _newBuyersLockupPeriod;
    }

    function setRevertLockedTransfers(bool _revertLockedTransfers) external override {
        revertLockedTransfered[msg.sender] = _revertLockedTransfers;   
    }

    function setEmergencyWithdrawAllowed(bool _newEmergencyWithdrawAllowed) external override onlyOwner {
        emergencyWithdrawAllowed = _newEmergencyWithdrawAllowed;
    }

    function setStakingContractAddress(address _newStakingContractAddress) external override onlyOwner {
        stakingContractAddress = _newStakingContractAddress;
    }

    function setCanPurgeSnapshots(bool _newCanPurgeSnapshots) external override onlyOwner {
        purgeSnapshots = _newCanPurgeSnapshots;
    }

    function setMaxAllowedLeverage(uint8 _newMaxAllowedLeverage) external override onlyOwner {
        maxAllowedLeverage = _newMaxAllowedLeverage;
    }

    function getToken() external view override returns (IERC20) {
        return token;
    }

    function calculatePositionBalance(address _positionAddress) external view override returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt) {
        positionUnitsAmount = positions[_positionAddress].positionUnitsAmount;
        leverage = positions[_positionAddress].leverage;
        require(positionUnitsAmount > 0, "No position for given address");
        (currentPositionBalance, isPositive, fundingFees, marginDebt) = _calculatePositionBalance(_positionAddress, true);
    }

    function calculatePositionPendingFees(address _positionAddress, uint168 _positionUnitsAmount) external view override returns (uint256 pendingFees) {
        Position memory position = positions[_positionAddress];
        pendingFees = _calculateFundingFees(cviSnapshots[position.creationTimestamp], 
            cviSnapshots[latestSnapshotTimestamp], _positionUnitsAmount).add(
                calculateLatestFundingFees(latestSnapshotTimestamp, _positionUnitsAmount));
    }

    function totalBalance() public view override returns (uint256 balance) {
        (uint16 cviValue,,) = cviOracle.getCVILatestRoundData();
        return _totalBalance(cviValue);
    }

    function totalBalanceWithAddendum() external view override returns (uint256 balance) {
        return totalBalance().add(calculateLatestFundingFees(latestSnapshotTimestamp, totalPositionUnitsAmount));
    }

    function calculateLatestTurbulenceIndicatorPercent() external view override returns (uint16) {
        SnapshotUpdate memory updateData = _updateSnapshots(latestSnapshotTimestamp);
        if (updateData.updatedTurbulenceData) {
            return feesCalculator.calculateTurbulenceIndicatorPercent(updateData.totalTime, updateData.totalRounds);
        } else {
            return feesCalculator.turbulenceIndicatorPercent();
        }
    }

    function getLiquidableAddresses(address[] calldata _positionOwners) external view override returns (address[] memory) {
        address[] memory addressesToLiquidate = new address[](_positionOwners.length);

        uint256 liquidationAddressesAmount = 0;
        for (uint256 i = 0; i < _positionOwners.length; i++) {
            (uint256 currentPositionBalance, bool isBalancePositive,, ) = _calculatePositionBalance(_positionOwners[i], true);

            Position memory position = positions[_positionOwners[i]];

            if (position.positionUnitsAmount > 0 && liquidation.isLiquidationCandidate(currentPositionBalance, isBalancePositive, position.positionUnitsAmount, position.openCVIValue, position.leverage)) {
                addressesToLiquidate[liquidationAddressesAmount] = _positionOwners[i];
                liquidationAddressesAmount = liquidationAddressesAmount.add(1);
            }
        }

        address[] memory addressesToActuallyLiquidate = new address[](liquidationAddressesAmount);
        for (uint256 i = 0; i < liquidationAddressesAmount; i++) {
            addressesToActuallyLiquidate[i] = addressesToLiquidate[i];
        }

        return addressesToActuallyLiquidate;
    }

    function collectTokens(uint256 _tokenAmount) internal virtual {
        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
    }

    function _deposit(uint256 _tokenAmount, uint256 _minLPTokenAmount) internal returns (uint256 lpTokenAmount) {
        require(_tokenAmount > 0, "Tokens amount must be positive");
        lastDepositTimestamp[msg.sender] = block.timestamp;

        (uint16 cviValue,) = updateSnapshots(true);

        uint256 depositFee = _tokenAmount.mul(uint256(feesCalculator.depositFeePercent())) / MAX_FEE_PERCENTAGE;

        uint256 tokenAmountToDeposit = _tokenAmount.sub(depositFee);
        uint256 supply = totalSupply();
        uint256 balance = _totalBalance(cviValue);
    
        if (supply > 0 && balance > 0) {
            lpTokenAmount = tokenAmountToDeposit.mul(supply) / balance;
        } else {
            lpTokenAmount = tokenAmountToDeposit.mul(initialTokenToLPTokenRate);
        }

        emit Deposit(msg.sender, _tokenAmount, lpTokenAmount, depositFee);

        require(lpTokenAmount >= _minLPTokenAmount, "Too few LP tokens");
        require(lpTokenAmount > 0, "Too few tokens");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.add(tokenAmountToDeposit);

        _mint(msg.sender, lpTokenAmount);
        collectTokens(_tokenAmount);
        collectProfit(depositFee);
    }

    function _withdraw(uint256 _tokenAmount, bool _shouldBurnMax, uint256 _maxLPTokenBurnAmount) internal returns (uint256 burntAmount, uint256 withdrawnAmount) {
        require(lastDepositTimestamp[msg.sender].add(lpsLockupPeriod) <= block.timestamp, "Funds are locked");

        (uint16 cviValue,) = updateSnapshots(true);

        if (_shouldBurnMax) {
            burntAmount = _maxLPTokenBurnAmount;
            _tokenAmount = burntAmount.mul(_totalBalance(cviValue)).div(totalSupply());
        } else {
            require(_tokenAmount > 0, "Tokens amount must be positive");

            // Note: rounding up (ceiling) the to-burn amount to prevent precision loss
            burntAmount = _tokenAmount.mul(totalSupply()).sub(1).div(_totalBalance(cviValue)).add(1);
            require(burntAmount <= _maxLPTokenBurnAmount, "Too much LP tokens to burn");
        }

        require(burntAmount <= balanceOf(msg.sender), "Not enough LP tokens for account");
        require(emergencyWithdrawAllowed || getTokenBalance().sub(totalPositionUnitsAmount) >= _tokenAmount, "Collateral ratio broken");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(_tokenAmount);

        uint256 withdrawFee = _tokenAmount.mul(uint256(feesCalculator.withdrawFeePercent())) / MAX_FEE_PERCENTAGE;
        withdrawnAmount = _tokenAmount.sub(withdrawFee);

        emit Withdraw(msg.sender, _tokenAmount, burntAmount, withdrawFee);
        
        _burn(msg.sender, burntAmount);

        collectProfit(withdrawFee);
        transferFunds(withdrawnAmount);
    }

    function _openPosition(uint168 _tokenAmount, uint16 _maxCVI, uint168 _maxBuyingPremiumFeePercentage, uint8 _leverage) internal returns (uint168 positionUnitsAmount) {
        require(_leverage > 0, "Leverage must be positive");
        require(_leverage <= maxAllowedLeverage, "Leverage excceeds max allowed");
        require(_tokenAmount > 0, "Tokens amount must be positive");
        require(_maxCVI > 0 && _maxCVI <= MAX_CVI_VALUE, "Bad max CVI value");

        OpenPositionLocals memory locals;

        (locals.cviValue, locals.latestSnapshot) = updateSnapshots(false);
        require(locals.cviValue <= _maxCVI, "CVI too high");

        (uint16 openPositionFeePercent, uint16 buyingPremiumFeeMaxPercent) = feesCalculator.openPositionFees();

        // Calculate buying premium fee, assuming the maxmimum 
        locals.openPositionFee = uint256(_tokenAmount).mul(_leverage).mul(openPositionFeePercent) / MAX_FEE_PERCENTAGE;
        locals.maxPositionUnitsAmount = uint256(_tokenAmount).sub(locals.openPositionFee).mul(_leverage).mul(MAX_CVI_VALUE) / locals.cviValue;
        locals.minPositionUnitsAmount = locals.maxPositionUnitsAmount.
            mul(MAX_FEE_PERCENTAGE.sub(buyingPremiumFeeMaxPercent)) / MAX_FEE_PERCENTAGE;

        locals.balance = getTokenBalance(_tokenAmount);

        locals.collateralRatio = 0;
        if (locals.balance > 0) {
            locals.collateralRatio = (totalPositionUnitsAmount.add(locals.minPositionUnitsAmount)).mul(PRECISION_DECIMALS).
                div((locals.balance.add(uint256(_tokenAmount) - locals.openPositionFee)));
        }
        (locals.buyingPremiumFee, locals.buyingPremiumFeePercentage) = feesCalculator.calculateBuyingPremiumFee(_tokenAmount, _leverage, locals.collateralRatio);

        require(locals.buyingPremiumFeePercentage <= _maxBuyingPremiumFeePercentage, "Premium fee too high");
        
        // Leaving buying premium in shared pool
        require(locals.openPositionFee < _tokenAmount, "Open fee too big");
        locals.tokenAmountToOpenPosition = (_tokenAmount - uint168(locals.openPositionFee)).sub(locals.buyingPremiumFee).mul(_leverage);
        
        Position storage position = positions[msg.sender];

        if (position.positionUnitsAmount > 0) {
            (positionUnitsAmount, locals.marginDebt, locals.positionBalance) = _mergePosition(position, locals.latestSnapshot, locals.cviValue, locals.tokenAmountToOpenPosition, _leverage);
            uint256 addedTotalLeveragedTokensAmount = totalLeveragedTokensAmount.add(uint256(_tokenAmount - locals.openPositionFee).add(locals.positionBalance).mul(_leverage));
            totalLeveragedTokensAmount = addedTotalLeveragedTokensAmount.sub(locals.marginDebt).sub(locals.positionBalance);
        } else {
            uint256 __positionUnitsAmount = uint256(locals.tokenAmountToOpenPosition).mul(MAX_CVI_VALUE) / locals.cviValue;
            positionUnitsAmount = uint168(__positionUnitsAmount);
            require(positionUnitsAmount == __positionUnitsAmount, "Too much position units");

            Position memory newPosition = Position(positionUnitsAmount, _leverage, locals.cviValue, uint32(block.timestamp), uint32(block.timestamp));

            positions[msg.sender] = newPosition;
            totalPositionUnitsAmount = totalPositionUnitsAmount.add(positionUnitsAmount);

            totalLeveragedTokensAmount = totalLeveragedTokensAmount.add((_tokenAmount - locals.openPositionFee) * _leverage);
        }   

        emit OpenPosition(msg.sender, _tokenAmount, _leverage, locals.openPositionFee.add(locals.buyingPremiumFee), positionUnitsAmount, locals.cviValue);

        collectTokens(_tokenAmount);        

        locals.balance = locals.balance.add(_tokenAmount);
        collectProfit(locals.openPositionFee);

        require(totalPositionUnitsAmount <= locals.balance, "Not enough liquidity");

        if (address(rewards) != address(0)) {
            rewards.reward(msg.sender, positionUnitsAmount, _leverage);
        }
    }

    struct MergePositionLocals {
        uint168 oldPositionUnits;
        uint256 newPositionUnits;
        uint256 newTotalPositionUnitsAmount;
        uint256 newTotalFundingFeesAmount;
    }

    function _mergePosition(Position storage _position, uint256 _latestSnapshot, uint16 _cviValue, uint256 _leveragedTokenAmount, uint8 _leverage) private returns (uint168 positionUnitsAmount, uint256 marginDebt, uint256 positionBalance) {
        MergePositionLocals memory locals;

        locals.oldPositionUnits = _position.positionUnitsAmount;
        (uint256 currentPositionBalance, uint256 fundingFees, uint256 __marginDebt, bool wasLiquidated) = _closePosition(_position, locals.oldPositionUnits, _latestSnapshot, _cviValue);
        
        // If was liquidated, balance is negative
        if (wasLiquidated) {
            currentPositionBalance = 0;
            locals.oldPositionUnits = 0;
            __marginDebt = 0;
            locals.oldPositionUnits = 0;
        }

        locals.newPositionUnits = currentPositionBalance.mul(_leverage).add(_leveragedTokenAmount).mul(MAX_CVI_VALUE).div(_cviValue);
        positionUnitsAmount = uint168(locals.newPositionUnits);
        require(positionUnitsAmount == locals.newPositionUnits, "Too much position units");

        _position.creationTimestamp = uint32(block.timestamp);
        _position.positionUnitsAmount = positionUnitsAmount;
        _position.openCVIValue = _cviValue;
        _position.leverage = _leverage;

        (locals.newTotalPositionUnitsAmount, locals.newTotalFundingFeesAmount) = subtractTotalPositionUnits(locals.oldPositionUnits, fundingFees);
        totalFundingFeesAmount = locals.newTotalFundingFeesAmount;
        totalPositionUnitsAmount = locals.newTotalPositionUnitsAmount.add(positionUnitsAmount);
        marginDebt = __marginDebt;
        positionBalance = currentPositionBalance;
    }

    function transferFunds(uint256 _tokenAmount) internal virtual {
        token.safeTransfer(msg.sender, _tokenAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (lastDepositTimestamp[from].add(lpsLockupPeriod) > block.timestamp && 
            lastDepositTimestamp[from] > lastDepositTimestamp[to] && 
            from != stakingContractAddress && to != stakingContractAddress) {
                require(!revertLockedTransfered[to], "Recipient refuses locked tokens");
                lastDepositTimestamp[to] = lastDepositTimestamp[from];
        }
    }

    function sendProfit(uint256 _amount, IERC20 _token) internal virtual {
        feesCollector.sendProfit(_amount, _token);
    }

    function getTokenBalance() private view returns (uint256) {
        return getTokenBalance(0);
    }

    function getTokenBalance(uint256 _tokenAmount) internal view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint80 newLatestRoundId;
        uint16 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateSnapshots(bool _canPurgeLatestSnapshot) private returns (uint16 latestCVIValue, uint256 latestSnapshot) {
        uint256 latestTimestamp = latestSnapshotTimestamp;
        SnapshotUpdate memory updateData = _updateSnapshots(latestTimestamp);

        if (updateData.updatedSnapshot) {
            cviSnapshots[block.timestamp] = updateData.latestSnapshot;
            totalFundingFeesAmount = totalFundingFeesAmount.add(updateData.singleUnitFundingFee.mul(totalPositionUnitsAmount) / PRECISION_DECIMALS);
        }

        if (updateData.updatedLatestRoundId) {
            latestOracleRoundId = updateData.newLatestRoundId;
        }

        if (updateData.updatedTurbulenceData) {
            feesCalculator.updateTurbulenceIndicatorPercent(updateData.totalTime, updateData.totalRounds);
        }

        if (updateData.updatedLatestTimestamp) {
            latestSnapshotTimestamp = uint32(block.timestamp);

            // Delete old snapshot if it can be deleted (not an open snapshot) to save gas
            if (canPurgeLatestSnapshot && purgeSnapshots) {
                delete cviSnapshots[latestTimestamp];
            }

            // Update purge since timestamp has changed and it is safe
            canPurgeLatestSnapshot = _canPurgeLatestSnapshot;
        } else if (canPurgeLatestSnapshot) {
            // Update purge only from true to false, so if an open was in the block, will never be purged
            canPurgeLatestSnapshot = _canPurgeLatestSnapshot;
        }

        return (updateData.cviValue, updateData.latestSnapshot);
    }

    function _updateSnapshots(uint256 _latestTimestamp) private view returns (SnapshotUpdate memory snapshotUpdate) {
        (uint16 cviValue, uint80 periodEndRoundId, uint256 periodEndTimestamp) = cviOracle.getCVILatestRoundData();
        snapshotUpdate.cviValue = cviValue;

        snapshotUpdate.latestSnapshot = cviSnapshots[block.timestamp];
        if (snapshotUpdate.latestSnapshot != 0) { // Block was already updated
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        if (latestSnapshotTimestamp == 0) { // For first recorded block
            snapshotUpdate.latestSnapshot = PRECISION_DECIMALS;
            snapshotUpdate.updatedSnapshot = true;
            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;
            snapshotUpdate.updatedLatestTimestamp = true;
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        uint80 periodStartRoundId = latestOracleRoundId;
        require(periodEndRoundId >= periodStartRoundId, "Bad round id");

        snapshotUpdate.totalRounds = periodEndRoundId - periodStartRoundId;

        uint256 cviValuesNum = snapshotUpdate.totalRounds > 0 ? 2 : 1;
        IFeesCalculatorV3.CVIValue[] memory cviValues = new IFeesCalculatorV3.CVIValue[](cviValuesNum);
        
        if (snapshotUpdate.totalRounds > 0) {
            (uint16 periodStartCVIValue, uint256 periodStartTimestamp) = cviOracle.getCVIRoundData(periodStartRoundId);
            cviValues[0] = IFeesCalculatorV3.CVIValue(periodEndTimestamp.sub(_latestTimestamp), periodStartCVIValue);
            cviValues[1] = IFeesCalculatorV3.CVIValue(block.timestamp.sub(periodEndTimestamp), cviValue);

            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;

            snapshotUpdate.totalTime = periodEndTimestamp.sub(periodStartTimestamp);
            snapshotUpdate.updatedTurbulenceData = true;
        } else {
            cviValues[0] = IFeesCalculatorV3.CVIValue(block.timestamp.sub(_latestTimestamp), cviValue);
        }

        snapshotUpdate.singleUnitFundingFee = feesCalculator.calculateSingleUnitFundingFee(cviValues);
        snapshotUpdate.latestSnapshot = cviSnapshots[_latestTimestamp].add(snapshotUpdate.singleUnitFundingFee);
        snapshotUpdate.updatedSnapshot = true;
        snapshotUpdate.updatedLatestTimestamp = true;
    }

    function _totalBalance(uint16 _cviValue) private view returns (uint256 balance) {
        return totalLeveragedTokensAmount.add(totalFundingFeesAmount).sub(totalPositionUnitsAmount.mul(_cviValue) / MAX_CVI_VALUE);
    }

    function collectProfit(uint256 amount) private {
        if (amount > 0 && address(feesCollector) != address(0)) {
            sendProfit(amount, token);
        }
    }

    function checkAndLiquidatePosition(address _positionAddress, bool _withAddendum) private returns (bool wasLiquidated, uint256 liquidatedAmount, bool isPositive) {
        (uint256 currentPositionBalance, bool isBalancePositive, uint256 fundingFees, uint256 marginDebt) = _calculatePositionBalance(_positionAddress, _withAddendum);
        isPositive = isBalancePositive;
        liquidatedAmount = currentPositionBalance;

        Position memory position = positions[_positionAddress];

        if (liquidation.isLiquidationCandidate(currentPositionBalance, isBalancePositive, position.positionUnitsAmount, position.openCVIValue, position.leverage)) {
            (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAmount) = subtractTotalPositionUnits(position.positionUnitsAmount, fundingFees);
            totalPositionUnitsAmount = newTotalPositionUnitsAmount;
            totalFundingFeesAmount = newTotalFundingFeesAmount;
            totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(marginDebt);

            emit LiquidatePosition(_positionAddress, currentPositionBalance, isBalancePositive, position.positionUnitsAmount);

            delete positions[_positionAddress];
            wasLiquidated = true;
        }
    }

    function subtractTotalPositionUnits(uint168 _positionUnitsAmountToSubtract, uint256 _fundingFeesToSubtract) private view returns (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAMount) {
        newTotalPositionUnitsAmount = totalPositionUnitsAmount.sub(_positionUnitsAmountToSubtract);
        newTotalFundingFeesAMount = totalFundingFeesAmount;
        if (newTotalPositionUnitsAmount == 0) {
            newTotalFundingFeesAMount = 0;
        } else {
            newTotalFundingFeesAMount = newTotalFundingFeesAMount.sub(_fundingFeesToSubtract);
        }
    }

    function _calculatePositionBalance(address _positionAddress, bool _withAddendum) private view returns (uint256 currentPositionBalance, bool isPositive, uint256 fundingFees, uint256 marginDebt) {
        Position memory position = positions[_positionAddress];

        (uint16 cviValue,,) = cviOracle.getCVILatestRoundData();

        fundingFees = _calculateFundingFees(cviSnapshots[position.creationTimestamp], cviSnapshots[latestSnapshotTimestamp], position.positionUnitsAmount);
        if (_withAddendum) {
            fundingFees = fundingFees.add(calculateLatestFundingFees(latestSnapshotTimestamp, position.positionUnitsAmount));
        }
        
        (currentPositionBalance, isPositive, marginDebt) = __calculatePositionBalance(position.positionUnitsAmount, position.leverage, cviValue, position.openCVIValue, fundingFees);
    }

    function __calculatePositionBalance(uint256 _positionUnits, uint8 _leverage, uint16 _cviValue, uint16 _openCVIValue, uint256 _fundingFees) private pure returns (uint256 currentPositionBalance, bool isPositive, uint256 marginDebt) {
        uint256 positionBalanceWithoutFees = _positionUnits.mul(_cviValue) / MAX_CVI_VALUE;

        marginDebt = _leverage > 1 ? _positionUnits.mul(_openCVIValue).mul(_leverage - 1) / MAX_CVI_VALUE / _leverage: 0;
        uint256 totalDebt = marginDebt.add(_fundingFees);

        if (positionBalanceWithoutFees >= totalDebt) {
            currentPositionBalance = positionBalanceWithoutFees.sub(totalDebt);
            isPositive = true;
        } else {
            currentPositionBalance = totalDebt.sub(positionBalanceWithoutFees);
        }
    }

    function _calculateFundingFees(uint256 startTimeSnapshot, uint256 endTimeSnapshot, uint256 positionUnitsAmount) private pure returns (uint256) {
        return endTimeSnapshot.sub(startTimeSnapshot).mul(positionUnitsAmount) / PRECISION_DECIMALS;
    }

    function calculateLatestFundingFees(uint256 startTime, uint256 positionUnitsAmount) private view returns (uint256) {
        SnapshotUpdate memory updateData = _updateSnapshots(latestSnapshotTimestamp);
        return _calculateFundingFees(cviSnapshots[startTime], updateData.latestSnapshot, positionUnitsAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPositionRewardsV2.sol";

contract PositionRewardsV2 is IPositionRewardsV2, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION_DECIMALS = 1e10;

    mapping(address => uint256) public unclaimedPositionUnits;

    uint256 public maxClaimPeriod = 30 days;
    uint256 public maxRewardTime = 3 days;
    uint256 public maxRewardTimePercentageGain = 25e8;

    uint256 public maxDailyReward = 2300e18;

    uint256 public maxSingleReward = 800e18;
    uint256 public rewardMaxLinearPositionUnits = 20e18;
    uint256 public rewardMaxLinearGOVI = 100e18;

    uint256 public rewardFactor = 1e13;

    uint256 public lastMaxSingleReward;
    uint256 public lastRewardMaxLinearPositionUnits;
    uint256 public lastRewardMaxLinearGOVI;

    uint256 public rewardCalculationValidTimestamp;

    uint256 public todayClaimedRewards;
    uint256 public lastClaimedDay;

    address public rewarder;

    IERC20 private immutable cviToken;

    PlatformV2 public platform;

    constructor(IERC20 _cviToken) public {
        cviToken = _cviToken;
    }

    modifier onlyRewarder {
        require(msg.sender == rewarder, "Not allowed");
        _;
    }

    function calculatePositionReward(uint256 _positionUnits, uint256 _positionTimestamp) public view override returns (uint256 rewardAmount) {
        require(_positionUnits > 0, "Position units must be positive");

        uint256 _rewardMaxLinearPositionUnits;
        uint256 _rewardMaxLinearGOVI;
        uint256 _maxSingleReward;

        if (block.timestamp > rewardCalculationValidTimestamp) {
            _rewardMaxLinearPositionUnits = rewardMaxLinearPositionUnits;
            _rewardMaxLinearGOVI = rewardMaxLinearGOVI.div(rewardFactor);
            _maxSingleReward = maxSingleReward.div(rewardFactor);
        } else {
            _rewardMaxLinearPositionUnits = lastRewardMaxLinearPositionUnits;
            _rewardMaxLinearGOVI = lastRewardMaxLinearGOVI.div(rewardFactor);
            _maxSingleReward = lastMaxSingleReward.div(rewardFactor);
        }

        uint256 factoredPositionUnits = _positionUnits.mul(calculatePositionUnitsFactor(_positionTimestamp)) / PRECISION_DECIMALS;

        if (factoredPositionUnits <= _rewardMaxLinearPositionUnits) {
            rewardAmount = factoredPositionUnits.mul(_rewardMaxLinearGOVI) / _rewardMaxLinearPositionUnits;  
        } else {
            (uint256 alpha, uint256 beta, uint256 gamma) = calculateAlphaBetaGamma(_maxSingleReward, _rewardMaxLinearPositionUnits, _rewardMaxLinearGOVI);

            // reward = c - (alpha / ((x + beta)^2 + gamma)
            uint256 betaPlusFactoredPositionUnits = beta.add(factoredPositionUnits);

            rewardAmount = _maxSingleReward.sub(alpha.div(betaPlusFactoredPositionUnits.mul(betaPlusFactoredPositionUnits).add(gamma)));
        }

        rewardAmount = rewardAmount.mul(rewardFactor);
        require(rewardAmount <= _maxSingleReward.mul(rewardFactor), "Reward too big");
    }

    function reward(address _account, uint256 _positionUnits, uint8 _leverage) external override onlyRewarder {
        require(_positionUnits > 0, "Position units must be positive");
        unclaimedPositionUnits[_account] = unclaimedPositionUnits[_account].add(_positionUnits / _leverage);
    }

    function claimReward() external override {
        require(address(platform) != address(0), "Platform not set");

        (uint256 positionUnitsAmount,,, uint256 creationTimestamp,) = platform.positions(msg.sender);
        require(positionUnitsAmount > 0, "No opened position");
        require(block.timestamp <= creationTimestamp + maxClaimPeriod, "Claim too late");

        uint256 today = block.timestamp / 1 days;
        uint256 positionDay = creationTimestamp / 1 days;
        require(today > positionDay, "Claim too early");

        // Reward position units will be the min from currently open and currently available
        // This resolves the issue of claiming after a merge
        uint256 rewardPositionUnits = unclaimedPositionUnits[msg.sender];
        if (positionUnitsAmount < rewardPositionUnits) {
            rewardPositionUnits = positionUnitsAmount;
        }

        require(rewardPositionUnits > 0, "No reward");

        uint256 rewardAmount = calculatePositionReward(rewardPositionUnits, creationTimestamp);
        uint256 _maxDailyReward = maxDailyReward;

        uint256 updatedDailyClaimedReward = 0;

        if (today > lastClaimedDay) {
            lastClaimedDay = today;
        } else {
            updatedDailyClaimedReward = todayClaimedRewards;
        }

        updatedDailyClaimedReward = updatedDailyClaimedReward.add(rewardAmount);

        require(updatedDailyClaimedReward <= _maxDailyReward, "Daily reward spent");

        todayClaimedRewards = updatedDailyClaimedReward;
        unclaimedPositionUnits[msg.sender] = 0;

        emit Claimed(msg.sender, rewardAmount);
        cviToken.safeTransfer(msg.sender, rewardAmount);
    }

    function setRewarder(address _newRewarder) external override onlyOwner {
        rewarder = _newRewarder;
    }

    function setMaxDailyReward(uint256 _newMaxDailyReward) external override onlyOwner {
        maxDailyReward = _newMaxDailyReward;
    }

    function setRewardCalculationParameters(uint256 _newMaxSingleReward, uint256 _rewardMaxLinearPositionUnits, uint256 _rewardMaxLinearGOVI) external override onlyOwner {
        require(_newMaxSingleReward > 0, "Max reward must be positive");
        require(_rewardMaxLinearPositionUnits > 0, "Max linear x must be positive");
        require(_rewardMaxLinearGOVI > 0, "Max linear y must be positive");

        // Makes sure alpha and beta values for new values are positive
        calculateAlphaBetaGamma(_newMaxSingleReward.div(rewardFactor), _rewardMaxLinearPositionUnits, _rewardMaxLinearGOVI.div(rewardFactor));

        lastRewardMaxLinearPositionUnits = rewardMaxLinearPositionUnits;
        rewardMaxLinearPositionUnits = _rewardMaxLinearPositionUnits;

        lastRewardMaxLinearGOVI = rewardMaxLinearGOVI;
        rewardMaxLinearGOVI = _rewardMaxLinearGOVI;

        lastMaxSingleReward = maxSingleReward;
        maxSingleReward = _newMaxSingleReward;

        rewardCalculationValidTimestamp = block.timestamp.add(maxClaimPeriod);
    }

    function setRewardFactor(uint256 _newRewardFactor) external override onlyOwner {
        rewardFactor = _newRewardFactor;
    }

    function setMaxClaimPeriod(uint256 _newMaxClaimPeriod) external override onlyOwner {
        maxClaimPeriod = _newMaxClaimPeriod;
    }

    function setMaxRewardTime(uint256 _newMaxRewardTime) external override onlyOwner {
        require (_newMaxRewardTime > 0, "Max reward time not positive");
        maxRewardTime = _newMaxRewardTime;
    }

    function setMaxRewardTimePercentageGain(uint256 _newMaxRewardTimePercentageGain) external override onlyOwner {
        maxRewardTimePercentageGain = _newMaxRewardTimePercentageGain;
    }

    function setPlatform(PlatformV2 _newPlatform) external override onlyOwner {
        platform = _newPlatform;
    }

    function calculateAlphaBetaGamma(uint256 _maxSingleReward, uint256 _rewardMaxLinearX, uint256 _rewardMaxLinearY) private pure returns (uint256 alpha, uint256 beta, uint256 gamma) {
        // beta = c / a (a = y0/x0)
        beta = _maxSingleReward.mul(_rewardMaxLinearX) / _rewardMaxLinearY;

        // alpha = (2 * c ^ 2 * beta) / a (a = y0/x0)
        alpha = _maxSingleReward.mul(_maxSingleReward).mul(2).mul(beta).mul(_rewardMaxLinearX) / _rewardMaxLinearY;

        // gamma = (2 * c * beta - a * beta ^ 2) / a (a=y0/x0)
        gamma = (_maxSingleReward.mul(2).mul(beta).mul(_rewardMaxLinearX) / _rewardMaxLinearY).sub(beta.mul(beta));

        require(alpha > 0, "Alpha must be positive");
        require(beta > 0, "Beta must be positive");
        require(gamma > 0, "Gamma must be positive");
    }

    function calculatePositionUnitsFactor(uint256 _positionTimestamp) private view returns (uint256) {
        uint256 _maxRewardTime = maxRewardTime;
        uint256 time = block.timestamp.sub(_positionTimestamp);

        if (time > _maxRewardTime) {
            time = _maxRewardTime;
        }

        return PRECISION_DECIMALS.add(time.mul(maxRewardTimePercentageGain) / _maxRewardTime);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface ICVIOracleV3 {
    function getCVIRoundData(uint80 roundId) external view returns (uint16 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint16 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface IFeesCalculatorV3 {

    struct CVIValue {
        uint256 period;
        uint16 cviValue;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds) external returns (uint16);

    function setTurbulenceUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalHeartbeats, uint256 newRounds) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithTurbulence(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint16 turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    
    function calculateSingleUnitFundingFee(CVIValue[] calldata cviValues) external pure returns (uint256 fundingFee);
    function calculateClosePositionFeePercent(uint256 creationTimestamp) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function buyingPremiumFeeMaxPercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface ILiquidationV2 {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
  function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICVIOracleV3.sol";
import "./IFeesCalculatorV3.sol";
import "./IPositionRewardsV2.sol";
import "../../v1/interfaces/IFeesCollector.sol";
import "./ILiquidationV2.sol";

interface IPlatformV2 {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint16 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function openPosition(uint168 tokenAmount, uint16 maxCVI, uint168 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount);
    function closePosition(uint168 positionUnitsAmount, uint16 minCVI) external returns (uint256 tokenAmount);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);
    function getLiquidableAddresses(address[] calldata positionOwners) external view returns (address[] memory);

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setFeesCollector(IFeesCollector newCollector) external;
    function setFeesCalculator(IFeesCalculatorV3 newCalculator) external;
    function setCVIOracle(ICVIOracleV3 newOracle) external;
    function setRewards(IPositionRewardsV2 newRewards) external;
    function setLiquidation(ILiquidationV2 newLiquidation) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;

    function setLPLockupPeriod(uint256 newLPLockupPeriod) external;
    function setBuyersLockupPeriod(uint256 newBuyersLockupPeriod) external;

    function setEmergencyWithdrawAllowed(bool newEmergencyWithdrawAllowed) external;
    function setStakingContractAddress(address newStakingContractAddress) external;

    function setCanPurgeSnapshots(bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function getToken() external view returns (IERC20);

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance() external view returns (uint256 balance);
    function totalBalanceWithAddendum() external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint16 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "../../v3/PlatformV2.sol";

interface IPositionRewardsV2 {
	event Claimed(address indexed account, uint256 rewardAmount);

	function reward(address account, uint256 positionUnits, uint8 leverage) external;
	function claimReward() external;
	function calculatePositionReward(uint256 positionUnits, uint256 positionTimestamp) external view returns (uint256 rewardAmount);

	function setRewarder(address newRewarder) external;
	function setMaxDailyReward(uint256 newMaxDailyReward) external;	
	function setRewardCalculationParameters(uint256 newMaxSingleReward, uint256 rewardMaxLinearPositionUnits, uint256 rewardMaxLinearGOVI) external;
	function setRewardFactor(uint256 newRewardFactor) external;
	function setMaxClaimPeriod(uint256 newMaxClaimPeriod) external;
  	function setMaxRewardTime(uint256 newMaxRewardTime) external;
  	function setMaxRewardTimePercentageGain(uint256 _newMaxRewardTimePercentageGain) external;
	function setPlatform(PlatformV2 newPlatform) external;
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
library SafeMath168 {
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
    function add(uint168 a, uint168 b) internal pure returns (uint168) {
        uint168 c = a + b;
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
    function sub(uint168 a, uint168 b) internal pure returns (uint168) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b <= a, errorMessage);
        uint168 c = a - b;

        return c;
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
    function mul(uint168 a, uint168 b) internal pure returns (uint168) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint168 c = a * b;
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint168 a, uint168 b) internal pure returns (uint168) {
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b > 0, errorMessage);
        uint168 c = a / b;
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint168 a, uint168 b) internal pure returns (uint168) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}