pragma solidity ^0.4.11;

contract Grid {
  // The account address with admin privilege to this contract
  // This is also the default owner of all unowned pixels
  address admin;

  // The size in number of pixels of the square grid on each side
  uint16 public size;

  // The default price of unowned pixels
  uint public defaultPrice;

  // The price-fee ratio used in the following formula:
  //   salePrice / feeRatio = fee
  //   payout = salePrice - fee
  // Higher feeRatio equates to lower fee percentage
  uint public feeRatio;

  // The price increment rate used in the following formula:
  //   price = prevPrice + (prevPrice * incrementRate / 100);
  uint public incrementRate;

  struct Pixel {
    // User with permission to modify the pixel. A successful sale of the
    // pixel will result in payouts being credited to the pendingWithdrawal of
    // the User
    address owner;

    // Current listed price of the pixel
    uint price;

    // Current color of the pixel. A valid of 0 is considered transparent and
    // not black. Use 1 for black.
    uint24 color;
  }

  // The state of the pixel grid
  mapping(uint32 => Pixel) pixels;

  // The state of all users who have transacted with this contract
  mapping(address => uint) pendingWithdrawals;

  // An optional message that is shown in some parts of the UI and in the
  // details pane of every owned pixel
  mapping(address => string) messages;

  //============================================================================
  // Events
  //============================================================================

  event PixelTransfer(uint16 row, uint16 col, uint price, address prevOwner, address newOwner);
  event PixelColor(uint16 row, uint16 col, address owner, uint24 color);
  event PixelPrice(uint16 row, uint16 col, address owner, uint price);

  //============================================================================
  // Basic API and helper functions
  //============================================================================

  function Grid(
    uint16 _size,
    uint _defaultPrice,
    uint _feeRatio,
    uint _incrementRate) {
    admin = msg.sender;
    defaultPrice = _defaultPrice;
    feeRatio = _feeRatio;
    size = _size;
    incrementRate = _incrementRate;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  modifier onlyOwner(uint16 row, uint16 col) {
    require(msg.sender == getPixelOwner(row, col));
    _;
  }

  function getKey(uint16 row, uint16 col) constant returns (uint32) {
    require(row < size && col < size);
    return uint32(SafeMath.add(SafeMath.mul(row, size), col));
  }

  function() payable {}

  //============================================================================
  // Admin API
  //============================================================================

  function setAdmin(address _admin) onlyAdmin {
    admin = _admin;
  }

  function setFeeRatio(uint _feeRatio) onlyAdmin {
    feeRatio = _feeRatio;
  }

  function setDefaultPrice(uint _defaultPrice) onlyAdmin {
    defaultPrice = _defaultPrice;
  }

  //============================================================================
  // Public Querying API
  //============================================================================

  function getPixelColor(uint16 row, uint16 col) constant returns (uint24) {
    uint32 key = getKey(row, col);
    return pixels[key].color;
  }

  function getPixelOwner(uint16 row, uint16 col) constant returns (address) {
    uint32 key = getKey(row, col);
    if (pixels[key].owner == 0) {
      return admin;
    }
    return pixels[key].owner;
  }

  function getPixelPrice(uint16 row, uint16 col) constant returns (uint) {
    uint32 key = getKey(row, col);
    if (pixels[key].owner == 0) {
      return defaultPrice;
    }
    return pixels[key].price;
  }

  function getUserMessage(address user) constant returns (string) {
    return messages[user];
  }

  //============================================================================
  // Public Transaction API
  //============================================================================

  function checkPendingWithdrawal() constant returns (uint) {
    return pendingWithdrawals[msg.sender];
  }

  function withdraw() {
    if (pendingWithdrawals[msg.sender] > 0) {
      uint amount = pendingWithdrawals[msg.sender];
      pendingWithdrawals[msg.sender] = 0;
      msg.sender.transfer(amount);
    }
  }

  function buyPixel(uint16 row, uint16 col, uint24 newColor) payable {
    uint balance = pendingWithdrawals[msg.sender];
    // Return instead of letting getKey throw here to correctly refund the
    // transaction by updating the user balance in user.pendingWithdrawal
    if (row >= size || col >= size) {
      pendingWithdrawals[msg.sender] = SafeMath.add(balance, msg.value);
      return;
    }

    uint32 key = getKey(row, col);
    uint price = getPixelPrice(row, col);
    address owner = getPixelOwner(row, col);

    // Return instead of throw here to correctly refund the transaction by
    // updating the user balance in user.pendingWithdrawal
    if (msg.value < price) {
      pendingWithdrawals[msg.sender] = SafeMath.add(balance, msg.value);
      return;
    }

    uint fee = SafeMath.div(msg.value, feeRatio);
    uint payout = SafeMath.sub(msg.value, fee);

    uint adminBalance = pendingWithdrawals[admin];
    pendingWithdrawals[admin] = SafeMath.add(adminBalance, fee);

    uint ownerBalance = pendingWithdrawals[owner];
    pendingWithdrawals[owner] = SafeMath.add(ownerBalance, payout);

    // Increase the price automatically based on the global incrementRate
    uint increase = SafeMath.div(SafeMath.mul(price, incrementRate), 100);
    pixels[key].price = SafeMath.add(price, increase);
    pixels[key].owner = msg.sender;

    PixelTransfer(row, col, price, owner, msg.sender);
    setPixelColor(row, col, newColor);
  }

  //============================================================================
  // Owner Management API
  //============================================================================

  function setPixelColor(uint16 row, uint16 col, uint24 color) onlyOwner(row, col) {
    uint32 key = getKey(row, col);
    if (pixels[key].color != color) {
      pixels[key].color = color;
      PixelColor(row, col, pixels[key].owner, color);
    }
  }

  function setPixelPrice(uint16 row, uint16 col, uint newPrice) onlyOwner(row, col) {
    uint32 key = getKey(row, col);
    // The owner can only lower the price. Price increases are determined by
    // the global incrementRate
    require(pixels[key].price > newPrice);

    pixels[key].price = newPrice;
    PixelPrice(row, col, pixels[key].owner, newPrice);
  }

  //============================================================================
  // User Management API
  //============================================================================

  function setUserMessage(string message) {
    messages[msg.sender] = message;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}