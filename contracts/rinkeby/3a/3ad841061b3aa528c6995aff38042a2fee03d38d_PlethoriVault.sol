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
    
    
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
       

        _createDeposit(operator,tokenId);

        return this.onERC721Received.selector;
    }
    
    
     function _createDeposit(address owner,uint256 tokenId) internal{
         int24 tickLower;
         int24 tickUpper;
         uint128 liquidity;
          // get position information
         (tickLower,tickUpper,liquidity) = getPositionInfo(tokenId);
         
         deposits[tokenId] = Deposit({
             owner:owner,
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