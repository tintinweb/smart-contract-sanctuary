// SPDX-License-Identifier: MIT

/* solhint-disable no-empty-blocks */
pragma solidity 0.8.6;

import { IUniswapV2Pair } from "./external/uniswap/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "./external/uniswap/IUniswapV2Router02.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";
import { FeeManager } from "./abstract/FeeManager.sol";

contract FanFeeManager is FeeManager, Ownable {
    /// @notice address of wrapped BNB
    address public wBNB;

    /// @notice address of LP mint
    address public lpMint;

    /// @notice uniswap V2 pair address
    IUniswapV2Pair public uniswapPair;
    /// @notice uniswap V2 router
    IUniswapV2Router02 public uniswapRouter;

    /// @notice min amount of tokens to trigger sync
    uint256 public minTokens;

    /// @notice fee distribution
    uint256 public burnFeeAlloc = 10;
    uint256 public lpFeeAlloc = 10;
    uint256 public totalFeeAlloc = burnFeeAlloc + lpFeeAlloc;

    constructor(address _token, address _wBNB) FeeManager(_token) {
        require(_wBNB != address(0), "_wBNB address cannot be 0");
        wBNB = _wBNB;
        minTokens = 1000 * 10**18;
    }

    function setUniswap(address _uniswapPair, address _uniswapRouter) external onlyOwner {
        require(_uniswapPair != address(0), "_uniswapPair address cannot be 0");
        require(_uniswapRouter != address(0), "_uniswapRouter address cannot be 0");
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        IERC20(token).approve(address(uniswapRouter), 0);
        IERC20(token).approve(address(uniswapRouter), type(uint256).max);
        IERC20(wBNB).approve(address(uniswapRouter), 0);
        IERC20(wBNB).approve(address(uniswapRouter), type(uint256).max);
    }

    function canSyncFee(address, address recipient) external view override returns (bool shouldSyncFee) {
        if (recipient == address(uniswapPair)) {
            shouldSyncFee = true; // when swap FAN > BNB
        }
    }

    function _syncFee() internal override {
        uint256 totalAmount = IERC20(token).balanceOf(address(this));
        uint256 burnAmount;

        if (totalAmount >= minTokens) {
            burnAmount = (totalAmount * burnFeeAlloc) / totalFeeAlloc;
            IERC20(token).burn(burnAmount);

            uint256 lpAmount = totalAmount - burnAmount;

            uint256 swapAmount = lpAmount / 2;
            uint256 liquidityAmount = lpAmount - swapAmount;

            // swap half for BNB
            uint256 preBNB = IERC20(wBNB).balanceOf(address(this));
            _swapTokens(swapAmount);
            uint256 postBNB = IERC20(wBNB).balanceOf(address(this));

            // add other half with received BNB
            _addTokensToLiquidity(liquidityAmount, postBNB - preBNB);
        }
    }

    function _swapTokens(uint256 amount) private {
        address[] memory path = new address[](2);

        path[0] = token;
        path[1] = wBNB;

        try
            uniswapRouter.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp // solhint-disable-line not-rely-on-time
            )
        {
            //
        } catch {
            //
        }
    }

    function _addTokensToLiquidity(uint256 tokensAmount, uint256 usdAmount) private {
        if (tokensAmount != 0 && usdAmount != 0) {
            address destination = (lpMint != address(0)) ? lpMint : address(this);

            try
                uniswapRouter.addLiquidity(
                    token,
                    wBNB,
                    tokensAmount,
                    usdAmount,
                    0,
                    0,
                    destination,
                    block.timestamp // solhint-disable-line not-rely-on-time
                )
            {
                //
            } catch {
                //
            }
        }
    }

    function setLpMint(address _lpMint) public onlyOwner {
        lpMint = _lpMint;
    }

    function setMinTokens(uint256 _minTokens) public onlyOwner {
        require(_minTokens >= 100, "not less then 100");
        minTokens = _minTokens;
    }

    function setFeeAlloc(uint256 _burnFeeAlloc, uint256 _lpFeeAlloc) public onlyOwner {
        require(_burnFeeAlloc >= 10 && _burnFeeAlloc <= 100, "_burnFeeAlloc is outside of range 10-100");
        require(_lpFeeAlloc >= 10 && _lpFeeAlloc <= 100, "_lpFeeAlloc is outside of range 10-100");
        burnFeeAlloc = _burnFeeAlloc;
        lpFeeAlloc = _lpFeeAlloc;
        totalFeeAlloc = burnFeeAlloc + lpFeeAlloc;
    }

    function recoverBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function recoverBep20(address _token) external onlyOwner {
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract FeeManager {
    /// @notice token address
    address public token;

    constructor(address _token) {
        require(_token != address(0), "_token address cannot be 0");
        token = _token;
        _lock = _NOT_LOCKED;
    }

    modifier onlyToken() {
        require(msg.sender == token, "only token");
        _;
    }

    uint256 private constant _NOT_LOCKED = 1;
    uint256 private constant _LOCKED = 2;
    uint256 private _lock;

    modifier lock() {
        if (_lock == _NOT_LOCKED) {
            _lock = _LOCKED;
            _;
            _lock = _NOT_LOCKED;
        }
    }

    function syncFee() external onlyToken lock {
        _syncFee();
    }

    function canSyncFee(address sender, address recipient) external view virtual returns (bool shouldSyncFee);

    function _syncFee() internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

/* solhint-disable func-name-mixedcase */
pragma solidity 0.8.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

/* solhint-disable func-name-mixedcase */
pragma solidity 0.8.6;

/**
 * @title Uniswap V2 router01 interface
 */
interface IUniswapV2Router01 {
    // external functions

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
            uint256,
            uint256,
            uint256
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory);

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
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256);

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
    ) external returns (uint256, uint256);

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
    ) external returns (uint256, uint256);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory);

    // external functions (views)

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory);

    // external functions (pure)

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IUniswapV2Router01.sol";

/**
 * @title Uniswap V2 router02 interface
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    // external functions

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256);

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
    ) external returns (uint256);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

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