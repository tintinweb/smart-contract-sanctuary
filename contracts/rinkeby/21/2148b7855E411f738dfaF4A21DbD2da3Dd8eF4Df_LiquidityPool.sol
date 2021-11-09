// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/IDefiCore.sol";
import "./interfaces/ISystemParameters.sol";
import "./interfaces/IAssetParameters.sol";
import "./interfaces/IAssetsRegistry.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IInterestRateLibrary.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/ILiquidityPoolRegistry.sol";

import "./libraries/AnnualRatesConverter.sol";
import "./libraries/DecimalsConverter.sol";

import "./Registry.sol";
import "./CompoundRateKeeper.sol";
import "./common/Globals.sol";
import "./common/AbstractDependant.sol";

contract LiquidityPool is ILiquidityPool, ERC20Upgradeable, AbstractDependant {
    using DecimalsConverter for uint256;

    IDefiCore private defiCore;
    IAssetParameters private assetParameters;
    IAssetsRegistry private assetsRegistry;
    IInterestRateLibrary private interestRateLibrary;
    IRewardsDistribution private rewardsDistribution;
    ILiquidityPoolRegistry private liquidityPoolRegistry;

    CompoundRateKeeper public compoundRateKeeper;

    uint256 public constant UPDATE_RATE_INTERVAL = 1 hours;

    address public override assetAddr;
    bytes32 public override assetKey;

    mapping(address => mapping(uint256 => uint256)) public lastLiquidity;
    mapping(address => BorrowInfo) public override borrowInfos;
    mapping(address => mapping(address => uint256)) public borrowAllowances;

    uint256 public override aggregatedBorrowedAmount;
    uint256 public aggregatedNormalizedBorrowedAmount;
    uint256 public totalReserves;

    event FundsWithdrawn(address _recipient, address _liquidityPool, uint256 _amount);
    event BorrowApproval(address _userAddr, uint256 _borrowAmount, address _delegateeAddr);

    modifier onlyDefiCore() {
        require(address(defiCore) == msg.sender, "LiquidityPool: Caller not a DefiCore.");
        _;
    }

    modifier onlyLiquidityPoolRegistry() {
        require(
            address(liquidityPoolRegistry) == msg.sender,
            "LiquidityPool: Caller not an ILiquidityPoolRegistry."
        );
        _;
    }

    function liquidityPoolInitialize(
        address _assetAddr,
        bytes32 _assetKey,
        string calldata _tokenSymbol
    ) external override initializer {
        __ERC20_init(
            string(abi.encodePacked("NewDefi ", _tokenSymbol)),
            string(abi.encodePacked("n", _tokenSymbol))
        );
        compoundRateKeeper = new CompoundRateKeeper();
        assetAddr = _assetAddr;
        assetKey = _assetKey;
    }

    function setDependencies(Registry _registry) external override onlyInjectorOrZero {
        defiCore = IDefiCore(_registry.getDefiCoreContract());
        assetParameters = IAssetParameters(_registry.getAssetParametersContract());
        assetsRegistry = IAssetsRegistry(_registry.getAssetsRegistryContract());
        interestRateLibrary = IInterestRateLibrary(_registry.getInterestRateLibraryContract());
        rewardsDistribution = IRewardsDistribution(_registry.getRewardsDistributionContract());
        liquidityPoolRegistry = ILiquidityPoolRegistry(
            _registry.getLiquidityPoolRegistryContract()
        );
    }

    function getTotalLiquidity() external view override returns (uint256) {
        return convertNTokensToAsset(totalSupply());
    }

    function getTotalBorrowedAmount() public view override returns (uint256) {
        return
            _getAbsoluteAmount(
                aggregatedNormalizedBorrowedAmount,
                compoundRateKeeper.getCurrentRate()
            );
    }

    function getAggregatedLiquidityAmount() public view override returns (uint256) {
        return
            IERC20(assetAddr).balanceOf(address(this)).convertTo18(getUnderlyingDecimals()) -
            totalReserves;
    }

    function getCurrentLiquidityAmount(address _userAddr) public view override returns (uint256) {
        return convertNTokensToAsset(balanceOf(_userAddr));
    }

    function getUserBorrowedAmount(address _userAddr) external view override returns (uint256) {
        return
            _getAbsoluteAmount(
                borrowInfos[_userAddr].normalizedAmount,
                compoundRateKeeper.getCurrentRate()
            );
    }

    function getBorrowPercentage() public view override returns (uint256) {
        return _getBorrowPercentage(0);
    }

    function getMaxToWithdraw(address _userAddr)
        public
        view
        override
        returns (uint256 _maxToWithdraw)
    {
        IDefiCore _defiCore = defiCore;
        _maxToWithdraw =
            getCurrentLiquidityAmount(_userAddr) -
            lastLiquidity[_userAddr][block.number];

        if (_defiCore.isCollateralAssetEnabled(_userAddr, assetKey)) {
            uint256 _userLiquidityInUSD = getAmountInUSD(_maxToWithdraw);
            uint256 _totalBorrowBalance = _defiCore.getTotalBorrowBalanceInUSD(_userAddr);
            uint256 _currentColRatio = assetParameters.getColRatio(assetKey);
            uint256 _residualLimit =
                _defiCore.getCurrentBorrowLimitInUSD(_userAddr) -
                    (_userLiquidityInUSD * DECIMAL) /
                    _currentColRatio;

            if (_residualLimit < _totalBorrowBalance) {
                uint256 missingAmount =
                    ((_totalBorrowBalance - _residualLimit) * _currentColRatio) / DECIMAL;
                _maxToWithdraw = getAmountFromUSD(_userLiquidityInUSD - missingAmount);
            }
        }

        uint256 _aggregatedBorrowedAmount = aggregatedBorrowedAmount;
        uint256 _maxWithdrawUR = assetParameters.getMaxUtilizationRatio(assetKey) - ONE_PERCENT; // If maxUR = 95%, maxWithdrawUR = 94% for more safety
        uint256 _maxAvailableLiquidity =
            (getAggregatedLiquidityAmount() + _aggregatedBorrowedAmount) -
                (_aggregatedBorrowedAmount * DECIMAL) /
                _maxWithdrawUR;

        _maxToWithdraw = Math.min(_maxToWithdraw, _maxAvailableLiquidity);
    }

    function getMaxToBorrow(address _userAddr) external view override returns (uint256) {
        uint256 _availableToBorrowAmount = getAvailableToBorrowLiquidity();
        (uint256 _availableLiquidityInUSD, ) = defiCore.getAvailableLiquidity(_userAddr);

        _availableLiquidityInUSD = Math.min(
            _availableLiquidityInUSD,
            getAmountInUSD(_availableToBorrowAmount)
        );
        return getAmountFromUSD(_availableLiquidityInUSD);
    }

    function getMaxToRepay(address _userAddr) external view override returns (uint256) {
        uint256 _userBalance = IERC20(assetAddr).balanceOf(_userAddr);
        uint256 _newCompoundRate = getNewCompoundRate();

        return
            Math.min(
                _userBalance.convertTo18(getUnderlyingDecimals()),
                _getAbsoluteAmount(borrowInfos[_userAddr].normalizedAmount, _newCompoundRate)
            );
    }

    function getAvailableToBorrowLiquidity() public view override returns (uint256) {
        uint256 _maxUR = assetParameters.getMaxUtilizationRatio(assetKey);
        uint256 _absoluteBorrowAmount = aggregatedBorrowedAmount;

        return
            ((_absoluteBorrowAmount + getAggregatedLiquidityAmount()) * _maxUR) /
            DECIMAL -
            _absoluteBorrowAmount;
    }

    function getAnnualBorrowRate() public view override returns (uint256 _annualBorrowRate) {
        uint256 _utilizationRatio = getBorrowPercentage();

        if (_utilizationRatio == 0) {
            return 0;
        }

        IAssetParameters.InterestRateParams memory _params =
            assetParameters.getInterestRateParams(assetKey);
        uint256 _utilizationBreakingPoint = _params.utilizationBreakingPoint;

        if (_utilizationRatio < _utilizationBreakingPoint) {
            _annualBorrowRate = AnnualRatesConverter.getAnnualRate(
                0,
                _params.firstSlope,
                _utilizationRatio,
                0,
                _utilizationBreakingPoint,
                DECIMAL
            );
        } else {
            _annualBorrowRate = AnnualRatesConverter.getAnnualRate(
                _params.firstSlope,
                _params.secondSlope,
                _utilizationRatio,
                _utilizationBreakingPoint,
                DECIMAL,
                DECIMAL
            );
        }
    }

    function getAPY() external view override returns (uint256) {
        uint256 _totalBorrowedAmount = aggregatedBorrowedAmount;
        uint256 _currentTotalSupply = totalSupply();

        if (_currentTotalSupply == 0) {
            return 0;
        }

        uint256 _currentInterest =
            _getPercentageOfNumber(_totalBorrowedAmount, DECIMAL + getAnnualBorrowRate()) -
                _totalBorrowedAmount;

        return
            (_currentInterest * (DECIMAL - assetParameters.getReserveFactor(assetKey))) /
            _currentTotalSupply;
    }

    function convertAssetToNTokens(uint256 _assetAmount) public view override returns (uint256) {
        return (_assetAmount * DECIMAL) / exchangeRate();
    }

    function convertNTokensToAsset(uint256 _nTokensAmount) public view override returns (uint256) {
        return (_nTokensAmount * exchangeRate()) / DECIMAL;
    }

    function exchangeRate() public view override returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            return DECIMAL;
        }

        uint256 _aggregatedBorrowedAmount = aggregatedBorrowedAmount;
        uint256 _currentBorrowInterest =
            ((getTotalBorrowedAmount() - _aggregatedBorrowedAmount) *
                (DECIMAL - assetParameters.getReserveFactor(assetKey))) / DECIMAL;

        return
            ((_currentBorrowInterest +
                _aggregatedBorrowedAmount +
                getAggregatedLiquidityAmount()) * DECIMAL) / _totalSupply;
    }

    function getAmountInUSD(uint256 _assetAmount) public view override returns (uint256) {
        return (_assetAmount * getAssetPrice()) / ONE_TOKEN;
    }

    function getAmountFromUSD(uint256 _usdAmount) public view override returns (uint256) {
        return (_usdAmount * ONE_TOKEN) / getAssetPrice();
    }

    function getAssetPrice() public view override returns (uint256) {
        return assetParameters.getAssetPrice(assetKey, getUnderlyingDecimals());
    }

    function getFreezeStatus() public view override returns (bool) {
        return assetParameters.isPoolFrozen(assetKey);
    }

    function getUnderlyingDecimals() public view override returns (uint8) {
        return ERC20(assetAddr).decimals();
    }

    function getCurrentRate() public view override returns (uint256) {
        return compoundRateKeeper.getCurrentRate();
    }

    function getNewCompoundRate() public view override returns (uint256) {
        return
            compoundRateKeeper.getNewCompoundRate(
                AnnualRatesConverter.convertToRatePerSecond(
                    interestRateLibrary,
                    getAnnualBorrowRate(),
                    ONE_PERCENT
                )
            );
    }

    function updateCompoundRate() public override returns (uint256) {
        return
            compoundRateKeeper.update(
                AnnualRatesConverter.convertToRatePerSecond(
                    interestRateLibrary,
                    getAnnualBorrowRate(),
                    ONE_PERCENT
                )
            );
    }

    function addLiquidity(address _userAddr, uint256 _liquidityAmount)
        external
        override
        onlyDefiCore
    {
        uint256 _assetAmount = _convertToUnderlyingAsset(_liquidityAmount);

        require(
            IERC20(assetAddr).balanceOf(_userAddr) >= _assetAmount,
            "LiquidityPool: Not enough tokens on account."
        );

        _updateCompoundRate();

        uint256 _mintAmount = convertAssetToNTokens(_liquidityAmount);

        lastLiquidity[_userAddr][block.number] += _mintAmount;

        _mint(_userAddr, _mintAmount);

        IERC20(assetAddr).transferFrom(_userAddr, address(this), _assetAmount);
    }

    function withdrawLiquidityMax(address _userAddr) external override onlyDefiCore {
        _updateCompoundRate();

        uint256 _maxToWithdraw = getMaxToWithdraw(_userAddr);

        _burn(_userAddr, convertAssetToNTokens(_maxToWithdraw));

        IERC20(assetAddr).transfer(_userAddr, _convertToUnderlyingAsset(_maxToWithdraw));
    }

    function withdrawLiquidity(address _userAddr, uint256 _liquidityAmount)
        external
        override
        onlyDefiCore
    {
        require(
            getAggregatedLiquidityAmount() >= _liquidityAmount,
            "LiquidityPool: Not enough liquidity available on the contract."
        );

        _updateCompoundRate();

        uint256 _burnAmount = convertAssetToNTokens(_liquidityAmount);

        require(
            balanceOf(_userAddr) - lastLiquidity[_userAddr][block.number] >= _burnAmount,
            "LiquidityPool: Not enough nTokens to withdraw liquidity."
        );

        _burn(_userAddr, _burnAmount);

        IERC20(assetAddr).transfer(_userAddr, _convertToUnderlyingAsset(_liquidityAmount));

        require(
            getBorrowPercentage() <= assetParameters.getMaxUtilizationRatio(assetKey),
            "LiquidityPool: Utilization ratio after withdraw cannot be greater than the maximum."
        );
    }

    function approveToBorrow(
        address _userAddr,
        uint256 _borrowAmount,
        address _delegateeAddr,
        uint256 _currentAllowance
    ) external override onlyDefiCore {
        require(
            borrowAllowances[_userAddr][_delegateeAddr] == _currentAllowance,
            "LiquidityPool: The current allowance is not the same as expected."
        );
        borrowAllowances[_userAddr][_delegateeAddr] = _borrowAmount;

        emit BorrowApproval(_userAddr, _borrowAmount, _delegateeAddr);
    }

    function borrow(address _userAddr, uint256 _amountToBorrow) external override onlyDefiCore {
        _borrowInternal(_userAddr, _amountToBorrow);

        IERC20(assetAddr).transfer(_userAddr, _convertToUnderlyingAsset(_amountToBorrow));
    }

    function delegateBorrow(
        address _userAddr,
        address _delegatee,
        uint256 _amountToBorrow
    ) external override onlyDefiCore {
        uint256 borrowAllowance = borrowAllowances[_userAddr][_delegatee];

        require(
            borrowAllowance >= _amountToBorrow,
            "LiquidityPool: Not enough allowed to borrow amount."
        );

        _borrowInternal(_userAddr, _amountToBorrow);

        borrowAllowances[_userAddr][_delegatee] = borrowAllowance - _amountToBorrow;

        IERC20(assetAddr).transfer(_delegatee, _convertToUnderlyingAsset(_amountToBorrow));
    }

    function borrowFor(
        address _userAddr,
        address _delegator,
        uint256 _amountToBorrow
    ) external override onlyDefiCore {
        _borrowInternal(_userAddr, _amountToBorrow);

        IERC20(assetAddr).transfer(_delegator, _convertToUnderlyingAsset(_amountToBorrow));
    }

    function repayBorrow(
        address _userAddr,
        uint256 _repayAmount,
        bool _isMaxRepay
    ) external override onlyDefiCore returns (uint256) {
        return _closeBorrow(_userAddr, _userAddr, _repayAmount, _isMaxRepay);
    }

    function liquidate(
        address _userAddr,
        address _liquidatorAddr,
        uint256 _liquidityAmount
    ) external override onlyDefiCore {
        require(
            getAggregatedLiquidityAmount() >= _liquidityAmount,
            "LiquidityPool: Not enough liquidity available on the contract."
        );

        _updateCompoundRate();

        uint256 _burnAmount = convertAssetToNTokens(_liquidityAmount);

        require(
            balanceOf(_userAddr) >= _burnAmount,
            "LiquidityPool: Not enough nTokens to liquidate amount."
        );

        _burn(_userAddr, _burnAmount);

        IERC20(assetAddr).transfer(_liquidatorAddr, _convertToUnderlyingAsset(_liquidityAmount));
    }

    function closeBorrow(
        address _userAddr,
        address _closureAddr,
        uint256 _closeAmount
    ) external override onlyDefiCore returns (uint256) {
        return _closeBorrow(_userAddr, _closureAddr, _closeAmount, false);
    }

    function withdrawReservedFunds(
        address _recipientAddr,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external override onlyLiquidityPoolRegistry {
        uint256 _currentReserveAmount = totalReserves;

        if (_currentReserveAmount == 0) {
            return;
        }

        if (_isAllFunds) {
            _amountToWithdraw = _currentReserveAmount;
        } else {
            require(
                _amountToWithdraw <= _currentReserveAmount,
                "LiquidityPool: Not enough reserved funds."
            );
        }

        totalReserves = _currentReserveAmount - _amountToWithdraw;

        IERC20(assetAddr).transfer(_recipientAddr, _convertToUnderlyingAsset(_amountToWithdraw));

        emit FundsWithdrawn(_recipientAddr, address(this), _amountToWithdraw);
    }

    function _getNormalizedAmount(
        uint256 _normalizedAmount,
        uint256 _additionalAmount,
        uint256 _currentRate,
        bool _isAdding
    ) internal pure returns (uint256) {
        uint256 normalizedAdditionalAmount = (_additionalAmount * DECIMAL) / _currentRate;

        return
            _isAdding
                ? _normalizedAmount + normalizedAdditionalAmount
                : _normalizedAmount - normalizedAdditionalAmount;
    }

    function _getAbsoluteAmount(uint256 _normalizedAmount, uint256 _currentRate)
        internal
        pure
        returns (uint256)
    {
        return (_normalizedAmount * _currentRate) / DECIMAL;
    }

    function _getPercentageOfNumber(uint256 _number, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_number * _percentage) / DECIMAL;
    }

    function _getBorrowPercentage(uint256 _additionalBorrowAmount)
        internal
        view
        returns (uint256)
    {
        uint256 _absoluteBorrowAmount = aggregatedBorrowedAmount + _additionalBorrowAmount;
        uint256 _aggregatedLiquidityAmount =
            getAggregatedLiquidityAmount() - _additionalBorrowAmount;

        if (_aggregatedLiquidityAmount == 0 && _absoluteBorrowAmount == 0) {
            return 0;
        }

        return
            (_absoluteBorrowAmount * DECIMAL) /
            (_absoluteBorrowAmount + _aggregatedLiquidityAmount);
    }

    function _convertToUnderlyingAsset(uint256 _amountToConvert)
        internal
        view
        returns (uint256 _assetAmount)
    {
        _assetAmount = _amountToConvert.convertFrom18(getUnderlyingDecimals());

        require(_assetAmount > 0, "LiquidityPool: Incorrect asset amount after conversion.");
    }

    function _updateCompoundRate() internal returns (uint256) {
        if (compoundRateKeeper.getLastUpdate() + UPDATE_RATE_INTERVAL > block.timestamp) {
            return compoundRateKeeper.getCurrentRate();
        } else {
            return updateCompoundRate();
        }
    }

    function _borrowInternal(address _userAddr, uint256 _amountToBorrow) internal {
        require(
            getAggregatedLiquidityAmount() >= _amountToBorrow,
            "LiquidityPool: Not enough available to borrow amount."
        );

        uint256 _currentRate = _updateCompoundRate();

        require(
            _getBorrowPercentage(_amountToBorrow) <=
                assetParameters.getMaxUtilizationRatio(assetKey),
            "LiquidityPool: Utilization ratio after borrow cannot be greater than the maximum."
        );

        borrowInfos[_userAddr] = BorrowInfo(
            borrowInfos[_userAddr].borrowAmount + _amountToBorrow,
            _getNormalizedAmount(
                borrowInfos[_userAddr].normalizedAmount,
                _amountToBorrow,
                _currentRate,
                true
            )
        );

        aggregatedBorrowedAmount += _amountToBorrow;

        aggregatedNormalizedBorrowedAmount = _getNormalizedAmount(
            aggregatedNormalizedBorrowedAmount,
            _amountToBorrow,
            _currentRate,
            true
        );
    }

    function _closeBorrow(
        address _userAddr,
        address _closureAddr,
        uint256 _closeAmount,
        bool _isMaxRepay
    ) internal returns (uint256) {
        uint256 _currentRate = updateCompoundRate(); // Need to update without interval
        uint256 _currentNormalizedAmount = borrowInfos[_userAddr].normalizedAmount;
        uint256 _currentAbsoluteAmount =
            _getAbsoluteAmount(_currentNormalizedAmount, _currentRate);

        if (_currentAbsoluteAmount == 0) {
            return 0;
        }

        if (_isMaxRepay) {
            _closeAmount = Math.min(
                IERC20(assetAddr).balanceOf(_userAddr).convertTo18(getUnderlyingDecimals()),
                _currentAbsoluteAmount
            );

            require(
                _closeAmount > 0,
                "LiquidityPool: It is impossible to repay borrow without funds on the balance."
            );
        } else {
            _closeAmount = Math.min(_currentAbsoluteAmount, _closeAmount);
        }

        uint256 _currentInterest = _currentAbsoluteAmount - borrowInfos[_userAddr].borrowAmount;

        if (_closeAmount > _currentInterest) {
            borrowInfos[_userAddr].borrowAmount = _currentAbsoluteAmount - _closeAmount;

            aggregatedBorrowedAmount -= _closeAmount - _currentInterest;
        }

        if (aggregatedBorrowedAmount == 0) {
            aggregatedNormalizedBorrowedAmount = 0;
        } else {
            aggregatedNormalizedBorrowedAmount = _getNormalizedAmount(
                aggregatedNormalizedBorrowedAmount,
                _closeAmount,
                _currentRate,
                false
            );
        }

        if (borrowInfos[_userAddr].borrowAmount == 0) {
            borrowInfos[_userAddr].normalizedAmount = 0;
        } else {
            borrowInfos[_userAddr].normalizedAmount = _getNormalizedAmount(
                _currentNormalizedAmount,
                _closeAmount,
                _currentRate,
                false
            );
        }

        uint256 _reserveFunds =
            _getPercentageOfNumber(_currentInterest, assetParameters.getReserveFactor(assetKey));

        totalReserves += _reserveFunds;

        IERC20(assetAddr).transferFrom(
            _closureAddr,
            address(this),
            _convertToUnderlyingAsset(_closeAmount)
        );

        return _closeAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to != address(0)) {
            IDefiCore _defiCore = defiCore;
            IRewardsDistribution _rewardsDistribution = rewardsDistribution;

            if (_defiCore.isCollateralAssetEnabled(from, assetKey)) {
                uint256 _newBorrowLimit =
                    _defiCore.getNewBorrowLimitInUSD(from, assetKey, amount, false);
                require(
                    _newBorrowLimit >= _defiCore.getTotalBorrowBalanceInUSD(from),
                    "LiquidityPool: Borrow limit used after transfer greater than 100%."
                );
            }

            assetsRegistry.updateAssetsAfterTransfer(assetKey, from, to, amount);
            _rewardsDistribution.updateCumulativeSums(from, this);
            _rewardsDistribution.updateCumulativeSums(to, this);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "../interfaces/IInterestRateLibrary.sol";

library AnnualRatesConverter {
    function getAnnualRate(
        uint256 _lowInterestPercentage,
        uint256 _highInterestPercentage,
        uint256 _currentUR,
        uint256 _lowURPercentage,
        uint256 _highURPercentage,
        uint256 _decimal
    ) internal pure returns (uint256) {
        uint256 _interestPerPercent =
            ((_highInterestPercentage - _lowInterestPercentage) * _decimal) /
                (_highURPercentage - _lowURPercentage);

        return
            (_interestPerPercent * (_currentUR - _lowURPercentage)) /
            _decimal +
            _lowInterestPercentage;
    }

    function convertToRatePerSecond(
        IInterestRateLibrary _library,
        uint256 _interestRatePerYear,
        uint256 _onePercent
    ) internal view returns (uint256) {
        uint256 _libraryPrecision = _library.getLibraryPrecision();

        require(
            _interestRatePerYear * _libraryPrecision <=
                _library.maxSupportedPercentage() * _onePercent,
            "AnnualRatesConverter: Interest rate is not supported."
        );

        uint256 _precisionFactor = _libraryPrecision;

        if (
            _interestRatePerYear * _libraryPrecision <
            _library.getLimitOfExactValues() * _onePercent
        ) {
            _interestRatePerYear *= _libraryPrecision;

            _precisionFactor = 1;
        }

        uint256 _leftBorder = (_interestRatePerYear / _onePercent) * _precisionFactor;
        uint256 _rightBorder = _leftBorder + _precisionFactor;

        if (_interestRatePerYear % _onePercent == 0) {
            return _library.ratesPerSecond(_leftBorder);
        }

        uint256 _firstRatePerSecond = _library.ratesPerSecond(_leftBorder);
        uint256 _secondRatePerSecond = _library.ratesPerSecond(_rightBorder);

        return
            ((_secondRatePerSecond - _firstRatePerSecond) *
                (_interestRatePerYear - (_leftBorder * _onePercent) / _precisionFactor)) /
            _onePercent +
            _firstRatePerSecond;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ISystemParameters {
    event UintParamUpdated(bytes32 _paramKey, uint256 _newValue);

    /**
     * @notice Getter for parameter by key LIQUIDATION_BOUNDARY_KEY
     * @return current liquidation boundary parameter value
     */
    function getLiquidationBoundaryParam() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./ILiquidityPool.sol";

interface IRewardsDistribution {
    struct LiquidityPoolInfo {
        uint256 rewardPerBlock;
        uint256 supplyCumulativeSum;
        uint256 borrowCumulativeSum;
        uint256 lastUpdate;
    }

    struct UserDistributionInfo {
        uint256 lastSupplyCumulativeSum;
        uint256 lastBorrowCumulativeSum;
        uint256 aggregatedReward;
    }

    /**
     * @notice Returns APY for a specific liquidity pool
     * @param _liquidityPool Required liquidity pool
     * @return _supplyAPY - current supply APY
     * @return _borrowAPY - current borrow APY
     */
    function getAPY(ILiquidityPool _liquidityPool)
        external
        view
        returns (uint256 _supplyAPY, uint256 _borrowAPY);

    /**
     * @notice Returns current user reward of Governance Tokens
     * @param _assetKey Asset key of the liquidity pool
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     * @return _userReward - current user reward
     */
    function getUserReward(
        bytes32 _assetKey,
        address _userAddr,
        ILiquidityPool _liquidityPool
    ) external view returns (uint256 _userReward);

    /**
     * @notice Function for updating cumulative sums. Can only be called from DefiCore
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     */
    function updateCumulativeSums(address _userAddr, ILiquidityPool _liquidityPool) external;

    /**
     * @notice Function for withdraw accumulated rewards. Can only be called from DefiCore
     * @dev Cumulative sums are updated before withdrawal
     * @param _assetKey Asset key of the liquidity pool
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     * @return _userReward - current user reward
     */
    function withdrawUserReward(
        bytes32 _assetKey,
        address _userAddr,
        ILiquidityPool _liquidityPool
    ) external returns (uint256 _userReward);

    /**
     * @notice Function to update rewards per block
     * @dev The passed arrays must be of the same length
     * @param _assetKeys Arrays of asset keys
     * @param _rewardsPerBlock Arrays of new rewards per block
     */
    function setupRewardsPerBlockBatch(
        bytes32[] calldata _assetKeys,
        uint256[] calldata _rewardsPerBlock
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./IAssetParameters.sol";

interface ILiquidityPoolRegistry {
    event PoolAdded(bytes32 _assetKey, address _assetAddr, address _poolAddr);

    struct PoolAPYInfo {
        uint256 supplyAPY;
        uint256 borrowAPY;
        uint256 distrSupplyAPY;
        uint256 distrBorrowAPY;
    }

    struct LiquidityPoolInfo {
        bytes32 assetKey;
        uint256 marketSize;
        uint256 marketSizeInUsd;
        uint256 totalBorrowBalance;
        uint256 totalBorrowBalanceInUsd;
        PoolAPYInfo apyInfo;
    }

    struct DetailedLiquidityPoolInfo {
        uint256 totalBorrowed;
        uint256 availableLiquidity;
        uint256 utilizationRatio;
        IAssetParameters.LiquidityPoolParams liquidityPoolParams;
        PoolAPYInfo apyInfo;
    }

    function getAllSupportedAssets() external view returns (bytes32[] memory _resultArr);

    function getAllLiquidityPools() external view returns (address[] memory _resultArr);

    function getSupportedAssets(uint256 _offset, uint256 _limit)
        external
        view
        returns (bytes32[] memory _resultArr);

    function getLiquidityPools(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _resultArr);

    /**
     * @notice Returns the address of the liquidity pool by the asset key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return address of the liquidity pool
     */
    function liquidityPools(bytes32 _assetKey) external view returns (address);

    /**
     * @notice Indicates whether the address is a liquidity pool
     * @param _poolAddr Address of the liquidity pool
     * @return true if the passed address is a liquidity pool, false otherwise
     */
    function existingLiquidityPools(address _poolAddr) external view returns (bool);

    function onlyExistingPool(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Returns the address of the liquidity pool for the governance token
     * @return liquidity pool address for the governance token
     */
    function getGovernanceLiquidityPool() external view returns (address);

    function getTotalMarketsSize() external view returns (uint256 _totalMarketSize);

    function getLiquidityPoolsInfo(uint256 _offset, uint256 _limit)
        external
        view
        returns (LiquidityPoolInfo[] memory _resultArr);

    function getDetailedLiquidityPoolInfo(bytes32 _assetKey)
        external
        view
        returns (DetailedLiquidityPoolInfo memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ILiquidityPool {
    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 normalizedAmount;
    }

    function liquidityPoolInitialize(
        address _assetAddr,
        bytes32 _assetKey,
        string memory _tokenSymbol
    ) external;

    function assetAddr() external view returns (address);

    function assetKey() external view returns (bytes32);

    function borrowInfos(address _userAddr)
        external
        view
        returns (uint256 _borrowAmount, uint256 _normalizedAmount);

    function aggregatedBorrowedAmount() external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);

    function getTotalBorrowedAmount() external view returns (uint256);

    function getAggregatedLiquidityAmount() external view returns (uint256);

    function getCurrentLiquidityAmount(address _userAddr) external view returns (uint256);

    function getUserBorrowedAmount(address _userAddr) external view returns (uint256);

    function getBorrowPercentage() external view returns (uint256);

    function getMaxToWithdraw(address _userAddr) external view returns (uint256 _maxToWithdraw);

    function getMaxToBorrow(address _userAddr) external view returns (uint256);

    function getMaxToRepay(address _userAddr) external view returns (uint256);

    function getAvailableToBorrowLiquidity() external view returns (uint256);

    function getAnnualBorrowRate() external view returns (uint256 _annualBorrowRate);

    function getAPY() external view returns (uint256);

    function convertAssetToNTokens(uint256 _assetAmount) external view returns (uint256);

    function convertNTokensToAsset(uint256 _nTokensAmount) external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getAmountInUSD(uint256 _assetAmount) external view returns (uint256);

    function getAmountFromUSD(uint256 _usdAmount) external view returns (uint256);

    function getAssetPrice() external view returns (uint256);

    function getFreezeStatus() external view returns (bool);

    function getUnderlyingDecimals() external view returns (uint8);

    function getCurrentRate() external view returns (uint256);

    function getNewCompoundRate() external view returns (uint256);

    function updateCompoundRate() external returns (uint256);

    function addLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function withdrawLiquidityMax(address _userAddr) external;

    function withdrawLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function approveToBorrow(
        address _userAddr,
        uint256 _borrowAmount,
        address _borrowalAddr,
        uint256 _expectedAllowance
    ) external;

    function borrow(address _userAddr, uint256 _amountToBorrow) external;

    function repayBorrow(
        address _userAddr,
        uint256 _repayAmount,
        bool _isMaxRepay
    ) external returns (uint256);

    function delegateBorrow(
        address _userAddr,
        address _delegator,
        uint256 _amountToBorrow
    ) external;

    function liquidate(
        address _userAddr,
        address _liquidatorAddr,
        uint256 _liquidityAmount
    ) external;

    function closeBorrow(
        address _userAddr,
        address _closureAddr,
        uint256 _closeAmount
    ) external returns (uint256);

    function withdrawReservedFunds(
        address _recipientAddr,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external;

    function borrowFor(
        address _userAddr,
        address _delegator,
        uint256 _amountToBorrow
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IInterestRateLibrary {
    /**
     * @notice The function returns the second rate for the passed annual rate
     * @param _annualRate Annual rate to be converted
     * @return _ratePerSecond - converted second rate
     */
    function ratesPerSecond(uint256 _annualRate) external view returns (uint256 _ratePerSecond);

    /**
     * @notice The function returns the library precision
     * @dev For default library precision equals to 10^1
     * @return _libraryPrecision - current library precision
     */
    function getLibraryPrecision() external view returns (uint256 _libraryPrecision);

    /**
     * @notice The function returns the limit of exact values with current library precision
     * @return limit of exact values
     */
    function getLimitOfExactValues() external view returns (uint256);

    /**
     * @notice The function returns the current max supported percentage
     * @return max supported percentage with library decimals
     */
    function maxSupportedPercentage() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IDefiCore {
    struct RewardsDistributionInfo {
        address assetAddr;
        uint256 distributionReward;
        uint256 distributionRewardInUSD;
        uint256 userBalance;
        uint256 userBalanceInUSD;
    }

    struct LiquidationInfo {
        bytes32[] borrowAssetKeys;
        bytes32[] supplyAssetKeys;
        uint256 totalBorrowedAmount;
    }

    struct UserLiquidationInfo {
        uint256 borrowAssetPrice;
        uint256 receiveAssetPrice;
        uint256 bonusReceiveAssetPrice;
        uint256 borrowedAmount;
        uint256 supplyAmount;
        uint256 maxQuantity;
    }

    event LiquidateBorrow(bytes32 _paramKey, address _userAddr, uint256 _amount);
    event LiquidatorPay(bytes32 _paramKey, address _liquidatorAddr, uint256 _amount);

    function isCollateralAssetEnabled(address _userAddr, bytes32 _assetKey)
        external
        view
        returns (bool);

    function getAvailableLiquidity(address _userAddr) external view returns (uint256, uint256);

    function getTotalBorrowBalanceInUSD(address _userAddr)
        external
        view
        returns (uint256 _totalBorrowBalance);

    function getCurrentBorrowLimitInUSD(address _userAddr)
        external
        view
        returns (uint256 _currentBorrowLimit);

    function getNewBorrowLimitInUSD(
        address _userAddr,
        bytes32 _assetKey,
        uint256 _tokensAmount,
        bool _isAdding
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetsRegistry {
    struct SupplyAssetInfo {
        address assetAddr;
        uint256 supplyAPY;
        uint256 distributionSupplyAPY;
        uint256 userSupplyBalanceInUSD;
        uint256 userSupplyBalance;
        MaxSupplyValues maxSupplyValues;
        bool isPossibleToBeCollateral;
        bool isCollateralEnabled;
    }

    struct BorrowAssetInfo {
        address assetAddr;
        uint256 borrowAPY;
        uint256 distributionBorrowAPY;
        uint256 userBorrowBalanceInUSD;
        uint256 userBorrowBalance;
        MaxBorrowValues maxBorrowValues;
        uint256 borrowPercentage;
    }

    struct AssetInfo {
        address assetAddr;
        uint256 apy;
        uint256 distributionAPY;
        uint256 userBalanceInUSD;
        uint256 userBalance;
        uint256 poolCapacity;
        uint256 maxValue;
        bool isPossibleToBeCollateral;
        bool isCollateralEnabled;
    }

    struct MaxSupplyValues {
        uint256 maxToSupply;
        uint256 maxToWithdraw;
    }

    struct MaxBorrowValues {
        uint256 maxToBorrow;
        uint256 maxToRepay;
    }

    function getUserSupplyAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _userSupplyAssets);

    function getUserBorrowAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _userBorrowAssets);

    function getSupplyAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userSupplyAssets);

    function getBorrowAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userBorrowAssets);

    function getSupplyAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (SupplyAssetInfo[] memory _resultArr);

    function getBorrowAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (BorrowAssetInfo[] memory _resultArr);

    function getAssetsInfo(
        bytes32[] memory _assetsKeys,
        address _userAddr,
        bool _isSupply
    ) external view returns (AssetInfo[] memory _resultArr);

    function updateAssetsAfterTransfer(
        bytes32 _assetKey,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function updateSupplyAssets(
        address _userAddr,
        bytes32 _assetKey,
        address _liquidityPoolAddr
    ) external;

    function updateBorrowAssets(
        address _userAddr,
        bytes32 _assetKey,
        address _liquidityPoolAddr
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetParameters {
    event UintParamUpdated(bytes32 _assetKey, bytes32 _paramKey, uint256 _newValue);
    event BoolParamUpdated(bytes32 _assetKey, bytes32 _paramKey, bool _newValue);

    struct InterestRateParams {
        uint256 basePercentage;
        uint256 firstSlope;
        uint256 secondSlope;
        uint256 utilizationBreakingPoint;
    }

    struct LiquidityPoolParams {
        uint256 collateralizationRatio;
        uint256 reserveFactor;
        uint256 liquidationDiscount;
        uint256 maxUtilizationRatio;
        bool isAvailableAsCollateral;
    }

    /**
     * @notice Shows whether the pool is frozen by the given key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isPoolFrozen(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Shows the ability of an aset to be a collateral
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isAvailableAsCollateral(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Returns parameters for calculating interest rates on a loan
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _params - structure object with parameters for calculating interest rates
     */
    function getInterestRateParams(bytes32 _assetKey)
        external
        view
        returns (InterestRateParams memory _params);

    /**
     * @notice Returns the maximum possible utilization ratio
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return maximum possible utilization ratio
     */
    function getMaxUtilizationRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the discount for the liquidator in the desired pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return liquidation discount
     */
    function getLiquidationDiscount(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the minimum percentages of the parties for the distribution of governance tokens
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _minSupplyPart the minimum part that goes to depositors
     * @return _minBorrowPart the minimum part that goes to borrowers
     */
    function getDistributionMinimums(bytes32 _assetKey)
        external
        view
        returns (uint256 _minSupplyPart, uint256 _minBorrowPart);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current collateralization ratio value
     */
    function getColRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current reserve factor value
     */
    function getReserveFactor(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the price of a token in dollars
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return asset price
     */
    function getAssetPrice(bytes32 _assetKey, uint8 _assetDecimals)
        external
        view
        returns (uint256);

    function getLiquidityPoolParams(bytes32 _assetKey)
        external
        view
        returns (LiquidityPoolParams memory);

    function addLiquidityPoolAssetInfo(bytes32 _assetKey, bool _isCollateral) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Upgrader {
    address private immutable _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "DependencyInjector: Not an owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function upgrade(address what, address to) external onlyOwner {
        TransparentUpgradeableProxy(payable(what)).upgradeTo(to);
    }

    function upgradeAndCall(
        address what,
        address to,
        bytes calldata data
    ) external onlyOwner {
        TransparentUpgradeableProxy(payable(what)).upgradeToAndCall(to, data);
    }

    function getImplementation(address what) external onlyOwner returns (address) {
        return TransparentUpgradeableProxy(payable(what)).implementation();
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint8 constant STANDARD_DECIMALS = 18;
uint256 constant ONE_TOKEN = 10**STANDARD_DECIMALS;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;

// SPDX-License-Identifier: ALGPL-3.0-or-later-or-later
// from https://github.com/makerdao/dss/blob/master/src/jug.sol
pragma solidity 0.8.3;

library DSMath {
    /// @dev github.com/makerdao/dss implementation
    /// of exponentiation by squaring
    //  nth power of x mod b
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := b
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := b
                        }
                        default {
                            z := x
                        }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "../Registry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(Registry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./common/Upgrader.sol";
import "./common/AbstractDependant.sol";

contract Registry is AccessControl {
    Upgrader private immutable upgrader;

    mapping(bytes32 => address) private _contracts;
    mapping(address => bool) private _isProxy;

    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant SYSTEM_PARAMETERS_NAME = keccak256("SYSTEM_PARAMETERS");
    bytes32 public constant ASSET_PARAMETERS_NAME = keccak256("ASSET_PARAMETERS");
    bytes32 public constant DEFI_CORE_NAME = keccak256("DEFI_CORE");
    bytes32 public constant INTEREST_RATE_LIBRARY_NAME = keccak256("INTEREST_RATE_LIBRARY");
    bytes32 public constant LIQUIDITY_POOL_FACTORY_NAME = keccak256("LIQUIDITY_POOL_FACTORY");
    bytes32 public constant GOVERNANCE_TOKEN_NAME = keccak256("GOVERNANCE_TOKEN");
    bytes32 public constant REWARDS_DISTRIBUTION_NAME = keccak256("REWARDS_DISTRIBUTION");
    bytes32 public constant PRICE_MANAGER_NAME = keccak256("PRICE_MANAGER");
    bytes32 public constant ASSETS_REGISTRY_NAME = keccak256("ASSETS_REGISTRY");
    bytes32 public constant LIQUIDITY_POOL_ADMIN_NAME = keccak256("LIQUIDITY_POOL_ADMIN");
    bytes32 public constant LIQUIDITY_POOL_REGISTRY_NAME = keccak256("LIQUIDITY_POOL_REGISTRY");

    event ContractAdded(bytes32 _name, address _contractAddress);
    event ProxyContractAdded(bytes32 _name, address _proxyAddress, address _implAddress);

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "Registry: Caller is not an admin");
        _;
    }

    constructor() {
        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);

        upgrader = new Upgrader();
    }

    function getSystemParametersContract() external view returns (address) {
        return getContract(SYSTEM_PARAMETERS_NAME);
    }

    function getAssetParametersContract() external view returns (address) {
        return getContract(ASSET_PARAMETERS_NAME);
    }

    function getDefiCoreContract() external view returns (address) {
        return getContract(DEFI_CORE_NAME);
    }

    function getInterestRateLibraryContract() external view returns (address) {
        return getContract(INTEREST_RATE_LIBRARY_NAME);
    }

    function getLiquidityPoolFactoryContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_FACTORY_NAME);
    }

    function getGovernanceTokenContract() external view returns (address) {
        return getContract(GOVERNANCE_TOKEN_NAME);
    }

    function getRewardsDistributionContract() external view returns (address) {
        return getContract(REWARDS_DISTRIBUTION_NAME);
    }

    function getPriceManagerContract() external view returns (address) {
        return getContract(PRICE_MANAGER_NAME);
    }

    function getAssetsRegistryContract() external view returns (address) {
        return getContract(ASSETS_REGISTRY_NAME);
    }

    function getLiquidityPoolAdminContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_ADMIN_NAME);
    }

    function getLiquidityPoolRegistryContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_REGISTRY_NAME);
    }

    function getContract(bytes32 _name) public view returns (address) {
        require(_contracts[_name] != address(0), "Registry: This mapping doesn't exist");

        return _contracts[_name];
    }

    function hasContract(bytes32 _name) external view returns (bool) {
        return _contracts[_name] != address(0);
    }

    function getUpgrader() external view returns (address) {
        require(address(upgrader) != address(0), "Registry: Bad upgrader.");

        return address(upgrader);
    }

    function getImplementation(bytes32 _name) external returns (address) {
        address _contractProxy = _contracts[_name];

        require(_contractProxy != address(0), "Registry: This mapping doesn't exist.");
        require(_isProxy[_contractProxy], "Registry: Not a proxy contract.");

        return upgrader.getImplementation(_contractProxy);
    }

    function injectDependencies(bytes32 _name) external onlyAdmin {
        address contractAddress = _contracts[_name];

        require(contractAddress != address(0), "Registry: This mapping doesn't exist.");

        AbstractDependant dependant = AbstractDependant(contractAddress);

        if (dependant.injector() == address(0)) {
            dependant.setInjector(address(this));
        }

        dependant.setDependencies(this);
    }

    function upgradeContract(bytes32 _name, address _newImplementation) external onlyAdmin {
        _upgradeContract(_name, _newImplementation, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradeContractAndCall(
        bytes32 _name,
        address _newImplementation,
        string calldata _functionSignature
    ) external onlyAdmin {
        _upgradeContract(_name, _newImplementation, _functionSignature);
    }

    function _upgradeContract(
        bytes32 _name,
        address _newImplementation,
        string memory _functionSignature
    ) internal {
        address _contractToUpgrade = _contracts[_name];

        require(_contractToUpgrade != address(0), "Registry: This mapping doesn't exist.");
        require(_isProxy[_contractToUpgrade], "Registry: Not a proxy contract.");

        if (bytes(_functionSignature).length > 0) {
            upgrader.upgradeAndCall(
                _contractToUpgrade,
                _newImplementation,
                abi.encodeWithSignature(_functionSignature)
            );
        } else {
            upgrader.upgrade(_contractToUpgrade, _newImplementation);
        }
    }

    function addContract(bytes32 _name, address _contractAddress) external onlyAdmin {
        require(_contractAddress != address(0), "Registry: Null address is forbidden.");
        require(_contracts[_name] == address(0), "Registry: Unable to change the contract.");

        _contracts[_name] = _contractAddress;

        emit ContractAdded(_name, _contractAddress);
    }

    function addProxyContract(bytes32 _name, address _contractAddress) external onlyAdmin {
        require(_contractAddress != address(0), "Registry: Null address is forbidden.");
        require(_contracts[_name] == address(0), "Registry: Unable to change the contract.");

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(_contractAddress, address(upgrader), "");

        _contracts[_name] = address(proxy);
        _isProxy[address(proxy)] = true;

        emit ProxyContractAdded(_name, address(proxy), _contractAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/DSMath.sol";
import "./common/Globals.sol";

contract CompoundRateKeeper is Ownable {
    struct CompoundRate {
        uint256 rate;
        uint256 lastUpdate;
    }

    CompoundRate public compoundRate;

    constructor() {
        compoundRate = CompoundRate(DECIMAL, block.timestamp);
    }

    function getCurrentRate() external view returns (uint256) {
        return compoundRate.rate;
    }

    function getLastUpdate() external view returns (uint256) {
        return compoundRate.lastUpdate;
    }

    function update(uint256 _interestRate) external onlyOwner returns (uint256 _newRate) {
        _newRate = getNewCompoundRate(_interestRate);

        compoundRate.rate = _newRate;
        compoundRate.lastUpdate = block.timestamp;
    }

    function getNewCompoundRate(uint256 _interestRate) public view returns (uint256 _newRate) {
        uint256 _period = block.timestamp - compoundRate.lastUpdate;
        _newRate =
            (compoundRate.rate * (DSMath.rpow(_interestRate + DECIMAL, _period, DECIMAL))) /
            DECIMAL;
    }
}