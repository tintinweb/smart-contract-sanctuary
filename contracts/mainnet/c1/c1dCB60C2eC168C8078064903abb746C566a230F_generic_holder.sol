contract generic_holder {
    address owner;
    
    modifier onlyowner {
        if (owner == msg.sender)
            _;
    }
    
    // constructor
    function generic_holder() {
        owner = msg.sender;
    }
    
    function change_owner(address new_owner) external onlyowner {
        owner = new_owner;
    }
    
    function execute(address _to, uint _value, bytes _data) external onlyowner returns (bool){
        return _to.call.value(_value)(_data);
    }
    
    function get_owner() constant returns (address) {
        return owner;
    }
}