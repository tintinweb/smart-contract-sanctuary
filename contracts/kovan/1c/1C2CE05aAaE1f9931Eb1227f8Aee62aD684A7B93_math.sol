/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract math{
     struct Token721 {
        address contractAddress;
        uint256 tokenId;
    }
    struct Token1155 {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }
    mapping(uint256 => Token721[]) internal Token721s;
    mapping(uint256 => Token1155[]) internal Token1155s;
    
    function getTokens(uint256 shardPoolId)
        external
        view
        returns (Token721[] memory _token721s, Token1155[] memory _token1155s)
    {
        _token721s = Token721s[shardPoolId];
        _token1155s = Token1155s[shardPoolId];
    }
     function createShard(
     uint256 shardPoolId,
        Token721[] calldata token721s,
        Token1155[] calldata token1155s
       
    ) external      {
        
        for (uint256 i = 0; i < token721s.length; i++) {
            Token721 memory token = token721s[i];
            Token721s[shardPoolId].push(token);

            
        }
        for (uint256 i = 0; i < token1155s.length; i++) {
            Token1155 memory token = token1155s[i];
            Token1155s[shardPoolId].push(token);
          
        }
    }
 
}