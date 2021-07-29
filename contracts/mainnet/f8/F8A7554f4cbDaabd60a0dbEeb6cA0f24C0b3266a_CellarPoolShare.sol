/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

//SPDX-License-Identifier: Apache-2.0
// VolumeFi Software, Inc.

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
}

library Address {
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "approve non-zero to non-zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "ERC20 operation did not succeed"
            );
        }
    }
}

library FixedPoint96 {
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        require(denominator > prod1);

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = -denominator & denominator;

        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }

        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;

        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        result = prod0 * inv;
        return result;
    }
}

library TickMath {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick =
            tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), "T");

        uint256 ratio =
            absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate =
            FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }
}

interface ICellarPoolShare is IERC20 {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct MintResult {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    struct CellarAddParams {
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CellarRemoveParams {
        uint256 tokenAmount;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CellarTickInfo {
        uint184 tokenId;
        int24 tickUpper;
        int24 tickLower;
        uint24 weight;
    }

    struct UintPair {
        uint256 a;
        uint256 b;
    }

    event AddedLiquidity(
        address indexed token0,
        address indexed token1,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event RemovedLiquidity(
        address indexed token0,
        address indexed token1,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    function addLiquidityForUniV3(CellarAddParams calldata cellarParams)
        external;

    function addLiquidityEthForUniV3(CellarAddParams calldata cellarParams)
        external
        payable;

    function removeLiquidityFromUniV3(CellarRemoveParams calldata cellarParams)
        external;

    function removeLiquidityEthFromUniV3(
        CellarRemoveParams calldata cellarParams
    ) external;

    function reinvest() external;

    function setValidator(address _validator, bool value) external;

    function transferOwnership(address newOwner) external;

    function setFee(uint16 newFee) external;

    function owner() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract CellarPoolShare is ICellarPoolShare {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant NONFUNGIBLEPOSITIONMANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    address public constant UNISWAPV3FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public constant SWAPROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint16 public constant FEEDOMINATOR = 10000;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public validator;
    uint256 private _totalSupply;
    address private _owner;
    string private _name;
    string private _symbol;

    address public immutable token0;
    address public immutable token1;
    uint24 public immutable feeLevel;
    CellarTickInfo[] public cellarTickInfo;
    bool private _isEntered;
    uint16 public fee = 1000;

    constructor(
        string memory name_,
        string memory symbol_,
        address _token0,
        address _token1,
        uint24 _feeLevel,
        CellarTickInfo[] memory _cellarTickInfo
    ) {
        _name = name_;
        _symbol = symbol_;
        require(_token0 < _token1, "Tokens are not sorted");
        token0 = _token0;
        token1 = _token1;
        feeLevel = _feeLevel;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            require(_cellarTickInfo[i].weight > 0, "Weight cannot be zero");
            require(_cellarTickInfo[i].tokenId == 0, "tokenId is not empty");
            if (i > 0) {
                require(_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i - 1].tickLower, "Wrong tick tier");
            }
            cellarTickInfo.push(
                CellarTickInfo({
                    tokenId: 0,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    tickLower: _cellarTickInfo[i].tickLower,
                    weight: _cellarTickInfo[i].weight
                })
            );
        }
        _owner = msg.sender;
    }

    modifier onlyValidator() {
        require(validator[msg.sender], "Not validator");
        _;
    }

    modifier nonReentrant() {
        require(!_isEntered, "reentrant call");
        _isEntered = true;
        _;
        _isEntered = false;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "transfer exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function addLiquidityForUniV3(CellarAddParams calldata cellarParams)
        external
        override
    {
        IERC20(token0).safeTransferFrom(
            msg.sender,
            address(this),
            cellarParams.amount0Desired
        );

        IERC20(token1).safeTransferFrom(
            msg.sender,
            address(this),
            cellarParams.amount1Desired
        );

        (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        ) = _addLiquidity(cellarParams);

        if (liquidityBefore == 0) {
            _mint(msg.sender, liquiditySum);
        } else {
            _mint(
                msg.sender,
                FullMath.mulDiv(liquiditySum, _totalSupply, liquidityBefore)
            );
        }
        require(inAmount0 >= cellarParams.amount0Min, "Less than Amount0Min");
        require(inAmount1 >= cellarParams.amount1Min, "Less than Amount1Min");

        if (cellarParams.amount0Desired > inAmount0) {
            IERC20(token0).safeTransfer(
                msg.sender,
                cellarParams.amount0Desired - inAmount0
            );
        }
        if (cellarParams.amount1Desired > inAmount1) {
            IERC20(token1).safeTransfer(
                msg.sender,
                cellarParams.amount1Desired - inAmount1
            );
        }
        emit AddedLiquidity(token0, token1, liquiditySum, inAmount0, inAmount1);
    }

    function addLiquidityEthForUniV3(CellarAddParams calldata cellarParams)
        external
        payable
        override
        nonReentrant
    {
        if (token0 == WETH) {
            if (msg.value > cellarParams.amount0Desired) {
                payable(msg.sender).transfer(
                    msg.value - cellarParams.amount0Desired
                );
            } else {
                require(
                    msg.value == cellarParams.amount0Desired,
                    "Eth not enough"
                );
            }
            IWETH(WETH).deposit{value: cellarParams.amount0Desired}();
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount1Desired
            );
        } else {
            require(token1 == WETH, "Not Eth Pair");
            if (msg.value > cellarParams.amount1Desired) {
                payable(msg.sender).transfer(
                    msg.value - cellarParams.amount1Desired
                );
            } else {
                require(
                    msg.value == cellarParams.amount1Desired,
                    "Eth not enough"
                );
            }
            IWETH(WETH).deposit{value: cellarParams.amount1Desired}();
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount0Desired
            );
        }

        (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        ) = _addLiquidity(cellarParams);

        if (liquidityBefore == 0) {
            _mint(msg.sender, liquiditySum);
        } else {
            _mint(
                msg.sender,
                FullMath.mulDiv(liquiditySum, _totalSupply, liquidityBefore)
            );
        }

        require(inAmount0 >= cellarParams.amount0Min, "Less than Amount0Min");
        require(inAmount1 >= cellarParams.amount1Min, "Less than Amount1Min");

        uint256 retAmount0 = cellarParams.amount0Desired.sub(inAmount0);
        uint256 retAmount1 = cellarParams.amount1Desired.sub(inAmount1);

        if (retAmount0 > 0) {
            if (token0 == WETH) {
                IWETH(WETH).withdraw(retAmount0);
                msg.sender.transfer(retAmount0);
            } else {
                IERC20(token0).safeTransfer(msg.sender, retAmount0);
            }
        }
        if (retAmount1 > 0) {
            if (token1 == WETH) {
                IWETH(WETH).withdraw(retAmount1);
                msg.sender.transfer(retAmount1);
            } else {
                IERC20(token1).safeTransfer(msg.sender, retAmount1);
            }
        }
        emit AddedLiquidity(token0, token1, liquiditySum, inAmount0, inAmount1);
    }

    function removeLiquidityEthFromUniV3(
        CellarRemoveParams calldata cellarParams
    ) external override nonReentrant {
        (uint256 outAmount0, uint256 outAmount1, uint128 liquiditySum) =
            _removeLiquidity(cellarParams);
        _burn(msg.sender, cellarParams.tokenAmount);

        require(outAmount0 >= cellarParams.amount0Min, "Less than Amount0Min");
        require(outAmount1 >= cellarParams.amount1Min, "Less than Amount1Min");

        if (token0 == WETH) {
            IWETH(WETH).withdraw(outAmount0);
            msg.sender.transfer(outAmount0);
            IERC20(token1).safeTransfer(msg.sender, outAmount1);
        } else {
            require(token1 == WETH, "Not Eth Pair");
            IWETH(WETH).withdraw(outAmount1);
            msg.sender.transfer(outAmount1);
            IERC20(token0).safeTransfer(msg.sender, outAmount0);
        }
        emit RemovedLiquidity(
            token0,
            token1,
            liquiditySum,
            outAmount0,
            outAmount1
        );
    }

    function removeLiquidityFromUniV3(CellarRemoveParams calldata cellarParams)
        external
        override
    {
        (uint256 outAmount0, uint256 outAmount1, uint128 liquiditySum) =
            _removeLiquidity(cellarParams);
        _burn(msg.sender, cellarParams.tokenAmount);

        require(outAmount0 >= cellarParams.amount0Min, "Less than Amount0Min");
        require(outAmount1 >= cellarParams.amount1Min, "Less than Amount1Min");

        IERC20(token0).safeTransfer(msg.sender, outAmount0);
        IERC20(token1).safeTransfer(msg.sender, outAmount1);
        emit RemovedLiquidity(
            token0,
            token1,
            liquiditySum,
            outAmount0,
            outAmount1
        );
    }

    function reinvest() external override onlyValidator {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        uint256 weightSum;
        uint256 balance0;
        uint256 balance1;
        for (uint256 index = 0; index < _cellarTickInfo.length; index++) {
            require(_cellarTickInfo[index].tokenId != 0, "NFLP doesnot exist");
            weightSum += _cellarTickInfo[index].weight;
            (uint256 amount0, uint256 amount1) =
                INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: _cellarTickInfo[index].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            balance0 += amount0;
            balance1 += amount1;
        }
        uint256 fee0 = (balance0 * fee) / FEEDOMINATOR;
        uint256 fee1 = (balance1 * fee) / FEEDOMINATOR;
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        if (balance0 > 0 && balance1 > 0) {
            (uint256 inAmount0, uint256 inAmount1, , uint128 liquiditySum) =
                _addLiquidity(
                    CellarAddParams({
                        amount0Desired: balance0,
                        amount1Desired: balance1,
                        amount0Min: 0,
                        amount1Min: 0,
                        recipient: address(this),
                        deadline: type(uint256).max
                    })
                );

            emit AddedLiquidity(
                token0,
                token1,
                liquiditySum,
                inAmount0,
                inAmount1
            );
        }
    }

    function rebalance(CellarTickInfo[] memory _cellarTickInfo) external {

        require(msg.sender == _owner, "Not owner");
        CellarRemoveParams memory removeParams =
            CellarRemoveParams({
                tokenAmount: _totalSupply,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: type(uint256).max
            });
        _removeLiquidity(removeParams);

        CellarTickInfo[] memory _oldCellarTickInfo = cellarTickInfo;
        for (uint256 i = 0; i < _oldCellarTickInfo.length; i++) {
            INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).burn(
                _oldCellarTickInfo[i].tokenId
            );
        }
        delete cellarTickInfo;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            require(_cellarTickInfo[i].tickUpper > _cellarTickInfo[i].tickLower, "Wrong tick tier");
            if (i > 0) {
                require(_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i - 1].tickLower, "Wrong tick tier");
            }
            require(_cellarTickInfo[i].weight > 0, "Weight cannot be zero");
            require(_cellarTickInfo[i].tokenId == 0, "tokenId is not empty");
            cellarTickInfo.push(_cellarTickInfo[i]);
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (balance0 > 0 && balance1 > 0) {
            (uint256 inAmount0, uint256 inAmount1, , ) =
                _addLiquidity(
                    CellarAddParams({
                        amount0Desired: balance0,
                        amount1Desired: balance1,
                        amount0Min: 0,
                        amount1Min: 0,
                        recipient: address(this),
                        deadline: type(uint256).max
                    })
                );
            balance0 -= inAmount0;
            balance1 -= inAmount1;
        }
        else {
            if (balance1 == 0) {
                IERC20(token0).safeApprove(SWAPROUTER, balance0 / 2);
                ISwapRouter(SWAPROUTER).exactInputSingle(
                    ISwapRouter.ExactInputSingleParams({
                        tokenIn: token0,
                        tokenOut: token1,
                        fee: feeLevel,
                        recipient: address(this),
                        deadline: type(uint256).max,
                        amountIn: balance0 / 2,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    })
                );
                IERC20(token0).safeApprove(SWAPROUTER, 0);
            }
            if (balance0 == 0) {
                IERC20(token1).safeApprove(SWAPROUTER, balance1 / 2);
                ISwapRouter(SWAPROUTER).exactInputSingle(
                    ISwapRouter.ExactInputSingleParams({
                        tokenIn: token1,
                        tokenOut: token0,
                        fee: feeLevel,
                        recipient: address(this),
                        deadline: type(uint256).max,
                        amountIn: balance1 / 2,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    })
                );
                IERC20(token1).safeApprove(SWAPROUTER, 0);
            }

            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
            _addLiquidity(
                CellarAddParams({
                    amount0Desired: balance0,
                    amount1Desired: balance1,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: type(uint256).max
                })
            );
        }
    }

    function setValidator(address _validator, bool value) external override {
        require(msg.sender == _owner, "Not owner");
        validator[_validator] = value;
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == _owner, "Not owner");
        _owner = newOwner;
    }

    function setFee(uint16 newFee) external override {
        require(msg.sender == _owner, "Not owner");
        fee = newFee;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from zero address");
        require(recipient != address(0), "transfer to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "burn from zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) internal {
        require(owner_ != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _getWeightInfo(CellarTickInfo[] memory _cellarTickInfo)
        internal
        returns (
            uint256 weightSum0,
            uint256 weightSum1,
            uint128 liquidityBefore,
            uint256[] memory weight0,
            uint256[] memory weight1
        )
    {
        weight0 = new uint256[](_cellarTickInfo.length);
        weight1 = new uint256[](_cellarTickInfo.length);
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        UintPair memory sqrtPrice0;

        uint256 weight00;
        uint256 weight10;

        sqrtPrice0.a = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickLower
        );
        sqrtPrice0.b = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickUpper
        );

        weight00 = _cellarTickInfo[0].weight;

        weight10 = _cellarTickInfo[_cellarTickInfo.length - 1].weight;
        for (uint16 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].tokenId > 0) {
                (, , , , , , , uint128 liquidity, , , , ) =
                    INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
                        .positions(_cellarTickInfo[i].tokenId);
                liquidityBefore += liquidity;
            }

            UintPair memory sqrtCurrentTickPriceX96;
            sqrtCurrentTickPriceX96.a = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickLower
            );
            sqrtCurrentTickPriceX96.b = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickUpper
            );

            if (currentTick <= _cellarTickInfo[i].tickLower) {
                weight0[i] =
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b -
                                sqrtCurrentTickPriceX96.a,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtCurrentTickPriceX96.a
                    ) * _cellarTickInfo[i].weight) /
                    weight00;
                weightSum0 += weight0[i];
            } else if (currentTick >= _cellarTickInfo[i].tickUpper) {
                weight1[i] =
                    (FullMath.mulDiv(
                        sqrtCurrentTickPriceX96.b - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum1 += weight1[i];
            } else {
                weight0[i] =
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b - sqrtPriceX96,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtPriceX96
                    ) * _cellarTickInfo[i].weight) /
                    weight00;

                weight1[i] =
                    (FullMath.mulDiv(
                        sqrtPriceX96 - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum0 += weight0[i];
                weightSum1 += weight1[i];
            }
        }
    }

    function _modifyWeightInfo(
        CellarTickInfo[] memory _cellarTickInfo,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 weightSum0,
        uint256 weightSum1,
        uint256[] memory weight0,
        uint256[] memory weight1
    ) internal view returns (uint256 newWeightSum0, uint256 newWeightSum1) {
        if (_cellarTickInfo.length == 1) {
            return (weightSum0, weightSum1);
        }

        UintPair memory liquidity;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        liquidity.a = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[0], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[0], weightSum1)
        );
        uint256 tickLength = _cellarTickInfo.length - 1;
        liquidity.b = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[tickLength], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[tickLength], weightSum1)
        );

        if (
            liquidity.a * _cellarTickInfo[tickLength].weight >
            liquidity.b * _cellarTickInfo[0].weight
        ) {
            if (liquidity.b * _cellarTickInfo[0].weight > 0) {
                newWeightSum0 = FullMath.mulDiv(
                    weightSum0,
                    liquidity.a * _cellarTickInfo[tickLength].weight,
                    liquidity.b * _cellarTickInfo[0].weight
                );
            }
            else {
                newWeightSum0 = 0;
            }
            newWeightSum1 = weightSum1;
        } else {
            newWeightSum0 = weightSum0;
            if (liquidity.a * _cellarTickInfo[tickLength].weight > 0) {
                newWeightSum1 = FullMath.mulDiv(
                    weightSum1,
                    liquidity.b * _cellarTickInfo[0].weight,
                    liquidity.a * _cellarTickInfo[tickLength].weight
                );
            }
            else {
                newWeightSum1 = 0;
            }
        }
    }

    function _addLiquidity(CellarAddParams memory cellarParams)
        internal
        returns (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        IERC20(token0).safeApprove(
            NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount0Desired
        );
        IERC20(token1).safeApprove(
            NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount1Desired
        );

        uint256 weightSum0;
        uint256 weightSum1;
        uint256[] memory weight0 = new uint256[](_cellarTickInfo.length);
        uint256[] memory weight1 = new uint256[](_cellarTickInfo.length);

        (
            weightSum0,
            weightSum1,
            liquidityBefore,
            weight0,
            weight1
        ) = _getWeightInfo(_cellarTickInfo);

        (weightSum0, weightSum1) = _modifyWeightInfo(
            _cellarTickInfo,
            cellarParams.amount0Desired,
            cellarParams.amount1Desired,
            weightSum0,
            weightSum1,
            weight0,
            weight1
        );

        for (uint16 i = 0; i < _cellarTickInfo.length; i++) {
            INonfungiblePositionManager.MintParams memory mintParams =
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: feeLevel,
                    tickLower: _cellarTickInfo[i].tickLower,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: cellarParams.deadline
                });

                INonfungiblePositionManager.IncreaseLiquidityParams
                    memory increaseLiquidityParams
             =
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            if (weightSum0 > 0) {
                mintParams.amount0Desired = FullMath.mulDiv(
                    cellarParams.amount0Desired,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Desired = mintParams
                    .amount0Desired;
                mintParams.amount0Min = FullMath.mulDiv(
                    cellarParams.amount0Min,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Min = mintParams.amount0Min;
            }
            if (weightSum1 > 0) {
                mintParams.amount1Desired = FullMath.mulDiv(
                    cellarParams.amount1Desired,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Desired = mintParams
                    .amount1Desired;
                mintParams.amount1Min = FullMath.mulDiv(
                    cellarParams.amount1Min,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Min = mintParams.amount1Min;
            }
            if (
                mintParams.amount0Desired > 0 || mintParams.amount1Desired > 0
            ) {
                MintResult memory mintResult;
                if (_cellarTickInfo[i].tokenId == 0) {

                    try INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
                        .mint(mintParams) returns (uint256 r1, uint128 r2, uint256 r3, uint256 r4) {
                        mintResult.tokenId = r1;
                        mintResult.liquidity = r2;
                        mintResult.amount0 = r3;
                        mintResult.amount1 = r4;
                    } catch {}

                    cellarTickInfo[i].tokenId = uint184(mintResult.tokenId);

                    inAmount0 += mintResult.amount0;
                    inAmount1 += mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                } else {
                    try INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
                        .increaseLiquidity(increaseLiquidityParams) returns (uint128 r1, uint256 r2, uint256 r3) {
                        mintResult.liquidity = r1;
                        mintResult.amount0 = r2;
                        mintResult.amount1 = r3;
                    } catch {}
                    inAmount0 += mintResult.amount0;
                    inAmount1 += mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                }
            }
        }
        IERC20(token0).safeApprove(NONFUNGIBLEPOSITIONMANAGER, 0);
        IERC20(token1).safeApprove(NONFUNGIBLEPOSITIONMANAGER, 0);
    }

    function _removeLiquidity(CellarRemoveParams memory cellarParams)
        internal
        returns (
            uint256 outAmount0,
            uint256 outAmount1,
            uint128 liquiditySum
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        uint256 fee0;
        uint256 fee1;
        for (uint16 i = 0; i < _cellarTickInfo.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) =
                INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
                    .positions(_cellarTickInfo[i].tokenId);
            uint128 outLiquidity =
                uint128(
                    FullMath.mulDiv(
                        liquidity,
                        cellarParams.tokenAmount,
                        _totalSupply
                    )
                );

                INonfungiblePositionManager.DecreaseLiquidityParams
                    memory decreaseLiquidityParams
             =
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    liquidity: outLiquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            (uint256 amount0, uint256 amount1) =
                INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
                    .decreaseLiquidity(decreaseLiquidityParams);
            (uint256 collectAmount0, uint256 collectAmount1) =
                INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: _cellarTickInfo[i].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            fee0 += collectAmount0 - amount0;
            fee1 += collectAmount1 - amount1;
            outAmount0 += amount0;
            outAmount1 += amount1;
            liquiditySum += outLiquidity;
        }
        fee0 = (fee0 * fee) / FEEDOMINATOR;
        fee1 = (fee1 * fee) / FEEDOMINATOR;
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    receive() external payable {}
}