// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.1;

import './Permissions.sol';
import './SafeMath.sol';

contract Product {
    uint productID;
    string name;
    uint price;
    uint tax;
    Supplier supplier;
    
    constructor(uint _id, string memory _name, uint _price, uint _tax, Supplier _supplier) {
        productID = _id;
        name = _name;
        price = _price;
        tax = _tax;
        supplier = _supplier;
    }
    
    function getPrice() public view returns(uint) {
        return price;
    }
    
    function getTax() public view returns(uint) {
        return price;
    }
    
    function getSupplier() public view returns(Supplier) {
        return supplier;
    }
    
    function getTotalPrice(uint _amount) public view returns(uint) {
        return SafeMath.mul(this.getPrice(), _amount);
    }
    
    function getTotalPriceAfterTax(uint _amount) public view returns(uint) {
        return SafeMath.mul(getTotalPrice(_amount), this.getTax());
    }
}

contract Order is EscrowOwnable {
    Product product;
    address customer;
    
    uint amount;
    uint paymentTimestamp;
    
    event ORDER_CANCLED(address ORDER, address CUSTOMER);
    event ORDER_STATUS_CHANGED(OrderStatus ORDERSTATUS);
    
    enum OrderStatus { DRAFT, APPROVED, IN_PROGRESS, RECEIVED, CANCELLED }
    OrderStatus currentStatus;

    
    constructor(address _escrow, address _customer, Product _product) {
        setEscrow(_escrow);
        customer = _customer;
        product = _product;
    }
    
    function cancleOrder() public onlyAuthorized {
        require(currentStatus != OrderStatus.CANCELLED, "Bestellung schon storniert!");
        currentStatus = OrderStatus.CANCELLED;
        emit ORDER_CANCLED(address(this), customer);
    }
    
    function updateOrder(OrderStatus _status) public {
        require(msg.sender == address(product.getSupplier()));
        currentStatus = _status;
        emit ORDER_STATUS_CHANGED(_status);
    }
}

contract VendorContract is EscrowOwnable {
    string public name;
    
    
    Product[] products;
    mapping(address => Supplier) suppliers;
    mapping(address => uint) productCount;
    
    mapping(address => Order[]) customerOrders;
    
    uint realizedFunds;
    
    constructor(string memory _name) {
        setEscrow(msg.sender);
        name = _name;
    }
    
    function getRealizedBalance() public view onlyAuthorized returns(uint) {
        return realizedFunds;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function _productCount() public view returns(uint) {
        return products.length;
    }
    
    function claimProfit(uint _amount) public onlyOwner {
        uint availableClaim = SafeMath.sub(getBalance(), realizedFunds);
        require(SafeMath.sub(availableClaim, _amount) > 0, "Kein verfuegbarer Profit!");
        transfer(_amount);
    }
    
    function claimAllProfit() public onlyOwner {
        claimProfit(realizedFunds);
    }
    
    function produktAnlegen(address _supplier, string memory _name, uint _price, uint _tax) onlyOwner public {
        require(suppliers[_supplier].isSet(), "Zulieferer nicht gefunden!");
        Supplier supplier = suppliers[_supplier];
        Product newProduct = new Product(_productCount(), _name, _price, _tax, supplier);
        products.push(newProduct);
        productCount[address(newProduct)] = 9999;
    }
    
    function purchaseProduct(uint _productID, uint _amount) public payable {
        require(_productID >= 0 && _productID < products.length, "ProductID invalide!");
        Product product = products[_productID];
        require(productCount[address(product)] > _amount, "Lagerbestand unzureichend!");
        
        require(msg.value == product.getTotalPriceAfterTax(_amount));
        
        productCount[address(product)] = SafeMath.sub(productCount[address(product)], _amount);
        customerOrders[msg.sender].push(new Order(escrow, msg.sender, product));
    }
    
    function subProductValue(Product _product, int _amount) internal {
        require(productCount[address(_product)] >= uint(_amount));
        productCount[address(_product)] = SafeMath.sub(productCount[address(_product)], uint(_amount));
    }
    
    function addProductValue(Product _product, int _amount) internal {
        productCount[address(_product)] = SafeMath.add(productCount[address(_product)], uint(_amount));
    }
    
    function updateProductCount(uint _productID, int _amount) public onlyOwner {
        require(_productID >= 0 && _productID < products.length, "ProductID invalide!");
        Product product = products[_productID];
        if(_amount < 0) subProductValue(product, _amount); else addProductValue(product, _amount);
    }
    
    function showProducts() public view returns(Product[] memory) {
        return products;
    }
    
    function showMyOrders() public view returns(Order[] memory) {
        return customerOrders[msg.sender];
    }
}

contract Supplier is Ownable {
    string public name;
    bool set = false;
    
    constructor() {
        set = true;
    }

    function isSet() public view returns(bool) {
        return set;
    }
}

contract EscrowContract is Ownable {
    mapping(address => VendorContract) public vendorContract;
    function deployVendorContract(string memory _name) public {
        require(address(vendorContract[msg.sender]) == address(0));
        vendorContract[msg.sender] = new VendorContract(_name);
    }
    
    function getContractFromVendor(address _vendor) public view returns(VendorContract){
        return vendorContract[_vendor];
    }
    
    
    
}