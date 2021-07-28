/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

/*
 *
 *  ___  ___                               _____
 *  |  \/  |                              |_   _|
 *  | .  . |_   _ _ __ ___  _ __ ___  _   _ | | _ __  _   _
 *  | |\/| | | | | '_ ` _ \| '_ ` _ \| | | || || '_ \| | | |
 *  | |  | | |_| | | | | | | | | | | | |_| || || | | | |_| |
 *  \_|  |_/\__,_|_| |_| |_|_| |_| |_|\__, \___/_| |_|\__,_|
 *                                     __/ |
 *                                    |___/
 *
 * https://t.me/MummyInu
 * https://mummyinu.com
 *
 * MATIC release today  (Wed, 28 Jul 2021)
 * BSC   release next week
 * ETH   release TBD
 *
 */

pragma solidity ^0.6.12;

// SPDX-License-Identifier: The MIT License

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

contract NewTokenAdvertisement is Context, IBEP20 {
    uint256 private _tTotal = 100000000 * 10**6 * 10**9;
    string private _name = "MummyInu Ad (t.me/mummyinu)";
    string private _symbol = "MUMINU-AD";
    uint8 private _decimals = 6;

    IPancakeRouter02 public immutable pcsV2Router;
    address public immutable pcsV2Pair;

    constructor() public {
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        // Create a uniswap pair for this new token
        pcsV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(
            address(this),
            _pancakeswapV2Router.WETH()
        );
        pcsV2Router = _pancakeswapV2Router;

        emit Transfer(address(0), address(0xdead), _tTotal);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {}
}