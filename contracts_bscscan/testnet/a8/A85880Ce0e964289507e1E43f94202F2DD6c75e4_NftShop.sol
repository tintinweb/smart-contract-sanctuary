// SPDX-License-Identifier: MIT

/* version 0.1.1 - Aggiunta funzione di withdraw all tokens - Multimanager Last V 0.1.4 */


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";
import "./IMarket.sol";
import "./LibMarket.sol";
import "./ERC20.sol";

contract NftShop is INftShop, ERC721, Multimanager{
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    
    uint256 _price;

    Counters.Counter private _tokenIds;
    
    constructor() ERC721("Nala X", "NALAX"){   
        _price = 500000000000000000;
    }
    
    function buyNft() public payable {
        
        require((msg.value >= _price ), 'The payment must be greater than 0.5 BNB');
        
        address from = msg.sender;
        uint256 paymentReceved = msg.value;
        
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        _nftPaymentValue[newItemId]=paymentReceved; // quanto è stato pagato l'NFT
        _nftOwner[newItemId]=from; // chi è il propretario dell'Nft
        
        emit redeemNftEvent(newItemId, from, paymentReceved);
    }

    /* Funzioni Pubbliche */
    function getTokenBalanceAndOwner(uint256 tokenID)public view returns (uint256, address){
        return (_nftPaymentValue[tokenID], _nftOwner[tokenID]);
    }

    function getPrice() public view returns (uint256){
        return _price;
    }
    
    /* Funzioni di amministrazione */
    function _transferBNB(address payable _to, uint256 amount) public onlyManager{
        require(address(this).balance >= amount); 
        _to.transfer(amount);
    }
    
    function _paymentToManager(uint256 amount) public onlyManager {
         require(address(this).balance >= amount); 
         payable(msg.sender).transfer(amount);
    }
    
    function _transferAllTokensContracts(ERC20 _token, address payable _to, uint256 amount) public onlyManager{
        _token.transfer(_to, amount);
    }

}