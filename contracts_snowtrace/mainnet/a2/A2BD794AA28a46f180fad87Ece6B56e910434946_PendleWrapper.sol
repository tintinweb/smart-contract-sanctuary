// solhint-disable var-name-mixedcase
// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;
pragma abicoder v2;
import "../libraries/PendleStructs.sol";
import "../libraries/TokenUtilsLib.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPendleMarket.sol";
import "../periphery/WithdrawableV2.sol";
import "../interfaces/IPendleForge.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IPendleYieldToken.sol";
import "../interfaces/IDMMLiquidityRouter.sol";
import "../interfaces/IPendleLiquidityMining.sol";
import "../interfaces/IPendleLiquidityMiningV2.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IJoeBar.sol";
import "../interfaces/IWMEMO.sol";
import "../interfaces/ITimeStaking.sol";
import "./ICEther.sol";
import "../libraries/UniswapV2Lib.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

enum Mode {
    BENQI,
    JOE,
    xJOE,
    WONDERLAND
}

struct Approval {
    address token;
    address to;
}

struct DataTknzSingle {
    address token;
    uint256 amount;
}

struct PairTokenAmount {
    address token;
    uint256 amount;
}

struct DataTknz {
    DataTknzSingle single;
    DataAddLiqJoe double;
    address forge;
    uint256 expiryYT;
}

struct DataYO {
    address OT;
    address YT;
    uint256 amountYO;
}

struct DataAddLiqOT {
    address baseToken;
    uint256 amountTokenDesired;
    uint256 amountTokenMin;
    uint256 deadline;
    address liqMiningAddr;
}

struct DataAddLiqYT {
    address baseToken;
    uint256 amountTokenDesired;
    uint256 amountTokenMin;
    bytes32 marketFactoryId;
    address liqMiningAddr;
}

struct DataAddLiqJoe {
    address tokenA;
    address tokenB;
    uint256 amountADesired;
    uint256 amountBDesired;
    uint256 amountAMin;
    uint256 amountBMin;
    uint256 deadline;
}

struct ConstructorData {
    IPendleRouter pendleRouter;
    IUniswapV2Router02 joeRouter;
    IJoeBar joeBar;
    IWETH weth;
    IWMEMO wMEMO;
    ITimeStaking timeStaking;
    bytes32 codeHashJoe;
}

struct DataSwap {
    uint256 amountInMax;
    uint256 amountOut;
    address[] path;
}

struct DataPull {
    DataSwap[] swaps;
    PairTokenAmount[] pulls;
    uint256 deadline;
}

library SmartArrayUtils {
    function add(address[12] memory arr, address token) internal pure {
        if (token == address(0)) return;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == token || arr[i] == address(0)) {
                arr[i] = token;
                return;
            }
        }
        revert("TOKENS_LIMIT_EXCEEDED");
    }

    function add(address[12] memory arr, DataPull calldata data) internal pure {
        for (uint256 i = 0; i < data.pulls.length; i++) {
            add(arr, data.pulls[i].token);
        }
        for (uint256 i = 0; i < data.swaps.length; i++) {
            DataSwap memory swap = data.swaps[i];
            add(arr, swap.path[0]);
            add(arr, swap.path[swap.path.length - 1]);
        }
    }

    function add(address[12] memory arr, DataYO memory data) internal pure {
        add(arr, data.OT);
        add(arr, data.YT);
    }
}

library SwapHelper {
    using TokenUtils for IERC20;
    using SafeMath for uint256;
    address internal constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier validateSingleSwap(DataSwap memory data) {
        uint256 len = data.path.length;
        require(len >= 2 && data.path[0] != data.path[len - 1], "INVALID_SWAP_PATH");
        require(data.amountInMax != 0, "ZERO_MAX_IN_AMOUNT");
        require(data.amountOut != 0, "ZERO_MAX_IN_AMOUNT");
        _;
    }

    function swapMultiPaths(
        IUniswapV2Router02 router,
        DataSwap[] calldata data,
        uint256 deadline,
        IWETH weth
    ) internal {
        for (uint256 i = 0; i < data.length; i++) {
            swapSinglePath(router, data[i], weth, deadline);
        }
    }

    function swapSinglePath(
        IUniswapV2Router02 router,
        DataSwap calldata data,
        IWETH weth,
        uint256 deadline
    ) internal validateSingleSwap(data) {
        address[] memory path = data.path;
        if (!_isETH(data.path[0])) {
            IERC20(data.path[0]).infinityApprove(address(router));
        }
        if (_isETH(data.path[0])) {
            path[0] = address(weth);
            router.swapAVAXForExactTokens{value: data.amountInMax}(
                data.amountOut,
                path,
                address(this),
                deadline
            );
        } else if (_isETH(data.path[data.path.length - 1])) {
            path[path.length - 1] = address(weth);
            router.swapTokensForExactAVAX(
                data.amountOut,
                data.amountInMax,
                path,
                address(this),
                deadline
            );
        } else {
            // no ETH
            router.swapTokensForExactTokens(
                data.amountOut,
                data.amountInMax,
                path,
                address(this),
                deadline
            );
        }
    }

    function _isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }
}

contract PendleWrapper is ReentrancyGuard {
    using TokenUtils for IERC20;
    using SmartArrayUtils for address[12];
    using SwapHelper for IUniswapV2Router02;

    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    bytes32 public immutable codeHashJoe;

    IUniswapV2Router02 public immutable joeRouter;
    IJoeBar public immutable joeBar;
    IWETH public immutable weth;
    IWMEMO public immutable wMEMO;
    IERC20 public immutable MEMO;
    ITimeStaking public immutable timeStaking;

    IPendleRouter public immutable pendleRouter;
    IPendleData public immutable pendleData;

    event SwapEventYT(
        address user,
        address inToken,
        address outToken,
        uint256 inAmount,
        uint256 outAmount
    );
    event MintYieldTokens(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToTokenize,
        uint256 amountTokenMinted,
        address indexed user
    );
    event AddLiquidityYT(
        address indexed sender,
        bytes32 marketFactoryId,
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 exactOutLp
    );
    event AddLiquidityOT(
        address indexed sender,
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 exactOutLp
    );
    event RawTokenToYTokenSingle(
        address indexed user,
        address rawAsset,
        address yieldBearingToken,
        uint256 amountIn,
        uint256 amountOut
    );
    event RawTokenToYTokenDouble(
        address indexed user,
        address token0,
        address token1,
        address lpToken,
        uint256 amountIn0,
        uint256 amountIn1,
        uint256 lpOut
    );

    constructor(ConstructorData memory _data) {
        pendleRouter = _data.pendleRouter;
        pendleData = _data.pendleRouter.data();
        joeRouter = _data.joeRouter;
        joeBar = _data.joeBar;
        weth = _data.weth;
        wMEMO = _data.wMEMO;
        MEMO = IERC20(_data.wMEMO.MEMO());
        timeStaking = _data.timeStaking;
        codeHashJoe = _data.codeHashJoe;
    }

    receive() external payable {}

    // start of Level 1 functions
    function insAddDualLiqForYT(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz,
        DataAddLiqYT calldata dataAddYT
    )
        external
        payable
        nonReentrant
        returns (
            DataYO memory dataYO,
            uint256 lpOut,
            uint256 amountBaseTokenUsed
        )
    {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, address(this), dataTknz);

        (amountBaseTokenUsed, lpOut) = _addDualLiqYT(arr, dataYO, dataAddYT);

        _pushAll(arr);
    }

    function insAddSingleLiq(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutLp,
        address liqMiningAddr
    ) external payable nonReentrant returns (DataYO memory dataYO, uint256 lpOut) {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, address(this), dataTknz);

        lpOut = _addSingleLiqYT(arr, dataYO, marketFactoryId, baseToken, minOutLp, liqMiningAddr);

        _pushAll(arr);
    }

    function insAddDualLiqForOT(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz,
        DataAddLiqOT calldata dataAddOT
    )
        external
        payable
        nonReentrant
        returns (
            DataYO memory dataYO,
            uint256 lpOutOT,
            uint256 amountBaseTokenUsedOT
        )
    {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, address(this), dataTknz);

        (amountBaseTokenUsedOT, lpOutOT) = _addDualLiqOT(arr, dataYO, dataAddOT);

        _pushAll(arr);
    }

    function insAddDualLiqForOTandYT(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz,
        DataAddLiqOT calldata dataAddOT,
        DataAddLiqYT calldata dataAddYT
    )
        external
        payable
        nonReentrant
        returns (
            DataYO memory dataYO,
            uint256 lpOutOT,
            uint256 amountBaseTokenUsedOT,
            uint256 lpOutYT,
            uint256 amountBaseTokenUsedYT
        )
    {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, address(this), dataTknz);

        (amountBaseTokenUsedOT, lpOutOT) = _addDualLiqOT(arr, dataYO, dataAddOT);

        (amountBaseTokenUsedYT, lpOutYT) = _addDualLiqYT(arr, dataYO, dataAddYT);

        _pushAll(arr);
    }

    function insRealizeFutureYield(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutBaseTokenAmount
    ) external payable nonReentrant returns (DataYO memory dataYO, uint256 amountBaseTokenOut) {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, address(this), dataTknz);

        amountBaseTokenOut = _sellAllYT(
            dataYO,
            arr,
            marketFactoryId,
            baseToken,
            minOutBaseTokenAmount
        );

        _pushAll(arr);
    }

    function insTokenize(
        Mode mode,
        DataPull calldata dataPull,
        DataTknz calldata dataTknz
    ) external payable nonReentrant returns (DataYO memory dataYO) {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);

        dataYO = _insTokenize(mode, arr, msg.sender, dataTknz);

        _pushAll(arr);
    }

    function insSwap(DataPull calldata dataPull) external payable nonReentrant {
        address[12] memory arr;
        _pullAndSwap(arr, dataPull);
        _pushAll(arr);
    }

    // end of Level-1 functions

    function infinityApprove(Approval[] calldata approvals) public {
        for (uint256 i = 0; i < approvals.length; i++)
            IERC20(approvals[i].token).infinityApprove(approvals[i].to);
    }

    // start of Level-2 functions
    function _pullAndSwap(address[12] memory arr, DataPull calldata dataPull) internal {
        _pullToken(dataPull, arr);
        joeRouter.swapMultiPaths(dataPull.swaps, dataPull.deadline, weth);
    }

    function _insTokenize(
        Mode mode,
        address[12] memory arr,
        address to,
        DataTknz calldata data
    ) internal returns (DataYO memory dataYO) {
        uint256 amountToTokenize = _rawTokenToYToken(mode, data);
        bytes32 forgeId = IPendleForge(data.forge).forgeId();
        address underlyingAsset = _getUnderlyingAsset(mode, data);
        if (_isETH(underlyingAsset)) {
            underlyingAsset = address(weth);
        }

        (dataYO.OT, dataYO.YT, dataYO.amountYO) = pendleRouter.tokenizeYield(
            forgeId,
            underlyingAsset,
            data.expiryYT,
            amountToTokenize,
            to
        );

        arr.add(dataYO);

        emit MintYieldTokens(
            forgeId,
            underlyingAsset,
            data.expiryYT,
            amountToTokenize,
            dataYO.amountYO,
            msg.sender
        );
    }

    function _addDualLiqOT(
        address[12] memory,
        DataYO memory dataYO,
        DataAddLiqOT calldata data
    ) internal returns (uint256 lpOut, uint256 amountBaseTokenUsed) {
        bool addToLiqMining = data.liqMiningAddr != address(0);
        address lpReceiver = addToLiqMining ? address(this) : msg.sender;

        (, amountBaseTokenUsed, lpOut) = _addDualLiqJoe(
            lpReceiver,
            DataAddLiqJoe(
                dataYO.OT,
                data.baseToken,
                dataYO.amountYO,
                data.amountTokenDesired,
                dataYO.amountYO,
                data.amountTokenMin,
                data.deadline
            )
        );

        if (addToLiqMining) _addToOTLiqMiningContract(data.liqMiningAddr, lpOut);
        // the LP is either sent directly to the user or add to liqMining

        emit AddLiquidityOT(
            msg.sender,
            dataYO.OT,
            data.baseToken,
            dataYO.amountYO,
            amountBaseTokenUsed,
            lpOut
        );
    }

    function _addDualLiqYT(
        address[12] memory arr,
        DataYO memory dataYO,
        DataAddLiqYT calldata data
    ) internal returns (uint256 amountBaseTokenUsed, uint256 lpOut) {
        bool addToLiqMining = data.liqMiningAddr != address(0);

        (, amountBaseTokenUsed, lpOut) = pendleRouter.addMarketLiquidityDual{
            value: (_isETH(data.baseToken) ? data.amountTokenDesired : 0)
        }(
            data.marketFactoryId,
            dataYO.YT,
            data.baseToken,
            dataYO.amountYO,
            data.amountTokenDesired,
            dataYO.amountYO,
            data.amountTokenMin
        );

        if (addToLiqMining) {
            _addToYTLiqMiningContract(
                data.liqMiningAddr,
                IPendleYieldToken(dataYO.YT).expiry(),
                lpOut
            );
        } else {
            arr.add(_getPendleLp(data.marketFactoryId, data.baseToken, dataYO.YT));
        }

        emit AddLiquidityYT(
            msg.sender,
            data.marketFactoryId,
            dataYO.YT,
            data.baseToken,
            dataYO.amountYO,
            data.amountTokenDesired,
            lpOut
        );
    }

    function _addSingleLiqYT(
        address[12] memory arr,
        DataYO memory dataYO,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutLp,
        address liqMiningAddr
    ) internal returns (uint256 lpOut) {
        // no need to pull anything

        bool addToLiqMining = liqMiningAddr != address(0);

        lpOut = pendleRouter.addMarketLiquiditySingle(
            marketFactoryId,
            dataYO.YT,
            baseToken,
            true,
            dataYO.amountYO,
            minOutLp
        );

        if (addToLiqMining) {
            _addToYTLiqMiningContract(liqMiningAddr, IPendleYieldToken(dataYO.YT).expiry(), lpOut);
        } else {
            arr.add(_getPendleLp(marketFactoryId, baseToken, dataYO.YT));
        }

        emit AddLiquidityYT(
            msg.sender,
            marketFactoryId,
            dataYO.YT,
            baseToken,
            dataYO.amountYO,
            0,
            lpOut
        );
    }

    function _sellAllYT(
        DataYO memory dataYO,
        address[12] memory arr,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutBaseTokenAmount
    ) internal returns (uint256 amountBaseTokenOut) {
        amountBaseTokenOut = pendleRouter.swapExactIn(
            dataYO.YT,
            baseToken,
            dataYO.amountYO,
            minOutBaseTokenAmount,
            marketFactoryId
        );

        arr.add(baseToken);

        emit SwapEventYT(msg.sender, dataYO.YT, baseToken, dataYO.amountYO, amountBaseTokenOut);
    }

    // end of Level-2 functions

    function _rawTokenToYToken(Mode mode, DataTknz calldata data)
        internal
        returns (uint256 amountYTokenReceived)
    {
        if (mode == Mode.BENQI) amountYTokenReceived = _rawTokenToYTokenBenQi(data);
        else if (mode == Mode.xJOE) amountYTokenReceived = _rawTokenToYTokenXJoe(data);
        else if (mode == Mode.WONDERLAND) amountYTokenReceived = _rawTokenToYTokenWonderland(data);
        else (, , amountYTokenReceived) = _rawTokenToYTokenJoe(address(this), data.double);
    }

    function _rawTokenToYTokenBenQi(DataTknz calldata data)
        internal
        returns (uint256 amountYTokenReceived)
    {
        (address token, uint256 amount) = (data.single.token, data.single.amount);
        address cToken;
        if (_isETH(token)) {
            cToken = IPendleForge(data.forge).getYieldBearingToken(address(weth));
            ICEther(cToken).mint{value: amount}();
        } else {
            cToken = IPendleForge(data.forge).getYieldBearingToken(token);
            ICToken(cToken).mint(amount);
        }
        amountYTokenReceived = _selfBalanceOf(cToken);
        emit RawTokenToYTokenSingle(msg.sender, token, cToken, amount, amountYTokenReceived);
    }

    function _rawTokenToYTokenXJoe(DataTknz calldata data)
        internal
        returns (uint256 amountYTokenReceived)
    {
        joeBar.enter(data.single.amount);
        amountYTokenReceived = _selfBalanceOf(address(joeBar));
        emit RawTokenToYTokenSingle(
            msg.sender,
            data.single.token,
            address(joeBar),
            data.single.amount,
            amountYTokenReceived
        );
    }

    function _rawTokenToYTokenWonderland(DataTknz calldata data)
        internal
        returns (uint256 amountYTokenReceived)
    {
        if (data.single.token != address(MEMO)) {
            // if it's not MEMO, for sure it's TIME
            require(timeStaking.warmupPeriod() == 0, "WARMUP_PERIOD_NOT_ZERO");
            timeStaking.stake(data.single.amount, address(this));
            timeStaking.claim(address(this));
        }

        // MEMO is only used in this function, so we can use the entire balance of MEMO
        wMEMO.wrap(_selfBalanceOf(address(MEMO)));

        amountYTokenReceived = _selfBalanceOf(address(wMEMO));
        emit RawTokenToYTokenSingle(
            msg.sender,
            data.single.token,
            address(wMEMO),
            data.single.amount,
            amountYTokenReceived
        );
    }

    function _rawTokenToYTokenJoe(address to, DataAddLiqJoe memory data)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 lpOut
        )
    {
        address pool = _getJoePool(data);
        (amountA, amountB, lpOut) = _addDualLiqJoe(to, data);
        emit RawTokenToYTokenDouble(
            msg.sender,
            data.tokenA,
            data.tokenB,
            pool,
            amountA,
            amountB,
            lpOut
        );
    }

    function _addDualLiqJoe(address to, DataAddLiqJoe memory data)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 lpOut
        )
    {
        bool swapped = false;
        if (_isETH(data.tokenB)) {
            swapped = true;
            _swapTokenABData(data);
        }

        // if one of the two tokens is ETH, it will always be tokenA
        if (_isETH(data.tokenA)) {
            // amountToken, amountETH, liquidity
            (amountB, amountA, lpOut) = joeRouter.addLiquidityAVAX{value: data.amountADesired}(
                data.tokenB,
                data.amountBDesired,
                data.amountBMin,
                data.amountAMin,
                to,
                data.deadline
            );
        } else {
            (amountA, amountB, lpOut) = joeRouter.addLiquidity(
                data.tokenA,
                data.tokenB,
                data.amountADesired,
                data.amountBDesired,
                data.amountAMin,
                data.amountBMin,
                to,
                data.deadline
            );
        }

        if (swapped) {
            (amountA, amountB) = (amountB, amountA);
            _swapTokenABData(data);
        }
    }

    function _addToYTLiqMiningContract(
        address liqAddr,
        uint256 expiry,
        uint256 lpAmount
    ) internal {
        IPendleLiquidityMining(liqAddr).stakeFor(msg.sender, expiry, lpAmount);
    }

    function _addToOTLiqMiningContract(address liqAddr, uint256 lpAmount) internal {
        IPendleLiquidityMiningV2(liqAddr).stake(msg.sender, lpAmount);
    }

    function _pullToken(DataPull calldata data, address[12] memory arr) internal {
        arr.add(data);

        uint256 totalEthAmount = 0;
        for (uint256 i = 0; i < data.pulls.length; i++) {
            PairTokenAmount memory pair = data.pulls[i];
            if (_isETH(pair.token)) {
                totalEthAmount += pair.amount;
            } else {
                IERC20(pair.token).safeTransferFrom(msg.sender, address(this), pair.amount);
            }
        }
        for (uint256 i = 0; i < data.swaps.length; i++) {
            DataSwap memory swap = data.swaps[i];
            if (_isETH(swap.path[0])) {
                totalEthAmount += swap.amountInMax;
            } else {
                IERC20(swap.path[0]).safeTransferFrom(msg.sender, address(this), swap.amountInMax);
            }
        }
        require(totalEthAmount >= _selfBalanceOf(ETH_ADDRESS), "INSUFFICIENT_ETH_AMOUNT");
    }

    function _pushAll(address[12] memory arr) internal {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == address(0)) break;
            if (_isETH(arr[i])) {
                (bool success, ) = msg.sender.call{value: _selfBalanceOf(arr[i])}("");
                require(success, "TRANSFER_FAILED");
            } else {
                IERC20(arr[i]).safeTransfer(msg.sender, _selfBalanceOf(arr[i]));
            }
        }
    }

    function _getPendleLp(
        bytes32 marketFactoryId,
        address baseToken,
        address YT
    ) internal view returns (address) {
        return
            pendleData.getMarket(
                marketFactoryId,
                YT,
                _isETH(baseToken) ? address(weth) : baseToken
            );
    }

    function _selfBalanceOf(address token) internal view returns (uint256) {
        if (_isETH(token)) return address(this).balance;
        return IERC20(token).balanceOf(address(this));
    }

    function _getUnderlyingAsset(Mode mode, DataTknz memory data) internal view returns (address) {
        if (mode == Mode.JOE) {
            return _getJoePool(data.double);
        }
        if (mode == Mode.WONDERLAND) {
            return address(MEMO);
        }
        return data.single.token;
    }

    function _getJoePool(DataAddLiqJoe memory data) internal view returns (address) {
        (address tokenA, address tokenB) = (data.tokenA, data.tokenB);
        return
            UniswapV2Library.pairFor(
                joeRouter.factory(),
                (_isETH(tokenA) ? address(weth) : tokenA),
                (_isETH(tokenB) ? address(weth) : tokenB),
                codeHashJoe
            );
    }

    function _swapTokenABData(DataAddLiqJoe memory data) internal pure {
        (data.tokenA, data.tokenB) = (data.tokenB, data.tokenA);
        (data.amountADesired, data.amountBDesired) = (data.amountBDesired, data.amountADesired);
        (data.amountAMin, data.amountBMin) = (data.amountBMin, data.amountAMin);
    }

    function _isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

struct TokenReserve {
    uint256 weight;
    uint256 balance;
}

struct PendingTransfer {
    uint256 amount;
    bool isOut;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        token.safeTransfer(to, value);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        token.safeTransferFrom(from, to, value);
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        token.approve(spender, 0);
        token.approve(spender, value);
    }

    function infinityApprove(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) <= type(uint256).max) {
            safeApprove(token, spender, type(uint256).max);
        }
    }

    function requireERC20(address tokenAddr) internal view {
        require(IERC20(tokenAddr).totalSupply() > 0, "INVALID_ERC20");
    }

    function requireERC20(IERC20 token) internal view {
        require(token.totalSupply() > 0, "INVALID_ERC20");
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IPendleRouter.sol";
import "./IPendleBaseToken.sol";
import "../libraries/PendleStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleMarket is IERC20 {
    /**
     * @notice Emitted when reserves pool has been updated
     * @param reserve0 The XYT reserves.
     * @param weight0  The XYT weight
     * @param reserve1 The generic token reserves.
     * For the generic Token weight it can be inferred by (2^40) - weight0
     **/
    event Sync(uint256 reserve0, uint256 weight0, uint256 reserve1);
    event RedeemLpInterests(address user, uint256 interests);

    function setUpEmergencyMode(address spender) external;

    function bootstrap(
        address user,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquiditySingle(
        address user,
        address inToken,
        uint256 inAmount,
        uint256 minOutLp
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquidityDual(
        address user,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    ) external returns (PendingTransfer[2] memory transfers, uint256 lpOut);

    function removeMarketLiquidityDual(
        address user,
        uint256 inLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function removeMarketLiquiditySingle(
        address user,
        address outToken,
        uint256 exactInLp,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function swapExactIn(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 minOutAmount
    ) external returns (uint256 outAmount, PendingTransfer[2] memory transfers);

    function swapExactOut(
        address inToken,
        uint256 maxInAmount,
        address outToken,
        uint256 outAmount
    ) external returns (uint256 inAmount, PendingTransfer[2] memory transfers);

    function redeemLpInterests(address user) external returns (uint256 interests);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function factoryId() external view returns (bytes32);

    function token() external view returns (address);

    function xyt() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PermissionsV2.sol";

abstract contract WithdrawableV2 is PermissionsV2 {
    using SafeERC20 for IERC20;

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /**
     * @dev Allows governance to withdraw Ether in a Pendle contract
     *      in case of accidental ETH transfer into the contract.
     * @param amount The amount of Ether to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawEther(uint256 amount, address payable sendTo) external onlyGovernance {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "WITHDRAW_FAILED");
        emit EtherWithdraw(amount, sendTo);
    }

    /**
     * @dev Allows governance to withdraw all IERC20 compatible tokens in a Pendle
     *      contract in case of accidental token transfer into the contract.
     * @param token IERC20 The address of the token contract.
     * @param amount The amount of IERC20 tokens to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external onlyGovernance {
        require(_allowedToWithdraw(address(token)), "TOKEN_NOT_ALLOWED");
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    // must be overridden by the sub contracts, so we must consider explicitly
    // in each and every contract which tokens are allowed to be withdrawn
    function _allowedToWithdraw(address) internal view virtual returns (bool allowed);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleRewardManager.sol";
import "./IPendleYieldContractDeployer.sol";
import "./IPendleData.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleForge {
    /**
     * @dev Emitted when the Forge has minted the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying yield token.
     * @param expiry The expiry of the XYT token
     * @param amountToTokenize The amount of yield bearing assets to tokenize
     * @param amountTokenMinted The amount of OT/XYT minted
     **/
    event MintYieldTokens(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToTokenize,
        uint256 amountTokenMinted,
        address indexed user
    );

    /**
     * @dev Emitted when the Forge has created new yield token contracts.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying asset.
     * @param expiry The date in epoch time when the contract will expire.
     * @param ot The address of the ownership token.
     * @param xyt The address of the new future yield token.
     **/
    event NewYieldContracts(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        address ot,
        address xyt,
        address yieldBearingAsset
    );

    /**
     * @dev Emitted when the Forge has redeemed the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amountToRedeem The amount of OT to be redeemed.
     * @param redeemedAmount The amount of yield token received
     **/
    event RedeemYieldToken(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToRedeem,
        uint256 redeemedAmount,
        address indexed user
    );

    /**
     * @dev Emitted when interest claim is settled
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param user Interest receiver Address
     * @param amount The amount of interest claimed
     **/
    event DueInterestsSettled(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount,
        uint256 forgeFeeAmount,
        address indexed user
    );

    /**
     * @dev Emitted when forge fee is withdrawn
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amount The amount of interest claimed
     **/
    event ForgeFeeWithdrawn(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount
    );

    function setUpEmergencyMode(
        address _underlyingAsset,
        uint256 _expiry,
        address spender
    ) external;

    function newYieldContracts(address underlyingAsset, uint256 expiry)
        external
        returns (address ot, address xyt);

    function redeemAfterExpiry(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 interests);

    function updateDueInterests(
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external;

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function redeemUnderlying(
        address user,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function mintOtAndXyt(
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function withdrawForgeFee(address underlyingAsset, uint256 expiry) external;

    function getYieldBearingToken(address underlyingAsset) external returns (address);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function data() external view returns (IPendleData);

    function rewardManager() external view returns (IPendleRewardManager);

    function yieldContractDeployer() external view returns (IPendleYieldContractDeployer);

    function rewardToken() external view returns (IERC20);

    /**
     * @notice Gets the bytes32 ID of the forge.
     * @return Returns the forge and protocol identifier.
     **/
    function forgeId() external view returns (bytes32);

    function dueInterests(
        address _underlyingAsset,
        uint256 expiry,
        address _user
    ) external view returns (uint256);

    function yieldTokenHolders(address _underlyingAsset, uint256 _expiry)
        external
        view
        returns (address yieldTokenHolder);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
// solhint-disable
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

/// @author Uniswap
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPendleBaseToken.sol";
import "./IPendleForge.sol";

interface IPendleYieldToken is IERC20, IPendleBaseToken {
    /**
     * @notice Emitted when burning OT or XYT tokens.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    event Burn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when minting OT or XYT tokens.
     * @param user The address performing the mint.
     * @param amount The amount to be minted.
     **/
    event Mint(address indexed user, uint256 amount);

    /**
     * @notice Burns OT or XYT tokens from user, reducing the total supply.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    function burn(address user, uint256 amount) external;

    /**
     * @notice Mints new OT or XYT tokens for user, increasing the total supply.
     * @param user The address to send the minted tokens.
     * @param amount The amount to be minted.
     **/
    function mint(address user, uint256 amount) external;

    /**
     * @notice Gets the forge address of the PendleForge contract for this yield token.
     * @return Retuns the forge address.
     **/
    function forge() external view returns (IPendleForge);

    /**
     * @notice Returns the address of the underlying asset.
     * @return Returns the underlying asset address.
     **/
    function underlyingAsset() external view returns (address);

    /**
     * @notice Returns the address of the underlying yield token.
     * @return Returns the underlying yield token address.
     **/
    function underlyingYieldToken() external view returns (address);

    /**
     * @notice let the router approve itself to spend OT/XYT/LP from any wallet
     * @param user user to approve
     **/
    function approveRouter(address user) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev an simple interface for integration dApp to contribute liquidity
interface IDMMLiquidityRouter {
    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param amountADesired the amount of tokenA users want to add to the pool
     * @param amountBDesired the amount of tokenB users want to add to the pool
     * @param amountAMin bounds to the extents to which amountB/amountA can go up
     * @param amountBMin bounds to the extents to which amountB/amountA can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPoolETH(
        IERC20 token,
        uint32 ampBps,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param amountTokenDesired the amount of token users want to add to the pool
     * @dev   msg.value equals to amountEthDesired
     * @param amountTokenMin bounds to the extents to which WETH/token can go up
     * @param amountETHMin bounds to the extents to which WETH/token can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidityETH(
        IERC20 token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax whether users permit the router spending max lp token or not.
     * @param r s v Signature of user to permit the router spending lp token
     */
    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum ethereum in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     */
    function removeLiquidityETH(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum ethereum in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     * @param approveMax whether users permit the router spending max lp token
     * @param r s v signatures of user to permit the router spending lp token.
     */
    function removeLiquidityETHWithPermit(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param amountA amount of 1 side token added to the pool
     * @param reserveA current reserve of the pool
     * @param reserveB current reserve of the pool
     * @return amountB amount of the other token added to the pool
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

interface IPendleLiquidityMining {
    event RedeemLpInterests(uint256 expiry, address user, uint256 interests);
    event Funded(uint256[] _rewards, uint256 numberOfEpochs);
    event RewardsToppedUp(uint256[] _epochIds, uint256[] _rewards);
    event AllocationSettingSet(uint256[] _expiries, uint256[] _allocationNumerators);
    event Staked(uint256 expiry, address user, uint256 amount);
    event Withdrawn(uint256 expiry, address user, uint256 amount);
    event PendleRewardsSettled(uint256 expiry, address user, uint256 amount);

    /**
     * @notice fund new epochs
     */
    function fund(uint256[] calldata rewards) external;

    /**
    @notice top up rewards for any funded future epochs (but not to create new epochs)
    */
    function topUpRewards(uint256[] calldata _epochIds, uint256[] calldata _rewards) external;

    /**
     * @notice Stake an exact amount of LP_expiry
     */
    function stake(uint256 expiry, uint256 amount) external returns (address);

    /**
     * @notice Stake an exact amount of LP_expiry
     */
    function stakeFor(
        address to,
        uint256 expiry,
        uint256 amount
    ) external returns (address);

    /**
     * @notice Stake an exact amount of LP_expiry, using a permit
     */
    function stakeWithPermit(
        uint256 expiry,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address);

    /**
     * @notice Withdraw an exact amount of LP_expiry
     */
    function withdraw(uint256 expiry, uint256 amount) external;

    /**
     * @notice Withdraw an exact amount of LP_expiry
     */
    function withdrawTo(
        address to,
        uint256 expiry,
        uint256 amount
    ) external;

    /**
     * @notice Get the pending rewards for a user
     * @return rewards Returns rewards[0] as the rewards available now, as well as rewards
     that can be claimed for subsequent epochs (size of rewards array is numberOfEpochs)
     */
    function redeemRewards(uint256 expiry, address user) external returns (uint256 rewards);

    /**
     * @notice Get the pending LP interests for a staker
     * @return dueInterests Returns the interest amount
     */
    function redeemLpInterests(uint256 expiry, address user)
        external
        returns (uint256 dueInterests);

    /**
     * @notice Let the liqMiningEmergencyHandler call to approve spender to spend tokens from liqMiningContract
     *          and to spend tokensForLpHolder from the respective lp holders for expiries specified
     */
    function setUpEmergencyMode(uint256[] calldata expiries, address spender) external;

    /**
     * @notice Read the all the expiries that user has staked LP for
     */
    function readUserExpiries(address user) external view returns (uint256[] memory expiries);

    /**
     * @notice Read the amount of LP_expiry staked for a user
     */
    function getBalances(uint256 expiry, address user) external view returns (uint256);

    function lpHolderForExpiry(uint256 expiry) external view returns (address);

    function startTime() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function totalRewardsForEpoch(uint256) external view returns (uint256);

    function numberOfEpochs() external view returns (uint256);

    function vestingEpochs() external view returns (uint256);

    function baseToken() external view returns (address);

    function underlyingAsset() external view returns (address);

    function underlyingYieldToken() external view returns (address);

    function pendleTokenAddress() external view returns (address);

    function marketFactoryId() external view returns (bytes32);

    function forgeId() external view returns (bytes32);

    function forge() external view returns (address);

    function readAllExpiriesLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

interface IPendleLiquidityMiningV2 {
    event Funded(uint256[] rewards, uint256 numberOfEpochs);
    event RewardsToppedUp(uint256[] epochIds, uint256[] rewards);
    event Staked(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
    event PendleRewardsSettled(address user, uint256 amount);

    function fund(uint256[] calldata rewards) external;

    function topUpRewards(uint256[] calldata epochIds, uint256[] calldata rewards) external;

    function stake(address forAddr, uint256 amount) external;

    function withdraw(address toAddr, uint256 amount) external;

    function redeemRewards(address user) external returns (uint256 rewards);

    function redeemDueInterests(address user) external returns (uint256 amountOut);

    function setUpEmergencyMode(address spender, bool) external;

    function updateAndReadEpochData(uint256 epochId, address user)
        external
        returns (
            uint256 totalStakeUnits,
            uint256 totalRewards,
            uint256 lastUpdated,
            uint256 stakeUnitsForUser,
            uint256 availableRewardsForUser
        );

    function balances(address user) external view returns (uint256);

    function startTime() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function readEpochData(uint256 epochId, address user)
        external
        view
        returns (
            uint256 totalStakeUnits,
            uint256 totalRewards,
            uint256 lastUpdated,
            uint256 stakeUnitsForUser,
            uint256 availableRewardsForUser
        );

    function numberOfEpochs() external view returns (uint256);

    function vestingEpochs() external view returns (uint256);

    function stakeToken() external view returns (address);

    function yieldToken() external view returns (address);

    function pendleTokenAddress() external view returns (address);

    function totalStake() external view returns (uint256);

    function dueInterests(address) external view returns (uint256);

    function lastParamL(address) external view returns (uint256);

    function lastNYield() external view returns (uint256);

    function paramL() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Compound ERC20 CToken
 *
 * @dev Implementation of the interest bearing token for the DLP protocol.
 * @author Compound
 */
interface ICToken is IERC20 {
    /*** User Interface ***/

    function balanceOfUnderlying(address owner) external returns (uint256);

    function isCToken() external returns (bool);

    function underlying() external returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256 error,
            uint256 balance,
            uint256 borrowed,
            uint256 exchangeRate
        );

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJoeBar is IERC20 {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWMEMO is IERC20 {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wMEMOToMEMO(uint256 _amount) external view returns (uint256);

    function MEMOTowMEMO(uint256 _amount) external view returns (uint256);

    function MEMO() external view returns (address);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface ITimeStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function warmupPeriod() external returns (uint);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICEther is IERC20 {
    /*** User Interface ***/

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
// solhint-disable
pragma solidity 0.7.6;

/// @author Uniswap
library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 codeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        codeHash
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IWETH.sol";
import "./IPendleData.sol";
import "../libraries/PendleStructs.sol";
import "./IPendleMarketFactory.sol";

interface IPendleRouter {
    /**
     * @notice Emitted when a market for a future yield token and an ERC20 token is created.
     * @param marketFactoryId Forge identifier.
     * @param xyt The address of the tokenized future yield token as the base asset.
     * @param token The address of an ERC20 token as the quote asset.
     * @param market The address of the newly created market.
     **/
    event MarketCreated(
        bytes32 marketFactoryId,
        address indexed xyt,
        address indexed token,
        address indexed market
    );

    /**
     * @notice Emitted when a swap happens on the market.
     * @param trader The address of msg.sender.
     * @param inToken The input token.
     * @param outToken The output token.
     * @param exactIn The exact amount being traded.
     * @param exactOut The exact amount received.
     * @param market The market address.
     **/
    event SwapEvent(
        address indexed trader,
        address inToken,
        address outToken,
        uint256 exactIn,
        uint256 exactOut,
        address market
    );

    /**
     * @dev Emitted when user adds liquidity
     * @param sender The user who added liquidity.
     * @param token0Amount the amount of token0 (xyt) provided by user
     * @param token1Amount the amount of token1 provided by user
     * @param market The market address.
     * @param exactOutLp The exact LP minted
     */
    event Join(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactOutLp
    );

    /**
     * @dev Emitted when user removes liquidity
     * @param sender The user who removed liquidity.
     * @param token0Amount the amount of token0 (xyt) given to user
     * @param token1Amount the amount of token1 given to user
     * @param market The market address.
     * @param exactInLp The exact Lp to remove
     */
    event Exit(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactInLp
    );

    /**
     * @notice Gets a reference to the PendleData contract.
     * @return Returns the data contract reference.
     **/
    function data() external view returns (IPendleData);

    /**
     * @notice Gets a reference of the WETH9 token contract address.
     * @return WETH token reference.
     **/
    function weth() external view returns (IWETH);

    /***********
     *  FORGE  *
     ***********/

    function newYieldContracts(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (address ot, address xyt);

    function redeemAfterExpiry(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external returns (uint256 interests);

    function redeemUnderlying(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function renewYield(
        bytes32 forgeId,
        uint256 oldExpiry,
        address underlyingAsset,
        uint256 newExpiry,
        uint256 renewalRate
    )
        external
        returns (
            uint256 redeemedAmount,
            uint256 amountRenewed,
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function tokenizeYield(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    /***********
     *  MARKET *
     ***********/

    function addMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    )
        external
        payable
        returns (
            uint256 amountXytUsed,
            uint256 amountTokenUsed,
            uint256 lpOut
        );

    function addMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInAsset,
        uint256 minOutLp
    ) external payable returns (uint256 exactOutLp);

    function removeMarketLiquidityDual(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 exactInLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    function removeMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInLp,
        uint256 minOutAsset
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param marketFactoryId Market Factory identifier.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external returns (address market);

    function bootstrapMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external payable;

    function swapExactIn(
        address tokenIn,
        address tokenOut,
        uint256 inTotalAmount,
        uint256 minOutTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 outTotalAmount);

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 outTotalAmount,
        uint256 maxInTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 inTotalAmount);

    function redeemLpInterests(address market, address user) external returns (uint256 interests);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleBaseToken is IERC20 {
    /**
     * @notice Decreases the allowance granted to spender by the caller.
     * @param spender The address to reduce the allowance from.
     * @param subtractedValue The amount allowance to subtract.
     * @return Returns true if allowance has decreased, otherwise false.
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice The yield contract start in epoch time.
     * @return Returns the yield start date.
     **/
    function start() external view returns (uint256);

    /**
     * @notice The yield contract expiry in epoch time.
     * @return Returns the yield expiry date.
     **/
    function expiry() external view returns (uint256);

    /**
     * @notice Increases the allowance granted to spender by the caller.
     * @param spender The address to increase the allowance from.
     * @param addedValue The amount allowance to add.
     * @return Returns true if allowance has increased, otherwise false
     **/
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Returns the number of decimals the token uses.
     * @return Returns the token's decimals.
     **/
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return Returns the token's name.
     **/
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return Returns the token's symbol.
     **/
    function symbol() external view returns (string memory);

    /**
     * @notice approve using the owner's signature
     **/
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

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleYieldToken.sol";
import "./IPendlePausingManager.sol";
import "./IPendleMarket.sol";

interface IPendleData {
    /**
     * @notice Emitted when validity of a forge-factory pair is updated
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    event ForgeFactoryValiditySet(bytes32 _forgeId, bytes32 _marketFactoryId, bool _valid);

    /**
     * @notice Emitted when Pendle and PendleFactory addresses have been updated.
     * @param treasury The address of the new treasury contract.
     **/
    event TreasurySet(address treasury);

    /**
     * @notice Emitted when LockParams is changed
     **/
    event LockParamsSet(uint256 lockNumerator, uint256 lockDenominator);

    /**
     * @notice Emitted when ExpiryDivisor is changed
     **/
    event ExpiryDivisorSet(uint256 expiryDivisor);

    /**
     * @notice Emitted when forge fee is changed
     **/
    event ForgeFeeSet(uint256 forgeFee);

    /**
     * @notice Emitted when interestUpdateRateDeltaForMarket is changed
     * @param interestUpdateRateDeltaForMarket new interestUpdateRateDeltaForMarket setting
     **/
    event InterestUpdateRateDeltaForMarketSet(uint256 interestUpdateRateDeltaForMarket);

    /**
     * @notice Emitted when market fees are changed
     * @param _swapFee new swapFee setting
     * @param _protocolSwapFee new protocolSwapFee setting
     **/
    event MarketFeesSet(uint256 _swapFee, uint256 _protocolSwapFee);

    /**
     * @notice Emitted when the curve shift block delta is changed
     * @param _blockDelta new block delta setting
     **/
    event CurveShiftBlockDeltaSet(uint256 _blockDelta);

    /**
     * @dev Emitted when new forge is added
     * @param marketFactoryId Human Readable Market Factory ID in Bytes
     * @param marketFactoryAddress The Market Factory Address
     */
    event NewMarketFactory(bytes32 indexed marketFactoryId, address indexed marketFactoryAddress);

    /**
     * @notice Set/update validity of a forge-factory pair
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    function setForgeFactoryValidity(
        bytes32 _forgeId,
        bytes32 _marketFactoryId,
        bool _valid
    ) external;

    /**
     * @notice Sets the PendleTreasury contract addresses.
     * @param newTreasury Address of new treasury contract.
     **/
    function setTreasury(address newTreasury) external;

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function pausingManager() external view returns (IPendlePausingManager);

    /**
     * @notice Gets the treasury contract address where fees are being sent to.
     * @return Address of the treasury contract.
     **/
    function treasury() external view returns (address);

    /***********
     *  FORGE  *
     ***********/

    /**
     * @notice Emitted when a forge for a protocol is added.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    event ForgeAdded(bytes32 indexed forgeId, address indexed forgeAddress);

    /**
     * @notice Adds a new forge for a protocol.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    function addForge(bytes32 forgeId, address forgeAddress) external;

    /**
     * @notice Store new OT and XYT details.
     * @param forgeId Forge and protocol identifier.
     * @param ot The address of the new XYT.
     * @param xyt The address of the new XYT.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     **/
    function storeTokens(
        bytes32 forgeId,
        address ot,
        address xyt,
        address underlyingAsset,
        uint256 expiry
    ) external;

    /**
     * @notice Set a new forge fee
     * @param _forgeFee new forge fee
     **/
    function setForgeFee(uint256 _forgeFee) external;

    /**
     * @notice Gets the OT and XYT tokens.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot The OT token references.
     * @return xyt The XYT token references.
     **/
    function getPendleYieldTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot, IPendleYieldToken xyt);

    /**
     * @notice Gets a forge given the identifier.
     * @param forgeId Forge and protocol identifier.
     * @return forgeAddress Returns the forge address.
     **/
    function getForgeAddress(bytes32 forgeId) external view returns (address forgeAddress);

    /**
     * @notice Checks if an XYT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidXYT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    /**
     * @notice Checks if an OT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidOT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    function validForgeFactoryPair(bytes32 _forgeId, bytes32 _marketFactoryId)
        external
        view
        returns (bool);

    /**
     * @notice Gets a reference to a specific OT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot Returns the reference to an OT.
     **/
    function otTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot);

    /**
     * @notice Gets a reference to a specific XYT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingAsset Token address of the underlying asset
     * @param expiry Yield contract expiry in epoch time.
     * @return xyt Returns the reference to an XYT.
     **/
    function xytTokens(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (IPendleYieldToken xyt);

    /***********
     *  MARKET *
     ***********/

    event MarketPairAdded(address indexed market, address indexed xyt, address indexed token);

    function addMarketFactory(bytes32 marketFactoryId, address marketFactoryAddress) external;

    function isMarket(address _addr) external view returns (bool result);

    function isXyt(address _addr) external view returns (bool result);

    function addMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        address market
    ) external;

    function setMarketFees(uint256 _swapFee, uint256 _protocolSwapFee) external;

    function setInterestUpdateRateDeltaForMarket(uint256 _interestUpdateRateDeltaForMarket)
        external;

    function setLockParams(uint256 _lockNumerator, uint256 _lockDenominator) external;

    function setExpiryDivisor(uint256 _expiryDivisor) external;

    function setCurveShiftBlockDelta(uint256 _blockDelta) external;

    /**
     * @notice Displays the number of markets currently existing.
     * @return Returns markets length,
     **/
    function allMarketsLength() external view returns (uint256);

    function forgeFee() external view returns (uint256);

    function interestUpdateRateDeltaForMarket() external view returns (uint256);

    function expiryDivisor() external view returns (uint256);

    function lockNumerator() external view returns (uint256);

    function lockDenominator() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function protocolSwapFee() external view returns (uint256);

    function curveShiftBlockDelta() external view returns (uint256);

    function getMarketByIndex(uint256 index) external view returns (address market);

    /**
     * @notice Gets a market given a future yield token and an ERC20 token.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the market address.
     **/
    function getMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external view returns (address market);

    /**
     * @notice Gets a market factory given the identifier.
     * @param marketFactoryId MarketFactory identifier.
     * @return marketFactoryAddress Returns the factory address.
     **/
    function getMarketFactoryAddress(bytes32 marketFactoryId)
        external
        view
        returns (address marketFactoryAddress);

    function getMarketFromKey(
        address xyt,
        address token,
        bytes32 marketFactoryId
    ) external view returns (address market);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";

interface IPendleMarketFactory {
    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param xyt Token address of the futuonlyCorere yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(address xyt, address token) external returns (address market);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function marketFactoryId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendlePausingManager {
    event AddPausingAdmin(address admin);
    event RemovePausingAdmin(address admin);
    event PendingForgeEmergencyHandler(address _pendingForgeHandler);
    event PendingMarketEmergencyHandler(address _pendingMarketHandler);
    event PendingLiqMiningEmergencyHandler(address _pendingLiqMiningHandler);
    event ForgeEmergencyHandlerSet(address forgeEmergencyHandler);
    event MarketEmergencyHandlerSet(address marketEmergencyHandler);
    event LiqMiningEmergencyHandlerSet(address liqMiningEmergencyHandler);

    event PausingManagerLocked();
    event ForgeHandlerLocked();
    event MarketHandlerLocked();
    event LiqMiningHandlerLocked();

    event SetForgePaused(bytes32 forgeId, bool settingToPaused);
    event SetForgeAssetPaused(bytes32 forgeId, address underlyingAsset, bool settingToPaused);
    event SetForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool settingToPaused
    );

    event SetForgeLocked(bytes32 forgeId);
    event SetForgeAssetLocked(bytes32 forgeId, address underlyingAsset);
    event SetForgeAssetExpiryLocked(bytes32 forgeId, address underlyingAsset, uint256 expiry);

    event SetMarketFactoryPaused(bytes32 marketFactoryId, bool settingToPaused);
    event SetMarketPaused(bytes32 marketFactoryId, address market, bool settingToPaused);

    event SetMarketFactoryLocked(bytes32 marketFactoryId);
    event SetMarketLocked(bytes32 marketFactoryId, address market);

    event SetLiqMiningPaused(address liqMiningContract, bool settingToPaused);
    event SetLiqMiningLocked(address liqMiningContract);

    function forgeEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function marketEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function liqMiningEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function permLocked() external view returns (bool);

    function permForgeHandlerLocked() external view returns (bool);

    function permMarketHandlerLocked() external view returns (bool);

    function permLiqMiningHandlerLocked() external view returns (bool);

    function isPausingAdmin(address) external view returns (bool);

    function setPausingAdmin(address admin, bool isAdmin) external;

    function requestForgeHandlerChange(address _pendingForgeHandler) external;

    function requestMarketHandlerChange(address _pendingMarketHandler) external;

    function requestLiqMiningHandlerChange(address _pendingLiqMiningHandler) external;

    function applyForgeHandlerChange() external;

    function applyMarketHandlerChange() external;

    function applyLiqMiningHandlerChange() external;

    function lockPausingManagerPermanently() external;

    function lockForgeHandlerPermanently() external;

    function lockMarketHandlerPermanently() external;

    function lockLiqMiningHandlerPermanently() external;

    function setForgePaused(bytes32 forgeId, bool paused) external;

    function setForgeAssetPaused(
        bytes32 forgeId,
        address underlyingAsset,
        bool paused
    ) external;

    function setForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool paused
    ) external;

    function setForgeLocked(bytes32 forgeId) external;

    function setForgeAssetLocked(bytes32 forgeId, address underlyingAsset) external;

    function setForgeAssetExpiryLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external;

    function checkYieldContractStatus(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (bool _paused, bool _locked);

    function setMarketFactoryPaused(bytes32 marketFactoryId, bool paused) external;

    function setMarketPaused(
        bytes32 marketFactoryId,
        address market,
        bool paused
    ) external;

    function setMarketFactoryLocked(bytes32 marketFactoryId) external;

    function setMarketLocked(bytes32 marketFactoryId, address market) external;

    function checkMarketStatus(bytes32 marketFactoryId, address market)
        external
        returns (bool _paused, bool _locked);

    function setLiqMiningPaused(address liqMiningContract, bool settingToPaused) external;

    function setLiqMiningLocked(address liqMiningContract) external;

    function checkLiqMiningStatus(address liqMiningContract)
        external
        returns (bool _paused, bool _locked);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleRewardManager {
    event UpdateFrequencySet(address[], uint256[]);
    event SkippingRewardsSet(bool);

    event DueRewardsSettled(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountOut,
        address user
    );

    function redeemRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external returns (uint256 dueRewards);

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function updateParamLManual(address _underlyingAsset, uint256 _expiry) external;

    function setUpdateFrequency(
        address[] calldata underlyingAssets,
        uint256[] calldata frequencies
    ) external;

    function setSkippingRewards(bool skippingRewards) external;

    function forgeId() external returns (bytes32);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleYieldContractDeployer {
    function forgeId() external returns (bytes32);

    function forgeOwnershipToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address ot);

    function forgeFutureYieldToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address xyt);

    function deployYieldTokenHolder(address yieldToken, uint256 expiry)
        external
        returns (address yieldTokenHolder);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/PendleGovernanceManager.sol";
import "../interfaces/IPermissionsV2.sol";

abstract contract PermissionsV2 is IPermissionsV2 {
    PendleGovernanceManager public immutable override governanceManager;
    address internal initializer;

    constructor(address _governanceManager) {
        require(_governanceManager != address(0), "ZERO_ADDRESS");
        initializer = msg.sender;
        governanceManager = PendleGovernanceManager(_governanceManager);
    }

    modifier initialized() {
        require(initializer == address(0), "NOT_INITIALIZED");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == _governance(), "ONLY_GOVERNANCE");
        _;
    }

    function _governance() internal view returns (address) {
        return governanceManager.governance();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract PendleGovernanceManager {
    address public governance;
    address public pendingGovernance;

    event GovernanceClaimed(address newGovernance, address previousGovernance);

    event TransferGovernancePending(address pendingGovernance);

    constructor(address _governance) {
        require(_governance != address(0), "ZERO_ADDRESS");
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the change governance process.
     */
    function claimGovernance() external {
        require(pendingGovernance == msg.sender, "WRONG_GOVERNANCE");
        emit GovernanceClaimed(pendingGovernance, governance);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param _governance The address to transfer ownership to.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "ZERO_ADDRESS");
        pendingGovernance = _governance;

        emit TransferGovernancePending(pendingGovernance);
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../core/PendleGovernanceManager.sol";

interface IPermissionsV2 {
    function governanceManager() external returns (PendleGovernanceManager);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
// solhint-disable
pragma solidity >=0.6.2;

/// @author Uniswap
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}