pragma solidity ^0.4.24;
// contract creation
contract TestToken{
    // mapping the owner and balance
    
    mapping(address => uint)balances;
    // it is the event for Transfer
    // declarations 
    address public _owner;
    string public name;
    uint public decimals;
    string public symbol;
    uint totalsupply; // totalsupply
    
    // intializing the tokens 
    function Token() public {
        balances[msg.sender] = 1000;
        name = "TKN";                                 
        decimals = 18;                                          
        symbol = "TKN";
    }// intialize function ends 
    
    // only owner can modify
    modifier onlyOwner{
        require(msg.sender == 0x313a0a8ae2d80f4ba26df69b5b747a72187e8076,"only owner can modify this function");
        _;
    }
    // for update the total supply 
    function changeTotsupp(uint totalsupply) public onlyOwner{
        balances[msg.sender] = balanceOf(0x313a0a8ae2d80f4ba26df69b5b747a72187e8076) + totalsupply;
    }
    event Transfer(address indexed _from,address  indexed _to,uint  _value);
    // To check the token balance of users
    
    function balanceOf(address _owner) public constant returns(uint balance){
        return balances[_owner];
    } // check balance function ends
    
    // Transfer function
    function transfer(address _to,uint _value) public returns(bool success){
        if(balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender,_to,_value);
            return true;
        }
        else {
            return false;
        }
    } // Transfer function ends
    
    
}// contract ends