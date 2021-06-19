/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.5.0;

contract Ownable {
    address private owner;

    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
        
    }

    constructor () internal {
        owner = msg.sender;
    }
}


contract OpinToken is Ownable{
    string public constant name = "OpinToken";
    string public constant symbol = "OPINT";
    uint8 public constant decimals = 1;
    address payable public fundsWallet; 
    
    uint public TotalSupply = 10000000;
    
    mapping (address => uint) public balances;
    
    mapping (address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    

    
    function emission(address to, uint value) onlyOwner public {
        require(TotalSupply + value >= TotalSupply && balances[to] + value >= balances[to]);
        balances[to] += value;
        TotalSupply += value;
    }
    
    // function allocation(address this, address owner) onlyOwner public payable   {
      //  balances[this] = 9000000;
      //  TotalSupply -= 9000000;
        
        
    //}
    
    
    
    
    
    
    function allowance(address _owner, address _spender) public view returns(uint){
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    
    
    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to , _value);
    }
    
     function transferFrom(address _from, address _to, uint _value) public {
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to , _value);
        
    }
    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
    }
    

    
    function MakeICO() onlyOwner public{
        balances[msg.sender] = 10000000;                               
        fundsWallet = msg.sender;                                    
    }
    
    function ICOballance() public view returns(uint){
        
        return balances[fundsWallet];
    }
    
    
    
    function sell() external payable{
        require(balances[fundsWallet] > 0);
        uint tokens = 1000 * msg.value / 1000000000000000000;
        if (tokens > balances[fundsWallet]){
            tokens = balances[fundsWallet];
            uint Wei = tokens * 1000000000000000000 / 1000;
            msg.sender.transfer(msg.value - Wei);
        }
        require (tokens > 0 && tokens < balances[fundsWallet]);
        balances[msg.sender] += tokens;
        balances[fundsWallet] -= tokens;
        
        emit Transfer(fundsWallet, msg.sender, tokens);
        
        fundsWallet.transfer(msg.value);
    }

    
  

   
    
}