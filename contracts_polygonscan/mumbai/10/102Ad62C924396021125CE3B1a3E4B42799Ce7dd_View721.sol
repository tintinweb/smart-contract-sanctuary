/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

pragma solidity >=0.8.0;

interface I721{
    function balanceOf(address) external view returns(uint256);
    function tokenOfOwnerByIndex(address, uint256) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function tokenByIndex(uint256) external view returns(uint256);
}

contract View721 {
    function getTokenIds(I721 token, address owner, uint256 start, uint256 limit) public view returns(uint256[] memory ) {
        uint256 balance = token.balanceOf(owner);
        uint256[] memory tokenIds;
        if(balance > start){
            uint256 size = balance - start > limit ? limit : balance - start;
            tokenIds = new uint256[](size);
            for(uint256 i = 0; i < size; i++){
                tokenIds[i] = token.tokenOfOwnerByIndex(owner, start+i);
            }
        }
        return tokenIds;
    }
    
    function getBalance(I721 token, address owner) public view returns(uint256) {
        return token.balanceOf(owner);
    }
    
    function getAllTokenIds(I721 token, uint256 start, uint256 limit) public view returns(uint256[] memory ) {
        uint256 balance = token.totalSupply();
        uint256[] memory tokenIds;
        if(balance > start){
            uint256 size = balance - start > limit ? limit : balance - start;
            tokenIds = new uint256[](size);
            for(uint256 i = 0; i < size; i++){
                tokenIds[i] = token.tokenByIndex(start+i);
            }
        }
        return tokenIds;
    }
    
    function getAllBalance(I721 token) public view returns(uint256) {
        return token.totalSupply();
    }
}