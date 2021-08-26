/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity ^0.4.2;
contract EtherPixel {
    
    struct Pixel {
        address owner;
        bool currentlyForSale;
        uint price;
        uint timesSold;
    }
    
    mapping (uint => Pixel) public Pixels;
    
    mapping (address => uint[]) public PixelOwners;

    uint public latestNewPixelForSale;
    
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function EtherPixel() {
        
        latestNewPixelForSale = 6;
        
        Pixels[0].owner = msg.sender;
        Pixels[0].currentlyForSale = true;
        Pixels[0].price = 250000000000000000;
        Pixels[0].timesSold = 1;
        PixelOwners[msg.sender].push(0);
        
        Pixels[1].owner = msg.sender;
        Pixels[1].currentlyForSale = true;
        Pixels[1].price = 250000000000000000;
        Pixels[1].timesSold = 1;
        PixelOwners[msg.sender].push(1);
        
        Pixels[2].owner = msg.sender;
        Pixels[2].currentlyForSale = true;
        Pixels[2].price = 250000000000000000;
        Pixels[2].timesSold = 1;
        PixelOwners[msg.sender].push(2);
        
        Pixels[3].owner = msg.sender;
        Pixels[3].currentlyForSale = true;
        Pixels[3].price = 250000000000000000;
        Pixels[3].timesSold = 1;
        PixelOwners[msg.sender].push(3);
        
        Pixels[4].owner = msg.sender;
        Pixels[4].currentlyForSale = true;
        Pixels[4].price = 250000000000000000;
        Pixels[4].timesSold = 1;
        PixelOwners[msg.sender].push(4);
        
        Pixels[5].owner = msg.sender;
        Pixels[5].currentlyForSale = true;
        Pixels[5].price = 250000000000000000;
        Pixels[5].timesSold = 1;
        PixelOwners[msg.sender].push(5);
        
        Pixels[6].currentlyForSale = true;
        Pixels[6].price = 250000000000000000;
        
        owner = msg.sender;
    }
    
    function getPixelInfo (uint PixelNumber) returns (address, bool, uint, uint) {
        return (Pixels[PixelNumber].owner, Pixels[PixelNumber].currentlyForSale, Pixels[PixelNumber].price, Pixels[PixelNumber].timesSold);
    }
    
    function PixelOwningHistory (address _address) returns (uint[]) {
        return PixelOwners[_address];
    }
    
    function buyPixel (uint PixelNumber) payable {
        require(Pixels[PixelNumber].currentlyForSale == true);
        require(msg.value == Pixels[PixelNumber].price);
        Pixels[PixelNumber].currentlyForSale = false;
        Pixels[PixelNumber].timesSold++;
        if (PixelNumber != latestNewPixelForSale) {
            Pixels[PixelNumber].owner.transfer(Pixels[PixelNumber].price);
        }
        Pixels[PixelNumber].owner = msg.sender;
        PixelOwners[msg.sender].push(PixelNumber);
        if (PixelNumber == latestNewPixelForSale) {
            if (PixelNumber != 99) {
                latestNewPixelForSale++;
                Pixels[latestNewPixelForSale].price = 250000000000000000;
                Pixels[latestNewPixelForSale].currentlyForSale = true;
            }
        }
    }
    
    function sellPixel (uint PixelNumber, uint price) {
        require(msg.sender == Pixels[PixelNumber].owner);
        require(price > 0);
        Pixels[PixelNumber].price = price;
        Pixels[PixelNumber].currentlyForSale = true;
    }
    
    function dontSellPixel (uint PixelNumber) {
        require(msg.sender == Pixels[PixelNumber].owner);
        Pixels[PixelNumber].currentlyForSale = false;
    }
    
    function giftPixel (uint PixelNumber, address receiver) {
        require(msg.sender == Pixels[PixelNumber].owner);
        Pixels[PixelNumber].owner = receiver;
        PixelOwners[receiver].push(PixelNumber);
    }
    
    function() payable {
        
    }
    
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
}