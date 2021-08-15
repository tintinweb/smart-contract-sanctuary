/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

interface iBEP20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function uniswapV2Pair() external view returns (address);
    function pancakeV2Pair() external view returns (address);
}

abstract contract Context {
    address internal ZEROAddr = 0x0000000000000000000000000000000000000000;
    address internal DEADddr = 0x000000000000000000000000000000000000dEaD;
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract BEP20_Info is Context{

    struct TokenINFO {string name;string symbol;uint8 decimals;uint256 hsupply;uint256 supply;address pair;uint256 balance;uint256 hbalance;}
    mapping(address => TokenINFO) public toke_information;

    function getinfo(address _token_ca) public view returns (TokenINFO memory) {
        address uSwapPair;
        address pSwapPair;
        address pair;
        iBEP20 TINS;
        TINS = iBEP20(_token_ca);

        try TINS.uniswapV2Pair() {uSwapPair = TINS.uniswapV2Pair();}catch(bytes memory){}
        try TINS.pancakeV2Pair() {pSwapPair = TINS.pancakeV2Pair();}catch(bytes memory){}

        if (ZEROAddr != uSwapPair && DEADddr != uSwapPair) {
            pair = uSwapPair;
        }
        if (ZEROAddr != pSwapPair && DEADddr != pSwapPair) {
            pair = pSwapPair;
        }

        TokenINFO memory tinfo = TokenINFO(
            TINS.name(),
            TINS.symbol(),
            TINS.decimals(),
            TINS.totalSupply(),
            TINS.totalSupply() / (10 ** TINS.decimals()),
            pair,
            TINS.balanceOf(_msgSender()),
            TINS.balanceOf(_msgSender()) / (10 **  TINS.decimals())
        );
        return tinfo;
    }
}