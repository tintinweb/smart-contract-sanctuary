pragma solidity ^0.4.15;

contract generic_holder {
    address owner;
    
    modifier onlyowner {
        require(msg.sender == owner);
        _;
    }
    
    // constructor
    function generic_holder() {
        owner = msg.sender;
    }
    
    function change_owner(address new_owner) external onlyowner {
        owner = new_owner;
    }
    
    function execute(address _to, uint _value, bytes _data) external onlyowner payable returns (bool){
        return _to.call.value(_value)(_data);
    }

    function send(address _to) external onlyowner payable returns (bool){
        return _to.call.gas(300000).value(msg.value)();
    }
    
    function get_owner() constant returns (address) {
        return owner;
    }
    
}