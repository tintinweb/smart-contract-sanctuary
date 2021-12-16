/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// File: _PRICE_GETTER/pricegetter/contracts/libs/IUniPair.sol



pragma solidity >=0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function factory() external view returns (address);
}
// File: _PRICE_GETTER/pricegetter/contracts/libs/IUniRouter.sol


pragma solidity ^0.8.4;

interface IUniRouter01 {
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

interface IUniRouter02 is IUniRouter01 {
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
interface IUniFactory {
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
// File: _PRICE_GETTER/pricegetter/contracts/libs/IAMMInfo.sol


pragma solidity ^0.8.4;

/*
Join us at Crystl.Finance!
█▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/



// calculates the CREATE2 address for a pair without making any external calls
function pairFor(address tokenA, address tokenB, address factory, bytes32 initcodehash) pure returns (address pair) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initcodehash
    )))));
}

struct AmmInfo {
    string name;
    address router;
    address factory;
    uint8 fee;
    bytes32 paircodehash;
}

interface IAMMInfo {

    function getAmmList() external pure returns (AmmInfo[] memory list);

}
// File: _PRICE_GETTER/pricegetter/contracts/libs/AMMInfoPolygon.sol


pragma solidity ^0.8.4;

/*
Join us at Crystl.Finance!
█▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/


contract AMMInfoPolygon is IAMMInfo {

    address constant private APE_FACTORY = 0xCf083Be4164828f00cAE704EC15a36D711491284;
    address constant private QUICK_FACTORY = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address constant private SUSHI_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address constant private DFYN_FACTORY = 0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B;
    address constant private JET_FACTORY = 0x668ad0ed2622C62E24f0d5ab6B6Ac1b9D2cD4AC7;
    address constant private WAULT_FACTORY = 0xa98ea6356A316b44Bf710D5f9b6b4eA0081409Ef; 
    //address constant private BONE_FACTORY = 0xf1F4d4C5F4C20DDAC22CF5FBEdEe025401645c95;
    address constant private POLYCAT_FACTORY = 0x477Ce834Ae6b7aB003cCe4BC4d8697763FF456FA;

    //used for internally locating a pair without an external call to the factory
    bytes32 constant private APE_PAIRCODEHASH = hex'511f0f358fe530cda0859ec20becf391718fdf5a329be02f4c95361f3d6a42d8';
    bytes32 constant private QUICK_PAIRCODEHASH = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';
    bytes32 constant private SUSHI_PAIRCODEHASH = hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303';
    bytes32 constant private DFYN_PAIRCODEHASH = hex'f187ed688403aa4f7acfada758d8d53698753b998a3071b06f1b777f4330eaf3';
    bytes32 constant private JET_PAIRCODEHASH = hex'505c843b83f01afef714149e8b174427d552e1aca4834b4f9b4b525f426ff3c6';
    bytes32 constant private WAULT_PAIRCODEHASH = hex'1cdc2246d318ab84d8bc7ae2a3d81c235f3db4e113f4c6fdc1e2211a9291be47';
    //bytes32 constant private BONE_PAIRCODEHASH = hex'06fd5cbbb236425013aaf86e956638e6888c10bea58ca23d9bef578c3df5b83d';
    bytes32 constant private POLYCAT_PAIRCODEHASH = hex'3cad6f9e70e13835b4f07e5dd475f25a109450b22811d0437da51e66c161255a';

    // Fees are in increments of 1 basis point (0.01%)
    uint8 constant private APE_FEE = 20; 
    uint8 constant private QUICK_FEE = 30;
    uint8 constant private SUSHI_FEE = 30;
    uint8 constant private DFYN_FEE = 30;
    uint8 constant private JET_FEE = 0;
    uint8 constant private WAULT_FEE = 20;
    //uint8 constant private BONE_FEE = 20;
    uint8 constant private POLYCAT_FEE = 24;

    constructor() {
        AmmInfo[] memory list = getAmmList();
        for (uint i; i < list.length; i++) {
            require(IUniRouter02(list[i].router).factory() == list[i].factory, "wrong router/factory");

            IUniFactory f = IUniFactory(list[i].factory);
            IUniPair pair = IUniPair(f.allPairs(0));
            address token0 = pair.token0();
            address token1 = pair.token1();
            
            require(pairFor(token0, token1, list[i].factory, list[i].paircodehash) == address(pair), "bad initcodehash?");

        }

    }

    function getAmmList() public pure returns (AmmInfo[] memory list) {
        list = new AmmInfo[](7);
        list[0] = AmmInfo({
            name: "ApeSwap", 
            router: 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607,
            factory: APE_FACTORY,
            paircodehash: APE_PAIRCODEHASH,
            fee: APE_FEE
        });
        list[1] = AmmInfo({
            name: "QuickSwap", 
            router: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff,
            factory: QUICK_FACTORY,
            paircodehash: QUICK_PAIRCODEHASH,
            fee: QUICK_FEE
        });
        list[2] = AmmInfo({
            name: "Sushi", 
            router: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,
            factory: SUSHI_FACTORY,
            paircodehash: SUSHI_PAIRCODEHASH,
            fee: SUSHI_FEE
        });
        list[3] = AmmInfo({
            name: "DFYN", 
            router: 0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429,
            factory: DFYN_FACTORY,
            paircodehash: DFYN_PAIRCODEHASH,
            fee: DFYN_FEE
        });
        list[4] = AmmInfo({
            name: "JetSwap", 
            router: 0x5C6EC38fb0e2609672BDf628B1fD605A523E5923,
            factory: JET_FACTORY,
            paircodehash: JET_PAIRCODEHASH,
            fee: JET_FEE
        });
        list[5] = AmmInfo({
            name: "WaultSwap", 
            router: 0x3a1D87f206D12415f5b0A33E786967680AAb4f6d,
            factory: WAULT_FACTORY,
            paircodehash: WAULT_PAIRCODEHASH,
            fee: WAULT_FEE
        });
        list[6] = AmmInfo({
            name: "PolyCat", 
            router: 0x94930a328162957FF1dd48900aF67B5439336cBD,
            factory: POLYCAT_FACTORY,
            paircodehash: POLYCAT_PAIRCODEHASH,
            fee: POLYCAT_FEE
        });
    }
}