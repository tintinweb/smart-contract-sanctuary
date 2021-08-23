//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import './IUniswapV3Factory.sol';
import './INonfungiblePositionManager.sol';

interface IERC721Receiver {
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract PlethoriVault {
    
    
   struct Deposit {
      address owner;
      int24 tickLower;
      int24 tickUpper;
      uint128 liquidity;
    }
   
   IUniswapV3Factory public factory;

   INonfungiblePositionManager public nonfungiblePositionManager;
   
   mapping(uint256 => Deposit) public deposits;


    constructor(
        IUniswapV3Factory _factory,
        INonfungiblePositionManager _nonfungiblePositionManager   
    ) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }  
    
    
     function deposit(uint256 tokenId) external{
         int24 tickLower;
         int24 tickUpper;
         uint128 liquidity;
         (tickLower,tickUpper,liquidity) = getPositionInfo(tokenId);
         
         deposits[tokenId] = Deposit({
             owner:msg.sender,
             tickLower:tickLower,
             tickUpper:tickUpper,
             liquidity:liquidity
         });
         
     }
    
 

    function getPositionInfo(uint256 tokenId) internal view returns(
         int24 tickLower,
         int24  tickUpper,
         uint128  liquidity
    ){
          (
            ,
            ,
            ,
            ,
            ,
           tickLower,
           tickUpper,
           liquidity
            ,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(tokenId);
        
     
    }

}