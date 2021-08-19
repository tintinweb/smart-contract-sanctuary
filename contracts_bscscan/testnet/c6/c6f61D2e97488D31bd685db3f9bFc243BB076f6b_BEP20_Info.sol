/**
 *Submitted for verification at BscScan.com on 2021-08-19
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

contract BEP20_Info is Context {
    struct Token_Data {
        string name;
        string symbol;
        uint8 decimals;
        uint256 hsupply;
        uint256 supply;
        uint256 balance;
        uint256 hbalance;
        address pair;
    }

    function getInfo(address _token_ca, address wallet_addr, bool isCakeLP) internal view returns (Token_Data memory) {
        address pair;
        iBEP20 TINS;
        TINS = iBEP20(_token_ca);

        uint256 TotalSupply = TINS.totalSupply();
        uint256 walletBalance = TINS.balanceOf(wallet_addr);
        uint8 decimals = TINS.decimals();

        if (isCakeLP) {

        } else {
            try TINS.uniswapV2Pair() {pair = TINS.uniswapV2Pair();}catch(bytes memory){}
            try TINS.pancakeV2Pair() {pair = TINS.pancakeV2Pair();}catch(bytes memory){}
        }

        Token_Data memory info = Token_Data(
            TINS.name(),
            TINS.symbol(),
            decimals,
            TotalSupply,
            TotalSupply / (10 ** decimals),
            walletBalance,
            walletBalance / (10 ** decimals),
            pair
        );
        return info;
    }

    function tokenInfo(address _token_ca, address wallet_address) public view returns (Token_Data memory){
        Token_Data memory info = getInfo(_token_ca, wallet_address, false);
        return info;
    }

    function cakeLP(address _token_ca, address wallet_address) public view returns (Token_Data memory){
        Token_Data memory info = getInfo(_token_ca, wallet_address, true);
        return info;
    }
}