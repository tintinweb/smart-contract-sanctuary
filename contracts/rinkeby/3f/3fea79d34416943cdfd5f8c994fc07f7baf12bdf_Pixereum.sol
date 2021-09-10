/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.4.19;
  
contract Pixereum {
    
    struct Pixel {
        address owner;
        string message;
        uint256 price;
        bool isSale;
    }
    mapping (uint16 => Pixel) private pixels;
    uint24[10000] public colors;
    address private constant fundWallet = 0xBBf545beE1E4C8A51875a6c92610cc5b898d2107;
    uint public constant numberOfPixels = 10000;
    uint256 public constant feeRate = 100;                          // 1%
    uint256 private constant defaultWeiPrice = 10000000000000000;   // 0.01 eth
    
    // constructor
    function Pixereum() public {
    }
    
    // get a pixel number from (x,y)
    function getPixelNumber(byte _x, byte _y) internal pure returns(uint16) {
        return uint16(_x) + uint16(_y)*100;
    }
    
    // get a color from bytes
    function getColor(byte _red, byte _green, byte _blue) internal pure returns(uint24) {
        return uint24(_red)*65536 + uint24(_green)*256 + uint24(_blue);
    }
    
    // set a new price
    function setPrice(byte _x, byte _y, uint256 _weiAmount) public {
        uint16 pixelNumber = getPixelNumber(_x, _y);
        if (pixels[pixelNumber].owner == msg.sender) {
            pixels[pixelNumber].price = _weiAmount;
        }
    }
    
    // set a new sale state
    function setSaleState(byte _x, byte _y, bool _isSale) public {
        uint16 pixelNumber = getPixelNumber(_x, _y);
        if (pixels[pixelNumber].owner == msg.sender) {
            pixels[pixelNumber].isSale = _isSale;
        }
    }
    
    // set new color
    function setColor(byte _x, byte _y, byte _red, byte _green, byte _blue) public {
        uint16 pixelNumber = getPixelNumber(_x, _y);
        if (pixels[pixelNumber].owner == msg.sender) {
            colors[pixelNumber] = getColor(_red, _green, _blue);
        }
    }
    
    function setMessage(byte _x, byte _y, string _message) public {
        uint16 pixelNumber = getPixelNumber(_x, _y);
        if (pixels[pixelNumber].owner == msg.sender) {
            pixels[pixelNumber].message = _message;
        }
    }
    
    // used by web interface
    function getColors() constant public returns(uint24[10000])  {
        return colors;
    }
    
    function getPixel(uint16 _at) constant public returns(address, string, uint256, bool) {
        Pixel memory pixel;
         if (pixels[_at].owner == 0) {
             pixel = Pixel(fundWallet, "", defaultWeiPrice, true); 
         } else {
             pixel = pixels[_at];
         }
         return (pixel.owner, pixel.message, pixel.price, pixel.isSale);
     }
    
    // called when ether is sent to this contract
    function () payable public {
        
        // check if data format is valid
        // byte0=x, byte1=y, byte2-4=color
        if (msg.data.length != 5) revert();
        // get a pixel number from received data
        uint16 pixelNumber = getPixelNumber(msg.data[0], msg.data[1]);
        
        // check if number of pixels is valid
        if(pixelNumber >= numberOfPixels) revert();
        
        // get current pixel info
        address currentOwner;
        uint256 currentPrice;
        bool currentSaleState;
        (currentOwner, , currentPrice, currentSaleState) = getPixel(pixelNumber);
        
        // check if the pixel is for sale
        if(currentSaleState == false) revert();
        
        // check if a received amount is higher than price
        if(currentPrice > msg.value) revert();
        
        // calculate fee
        uint fee = msg.value / 100;
        
        // update pixel
        pixels[pixelNumber] = Pixel(msg.sender, "", currentPrice, false);
        
        // calculate pixel color from received data
        uint24 color = getColor(msg.data[2], msg.data[3], msg.data[4]);
        colors[pixelNumber] = color;
        
        // transfer received amount to oldOwner
        currentOwner.transfer(msg.value - fee);
        
        // transfer fee to fundWallet
        fundWallet.transfer(fee);
    }
    
}