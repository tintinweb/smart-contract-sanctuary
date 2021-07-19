/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;



abstract contract ERC20Interface {
    function balanceOf(address whom) view public virtual returns (uint256);
}

contract balanceHelper {
    
    struct balancePair
    {
        address addr; 
        uint256 bal; 
    }

    function _getTokenBalance(address _from, address _tokenAddress) view internal returns (uint256) {
        return ERC20Interface(_tokenAddress).balanceOf(_from);
    }
    
    function _getEtherBalance(address _from) view internal returns (uint256) {
        return address(_from).balance;
    }
    
    function getBalances(address _from, address[] memory _tokens) view public returns (balancePair[] memory) {
        balancePair[] memory result = new balancePair[](_tokens.length + 1);

        balancePair memory bp = balancePair(_from, _getEtherBalance(_from));
        result[0] = bp;
        for (uint256 i = 0; i < _tokens.length; i++) {
            result[i+1] = balancePair(_tokens[i], _getTokenBalance(_from, _tokens[i]));
        }
        
        return result;
    }

}