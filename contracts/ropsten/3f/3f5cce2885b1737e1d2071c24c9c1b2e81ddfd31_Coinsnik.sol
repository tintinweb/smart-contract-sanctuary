pragma solidity ^0.4.25;
contract Coinsnik {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) public allowance;
    address public owner = msg.sender;
    string public name;
    uint public decimals;
    string public symbol;
    constructor(uint initialSupply) payable public{
   
        balances[msg.sender] =initialSupply;
        name = "nikhila";                                   
        decimals = 18;                                          
        symbol = "NIKCN"; 
    }
    
    function increaseTS(uint amount)public onlySeller{
  
        balances[msg.sender]+=amount;
    }
    
    modifier onlySeller() { // Modifier
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }

   function transfer(address _to, uint256 _value) public payable returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer( msg.sender,_to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant public returns (uint256 balance) {
      return balances[_owner];
  }
        

    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


}