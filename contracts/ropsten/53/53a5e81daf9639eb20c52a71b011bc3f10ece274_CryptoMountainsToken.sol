pragma solidity ^0.4.8;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner == 0x0) throw;
        owner = newOwner;
    }
}

contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Token {
   
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
       
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
       
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CryptoMountainsToken is owned, SafeMath, StandardToken {
    string public name = "CryptoMountainsToken";                               
    string public symbol = "CMT";                                      
    address public CMTAddress = this;                            
    uint8 public decimals = 2;                                            
    uint256 public totalSupply = 10000000000000;                           
    uint256 public buyPriceEth = 1 ether;                                  // Buy price for Dentacoins
    uint256 public sellPriceEth = 0 ether;                                 // Sell price for Dentacoins
    uint256 public gasForCMT = 5 finney;                                    // Eth from contract against DCN to pay tx (10 times sellPriceEth)
    uint256 public CMTForGas = 0;                                           // DCN to contract against eth to pay tx
    uint256 public gasReserve = 0.5 ether;                                    // Eth amount that remains in the contract for gas and can&#39;t be sold
    uint256 public minBalanceForAccounts = 5 finney;                       // Minimal eth balance of sender and recipient
    bool public directTradeAllowed = false;                                 // Halt trading DCN by sending to the contract directly

    function CryptoMountainsToken() {
        balances[msg.sender] = totalSupply;                                 
    }

    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) onlyOwner {
        buyPriceEth = newBuyPriceEth;                                      
        sellPriceEth = newSellPriceEth;
    }
    function setGasForCMT(uint newGasAmountInWei) onlyOwner {
        gasForCMT = newGasAmountInWei;
    }
    function setCMTForGas(uint newDCNAmount) onlyOwner {
        CMTForGas = newDCNAmount;
    }
    function setGasReserve(uint newGasReserveInWei) onlyOwner {
        gasReserve = newGasReserveInWei;
    }
    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }
    function haltDirectTrade() onlyOwner {
        directTradeAllowed = false;
    }
    function unhaltDirectTrade() onlyOwner {
        directTradeAllowed = true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value < CMTForGas) throw;                                  
        if (msg.sender != owner && _to == CMTAddress && directTradeAllowed) {
            sellCMTAgainstEther(_value);                            
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {              
            balances[msg.sender] = safeSub(balances[msg.sender], _value);  

            if (msg.sender.balance >= minBalanceForAccounts && _to.balance >= minBalanceForAccounts) {   
                balances[_to] = safeAdd(balances[_to], _value);           
                Transfer(msg.sender, _to, _value);                         
                return true;
            } else {
                balances[this] = safeAdd(balances[this], CMTForGas);        
                balances[_to] = safeAdd(balances[_to], safeSub(_value, CMTForGas));  
                Transfer(msg.sender, _to, safeSub(_value, CMTForGas));     

                if(msg.sender.balance < minBalanceForAccounts) {
                    if(!msg.sender.send(gasForCMT)) throw;                  
                  }
                if(_to.balance < minBalanceForAccounts) {
                    if(!_to.send(gasForCMT)) throw;                         
                }
            }
        } else { throw; }
    }

    function buyCMTAgainstEther() payable returns (uint amount) {
        if (buyPriceEth == 0 || msg.value < buyPriceEth) throw;             
        amount = msg.value / buyPriceEth;                                  
        if (balances[this] < amount) throw;                               
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);       
        balances[this] = safeSub(balances[this], amount);                  
        Transfer(this, msg.sender, amount);                                
        return amount;
    }

    function sellCMTAgainstEther(uint256 amount) returns (uint revenue) {
        if (sellPriceEth == 0 || amount < CMTForGas) throw;               
        if (balances[msg.sender] < amount) throw;                          
        revenue = safeMul(amount, sellPriceEth);                            
        if (safeSub(this.balance, revenue) < gasReserve) throw;             
        if (!msg.sender.send(revenue)) {                                   
            throw;                                                     
        } else {
            balances[this] = safeAdd(balances[this], amount);               // Add the amount to Dentacoin balance
            balances[msg.sender] = safeSub(balances[msg.sender], amount);   // Subtract the amount from seller&#39;s balance
            Transfer(this, msg.sender, revenue);                            // Execute an event reflecting on the change
            return revenue;                                                 // End function and returns
        }
    }

    function refundToOwner (uint256 amountOfEth, uint256 CMT) onlyOwner {
        uint256 eth = safeMul(amountOfEth, 1 ether);
        if (!msg.sender.send(eth)) {                                        // Send ether to the owner. It&#39;s important
            throw;                                                          // To do this last to avoid recursion attacks
        } else {
            Transfer(this, msg.sender, eth);                                
        }
        if (balances[this] < CMT) throw;                                    
        balances[msg.sender] = safeAdd(balances[msg.sender], CMT);          
        balances[this] = safeSub(balances[this], CMT);                     
        Transfer(this, msg.sender, CMT);                                   
    }

    function() payable {
        if (msg.sender != owner) {
            if (!directTradeAllowed) throw;
            buyCMTAgainstEther();                              
        }
    }
}