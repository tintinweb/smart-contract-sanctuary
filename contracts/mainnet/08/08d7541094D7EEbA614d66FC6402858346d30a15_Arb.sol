/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Arb.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6 >=0.8.6 <0.9.0;

////// src/IBasicIssuance.sol
/* pragma solidity 0.8.6; */

interface IBasicIssuance {
    function getRequiredComponentUnitsForIssue(
        address _setToken,
        uint256 _quantity
    )
        external
        view
        returns (address[] memory, uint256[] memory);

    function issue(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;
}

////// src/IERC20.sol
/* pragma solidity ^0.8.6; */

interface IERC20 {
    function balanceOf(address _guy) external view returns (uint256);
    function transfer(address _guy, uint256 _wad) external;
    function approve(address spender, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
}

////// src/IExchangeIssuance.sol
/* pragma solidity ^0.8.6; */

interface IExchangeIssuance {
    function redeemExactSetForToken(
        address _setToken,
        address _outputToken,
        uint256 _amountSetToken,
        uint256 _minOutputReceive
    ) external returns (uint256);

    function issueExactSetFromToken(
        address _setToken,
        address _inputToken,
        uint256 _amountSetToken,
        uint256 _maxAmountInputToken
    ) external returns (uint256);
}

////// src/ISetToken.sol
/* pragma solidity 0.8.6; */

interface ISetToken {
    function getComponents() external view returns (address[] memory);
}

////// src/IUniRouter.sol
// SPDX-License-Identifer: UNLICENSED
/* pragma solidity 0.8.6; */

interface IUniRouter {
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

////// src/IUniswapV3Pool.sol
/* pragma solidity ^0.8.6; */

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);
}

////// src/IWETH9.sol
/* pragma solidity 0.8.6; */

interface IWETH9 {
    function deposit() external payable;
}

////// src/Arb.sol
/* pragma solidity ^0.8.6; */

/* import { IBasicIssuance } from "./IBasicIssuance.sol"; */
/* import { IERC20 } from "./IERC20.sol"; */
/* import { IExchangeIssuance } from "./IExchangeIssuance.sol"; */
/* import { ISetToken } from "./ISetToken.sol"; */
/* import { IUniRouter } from "./IUniRouter.sol"; */
/* import { IUniswapV3Pool } from "./IUniswapV3Pool.sol"; */
/* import { IWETH9 } from "./IWETH9.sol"; */

contract Arb {

    IUniswapV3Pool constant pool = IUniswapV3Pool(0x9359c87B38DD25192c5f2b07b351ac91C90E6ca7);
    IExchangeIssuance constant exchangeIssuance = IExchangeIssuance(0xc8C85A3b4d03FB3451e7248Ff94F780c92F884fD);
    IBasicIssuance constant basicIssuance = IBasicIssuance(0xd8EF3cACe8b4907117a45B0b125c68560532F94D);

    IUniRouter constant uniRouter = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniRouter constant sushiRouter = IUniRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address constant inst = 0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb;
    address constant badger = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant knc = 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202;

    IUniswapV3Pool constant instPool = IUniswapV3Pool(0xCba27C8e7115b4Eb50Aa14999BC0866674a96eCB);

    IERC20 constant dpi = IERC20(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);
    IERC20 constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() {
        dpi.approve(address(exchangeIssuance), type(uint256).max);
        dpi.approve(address(pool), type(uint256).max);
        weth.approve(address(exchangeIssuance), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        weth.approve(address(uniRouter), type(uint256).max);
        weth.approve(address(sushiRouter), type(uint256).max);
        weth.approve(address(instPool), type(uint256).max);
    }

    function buy(uint256 _dpiAmount) external {

        pool.swap(
            address(this),
            false,
            -int256(_dpiAmount),
            1461446703485210103287273052203988822378723970341,
            bytes(abi.encode(true, msg.sender))
        );
    }

    function sell(uint256 _dpiAmount) external {

        pool.swap(
            address(this),
            true,
            int256(_dpiAmount),
            4295128740,
            bytes(abi.encode(false, msg.sender))
        );
    }

    function approve() external {
        address[] memory components = ISetToken(address(dpi)).getComponents();

        for (uint256 i = 0; i < components.length; i++) {
            IERC20 component = IERC20(components[i]);
            if(component.allowance(address(this), address(basicIssuance)) == 0) {
                component.approve(address(basicIssuance), type(uint256).max);
            }
        }
    }

    function uniswapV3SwapCallback(int256 a, int256 b, bytes calldata c) external {
        (bool isBuy, address to) = abi.decode(c, (bool, address));

        if (to == address(0)) {
            weth.transfer(address(instPool), uint256(b));
            return;
        }

        if (isBuy) {
            _completeBuy(uint256(b), to);
            weth.transfer(address(pool), uint256(b));
        } else {
            _completeSell(uint256(a), to);
            dpi.transfer(address(pool), uint256(a));
        }
    }

    function _completeBuy(uint256 _back, address _to) internal {

        uint256 dpiBalance = dpi.balanceOf(address(this));
        uint256 out = exchangeIssuance.redeemExactSetForToken(
            address(dpi),
            address(weth),
            dpiBalance,
            0
        );

        weth.transfer(_to, out - _back);
    }

    function _completeSell(uint256 _back, address _to) internal {

        _issue(_back);

        uint256 wethBalance = weth.balanceOf(address(this));
        weth.transfer(_to, wethBalance);
    }

    function _issue(uint256 _amount) internal {
        (address[] memory components, uint256[] memory amounts) =
            basicIssuance.getRequiredComponentUnitsForIssue(address(dpi), _amount);

        for (uint256 i = 0; i < components.length; i++) {
            _buyComponent(components[i], amounts[i]);
        }

        basicIssuance.issue(address(dpi), _amount, address(this));
    }

    function _buyComponent(address _token, uint256 _amount) internal {

        if (_token == inst) {
            instPool.swap(
                address(this),
                false,
                -int256(_amount),
                1461446703485210103287273052203988822378723970341,
                bytes(abi.encode(true, address(0)))
            );
        } else if (_token == badger) {
            address[] memory path = new address[](3);
            path[0] = address(weth);
            path[1] = wbtc;
            path[2] = _token;

            uniRouter.swapTokensForExactTokens(
                _amount,
                type(uint256).max,
                path,
                address(this),
                type(uint256).max
            );
        } else {
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = _token;

            IUniRouter router = _token == knc ? sushiRouter : uniRouter;

            router.swapTokensForExactTokens(
                _amount,
                type(uint256).max,
                path,
                address(this),
                type(uint256).max
            );
        }
    }

    receive() external payable {
        IWETH9(address(weth)).deposit{value: msg.value}();
    }
}