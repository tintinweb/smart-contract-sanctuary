pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}


contract Resolver {
    struct Balances {
        address owner;
        uint[] balance;
    }
    function getBalances(address[] memory owners, address[] memory tknAddress) public view returns (Balances[] memory) {
        Balances[] memory tokensBal = new Balances[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            uint[] memory bals = new uint[](tknAddress.length);
            for (uint j = 0; j < tknAddress.length; j++) {
                if (tknAddress[j] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                    bals[j] = owners[i].balance;
                } else {
                    TokenInterface token = TokenInterface(tknAddress[j]);
                    bals[j] = token.balanceOf(owners[i]);
                }
            }
            tokensBal[i] = Balances({
                owner: owners[i],
                balance: bals
            });
        }
        return tokensBal;
    }
}


contract InstaPowerERC20Resolver is Resolver {
    string public constant name = "ERC20-Power-Resolver-v1";
}