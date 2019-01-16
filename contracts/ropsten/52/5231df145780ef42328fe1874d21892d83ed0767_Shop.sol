//Complier version:0.5.1+commit.c8a2cb62.Emscripten.clang

pragma solidity ^0.5.0;
contract Shop {
    
    ////////////////////
    // STRUCTS
    ////////////////////
    
    //Struct of a product
    //The identifier of the product is the hash of the file
    struct Product
    {
        //Price of the product, which will the producers get
        uint64 price;
        
        //Fee after the product, which will the shop owner get
        uint64 feePerProduct;
        
        //Percent of the fee, needed because of the price change
        uint8 feePercent;
        
        //Is the publisher think it is sell able?
        bool sellableByProducer;
        
        //Is the shop owner think it is sell able?
        bool sellableByShop;
        
        //Is the shopowner think it is downloadable? (Like is the file online, etc...)
        bool downloadable;
    
        //Is is published? If ever published true, otherwise false
        bool published;
        
        //List of the other products in bundled UNDER this product, it is a master-salve, 1 to N relation
        bytes32[] bundle;
    }
    
    
    //Struct of a producer
    struct Producer
    {
        //Mapping of the products under this producer
        mapping(bytes32 => Product) products;
        
        //The list of the product, for easier accessing
        bytes32[] productsList;
        
        //Flag, if ever published anything or not
        bool alive;
    }
    
    ////////////////////
    // SHOP VARIABLES
    ////////////////////
    
    //Mapping of the producers
    mapping (address => Producer) producers;
    
    //List of the producers
    address[] producersList;
    
    //Balance of everybody including producer and shop owner
    mapping (address => uint) public balances;
    
    //Mapping about every buying
    mapping (address => mapping(address => mapping(bytes32 => bool))) ownings;
    
    //Address of the shop owner
    address shopOwner;
    
    //Flag, used to indicate if the shop open, or closed
    bool isShopOnline;
    
    // Date for the closing time, needed for special withdraw after closing, see 
    // closedWithdraw function for more information
    uint closingTime;
    
    //Needed for second shop owner changing function
    bytes32 hashedPassword;
    
    //Minimal price of the books
    //Used in during publishing and price changing
    uint64 public minimalProductPrice;
    
    //Global price of the function of changing the price of the products
    //Need to regulate the frequency of price changing
    uint64 public feeForPriceChange;
    
    //Fee for publishing products
    //Need to regulate the number of products
    uint64 public feeForPublish;
    
    
    ////////////////////
    // EVENTS
    ////////////////////
    
    //Update event, emitted if one of the product is changed somehow
    event Update(address indexed producer, bytes32 indexed productHash);
    
    //Buy event, emitted if somebody buys a product
    event Buy(address indexed producer, bytes32 indexed productHash, address indexed buyer);
    
    //Withdraw event, emitted if somebody withdraws
    event Withdraw(address indexed producer, uint amount);
    
    //Special withdraw event, emitted if shop owner withdraw from producer/user balance after closing
    event ClosedWithdraw(address indexed producer, address indexed shopOwner, uint amount);

    ////////////////////
    // MODIFIERS
    ////////////////////    

    //require to call the function from a special account, only used with shopOwner
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    
    //Require a minimal amount of ether, after the needed the user get what was left
    //Used for the fees, not for the buying function
    modifier costs(uint _amount) {
        require(isShopOnline);
        require(msg.value >= _amount);
        
        _;
        
        balances[shopOwner] += _amount;
        
        if (msg.value > _amount)
            balances[msg.sender] += (msg.value - _amount);
    }
    
    
    ////////////////////
    // FUNCTIONS
    ////////////////////   
    
    //Normal constructor
    function Constructor(bytes32 _HashedPassword) public
    {
        shopOwner = msg.sender;
        hashedPassword = _HashedPassword;
        isShopOnline = true;
    }
    
    //Publishing function, producers can publish their products with this function
    // _productHash: The hash of the products, used as an id
    // _price: Price of the product in Wei
    // _onTopFeeType: Type of the fee, if true, then the shop fee will put on 
    //    the top of the _price value, otherwise the full price of the product
    //    will be _price
    function publish(bytes32 _productHash, uint64 _price, bool _onTopFeeType) public payable costs(feeForPublish)
    {
        //The product have to be unpublished, and the shop have to be non closed
        require(producers[msg.sender].products[_productHash].published == false);
        require(isShopOnline);
        require(_price >= minimalProductPrice);
        
        //Setting the parameters of the product
        
        Product memory product;
        
        (product.price, product.feePerProduct) = getPrice(_price, _onTopFeeType, 10);

        product.feePercent = 10;
        product.published = true;
            
        producers[msg.sender].products[_productHash] = product;
        producers[msg.sender].productsList.push(_productHash);
        
        if (producers[msg.sender].alive == false)
        {
            producersList.push(msg.sender);
            producers[msg.sender].alive = true;
        }
        
        emit Update(msg.sender, _productHash);
    }
    
    
    //With this function the producer can change if the product is buy able or not
    //After publish the product still non sell able by the producer
    function setSellable (bytes32 _productHash, bool _sellable) public
    {
        producers[msg.sender].products[_productHash].sellableByProducer = _sellable;
        
        emit Update(msg.sender, _productHash);
    }
    
    //With this function the producer can add to the bundle of a product
    //There is not capability to remove from bundle!
    function addBundle (bytes32 _productHash, bytes32 bundle) public
    {
        producers[msg.sender].products[_productHash].bundle.push(bundle);
        
        emit Update(msg.sender, _productHash);
    }
    
    //Internal fuction to calculate the fee, based on the fee type, see publish function for more information
    function getPrice(uint64 _price, bool _onTopFeeType, uint8 _percent) internal pure returns(uint64, uint64)
    {
        if (_onTopFeeType)
            return(_price, _price*100/(100-_percent)-_price);
        
        return(_price*(100-_percent)/100,_percent*_price/100);
    }
    
    //Function for producers to change the price of their products
    //It cost some fee, to prevent too frequenty price changing
    function setPriceForProduct (bytes32 _productHash , uint64 _newPrice, bool _onTopFeeType) public payable costs(feeForPriceChange)
    {
        require(_newPrice >= minimalProductPrice);
        
        Product storage p  = producers[msg.sender].products[_productHash];
        
        require(p.published == true);
           
        
        (p.price, p.feePerProduct) = getPrice(_newPrice, _onTopFeeType, p.feePercent);
        
        
        emit Update(msg.sender, _productHash);
    }
    
    
    //Buy function for users, product identified by producer address and product hash
    function buy(address _producer, bytes32 _productHash) public payable
    {
        Product memory p  = producers[_producer].products[_productHash];
        
        uint64 price = p.price + p.feePerProduct;
        
        //The product have to be sell able
        require(p.sellableByProducer);
        require(p.sellableByShop);
        
        //The ether value have to be enough
        require(msg.value >= price);
        
        //The shop have to be non closed
        require(isShopOnline);
        
        //The shop get the fee, the producer the price
        balances[shopOwner] += p.feePerProduct;
        balances[_producer] += p.price;
        
        //The user get back the leftover, if there were any
        if (msg.value > price)
            balances[msg.sender] += (msg.value - price);
        
        //Set the ownings mapping
        ownings[msg.sender][_producer][_productHash] = true;
        
        //Emit event about the buying
        emit Buy(_producer, _productHash, msg.sender);
    }
    
    //Admin function, the shop owner can change the fee on a product, but never could set it higher than 30%
    function setFeePercentForProduct (address _producer, bytes32 _productHash , uint8 _newFeePercent) public onlyBy(shopOwner)
    {
        require(_newFeePercent < 31);
        
        Product storage p  = producers[_producer].products[_productHash];
        
        require(p.published == true);
        
        p.feePercent = _newFeePercent;

        p.feePerProduct = p.price*100/(100-_newFeePercent)-p.price;
        
        emit Update(_producer, _productHash);
    }
    
    //Admin function, to set the global fee for price change
    function setFeeForPriceChange (uint64 _newFee) public onlyBy(shopOwner)
    {
        feeForPriceChange = _newFee;
    }
    
    //Admin function, to set the global fee for publishing a new product
    function setFeeForPublish (uint64 _newFee) public onlyBy(shopOwner)
    {
        feeForPublish = _newFee;
    }
    
    //Admin function, to set a product to sell able
    function setSellable (address _producer, bytes32 _productHash, bool _sellable) public onlyBy(shopOwner)
    {
        producers[_producer].products[_productHash].sellableByShop = _sellable;
        
        emit Update(_producer, _productHash);
    }
    
    //Admin function, to set a product to downloadable
    function setDownloadable (address _producer, bytes32 _productHash, bool _downloadable) public onlyBy(shopOwner)
    {
        producers[_producer].products[_productHash].downloadable = _downloadable;
        
        emit Update(_producer, _productHash);
    }
    
    //Admin function, to change the owner, the balances not changing
    function changeShopOwner(address _newShopOwner) public onlyBy(shopOwner)
    {
        shopOwner = _newShopOwner;
    }
    
    //Admin function to change the owner with _password
    //The new owner get the old owner&#39;s balance, have to give a new password too
    function changeShopOwner(bytes32 _password, bytes32 _newHashedPassword) public
    {
        require(hashedPassword == keccak256(abi.encodePacked(_password)));
        
        
        balances[msg.sender] += balances[shopOwner];
        balances[shopOwner] = 0;
        
        shopOwner = msg.sender;
        
        hashedPassword = _newHashedPassword;
    }
    
    //Admin function to close the shop
    function closeShop () public onlyBy(shopOwner)
    {
        isShopOnline = false;
        closingTime = now;
    }
    
    //Admin function to reopen the shop
    function reopenShop () public onlyBy(shopOwner)
    {
        isShopOnline = true;
        closingTime = 0;
    }
    
    //Classic withdraw pattern
    function withdraw() public 
    {
        uint amount = balances[msg.sender];

        balances[msg.sender] = 0;
    
        emit Withdraw(msg.sender, amount);
        
        msg.sender.transfer(amount);
    }
    
    //Classic withdraw pattern in case shop is closed
    //The shopOwner could take out ether, but only after 90 days
    function closedWithdraw(address balance) public onlyBy(shopOwner)
    {
        require(isShopOnline == false);
        require(closingTime - 90 days > now);
        
        uint amount = balances[balance];

        balances[balance] = 0;
        
        emit ClosedWithdraw(balance, msg.sender, amount);
        
        msg.sender.transfer(amount);
    }
    
}