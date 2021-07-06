// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ICToken.sol";
import "./IYearn.sol";
import "./ILendingPoolV2.sol";
import "./IBasket.sol";
import "./IATokenV2.sol";
import "./ICurveZap.sol";
import "./ICurve.sol";

import "./ABDKMath64x64.sol";

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./console.sol";

contract BMIZapper is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    // Auxillery
    address constant AAVE_LENDING_POOL_V2 = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    // Tokens

    // BMI
    address public BMI;

    // Bare
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address constant USDP = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant ALUSD = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address constant USDN = 0x674C6Ad92Fd080e4004b2312b45f796a192D27a0;

    // Yearn
    address constant yDAI = 0x19D3364A399d251E894aC732651be8B0E4e85001;
    address constant yUSDC = 0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9;
    address constant yUSDT = 0x7Da96a3891Add058AdA2E826306D812C638D87a7;
    address constant yTUSD = 0x37d19d1c4E1fa9DC47bD1eA12f742a0887eDa74a;
    address constant ySUSD = 0xa5cA62D95D24A4a350983D5B8ac4EB8638887396;

    // Yearn CRV
    address constant yCRV = 0x4B5BfD52124784745c1071dcB244C6688d2533d3; // Y Pool
    address constant ycrvSUSD = 0x5a770DbD3Ee6bAF2802D29a901Ef11501C44797A;
    address constant ycrvYBUSD = 0x8ee57c05741aA9DB947A744E713C15d4d19D8822;
    address constant ycrvBUSD = 0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca;
    address constant ycrvUSDP = 0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417;
    address constant ycrvFRAX = 0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139;
    address constant ycrvALUSD = 0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8;
    address constant ycrvLUSD = 0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6;
    address constant ycrvUSDN = 0x3B96d491f067912D18563d56858Ba7d6EC67a6fa;
    address constant ycrvIB = 0x27b7b1ad7288079A66d12350c828D3C00A6F07d7;
    address constant ycrvThree = 0x84E13785B5a27879921D6F685f041421C7F482dA;
    address constant ycrvDUSD = 0x30FCf7c6cDfC46eC237783D94Fc78553E79d4E9C;
    address constant ycrvMUSD = 0x8cc94ccd0f3841a468184aCA3Cc478D2148E1757;
    address constant ycrvUST = 0x1C6a9783F812b3Af3aBbf7de64c3cD7CC7D1af44;

    // Aave
    address constant aDAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address constant aUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address constant aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;
    address constant aTUSD = 0x101cc05f4A51C0319f570d5E146a8C625198e636;
    address constant aSUSD = 0x6C5024Cd4F8A59110119C56f8933403A539555EB;

    // Compound
    address constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address constant cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    address constant cTUSD = 0x12392F67bdf24faE0AF363c24aC620a2f67DAd86;

    // Curve
    address constant crvY = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address constant crvYPool = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address constant crvYZap = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;

    address constant crvSUSD = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address constant crvSUSDPool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address constant crvSUSDZap = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

    address constant crvYBUSD = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address constant crvYBUSDPool = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address constant crvYBUSDZap = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;

    address constant crvThree = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address constant crvThreePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    address constant crvUSDP = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address constant crvUSDPPool = 0x42d7025938bEc20B69cBae5A77421082407f053A;
    address constant crvUSDPZap = 0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940;

    address constant crvDUSD = 0x3a664Ab939FD8482048609f652f9a0B0677337B9;
    address constant crvDUSDPool = 0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c;
    address constant crvDUSDZap = 0x61E10659fe3aa93d036d099405224E4Ac24996d0;

    address constant crvMUSD = 0x1AEf73d49Dedc4b1778d0706583995958Dc862e6;
    address constant crvMUSDPool = 0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6;
    address constant crvMUSDZap = 0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2;

    address constant crvUST = 0x94e131324b6054c0D789b190b2dAC504e4361b53;
    address constant crvUSTPool = 0x890f4e345B1dAED0367A877a1612f86A1f86985f;
    address constant crvUSTZap = 0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d;

    address constant crvUSDN = 0x4f3E8F405CF5aFC05D68142F3783bDfE13811522;
    address constant crvUSDNPool = 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    address constant crvUSDNZap = 0x094d12e5b541784701FD8d65F11fc0598FBC6332;

    address constant crvIB = 0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address constant crvIBPool = 0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF;

    address constant crvBUSD = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address constant crvFRAX = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address constant crvALUSD = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address constant crvLUSD = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;

    address constant crvMetaZapper = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    // **** Constructor ****

    constructor(address _bmi) {
        BMI = _bmi;
    }

    function recoverERC20(address _token) public onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function recoverERC20s(address[] memory _tokens) public onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(msg.sender, IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }

    // **** View only functions **** //

    // Estimates USDC equilavent for yearn crv and crv pools
    function calcUSDCEquilavent(address _from, uint256 _amount) public view returns (uint256) {
        if (_isYearnCRV(_from)) {
            _amount = _amount.mul(IYearn(_from).pricePerShare()).div(1e18);
            _from = IYearn(_from).token();
        }

        if (_from == crvY || _from == crvSUSD || _from == crvThree || _from == crvYBUSD) {
            address zap = crvYZap;

            if (_from == crvSUSD) {
                zap = crvSUSDZap;
            } else if (_from == crvThree) {
                zap = crvThreePool;
            } else if (_from == crvYBUSD) {
                zap = crvYBUSDZap;
            }

            return ICurveZapSimple(zap).calc_withdraw_one_coin(_amount, 1);
        } else if (_from == crvUSDN || _from == crvUSDP || _from == crvDUSD || _from == crvMUSD || _from == crvUST) {
            address zap = crvUSDNZap;

            if (_from == crvUSDP) {
                zap = crvUSDPZap;
            } else if (_from == crvDUSD) {
                zap = crvDUSDZap;
            } else if (_from == crvMUSD) {
                zap = crvMUSDZap;
            } else if (_from == crvUST) {
                zap = crvUSTZap;
            }

            return ICurveZapSimple(zap).calc_withdraw_one_coin(_amount, 2);
        } else if (_from == crvIB) {
            return ICurveZapSimple(crvIBPool).calc_withdraw_one_coin(_amount, 1, true);
        } else {
            // Meta pools, USDC is 2nd index
            return ICurveZapSimple(crvMetaZapper).calc_withdraw_one_coin(_from, _amount, 2);
        }
    }

    function getUnderlyingAmount(address _derivative, uint256 _amount) public view returns (address, uint256) {
        if (_isAave(_derivative)) {
            return (IATokenV2(_derivative).UNDERLYING_ASSET_ADDRESS(), _amount);
        }

        if (_isCompound(_derivative)) {
            uint256 rate = ICToken(_derivative).exchangeRateStored();
            address underlying = ICToken(_derivative).underlying();
            uint256 underlyingDecimals = ERC20(underlying).decimals();
            uint256 mantissa = 18 + underlyingDecimals - 8;
            uint256 oneCTokenInUnderlying = rate.mul(1e18).div(10**mantissa);
            return (underlying, _amount.mul(oneCTokenInUnderlying).div(1e8));
        }

        // YearnCRV just or CRV return USDC
        if (_isCRV(_derivative) || _isYearnCRV(_derivative)) {
            return (USDC, calcUSDCEquilavent(_derivative, _amount));
        }

        if (_isYearn(_derivative)) {
            _amount = _amount.mul(IYearn(_derivative).pricePerShare()).div(1e18);

            if (_derivative == yDAI) {
                return (DAI, _amount);
            }

            if (_derivative == yUSDC) {
                return (USDC, _amount);
            }

            if (_derivative == yUSDT) {
                return (USDT, _amount);
            }

            if (_derivative == yTUSD) {
                return (TUSD, _amount);
            }

            if (_derivative == ySUSD) {
                return (SUSD, _amount);
            }
        }

        return (_derivative, _amount);
    }

    // **** Stateful functions ****

    function zapToBMI(
        address _from,
        uint256 _amount,
        address _fromUnderlying,
        uint256 _fromUnderlyingAmount,
        uint256 _minBMIRecv,
        address[] memory _bmiConstituents,
        uint256[] memory _bmiConstituentsWeightings,
        address _aggregator,
        bytes memory _aggregatorData,
        bool refundDust
    ) public returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _bmiConstituentsWeightings.length; i++) {
            sum = sum.add(_bmiConstituentsWeightings[i]);
        }

        // Sum should be between 0.999 and 1.000
        assert(sum <= 1e18);
        assert(sum >= 999e15);

        // Transfer to contract
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);

        // Primitive
        if (_isBare(_from)) {
            _primitiveToBMI(_from, _amount, _bmiConstituents, _bmiConstituentsWeightings, _aggregator, _aggregatorData);
        }
        // Yearn (primitive)
        else if (_isYearn(_from)) {
            IYearn(_from).withdraw();
            _primitiveToBMI(
                _fromUnderlying,
                _fromUnderlyingAmount,
                _bmiConstituents,
                _bmiConstituentsWeightings,
                _aggregator,
                _aggregatorData
            );
        }
        // Yearn (primitive)
        else if (_isYearnCRV(_from)) {
            IYearn(_from).withdraw();
            address crvToken = IYearn(_from).token();
            _crvToPrimitive(crvToken, IERC20(crvToken).balanceOf(address(this)));
            _primitiveToBMI(
                USDC,
                IERC20(USDC).balanceOf(address(this)),
                _bmiConstituents,
                _bmiConstituentsWeightings,
                address(0),
                ""
            );
        }
        // Compound
        else if (_isCompound(_from)) {
            require(ICToken(_from).redeem(_amount) == 0, "!ctoken-redeem");
            _primitiveToBMI(
                _fromUnderlying,
                _fromUnderlyingAmount,
                _bmiConstituents,
                _bmiConstituentsWeightings,
                _aggregator,
                _aggregatorData
            );
        }
        // Aave
        else if (_isAave(_from)) {
            IERC20(_from).safeApprove(AAVE_LENDING_POOL_V2, 0);
            IERC20(_from).safeApprove(AAVE_LENDING_POOL_V2, _amount);
            ILendingPoolV2(AAVE_LENDING_POOL_V2).withdraw(_fromUnderlying, type(uint256).max, address(this));

            _primitiveToBMI(
                _fromUnderlying,
                _fromUnderlyingAmount,
                _bmiConstituents,
                _bmiConstituentsWeightings,
                _aggregator,
                _aggregatorData
            );
        }
        // Curve
        else {
            _crvToPrimitive(_from, _amount);
            _primitiveToBMI(
                USDC,
                IERC20(USDC).balanceOf(address(this)),
                _bmiConstituents,
                _bmiConstituentsWeightings,
                address(0),
                ""
            );
        }

        // Checks
        uint256 _bmiBal = IERC20(BMI).balanceOf(address(this));
        require(_bmiBal >= _minBMIRecv, "!min-mint");
        IERC20(BMI).safeTransfer(msg.sender, _bmiBal);

        // Convert back dust to USDC and refund remaining USDC to usd
        if (refundDust) {
            for (uint256 i = 0; i < _bmiConstituents.length; i++) {
                _fromBMIConstituentToUSDC(_bmiConstituents[i], IERC20(_bmiConstituents[i]).balanceOf(address(this)));
            }
            IERC20(USDC).safeTransfer(msg.sender, IERC20(USDC).balanceOf(address(this)));
        }

        return _bmiBal;
    }

    // **** Internal helpers ****

    function _crvToPrimitive(address _from, uint256 _amount) internal {
        // Remove via zap to USDC
        if (_from == crvY || _from == crvSUSD || _from == crvYBUSD) {
            address zap = crvYZap;

            if (_from == crvSUSD) {
                zap = crvSUSDZap;
            } else if (_from == crvYBUSD) {
                zap = crvYBUSDZap;
            }

            IERC20(_from).safeApprove(zap, 0);
            IERC20(_from).safeApprove(zap, _amount);
            ICurveZapSimple(zap).remove_liquidity_one_coin(_amount, 1, 0, false);
        } else if (_from == crvUSDP || _from == crvUSDN || _from == crvDUSD || _from == crvMUSD || _from == crvUST) {
            address zap = crvUSDNZap;

            if (_from == crvUSDP) {
                zap = crvUSDPZap;
            } else if (_from == crvDUSD) {
                zap = crvDUSDZap;
            } else if (_from == crvMUSD) {
                zap = crvMUSDZap;
            } else if (_from == crvUST) {
                zap = crvUSTZap;
            }

            IERC20(_from).safeApprove(zap, 0);
            IERC20(_from).safeApprove(zap, _amount);
            ICurveZapSimple(zap).remove_liquidity_one_coin(_amount, 2, 0);
        } else if (_from == crvIB) {
            IERC20(_from).safeApprove(crvIBPool, 0);
            IERC20(_from).safeApprove(crvIBPool, _amount);
            ICurveZapSimple(crvIBPool).remove_liquidity_one_coin(_amount, 1, 0, true);
        } else if (_from == crvThree) {
            address zap = crvThreePool;

            IERC20(_from).safeApprove(zap, 0);
            IERC20(_from).safeApprove(zap, _amount);
            ICurveZapSimple(zap).remove_liquidity_one_coin(_amount, 1, 0);
        } else {
            // Meta pools, USDC is 2nd index
            IERC20(_from).safeApprove(crvMetaZapper, 0);
            IERC20(_from).safeApprove(crvMetaZapper, _amount);
            ICurveZapSimple(crvMetaZapper).remove_liquidity_one_coin(_from, _amount, 2, 0, address(this));
        }
    }

    function _primitiveToBMI(
        address _token,
        uint256 _amount,
        address[] memory _bmiConstituents,
        uint256[] memory _bmiConstituentsWeightings,
        address _aggregator,
        bytes memory _aggregatorData
    ) internal {
        // Offset, DAI = 0, USDC = 1, USDT = 2
        uint256 offset = 0;

        // Primitive to USDC (if not already USDC)
        if (_token != DAI && _token != USDC && _token != USDT) {
            IERC20(_token).safeApprove(_aggregator, 0);
            IERC20(_token).safeApprove(_aggregator, _amount);

            (bool success, ) = _aggregator.call(_aggregatorData);
            require(success, "!swap");

            // Always goes to USDC
            // If we swapping
            _token = USDC;
        }

        if (_token == USDC) {
            offset = 1;
        } else if (_token == USDT) {
            offset = 2;
        }

        // Amount to mint
        uint256 amountToMint;
        uint256 bmiSupply = IERC20(BMI).totalSupply();

        uint256 tokenBal = IERC20(_token).balanceOf(address(this));
        uint256 tokenAmount;
        for (uint256 i = 0; i < _bmiConstituents.length; i++) {
            // Weighting of the token for BMI constituient
            tokenAmount = tokenBal.mul(_bmiConstituentsWeightings[i]).div(1e18);
            _toBMIConstituent(_token, _bmiConstituents[i], tokenAmount, offset);

            // Get amount to Mint
            amountToMint = _approveBMIAndGetMintableAmount(bmiSupply, _bmiConstituents[i], amountToMint);
        }

        // Mint BASK
        IBasket(BMI).mint(amountToMint);
    }

    function _approveBMIAndGetMintableAmount(
        uint256 _bmiTotalSupply,
        address _bmiConstituient,
        uint256 _curMintAmount
    ) internal returns (uint256) {
        uint256 bal = IERC20(_bmiConstituient).balanceOf(address(this));
        uint256 bmiBal = IERC20(_bmiConstituient).balanceOf(BMI);

        IERC20(_bmiConstituient).safeApprove(BMI, 0);
        IERC20(_bmiConstituient).safeApprove(BMI, bal);

        // Calculate how much BMI we can mint at max
        // Formula: min(e for e in bmiSupply * tokenWeHave[e] / tokenInBMI[e])
        if (_curMintAmount == 0) {
            return _bmiTotalSupply.mul(bal).div(bmiBal);
        }

        uint256 temp = _bmiTotalSupply.mul(bal).div(bmiBal);
        if (temp < _curMintAmount) {
            return temp;
        }

        return _curMintAmount;
    }

    function _toBMIConstituent(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        uint256 _curveOffset
    ) internal {
        uint256 bal;
        uint256[4] memory depositAmounts4 = [uint256(0), uint256(0), uint256(0), uint256(0)];

        if (_toToken == ySUSD) {
            IERC20(_fromToken).safeApprove(crvSUSDPool, 0);
            IERC20(_fromToken).safeApprove(crvSUSDPool, _amount);

            ICurvePool(crvSUSDPool).exchange(int128(_curveOffset), 3, _amount, 0);

            bal = IERC20(SUSD).balanceOf(address(this));
            IERC20(SUSD).safeApprove(ySUSD, 0);
            IERC20(SUSD).safeApprove(ySUSD, bal);
        }
        // Gen 1 pools
        else if (
            _toToken == yCRV ||
            _toToken == ycrvSUSD ||
            _toToken == ycrvYBUSD ||
            _toToken == ycrvUSDN ||
            _toToken == ycrvUSDP ||
            _toToken == ycrvDUSD ||
            _toToken == ycrvMUSD ||
            _toToken == ycrvUST
        ) {
            address crvToken = IYearn(_toToken).token();

            address zap = crvYZap;
            if (_toToken == ycrvSUSD) {
                zap = crvSUSDZap;
            } else if (_toToken == ycrvYBUSD) {
                zap = crvYBUSDZap;
            } else if (_toToken == ycrvUSDN) {
                zap = crvUSDNZap;
                _curveOffset += 1;
            } else if (_toToken == ycrvUSDP) {
                zap = crvUSDPZap;
                _curveOffset += 1;
            } else if (_toToken == ycrvDUSD) {
                zap = crvDUSDZap;
                _curveOffset += 1;
            } else if (_toToken == ycrvMUSD) {
                zap = crvMUSDZap;
                _curveOffset += 1;
            } else if (_toToken == ycrvUST) {
                zap = crvUSTZap;
                _curveOffset += 1;
            }

            depositAmounts4[_curveOffset] = _amount;
            IERC20(_fromToken).safeApprove(zap, 0);
            IERC20(_fromToken).safeApprove(zap, _amount);
            ICurveZapSimple(zap).add_liquidity(depositAmounts4, 0);

            bal = IERC20(crvToken).balanceOf(address(this));
            IERC20(crvToken).safeApprove(_toToken, 0);
            IERC20(crvToken).safeApprove(_toToken, bal);
        } else if (_toToken == ycrvThree || _toToken == ycrvIB) {
            address crvToken = IYearn(_toToken).token();

            uint256[3] memory depositAmounts3 = [uint256(0), uint256(0), uint256(0)];
            depositAmounts3[_curveOffset] = _amount;

            address zap = crvThreePool;
            if (_toToken == ycrvIB) {
                zap = crvIBPool;
            }

            IERC20(_fromToken).safeApprove(zap, 0);
            IERC20(_fromToken).safeApprove(zap, _amount);

            if (_toToken == ycrvThree) {
                ICurveZapSimple(zap).add_liquidity(depositAmounts3, 0);
            } else {
                ICurveZapSimple(zap).add_liquidity(depositAmounts3, 0, true);
            }

            bal = IERC20(crvToken).balanceOf(address(this));
            IERC20(crvToken).safeApprove(_toToken, 0);
            IERC20(crvToken).safeApprove(_toToken, bal);
        }
        // Meta pools
        else if (_toToken == ycrvBUSD || _toToken == ycrvFRAX || _toToken == ycrvALUSD || _toToken == ycrvLUSD) {
            // CRV Token = CRV Pool
            address crvToken = IYearn(_toToken).token();

            depositAmounts4[_curveOffset + 1] = _amount;
            IERC20(_fromToken).safeApprove(crvMetaZapper, 0);
            IERC20(_fromToken).safeApprove(crvMetaZapper, _amount);

            ICurveZapSimple(crvMetaZapper).add_liquidity(crvToken, depositAmounts4, 0);

            bal = IERC20(crvToken).balanceOf(address(this));
            IERC20(crvToken).safeApprove(_toToken, 0);
            IERC20(crvToken).safeApprove(_toToken, bal);
        }

        IYearn(_toToken).deposit();
    }

    function _fromBMIConstituentToUSDC(address _fromToken, uint256 _amount) internal {
        if (_isYearnCRV(_fromToken)) {
            _crvToPrimitive(IYearn(_fromToken).token(), IYearn(_fromToken).withdraw(_amount));
        }
    }

    function _isBare(address _token) internal pure returns (bool) {
        return (_token == DAI ||
            _token == USDC ||
            _token == USDT ||
            _token == TUSD ||
            _token == SUSD ||
            _token == BUSD ||
            _token == USDP ||
            _token == FRAX ||
            _token == ALUSD ||
            _token == LUSD ||
            _token == USDN);
    }

    function _isYearn(address _token) internal pure returns (bool) {
        return (_token == yDAI || _token == yUSDC || _token == yUSDT || _token == yTUSD || _token == ySUSD);
    }

    function _isYearnCRV(address _token) internal pure returns (bool) {
        return (_token == yCRV ||
            _token == ycrvSUSD ||
            _token == ycrvYBUSD ||
            _token == ycrvBUSD ||
            _token == ycrvUSDP ||
            _token == ycrvFRAX ||
            _token == ycrvALUSD ||
            _token == ycrvLUSD ||
            _token == ycrvUSDN ||
            _token == ycrvThree ||
            _token == ycrvIB ||
            _token == ycrvMUSD ||
            _token == ycrvUST ||
            _token == ycrvDUSD);
    }

    function _isCRV(address _token) internal pure returns (bool) {
        return (_token == crvY ||
            _token == crvSUSD ||
            _token == crvYBUSD ||
            _token == crvBUSD ||
            _token == crvUSDP ||
            _token == crvFRAX ||
            _token == crvALUSD ||
            _token == crvLUSD ||
            _token == crvThree ||
            _token == crvUSDN ||
            _token == crvDUSD ||
            _token == crvMUSD ||
            _token == crvUST ||
            _token == crvIB);
    }

    function _isCompound(address _token) internal pure returns (bool) {
        return (_token == cDAI || _token == cUSDC || _token == cUSDT || _token == cTUSD);
    }

    function _isAave(address _token) internal pure returns (bool) {
        return (_token == aDAI || _token == aUSDC || _token == aUSDT || _token == aTUSD || _token == aSUSD);
    }
}