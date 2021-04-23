pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721.sol";

/**
 * @title BDDPixelFactory
 * @dev implments the pixel nft logic for BillionDollarDapp.com
 */
contract BDDPixelFactory is ERC721, Ownable {

  // Global Pixel Info
  uint8 public rentalCommissionPercent;     // 0-50
  uint8 public maxAltTextLength;            // 0-255
  uint16 public maxTotalSupply;              // 10000
  uint16 public currentTokenId;              //
  uint16 public minimumRentalTimeUnit;       // ~1 hr = 3600 seconds (uint16 up to 65535)
  uint16 public maximumRentalTimeUnits;       // ~1 mo = 1hr * 24hr / day * 30 days / mo = 720
  uint256 public maximumCreationPrice;        // The price of the last pixel.  Price of pixel is _pixelId/totalPixels * maximumCreationPrice
  uint256 public rentalFeeForMinimumTimeUnit; // ~$10 USD?

  struct Pixel {
    string color;         // the color of the pixel
    string ownerAlt;      // owner alt text.
    string rentalColor;   // show this color up until rental period ends.
    string rentalAlt;     // renter alt text.
    uint32 rentTimeEnd;  // the time when the pixel can change again
    uint256 totalRentalRevenue;
  }

  Pixel[] public pixels;

  //mapping (uint256 => Pixel) public pixels;
  //mapping (uint256 => address) public pixelToOwner;
  //mapping (address => uint) ownerPixelCount;

  // Events
  event PixelCreated(address indexed pixelOwner, uint256 indexed pixelId, uint256 creationPricePaid);
  event PixelOwnerChangedColor(address indexed pixelOwner, uint256 indexed pixelId, string newColor);
  event PixelOwnerChangedAlt(address indexed pixelOwner, uint256 indexed pixelId, string newAlt);
  event PixelRented(address indexed pixelRenter, uint256 indexed pixelId, uint256 endTime, string rentalColor, string rentalAlt);

  // Modifiers
  modifier onlyOwnerOfPixel(uint16 _pixelId) {
    require(msg.sender == ownerOf(_pixelId), "Not authorized. Must be the owner of the BDDPixel NFT.");
    _;
  }

  // Constructor
  constructor() ERC721("BillionDollarDapp Pixel", "BDDPixel") {
    maxTotalSupply = 10000; // 100*100 = 10000
    currentTokenId = 0;
    minimumRentalTimeUnit = 3600; // seconds; 60 = 1min; 600 = 10min; 3600 = 1hr;
    maximumRentalTimeUnits = 720; // max number of minimumRentalTimeUnit to allow (e.g., 720 hr ~ 1 mo)
    maximumCreationPrice = 1 ether; // The maximum price paid to contract owner to mint a pixel.  Formula: maximumCreationPrice * pixelId / totalPixels;
    rentalFeeForMinimumTimeUnit = 0.001 ether; // $2 USD?
    rentalCommissionPercent = 33; // The amount of a rental sent to the contract owner.
    maxAltTextLength = 50; // Maximum of characters allowed for alt text.
  }

  function _baseURI() internal view override returns (string memory) {
    return 'http://nft.billiondollardapp.com/';
  }

  function getTokenIdForNextAvailablePixel() public view returns (uint16) {
    require((currentTokenId + 1 <= maxTotalSupply), "No more pixels are available for creation.");
    return (currentTokenId + 1);
  }

  function getCreationPriceForNextAvailablePixel() public view returns (uint256) {
    require((currentTokenId + 1 <= maxTotalSupply), "No more pixels are available for creation.");
    return (maximumCreationPrice * (currentTokenId) / maxTotalSupply);
  }

  function getAllPixels() public view returns(Pixel[] memory) {
      return pixels;
  }

  // MINT TOKEN FUNCTIONS
  //function anyoneCreatePixel(string memory _color) external payable returns (uint256) {
  function anyoneCreatePixel(string memory _color) external payable {
    require(msg.value >= getCreationPriceForNextAvailablePixel(), "Creation price not sufficient.");
    require(bytes(_color).length == 7, "Color is wrong length; it must be a hex code in the format #RRGGBB.");
    require(currentTokenId < maxTotalSupply, "No more Pixels are available to mint.");

    currentTokenId++;
    uint256 _newPixelId = currentTokenId;
    _mint(msg.sender, _newPixelId);

    pixels.push(Pixel(_color, "", "", "", 0, 0));

    //pixelToOwner[currentTokenId] = msg.sender;
    //ownerPixelCount[msg.sender]++;

    // TODO : Figure out URI and MetaData?
    //_setTokenURI();

    //event PixelCreated(address indexed pixelOwner, uint256 indexed pixelId, uint256 creationPricePaid);
    emit PixelCreated(msg.sender, currentTokenId, msg.value);
    //return newPixelId;
  }

  function pixelOwnerUpdatePixelColor(uint16 _pixelId, string calldata _newColor) external onlyOwnerOfPixel(_pixelId) {
    require(_pixelId <= currentTokenId, "That pixel does not exist"); // require valid _pixelId
    require(bytes(_newColor).length == 7, "Color is wrong length; it must be a hex code in the format #RRGGBB."); // require color length be right for "#rrggbb"

    // NOTE: pixel array is zero index so must subtract one from the pixelId to get the correct value.
    pixels[_pixelId - 1].color = _newColor;

    emit PixelOwnerChangedColor(msg.sender, _pixelId, _newColor);
  }

  function pixelOwnerUpdatePixelAlt(uint16 _pixelId, string calldata _newAlt) external onlyOwnerOfPixel(_pixelId) {
    require(_pixelId <= currentTokenId, "That pixel does not exist"); // require valid _pixelId
    require(bytes(_newAlt).length <= maxAltTextLength, "Alt is wrong length. Must be <= maxAltTextLength."); // require og tweet sized alt text

    // NOTE: pixel array is zero index so must subtract one from the pixelId to get the correct value.
    pixels[_pixelId - 1].ownerAlt = _newAlt;

    emit PixelOwnerChangedAlt(msg.sender, _pixelId, _newAlt);
  }

  // ===== MINT TOKEN FUNCTIONS =====
  function contractOwnerUpdateMaximumCreationPrice(uint256 _newMaximumCreationPrice) external onlyOwner() {
    maximumCreationPrice = _newMaximumCreationPrice;
  }

  // ===== RENT TOKEN FUNCTIONS =====

  function contractOwnerUpdateMaxTotalSupply(uint16 _newMaxTotalSupply) external onlyOwner() {
    require(_newMaxTotalSupply <= 10000, "Can not set maxTotalSupply to a value higher than 10000.");
    require(_newMaxTotalSupply >= currentTokenId, "Can not set maxTotalSupply to a value lower than currentTokenId.");
    maxTotalSupply = _newMaxTotalSupply;
  }

  function contractOwnerUpdateMinimumRentalTimeUnit(uint16 _newMinimumTimeUnit) external onlyOwner() {
    minimumRentalTimeUnit = _newMinimumTimeUnit; // seconds
  }

  function contractOwnerUpdateMaximumRentalTimeUnits(uint16 _newMaximumRentalTimeUnits) external onlyOwner() {
    maximumRentalTimeUnits = _newMaximumRentalTimeUnits;
  }

  function contractOwnerUpdateRentalPrice(uint256 _newRentalFeeForMinimumTimeUnit) external onlyOwner() {
    rentalFeeForMinimumTimeUnit = _newRentalFeeForMinimumTimeUnit;
  }

  function contractOwnerUpdateAltTextLength(uint8 _newAltTextLength) external onlyOwner() {
    require(_newAltTextLength >= 0, "Alt text length must be greater than or equal to 0.");
    require(_newAltTextLength <= 255, "Alt text length must be less than or equal to 255.");
    maxAltTextLength = _newAltTextLength;
  }

  function contractOwnerUpdateRentalCommissionPercent(uint8 _newRentalCommissionPercent) external onlyOwner() {
    require(_newRentalCommissionPercent >= 0, "Commission must be greater than or equal to 0.");
    require(_newRentalCommissionPercent <= 50, "Commission must be less than or equal to 50.");
    rentalCommissionPercent = _newRentalCommissionPercent;
  }

  function getCurrentRentalPriceForTimeUnits(uint16 _desiredTimeUnits) public view returns (uint256) {
    require(_desiredTimeUnits <= maximumRentalTimeUnits, "Maximum time units is maximumRentalTimeUnits.");
    return (rentalFeeForMinimumTimeUnit * _desiredTimeUnits);
  }

  function _pixelSetRentTimeEnd(Pixel storage _pixel, uint32 _timeUnits) internal {
    require(_timeUnits <= maximumRentalTimeUnits, "Maximum time units is maximumRentalTimeUnits.");
    _pixel.rentTimeEnd = uint32(block.timestamp + (_timeUnits * minimumRentalTimeUnit));
  }

  function _pixelIsAvailableToRent(Pixel storage _pixel) internal view returns (bool) {
      return (_pixel.rentTimeEnd <= block.timestamp);
  }

  function isPixelAvailableToRent(uint16 _pixelId) external view returns (bool) {
      Pixel storage _pixel = pixels[_pixelId - 1];
      return (_pixel.rentTimeEnd <= block.timestamp);
  }

  // TODO: Rent pixel function
  function anyoneRentPixel(uint16 _pixelId, uint16 _timeUnits, string calldata _rentalColor, string calldata _rentalAlt) external payable {
    require(_pixelId <= currentTokenId, "That pixel does not exist."); // require valid _pixelId
    require(bytes(_rentalColor).length == 7, "Color is wrong length; it must be a hex code in the format #RRGGBB."); // require color length be right for "#rrggbb"
    require(bytes(_rentalAlt).length <= maxAltTextLength, "Alt is wrong length. Must be <= maxAltTextLength."); // require color length be right for "#rrggbb"
    require(_timeUnits > 0, "Time units must be at least 1.");
    require(_timeUnits <= maximumRentalTimeUnits, "Maximum time units is maximumRentalTimeUnits");

    // require that the current time > the current pixelRentTimeEnd
    // require that the payment be sufficient.
    require(msg.value >= getCurrentRentalPriceForTimeUnits(_timeUnits));

    Pixel storage desiredPixel = pixels[_pixelId - 1];
    require(_pixelIsAvailableToRent(desiredPixel));
    desiredPixel.rentalColor = _rentalColor;
    desiredPixel.rentalAlt = _rentalAlt;
    _pixelSetRentTimeEnd(desiredPixel, _timeUnits);
    desiredPixel.totalRentalRevenue += msg.value;

    // send money to pixel owner minus commission
    uint256 _contractPayment = msg.value * rentalCommissionPercent / 100;
    uint256 _pixelOwnerPayment = msg.value - _contractPayment;
    payable(address(ownerOf(_pixelId))).transfer(_pixelOwnerPayment);

    //event PixelRented(address indexed pixelRenter, uint256 indexed pixelId, uint256 endTime, string rentalColor);
    emit PixelRented(msg.sender, _pixelId, desiredPixel.rentTimeEnd, _rentalColor, _rentalAlt);
  }

  // FINANCIAL
  function contractOwnerWithdraw() external onlyOwner() {
    address payable _owner = payable(this.owner());
    _owner.transfer(address(this).balance);
  }

/*
  function contractOwnerPayDividendToPixelOwners(uint256 _profit) external onlyOwner() {
    // make sure we have enough money
    require(_profit <= address(this).balance);
    // money to distribute
    for (uint16 _pixelId = 1; _pixelId <= currentTokenId; _pixelId++) {  //for loop example
         // get owner of pixel Id
         address payable _pixelOwner = payable(ownerOf(_pixelId));
         // transfer owner 1/currentTokenId of balance
         _pixelOwner.transfer(_profit / currentTokenId);
    }
  }

  function anyoneTipPixelOwners(string calldata _message) external payable {
    // make sure we have enough money to split up
    require(msg.value >= currentTokenId, "Must tip at least currentTokenId Wei.");
    // require the message to be sized to maxAltTextLength
    require(bytes(_message).length <= maxAltTextLength, "Message too long. Must be <= maxAltTextLength.");

    // money to distribute
    for (uint16 _pixelId = 1; _pixelId <= currentTokenId; _pixelId++) {  //for loop example
         // get owner of pixel Id
         address payable _pixelOwner = payable(ownerOf(_pixelId));
         // transfer owner 1/currentTokenId of balance
         _pixelOwner.transfer(msg.value / currentTokenId);
    }

    emit PixelOwnersTipped(msg.sender, msg.value, _message);
  }
*/
  // END OF LIFE
  function contractOwnerDestroyContract() external onlyOwner() {
    address payable _owner = payable(this.owner());
    selfdestruct(_owner);
  }
}