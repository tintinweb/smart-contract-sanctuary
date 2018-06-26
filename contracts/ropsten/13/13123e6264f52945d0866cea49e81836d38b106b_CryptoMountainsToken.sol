pragma solidity ^0.4.24;

    contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
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
    if (!assertion) revert();
  }
}

contract Token {
   
    uint256 public totalSupply;
    function balanceOf(address _owner) constant  public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
       
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
       
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CryptoMountainsToken is owned, SafeMath, StandardToken {
    string public name = &quot;CryptoMountainsToken&quot;;                               
    string public symbol = &quot;CMT&quot;;                                      
    address public CMTAddress = this;                            
    uint8 public decimals = 2;                                            
    uint256 public totalSupply = 10000000000000;   
    uint256 public PrezzoCMTacquisto = 1 ether;                               
    uint256 public PrezzoCMTvendita = 0 ether;                               
    uint256 public feeCMT = 0;                                          
    uint256 public RiservaETH = 0.5 ether;                                    
    uint256 public BilancioMinimoAccount = 5 finney;                     
    bool public CassaAutomaticaAccesa = false;                                
    mapping (address => bool) public Negozio;
    mapping (address => bool) public MiningRig;
    mapping (address => bool) public ContoBloccato;
    event Negoziante(address target, bool negozio);
    event Miner(address target, bool miningRig);
    event FondiBloccati(address target, bool bloccati);
   
    constructor() public {
        balances[msg.sender] = totalSupply; 
    }
    function AggiungiNegoziante (address target) onlyOwner public {
        Negozio[target] = true;
        emit Negoziante(target, true);
    }
    function RimuoviNegoziante (address target) onlyOwner public {
        Negozio[target] = false;
        emit Negoziante(target, false);
    }
    function AggiungiMiner (address target) onlyOwner public {
        MiningRig[target] = true;
        emit Miner(target, true);
    }
    function RimuoviMiner (address target) onlyOwner public {
        MiningRig[target] = false;
        emit Miner(target, false);
    }    
    function BloccaConto(address target) onlyOwner public {
        ContoBloccato[target] = true;
        emit FondiBloccati(target, true);
    }
    function SbloccaConto(address target) onlyOwner public {
        ContoBloccato[target] = false;
        emit FondiBloccati(target, false);
    }
    function PrezzoCMT(uint256 NuovoPrezzoCMTacquisto, uint256 NuovoPrezzoCMTvendita) onlyOwner public {
        PrezzoCMTacquisto = NuovoPrezzoCMTacquisto;                                      
        PrezzoCMTvendita = NuovoPrezzoCMTvendita;
    }
    function feeCMT(uint NuovoValoreFee) onlyOwner public {
        feeCMT = NuovoValoreFee;
    }
    function RiservaETH(uint NuovaRiservaETH) onlyOwner public {
        RiservaETH = NuovaRiservaETH;
    }
    function BilancioMinimoAccount(uint BilancioMinimoAccountInWei) onlyOwner public {
        BilancioMinimoAccount = BilancioMinimoAccountInWei;
    }
    function AccendiCassaAutomatica() onlyOwner public {
        CassaAutomaticaAccesa = true;
    }
    function SpegniCassaAutomatica() onlyOwner public {
        CassaAutomaticaAccesa = false;
    }
    function AumentaToken(uint value, address to) onlyOwner public returns (bool) {
    totalSupply = safeAdd(totalSupply, value);
    balances[to] = safeAdd(balances[to], value);
    emit Transfer(0, to, value);
    return true;
    }   

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_value < feeCMT) revert();                                  
        if (msg.sender != owner && _to == CMTAddress && CassaAutomaticaAccesa == true  && MiningRig[msg.sender] != true && ContoBloccato[msg.sender] != true) {
            Vendi(_value);                            
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {              
            balances[msg.sender] = safeSub(balances[msg.sender], _value);  

            if (msg.sender.balance >= BilancioMinimoAccount && _to.balance >= BilancioMinimoAccount && ContoBloccato[msg.sender] != true) {   
                balances[_to] = safeAdd(balances[_to], _value);           
                emit Transfer(msg.sender, _to, _value);                         
                return true;
            } else {
                balances[this] = safeAdd(balances[this], feeCMT);        
                balances[_to] = safeAdd(balances[_to], safeSub(_value, feeCMT));  
                emit Transfer(msg.sender, _to, safeSub(_value, feeCMT));
                require(!ContoBloccato[msg.sender]);
                    if(Negozio[_to] || Negozio[msg.sender] && !ContoBloccato[msg.sender]){
                if(msg.sender.balance < BilancioMinimoAccount) {
                    if(!msg.sender.send(safeSub(BilancioMinimoAccount, msg.sender.balance))) revert();                  
                  }
                if(_to.balance < BilancioMinimoAccount) {
                    if(!_to.send(safeSub(BilancioMinimoAccount, _to.balance))) revert();                         
                }
              }
            }
        } else { revert(); }
    }

    function Compra() payable public returns (uint amount) {
        if (PrezzoCMTacquisto == 0 || msg.value < PrezzoCMTacquisto || ContoBloccato[msg.sender] == true || MiningRig[msg.sender] == true) revert();             
        amount = msg.value / PrezzoCMTacquisto;                                  
        if (balances[this] < amount) revert();                               
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);       
        balances[this] = safeSub(balances[this], amount);                  
        emit Transfer(this, msg.sender, amount);                                
        return amount;
    }

    function Vendi(uint256 amount) public returns (uint revenue) {
        if (PrezzoCMTvendita == 0 || amount < feeCMT || ContoBloccato[msg.sender] == true || MiningRig[msg.sender] == true) revert();               
        if (balances[msg.sender] < amount) revert();                          
        revenue = safeMul(amount, PrezzoCMTvendita);                            
        if (safeSub(this.balance, revenue) < RiservaETH) revert();             
        if (!msg.sender.send(revenue)) {                                   
            revert();                                                     
        } else {
            balances[this] = safeAdd(balances[this], amount);               
            balances[msg.sender] = safeSub(balances[msg.sender], amount);   
            emit Transfer(this, msg.sender, revenue);                         
            return revenue;                                                
        }
    }

    function PrelievoProprietario (uint256 amountOfEth, uint256 CMT) public onlyOwner {
        uint256 eth = safeMul(amountOfEth, 1 ether);
        if (!msg.sender.send(eth)) {                                       
            revert();                                                        
        } else {
            emit Transfer(this, msg.sender, eth);                                
        }
        if (balances[this] < CMT) revert();                                    
        balances[msg.sender] = safeAdd(balances[msg.sender], CMT);          
        balances[this] = safeSub(balances[this], CMT);                     
        emit Transfer(this, msg.sender, CMT);                                   
    }

    function() public payable {
        if (msg.sender != owner && MiningRig[msg.sender] != true && ContoBloccato[msg.sender] != true) {
            if (!CassaAutomaticaAccesa) revert();
            Compra();                              
        }
    }
}