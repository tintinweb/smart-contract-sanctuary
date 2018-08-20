pragma solidity ^0.4.24;

contract Exchange {
    
    // Order struct
    struct Order {
        address creator;
        uint amount;
        uint createdAt;
    }
    
    event OrderCreation(uint _index);
    event OrderClosed(uint _index);
    event OrderAccept(uint _index);
    
    uint constant ORDER_LIFE_TIME = 86400000;
    
    // list of orders
    Order[] public orders;
    
    // check if _creator is order creator
    modifier onlyCreator(address _creator, uint _index) {
        require(_creator == orders[_index].creator);
        _;
    }
    
    // check if order life time end
    modifier canBeClosed(uint _index) {
        require(block.timestamp > orders[_index].createdAt + ORDER_LIFE_TIME);
        _;
    }
    
    // check if order life time doesn&#39;t end
    modifier isOpen(uint _index) {
        require(block.timestamp < orders[_index].createdAt + ORDER_LIFE_TIME);
        _;
    }
    
    // check if order exists
    modifier isNotNull(uint _index) {
        require(orders[_index].amount != 0);
        _;
    }
    
    // check if price is enought
    modifier isEnoughPrice(uint _index, uint amount) {
        require(orders[_index].amount == amount);
        _;
    }
    
    // create order
    function () public payable {
        Order memory order = Order({
            creator: msg.sender,
            amount: msg.value,
            createdAt: block.timestamp
        });
        emit OrderCreation(orders.length + 1);
        orders.push(order);
    }
    
    // get orders length
    function getOrdersLength() constant public returns (uint) {
        return orders.length;
    }
    
    // close order
    function closeOrder(
        uint _index
    ) 
        public 
        onlyCreator(msg.sender, _index)
        canBeClosed(_index)
    {
        uint amount = orders[_index].amount;
        delete orders[_index];
        emit OrderClosed(_index);
        msg.sender.transfer(amount);
    }
    
    // accept order
    function acceptOrder(
        uint _index    
    )
        public
        payable
        isOpen(_index)
        isNotNull(_index)
        isEnoughPrice(_index, msg.value)
    {
        uint amount = orders[_index].amount;
        address seller = orders[_index].creator;
        delete orders[_index];
        emit OrderAccept(_index);
        
        // make an exchange
        msg.sender.transfer(amount);
        seller.transfer(msg.value);
    }
    
}