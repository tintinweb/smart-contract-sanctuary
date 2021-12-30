// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Holder.sol";
import "./IERC1155.sol";

interface IAdidasOriginals {

  function purchase(uint256 amount) external payable;

}

contract GoMint is ERC1155Holder{

  function mint(address targetNft) payable external{
   
    IAdidasOriginals(targetNft).purchase{value: address(this).balance}(2);
    IERC1155(targetNft).safeTransferFrom(address(this), tx.origin, 0, 2, "");
  }
  
}

contract GoMintFactory{

  address targetNft;
  uint256 price = 2000000000000000 * 2;


  constructor(address _targetNft){
    targetNft = _targetNft;
  }

  function goMint()external payable{


    for(uint8 i = 0; i< 50; i++){
      address mintContract;
      bytes memory bytecode = type(GoMint).creationCode;

      bytes32 salt = keccak256(abi.encodePacked(i,block.timestamp,msg.sender));
      assembly {
          mintContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }

      //mintContract.transfer(price);
      GoMint(mintContract).mint{value:price}(targetNft);

    }

  }

}