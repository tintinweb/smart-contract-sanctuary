/*

 Copyright 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.6;

import "../../../utils/exchanges/uniswap/IUniswapV2Router02/IUniswapV2Router02.sol";
import "../../../utils/exchanges/uniswap/IUniswapV2Factory/IUniswapV2Factory.sol";
import "../../../utils/exchanges/uniswap/IUniswapV2Pair/IUniswapV2Pair.sol";

interface Token {

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256);
}

interface DragoEventful {

    function customDragoLog(bytes4 _methodHash, bytes calldata _encodedParams) external returns (bool success);
}

abstract contract Drago {

    address public owner;

    function getExchangesAuth() external virtual view returns (address);

    function getEventful() external virtual view returns (address);
}

abstract contract ExchangesAuthority {
    function canTradeTokenOnExchange(address _token, address _exchange) external virtual view returns (bool);
}

contract AUniswapV2 {

    address payable constant private UNISWAP_V2_ROUTER_ADDRESS = payable(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    bytes4 constant private SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (uint amountA, uint amountB, uint liquidity)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, tokenA);
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, tokenB);
        _safeApprove(tokenA, UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        _safeApprove(tokenB, UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        (amountA, amountB, liquidity) = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(tokenA).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(tokenA, UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        }
        if (Token(tokenB).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(tokenB, UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        }
        /*
        DragoEventful events = DragoEventful(getDragoEventful());
        bytes4 methodHash = bytes4(keccak256("addLiquidity(address[3],uint256[4],address,uint256)"));
        bytes memory encodedParams = abi.encode(
            address(this),
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        require(
            events.customDragoLog(methodHash, encodedParams),
            "UNISWAP_ADD_LIQUIDITY_LOG_ERROR"
        );
        */
    }

    function addLiquidityETH(
        uint sendETHAmount,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, token);
        _safeApprove(token, UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        (amountToken, amountETH, liquidity) = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS)
        .addLiquidityETH{value: sendETHAmount}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(token).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(token, UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        public
        returns (uint amountA, uint amountB)
    {
        //callerIsDragoOwner();
        IUniswapV2Pair(
            address(
                IUniswapV2Factory(
                    IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).factory()
                ).getPair(
                    tokenA,
                    tokenB
                )
            )
        ).approve(UNISWAP_V2_ROUTER_ADDRESS, liquidity);
        (amountA, amountB) = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to != address(this) ? address(this) : address(this), // cannot remove liquidity to any other than Drago
            deadline
        );
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        public
        returns (uint amountToken, uint amountETH)
    {
        //callerIsDragoOwner();
        IUniswapV2Pair(
            address(
                IUniswapV2Factory(
                    IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).factory()
                ).getPair(
                    IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).WETH(),
                    token
                )
            )
        ).approve(UNISWAP_V2_ROUTER_ADDRESS, liquidity);
        (amountToken, amountETH) = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        public
        returns (uint amountETH)
    {
        //callerIsDragoOwner();
        IUniswapV2Pair(
            address(
                IUniswapV2Factory(
                    IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).factory()
                ).getPair(
                    IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).WETH(),
                    token
                )
            )
        ).approve(UNISWAP_V2_ROUTER_ADDRESS, liquidity);
        amountETH = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
    }

    // **** SWAP ****
    // TODO: check for attack vectors in complex path in all functions
    // TODO: potentially restrict to known/preapproved paths or max path.length = 2
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    function swapExactETHForTokens(
        uint256 exactETHAmount,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS)
        .swapExactETHForTokens{value: exactETHAmount}(
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    function swapETHForExactTokens(
        uint256 sendETHAmount,
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts)
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        amounts = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS)
        .swapETHForExactTokens{value: sendETHAmount}(
            amountOut,
            path,
            to != address(this) ? address(this) : address(this), // can only transfer to this drago
            deadline
        );
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this),
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 exactETHAmount,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[(path.length -1)]);
        IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS)
        .swapExactETHForTokensSupportingFeeOnTransferTokens{value: exactETHAmount}(
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this),
            deadline
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
    {
        //callerIsDragoOwner();
        //canTradeTokenOnExchange(UNISWAP_V2_ROUTER_ADDRESS, path[0]);
        _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, 2**256 -1);
        IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to != address(this) ? address(this) : address(this),
            deadline
        );
        if (Token(path[0]).allowance(address(this), UNISWAP_V2_ROUTER_ADDRESS) > uint256(0)) {
            _safeApprove(path[0], UNISWAP_V2_ROUTER_ADDRESS, uint256(0));
        }
    }

    // **** INTERNAL ****
    /// @dev Gets the address of the logger contract.
    /// @return Address of the logger contrac.
    function getDragoEventful()
        internal
        view
        returns (address)
    {
        address dragoEvenfulAddress =
            Drago(
                address(this)
            ).getEventful();
        return dragoEvenfulAddress;
    }

    function callerIsDragoOwner()
        internal
        view
    {
        if (
            Drago(
                address(this)
            ).owner() != msg.sender
        ) { revert("FAIL_OWNER_CHECK_ERROR"); }
    }

    function canTradeTokenOnExchange(
        address payable uniswapV2RouterAddress,
        address token
    )
        internal
        view
    {
        if (!ExchangesAuthority(
                Drago(
                    address(uint160(address(this)))
                )
                .getExchangesAuth()
            )
            .canTradeTokenOnExchange(token, uniswapV2RouterAddress)) {
                revert("UNISWAP_TOKEN_ON_EXCHANGE_ERROR");
            }
    }
    
    function _safeApprove(
        address token,
        address spender,
        uint256 value
    )
        internal
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, spender, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RIGOBLOCK_APPROVE_FAILED"
        );
    }
}

pragma solidity >=0.5.12 <0.8.0;

interface IUniswapV2Router02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    // solhint-disable-next-line
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

pragma solidity >=0.7.6 <0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.6 <0.8.0;

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

    /* solhint-disable */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    /* solhint-enable */
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

    // solhint-disable-next-line
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

