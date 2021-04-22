/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity 0.8.3;

// "SPDX-License-Identifier: MIT"

abstract contract ERC721Base {
    function  balanceOf(address owner) external virtual view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns(uint256);
    function tokenURI(uint256 tokenId) public view virtual returns(string memory);
}

contract Collector {
    
    
    constructor() {
        
    }
    
    function aggregate(address owner, address[] memory contractsAddrs) public view returns (uint256 blockNumber, string[][] memory returnData) {
        blockNumber = block.number;
        returnData = new string[][](contractsAddrs.length);
        
        for(uint256 contractIndex = 0; contractIndex < contractsAddrs.length; contractIndex++) {
            ERC721Base _contract = ERC721Base(contractsAddrs[contractIndex]);
            uint256 balance = _contract.balanceOf(owner);
            if(balance > 0){
                string[] memory tokensInfoURIsForContract = new string[](balance);
                for(uint256 tokenIndex = 0; tokenIndex < balance; tokenIndex++){
                    uint256 tokenId = _contract.tokenOfOwnerByIndex(owner, tokenIndex);
                    string memory tokenInfoURI = _contract.tokenURI(tokenId);
                    tokensInfoURIsForContract[tokenIndex] = tokenInfoURI;
                }
                returnData[contractIndex] = tokensInfoURIsForContract;
            }
            else{
                //returnData[contractIndex] = string[]();
            }
        }
    }
    
    
    
}