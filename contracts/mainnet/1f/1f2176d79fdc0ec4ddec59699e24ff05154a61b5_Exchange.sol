pragma solidity ^0.4.24;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

//ERC20 function interface
interface ERC20_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
}


/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    
    /*Structs*/
    //This is the base data structure for an order (the maker of the order and the price)
    struct Order {
        address maker;// the placer of the order
        uint price;// The price in wei
        uint amount;
        address asset;
    }

    struct ListAsset {
        uint price;
        uint amount;
    }

    mapping(address => ListAsset) public listOfAssets;
    //Maps an OrderID to the list of orders
    mapping(uint256 => Order) public orders;
    //An mapping of a token address to the orderID&#39;s
    mapping(address =>  uint256[]) public forSale;
    //Index telling where a specific tokenId is in the forSale array
    mapping(uint256 => uint256) internal forSaleIndex;
    //Index telling where a specific tokenId is in the forSale array
    address[] public openBooks;
    //mapping of address to position in openBooks
    mapping (address => uint) internal openBookIndex;
    //mapping of user to their orders
    mapping(address => uint[]) public userOrders;
    //mapping from orderId to userOrder position
    mapping(uint => uint) internal userOrderIndex;
    //A list of the blacklisted addresses
    mapping(address => bool) internal blacklist;
    //order_nonce;
    uint internal order_nonce;

    /*Events*/
    event OrderPlaced(address _sender,address _token, uint256 _amount, uint256 _price);
    event Sale(address _sender,address _token, uint256 _amount, uint256 _price);
    event OrderRemoved(address _sender,address _token, uint256 _amount, uint256 _price);

    /*Modifiers*/
    /**
    *@dev Access modifier for Owner functionality
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev the constructor argument to set the owner and initialize the array.
    */
    constructor() public{
        owner = msg.sender;
        openBooks.push(address(0));
        order_nonce = 1;
    }

    /**
    *@dev list allows a party to place an order on the orderbook
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require(blacklist[msg.sender] == false);
        require(_price > 0);
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(token.allowance(msg.sender,address(this)) >= _amount);
        if(forSale[_tokenadd].length == 0){
            forSale[_tokenadd].push(0);
            }
        forSaleIndex[order_nonce] = forSale[_tokenadd].length;
        forSale[_tokenadd].push(order_nonce);
        orders[order_nonce] = Order({
            maker: msg.sender,
            asset: _tokenadd,
            price: _price,
            amount:_amount
        });
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(openBookIndex[_tokenadd] == 0 ){    
            openBookIndex[_tokenadd] = openBooks.length;
            openBooks.push(_tokenadd);
        }
        userOrderIndex[order_nonce] = userOrders[msg.sender].length;
        userOrders[msg.sender].push(order_nonce);
        order_nonce += 1;
    }

    /**
    *@dev list allows a party to list an order on the orderbook
    *@param _asset address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price per unit in wei
    */
    //Then you would have a mapping from an asset to its price/ quantity when you list it.
    function listDda(address _asset, uint256 _amount, uint256 _price) public onlyOwner() {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        listing.price = _price;
        listing.amount= _amount;
    }

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
    function buyPerUnit(address _asset, uint256 _amount) external payable {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        require(_amount <= listing.amount);
        require(msg.value == _amount.mul(listing.price));
        listing.amount= listing.amount.sub(_amount);
    }

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
    function unlist(uint256 _orderId) external{
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];
        require(msg.sender== _order.maker || msg.sender == owner);
        unLister(_orderId,_order);
        emit OrderRemoved(msg.sender,_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        Order memory _order = orders[_orderId];
        require(_order.price != 0 && _order.maker != address(0) && _order.asset != address(0) && _order.amount != 0);
        require(msg.value == _order.price);
        require(blacklist[msg.sender] == false);
        address maker = _order.maker;
        ERC20_Interface token = ERC20_Interface(_order.asset);
        if(token.allowance(_order.maker,address(this)) >= _order.amount){
            assert(token.transferFrom(_order.maker,msg.sender, _order.amount));
            maker.transfer(_order.price);
        }
        unLister(_orderId,_order);
        emit Sale(msg.sender,_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev getOrder lists the price,amount, and maker of a specific token for a sale
    *@param _orderId uint256 ID of order
    *@return address of the party selling
    *@return uint of the price of the sale (in wei)
    *@return uint of the order amount of the sale
    *@return address of the token
    */
    function getOrder(uint256 _orderId) external view returns(address,uint,uint,address){
        Order storage _order = orders[_orderId];
        return (_order.maker,_order.price,_order.amount,_order.asset);
    }

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner() {
        blacklist[_address] = _motion;
    }

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
    function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    }

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
    function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    }

    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function getBookCount() public constant returns(uint) {
        return openBooks.length;
    }

    /**
    *@dev getOrders allows parties to get an array of all orderId&#39;s open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
    function getOrders(address _token) public constant returns(uint[]) {
        return forSale[_token];
    }

    /**
    *@dev getUserOrders allows parties to get an array of all orderId&#39;s open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    }

    /**
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _orderId is the uint256 ID of order
    *@param _order is the struct containing the details of the order
    */
    function unLister(uint256 _orderId, Order _order) internal{
            uint256 tokenIndex;
            uint256 lastTokenIndex;
            address lastAdd;
            uint256  lastToken;
        if(forSale[_order.asset].length == 2){
            tokenIndex = openBookIndex[_order.asset];
            lastTokenIndex = openBooks.length.sub(1);
            lastAdd = openBooks[lastTokenIndex];
            openBooks[tokenIndex] = lastAdd;
            openBookIndex[lastAdd] = tokenIndex;
            openBooks.length--;
            openBookIndex[_order.asset] = 0;
            forSale[_order.asset].length -= 2;
        }
        else{
            tokenIndex = forSaleIndex[_orderId];
            lastTokenIndex = forSale[_order.asset].length.sub(1);
            lastToken = forSale[_order.asset][lastTokenIndex];
            forSale[_order.asset][tokenIndex] = lastToken;
            forSaleIndex[lastToken] = tokenIndex;
            forSale[_order.asset].length--;
        }
        forSaleIndex[_orderId] = 0;
        orders[_orderId] = Order({
            maker: address(0),
            price: 0,
            amount:0,
            asset: address(0)
        });
        if(userOrders[_order.maker].length > 1){
            tokenIndex = userOrderIndex[_orderId];
            lastTokenIndex = userOrders[_order.maker].length.sub(1);
            lastToken = userOrders[_order.maker][lastTokenIndex];
            userOrders[_order.maker][tokenIndex] = lastToken;
            userOrderIndex[lastToken] = tokenIndex;
        }
        userOrders[_order.maker].length--;
        userOrderIndex[_orderId] = 0;
    }
}