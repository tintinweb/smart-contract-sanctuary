//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import './IUniswapV3Factory.sol';
import './INonfungiblePositionManager.sol';



contract PlethoriVault {
    
    
   struct Deposit {
      address owner;
      int24 tickLower;
      int24 tickUpper;
      uint128 liquidity;
    }
   
   IERC721 public nftPosition;
   IUniswapV3Factory public factory;

   INonfungiblePositionManager public nonfungiblePositionManager;
   
   mapping(uint256 => Deposit) public deposits;


    constructor(
        IUniswapV3Factory _factory,
        INonfungiblePositionManager _nonfungiblePositionManager ,
        IERC721 _nftPosition
    ) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        nftPosition = _nftPosition;
    }  
    
    
 
    
     function deposit(uint256 tokenId) external{
         require(tokenId > 0,"NFT tokenId can not be zero.");
         nftPosition.safeTransferFrom(msg.sender,address(this),tokenId);
         int24 tickLower;
         int24 tickUpper;
         uint128 liquidity;
          // get position information
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