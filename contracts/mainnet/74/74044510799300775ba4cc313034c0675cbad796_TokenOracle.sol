/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address _whom) external view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}


contract TokenOracle {
    function fetch(address[] memory tokens) view public returns(string[] memory symbols, string[] memory names, uint8[] memory decimals, uint256[] memory supplies) {
        
        symbols = new string[](tokens.length);
        names = new string[](tokens.length);
        decimals = new uint8[](tokens.length);
        supplies = new uint256[](tokens.length);
        
        for(uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            names[i] = token.name();
            decimals[i] = token.decimals();
            symbols[i] = token.symbol();
            supplies[i] = token.totalSupply();
        }
    }
}