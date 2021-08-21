/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

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
    
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;
        
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}

library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }
    
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }
    
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }
    
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }
    
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }
    
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

library PoolAddress {
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface weth9 is erc20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface univ3 {
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
    function mint(address, int24, int24, uint128, bytes calldata) external returns (uint256, uint256);
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256, uint256);
    function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128, uint128);
    function positions(bytes32) external view returns (uint128, uint, uint, uint128, uint128);
}

contract Keep3rV1Pair {
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    uint public totalSupply = 0;
    
    mapping(address => mapping (address => uint)) public allowance;
    mapping(address => uint) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    address public immutable token0;
    address public immutable token1;
    
    address public immutable pool;
    
    address public governance;
    address public pendingGovernance;

    int24 constant tickLower = -887200;
    int24 constant tickUpper = 887200;
    
    weth9 constant weth = weth9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    uint24 immutable fee;
    
    function _safeTransfer(address token,address to,uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    constructor(address _pool) {
        pool = _pool;
        address _token0 = univ3(_pool).token0();
        address _token1 = univ3(_pool).token1();
        token0 =  _token0;
        token1 =  _token1;
        fee = univ3(_pool).fee();
        name = string(abi.encodePacked("Keep3rV1 - ", erc20(_token0).symbol(), "/", erc20(_token1).symbol()));
        symbol = string(abi.encodePacked("kLP-", erc20(_token0).symbol(), "/", erc20(_token1).symbol()));
        governance = msg.sender;
    }
    
    modifier gov() {
        require(msg.sender == governance);
        _;
    }
    
    function setGovernance(address _governance) external gov {
        pendingGovernance = _governance;
    }
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
    
    struct MintCallbackData {
        PoolAddress.PoolKey poolKey;
        address payer;
    }
    
    /// @notice Add liquidity to an initialized pool
    function _addLiquidity(uint amount0Desired, uint amount1Desired, uint amount0Min, uint amount1Min)
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee});
            
        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = univ3(pool).slot0();
            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0Desired,
                amount1Desired
            );
        }

        (amount0, amount1) = univ3(pool).mint(
            address(this),
            tickLower,
            tickUpper,
            liquidity,
            abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
        );

        require(amount0 >= amount0Min && amount1 >= amount1Min, 'Price slippage check');
    }
    
    function _pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == address(weth) && address(this).balance >= value) {
            // pay with WETH9
            weth.deposit{value: value}(); // wrap only what is needed to pay
            weth.transfer(recipient, value);
        } else if (payer == address(this)) {
            _safeTransfer(token, recipient, value);
        } else {
            _safeTransferFrom(token, payer, recipient, value);
        }
    }
    
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
    
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        require(msg.sender == pool);
        if (amount0Owed > 0) _pay(decoded.poolKey.token0, decoded.payer, pool, amount0Owed);
        if (amount1Owed > 0) _pay(decoded.poolKey.token1, decoded.payer, pool, amount1Owed);
    }
    
    // this low-level function should be called from a contract which performs important safety checks
    function mint(uint amount0Desired, uint amount1Desired, uint amount0Min, uint amount1Min, address to) external payable returns (uint128 liquidity) {
       (liquidity,,) = _addLiquidity(amount0Desired, amount1Desired, amount0Min, amount1Min);
       _mint(to, liquidity);
       if (address(this).balance > 0) _safeTransferETH(msg.sender, address(this).balance);
    }
    
    function position() external view returns (uint128 liquidity, uint feeGrowthInside0LastX128, uint feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1) {
        (liquidity,feeGrowthInside0LastX128,feeGrowthInside1LastX128,tokensOwed0,tokensOwed1) = univ3(pool).positions(keccak256(abi.encodePacked(address(this), tickLower, tickUpper)));
    }
    
    function collect() external gov returns (uint amount0, uint amount1) {
        (,,,uint128 tokensOwed0, uint128 tokensOwed1) = univ3(pool).positions(keccak256(abi.encodePacked(address(this), tickLower, tickUpper)));
        (amount0, amount1) = univ3(pool).collect(governance, tickLower, tickUpper, tokensOwed0, tokensOwed1);
    }
    
    function burn(uint128 liquidity, uint amount0Min, uint amount1Min, address to) external returns (uint amount0, uint amount1) {
        (amount0, amount1) = univ3(pool).burn(tickLower, tickUpper, liquidity);
        require(amount0 >= amount0Min && amount1 >= amount1Min, 'Price slippage check');
        univ3(pool).collect(to, tickLower, tickUpper, uint128(amount0), uint128(amount1));
        _burn(msg.sender, liquidity);
    }
    
    function _mint(address dst, uint amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
        
    function _burn(address dst, uint amount) internal {
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balanceOf[src] -= amount;
        balanceOf[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }
}