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

contract HS is INftShop, ERC721URIStorage, Multimanager{
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    
    uint256 private _priceInBNBWei;
    uint256 private _priceInTokenWei;
    ERC20 private _tokenForBuy; 
    string private _tokenUriParam;
    uint256 private _maxTokensForContract;

    Counters.Counter private _tokenIds;
    
    constructor(
        uint256 priceInBNBWei,
        uint256 priceInTokenWei,
        ERC20 tokenForBuy, 
        string memory tokenUri,
        uint256 maxTokensForContract
        ) ERC721("HS Nala", "NALAHS"){   
            _priceInBNBWei = priceInBNBWei;
            _priceInTokenWei = priceInTokenWei;
            _tokenForBuy = tokenForBuy;
            _tokenUriParam = tokenUri;
            _maxTokensForContract = maxTokensForContract;
    }
    
    /* Acquisto del Token NFT con BNB */
    function buyNftWithBNB() public payable maxNfts(){
        string memory msgError = 'The payment must be greater';
        require((msg.value >= _priceInBNBWei), msgError);

        address from = msg.sender;
        uint256 paymentReceved = msg.value;
        
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenUriParam);
        
        emit redeemNftEvent(newItemId, from, paymentReceved);
    }
    
    /* Acquisto tramite il token */
    function buyNftWithToken() public maxNfts(){
        address from = msg.sender;
        _tokenForBuy.allowance(from,  address(this));
        require(_tokenForBuy.transferFrom(from, address(this), _priceInTokenWei), "Error during payment");
        
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenUriParam);
        
        emit redeemNftEvent(newItemId, from, _priceInTokenWei);
    }

    /* Funzioni Pubbliche */
    function getPrices() public view returns (uint256, uint256){
        return (_priceInBNBWei, _priceInTokenWei);
    }
    
    function getTokenForBuy() public view returns (ERC20, string memory, string memory){
        string memory name = _tokenForBuy.name();
        string memory symbol = _tokenForBuy.symbol();
        return (_tokenForBuy, name, symbol);
    }

    function getTokenUri() public view returns (string memory){
        return _tokenUriParam;
    }

    function getMaxTokens() public view returns (uint256){
        return _maxTokensForContract;
    }

    function getTokensAvailable() public view returns (uint256){
        return _maxTokensForContract.sub(_tokenIds.current());
    }

    /* Funzioni di amministrazione */
    function _transferBNB(address payable _to, uint256 amount) public onlyManager{
        require(address(this).balance >= amount); 
        _to.transfer(amount);
    }
    
    function _changePriceBNB(uint256 newPrice)public onlyManager returns(uint256){
        _priceInBNBWei = newPrice;
        return _priceInBNBWei;
    }

    function _changePriceToken(uint256 newPrice)public onlyManager returns(uint256){
        _priceInTokenWei = newPrice;
        return _priceInTokenWei;
    }

    function _changeTokenForBuy(ERC20 tokenForBuy) public onlyManager returns (ERC20){
        _tokenForBuy = tokenForBuy;
        return _tokenForBuy;
    }

    function _paymentToManager(uint256 amount) public onlyManager {
         require(address(this).balance >= amount); 
         payable(msg.sender).transfer(amount);
    }
    
    function _transferAllTokensContracts(ERC20 _token, address payable _to, uint256 amount) public onlyManager{
        _token.transfer(_to, amount);
    }

    modifier maxNfts() { // permette operazione solo ai managers
        require(_tokenIds.current() < _maxTokensForContract, "reached maximum number of tokens");
        _;
    }

}