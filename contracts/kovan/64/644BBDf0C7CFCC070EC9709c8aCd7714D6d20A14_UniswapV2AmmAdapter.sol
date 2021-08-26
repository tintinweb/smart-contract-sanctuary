/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import "../../../interfaces/external/IUniswapV2Router.sol";
import "../../../interfaces/external/IUniswapV2Pair.sol";
import "../../../interfaces/external/IUniswapV2Factory.sol";
import "../../../interfaces/IAmmAdapter.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Position {
  IERC20 tokenA;
  uint256 amountA;
  IERC20 tokenB;
  uint256 amountB;
}

/**
 * @title UniswapV2AmmAdapter
 * @author Stephen Hankinson
 *
 * Adapter for Uniswap V2 Router that encodes adding and removing liquidty
 */
contract UniswapV2AmmAdapter is IAmmAdapter {
    using SafeMath for uint256;

    /* ============ State Variables ============ */

    // Address of Uniswap V2 Router contract
    IUniswapV2Router public immutable router;
    IUniswapV2Factory public immutable factory;

    // Fee settings for the AMM
    uint256 internal immutable feeNumerator;
    uint256 internal immutable feeDenominator;

    // Internal function string for adding liquidity
    string internal constant ADD_LIQUIDITY =
        "addLiquidity(address,address[],uint256[],uint256,bool)";
    // Internal function string for adding liquidity with a single asset
    string internal constant ADD_LIQUIDITY_SINGLE_ASSET =
        "addLiquiditySingleAsset(address,address,uint256,uint256)";
    // Internal function string for removing liquidity
    string internal constant REMOVE_LIQUIDITY =
        "removeLiquidity(address,address[],uint256[],uint256,bool)";
    // Internal function string for removing liquidity to a single asset
    string internal constant REMOVE_LIQUIDITY_SINGLE_ASSET =
        "removeLiquiditySingleAsset(address,address,uint256,uint256)";

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _router          Address of Uniswap V2 Router contract
     * @param _feeNumerator    Numerator of the fee component (usually 997)
     * @param _feeDenominator  Denominator of the fee component (usually 1000)
     */
    constructor(address _router, uint256 _feeNumerator, uint256 _feeDenominator) public {
        router = IUniswapV2Router(_router);
        factory = IUniswapV2Factory(IUniswapV2Router(_router).factory());
        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;
    }

    /* ============ Internal Functions =================== */

    /**
     * Returns the pair reserves in an expected order
     *
     * @param  pair                   The pair to get the reserves from
     * @param  tokenA                 Address of the token to swap
     */
    function getReserves(
        IUniswapV2Pair pair,
        address tokenA
    )
        internal
        view
        returns (
            uint reserveA,
            uint reserveB
        ) 
    {
        address token0 = pair.token0();
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * Performs a swap via the Uniswap V2 Router
     *
     * @param  pair                   The pair to perform the swap on
     * @param  tokenA                 Address of the token to swap
     * @param  tokenB                 Address of pair token0
     * @param  amount                 Amount of the token to swap
     */
    function performSwap(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB,
        uint256 amount
    )
        internal
        returns (
            uint[] memory amounts
        )
    {

        // Get the reserves of the pair
        (uint256 reserveA, uint256 reserveB) = getReserves(pair, tokenA);

        // Use half of the provided amount in the swap
        uint256 amountToSwap = this.calculateSwapAmount(amount, reserveA);

        // Approve the router to spend the tokens
        IERC20(tokenA).approve(address(router), amountToSwap);

        // Determine how much we should expect of token1
        uint256 amountOut = router.getAmountOut(amountToSwap, reserveA, reserveB);

        // Perform the swap
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        amounts = router.swapExactTokensForTokens(
            amountToSwap,
            amountOut,
            path,
            address(this),
            block.timestamp // solhint-disable-line not-rely-on-time
        );

        // How much token do we have left?
        amounts[0] = amount.sub(amountToSwap);

    }

    /* ============ External Getter Functions ============ */

    /**
     * Returns the amount of tokenA to swap
     *
     * @param  amountA                  The amount of tokenA being supplied
     * @param  reserveA                 The reserve of tokenA in the pool
     */
    function calculateSwapAmount(
        uint256 amountA,
        uint256 reserveA
    )
        external
        view
        returns (
            uint256 swapAmount
        )
    {
        // Solves the following system of equations to find the ideal swapAmount
        // eq1: amountA = swapAmount + amountALP
        // eq2: amountBLP = swapAmount * feeNumerator * reserveB / (reserveA * feeDenominator + swapAmount * feeNumerator)
        // eq3: amountALP = amountBLP * (reserveA + swapAmount) / (reserveB - amountBLP)
        // Substitution: swapAmount^2 * feeNumerator + swapAmount * reserveA * (feeNumerator + feeDenominator) - amountA * reserveA * feeDenominator = 0
        // Solution: swapAmount = (-b +/- sqrt(b^2-4ac))/(2a)
        // a = feeNumerator
        // b = reserveA * (feeNumerator + feeDenominator)
        // c = -amountA * reserveA * feeDenominator
        // Note: a is always positive. b is always positive. The solved
        // equation has a negative multiplier on c but that is ignored here because the
        // negative in front of the 4ac in the quadratic solution would cancel it out,
        // making it an addition. Since b is always positive, we never want to take
        // the negative square root solution since that would always cause a negative
        // swapAmount, which doesn't make sense. Therefore, we only use the positive
        // square root value as the solution.
        uint256 b = reserveA.mul(feeNumerator.add(feeDenominator));
        uint256 c = amountA.mul(feeDenominator).mul(reserveA);

        swapAmount = Babylonian.sqrt(b.mul(b).add(feeNumerator.mul(c).mul(4)))
            .sub(b).div(feeNumerator.mul(2));
    }

    /**
     * Return calldata for the add liquidity call
     *
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to add liquidity
     * @param  _maxTokensIn             AmountsIn desired to add liquidity
     * @param  _minLiquidity            Min liquidity amount to add
     */
    function getProvideLiquidityCalldata(
        address _pool,
        address[] calldata _components,
        uint256[] calldata _maxTokensIn,
        uint256 _minLiquidity
    )
        external
        view
        override
        returns (
            address _target,
            uint256 _value,
            bytes memory _calldata
        )
    {
        _target = address(this);
        _value = 0;
        _calldata = abi.encodeWithSignature(
            ADD_LIQUIDITY,
            _pool,
            _components,
            _maxTokensIn,
            _minLiquidity,
            true
        );
    }

    /**
     * Return calldata for the add liquidity call for a single asset
     *
     * @param  _pool                    Address of liquidity token
     * @param  _component               Address of the token used to add liquidity
     * @param  _maxTokenIn              AmountsIn desired to add liquidity
     * @param  _minLiquidity            Min liquidity amount to add
     */
    function getProvideLiquiditySingleAssetCalldata(
        address _pool,
        address _component,
        uint256 _maxTokenIn,
        uint256 _minLiquidity
    )
        external
        view
        override
        returns (
            address _target,
            uint256 _value,
            bytes memory _calldata
        )
    {
        _target = address(this);
        _value = 0;
        _calldata = abi.encodeWithSignature(
            ADD_LIQUIDITY_SINGLE_ASSET,
            _pool,
            _component,
            _maxTokenIn,
            _minLiquidity
        );
    }

    /**
     * Return calldata for the remove liquidity call
     *
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to remove liquidity
     * @param  _minTokensOut            AmountsOut minimum to remove liquidity
     * @param  _liquidity               Liquidity amount to remove
     */
    function getRemoveLiquidityCalldata(
        address _pool,
        address[] calldata _components,
        uint256[] calldata _minTokensOut,
        uint256 _liquidity
    )
        external
        view
        override
        returns (
            address _target,
            uint256 _value,
            bytes memory _calldata
        )
    {
        _target = address(this);
        _value = 0;
        _calldata = abi.encodeWithSignature(
            REMOVE_LIQUIDITY,
            _pool,
            _components,
            _minTokensOut,
            _liquidity,
            true
        );
    }

    /**
     * Return calldata for the remove liquidity single asset call
     *
     * @param  _pool                    Address of liquidity token
     * @param  _component               Address of token required to remove liquidity
     * @param  _minTokenOut             AmountsOut minimum to remove liquidity
     * @param  _liquidity               Liquidity amount to remove
     */
    function getRemoveLiquiditySingleAssetCalldata(
        address _pool,
        address _component,
        uint256 _minTokenOut,
        uint256 _liquidity
    )
        external
        view
        override
        returns (
            address _target,
            uint256 _value,
            bytes memory _calldata
        )
    {
        _target = address(this);
        _value = 0;
        _calldata = abi.encodeWithSignature(
            REMOVE_LIQUIDITY_SINGLE_ASSET,
            _pool,
            _component,
            _minTokenOut,
            _liquidity
        );
    }

    /**
     * Returns the address of the spender
     *
     * @param  _pool       Address of liquidity token
     */
    function getSpenderAddress(address _pool)
        external
        view
        override
        returns (address)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");

        return address(this);
    }

    /**
     * Verifies that this is a valid Uniswap V2 _pool
     *
     * @param  _pool       Address of liquidity token
     */
    function isValidPool(address _pool) external view override returns (bool) {
        address token0;
        address token1;
        bool success = true;
        IUniswapV2Pair pair = IUniswapV2Pair(_pool);

        try pair.token0() returns (address _token0) {
            token0 = _token0;
        } catch {
            success = false;
        }

        try pair.token1() returns (address _token1) {
            token1 = _token1;
        } catch {
            success = false;
        }

        if( success ) {
            return factory.getPair(token0, token1) == _pool;
        }
        else {
            return false;
        }
    }

    /* ============ External Setter Functions ============ */

    /**
     * Adds liquidity via the Uniswap V2 Router
     *
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to add liquidity
     * @param  _maxTokensIn             AmountsIn desired to add liquidity
     * @param  _minLiquidity            Min liquidity amount to add
     * @param  _shouldTransfer          Should the tokens be transferred from the sender
     */
    function addLiquidity(
        address _pool,
        address[] memory _components,
        uint256[] memory _maxTokensIn,
        uint256 _minLiquidity,
        bool _shouldTransfer
    )
        public
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {

        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");
        require(_components.length == 2, "_components length is invalid");
        require(_maxTokensIn.length == 2, "_maxTokensIn length is invalid");
        require(factory.getPair(_components[0], _components[1]) == _pool, 
            "_pool doesn't match the components");
        require(_maxTokensIn[0] > 0, "supplied token0 must be greater than 0");
        require(_maxTokensIn[1] > 0, "supplied token1 must be greater than 0");
        require(_minLiquidity > 0, "_minLiquidity must be greater than 0");

        Position memory position = Position(IERC20(_components[0]), _maxTokensIn[0],
            IERC20(_components[1]), _maxTokensIn[1]);

        uint256 lpTotalSupply = pair.totalSupply();
        require(lpTotalSupply > 0, "_pool totalSupply must be > 0");

        (uint256 reserveA, uint256 reserveB) = getReserves(pair, _components[0]);
        uint256 amountAMin = reserveA.mul(_minLiquidity).div(lpTotalSupply);
        uint256 amountBMin = reserveB.mul(_minLiquidity).div(lpTotalSupply);

        require(amountAMin <= position.amountA && amountBMin <= position.amountB,
            "_minLiquidity is too high for amount maximums");

        // Bring the tokens to this contract, if needed, so we can use the Uniswap Router
        if( _shouldTransfer ) {
            position.tokenA.transferFrom(msg.sender, address(this), position.amountA);
            position.tokenB.transferFrom(msg.sender, address(this), position.amountB);
        }

        // Approve the router to spend the tokens
        position.tokenA.approve(address(router), position.amountA);
        position.tokenB.approve(address(router), position.amountB);

        // Add the liquidity
        (amountA, amountB, liquidity) = router.addLiquidity(
            address(position.tokenA),
            address(position.tokenB),
            position.amountA,
            position.amountB,
            amountAMin,
            amountBMin,
            msg.sender,
            block.timestamp // solhint-disable-line not-rely-on-time
        );

        // If there is token0 left, send it back
        if( amountA < position.amountA ) {
            position.tokenA.transfer(msg.sender, position.amountA.sub(amountA) );
        }

        // If there is token1 left, send it back
        if( amountB < position.amountB ) {
            position.tokenB.transfer(msg.sender, position.amountB.sub(amountB) );
        }

    }

    /**
     * Adds liquidity via the Uniswap V2 Router, swapping first to get both tokens
     *
     * @param  _pool                    Address of liquidity token
     * @param  _component               Address array required to add liquidity
     * @param  _maxTokenIn              AmountsIn desired to add liquidity
     * @param  _minLiquidity            Min liquidity amount to add
     */
    function addLiquiditySingleAsset(
        address _pool,
        address _component,
        uint256 _maxTokenIn,
        uint256 _minLiquidity
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {

        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");

        address tokenA = pair.token0();
        address tokenB = pair.token1();
        require(tokenA == _component || tokenB == _component, "_pool doesn't contain the _component");
        require(_maxTokenIn > 0, "supplied _maxTokenIn must be greater than 0");
        require(_minLiquidity > 0, "supplied _minLiquidity must be greater than 0");

        // Swap them if needed
        if( tokenB == _component ) {
            tokenB = tokenA;
            tokenA = _component;
        }

        uint256 lpTotalSupply = pair.totalSupply();
        require(lpTotalSupply > 0, "_pool totalSupply must be > 0");

        // Bring the tokens to this contract so we can use the Uniswap Router
        IERC20(tokenA).transferFrom(msg.sender, address(this), _maxTokenIn);

        // Execute the swap
        uint[] memory amounts = performSwap(pair, tokenA, tokenB, _maxTokenIn);

        address[] memory components = new address[](2);
        components[0] = tokenA;
        components[1] = tokenB;

        // Add the liquidity
        (amountA, amountB, liquidity) = addLiquidity(_pool, components, amounts, _minLiquidity, false);

    }

    /**
     * Remove liquidity via the Uniswap V2 Router
     *
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to remove liquidity
     * @param  _minTokensOut            AmountsOut minimum to remove liquidity
     * @param  _liquidity               Liquidity amount to remove
     * @param  _shouldReturn            Should the tokens be returned to the sender?
     */
    function removeLiquidity(
        address _pool,
        address[] memory _components,
        uint256[] memory _minTokensOut,
        uint256 _liquidity,
        bool _shouldReturn
    )
        public
        returns (
            uint amountA,
            uint amountB
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");
        require(_components.length == 2, "_components length is invalid");
        require(_minTokensOut.length == 2, "_minTokensOut length is invalid");
        require(factory.getPair(_components[0], _components[1]) == _pool, 
            "_pool doesn't match the components");
        require(_minTokensOut[0] > 0, "requested token0 must be greater than 0");
        require(_minTokensOut[1] > 0, "requested token1 must be greater than 0");
        require(_liquidity > 0, "_liquidity must be greater than 0");

        Position memory position = Position(IERC20(_components[0]), _minTokensOut[0],
            IERC20(_components[1]), _minTokensOut[1]);

        uint256 balance = pair.balanceOf(msg.sender);
        require(_liquidity <= balance, "_liquidity must be <= to current balance");

        // Calculate how many tokens are owned by the liquidity
        uint[] memory tokenInfo = new uint[](3);
        tokenInfo[2] = pair.totalSupply();
        (tokenInfo[0], tokenInfo[1]) = getReserves(pair, _components[0]);
        tokenInfo[0] = tokenInfo[0].mul(balance).div(tokenInfo[2]);
        tokenInfo[1] = tokenInfo[1].mul(balance).div(tokenInfo[2]);

        require(position.amountA <= tokenInfo[0] && position.amountB <= tokenInfo[1],
            "amounts must be <= ownedTokens");   

        // Bring the lp token to this contract so we can use the Uniswap Router
        pair.transferFrom(msg.sender, address(this), _liquidity);

        // Approve the router to spend the lp tokens
        pair.approve(address(router), _liquidity);

        // Remove the liquidity
        (amountA, amountB) = router.removeLiquidity(
            address(position.tokenA),
            address(position.tokenB),
            _liquidity, 
            position.amountA,
            position.amountB,
            _shouldReturn ? msg.sender : address(this),
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * Remove liquidity via the Uniswap V2 Router and swap to a single asset
     *
     * @param  _pool                    Address of liquidity token
     * @param  _component               Address required to remove liquidity
     * @param  _minTokenOut             AmountOut minimum to remove liquidity
     * @param  _liquidity               Liquidity amount to remove
     */
    function removeLiquiditySingleAsset(
        address _pool,
        address _component,
        uint256 _minTokenOut,
        uint256 _liquidity
    )
        external
        returns (
            uint[] memory amounts
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");

        address tokenA = pair.token0();
        address tokenB = pair.token1();
        require(tokenA == _component || tokenB == _component, "_pool doesn't contain the _component");
        require(_minTokenOut > 0, "requested token must be greater than 0");
        require(_liquidity > 0, "_liquidity must be greater than 0");

        // Swap them if needed
        if( tokenB == _component ) {
            tokenB = tokenA;
            tokenA = _component;
        }

        // Determine if enough of the token will be received
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = getReserves(pair, _component);
        uint[] memory receivedTokens = new uint[](2);
        receivedTokens[0] = reserveA.mul(_liquidity).div(totalSupply);
        receivedTokens[1] = reserveB.mul(_liquidity).div(totalSupply);

        address[] memory components = new address[](2);
        components[0] = tokenA;
        components[1] = tokenB;

        (receivedTokens[0], receivedTokens[1]) = removeLiquidity(_pool, components, receivedTokens, _liquidity, false);

        uint256 amountReceived = router.getAmountOut(
            receivedTokens[1],
            reserveB.sub(receivedTokens[1]),
            reserveA.sub(receivedTokens[0])
        );

        require( receivedTokens[0].add(amountReceived) >= _minTokenOut,
            "_minTokenOut is too high for amount received");

        // Approve the router to spend the swap tokens
        IERC20(tokenB).approve(address(router), receivedTokens[1]);

        // Swap the other token for _component
        components[0] = tokenB;
        components[1] = tokenA;
        amounts = router.swapExactTokensForTokens(
            receivedTokens[1],
            amountReceived,
            components,
            address(this),
            block.timestamp // solhint-disable-line not-rely-on-time
        );

        // Send the tokens back to the caller
        IERC20(tokenA).transfer(msg.sender, receivedTokens[0].add(amounts[1]));

    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

interface IUniswapV2Router {
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

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.6.10;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;


/**
 * @title IAmmAdapter
 * @author Set Protocol
 */
interface IAmmAdapter {

    function getProvideLiquidityCalldata(
        address _pool,
        address[] calldata _components,
        uint256[] calldata _maxTokensIn,
        uint256 _minLiquidity
    )
        external
        view
        returns (address _target, uint256 _value, bytes memory _calldata);

    function getProvideLiquiditySingleAssetCalldata(
        address _pool,
        address _component,
        uint256 _maxTokenIn,
        uint256 _minLiquidity
    ) external view returns (address _target, uint256 _value, bytes memory _calldata);

    function getRemoveLiquidityCalldata(
        address _pool,
        address[] calldata _components,
        uint256[] calldata _minTokensOut,
        uint256 _liquidity
    ) external view returns (address _target, uint256 _value, bytes memory _calldata);

    function getRemoveLiquiditySingleAssetCalldata(
        address _pool,
        address _component,
        uint256 _minTokenOut,
        uint256 _liquidity
    ) external view returns (address _target, uint256 _value, bytes memory _calldata);

    function getSpenderAddress(address _pool) external view returns(address);
    function isValidPool(address _pool) external view returns(bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}