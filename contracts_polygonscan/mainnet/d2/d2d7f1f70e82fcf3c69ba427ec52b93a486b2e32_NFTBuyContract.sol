/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

  interface IERC721{
    function create() external;
    function totalSupply() external;
 }
 

contract NFTBuyContract {

    address public targetnftaddress= address(0xf7c105dd8BB9095E4276CABfa9659Cf9a6B7b1bF);
    IERC721 private ERC721=IERC721(targetnftaddress);
    function settargetnftaddress(address _targetcontract) public {
        targetnftaddress=_targetcontract;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        
        while (true) {
        ERC721.totalSupply();
        }
        return this.onERC721Received.selector;
    }
    
    function createnft() public {
        ERC721.create();
    }
}