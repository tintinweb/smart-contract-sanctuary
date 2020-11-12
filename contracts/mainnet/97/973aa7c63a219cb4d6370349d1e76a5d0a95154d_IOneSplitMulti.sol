pragma solidity ^0.5.0;

import "./IERC20.sol";

contract IOneSplitConsts {
    // disableFlags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_KYBER + ...
    uint256 public constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 public constant FLAG_DISABLE_KYBER = 0x02;
    uint256 public constant FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x100000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x200000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x400000000; // Turned off by default
    uint256 public constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 public constant FLAG_DISABLE_OASIS = 0x08;
    uint256 public constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 public constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 public constant FLAG_DISABLE_CHAI = 0x40;
    uint256 public constant FLAG_DISABLE_AAVE = 0x80;
    uint256 public constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Turned off by default
    uint256 public constant FLAG_DISABLE_BDAI = 0x400;
    uint256 public constant FLAG_DISABLE_IEARN = 0x800;
    uint256 public constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 public constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 public constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 public constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Turned off by default
    uint256 public constant FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Turned off by default
    uint256 public constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 public constant FLAG_DISABLE_WETH = 0x80000;
    uint256 public constant FLAG_ENABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_ENABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_ENABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_DISABLE_IDLE = 0x800000;
}

contract IOneSplit is IOneSplitConsts {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) public payable;
}

contract IOneSplitMulti is IOneSplit {
    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable;
}