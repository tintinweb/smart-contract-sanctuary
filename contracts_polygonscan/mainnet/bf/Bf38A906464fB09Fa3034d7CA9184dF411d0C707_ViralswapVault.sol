// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm6R9KJH KEkg77qc0o0lY6W yvqrtLgZxgKJVAH FTy5ayHJfkisnFM Shi7gaWAfQezYkC M1U9mZfY9OhthMn VhuwjWDrIqu8IaO mBL830YhemOeyZ9 0sNJhblIzLSskfq ii978jFlUJwCtMI 3dKs4NZuJkhW86Q F0ZdHRWO9lUnhvJ Uge2AAymBbtvrmx Z6QE88Wuj10K5wV 96BePfhF27S. END KEYBASE SALTPACK SIGNED MESSAGE.
*/

import './libraries/Math.sol';
import './libraries/SafeMath.sol';
import './interfaces/IViralswapPair.sol';
import './interfaces/IViralswapFactory.sol';
import './interfaces/IViralswapRouter02.sol';
import './interfaces/IERC20Mintable.sol';

/**
 * @dev Implementation of the VIRAL Vault.
 *
 * ViralSwap Vault supports a fixed price buying of tokenOut when sent tokenIn.
 *
 * The tokenIn recieved are then used to add liquidity to the corresponding ViralSwap Pair.
 * The Vault does not hold tokenOut, they're minted each time a buy is made (the Vault MUST have the ability to mint tokens).
 */
contract ViralswapVault {
    using SafeMathViralswap for uint256;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public factory;
    address public tokenIn;
    address public tokenOut;
    address public pair;
    address public viralswapRouter02;

    uint256 public availableQuota;
    uint256 public feeOnTokenOutTransferBIPS;
    uint256 public tokenOutPerInflatedTokenIn; // inflated by 1e18

    uint112 private reserveIn;           // uses single storage slot, accessible via getReserves
    uint112 private reserveOut;          // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Viralswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) {
        _reserveIn = reserveIn;
        _reserveOut = reserveOut;
        _blockTimestampLast = blockTimestampLast;
    }

    function getQuoteOut(address _tokenIn, uint256 _amountIn) external view returns (uint256 amountOut) {
        if(_tokenIn != tokenIn) {
            return 0;
        }
        amountOut = _amountIn.mul(tokenOutPerInflatedTokenIn) / 1e18;
        if(amountOut > availableQuota) {
            return 0;
        }
    }

    function getQuoteIn(address _tokenOut, uint256 _amountOut) external view returns (uint256 amountIn) {
        if(_tokenOut != tokenOut) {
            return 0;
        }
        if(_amountOut > availableQuota) {
            return 0;
        }
        amountIn = _amountOut.mul(1e18) / tokenOutPerInflatedTokenIn;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Viralswap: TRANSFER_FAILED');
    }

    event Buy(address indexed sender, uint256 amountOut, address indexed to);
    event Sync(uint112 reserveIn, uint112 reserveOut);
    event AddQuota(uint256 quota);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at the time of deployment
    function initialize(uint256 _tokenOutPerInflatedTokenIn, address _tokenIn, address _tokenOut, address _viralswapRouter02, uint256 _feeOnTokenOutTransferBIPS) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        require(_tokenOutPerInflatedTokenIn != 0, "Viralswap: INVALID_TOKENOUT_QUANTITY");
        require(feeOnTokenOutTransferBIPS < 10000, "Viralswap: INVALID_FEE_ON_TOKENOUT");
        tokenOutPerInflatedTokenIn = _tokenOutPerInflatedTokenIn;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        viralswapRouter02 = _viralswapRouter02;
        feeOnTokenOutTransferBIPS = _feeOnTokenOutTransferBIPS;

        pair = IViralswapFactory(factory).getPair(_tokenIn, _tokenOut);
        require(pair != address(0), "Viralswap: PAIR_DOES_NOT_EXIST");
        (uint256 swapReserveIn, uint256 swapReserveOut) = _getSwapReserves(_tokenIn, _tokenOut);
        require(swapReserveIn > 0 && swapReserveOut > 0, "Viralswap: NO_LIQUIDITY_IN_POOL");
    }

    // called by factory to update the ViralRouter address
    function updateRouter(address _viralswapRouter02) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        viralswapRouter02 = _viralswapRouter02;
    }

    // called by factory to add minting quota for tokenOut
    function addQuota(uint256 quota) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        availableQuota = availableQuota.add(quota);
        emit AddQuota(quota);
    }

    function withdrawERC20(address _token, address _to) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        uint256 balance = IERC20Viralswap(_token).balanceOf(address(this));
        IERC20Viralswap(_token).transfer(_to, balance);
        _update();
    }

    // called by self to mint tokenOut
    function _mint(address _account, uint256 _amount) private {
        require(availableQuota >= _amount, 'Viralswap: INSUFFICIENT_QUOTA');
        availableQuota = availableQuota.sub(_amount);
        IERC20ViralswapMintable(tokenOut).mint(_account, _amount);
    }

    // update reserves to match current balances
    function _update() private {
        uint256 balanceIn = IERC20Viralswap(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20Viralswap(tokenOut).balanceOf(address(this));
        require(balanceIn <= uint112(-1) && balanceOut <= uint112(-1), 'Viralswap: OVERFLOW');
        reserveIn = uint112(balanceIn);
        reserveOut = uint112(balanceOut);
        blockTimestampLast = uint32(block.timestamp % 2**32);
        emit Sync(reserveIn, reserveOut);
    }

    function _addLiquidity(uint256 _amountInDesired, uint256 _amountOutDesired) private {

        IERC20Viralswap(tokenIn).transfer(pair, _amountInDesired);
        IERC20Viralswap(tokenOut).transfer(pair, _amountOutDesired);

        IViralswapPair(pair).mint(address(this));
    }

    function _getSwapReserves(address _tokenIn, address _tokenOut) internal view returns (uint256 _reserveIn, uint256 _reserveOut){

        (uint256 reserve0, uint256 reserve1,) = IViralswapPair(pair).getReserves();
        (_reserveIn, _reserveOut) = _tokenIn < _tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _quotePair(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // What actually is happening in the function:
    //  - calculate amount of tokenIn sent to the vault, check if it is atleast the expected amount, refund excess
    //  - calculate the tokenOut needed to add to liquidity
    //  - mint the required amount of tokenOut (buy + liquidity)
    //  - transfer tokenOut to the `to` address
    //  - add liquidity to the corresponding pair
    //  - update reserves
    function buy(uint256 amountOut, address to) external lock {
        require(msg.sender == viralswapRouter02, "Viralswap: FORBIDDEN");
        require(amountOut > 0, 'Viralswap: INSUFFICIENT_OUT_AMT');

        address _tokenIn = tokenIn;
        (uint112 _reserveIn,,) = getReserves();

        uint256 balanceIn = IERC20Viralswap(_tokenIn).balanceOf(address(this));
        uint256 amountIn = balanceIn.sub(_reserveIn);
        uint256 amountInExpected = amountOut.mul(1e18) / tokenOutPerInflatedTokenIn;
        require(amountIn >= amountInExpected, 'Viralswap: INSUFFICIENT_IN_AMT');

        _mint(address(this), amountOut); // important to have this before _tryBalancePool, as availableQuota changes
        IERC20Viralswap(tokenOut).transfer(to, amountOut);

        _tryBalancePool(_reserveIn, amountIn, availableQuota);

        emit Buy(msg.sender, amountOut, to);
    }

    function _tryBalancePool(uint256 _reserveIn, uint256 _maxSpendTokenIn, uint256 _maxSpendTokenOut) internal {
        require(_maxSpendTokenIn != 0 || _maxSpendTokenOut != 0, "Viralswap: ZERO_SPEND");

        address _tokenIn = tokenIn;
        address _tokenOut = tokenOut;
        bool buyTokenOut;
        uint256 swapAmountIn;
        {
            (uint256 swapReserveIn, uint256 swapReserveOut) = _getSwapReserves(_tokenIn, _tokenOut);
            (buyTokenOut, swapAmountIn) = IViralswapFactory(factory).computeProfitMaximizingTrade(
                1e18, tokenOutPerInflatedTokenIn, swapReserveIn, swapReserveOut
            );
        }

        uint256 maxSpend = buyTokenOut ? _maxSpendTokenIn : _maxSpendTokenOut;
        if (swapAmountIn > maxSpend) {
            swapAmountIn = maxSpend;
        }

        if(swapAmountIn != 0) {
             if(buyTokenOut) {
                // spend swapAmountIn worth of _tokenIn
                _swap(BURN_ADDRESS, _tokenIn, _tokenOut, swapAmountIn);

            } else {
                // mint and spend swapAmountIn worth of _tokenOut
                _mint(address(this), swapAmountIn);
                _swap(address(this), _tokenOut, _tokenIn, swapAmountIn);
            }
        }

        uint256 tokenInForLiquidity = IERC20Viralswap(_tokenIn).balanceOf(address(this)).sub(_reserveIn);

        if(tokenInForLiquidity > 0) {
            // the pool is balanced or quota insufficient
            uint256 tokenInForLiquidityFeeAdjusted = tokenInForLiquidity.sub(tokenInForLiquidity.mul(feeOnTokenOutTransferBIPS) / 10000 );
            uint256 tokenOutForLiquidity = tokenInForLiquidity.mul(tokenOutPerInflatedTokenIn) / 1e18;

            _mint(address(this), tokenOutForLiquidity);
            _addLiquidity(tokenInForLiquidityFeeAdjusted, tokenOutForLiquidity);
        }
        _update();
    }

    function _swap(address _to, address _tokenToSell, address _tokenToBuy, uint256 _amountIn) private {
        IERC20Viralswap(_tokenToSell).approve(viralswapRouter02, _amountIn);
        address[] memory path = new address[](2);
        path[0] = _tokenToSell;
        path[1] = _tokenToBuy;

        IViralswapRouter02(viralswapRouter02).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            0, // we can skip computing this number because the math is tested
            path,
            _to,
            block.timestamp
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathViralswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapPair {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getVault(address tokenA, address tokenB) external view returns (address vault);
    function allVaults(uint) external view returns (address vault);
    function allVaultsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function createVault(uint tokenOutPerTokenIn, address tokenIn, address tokenOut, address router, uint feeOnTokenOutTransferBIPS) external returns (address vault);

    function addQuota(address tokenA, address tokenB, uint quota) external;
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external;
    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external;

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;

    function pairCodeHash() external pure returns (bytes32);
    function vaultCodeHash() external pure returns (bytes32);

    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (bool, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapRouter02.sol';

interface IViralswapRouter02 is IUniswapV2Router02 {

    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactViralForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function buyViralForExactTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyViralForExactETHSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function getVaultAmountOut(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
    function getVaultAmountIn(address tokenIn, address tokenOut, uint amountOut) external view returns (uint amountIn);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import './IERC20.sol';

interface IERC20ViralswapMintable is IERC20Viralswap {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import './IUniswapRouter01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function VIRAL() external pure returns (address);
    function altRouter() external pure returns (address);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Viralswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}