pragma solidity ^0.4.0;

contract Purus {
    
    mapping (address => uint) public balances;
    uint public totalSupply;
    
    mapping (address => address) public meter_company;
    mapping (address => address) public company_meter;
    
    function transfer(address _to, uint _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        require(balances[_to] + _amount >= balances[_to]);

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        return true;
    }
    
    function register(address _meter, address _company) public {
        require(meter_company[_meter] == 0);
        meter_company[_meter] = _company;
        company_meter[_company] = _meter;
    }
    
    
    
    
    
    /*
    def transfer(_to, _amount):
        if(balances[msg.sender] >= _amount):
          balances[msg.sender] -= _amount
          balances[_to] += _amount
          return True
        else:
          return False
    */
    
    
}