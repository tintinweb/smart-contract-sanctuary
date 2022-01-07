// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Defines a new type with two fields.
// Declaring a struct outside of a contract allows
// it to be shared by multiple contracts.
// Here, this is not really needed.
struct TokenDetail {
    int256 amount;
}

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

contract SimpleMapping {
    // Structs can also be defined inside contracts, which makes them
    // visible only there and in derived contracts.
    struct TokenContract {
        address tokenAddress;
        int256 amount;
        TokenType tokenType;
        mapping(int256 => int256) nftAmount;
    }

    uint256 numPools;
    mapping(uint256 => TokenContract[]) pools;

    //Add a new type of token to initial a new pool
    function newPool(address tokenContractAddress, TokenType tokenType)
        public
        returns (uint256 poolID)
    {
        poolID = numPools++; // poolID is return variable
        // We cannot use "pools[poolID] = TokenContract(address, amount)"
        // because the RHS creates a memory-struct "TokenContract" that contains a mapping.
        TokenContract[] storage tokenArray = pools[poolID];
        TokenContract storage tc = tokenArray[0];
        tc.tokenAddress = tokenContractAddress;
        tc.amount = 0;
        tc.tokenType = tokenType;
    }

    function contributeToPool(
        uint256 poolID,
        address tokenContractAddress,
        int256 tokenAmount,
        int256 tokenID,
        TokenType tokenType
    ) public {
        bool isTokenContractExist = false;

        TokenContract[] storage tokenArray = pools[poolID];
        for (uint256 i = 0; i < tokenArray.length; i++) {
            if (tokenContractAddress == tokenArray[i].tokenAddress) {
                if (tokenArray[i].tokenType == TokenType.ERC20) {
                    tokenArray[i].amount += tokenAmount;
                } else {
                    tokenArray[i].nftAmount[tokenID] += tokenAmount;
                }
                isTokenContractExist = true;
            }
        }

        if(!isTokenContractExist){
            TokenContract storage tc = tokenArray[tokenArray.length];
            tc.tokenAddress = tokenContractAddress;
            tc.tokenType = tokenType;
            if(tokenType == TokenType.ERC20) {
                tc.amount = tokenAmount;
            } else {
                tc.amount = 0;
                tc.nftAmount[tokenID] = tokenAmount;
            }
        }

        //Add new token if doest exist
    }

    // function checkGoalReached(uint campaignID) public returns (bool reached) {
    //     TokenContract storage c = pools[campaignID];
    //     if (c.amount < c.fundingGoal)
    //         return false;
    //     uint amount = c.amount;
    //     c.amount = 0;
    //     c.beneficiary.transfer(amount);
    //     return true;
    // }
}