pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Exchange is Ownable {
    
    // Order struct
    struct Order {
        address creator;
        uint amount;
        uint createdAt;
        uint lifeTime;
    }
    
    event OrderCreation(uint _index);
    event OrderClosed(uint _index);
    event OrderAccept(uint _index);
    
    // list of orders
    Order[] public orders;
    
    // ZEON address
    address public zeonAddress;
    
    // ZEON amount to withdraw
    uint public zeonAmount;
    
    // ZEON percentage for the deal
    uint public zeonPercentage;
    
    // check if _creator is order creator
    modifier onlyCreator(address _creator, uint _index) {
        require(_creator == orders[_index].creator);
        _;
    }
    
    // check if order life time end
    modifier canBeClosed(uint _index) {
        require(block.timestamp > orders[_index].createdAt + orders[_index].lifeTime);
        _;
    }
    
    // check if order life time doesn&#39;t end
    modifier isOpen(uint _index) {
        require(block.timestamp < orders[_index].createdAt + orders[_index].lifeTime);
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
    
    constructor(
        address _address,
        uint _zeonPercentage
    ) 
        public 
    {
        zeonAddress = _address;
        zeonPercentage = _zeonPercentage;
    }
    
    // create order
    function () public payable {
        Order memory order = Order({
            creator: msg.sender,
            amount: msg.value,
            createdAt: block.timestamp,
            lifeTime: 5 minutes
        });
        emit OrderCreation(orders.length - 1);
        orders.push(order);
    }
    
    // get orders length
    function getOrdersLength() view public returns (uint) {
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
        uint perc = amount * zeonPercentage / 100;
        zeonAmount += perc;
        msg.sender.transfer(amount - perc);
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
    
    function withdraw() 
        public 
        onlyOwner 
    {
        uint amount = zeonAmount;
        zeonAmount = 0;
        zeonAddress.transfer(amount);
    }
    
}