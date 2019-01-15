pragma solidity 0.5.2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract PurchaseContract {
    
  using SafeMath for uint256;
  
  uint purchasedProductsCount;
  uint unPurchasedProductsCount;

  IERC20 token;

  struct Product {
    uint id;
    uint price;
    address buyer;
    address retailer;
    address model;
    bool purchased;
  }

  Product[] products;
  
  event Purchase(uint _id, uint _price, address _buyer, address _retailer, address _model);
  
  constructor(address _tokenAddress) public {
    token = IERC20(_tokenAddress);
  }

  function addProduct(uint _productId, uint _price) external {
    require(_productId > 0);
    require(_price > 0);

    products.push(Product(_productId, _price, address(0), msg.sender, address(0), false));
    unPurchasedProductsCount = unPurchasedProductsCount.add(1);
  }

  function addProducts(uint[] calldata _productIds, uint[] calldata _prices) external {
    require(_productIds.length > 0);
    require(_prices.length > 0);
    require(_productIds.length == _prices.length);

    for(uint i = 0; i < _productIds.length; i++) {
      require(_productIds[i] > 0 && _prices[i] > 0); 
      products.push(Product(_productIds[i], _prices[i], address(0), msg.sender, address(0), false));
      unPurchasedProductsCount = unPurchasedProductsCount.add(1);
    }
  }
  
  function purchaseRequest(uint _productId) external {
    (Product memory _product, uint index) = findProductAndIndexById(_productId);
    require(_productId != 0 && _product.id == _productId && _product.purchased == false);
    require(_product.buyer == address(0));
    require(_product.price <= token.balanceOf(msg.sender));
    _product.buyer = msg.sender;
     products[index] = _product;
  }

  function getProductPrice(uint _productId) external view returns(uint) {
    Product memory _product = findProductById(_productId);
    return _product.price;
  }

  function getProductRetailer(uint _productId) external view returns(address) {
    Product memory _product = findProductById(_productId);
    return _product.retailer;
  }
  
  function getProductBuyer(uint _productId) external view returns(address) {
    Product memory _product = findProductById(_productId);
    return _product.buyer;
  }
  
  function isPurchased(uint _productId) external view returns(bool) {
    Product memory _product = findProductById(_productId);
    return _product.purchased;
  }

  function getUnPurchasedProducts() external view returns(uint[] memory) {
    uint index;
    bool isEmpty = true;
    uint[] memory results = new uint[](unPurchasedProductsCount);

    for(uint i = 0; i < products.length; i++) {
       if(!products[i].purchased){
         results[index] = products[i].id;
         index = index.add(1);
         isEmpty = false;
       }
    }
    
    if(isEmpty) {
        return new uint[](1);
    }
    
    return results;
  }
  
  function getPurchasedProducts() external view returns(uint[] memory) {
    uint index;
    bool isEmpty = true;
    uint[] memory results = new uint[](purchasedProductsCount);

    for(uint i = 0; i < products.length; i++) {
       if(products[i].purchased){
         results[index] = products[i].id;
         index = index.add(1);
         isEmpty = false;
       }
    }
    
    if(isEmpty) {
        return new uint[](1);
    }

    return results;
  }

  function confirmPurchase(uint _productId, address _model) external {
    require(_productId != 0);

    (Product memory _product, uint index) = findProductAndIndexById(_productId);

    require(msg.sender == _product.retailer && _product.buyer != address(0) && token.allowance(_product.buyer, address(this)) >= _product.price); 

    _product.model = _model;

    token.transferFrom(_product.buyer, _product.retailer, _product.price.mul(90).div(100));
    token.transferFrom(_product.buyer, _product.model, _product.price.mul(6).div(100));
    
    _product.purchased = true;
    purchasedProductsCount = purchasedProductsCount.add(1);
    unPurchasedProductsCount = unPurchasedProductsCount.sub(1);
    
    products[index] = _product;

    emit Purchase(_productId, _product.price, _product.buyer, _product.retailer, _model);
  }

  function findProductAndIndexById(uint _productId) internal view returns(Product memory, uint) {
    for(uint i = 0; i < products.length; i++) {
       if(products[i].id == _productId){
         return (products[i], i);
       }
    }
    
    return (Product(0, 1, address(0), address(0), address(0), false), 0);
  }
  
  function findProductById(uint _productId) internal view returns(Product memory) {
    for(uint i = 0; i < products.length; i++) {
       if(products[i].id == _productId){
         return products[i];
       }
    }
    
    return Product(0, 1, address(0), address(0), address(0), false);
  }
  
  
}