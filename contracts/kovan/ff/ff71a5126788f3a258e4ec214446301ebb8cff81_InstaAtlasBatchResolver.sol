/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-04
*/

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function delegates(address) external view returns (address);
}


contract InstaAtlasBatchResolver {
    struct Balances {
        address owner;
        uint balance;
        address delegates;
    }

    function getBalances(address token, address[] memory holders) public view returns (Balances[] memory) {
        Balances[] memory tokensBal = new Balances[](holders.length);
        TokenInterface tokenContract = TokenInterface(token);
        for (uint i = 0; i < holders.length; i++) {
            address holder = holders[i];
            tokensBal[i] = Balances({
                owner: holder,
                balance: tokenContract.balanceOf(holder),
                delegates: tokenContract.delegates(holder)
            });
        }
        return tokensBal;
    }
}