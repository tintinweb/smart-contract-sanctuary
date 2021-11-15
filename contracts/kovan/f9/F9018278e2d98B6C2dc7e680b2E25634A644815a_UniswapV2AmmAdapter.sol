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

struct Position {
  address setToken;
  address tokenA;
  uint256 amountA;
  address tokenB;
  uint256 amountB;
  uint256 balance;
  uint256 totalSupply;
  uint256 reserveA;
  uint256 reserveB;
  uint256 calculatedAmountA;
  uint256 calculatedAmountB;
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
    address public immutable router;
    IUniswapV2Factory public immutable factory;

    // Internal function string for adding liquidity
    string internal constant ADD_LIQUIDITY =
        "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)";
    // Internal function string for removing liquidity
    string internal constant REMOVE_LIQUIDITY =
        "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)";

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _router          Address of Uniswap V2 Router contract
     */
    constructor(address _router) public {
        router = _router;
        factory = IUniswapV2Factory(IUniswapV2Router(_router).factory());
    }

    /* ============ External Getter Functions ============ */

    /**
     * Return calldata for the add liquidity call
     *
     * @param  _setToken                Address of the SetToken
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to add liquidity
     * @param  _maxTokensIn             AmountsIn desired to add liquidity
     * @param  _minLiquidity            Min liquidity amount to add
     */
    function getProvideLiquidityCalldata(
        address _setToken,
        address _pool,
        address[] calldata _components,
        uint256[] calldata _maxTokensIn,
        uint256 _minLiquidity
    )
        external
        view
        override
        returns (address target, uint256 value, bytes memory data)
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

        Position memory position = Position(_setToken, _components[0], _maxTokensIn[0], _components[1], _maxTokensIn[1],
            0, pair.totalSupply(), 0, 0, 0, 0);
        require(position.totalSupply > 0, "_pool totalSupply must be > 0");

        // Determine how much of each token the _minLiquidity would return
        (position.reserveA, position.reserveB) = _getReserves(pair, position.tokenA);
        position.calculatedAmountA = position.reserveA.mul(_minLiquidity).div(position.totalSupply);
        position.calculatedAmountB = position.reserveB.mul(_minLiquidity).div(position.totalSupply);

        require(position.calculatedAmountA  <= position.amountA && position.calculatedAmountB <= position.amountB,
            "_minLiquidity is too high for input token limit");

        target = router;
        value = 0;
        data = abi.encodeWithSignature(
            ADD_LIQUIDITY,
            position.tokenA,
            position.tokenB,
            position.amountA,
            position.amountB,
            position.calculatedAmountA,
            position.calculatedAmountB,
            position.setToken,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * Return calldata for the add liquidity call for a single asset
     */
    function getProvideLiquiditySingleAssetCalldata(
        address /* _setToken */,
        address /*_pool*/,
        address /*_component*/,
        uint256 /*_maxTokenIn*/,
        uint256 /*_minLiquidity*/
    )
        external
        view
        override
        returns (address /*target*/, uint256 /*value*/, bytes memory /*data*/)
    {
        revert("Uniswap V2 single asset addition is not supported");
    }

    /**
     * Return calldata for the remove liquidity call
     *
     * @param  _setToken                Address of the SetToken
     * @param  _pool                    Address of liquidity token
     * @param  _components              Address array required to remove liquidity
     * @param  _minTokensOut            AmountsOut minimum to remove liquidity
     * @param  _liquidity               Liquidity amount to remove
     */
    function getRemoveLiquidityCalldata(
        address _setToken,
        address _pool,
        address[] calldata _components,
        uint256[] calldata _minTokensOut,
        uint256 _liquidity
    )
        external
        view
        override
        returns (address target, uint256 value, bytes memory data)
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

        Position memory position = Position(_setToken, _components[0], _minTokensOut[0], _components[1], _minTokensOut[1],
            pair.balanceOf(_setToken), pair.totalSupply(), 0, 0, 0, 0);

        require(_liquidity <= position.balance, "_liquidity must be <= to current balance");

        // Calculate how many tokens are owned by the liquidity
        (position.reserveA, position.reserveB) = _getReserves(pair, position.tokenA);
        position.calculatedAmountA = position.reserveA.mul(position.balance).div(position.totalSupply);
        position.calculatedAmountB = position.reserveB.mul(position.balance).div(position.totalSupply);

        require(position.amountA <= position.calculatedAmountA && position.amountB <= position.calculatedAmountB,
            "amounts must be <= ownedTokens");

        target = router;
        value = 0;
        data = abi.encodeWithSignature(
            REMOVE_LIQUIDITY,
            position.tokenA,
            position.tokenB,
            _liquidity,
            position.amountA,
            position.amountB,
            position.setToken,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * Return calldata for the remove liquidity single asset call
     */
    function getRemoveLiquiditySingleAssetCalldata(
        address /* _setToken */,
        address /*_pool*/,
        address /*_component*/,
        uint256 /*_minTokenOut*/,
        uint256 /*_liquidity*/
    )
        external
        view
        override
        returns (address /*target*/, uint256 /*value*/, bytes memory /*data*/)
    {
        revert("Uniswap V2 single asset removal is not supported");
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
        returns (address spender)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pool);
        require(factory == IUniswapV2Factory(pair.factory()), "_pool factory doesn't match the router factory");

        spender = router;
    }

    /**
     * Verifies that this is a valid Uniswap V2 _pool
     *
     * @param  _pool       Address of liquidity token
     */
    function isValidPool(address _pool)
        external
        view
        override
        returns (bool isValid) {
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
            isValid = factory.getPair(token0, token1) == _pool;
        }
        else {
            return false;
        }
    }

    /* ============ Internal Functions =================== */

    /**
     * Returns the pair reserves in an expected order
     *
     * @param  pair                   The pair to get the reserves from
     * @param  tokenA                 Address of the token to swap
     */
    function _getReserves(
        IUniswapV2Pair pair,
        address tokenA
    )
        internal
        view
        returns (uint reserveA, uint reserveB)
    {
        address token0 = pair.token0();
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
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
        address _setToken,
        address _pool,
        address[] calldata _components,
        uint256[] calldata _maxTokensIn,
        uint256 _minLiquidity
    )
        external
        view
        returns (address _target, uint256 _value, bytes memory _calldata);

    function getProvideLiquiditySingleAssetCalldata(
        address _setToken,
        address _pool,
        address _component,
        uint256 _maxTokenIn,
        uint256 _minLiquidity
    ) external view returns (address _target, uint256 _value, bytes memory _calldata);

    function getRemoveLiquidityCalldata(
        address _setToken,
        address _pool,
        address[] calldata _components,
        uint256[] calldata _minTokensOut,
        uint256 _liquidity
    ) external view returns (address _target, uint256 _value, bytes memory _calldata);

    function getRemoveLiquiditySingleAssetCalldata(
        address _setToken,
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

