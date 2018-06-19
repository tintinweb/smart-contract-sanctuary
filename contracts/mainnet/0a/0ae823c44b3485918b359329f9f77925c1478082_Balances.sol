pragma solidity ^0.4.23;

interface Token {
    function balanceOf(address) external view returns(uint);
}

contract Balances {
    function getBalances(address[] users, Token[] tokens) external view returns(uint[]) {
        uint numUsers = users.length;
        uint numTokens = tokens.length;
        uint[] memory result = new uint[](numUsers * numTokens);
        uint resultInd = 0;
        uint userInd = 0;
        uint tokenInd = 0;
        
        for(userInd = 0 ; userInd < numUsers ; userInd++) {
            for(tokenInd = 0 ; tokenInd < numTokens ; tokenInd++) {
                result[resultInd++] = tokens[tokenInd].balanceOf(users[userInd]);
            }
        }
        
        return result;
        
    }
}