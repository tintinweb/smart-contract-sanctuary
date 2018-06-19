pragma solidity ^0.4.20;

contract SSC_HowManyPeoplePaid {
 
    event Bought(address _address);
    event PriceUpdated(uint256 _price);
 
    // Owner of the contract
    address private _owner;
 
    // The amount of curious people
    uint256 private _count = 0;
    // Price to take a look
    uint256 private _price = 1500000000000000;
    
    // Only update the counter if the mapping is false. This ensures uniqueness.
    mapping (address => bool) _clients;
    
    constructor() public {
        _owner = msg.sender;   
    }
    
   function withdraw() public{
        require(msg.sender == _owner);
        _owner.transfer(address(this).balance);
    }
    
    // == Payables == //
    
    function() public payable { }
    
    function buy() public payable {
        // Price must be at least _price, can be higher.
        assert(msg.value >= _price);
        
        // No mapping exists? Unique! Increase counter.
        if (!_clients[msg.sender]) {
            _clients[msg.sender] = true;
            _count += 1;
        }
        
        // Emit an event
        emit Bought(msg.sender);
    }
    
    // == Setters == //
    
    function setPrice(uint256 newPrice) public {
        require(msg.sender == _owner);
        assert(newPrice > 0);
        
        // Set value
        _price = newPrice;
        
        // Emit an event
        emit PriceUpdated(newPrice);
    }
    
    // == Getters == //
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getPrice() public view returns (uint256) {
        return _price;
    }
    
    // Will only return if this address exists in the mapping _clients.
    // - Only paying customers can see this counter
    // - If the customer has paid, he has life-time access
    function getCount() public view returns (bool, uint256) {
        if(_clients[msg.sender]){
            return (true,_count);    
        }
        return (false, 0);
    }
    
    function isClient(address _address) public view returns (bool) {
        return _clients[_address];
    }
}