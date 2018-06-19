pragma solidity ^0.4.17;

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        sAssert(c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        sAssert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        sAssert(c>=a && c>=b);
        return c;
    }

    function sAssert(bool assertion) pure internal {
        if (!assertion) {
            revert();
        }
    }
}

contract ArrayUtil {
    function indexOf(bytes32[] array, bytes32 value)
      internal
      view
      returns(uint)
    {
        bool found = false;
        uint index = 0;

        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                found = true;
                index = i;
                break;
            }
        }

        require(found);
        return index;
    }

    function remove(bytes32[] array, bytes32 value)
      internal
      returns(bytes32[])
    {
        uint index = indexOf(array, value);
        return removeAtIndex(array, index);
    }

    function removeAtIndex(bytes32[] array, uint index)
      internal
      returns(bytes32[])
    {
        if (index >= array.length) return;

        bytes32[] memory arrayNew = new bytes32[](array.length - 1);

        for (uint i = 0; i < arrayNew.length; i++) {
            if(i != index && i < index){
                arrayNew[i] = array[i];
            } else {
                arrayNew[i] = array[i+1];
            }
        }

        delete array;
        return arrayNew;
    }
}


contract CentralityGiftShop is SafeMath, ArrayUtil {
    // Struct and enum
    struct Inventory {
        string thumbURL;
        string photoURL;
        string name;
        string description;
    }

    struct Order {
        bytes32 inventoryId;
        uint price;
        uint quantity;
        string name;
        string description;
    }

    // Instance variables
    mapping(bytes32 => Inventory) public stock;
    mapping(bytes32 => uint) public stockPrice;
    mapping(bytes32 => uint) public stockAvailableQuantity;
    bytes32[] public stocks;

    address public owner;
    address public paymentContractAddress;

    mapping(address => Order[]) orders;

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    // Init
    function CentralityGiftShop()
      public
    {
        owner = msg.sender;
    }

    // Admin
    function setPaymentContractAddress(address contractAddress)
      public
      onlyOwner()
    {
        paymentContractAddress = contractAddress;
    }

    function withdraw()
      public
      onlyOwner()
    {
        require(paymentContractAddress != 0x0);

        uint balance = ERC20(paymentContractAddress).balanceOf(this);
        require(balance > 0);

        if (!ERC20(paymentContractAddress).transfer(msg.sender, balance)) {
            revert();
        }
    }

    function addInventory(
        bytes32 inventoryId,
        string thumbURL,
        string photoURL,
        string name,
        string description,
        uint price,
        uint availableQuantity
    )
      public
      onlyOwner()
    {
        Inventory memory inventory = Inventory({
            thumbURL: thumbURL,
            photoURL: photoURL,
            name: name,
            description: description
        });

        stock[inventoryId] = inventory;
        stockPrice[inventoryId] = price;
        stockAvailableQuantity[inventoryId] = availableQuantity;

        stocks.push(inventoryId);
    }

    function removeInventory(bytes32 inventoryId)
      public
      onlyOwner()
    {
        stocks = remove(stocks, inventoryId);
    }

    function purchaseFor(address buyer, bytes32 inventoryId, uint quantity)
     public
     onlyOwner()
    {
        uint price = stockPrice[inventoryId];

        // Check if the order is sane
        require(price > 0);
        require(quantity > 0);
        require(stockPrice[inventoryId] > 0);
        require(safeSub(stockAvailableQuantity[inventoryId], quantity) >= 0);

        //Place Order
        Inventory storage inventory = stock[inventoryId];

        Order memory order = Order({
            name: inventory.name,
            description: inventory.description,
            inventoryId: inventoryId,
            price: price,
            quantity: quantity
        });

        orders[buyer].push(order);
        stockAvailableQuantity[inventoryId] = safeSub(stockAvailableQuantity[inventoryId], quantity);
    }

    // Public
    function getStockLength()
      public
      view
      returns(uint) 
    {
        return stocks.length;
    }
    
    function getOrderLength(address buyer)
      public
      view
      returns(uint) 
    {
        return orders[buyer].length;
    }

    function getOrder(address buyer, uint index)
      public
      view
      returns(bytes32, uint, uint, string, string) 
    {
        Order o = orders[buyer][index];
        return (o.inventoryId, o.price, o.quantity, o.name, o.description);
    }
    
    function purchase(bytes32 inventoryId, uint quantity)
      public
    {
        uint index = indexOf(stocks, inventoryId);
        uint price = stockPrice[inventoryId];

        // Check if the order is sane
        require(price > 0);
        require(quantity > 0);
        require(stockPrice[inventoryId] > 0);
        require(safeSub(stockAvailableQuantity[inventoryId], quantity) >= 0);

        // Check cost
        uint cost = safeMul(price, quantity);
        require(cost > 0);

        if (!ERC20(paymentContractAddress).transferFrom(msg.sender, this, cost)) {
            revert();
        }

        Inventory storage inventory = stock[inventoryId];

        Order memory order = Order({
            name: inventory.name,
            description: inventory.description,
            inventoryId: inventoryId,
            price: price,
            quantity: quantity
        });

        orders[msg.sender].push(order);
        stockAvailableQuantity[inventoryId] = safeSub(stockAvailableQuantity[inventoryId], quantity);
    }

    // Default
    function () public {
        // Do not accept ether
        revert();
    }
}