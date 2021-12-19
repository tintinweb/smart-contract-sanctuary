// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Margin.sol";
import "./interfaces/IMarginFactory.sol";

//factory of margin, called by pairFactory
contract MarginFactory is IMarginFactory {
    address public immutable override upperFactory; // PairFactory
    address public immutable override config;

    // baseToken => quoteToken => margin
    mapping(address => mapping(address => address)) public override getMargin;

    modifier onlyUpper() {
        require(msg.sender == upperFactory, "AmmFactory: FORBIDDEN");
        _;
    }

    constructor(address upperFactory_, address config_) {
        require(upperFactory_ != address(0), "MarginFactory: ZERO_UPPER");
        require(config_ != address(0), "MarginFactory: ZERO_CONFIG");
        upperFactory = upperFactory_;
        config = config_;
    }

    function createMargin(address baseToken, address quoteToken) external override onlyUpper returns (address margin) {
        require(baseToken != quoteToken, "MarginFactory.createMargin: IDENTICAL_ADDRESSES");
        require(baseToken != address(0) && quoteToken != address(0), "MarginFactory.createMargin: ZERO_ADDRESS");
        require(getMargin[baseToken][quoteToken] == address(0), "MarginFactory.createMargin: MARGIN_EXIST");
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        bytes memory marginBytecode = type(Margin).creationCode;
        assembly {
            margin := create2(0, add(marginBytecode, 32), mload(marginBytecode), salt)
        }
        getMargin[baseToken][quoteToken] = margin;
        emit MarginCreated(baseToken, quoteToken, margin);
    }

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external override onlyUpper {
        require(amm != address(0), "MarginFactory.initMargin: ZERO_AMM");
        address margin = getMargin[baseToken][quoteToken];
        require(margin != address(0), "MarginFactory.initMargin: ZERO_MARGIN");
        IMargin(margin).initialize(baseToken, quoteToken, amm);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IMarginFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPriceOracle.sol";
import "../utils/Reentrant.sol";
import "../libraries/SignedMath.sol";

//@notice take price=1 in the following example
//@notice cpf means cumulative premium fraction
contract Margin is IMargin, IVault, Reentrant {
    using SignedMath for int256;

    address public immutable override factory;
    address public override config;
    address public override amm;
    address public override baseToken;
    address public override quoteToken;
    mapping(address => Position) public traderPositionMap; //all users' position
    mapping(address => int256) public traderCPF; //one trader's latest cpf, to calculate funding fee
    mapping(address => uint256) public traderLatestOperation; //to prevent flash loan attack
    uint256 public override reserve;
    uint256 public lastUpdateCPF; //last timestamp update cpf
    int256 public override netPosition; //base token
    uint256 internal totalQuoteLong;
    uint256 internal totalQuoteShort;
    int256 internal latestCPF; //latestCPF with 1e18 multiplied

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external override {
        require(factory == msg.sender, "Margin.initialize: FORBIDDEN");
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        amm = amm_;
        config = IMarginFactory(factory).config();
    }

    //@notice before add margin, ensure contract's baseToken balance larger than depositAmount
    function addMargin(address trader, uint256 depositAmount) external override nonReentrant {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        uint256 _reserve = reserve;
        //test case: 1. no transfer, add nonZero margin; 2. no transfer, add contractRemain margin
        require(depositAmount <= balance - _reserve, "Margin.addMargin: WRONG_DEPOSIT_AMOUNT");
        Position memory traderPosition = traderPositionMap[trader];

        traderPosition.baseSize = traderPosition.baseSize.addU(depositAmount);
        traderPositionMap[trader] = traderPosition;
        reserve = _reserve + depositAmount;

        emit AddMargin(trader, depositAmount, traderPosition);
    }

    //remove baseToken from trader's fundingFee+unrealizedPnl+margin, remain position need to meet the requirement of initMarginRatio
    function removeMargin(address trader, uint256 withdrawAmount) external override nonReentrant {
        require(traderLatestOperation[trader] != block.number, "Margin.removeMargin: ONE_BLOCK_TWICE_OPERATION");
        traderLatestOperation[trader] = block.number;
        //tocheck can remove this require?
        require(withdrawAmount > 0, "Margin.removeMargin: ZERO_WITHDRAW_AMOUNT");
        if (msg.sender != trader) {
            //tocheck if new router is harmful
            require(IConfig(config).routerMap(msg.sender), "Margin.removeMargin: FORBIDDEN");
        }
        int256 _latestCPF = updateCPF();

        //tocheck test carefully if withdraw margin more than withdrawable
        Position memory traderPosition = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (traderPosition.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = traderPosition.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, traderPosition.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, traderPosition.quoteSize.abs()));
        }

        //after last time operating trader's position, new fundingFee to earn.
        int256 fundingFee = (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);
        //if close all position, trader can withdraw how much and earn how much pnl
        (uint256 withdrawableAmount, int256 unrealizedPnl) = _getWithdrawable(
            traderPosition.quoteSize,
            traderPosition.baseSize + fundingFee,
            traderPosition.tradeSize
        );
        require(withdrawAmount <= withdrawableAmount, "Margin.removeMargin: NOT_ENOUGH_WITHDRAWABLE");

        uint256 withdrawAmountFromMargin;
        //withdraw from fundingFee firstly, then unrealizedPnl, finally margin
        int256 uncoverAfterFundingFee = int256(1).mulU(withdrawAmount) - fundingFee;
        if (uncoverAfterFundingFee > 0) {
            //fundingFee cant cover withdrawAmount, use unrealizedPnl and margin.
            //update tradeSize only, no quoteSize, so can sub uncoverAfterFundingFee directly
            if (uncoverAfterFundingFee <= unrealizedPnl) {
                traderPosition.tradeSize -= uncoverAfterFundingFee.abs();
            } else {
                //fundingFee and unrealizedPnl cant cover withdrawAmount, use margin
                withdrawAmountFromMargin = (uncoverAfterFundingFee - unrealizedPnl).abs();
                //update tradeSize to current price to make unrealizedPnl zero
                traderPosition.tradeSize = traderPosition.quoteSize < 0
                    ? (int256(1).mulU(traderPosition.tradeSize) - unrealizedPnl).abs()
                    : (int256(1).mulU(traderPosition.tradeSize) + unrealizedPnl).abs();
            }
        }

        traderPosition.baseSize = traderPosition.baseSize - uncoverAfterFundingFee;
        //tocheck need check marginRatio?
        // require(
        //     _calMarginRatio(traderPosition.quoteSize, traderPosition.baseSize) >= IConfig(config).initMarginRatio(),
        //     "initMarginRatio"
        // );

        traderPositionMap[trader] = traderPosition;
        traderCPF[trader] = _latestCPF;
        _withdraw(trader, trader, withdrawAmount);

        emit RemoveMargin(trader, withdrawAmount, fundingFee, withdrawAmountFromMargin, traderPosition);
    }

    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external override nonReentrant returns (uint256 baseAmount) {
        require(traderLatestOperation[trader] != block.number, "Margin.openPosition: ONE_BLOCK_TWICE_OPERATION");
        traderLatestOperation[trader] = block.number;
        require(side == 0 || side == 1, "Margin.openPosition: INVALID_SIDE");
        require(quoteAmount > 0, "Margin.openPosition: ZERO_QUOTE_AMOUNT");
        if (msg.sender != trader) {
            require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        }
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];
        bool isLong = side == 0;
        bool sameDir = traderPosition.quoteSize == 0 ||
            (traderPosition.quoteSize < 0 == isLong) ||
            (traderPosition.quoteSize > 0 == !isLong);

        baseAmount = _addPositionWithAmm(isLong, quoteAmount);
        require(baseAmount > 0, "Margin.openPosition: TINY_QUOTE_AMOUNT");

        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        if (sameDir) {
            //baseAmount is real base cost
            traderPosition.tradeSize = traderPosition.tradeSize + baseAmount;
        } else {
            //baseAmount is not real base cost, need to sub real base cost
            if (quoteAmount < quoteSizeAbs) {
                //entry price not change
                traderPosition.tradeSize =
                    traderPosition.tradeSize -
                    (quoteAmount * traderPosition.tradeSize) /
                    quoteSizeAbs;
            } else {
                //after close all opposite position, create new position with new entry price
                traderPosition.tradeSize = ((quoteAmount - quoteSizeAbs) * baseAmount) / quoteAmount;
            }
        }

        int256 baseAmountFunding;
        if (traderPosition.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = traderPosition.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, quoteSizeAbs))
                : int256(0).addU(_querySwapBaseWithAmm(false, quoteSizeAbs));
        }

        int256 fundingFee = (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);
        if (isLong) {
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
            totalQuoteLong = totalQuoteLong + quoteAmount;
            netPosition = netPosition.addU(baseAmount);
        } else {
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
            totalQuoteShort = totalQuoteShort + quoteAmount;
            netPosition = netPosition.subU(baseAmount);
        }

        require(
            _calMarginRatio(traderPosition.quoteSize, traderPosition.baseSize) >= IConfig(config).initMarginRatio(),
            "Margin.openPosition: INIT_MARGIN_RATIO"
        );
        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;
        emit OpenPosition(trader, side, baseAmount, quoteAmount, traderPosition);
    }

    function closePosition(address trader, uint256 quoteAmount)
        external
        override
        nonReentrant
        returns (uint256 baseAmount)
    {
        require(traderLatestOperation[trader] != block.number, "Margin.closePosition: ONE_BLOCK_TWICE_OPERATION");
        traderLatestOperation[trader] = block.number;
        if (msg.sender != trader) {
            require(IConfig(config).routerMap(msg.sender), "Margin.closePosition: FORBIDDEN");
        }
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];
        require(quoteAmount != 0, "Margin.closePosition: ZERO_POSITION");
        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        require(quoteAmount <= quoteSizeAbs, "Margin.closePosition: ABOVE_POSITION");

        bool isLong = traderPosition.quoteSize < 0;
        int256 baseAmountFunding = isLong
            ? int256(0).subU(_querySwapBaseWithAmm(true, quoteSizeAbs))
            : int256(0).addU(_querySwapBaseWithAmm(false, quoteSizeAbs));
        int256 fundingFee = (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);

        if (
            _calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize + fundingFee) >=
            IConfig(config).liquidateThreshold()
        ) {
            //unhealthy position, liquidate self
            int256 remainBaseAmount;
            baseAmount = _querySwapBaseWithAmm(isLong, quoteSizeAbs);
            if (isLong) {
                totalQuoteLong = totalQuoteLong - quoteSizeAbs;
                netPosition = netPosition.subU(baseAmount);
                remainBaseAmount = traderPosition.baseSize.subU(baseAmount) + fundingFee;
                if (remainBaseAmount < 0) {
                    IAmm(amm).forceSwap(
                        address(baseToken),
                        address(quoteToken),
                        (traderPosition.baseSize + fundingFee).abs(),
                        quoteSizeAbs
                    );
                    traderPosition.quoteSize = 0;
                    traderPosition.baseSize = 0;
                    traderPosition.tradeSize = 0;
                }
            } else {
                totalQuoteShort = totalQuoteShort - quoteSizeAbs;
                netPosition = netPosition.addU(baseAmount);
                remainBaseAmount = traderPosition.baseSize.addU(baseAmount) + fundingFee;
                if (remainBaseAmount < 0) {
                    IAmm(amm).forceSwap(
                        address(quoteToken),
                        address(baseToken),
                        quoteSizeAbs,
                        (traderPosition.baseSize + fundingFee).abs()
                    );
                    traderPosition.quoteSize = 0;
                    traderPosition.baseSize = 0;
                    traderPosition.tradeSize = 0;
                }
            }
            if (remainBaseAmount >= 0) {
                _minusPositionWithAmm(isLong, quoteSizeAbs);
                traderPosition.quoteSize = 0;
                traderPosition.tradeSize = 0;
                traderPosition.baseSize = remainBaseAmount;
            }
        } else {
            //healthy position, close position safely
            baseAmount = _minusPositionWithAmm(isLong, quoteAmount);

            //when close position, keep quoteSize/tradeSize not change, cant sub baseAmount because baseAmount contains pnl
            traderPosition.tradeSize -= (quoteAmount * traderPosition.tradeSize) / quoteSizeAbs;

            //close example
            //long old: quote -10, base 11; close position: quote 5, base -5; new: quote -5, base 6
            //short old: quote 10, base -9; close position: quote -5, base +5; new: quote 5, base -4
            if (isLong) {
                totalQuoteLong = totalQuoteLong - quoteAmount;
                netPosition = netPosition.subU(baseAmount);
                traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
                traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
            } else {
                totalQuoteShort = totalQuoteShort - quoteAmount;
                netPosition = netPosition.addU(baseAmount);
                traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
                traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
            }
        }

        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;

        emit ClosePosition(trader, quoteAmount, baseAmount, fundingFee, traderPosition);
    }

    function liquidate(address trader)
        external
        override
        nonReentrant
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        )
    {
        require(traderLatestOperation[msg.sender] != block.number, "Margin.liquidate: ONE_BLOCK_TWICE_OPERATION");

        int256 _latestCPF = updateCPF();
        Position memory traderPosition = traderPositionMap[trader];
        int256 quoteSize = traderPosition.quoteSize;
        require(quoteSize != 0, "Margin.liquidate: ZERO_POSITION");

        quoteAmount = quoteSize.abs();
        bool isLong = quoteSize < 0;
        int256 baseAmountFunding = isLong
            ? int256(0).subU(_querySwapBaseWithAmm(true, quoteAmount))
            : int256(0).addU(_querySwapBaseWithAmm(false, quoteAmount));

        int256 fundingFee = (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);
        require(
            _calDebtRatio(quoteSize, traderPosition.baseSize + fundingFee) >= IConfig(config).liquidateThreshold(),
            "Margin.liquidate: NOT_LIQUIDATABLE"
        );

        baseAmount = _querySwapBaseWithAmm(isLong, quoteAmount);
        //calc remain base after liquidate
        int256 remainBaseAmountAfterLiquidate = isLong
            ? traderPosition.baseSize.subU(baseAmount) + fundingFee
            : traderPosition.baseSize.addU(baseAmount) + fundingFee;

        if (remainBaseAmountAfterLiquidate > 0) {
            //calc liquidate reward
            bonus = (remainBaseAmountAfterLiquidate.abs() * IConfig(config).liquidateFeeRatio()) / 10000;
        }

        if (isLong) {
            totalQuoteLong = totalQuoteLong - quoteAmount;
            netPosition = netPosition.subU(baseAmount);
            IAmm(amm).forceSwap(
                address(baseToken),
                address(quoteToken),
                (traderPosition.baseSize.subU(bonus) + fundingFee).abs(),
                quoteAmount
            );
        } else {
            totalQuoteShort = totalQuoteShort - quoteAmount;
            netPosition = netPosition.addU(baseAmount);
            IAmm(amm).forceSwap(
                address(quoteToken),
                address(baseToken),
                quoteAmount,
                (traderPosition.baseSize.subU(bonus) + fundingFee).abs()
            );
        }

        traderCPF[trader] = _latestCPF;
        if (bonus > 0) {
            _withdraw(trader, msg.sender, bonus);
        }

        delete traderPositionMap[trader];

        emit Liquidate(msg.sender, trader, quoteAmount, baseAmount, bonus, traderPosition);
    }

    function deposit(address user, uint256 amount) external override nonReentrant {
        require(msg.sender == amm, "Margin.deposit: REQUIRE_AMM");
        require(amount > 0, "Margin.deposit: AMOUNT_IS_ZERO");
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        //tocheck if balance contains protocol profit?
        require(amount <= balance - reserve, "Margin.deposit: INSUFFICIENT_AMOUNT");

        reserve = reserve + amount;

        emit Deposit(user, amount);
    }

    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external override nonReentrant {
        require(msg.sender == amm, "Margin.withdraw: REQUIRE_AMM");

        _withdraw(user, receiver, amount);
    }

    function _withdraw(
        address user,
        address receiver,
        uint256 amount
    ) internal {
        //tocheck can remove this following two require?
        require(amount > 0, "Margin._withdraw: AMOUNT_IS_ZERO");
        require(amount <= reserve, "Margin._withdraw: NOT_ENOUGH_RESERVE");
        reserve = reserve - amount;
        IERC20(baseToken).transfer(receiver, amount);

        emit Withdraw(user, receiver, amount);
    }

    //swap exact quote to base
    function _addPositionWithAmm(bool isLong, uint256 quoteAmount) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            !isLong,
            quoteAmount,
            address(quoteToken),
            address(baseToken)
        );

        uint256[2] memory result = IAmm(amm).swap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[1] : result[0];
    }

    //close position, swap base to get exact quoteAmount, the base has contained pnl
    function _minusPositionWithAmm(bool isLong, uint256 quoteAmount) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount,
            address(quoteToken),
            address(baseToken)
        );

        uint256[2] memory result = IAmm(amm).swap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //update global funding fee
    function updateCPF() public override returns (int256 newLatestCPF) {
        uint256 currentTimeStamp = block.timestamp;
        newLatestCPF = _getNewLatestCPF();

        latestCPF = newLatestCPF;
        lastUpdateCPF = currentTimeStamp;

        emit UpdateCPF(currentTimeStamp, newLatestCPF);
    }

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view override returns (uint256) {
        return _querySwapBaseWithAmm(isLong, quoteAmount);
    }

    function getPosition(address trader)
        external
        view
        override
        returns (
            int256,
            int256,
            uint256
        )
    {
        Position memory position = traderPositionMap[trader];
        return (position.baseSize, position.quoteSize, position.tradeSize);
    }

    function getWithdrawable(address trader) external view override returns (uint256 withdrawable) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        (withdrawable, ) = _getWithdrawable(
            position.quoteSize,
            position.baseSize + (baseAmountFunding * (_getNewLatestCPF() - traderCPF[trader])).divU(1e18),
            position.tradeSize
        );
    }

    function getNewLatestCPF() external view override returns (int256) {
        return _getNewLatestCPF();
    }

    function getMarginRatio(address trader) external view override returns (uint256) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return
            _calMarginRatio(
                position.quoteSize,
                position.baseSize + (baseAmountFunding * (_getNewLatestCPF() - traderCPF[trader])).divU(1e18)
            );
    }

    function canLiquidate(address trader) external view override returns (bool) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return
            _calDebtRatio(
                position.quoteSize,
                position.baseSize + (baseAmountFunding * (_getNewLatestCPF() - traderCPF[trader])).divU(1e18)
            ) >= IConfig(config).liquidateThreshold();
    }

    function calFundingFee(address trader) external view override returns (int256) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return (baseAmountFunding * (_getNewLatestCPF() - traderCPF[trader])).divU(1e18);
    }

    function calDebtRatio(address trader) external view override returns (uint256 debtRatio) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return
            _calDebtRatio(
                position.quoteSize,
                position.baseSize + (baseAmountFunding * (_getNewLatestCPF() - traderCPF[trader])).divU(1e18)
            );
    }

    function calUnrealizedPnl(address trader) external view override returns (int256 unrealizedPnl) {
        Position memory position = traderPositionMap[trader];
        if (position.quoteSize < 0) {
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(position.tradeSize).subU(
                _querySwapBaseWithAmm(true, position.quoteSize.abs())
            );
        } else if (position.quoteSize > 0) {
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(_querySwapBaseWithAmm(false, position.quoteSize.abs())).subU(
                position.tradeSize
            );
        }
    }

    //query swap exact quote to base
    function _querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) internal view returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount,
            address(quoteToken),
            address(baseToken)
        );

        uint256[2] memory result = IAmm(amm).estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //@notice returns newLatestCPF with 1e18 multiplied
    function _getNewLatestCPF() internal view returns (int256 newLatestCPF) {
        //premiumFraction is (markPrice - indexPrice) * 1e18 / 8h / indexPrice
        int256 premiumFraction = IPriceOracle(IConfig(config).priceOracle()).getPremiumFraction(amm);
        uint256 maxCPFBoost = IConfig(config).maxCPFBoost();
        int256 delta;
        //todo change amplifier to configurable
        if (
            totalQuoteLong <= maxCPFBoost * totalQuoteShort &&
            totalQuoteShort <= maxCPFBoost * totalQuoteLong &&
            !(totalQuoteShort == 0 && totalQuoteLong == 0)
        ) {
            delta = premiumFraction >= 0
                ? premiumFraction.mulU(totalQuoteLong).divU(totalQuoteShort)
                : premiumFraction.mulU(totalQuoteShort).divU(totalQuoteLong);
        } else if (totalQuoteLong > maxCPFBoost * totalQuoteShort) {
            delta = premiumFraction >= 0 ? premiumFraction.mulU(maxCPFBoost) : premiumFraction.divU(maxCPFBoost);
        } else if (totalQuoteShort > maxCPFBoost * totalQuoteLong) {
            delta = premiumFraction >= 0 ? premiumFraction.divU(maxCPFBoost) : premiumFraction.mulU(maxCPFBoost);
        } else {
            delta = premiumFraction;
        }

        newLatestCPF = delta.mulU(block.timestamp - lastUpdateCPF) + latestCPF;
    }

    //@notice withdrawable from fundingFee, unrealizedPnl and margin
    function _getWithdrawable(
        int256 quoteSize,
        int256 baseSize,
        uint256 tradeSize
    ) internal view returns (uint256 amount, int256 unrealizedPnl) {
        if (quoteSize == 0) {
            amount = baseSize <= 0 ? 0 : baseSize.abs();
        } else if (quoteSize < 0) {
            //long example: quoteSize -10, baseSize 11, tradeSize 10
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(baseToken),
                address(quoteToken),
                0,
                quoteSize.abs()
            );

            uint256 a = result[0] * 10000;
            uint256 b = (10000 - IConfig(config).initMarginRatio());
            //calculate how many base needed to maintain current position
            uint256 baseNeeded = a / b;
            //tocheck need to consider this case
            if (a % b != 0) {
                baseNeeded += 1;
            }
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(tradeSize).subU(result[0]);
            amount = baseSize.abs() <= baseNeeded ? 0 : baseSize.abs() - baseNeeded;
        } else {
            //short example: quoteSize 10, baseSize -9, tradeSize 10
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(quoteToken),
                address(baseToken),
                quoteSize.abs(),
                0
            );

            uint256 baseNeeded = (result[1] * (10000 - IConfig(config).initMarginRatio())) / 10000;
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(result[1]).subU(tradeSize);
            int256 remainBase = baseSize.addU(baseNeeded);
            amount = remainBase <= 0 ? 0 : remainBase.abs();
        }
    }

    //debt*10000/asset
    function _calDebtRatio(int256 quoteSize, int256 baseSize) internal view returns (uint256 debtRatio) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            debtRatio = 0;
        } else if (quoteSize < 0 && baseSize <= 0) {
            debtRatio = 10000;
        } else if (quoteSize > 0) {
            uint256 quoteAmount = quoteSize.abs();
            //calculate asset
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                false
            );
            // uint256 baseAmount = (quoteAmount * 1e18) / price;
            //tocheck debtRatio range?
            debtRatio = baseAmount == 0 ? 10000 : (baseSize.abs() * 10000) / baseAmount;
        } else {
            uint256 quoteAmount = quoteSize.abs();
            //calculate debt
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                true
            );

            // uint256 baseAmount = (quoteAmount * 1e18) / price;
            uint256 ratio = (baseAmount * 10000) / baseSize.abs();
            //tocheck debtRatio range?
            debtRatio = 10000 < ratio ? 10000 : ratio;
        }
    }

    //10000-(debt*10000/asset)
    function _calMarginRatio(int256 quoteSize, int256 baseSize) internal view returns (uint256 marginRatio) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            marginRatio = 10000;
        } else if (quoteSize < 0 && baseSize <= 0) {
            marginRatio = 0;
        } else if (quoteSize > 0) {
            //short, calculate asset
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(quoteToken),
                address(baseToken),
                quoteSize.abs(),
                0
            );
            //asset
            uint256 baseAmount = result[1];
            //tocheck marginRatio range?
            marginRatio = (baseSize.abs() >= baseAmount || baseAmount == 0)
                ? 0
                : baseSize.mulU(10000).divU(baseAmount).addU(10000).abs();
        } else {
            //long, calculate debt
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(baseToken),
                address(quoteToken),
                0,
                quoteSize.abs()
            );
            //debt
            uint256 baseAmount = result[0];
            //tocheck marginRatio range?
            marginRatio = baseSize.abs() < baseAmount ? 0 : 10000 - ((baseAmount * 10000) / baseSize.abs());
        }
    }

    function _getSwapParam(
        bool isLong,
        uint256 amount,
        address token,
        address anotherToken
    )
        internal
        pure
        returns (
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 outputAmount
        )
    {
        if (isLong) {
            outputToken = token;
            outputAmount = amount;
            inputToken = anotherToken;
        } else {
            inputToken = token;
            inputAmount = amount;
            outputToken = anotherToken;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarginFactory {
    event MarginCreated(address indexed baseToken, address indexed quoteToken, address margin);

    function createMargin(address baseToken, address quoteToken) external returns (address margin);

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function margin() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);
    event TradingSlippageChanged(uint256 oldTradingSlippage, uint256 newTradingSlippage);
    event RouterRegistered(address indexed router);
    event RouterUnregistered(address indexed router);
    event SetLiquidateFeeRatio(uint256 oldLiquidateFeeRatio, uint256 liquidateFeeRatio);
    event SetLiquidateThreshold(uint256 oldLiquidateThreshold, uint256 liquidateThreshold);
    event SetInitMarginRatio(uint256 oldInitMarginRatio, uint256 initMarginRatio);
    event SetBeta(uint256 oldBeta, uint256 beta);
    event SetFeeParameter(uint256 oldFeeParameter, uint256 feeParameter);
    event SetMaxCPFBoost(uint256 oldMaxCPFBoost, uint256 maxCPFBoost);

    /// @notice get price oracle address.
    function priceOracle() external view returns (address);

    /// @notice get beta of amm.
    function beta() external view returns (uint8);

    /// @notice get feeParameter of amm.
    function feeParameter() external view returns (uint256);

    /// @notice get init margin ratio of margin.
    function initMarginRatio() external view returns (uint256);

    /// @notice get liquidate threshold of margin.
    function liquidateThreshold() external view returns (uint256);

    /// @notice get liquidate fee ratio of margin.
    function liquidateFeeRatio() external view returns (uint256);

    /// @notice get trading slippage  of amm.
    function tradingSlippage() external view returns (uint256);

    /// @notice get rebase gap of amm.
    function rebasePriceGap() external view returns (uint256);

    function routerMap(address) external view returns (bool);

    function maxCPFBoost() external view returns (uint256);

    function registerRouter(address router) external;

    function unregisterRouter(address router) external;

    /// @notice Set a new oracle
    /// @param newOracle new oracle address.
    function setPriceOracle(address newOracle) external;

    /// @notice Set a new beta of amm
    /// @param newBeta new beta.
    function setBeta(uint8 newBeta) external;

    /// @notice Set a new rebase gap of amm
    /// @param newGap new gap.
    function setRebasePriceGap(uint256 newGap) external;

    /// @notice Set a new trading slippage of amm
    /// @param newTradingSlippage .
    function setTradingSlippage(uint256 newTradingSlippage) external;

    /// @notice Set a new init margin ratio of margin
    /// @param marginRatio new init margin ratio.
    function setInitMarginRatio(uint256 marginRatio) external;

    /// @notice Set a new liquidate threshold of margin
    /// @param threshold new liquidate threshold of margin.
    function setLiquidateThreshold(uint256 threshold) external;

    /// @notice Set a new liquidate fee of margin
    /// @param feeRatio new liquidate fee of margin.
    function setLiquidateFeeRatio(uint256 feeRatio) external;

    /// @notice Set a new feeParameter.
    /// @param newFeeParameter New feeParameter get from AMM swap fee.
    /// @dev feeParameter = (1/fee -1 ) *100 where fee set by owner.
    function setFeeParameter(uint256 newFeeParameter) external;

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(address indexed trader, uint256 depositAmount, Position position);
    event RemoveMargin(
        address indexed trader,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(address indexed trader, uint8 side, uint256 baseAmount, uint256 quoteAmount, Position position);
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        Position position
    );
    event UpdateCPF(uint256 timeStamp, int256 cpf);

    /// @notice only factory can call this function
    /// @param baseToken_ margin's baseToken.
    /// @param quoteToken_ margin's quoteToken.
    /// @param amm_ amm address.
    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external;

    /// @notice add margin to trader
    /// @param trader .
    /// @param depositAmount base amount to add.
    function addMargin(address trader, uint256 depositAmount) external;

    /// @notice remove margin to msg.sender
    /// @param withdrawAmount base amount to withdraw.
    function removeMargin(address trader, uint256 withdrawAmount) external;

    /// @notice open position with side and quoteAmount by msg.sender
    /// @param side long or short.
    /// @param quoteAmount quote amount.
    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /// @notice close msg.sender's position with quoteAmount
    /// @param quoteAmount quote amount to close.
    function closePosition(address trader, uint256 quoteAmount) external returns (uint256 baseAmount);

    /// @notice liquidate trader
    function liquidate(address trader)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );

    function updateCPF() external returns (int256);

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get amm address of this margin
    function amm() external view returns (address);

    /// @notice get all users' net position of base
    function netPosition() external view returns (int256 netBasePosition);

    /// @notice get trader's position
    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    /// @notice get withdrawable margin of trader
    function getWithdrawable(address trader) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(address trader) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(address trader) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function getMarginRatio(address trader) external view returns (uint256);

    function getNewLatestCPF() external view returns (int256);

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, address indexed receiver, uint256 amount);

    /// @notice deposit baseToken to user
    function deposit(address user, uint256 amount) external;

    /// @notice withdraw user's baseToken from margin contract to receiver
    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external;

    /// @notice get baseToken amount in margin
    function reserve() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceOracle {
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getIndexPrice(address amm) external view returns (uint256);

    function getMarkPrice(address amm) external view returns (uint256 price);

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view returns (uint256 baseAmount);

    function getPremiumFraction(address amm) external view returns (int256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

//tocheck delete library, put into code directly
library SignedMath {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(0 - x);
        }
        return uint256(x);
    }

    function addU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x + int256(y);
    }

    function subU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x - int256(y);
    }

    function mulU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x * int256(y);
    }

    function divU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x / int256(y);
    }
}