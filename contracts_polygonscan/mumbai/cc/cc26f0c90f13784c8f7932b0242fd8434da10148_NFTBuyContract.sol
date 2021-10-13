/**
 *Submitted for verification at polygonscan.com on 2021-10-12
*/

pragma solidity ^0.8.4;



  interface IERC721{
    function create() external;
    function totalSupply() external;
 }
 

contract NFTBuyContract {

    address public targetnftaddress= address(0xbEa51dB32237C19D9C0306D92634FF77258d7Be9);
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