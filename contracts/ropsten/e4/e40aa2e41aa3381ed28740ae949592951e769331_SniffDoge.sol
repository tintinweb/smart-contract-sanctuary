/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.5.0;

contract SniffDoge {
    
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
    }
    
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    
    uint8 decimal_;
    function decimals() public view returns (uint8) {
        // 10**18 wei = 1 ether, eth can have 18 places of decimal, 
        // 1 wei = 0.000000000000000001 eth.
        return decimal_;
    }


    

    uint256 tsupply;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    
    mapping ( address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
        /*
        a = a+1 ; // if old value of a = 10 , new value is 10+1 = 11.
        a += 1;
        
        b = b - 10 ; // If old value of b = 100, new value is 100 - 10 = 90.
        b -= 10;
        */
        
    }
    
    


}