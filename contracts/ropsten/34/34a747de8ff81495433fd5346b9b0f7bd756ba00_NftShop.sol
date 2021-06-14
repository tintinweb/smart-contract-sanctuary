// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";
import "./IMarket.sol";
import "./LibMarket.sol";

contract NftShop is INftShop, ERC721, Multimanager{
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    constructor() ERC721("Mirai Nft", "MIRAI"){
        
    }

    
    function buyNft() public payable {
        
        require((msg.value > 0 ), 'The payment must be greater than zero');
        
        address from = msg.sender;
        uint256 paymentReceved = msg.value;
        
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _nftPaymentValue[newItemId]=paymentReceved;
        _nftOwner[newItemId]=from;
        
        emit redeemNftEvent(newItemId, from, paymentReceved);
    }

    function getTokenBalanceAndOwner(uint256 tokenID)public view returns (uint256, address){
        return (_nftPaymentValue[tokenID], _nftOwner[tokenID]);
    }
    
    function paymentFromManager(uint256 amount) public onlyManager {
        
         require(address(this).balance >= amount); 
         payable(msg.sender).transfer(amount);
    }

}