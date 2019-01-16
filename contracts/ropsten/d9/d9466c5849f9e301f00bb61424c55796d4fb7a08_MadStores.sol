pragma solidity ^0.5.0;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    constructor() public {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


// Token standard API
// https://github.com/ethereum/EIPs/issues/20

contract iERC20Token {
  function balanceOf( address who ) public view returns (uint value);
  function allowance( address owner, address spender ) public view returns (uint remaining);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);

  //these are implimented via automatic getters
  //function name() public view returns (string _name);
  //function symbol() public view returns (string _symbol);
  //function totalSupply() public view returns (uint256 _totalSupply);

  //but not this, cuz we need to access this fcn in the dai contract
  function decimals() public view returns (uint8 _decimals);
}

// -------------------------------------------------------------------------------------------------------
//  interface to message transport
// -------------------------------------------------------------------------------------------------------
contract MessageTransport {
  function getFee(address _fromAddr, address _toAddr) public view returns(uint256 _fee);
  function sendMessage(address _fromAddr, address _toAddr, uint attachmentIdx, uint _ref, bytes memory _message) public payable returns (uint _messageId);
}

// -------------------------------------------------------------------------------------------------------
//  interface to MADEscrow
// -------------------------------------------------------------------------------------------------------
contract MadEscrow is iERC20Token {
  function createEscrow(uint256 _productID, uint256 _XactId, uint256 _price, address _vendorAddr, address _customerAddr) public returns (uint256 _escrowID);
  function verifyEscrow(uint256 _escrowID, address _vendorAddr, address _customerAddr) public view returns (uint256 _productID);
  function verifyEscrowVendor(uint256 _escrowID, address _vendorAddr) public view returns (uint256 _productID, address _customerAddr);
  function verifyEscrowCustomer(uint256 _escrowID, address _customerAddr) public view returns (uint256 _productID, address _vendorAddr);
  function modifyEscrowPrice(uint256 _escrowID, uint256 _XactId, uint256 _surcharge) public;
  function cancelEscrow(uint256 _escrowID, uint256 _XactId) public;
  function approveEscrow(uint256 _escrowID, uint256 _XactId) public;
  function releaseEscrow(uint256 _escrowID, uint256 _XactId) public;
  function burnEscrow(uint256 _escrowID, uint256 _XactId) public payable;
}


// -------------------------------------------------------------------------------------------------------
//  MadStores Contract
// -------------------------------------------------------------------------------------------------------
contract MadStores is SafeMath {

  // -----------------------------------------------------------------------------------------------------
  // events
  // -----------------------------------------------------------------------------------------------------
  event StatEvent(string message);
  event RegisterVendorEvent(address indexed _vendorAddr, bytes name, bytes desc, bytes image);
  event RegisterProductEvent(uint256 indexed _productID, bytes name, bytes desc, bytes image);
  event PurchaseDepositEvent(address indexed _vendorAddr, address customerAddr, uint256 _escrowID, uint256 _productID, uint256 _surcharge, uint256 _msgId);
  event PurchaseCancelEvent(address indexed _vendorAddr, address indexed customerAddr, uint256 _escrowID, uint256 _productID, uint256 _msgId);
  event PurchaseApproveEvent(address indexed _vendorAddr, address indexed customerAddr, uint256 _escrowID, uint256 _productID, uint256 _msgId);
  event PurchaseRejectEvent(address indexed _vendorAddr, address customerAddr, uint256 _escrowID, uint256 _productID, uint256 _msgId);
  event DeliveryApproveEvent(address indexed _vendorAddr, address indexed customerAddr, uint256 _escrowID, uint256 _productID, uint256 _msgId);
  event DeliveryRejectEvent(address indexed _vendorAddr, address indexed customerAddr, uint256 _escrowID, uint256 _productID, uint256 _msgId);


  // -----------------------------------------------------------------------------------------------------
  // Product structure
  // -----------------------------------------------------------------------------------------------------
  struct Product {
    uint256 price;
    uint256 quantity;
    uint256 category;
    uint256 categoryProductIdx;
    uint256 region;
    uint256 regionProductIdx;
    address vendorAddr;

  }

  // -----------------------------------------------------------------------------------------------------
  // Vendor Account structure
  // for keeping track of vendor reputation
  // -----------------------------------------------------------------------------------------------------
  struct VendorAccount {
    uint256 deliveriesApproved;
    uint256 deliveriesRejected;
    uint256 region;
    uint256 ratingSum;
    bool activeFlag;
  }

  // -----------------------------------------------------------------------------------------------------
  // data storage
  // -----------------------------------------------------------------------------------------------------
  bool public isLocked;
  address payable public owner;
  MadEscrow madEscrow;
  MessageTransport messageTransport;
  uint256 public productCount;
  //productID to product
  mapping (uint256 => Product) public products;
  //vendorProductIdx to productID
  mapping (address => uint256) public vendorProductCounts;
  mapping (address => mapping(uint256 => uint256)) public vendorProducts;
  //topLevelRegion ProductIdx to productID
  mapping (uint8 => uint256) public regionProductCounts;
  mapping (uint256 => mapping(uint256 => uint256)) public regionProducts;
  //topLevelCategory ProductIdx to productID
  mapping (uint8 => uint256) public categoryProductCounts;
  mapping (uint8 => mapping(uint256 => uint256)) public categoryProducts;
  mapping (address => VendorAccount) public vendorAccounts;


  // -----------------------------------------------------------------------------------------------------
  // modifiers
  // -----------------------------------------------------------------------------------------------------
  modifier ownerOnly {
    require(msg.sender == owner, "owner only");
    _;
  }
  modifier unlockedOnly {
    require(!isLocked, "unlocked only");
    _;
  }


  // -----------------------------------------------------------------------------------------------------
  //  constructor and tune
  // -----------------------------------------------------------------------------------------------------
  constructor(address _messageTransport, address _madEscrow) public {
    owner = msg.sender;
    messageTransport = MessageTransport(_messageTransport);
    madEscrow = MadEscrow(_madEscrow);
  }
  //for debug only...
  function setPartners(address _messageTransport, address _madEscrow) public unlockedOnly ownerOnly {
    messageTransport = MessageTransport(_messageTransport);
    madEscrow = MadEscrow(_madEscrow);
  }
  function lock() public ownerOnly {
    isLocked = true;
  }
  //default payable function. refuse.
  function () external payable {
    revert();
  }


  // -----------------------------------------------------------------------------------------------------
  // see if a product matches search criteria
  // category & region are semi hierarchical. the top 8 bits are interpreted as a number specifiying the
  // top-level-category or top-level-region. if specified, then these must match exactly. the lower 248
  // bits are a bitmask of sub-categories or sub-regions. if specified then we only look for some overlap
  // between the product bitmap and the search parameter.
  // -----------------------------------------------------------------------------------------------------
  function isCertainProduct(uint256 _productID, address _vendorAddr, uint256 _category,
                            uint256 _region, uint256 _maxPrice, bool _onlyAvailable) internal view returns(bool) {
    Product storage _product = products[_productID];
    if (_onlyAvailable) {
      uint256 _minVendorBond = safeMul(_product.price, 50) / 100;
      uint256 _vendorBalance = madEscrow.balanceOf(_product.vendorAddr);
      if (_product.quantity == 0 || _product.price == 0 || _vendorBalance < _minVendorBond)
        return(false);
    }
    uint8 _tlc = uint8(_category >> 248);
    uint256 _llcBits = _category & ((2 ** 248) - 1);
    uint8 _tlr = uint8(_region >> 248);
    uint256 _llrBits = _region & ((2 ** 248) - 1);
    uint8 _productTlc = uint8(_product.category >> 248);
    uint256 _productLlcBits = _product.category & ((2 ** 248) - 1);
    uint8 _productTlr = uint8(_product.region >> 248);
    uint256 _productLlrBits = _product.region & ((2 ** 248) - 1);
    //note that productLlrBits == 0 => all sub-regions
    if ((_vendorAddr     == address(0) ||  _product.vendorAddr                == _vendorAddr) &&
        (_tlc            == 0          ||  _productTlc                        == _tlc       ) &&
        (_llcBits        == 0          || (_productLlcBits & _llcBits)        != 0          ) &&
        (_tlr            == 0          ||  _productTlr                        == _tlr       ) &&
        (_llrBits        == 0          ||
         _productLlrBits == 0          || (_productLlrBits & _llrBits)        != 0          ) &&
        (_maxPrice       == 0          ||  _product.price                     <= _maxPrice  ) ) {
      return(true);
    }
    return(false);
  }


  // _maxProducts >= 1
  // note that array will always have _maxResults entries. ignore productID = 0
  // this is a general purpose get-products fcn. it&#39;s main use will be when not looking up products by vendor address, category, or region.
  // if you&#39;re performing a search based on any of those parameters then it will be more efficient to call the most specific variant: getVendorProducts,
  // getCategoryProducts, or getRegionProducts. if searching based on 2 or more parameters then compare vendorProductCounts[_vendorAddr] to
  // categoryProductCounts[_tlc], to regionProductCounts[_tlr], and call the function that corresponds to the smallest number of products.
  //
  function getCertainProducts(address _vendorAddr, uint256 _category, uint256 _region, uint256 _maxPrice,
                              uint256 _productStartIdx, uint256 _maxResults, bool _onlyAvailable) public view returns(uint256 _idx, uint256[] memory _productIDs) {
    uint _count = 0;
    _productIDs = new uint256[](_maxResults);
    //note: first productID is 1
    uint _productID = _productStartIdx;
    for ( ; _productID <= productCount; ++_productID) {
      if (_productID != 0 && isCertainProduct(_productID, _vendorAddr, _category, _region, _maxPrice, _onlyAvailable)) {
        _productIDs[_count] = _productID;
        if (++_count >= _maxResults)
          break;
      }
    }
    _idx = _productID;
  }

  // _maxResults >= 1
  // _vendorAddr != 0
  // note that array will always have _maxResults entries. ignore productID = 0
  // if category is specified, then top-level-category (top 8 bits) must match product tlc exactly, whereas low-level-category bits must have
  // any overlap with product llc bits.
  //
  function getVendorProducts(address _vendorAddr, uint256 _category, uint256 _region, uint256 _maxPrice,
                             uint256 _productStartIdx, uint256 _maxResults, bool _onlyAvailable) public view returns(uint256 _idx, uint256[] memory _productIDs) {
    require(_vendorAddr != address(0), "address must be specified");
    uint _count = 0;
    _productIDs = new uint256[](_maxResults);
    uint256 _vendorProductCount = vendorProductCounts[_vendorAddr];
    mapping(uint256 => uint256) storage _vendorProducts = vendorProducts[_vendorAddr];
    //note first productID is at vendorProducts[1];
    for (_idx = _productStartIdx; _idx <= _vendorProductCount; ++_idx) {
      uint _productID = _vendorProducts[_idx];
      if (_productID != 0 && isCertainProduct(_productID, _vendorAddr, _category, _region, _maxPrice, _onlyAvailable)) {
        _productIDs[_count] = _productID;
        if (++_count >= _maxResults)
          break;
      }
    }
  }

  // _maxResults >= 1
  // _category != 0
  // note that array will always have _maxResults entries. ignore productID = 0
  // top-level-category (top 8 bits) must match product tlc exactly, whereas low-level-category bits must have any overlap with product llc bits.
  //
  function getCategoryProducts(address _vendorAddr, uint256 _category, uint256 _region, uint256 _maxPrice,
                               uint256 _productStartIdx, uint256 _maxResults, bool _onlyAvailable) public view returns(uint256 _idx, uint256[] memory _productIDs) {
    require(_category != 0, "category must be specified");
    uint _count = 0;
    uint8 _tlc = uint8(_category >> 248);
    _productIDs = new uint256[](_maxResults);
    uint256 _categoryProductCount = categoryProductCounts[_tlc];
    mapping(uint256 => uint256) storage _categoryProducts = categoryProducts[_tlc];
    //note first productID is at categoryProducts[1];
    for (_idx = _productStartIdx; _idx <= _categoryProductCount; ++_idx) {
      uint _productID = _categoryProducts[_idx];
      if (_productID != 0 && isCertainProduct(_productID, _vendorAddr, _category, _region, _maxPrice, _onlyAvailable)) {
        _productIDs[_count] = _productID;
        if (++_count >= _maxResults)
          break;
      }
    }
  }


  // _maxResults >= 1
  // _region != 0
  // note that array will always have _maxResults entries. ignore productID = 0
  // top-level-category (top 8 bits) must match product tlc exactly, whereas low-level-category bits must have any overlap with product llc bits.
  //
  function getRegionProducts(address _vendorAddr, uint256 _category, uint256 _region, uint256 _maxPrice,
                             uint256 _productStartIdx, uint256 _maxResults, bool _onlyAvailable) public view returns(uint256 _idx, uint256[] memory _productIDs) {
    require(_region != 0, "region must be specified");
    uint _count = 0;
    uint8 _tlr = uint8(_region >> 248);
    _productIDs = new uint256[](_maxResults);
    uint256 _regionProductCount = regionProductCounts[_tlr];
    mapping(uint256 => uint256) storage _regionProducts = regionProducts[_tlr];
    //note first productID is at regionProducts[1];
    for (_idx = _productStartIdx; _idx <= _regionProductCount; ++_idx) {
      uint _productID = _regionProducts[_idx];
      if (_productID != 0 && isCertainProduct(_productID, _vendorAddr, _category, _region, _maxPrice, _onlyAvailable)) {
        _productIDs[_count] = _productID;
        if (++_count >= _maxResults)
          break;
      }
    }
  }


  // -----------------------------------------------------------------------------------------------------
  // register a VendorAccount
  // -----------------------------------------------------------------------------------------------------
  function registerVendor(uint256 _defaultRegion, bytes memory _name, bytes memory _desc, bytes memory _image) public {
    vendorAccounts[msg.sender].activeFlag = true;
    vendorAccounts[msg.sender].region = _defaultRegion;
    emit RegisterVendorEvent(msg.sender, _name, _desc, _image);
    emit StatEvent("ok: vendor registered");
  }


  //if top level category/region changes we leave a hole in the oldTl[cr] map, and allocate a new entry in the newTl[cr] map
  function updateTlcTlr(uint256 _productID, uint8 _newTlc, uint8 _newTlr) internal returns(uint256 _categoryProductIdx, uint256 _regionProductIdx) {
    Product storage _product = products[_productID];
    uint8 _oldTlc = uint8(_product.category >> 248);
    if (_oldTlc == _newTlc) {
      _categoryProductIdx = _product.categoryProductIdx;
    } else {
      categoryProducts[_oldTlc][_product.categoryProductIdx] = 0;
      _categoryProductIdx = categoryProductCounts[_newTlc] = safeAdd(categoryProductCounts[_newTlc], 1);
    }
    uint8 _oldTlr = uint8(_product.region >> 248);
    if (_oldTlr == _newTlr) {
      _regionProductIdx = _product.regionProductIdx;
    } else {
      regionProducts[_oldTlr][_product.regionProductIdx] = 0;
      _regionProductIdx = regionProductCounts[_newTlr] = safeAdd(regionProductCounts[_newTlr], 1);
    }
  }


  // -----------------------------------------------------------------------------------------------------
  // register a Product
  // called by vendor
  // productID = 0 => register a new product, auto-assign product id
  // -----------------------------------------------------------------------------------------------------
  function registerProduct(uint256 _productID, uint256 _category, uint256 _region, uint256 _price, uint256 _quantity,
                           bytes memory _name, bytes memory _desc, bytes memory _image) public {
    uint256 _categoryProductIdx;
    uint256 _regionProductIdx;
    uint8 _newTlc = uint8(_category >> 248);
    uint8 _newTlr = uint8(_region >> 248);
    if (_productID == 0) {
      _productID = productCount = safeAdd(productCount, 1);
      uint256 _vendorProductIdx = vendorProductCounts[msg.sender] = safeAdd(vendorProductCounts[msg.sender], 1);
      vendorProducts[msg.sender][_vendorProductIdx] = _productID;
      _categoryProductIdx = categoryProductCounts[_newTlc] = safeAdd(categoryProductCounts[_newTlc], 1);
      _regionProductIdx = regionProductCounts[_newTlr] = safeAdd(regionProductCounts[_newTlr], 1);
    } else {
      require(products[_productID].vendorAddr == msg.sender, "caller does not own this product");
      (_categoryProductIdx, _regionProductIdx) = updateTlcTlr(_productID, _newTlc, _newTlr);
    }
    Product storage _product = products[_productID];
    _product.price = _price;
    _product.quantity = _quantity;
    _product.category = _category;
    _product.categoryProductIdx = _categoryProductIdx;
    _product.region = _region;
    _product.regionProductIdx = _regionProductIdx;
    _product.vendorAddr = msg.sender;
    categoryProducts[_newTlc][_categoryProductIdx] = _productID;
    regionProducts[_newTlr][_regionProductIdx] = _productID;
    emit RegisterProductEvent(_productID, _name, _desc, _image);
  }


  function productInfo(uint256 _productID) public view returns(address _vendorAddr, uint256 _price, uint256 _quantity, bool _available) {
    Product storage _product = products[_productID];
    _price = _product.price;
    _quantity = _product.quantity;
    _vendorAddr = _product.vendorAddr;
    uint256 _minVendorBond = safeMul(_price, 50) / 100;
    uint256 _vendorBalance = madEscrow.balanceOf(_product.vendorAddr);
    _available = (_quantity != 0 && _price != 0 && _vendorBalance >= _minVendorBond);
  }


  // -----------------------------------------------------------------------------------------------------
  // deposit funds to purchase a Product
  // this creates an escrow
  // called by customer
  // escrowID = 0 => create a new escrow, else use an existing escrow acct
  // an optional surchage (shipping & handling?) can be added to the nominal price of the product. this
  // function can also be called to add a surchage to an already existing escrow.
  // -----------------------------------------------------------------------------------------------------
  function purchaseDeposit(uint256 _escrowID, uint256 _productID, uint256 _surcharge, uint256 _attachmentIdx, bytes memory _message) public payable {
    address _vendorAddr;
    if (_escrowID != 0) {
      //ignore passed productID
      (_productID, _vendorAddr) = madEscrow.verifyEscrowCustomer(_escrowID, msg.sender);
    } else {
      require(_productID != 0, "product ID cannot be zero");
    }
    Product storage _product = products[_productID];
    _vendorAddr = _product.vendorAddr;
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, _vendorAddr);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _vendorAddr, _attachmentIdx, 0, _message);
    if (_escrowID == 0) {
      require(_product.quantity != 0, "product is not available");
      require(_product.price != 0, "product price is not valid");
      uint256 _modifiedPrice = safeAdd(_product.price, _surcharge);
      _escrowID = madEscrow.createEscrow(_productID, _msgId, _modifiedPrice, _vendorAddr, msg.sender);
      _product.quantity -= 1;
    } else {
      require(_surcharge != 0, "escrow already exists");
      madEscrow.modifyEscrowPrice(_escrowID, _msgId, _surcharge);
    }
    emit PurchaseDepositEvent(_vendorAddr, msg.sender, _escrowID, _productID, _surcharge, _msgId);
    emit StatEvent("ok: purchase funds deposited");
  }


  // -----------------------------------------------------------------------------------------------------
  // cancel purchase of a product
  // called by customer -- only before purchase has been approved by vendor
  // -----------------------------------------------------------------------------------------------------
  function purchaseCancel(uint256 _escrowID, uint256 _attachmentIdx, bytes memory _message) public payable {
    (uint256 _productID, address _vendorAddr) = madEscrow.verifyEscrowCustomer(_escrowID, msg.sender);
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, _vendorAddr);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _vendorAddr, _attachmentIdx, 0, _message);
    Product storage _product = products[_productID];
    _product.quantity += 1;
    madEscrow.cancelEscrow(_escrowID, _msgId);
    emit PurchaseCancelEvent(_vendorAddr, msg.sender, _escrowID, _productID, _msgId);
    emit StatEvent("ok: purchase canceled -- funds returned");
  }


  // -----------------------------------------------------------------------------------------------------
  // approve of a purchase
  // called by vendor
  // -----------------------------------------------------------------------------------------------------
  function purchaseApprove(uint256 _escrowID, uint256 _attachmentIdx, bytes memory _message) public payable {
    //TODO: ensure that msg.sender has an EMS account
    (uint256 _productID, address _customerAddr) = madEscrow.verifyEscrowVendor(_escrowID, msg.sender);
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, msg.sender);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _customerAddr, _attachmentIdx, 0, _message);
    madEscrow.approveEscrow(_escrowID, _msgId);
    emit PurchaseApproveEvent(msg.sender, _customerAddr, _escrowID, _productID, _msgId);
    emit StatEvent("ok: purchase approved -- funds locked");
  }



  // -----------------------------------------------------------------------------------------------------
  // reject a purchase
  // called by vendor
  // -----------------------------------------------------------------------------------------------------
  function purchaseReject(uint256 _escrowID, uint256 _attachmentIdx, bytes memory _message) public payable {
    //TODO: ensure that msg.sender has an EMS account
    (uint256 _productID, address _customerAddr) = madEscrow.verifyEscrowVendor(_escrowID, msg.sender);
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, msg.sender);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _customerAddr, _attachmentIdx, 0, _message);
    Product storage _product = products[_productID];
    madEscrow.cancelEscrow(_escrowID, _msgId);
    _product.quantity += 1;
    emit PurchaseRejectEvent(msg.sender, _customerAddr, _escrowID, _productID, _msgId);
    emit StatEvent("ok: purchase rejected -- funds returned");
  }


  // -----------------------------------------------------------------------------------------------------
  // acknowledge succesful delivery of a purchased item
  // called by customer
  // -----------------------------------------------------------------------------------------------------
  function deliveryApprove(uint256 _escrowID, uint256 _attachmentIdx, uint8 _rating, bytes memory _message) public payable {
    //TODO: ensure that msg.sender has an EMS account
    (uint256 _productID, address _vendorAddr) = madEscrow.verifyEscrowCustomer(_escrowID, msg.sender);
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, _vendorAddr);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _vendorAddr, _attachmentIdx, 0, _message);
    madEscrow.releaseEscrow(_escrowID, _msgId);
    vendorAccounts[_vendorAddr].deliveriesApproved = safeAdd(vendorAccounts[_vendorAddr].deliveriesApproved, 1);
    if (_rating > 10)
        _rating = 10;
    vendorAccounts[_vendorAddr].ratingSum = safeAdd(vendorAccounts[_vendorAddr].ratingSum, _rating);
    emit DeliveryApproveEvent(_vendorAddr, msg.sender, _escrowID, _productID, _msgId);
    emit StatEvent("ok: delivery approved -- funds destributed");
  }


  // -----------------------------------------------------------------------------------------------------
  // indicate failed delivery of a purchased item
  // called by customer
  // product might have been delivered, but defective. so we do not return the
  // product to stock; that is we do not increment product quantity
  // -----------------------------------------------------------------------------------------------------
  function deliveryReject(uint256 _escrowID, uint256 _attachmentIdx, uint8 _rating, bytes memory _message) public payable {
    //TODO: ensure that msg.sender has an EMS account
    (uint256 _productID, address _vendorAddr) = madEscrow.verifyEscrowCustomer(_escrowID, msg.sender);
    //ensure message fees
    uint256 _msgFee = messageTransport.getFee(msg.sender, _vendorAddr);
    require(msg.value == _msgFee, "incorrect funds for message fee");
    uint256 _msgId = messageTransport.sendMessage.value(_msgFee)(msg.sender, _vendorAddr, _attachmentIdx, 0, _message);
    madEscrow.burnEscrow(_escrowID, _msgId);
    vendorAccounts[_vendorAddr].deliveriesRejected = safeAdd(vendorAccounts[_vendorAddr].deliveriesRejected, 1);
    if (_rating > 10)
      _rating = 10;
    vendorAccounts[_vendorAddr].ratingSum = safeAdd(vendorAccounts[_vendorAddr].ratingSum, _rating);
    emit DeliveryRejectEvent(_vendorAddr, msg.sender, _escrowID, _productID, _msgId);
    emit StatEvent("ok: delivery rejected -- funds burned");
  }


  // -------------------------------------------------------------------------
  // for debug
  // only available before the contract is locked
  // -------------------------------------------------------------------------
  function killContract() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}