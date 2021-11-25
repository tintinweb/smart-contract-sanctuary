// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CelebrateNFT.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract NFTSale is Ownable {
    
    using SafeMath for uint256;
    Celebrate internal _celebrate;
    
    uint256 public cardPrice;
    address payable private _wallet;
    uint256 public nftlimit;
    uint256 public cardsSold;
    
    constructor(uint256 _firstLimit,uint256 _cardPrice,address NFTcontractaddress, address payable wallet) {
        cardPrice = _cardPrice;
        _wallet =wallet;
        cardsSold = 0;
        _celebrate = Celebrate(NFTcontractaddress);
        nftlimit = _firstLimit;
    }
    
    
    function buyCard(address receiver)payable public{
        require( msg.value == cardPrice, "Sale: Insufficient or excessive funds provided" );
        require(receiver != address(0), "Sale: Invalid address");
        require(cardsSold.add(1) <= nftlimit, "Sale limit reached");
        
        _celebrate.mintTo(receiver);
        _forwardFunds(msg.value);
        cardsSold = cardsSold.add(1);
        
    }
    
    function giveAway(address receiver)public onlyOwner{
        _celebrate.mintTo(receiver);
        cardsSold = cardsSold.add(1);
    }
    
    
    function _forwardFunds(uint256 amount) internal {
        _wallet.transfer(amount);
    }
    
    
    function setWallets(address payable wallet)public onlyOwner{
        require(wallet != address(0), "invalid wallet address" );
        
        _wallet = wallet;
    }
    
    function updatePrices(uint256 _cardPrice)public onlyOwner{
        cardPrice = _cardPrice;
    }
    
    function getPrice()public view returns(uint256){
        return cardPrice;
    }
    
    function updateLimit(uint256 limit_)public onlyOwner{
        nftlimit = limit_;
    }

}