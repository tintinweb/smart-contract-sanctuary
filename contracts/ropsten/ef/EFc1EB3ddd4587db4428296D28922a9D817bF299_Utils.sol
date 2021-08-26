// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iGovernorAlpha.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iROUTER.sol";
import "./interfaces/iLENDER.sol";
import "./interfaces/iPOOLS.sol";
import "./interfaces/iFACTORY.sol";
import "./interfaces/iSYNTH.sol";

contract Utils {
    uint256 private constant one = 10**18;
    uint256 private constant _10k = 10000;
    uint256 private constant _year = 31536000; // One Year (in seconds)

    address public VADER;

    constructor(address _vader) {
        VADER = _vader;
    }

    //====================================SYSTEM FUNCTIONS====================================//
    // VADER FeeOnTransfer
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256) {
        return calcShare(totalSupply, maxSupply, 100); // 0->100BP
    }

    function assetChecks(address collateralAsset, address debtAsset) external {
        if (collateralAsset == VADER) {
            require(iPOOLS(POOLS()).isAnchor(debtAsset), "Bad Combo"); // Can borrow Anchor with VADER/ANCHOR-SYNTH
        } else if (collateralAsset == USDV()) {
            require(iPOOLS(POOLS()).isAsset(debtAsset), "Bad Combo"); // Can borrow Asset with VADER/ASSET-SYNTH
        } else if (iPOOLS(POOLS()).isSynth(collateralAsset) && iPOOLS(POOLS()).isAnchor(iSYNTH(collateralAsset).TOKEN())) {
            require(iPOOLS(POOLS()).isAnchor(debtAsset), "Bad Combo"); // Can borrow Anchor with VADER/ANCHOR-SYNTH
        } else if (iPOOLS(POOLS()).isSynth(collateralAsset) && iPOOLS(POOLS()).isAsset(iSYNTH(collateralAsset).TOKEN())) {
            require(iPOOLS(POOLS()).isAsset(debtAsset), "Bad Combo"); // Can borrow Anchor with VADER/ANCHOR-SYNTH
        }
    }

    function isBase(address token) public view returns (bool base) {
        return token == VADER || token == USDV();
    }

    function isPool(address token) public view returns (bool pool) {
        if (iPOOLS(POOLS()).isAnchor(token) || iPOOLS(POOLS()).isAsset(token)) {
            pool = true;
        }
    }

    //====================================PRICING====================================//

    function calcValueInBase(address token, uint256 amount) public view returns (uint256 value) {
        (uint256 _baseAmt, uint256 _tokenAmt) = iPOOLS(POOLS()).getPoolAmounts(token);
        if (_baseAmt > 0 && _tokenAmt > 0) {
            return (amount * _baseAmt) / _tokenAmt;
        }
    }

    function calcValueInToken(address token, uint256 amount) public view returns (uint256 value) {
        (uint256 _baseAmt, uint256 _tokenAmt) = iPOOLS(POOLS()).getPoolAmounts(token);
        if (_baseAmt > 0 && _tokenAmt > 0) {
            return (amount * _tokenAmt) / _baseAmt;
        }
    }

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) public view returns (uint256 value) {
        return calcValueInToken(token2, calcValueInBase(token1, amount));
    }

    function calcSwapValueInBase(address token, uint256 amount) public view returns (uint256) {
        (uint256 _baseAmt, uint256 _tokenAmt) = iPOOLS(POOLS()).getPoolAmounts(token);
        return calcSwapOutput(amount, _tokenAmt, _baseAmt);
    }

    function calcSwapValueInToken(address token, uint256 amount) public view returns (uint256) {
        (uint256 _baseAmt, uint256 _tokenAmt) = iPOOLS(POOLS()).getPoolAmounts(token);
        return calcSwapOutput(amount, _baseAmt, _tokenAmt);
    }

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view {
        uint256 _testingPrice = calcValueInBase(token, one);
        uint256 _lower = calcPart((_10k - bound), targetPrice); // ie 98% of price
        uint256 _upper = (targetPrice * (_10k + bound)) / _10k; // ie 105% of price
        if (inside) {
            require((_testingPrice >= _lower && _testingPrice <= _upper), "Not inside");
        } else {
            require((_testingPrice <= _lower || _testingPrice >= _upper), "Not outside");
        }
    }

    function getMemberShare(uint256 basisPoints, address token, address member) external view returns(uint256 units, uint256 outputBase, uint256 outputToken) {
        units = calcPart(basisPoints, iPOOLS(POOLS()).getMemberUnits(token, member));
        uint256 _totalUnits = iPOOLS(POOLS()).getUnits(token);
        uint256 _B = iPOOLS(POOLS()).getBaseAmount(token);
        uint256 _T = iPOOLS(POOLS()).getTokenAmount(token);
        address _synth = iFACTORY(FACTORY()).getSynth(token);
        if (_synth != address(0)) {
            uint256 _S = iERC20(_synth).totalSupply();
            _totalUnits = _totalUnits + calcSynthUnits(_S, _B, _T);
        }
        outputBase = calcShare(units, _totalUnits, _B);
        outputToken = calcShare(units, _totalUnits, _T);
    }

    //====================================INCENTIVES========================================//

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare) {
        if (iVADER(VADER).emitting() && iROUTER(ROUTER()).isCurated(token)) {
            uint256 _baseAmount = iPOOLS(POOLS()).getBaseAmount(token);
            if (iPOOLS(POOLS()).isAsset(token)) {
                uint256 _share = calcShare(_baseAmount, iPOOLS(POOLS()).pooledUSDV(), iROUTER(ROUTER()).reserveUSDV());
                rewardShare = getReducedShare(_share, rewardReductionFactor);
            } else if (iPOOLS(POOLS()).isAnchor(token)) {
                uint256 _share = calcShare(_baseAmount, iPOOLS(POOLS()).pooledVADER(), iROUTER(ROUTER()).reserveVADER());
                rewardShare = getReducedShare(_share, rewardReductionFactor);
            }
        }
    }

    function getReducedShare(uint256 amount, uint256 rewardReductionFactor) public pure returns (uint256) {
        return calcShare(1, rewardReductionFactor, amount); // Reduce to stop depleting fast
    }

    //=================================IMPERMANENT LOSS=====================================//

    // Actual protection with 100 day rule and Reserve balance
    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection) {
        uint256 _coverage = getCoverage(member, token);
        if (iROUTER(ROUTER()).isCurated(token)) {
            uint256 _duration = block.timestamp - iROUTER(ROUTER()).getMemberLastDeposit(member, token);
            if (_duration <= timeForFullProtection) {
                protection = calcShare(_duration, timeForFullProtection, _coverage); // Apply 100 day rule
            } else {
                protection = _coverage;
            }
        }
        return calcPart(basisPoints, protection);
    }

    // Theoretical coverage based on deposit/redemption values
    function getCoverage(address member, address token) public view returns (uint256) {
        uint256 _B0 = iROUTER(ROUTER()).getMemberBaseDeposit(member, token);
        uint256 _T0 = iROUTER(ROUTER()).getMemberTokenDeposit(member, token);
        uint256 _units = iPOOLS(POOLS()).getMemberUnits(token, member);
        uint256 _B1 = calcShare(_units, iPOOLS(POOLS()).getUnits(token), iPOOLS(POOLS()).getBaseAmount(token));
        uint256 _T1 = calcShare(_units, iPOOLS(POOLS()).getUnits(token), iPOOLS(POOLS()).getTokenAmount(token));
        return calcCoverage(_B0, _T0, _B1, _T1);
    }

    //==================================== LENDING ====================================//

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256 debt, uint256 baseValue) {
        uint256 _collateralAdjusted = (collateral * 6666) / 10000; // 150% collateral Ratio
        if (isBase(collateralAsset)) {
            baseValue = _collateralAdjusted;
        } else if (isPool(collateralAsset)) {
            baseValue = calcAsymmetricShare(
                _collateralAdjusted,
                iPOOLS(POOLS()).getMemberUnits(collateralAsset, member),
                iPOOLS(POOLS()).getBaseAmount(collateralAsset)
            ); // calc units to BASE
        } else if (iFACTORY(FACTORY()).isSynth(collateralAsset)) {
            baseValue = calcSwapValueInBase(iSYNTH(collateralAsset).TOKEN(), _collateralAdjusted); // Calc swap value
        }
        debt = calcSwapValueInToken(debtAsset, baseValue); // get debt output
        return (debt, baseValue);
    }

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256) {
        uint256 _memberDebt = iLENDER(LENDER()).getMemberDebt(member, collateralAsset, debtAsset); // Outstanding Debt
        uint256 _memberCollateral = iLENDER(LENDER()).getMemberCollateral(member, collateralAsset, debtAsset); // Collateral
        uint256 _collateral = iLENDER(LENDER()).getSystemCollateral(collateralAsset, debtAsset);
        uint256 _interestPaid = iLENDER(LENDER()).getSystemInterestPaid(collateralAsset, debtAsset);
        uint256 _memberInterestShare = calcShare(_memberCollateral, _collateral, _interestPaid); // Share of interest based on collateral
        uint256 _collateralUnlocked = calcShare(debt, _memberDebt, _memberCollateral);
        return (_collateralUnlocked, _memberInterestShare);
    }

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external view returns (uint256 interestOwed) {
        uint256 _interestPayment = calcShare(timeElapsed, _year, getInterestPayment(collateralAsset, debtAsset)); // Share of the payment over 1 year
        if (isBase(collateralAsset)) {
            interestOwed = calcValueInBase(debtAsset, _interestPayment); // Back to base
        } else if (iFACTORY(FACTORY()).isSynth(collateralAsset)) {
            interestOwed = calcValueOfTokenInToken(debtAsset, _interestPayment, collateralAsset); // Get value of Synth in debtAsset (doubleSwap)
        }
    }

    function getInterestPayment(address collateralAsset, address debtAsset) public view returns (uint256) {
        uint256 _debtLoading = getDebtLoading(collateralAsset, debtAsset);
        return (_debtLoading * iLENDER(LENDER()).getSystemDebt(collateralAsset, debtAsset)) / 10000;
    }

    function getDebtLoading(address collateralAsset, address debtAsset) public view returns (uint256) {
        uint256 _debtIssued = iLENDER(LENDER()).getSystemDebt(collateralAsset, debtAsset);
        uint256 _debtDepth = iPOOLS(POOLS()).getTokenAmount(debtAsset);
        return (_debtIssued * 10000) / _debtDepth;
    }

    //====================================CORE-MATH====================================//

    function calcPart(uint256 bp, uint256 total) public pure returns (uint256) {
        // 10,000 basis points = 100.00%
        require(bp <= 10000, "Must be correct BP");
        return calcShare(bp, 10000, total);
    }

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) public pure returns (uint256 share) {
        // share = amount * part/total
        if (part > total) {
            part = total;
        }
        if (total > 0) {
            share = (amount * part) / total;
        }
    }

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) public pure returns (uint256) {
        // y = (x * X * Y )/(x + X)^2
        uint256 numerator = (x * X * Y);
        uint256 denominator = (x + X) * (x + X);
        return (numerator / denominator);
    }

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256) {
        // fee = (x * x * Y) / (x + X)^2
        uint256 numerator = (x * x * Y);
        uint256 denominator = (x + X) * (x + X);
        return (numerator / denominator);
    }

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256) {
        // slip = (x) / (x + X)
        return (x * 10000) / (x + X);
    }

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external pure returns (uint256) {
        if (P == 0) {
            return b;
        } else {
            // units = ((P (t B + T b))/(2 T B)) * slipAdjustment
            // P * (part1 + part2) / (part3) * slipAdjustment
            uint256 slipAdjustment = getSlipAdjustment(b, B, t, T);
            uint256 part1 = t * B;
            uint256 part2 = T * b;
            uint256 part3 = 2 * T * B;
            uint256 _units = P * (part1 + part2) / part3;
            return (_units * slipAdjustment) / one; // Divide by 10**18
        }
    }

    function getSlipAdjustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) public pure returns (uint256) {
        // slipAdjustment = (1 - ABS((B t - b T)/((2 b + B) (t + T))))
        // 1 - ABS(part1 - part2)/(part3 * part4))
        uint256 part1 = B * t;
        uint256 part2 = b * T;
        uint256 part3 = (2 * b) + B;
        uint256 part4 = t + T;
        uint256 numerator;
        if (part1 > part2) {
            numerator = (part1 - part2);
        } else {
            numerator = (part2 - part1);
        }
        uint256 denominator = (part3 * part4);
        return one - (numerator * one) / denominator; // Multiply by 10**18
    }

    function calcSynthUnits(
        uint256 S,
        uint256 B,
        uint256 T
    ) public pure returns (uint256) {
        // (S * B)/(2 * T)
        return (S * B) / (2 * T);
    }

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) public pure returns (uint256) {
        // share = (u * U * (2 * A^2 - 2 * U * u + U^2))/U^3
        // (part1 * (part2 - part3 + part4)) / part5
        uint256 part1 = u * U;
        uint256 part2 = 2 * A * A;
        uint256 part3 = 2 * U * u;
        uint256 part4 = U * U;
        uint256 numerator = part1 * (part2 - part3 + part4);
        uint256 part5 = U * U * U;
        return numerator / part5;
    }

    // From the VADER whitepaper:
    //   coverage = (B0 - B1) + (T0 - T1) * B1/T1
    //     where
    //       B0: USDVDeposited; T0: assetDeposited;
    //       B1: USDVToRedeem;  T1: assetToRedeem;
    // This is the same as
    //   coverage = B0 + T0*B1/T1 - 2*B1
    //     where
    //       B0 + T0*B1/T1 is the deposit value
    //       2*B1          is the redemption value
    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) public pure returns (uint256) {
        if (T1 == 0) {
            return 0;
        }
        uint256 _depositValue = B0 + T0*B1/T1;
        uint256 _redemptionValue = 2*B1;
        if (_depositValue <= _redemptionValue) {
            return 0;
        }
        return _depositValue - _redemptionValue;
    }

    // Sorts array in memory from low to high, returns in-memory (Does not need to modify storage)
    function sortArray(uint256[] memory array) external pure returns (uint256[] memory) {
        uint256 l = array.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (array[i] > array[j]) {
                    uint256 temp = array[i];
                    array[i] = array[j];
                    array[j] = temp;
                }
            }
        }
        return array;
    }

    //============================== HELPERS ================================//

    function updateVADER(address newAddress) external {
        require(msg.sender == GovernorAlpha(), "!VADER");
        VADER = newAddress;
    }

    function GovernorAlpha() internal view returns (address) {
        return iVADER(VADER).GovernorAlpha();
    }

    function USDV() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).USDV();
    }

    function ROUTER() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).ROUTER();
    }

    function LENDER() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).LENDER();
    }

    function POOLS() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).POOLS();
    }

    function FACTORY() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).FACTORY();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iGovernorAlpha {
    function updateVADER(address newAddress) external;
    function VETHER() external view returns(address);
    function VADER() external view returns(address);
    function USDV() external view returns(address);
    function RESERVE() external view returns(address);
    function VAULT() external view returns(address);
    function ROUTER() external view returns(address);
    function LENDER() external view returns(address);
    function POOLS() external view returns(address);
    function FACTORY() external view returns(address);
    function UTILS() external view returns(address);
    function TIMELOCK() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {

    function GovernorAlpha() external view returns (address);

    function Admin() external view returns (address);

    function UTILS() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function era() external view returns(uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newSeconds, uint256 newCurve, uint256 newTailEmissionEra) external;

    function setReserve(address newReserve) external;

    function changeUTILS(address newUTILS) external;

    function changeGovernorAlpha(address newGovernorAlpha) external;

    function purgeGovernorAlpha() external;

    function upgrade(uint256 amount) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeemToVADER(uint256 amount) external returns (uint256);

    function redeemToVADERForMember(address member, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external;
    function setAnchorParams(
        uint256 newLimit,
        uint256 newInside,
        uint256 newOutside
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function updateVADER(address newAddress) external;

    function curatePool(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function listAnchor(address token) external;

    function replaceAnchor(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function isBase(address token) external view returns (bool base);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iLENDER {
    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function updateVADER(address newAddress) external;

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iPOOLS {
    function pooledVADER() external view returns (uint256);

    function pooledUSDV() external view returns (uint256);

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken,
        address member
    ) external returns (uint256 liquidityUnits);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints,
        address member
    ) external returns (uint256 units, uint256 outputBase, uint256 outputToken);

    function sync(address token, uint256 inputToken, address pool) external;

    function swap(
        address base,
        address token,
        uint256 inputToken,
        address member,
        bool toBase
    ) external returns (uint256 outputAmount);

    function deploySynth(address token) external;

    function mintSynth(
        address token,
        uint256 inputBase,
        address member
    ) external returns (uint256 outputAmount);

    function burnSynth(
        address token,
        address member
    ) external returns (uint256 outputBase);

    function syncSynth(address token) external;

    function lockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function unlockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function updateVADER(address newAddress) external;

    function isAsset(address token) external view returns (bool);

    function isAnchor(address token) external view returns (bool);

    function getPoolAmounts(address token) external view returns (uint256, uint256);

    function getBaseAmount(address token) external view returns (uint256);

    function getTokenAmount(address token) external view returns (uint256);

    function getUnits(address token) external view returns (uint256);

    function getMemberUnits(address token, address member) external view returns (uint256);

    function getSynth(address token) external returns (address);

    function isSynth(address token) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iFACTORY {
    function deploySynth(address) external returns (address);

    function mintSynth(
        address,
        address,
        uint256
    ) external returns (bool);

    function getSynth(address) external view returns (address);

    function isSynth(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iSYNTH {
    function mint(address account, uint256 amount) external;

    function TOKEN() external view returns (address);
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