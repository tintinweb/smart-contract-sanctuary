/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

contract Resolver {
    struct TokenBalances {
        uint[] userBalances;
    }

    function getBalances(address[] memory owners, address[] memory tknAddress) public view returns (TokenBalances[] memory) {
        TokenBalances[] memory tokensBal = new TokenBalances[](tknAddress.length);
        for (uint i = 0; i < tknAddress.length; i++) {
            uint[] memory bals = new uint[](owners.length);
            TokenInterface token = TokenInterface(tknAddress[i]);
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                for (uint j = 0; j < owners.length; j++) {
                    bals[j] = owners[j].balance;
                }
            } else {
                for (uint j = 0; j < owners.length; j++) {
                    bals[j] = token.balanceOf(owners[j]);
                }
            }
           
            tokensBal[i] = TokenBalances({
                userBalances: bals
            });
        }
        return tokensBal;
    }
}


contract InstaPowerERC20Resolver is Resolver {
    string public constant name = "ERC20-Power-Resolver-v1";
}