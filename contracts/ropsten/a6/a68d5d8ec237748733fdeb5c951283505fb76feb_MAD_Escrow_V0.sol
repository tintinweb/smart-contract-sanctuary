pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------
//  MAD Escrow Contract
// ---------------------------------------------------------------------------
contract MAD_Escrow_V0 {

  // -------------------------------------------------------------------------
  // events
  // -------------------------------------------------------------------------
  event StatEvent(string message);
  event RegisterVendorEvent(address indexed _vendorAddr, bool list, bytes desc, bytes image);
  event RegisterProductEvent(address indexed _vendorAddr, uint256 _productID, bytes desc, bytes image);
  event PurchaseDepositEvent(address indexed _vendorAddr, address customerAddr, uint256 _productID);
  event PurchaseCancelEvent(address indexed_vendorAddr, address indexed customerAddr);
  event PurchaseApproveEvent(address indexed_vendorAddr, address indexed customerAddr);
  event PurchaseRejectEvent(address indexed _vendorAddr, address customerAddr, uint256 _productID);
  event DeliveryApproveEvent(address indexed_vendorAddr, address indexed customerAddr, uint256 _productID);
  event DeliveryRejectEvent(address indexed_vendorAddr, address indexed customerAddr, uint256 _productID);

  // -------------------------------------------------------------------------
  // defines
  // -------------------------------------------------------------------------
  uint constant ESCROW_FEE_PCTX10 = 15;


  // -------------------------------------------------------------------------
  // Product structure
  // -------------------------------------------------------------------------
  struct Product {
    uint256 id;
    uint256 price;
    uint256 quantity;
  }

  // -------------------------------------------------------------------------
  // Escrow Account structure
  // an escrow account between two parties
  // -------------------------------------------------------------------------
  struct EscrowAccount {
    bool approved;                      // purchase has been approved by vendor
    uint256 productID;                  // escrow is for purchase of this product
    uint256 vendorBalance;                 // amount that vendor has put into escrow
    uint256 customerBalance;               // amount that customer has put into escrow
  }

  // -------------------------------------------------------------------------
  // Vendor Account structure
  // -------------------------------------------------------------------------
  struct VendorAccount {
    bool list;
    bool active;
    uint256 bondPct;
    uint256 bondBalance;
    mapping (uint256 => Product) products;
    mapping (address => EscrowAccount) escrowAccounts;
  }


  // -------------------------------------------------------------------------
  // data storage
  // -------------------------------------------------------------------------
  bool public isLocked;
  address public owner;
  address public communityAddr;
  uint256 public communityBalance;
  uint public contractSendGas = 100000;
  mapping (address => uint256) public partyFunds;
  mapping (address => VendorAccount) public vendorAccounts;


  // -------------------------------------------------------------------------
  // modifiers
  // -------------------------------------------------------------------------
  modifier ownerOnly {
    require(msg.sender == owner, "owner only");
    _;
  }
  modifier unlockedOnly {
    require(!isLocked, "unlocked only");
    _;
  }


  // -------------------------------------------------------------------------
  //  EMS constructor and tune
  // -------------------------------------------------------------------------
  constructor() public {
    owner = msg.sender;
  }
  function tune(uint256 _contractSendGas) public ownerOnly {
    contractSendGas = _contractSendGas;
  }



  // -------------------------------------------------------------------------
  // register a VendorAccount
  // -------------------------------------------------------------------------
  function registerVendor(uint256 _bondPct, bool _list, bytes _desc, bytes _image) public {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    _vendorAccount.list = _list;
    _vendorAccount.active = true;
    _vendorAccount.bondPct = _bondPct;
    emit RegisterVendorEvent(msg.sender, _list, _desc, _image);
    emit StatEvent("ok: vendor registered");
  }

  function unregisterVendor() public {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    _vendorAccount.list = false;
    _vendorAccount.active = false;
    emit StatEvent("ok: vendor unregistered");
  }


  // -------------------------------------------------------------------------
  // register a Product
  // called by vendor
  // -------------------------------------------------------------------------
  function registerProduct(uint256 _productID, uint256 _price, uint256 _quantity, bytes _desc, bytes _image) public {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    Product storage _product = _vendorAccount.products[_productID];
    _product.price = _price;
    _product.quantity = _quantity;
    emit RegisterProductEvent(msg.sender, _productID, _desc, _image);
    emit StatEvent("ok: product added");
  }

  function productInfo(uint256 _productID) public view returns(uint256 _price, uint256 _quantity) {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    Product storage _product = _vendorAccount.products[_productID];
    _price = _product.price;
    _quantity = _product.quantity;
  }


  // -------------------------------------------------------------------------
  // deposit bund funds
  // called by vendor
  // set price to zero discontinues a product
  // -------------------------------------------------------------------------
  function depositBond() public payable {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    _vendorAccount.bondBalance += msg.value;
    emit StatEvent("ok: bond deposited");
  }

  function transferBond(uint256 _amount) public payable {
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.bondBalance >= _amount, "bond funds are less than requested amount");
    _vendorAccount.bondBalance -= _amount;
    partyFunds[msg.sender] += _amount;
    emit StatEvent("ok: bond transfered");
  }


  // -------------------------------------------------------------------------
  // deposit fundes to purchase a Product
  // called by customer
  // -------------------------------------------------------------------------
  function purchaseDeposit(address _vendorAddr, uint256 _productID) public payable {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[_vendorAddr];
    require(_vendorAccount.active == true, "vendor account is not active");
    Product storage _product = _vendorAccount.products[_productID];
    require(_product.quantity != 0, "product is not available");
    require(_product.price != 0, "product price is not valid");
    uint256 _minCustomerBond = _product.price * _vendorAccount.bondPct / 100;
    uint256 _minVendorBond = _product.price + _minCustomerBond;
    require(msg.value >= _minCustomerBond, "insufficient deposit funds");
    require(_vendorAccount.bondBalance >= _minVendorBond, "vendor has not deposited enough bond funds");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[msg.sender];
    require(_escrowAccount.vendorBalance == 0, "escrow already active with this vendor");
    require(_escrowAccount.customerBalance == 0, "escrow already active with this vendor");
    _vendorAccount.bondBalance -= _minVendorBond;
    _escrowAccount.vendorBalance += _minVendorBond;
    _escrowAccount.customerBalance += msg.value;
    _escrowAccount.approved = false;
    _escrowAccount.productID = _productID;
    _product.quantity -= 1;
    emit PurchaseDepositEvent(_vendorAddr, msg.sender, _productID);
    emit StatEvent("ok: purchase funds deposited");
  }


  // -------------------------------------------------------------------------
  // cancel purchase of a product
  // called by customer -- only before purchase has been approved by vendor
  // -------------------------------------------------------------------------
  function purchaseCancel(address _vendorAddr) public {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[msg.sender];
    require(_escrowAccount.customerBalance != 0, "no active escrow with this vendor");
    require(_escrowAccount.approved != true, "purchase already approved; funds are locked");
    Product storage _product = _vendorAccount.products[_escrowAccount.productID];
    _product.quantity += 1;
    _vendorAccount.bondBalance += _escrowAccount.vendorBalance;
    partyFunds[msg.sender] += _escrowAccount.customerBalance;
    _escrowAccount.vendorBalance = 0;
    _escrowAccount.customerBalance = 0;
    _escrowAccount.approved = false;
    emit PurchaseCancelEvent(_vendorAddr, msg.sender);
    emit StatEvent("ok: purchase canceled -- funds returned");
  }



  // -------------------------------------------------------------------------
  // approve of a purchase
  // called by vendor
  // -------------------------------------------------------------------------
  function purchaseApprove(address _customerAddr) public {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[_customerAddr];
    _escrowAccount.approved = true;
    emit PurchaseApproveEvent(msg.sender, _customerAddr);
    emit StatEvent("ok: purchase approved -- funds locked");
  }


  // -------------------------------------------------------------------------
  // reject a purchase
  // called by vendor
  // -------------------------------------------------------------------------
  function purchaseReject(address _customerAddr) public {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[_customerAddr];
    require(_escrowAccount.vendorBalance != 0, "no active escrow with this customer");
    require(_escrowAccount.approved != true, "purchase already approved; funds are locked");
    Product storage _product = _vendorAccount.products[_escrowAccount.productID];
    _product.quantity += 1;
    _vendorAccount.bondBalance += _escrowAccount.vendorBalance;
    partyFunds[_customerAddr] += _escrowAccount.customerBalance;
    _escrowAccount.vendorBalance = 0;
    _escrowAccount.customerBalance = 0;
    emit PurchaseRejectEvent(msg.sender, _customerAddr, _escrowAccount.productID);
    emit StatEvent("ok: purchase rejected -- funds returned");
  }


  // -------------------------------------------------------------------------
  // acknowledge succesful delivery of a purchased item
  // called by customer
  // -------------------------------------------------------------------------
  function deliveryApprove(address _vendorAddr) public {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[msg.sender];
    require(_escrowAccount.approved == true, "purchase has not been approved yet");
    uint256 _price = (_escrowAccount.customerBalance - _escrowAccount.vendorBalance);
    uint256 _escrowFee = (_price * ESCROW_FEE_PCTX10) / 1000;
    communityBalance += _escrowFee;
    partyFunds[_vendorAddr] += (_escrowAccount.customerBalance - _escrowFee);
    partyFunds[msg.sender] += _escrowAccount.vendorBalance;
    _escrowAccount.customerBalance = 0;
    _escrowAccount.vendorBalance = 0;
    emit DeliveryApproveEvent(_vendorAddr, msg.sender, _escrowAccount.productID);
    emit StatEvent("ok: delivery approved -- funds destributed");
  }


  // -------------------------------------------------------------------------
  // indicate failed delivery of a purchased item
  // called by customer
  // product might have been delivered, but defective. so we do not return the
  // product to stock; that is we do not increment product quantity
  // -------------------------------------------------------------------------
  function deliveryReject(address _vendorAddr) public {
    //TODO: ensure that msg.sender has an EMS account
    VendorAccount storage _vendorAccount = vendorAccounts[msg.sender];
    require(_vendorAccount.active == true, "vendor account is not active");
    EscrowAccount storage _escrowAccount = _vendorAccount.escrowAccounts[msg.sender];
    require(_escrowAccount.approved == true, "purchase has not been approved yet");
    communityBalance += (_escrowAccount.customerBalance + _escrowAccount.vendorBalance);
    _escrowAccount.customerBalance = 0;
    _escrowAccount.vendorBalance = 0;
    emit DeliveryRejectEvent(_vendorAddr, msg.sender, _escrowAccount.productID);
    emit StatEvent("ok: delivery rejected -- funds burned");
  }


  // -------------------------------------------------------------------------
  // any party that has funds can withdraw at any time
  // called by vendor or customer
  // -------------------------------------------------------------------------
  function withdraw() public {
    uint _amount = partyFunds[msg.sender];
    partyFunds[msg.sender] = 0;
    msg.sender.transfer(_amount);
  }


  // -------------------------------------------------------------------------
  // withdraw escrow fees to the community address
  // -------------------------------------------------------------------------
  function withdrawEscrowFees() public {
    uint _amount = communityBalance;
    communityBalance = 0;
    if (!communityAddr.call.gas(contractSendGas).value(_amount)())
      revert();
  }


  // -------------------------------------------------------------------------
  // for debug
  // only available before the contract is locked
  // -------------------------------------------------------------------------
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}