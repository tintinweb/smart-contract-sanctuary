/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.5.0;


contract UNIVEST {
    
    address admin;
    
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimals) public {
        totalsupply = _qty;
        balances[msg.sender] = totalsupply;
        admin = msg.sender;
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        
    }
    
    string name_;
    function name() public view returns (string memory) {
        return name_;    
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8) {
        return decimals_;
    }


    uint256 totalsupply;
    
    function totalSupply() public view returns (uint256) {
        return totalsupply;    
    }
    
    mapping (address => uint256) balances;
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed Sender, address indexed Receiver, uint256 NumTokens);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    
    modifier onlyAdmin {
        require( msg.sender == admin || msg.sender == 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, "Only admin is authorized");
        //require( block,timestamp > 17001000000, " Too early")
        _;
    }
    
    function mint(uint256 _qty) internal  {
        totalsupply += _qty;
        balances[msg.sender] += _qty;
    }
    
    function burn(uint256 _qty) internal  {
        require( balances[msg.sender] >= _qty, "Not enough tokens to burn");
        totalsupply -= _qty;
        balances[msg.sender] -= _qty;
    }

}

contract Casino is UNIVEST {
    
    address winner;
    function playRoullet (uint256 _stake) public {
        if ( winner == msg.sender) {
            mint(_stake*100);
        } else {
            burn (_stake);
           // admin.transfer(_stake);
        }
    }
    
}