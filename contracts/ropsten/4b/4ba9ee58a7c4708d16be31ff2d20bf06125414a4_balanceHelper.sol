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
        uint256 etherBalance;
        uint256[] tokenBalances; 
    }

    function _getTokenBalance(address _from, address _tokenAddress) view internal returns (uint256) {
        try ERC20Interface(_tokenAddress).balanceOf(_from) returns (uint256 v) {
            return v;
        } catch {
            return 0;
        }
    }
    
    function _getEtherBalance(address _from) view internal returns (uint256) {
        return address(_from).balance;
    }
    
    function getBalances(address[] memory _addresses, address[] memory _tokens) view public returns (balancePair[] memory) {
        balancePair[] memory result = new balancePair[](_addresses.length);
        

        for (uint256 a = 0; a < _addresses.length; a++) {

            uint256[] memory tokenBal = new uint256[](_tokens.length);
            uint256 etherBal = _getEtherBalance(_addresses[a]);

            for (uint256 t = 0; t < _tokens.length; t++) {
                tokenBal[t] = _getTokenBalance(_addresses[a], _tokens[t]);
            }
            
            result[a] = balancePair(_addresses[a], etherBal, tokenBal);
        }
        return result;
    }

}