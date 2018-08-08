pragma solidity ^0.4.19;

contract Pixereum {


    struct Pixel {
        address owner;
        string message;
        uint256 price;
        bool isSale;
    }



    /**************************************************************************
    * public variables
    ***************************************************************************/
    uint24[10000] public colors;
    bool public isMessageEnabled;



    /**************************************************************************
    * private variables
    ***************************************************************************/
    mapping (uint16 => Pixel) private pixels;



    /**************************************************************************
    * public constants
    ***************************************************************************/
    uint16 public constant numberOfPixels = 10000;
    uint16 public constant width = 100;
    uint256 public constant feeRate = 100;



    /**************************************************************************
    * private constants
    ***************************************************************************/
    address private constant owner = 0xF1fA618D4661A8E20f665BE3BD46CAad828B5837;
    address private constant fundWallet = 0x4F6896AF8C26D1a3C464a4A03705FB78fA2aDB86;
    uint256 private constant defaultWeiPrice = 10000000000000000;   // 0.01 eth



    /**************************************************************************
    * modifiers
    ***************************************************************************/

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPixelOwner(uint16 pixelNumber) {
        require(msg.sender == pixels[pixelNumber].owner);
        _;
    }

    modifier messageEnabled {
        require(isMessageEnabled == true);
        _;
    }



    /**************************************************************************
    * public methods
    ***************************************************************************/

    // constructor
    function Pixereum() public {
        isMessageEnabled = true;
    }



    /**************************************************************************
    * public methods
    ***************************************************************************/

    function getPixel(uint16 _pixelNumber)
        constant
        public
        returns(address, string, uint256, bool) 
    {
        Pixel memory pixel;
        if (pixels[_pixelNumber].owner == 0) {
            pixel = Pixel(fundWallet, "", defaultWeiPrice, true); 
        } else {
            pixel = pixels[_pixelNumber];
        }
        return (pixel.owner, pixel.message, pixel.price, pixel.isSale);
    }
    
    
    function getColors() constant public returns(uint24[10000])  {
        return colors;
    }


    // called when ether is sent to this contract
    function ()
        payable
        public 
    {
        // check if data format is valid
        // bytes[0]=x, bytes[1]=y, bytes[2-4]=color
        require(msg.data.length == 5);

        uint16 pixelNumber = getPixelNumber(msg.data[0], msg.data[1]);
        uint24 color = getColor(msg.data[2], msg.data[3], msg.data[4]);
        buyPixel(msg.sender, pixelNumber, color, "");
    }


    function buyPixel(address beneficiary, uint16 _pixelNumber, uint24 _color, string _message)
        payable
        public 
    {
        require(_pixelNumber < numberOfPixels);
        require(beneficiary != address(0));
        require(msg.value != 0);
        
        // get current pixel info
        address currentOwner;
        uint256 currentPrice;
        bool currentSaleState;
        (currentOwner, , currentPrice, currentSaleState) = getPixel(_pixelNumber);
        
        // check if a pixel is for sale
        require(currentSaleState == true);

        // check if a received Ether is higher than current price
        require(currentPrice <= msg.value);

        // calculate fee
        uint fee = msg.value / feeRate;

        // transfer received amount to current owner
        currentOwner.transfer(msg.value - fee);

        // transfer fee to fundWallet
        fundWallet.transfer(fee);

        // update pixel
        pixels[_pixelNumber] = Pixel(beneficiary, _message, currentPrice, false);
        
        // update color
        colors[_pixelNumber] = _color;
    }


    function setOwner(uint16 _pixelNumber, address _owner) 
        public
        onlyPixelOwner(_pixelNumber)
    {
        require(_owner != address(0));
        pixels[_pixelNumber].owner = _owner;
    }


    function setColor(uint16 _pixelNumber, uint24 _color) 
        public
        onlyPixelOwner(_pixelNumber)
    {
        colors[_pixelNumber] = _color;
    }


    function setMessage(uint16 _pixelNumber, string _message)
        public
        messageEnabled
        onlyPixelOwner(_pixelNumber)
    {
        pixels[_pixelNumber].message = _message;
    }


    function setPrice(uint16 _pixelNumber, uint256 _weiAmount) 
        public
        onlyPixelOwner(_pixelNumber)
    {
        pixels[_pixelNumber].price = _weiAmount;
    }


    function setSaleState(uint16 _pixelNumber, bool _isSale)
        public
        onlyPixelOwner(_pixelNumber)
    {
        pixels[_pixelNumber].isSale = _isSale;
    }



    /**************************************************************************
    * internal methods
    ***************************************************************************/

    function getPixelNumber(byte _x, byte _y)
        internal pure
        returns(uint16) 
    {
        return uint16(_x) + uint16(_y) * width;
    }


    function getColor(byte _red, byte _green, byte _blue)
        internal pure
        returns(uint24) 
    {
        return uint24(_red)*65536 + uint24(_green)*256 + uint24(_blue);
    }



    /**************************************************************************
    * methods for contract owner
    ***************************************************************************/

    // for emergency purpose
    function deleteMessage(uint16 _pixelNumber)
        onlyOwner
        public
    {
        pixels[_pixelNumber].message = "";
    }


    // for emergency purpose
    function setMessageStatus(bool _isMesssageEnabled)
        onlyOwner
        public
    {
        isMessageEnabled = _isMesssageEnabled;
    }

}