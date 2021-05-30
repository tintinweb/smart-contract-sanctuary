/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWeth is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IWstEth is IERC20{
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function stETH() external view returns (IERC20);
}


interface IUniswapV2Pair{

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function mul(
        D256 memory d1,
        D256 memory d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return Decimal.D256({ value: Math.getPartial(d1.value, d2.value, BASE) });
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }

    function add(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(amount) });
    }

    function sub(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.sub(amount) });
    }

}

interface IStructs{
    enum Operation {
        Open,
        Borrow,
        Repay,
        Liquidate,
        TransferOwnership
    }

    struct Principal {
        bool sign; // true if positive
        uint256 value;
    }

    struct Position {
        address owner;
        Principal collateralAmount;
        Principal borrowedAmount;
    }

    struct OperationParams {
        uint256 id;
        uint256 amountOne;
        uint256 amountTwo;
        address addressOne;
    }

}

interface IOracle is IStructs{
     function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory);
}

interface IarcxPool is IStructs{

    function operateAction(
        Operation operation,
        OperationParams memory params
    ) external ;

    function getCurrentOracle() external view returns(address);

    function calculateLiquidationPrice(Decimal.D256 memory currentPrice) external view returns(Decimal.D256 memory);

    function calculateCollateralDelta(
        Principal memory parSupply,
        uint256 borrowedAmount,
        Decimal.D256 memory price
    )
        external
        view
        returns (Principal memory);

    function getPosition(uint256 position) external view returns (Position memory);

    function getFees()
    external
    view
    returns (
        Decimal.D256 memory _liquidationUserFee,
        Decimal.D256 memory _liquidationArcRatio
    );
}

interface ICurvePool {

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256); 
    // i = 1 to send, j = 0 to receive, 
}

contract ArcxLiquidations is IStructs {
    
    using SafeMath for uint256;
    using Math for uint256;

    IUniswapV2Pair stablexPair = IUniswapV2Pair(address(0x1BccE9E2Fd56E8311508764519d28E6ec22D4a47));

    IUniswapV2Pair ethUsdcPair = IUniswapV2Pair(address(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc));

    IarcxPool arcxPool = IarcxPool(address(0xC466Ec062D554BEB42f1766488F7345261C63616));

    IERC20 stablex = IERC20(address(0xcD91538B91B4ba7797D39a2f66E63810b50A33d0));

    IERC20 usdc = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));

    IWstEth wsteth = IWstEth(address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0));

    IWeth weth = IWeth(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    
    ICurvePool curvePool = ICurvePool(address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022));

    address owner;
    
    constructor() public {
        owner = msg.sender;
        wsteth.stETH().approve(address(curvePool), uint256(-1));
    }
    
    fallback() external payable {
        
    }
    
    receive() external payable {
        
    }

    function uniswapV2Call(address pair, uint256 amount0Out, uint256 amount1Out, bytes memory data) external {

        if(msg.sender != address(stablexPair)){
            return;
        }

        (uint256 amount, uint256 amountUSDC, uint256 position) = abi.decode(data, (uint256, uint256, uint256));

        OperationParams memory params = OperationParams({
            id: position,
            amountOne: 1,
            amountTwo: 1,
            addressOne: address(0)
        });

        arcxPool.operateAction(Operation.Liquidate, params);

        require(wsteth.balanceOf(address(this)) > 0, "!no collateral received");
        
        // unwraps wsteth
        uint256 stethBalance = wsteth.unwrap(wsteth.balanceOf(address(this)));
        // get amountOut for steth on curve
        uint256 ethAmountOut = curvePool.get_dy(1, 0, stethBalance);
        // swap steth for eth on curve
        curvePool.exchange(1, 0, stethBalance, ethAmountOut);

        (uint256 _amount0Out, uint256 _amount1Out) = ethUsdcPair.token0() == address(weth)?
            (uint256(0), amountUSDC):(amountUSDC, uint256(0));

        (uint256 reserve0, uint256 reserve1, ) = ethUsdcPair.getReserves();

        (uint256 reserveIn, uint256 reserveOut) = ethUsdcPair.token0() == address(weth)? 
        (reserve0, reserve1) : (reserve1, reserve0); 
        
        uint256 wethAmount = getAmountIn(amountUSDC, reserveIn, reserveOut);

        weth.deposit{value: wethAmount}();

        bytes memory empty;

        weth.transfer(address(ethUsdcPair), wethAmount);

        ethUsdcPair.swap(_amount0Out, _amount1Out, address(this), empty);

        usdc.transfer(msg.sender, amountUSDC);
        
    }

    function withdrawErc20(address token) external {

        require(msg.sender == owner, "!owner");
        
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        
    }
    
    function withdraw() external {
        
        require(msg.sender == owner, "!owner");
        
        payable(msg.sender).transfer(address(this).balance);
        
    }


    function getAmountOfStableXNeeded(uint256 posIndex) public view returns(uint256 borrowToLiquidate){

        Decimal.D256 memory currentPrice = IOracle(arcxPool.getCurrentOracle()).fetchCurrentPrice();

        Decimal.D256 memory liquidationPrice = arcxPool.calculateLiquidationPrice(currentPrice);

        Position memory position = arcxPool.getPosition(posIndex);

        Principal memory collateralDelta = arcxPool.calculateCollateralDelta(
            position.collateralAmount,
            position.borrowedAmount.value,
            liquidationPrice
        );

        (Decimal.D256 memory liquidateUserFees, Decimal.D256 memory liquidateArcxFees) = arcxPool.getFees();

        collateralDelta.value = Decimal.mul(
            collateralDelta.value,
            Decimal.add(
                liquidateUserFees,
                Decimal.one().value
            )
        );


        borrowToLiquidate = Decimal.mul(
            collateralDelta.value,
            liquidationPrice
        );

    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) private returns (uint amountIn) {
        require(amountOut > 0, 'ArcxLiquidation: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ArcxLiquidation: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }


    function run(uint256 posIndex) external {

        require(msg.sender == owner, "!owner");

        uint256 amount = getAmountOfStableXNeeded(posIndex);

        (uint256 amount0Out, uint256 amount1Out) = stablexPair.token0() == address(stablex)?
            (amount, uint256(0)):(uint256(0), amount);

        (uint256 reserve0, uint256 reserve1, ) = stablexPair.getReserves();

        (uint256 reserveIn, uint256 reserveOut) = stablexPair.token0() == address(stablex)? 
        (reserve1, reserve0) : (reserve0, reserve1); 

        uint256 amountIn = getAmountIn(amount, reserveIn, reserveOut);

        bytes memory data = abi.encode(amount, amountIn, posIndex);

        stablexPair.swap(amount0Out, amount1Out, address(this), data);

    }


}