/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

pragma solidity ^0.5.17;



contract ERC20Interface {
    function balanceOf(address whom) view public returns (uint256);
}

contract balanceHelper {

    function getTokenBalance(address _from, address _tokenAddress) view public returns (uint256) {
        return ERC20Interface(_tokenAddress).balanceOf(_from);
    }
    
    function getEtherBalance(address _from) view public returns (uint256) {
        return address(_from).balance;
    }
    
    function getBalances(address _from, address[] memory _tokens) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_tokens.length + 1);
        
        result[0] = getEtherBalance(_from);
        for (uint256 i = 0; i < _tokens.length; i++) {
            result[i+1] = getTokenBalance(_from, _tokens[i]);
        }
        
        return result;
    }

}