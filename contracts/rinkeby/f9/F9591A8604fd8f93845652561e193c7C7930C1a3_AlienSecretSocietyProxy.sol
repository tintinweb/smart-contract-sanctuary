// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";

contract IAlienSecretSociety {
    // Only owner
    function mintByOwner(address to, uint256 amount) public {}
    function transferOwnership(address newOwner) public {}
    // Supply
    function MAX_SUPPLY() public view returns (uint256) {}
    function totalSupply() public view returns (uint256) {}
    // Dutch Auction
    function dutchAuctionPurchased(address) public view returns (uint256) {}
    function dutchAuctionLimitPerWallet() public view returns (uint256) {}
}

contract AlienSecretSocietyProxy is Ownable {
    using SafeMath for uint256;
    IAlienSecretSociety public ASS;
    uint256 public price;
    bool public saleEnabled;
    mapping(address => uint) public proxyDutchAuctionPurchased;

    constructor(address addressASS) {
        ASS = IAlienSecretSociety(addressASS);
        price = 150000000000000000;
        saleEnabled = false;
    }

    function totalPurchasedAmount(address address_) public view returns (uint256) {
        return ASS.dutchAuctionPurchased(address_).add(proxyDutchAuctionPurchased[address_]);
    }

    function buyNow(uint256 amount) external payable {
        require(amount >= 1 , "cannot mint 0");
        require(saleEnabled == true, "auction is closed");
        require(ASS.MAX_SUPPLY() >= ASS.totalSupply().add(amount), "cannot mint token. maxSupply was reached");

        // Require msg.sender connot mint more than limit per wallet.
        uint256 purchasedAmount = totalPurchasedAmount(msg.sender);

        require(purchasedAmount.add(amount) <= ASS.dutchAuctionLimitPerWallet(), "wallet limit reached");

        // Calculate total price based on current Dutchprice.
        uint256 totalPrice = price.mul(amount);

        require(totalPrice <= msg.value, "not enough ETH sent");
        
        proxyDutchAuctionPurchased[msg.sender] = proxyDutchAuctionPurchased[msg.sender].add(amount);
    
        ASS.mintByOwner(msg.sender, amount);
    }

    // Owner protected methods.

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function setSaleEnabled(bool value) public onlyOwner {
        saleEnabled = value;
    }

    function setASSAddress(address addressASS) public onlyOwner {
        ASS = IAlienSecretSociety(addressASS);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function returnOwnershipOfASS() public onlyOwner {
        ASS.transferOwnership(msg.sender);
    }

}