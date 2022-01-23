// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/ITattooAntiBot.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IAddressHelper.sol";

contract TattooAntiBot is ITattooAntiBot {
    mapping(address => uint256) public _lastTradeTime;
    uint256 public _listingTime;
    uint256 public _listingBlock;
    address private _owner;
    address public _router;
    address public _token;
    address public _pairToken;
    address public _pairAddress;
    uint256 public _amountLimitPerTrade;
    uint256 public _amountToBeAddedPerBlock;
    uint256 public _timeLimitPerTrade;
    uint256 public _blockNumberToDisable;

    event PreTransferCheck(address pair, uint256 listingTime);

    constructor(){
        _listingTime = 0;
    }

    function saveConfig(address[] memory addresses, uint[] memory amounts) external {
        _router = addresses[0];
        _token = addresses[1];
        _pairToken = addresses[2];
        _amountLimitPerTrade = amounts[0];
        _amountToBeAddedPerBlock = amounts[1];
        _timeLimitPerTrade = amounts[2];
        _blockNumberToDisable = amounts[3];
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_router);
        if (IUniswapV2Factory(uniswapV2Router.factory()).getPair(_token, _pairToken) == address(0)) {
            _pairAddress = IUniswapV2Factory(uniswapV2Router.factory()).createPair(_token, _pairToken);
            _listingTime = block.timestamp;
            _listingBlock = block.number;
        }
        else
        {
            if (_listingTime == 0)
            {
                _listingTime = block.timestamp;
                _listingBlock = block.number;
            }
            _pairAddress = IUniswapV2Factory(uniswapV2Router.factory()).getPair(_token, _pairToken);
        }
    }

    function setTokenOwner(address newOwner) external override {
        address oldOwner = _owner;
        _owner = newOwner;
    }

    function onPreTransferCheck(address from, address to, uint256 amount) external override {
        IAddressHelper addressHelper = IAddressHelper(0x3Befa0536736bfbe2E343b6488eA0901aA23d7cc);
        require(addressHelper.existInWhitelist(from, address(this)), "beneficiary is not in whitelist");
        require(!addressHelper.existInBlacklist(from, address(this)), "beneficiary is in blacklist");
        require(_listingBlock > 0, "This token is not listed yet");
        require(amount <= _amountLimitPerTrade + _amountToBeAddedPerBlock * (block.number - _listingBlock), "Amount exceeds limit per Trade");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_router);
        address pair;
        if (IUniswapV2Factory(uniswapV2Router.factory()).getPair(from, to) == address(0)) {
            pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(from, to);
        }
        else
        {
            pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(from, to);
        }
        require(block.timestamp > _lastTradeTime[pair] + _timeLimitPerTrade, "Time exceeds the time limit per Trade");
        _lastTradeTime[pair] = block.timestamp;
        if (block.number > _listingBlock + _blockNumberToDisable)
        {
            _timeLimitPerTrade = 0;
        }
        emit PreTransferCheck(pair, _lastTradeTime[pair]);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ITattooAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

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
pragma solidity ^0.8.0;

interface IAddressHelper {
    function existInBlacklist(address _beneficiary, address _bot) external view returns (bool);
    function existInWhitelist(address _beneficiary, address _bot) external view returns (bool);
    function getBlacklist(address _bot) external view returns (address[] memory);
    function getWhitelist(address _bot) external view returns (address[] memory);
}