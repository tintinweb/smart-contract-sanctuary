/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* Payment method interfaces */
interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function symbol() external view returns (string memory);
}

// Compatible with BakerySwap and PancakeSwap
// Because both are forks from Uniswap
interface ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );
}

/* Storage contract */
contract StorageContract {
	// Structs
	struct Product {
		address creator;	// Product creator
		string	title;		// Product title
		string	desc;		// The entire description
		string	ipfsHash;	// Image of product
		uint	price;		// Price
	    uint    paymentID;  // Payment token ID
		uint	created_at;	// Block number
		uint	id;		    // Just display
		bool	deleted;	// Deleted identifier
	}

	// Variables
	address public owner;

	address	public mainToken;

    uint    marketFee = 1;
	uint	productCreationFee = 10 ** 18;	// In Wei for mainToken
	bool	_onlyAdmins = true;

	mapping (address => bool) admins;
	Product[] products;
	
	mapping (string => address) paymentMethodsAddresses;
	string[] paymentMethods;

	// Events
	event	NewProduct(Product product);
	event	DeleteProduct(address creator, uint id);
	event	Purchase(address buyer, uint amount, Product product);
	event   NewPaymentMethod(string name, address lpContract);

	// Modifiers
	modifier onlyOwner() {
		require(msg.sender == owner, "Permission denied");
		_;
	}

	modifier onlyAdmins() {
		if (_onlyAdmins) {
			require(admins[msg.sender], "Permission denied");
		}
		_;
	}

	// Constructor
	constructor() {
		owner = msg.sender;
	}
}

/* The core contract you need to inspect */
contract FineMarket is StorageContract {
	constructor(address _token) {
		owner = msg.sender;
		admins[owner] = true;
		mainToken = _token;
		
		IERC20 token = IERC20(_token);
		
		paymentMethodsAddresses[token.symbol()] = _token;
		paymentMethods.push(token.symbol());
	}

	/* Getters */
	function getProducts() public view returns (Product[] memory) {
	    return products;
	}
	
	function getProductsRange(uint from, uint amount) public view returns (Product[] memory) {
	    if (amount > 256) amount = 256;
	    if (from + amount > products.length) amount = products.length - from;
	    
	    Product[] memory tmp = new Product[](amount);
	    
	    for (uint i = from; i < from + amount; i++) {
	        tmp[i - from] = products[i];
	    }
	    
	    return tmp;
	}
	
	function getProductsCount() public view returns (uint) {
	    return products.length;
	}

	function getProduct(uint id) public view returns (Product memory) {
	    require(id < products.length, "Product unavailable");

		return products[id];
	}
	
	function getTokenPrice(string calldata name) public view returns (uint) {
	    ISwapPair pair = ISwapPair(paymentMethodsAddresses[name]);
	    
	    //        ||               ||
	    //        v DFINE          v BNB
	    (uint112 Reserve0, uint112 Reserve1,) = pair.getReserves();
	    
	    return Reserve0 / Reserve1;
	}
	
	function getPaymentMethods() public view returns (string[] memory) {
	    return paymentMethods;
	}
	
	function getPaymentMethodAddress(string calldata name) public view returns (address) {
	    return paymentMethodsAddresses[name];
	}

	/* Setters */
	function setMainToken(address newAddress) public onlyOwner {
		mainToken = newAddress;
		paymentMethodsAddresses[paymentMethods[0]] = newAddress;
		
		IERC20 token = IERC20(newAddress);
		paymentMethods[0] = token.symbol();
	}

	function deleteProduct(uint id) public {
		Product memory p = getProduct(id);
		require(p.deleted == false, "Product already deleted");

		products[id].deleted = true;
		emit DeleteProduct(msg.sender, id);
	}

	function updateProductPrice(uint id, uint newPrice) public {
		getProduct(id);
		products[id].price = newPrice;
	}

	/* Core product functions */
	function createProduct(string calldata title, string calldata desc, string calldata ipfsHash, uint price, uint paymentID) public onlyAdmins {
	    IERC20 mainToken = IERC20(mainToken);
	    
		require(mainToken.balanceOf(msg.sender) >= productCreationFee, "Balance insufficient");
		require(paymentID >= 0 && paymentID < paymentMethods.length, "Invalid payment method ID");
		mainToken.transferFrom(msg.sender, address(this), productCreationFee);

		Product memory newProduct = Product(
			msg.sender, title, desc, ipfsHash,
			price, paymentID, block.timestamp, products.length,
			false
		);
		products.push(newProduct);

		emit NewProduct(newProduct);
	}

	function purchaseProduct(uint id, uint amount) public {
		Product memory product = getProduct(id);

		// Check if sender have enough balance in the token supported
		require(product.deleted == false, "Product has been deleted, unable to purchase");
		require(amount > 0, "Amount invalid, must be above 0");
		
		IERC20 token = IERC20(paymentMethodsAddresses[paymentMethods[product.paymentID]]);
		require(token.balanceOf(msg.sender) >= (product.price * amount), "Balance insufficient");

        // Transfer fee
        uint fee = (product.price * amount) * marketFee / 100;
        tryTransferFrom(token, msg.sender, address(this), fee);
		// Make purchase
		tryTransferFrom(token, msg.sender, product.creator, (product.price * amount) - fee);

		emit Purchase(msg.sender, amount, product);
	}
	
	function tryTransferFrom(IERC20 token, address from, address to, uint amount) internal {
	    require(token.allowance(from, address(this)) >= amount, "Allowance insufficient");
	    token.transferFrom(from, to, amount);
	}

	/* Administration */
	function withdrawFund(uint amount, string calldata tokenName) public onlyOwner {
	    IERC20 token = IERC20(paymentMethodsAddresses[tokenName]);
		tryTransferFrom(token, address(this), owner, amount);
	}
	
	function isOnlyAdmins() public view returns (bool) {
	    return _onlyAdmins;
	}

	function toggleOnlyAdmins() public onlyOwner {
		_onlyAdmins = !_onlyAdmins;
	}

	function isAdmin(address account) public view returns (bool) {
		return admins[account];
	}

	function togglePermission(address account) public onlyOwner {
		admins[account] = !admins[account];
	}
	
	function transferOwnership(address to) public onlyOwner {
	    owner = to;
	}
}