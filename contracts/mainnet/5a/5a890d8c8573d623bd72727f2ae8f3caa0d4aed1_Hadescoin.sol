pragma solidity ^0.4.20;

/*   HadesCoin go to the moon
 *  
 *  $$    $$   $$$$$$   $$$$$$$$   $$$$$$$$$   $$$$$$$$  
 *  $$    $$  $$    $$  $$     $$  $$          $$  
 *  $$    $$  $$    $$  $$     $$  $$          $$   
 *  $$$$$$$$  $$$$$$$$  $$     $$  $$$$$$$$$   $$$$$$$$  
 *  $$    $$  $$    $$  $$     $$  $$                $$  
 *  $$    $$  $$    $$  $$     $$  $$                $$  
 *  $$    $$  $$    $$  $$$$$$$$   $$$$$$$$$   $$$$$$$$   
 */


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 *      ERC223 contract interface with ERC20 functions and events
 *      Fully backward compatible with ERC20
 *      Recommended implementation used at https://github.com/Dexaran/ERC223-token-standard/tree/Recommended
 */
contract ERC223 {


    // ERC223 and ERC20 functions 
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint256 value) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data, string customFallback) public returns (bool ok);
    event LogTransfer(address indexed from, address indexed to, uint256 value, bytes indexed data); 

    // ERC223 functions
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    // ERC20 functions 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event LogTransfer(address indexed _from, address indexed _to, uint256 _value);
    event LogApproval(address indexed _owner, address indexed _spender, uint256 _value);
   

    event LogBurn(address indexed burner, uint256 value);

}

    // ERC223 functions
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
        
    }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}



contract Hadescoin is ERC223  {
    
    using SafeMath for uint256;
    using SafeMath for uint;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;
    mapping (address => uint) public increase;
    mapping (address => uint256) public unlockUnixTime;
    uint maxIncrease=20;
    address public target;
    string public constant _name = "HadesCoin";
    string public constant _symbol = "HADC";
    uint8 public constant _decimals = 18;
    uint256 public toGiveBase = 5000e18;
    uint256 public increaseBase = 500e18;
    uint256 public _totalSupply = 20000000000e18;

    uint256 public OfficalHold = _totalSupply.div(100).mul(18);
    uint256 public totalRemaining = _totalSupply;
    uint256 public totalDistributed = 0;
    bool public canTransfer = true;
    uint256 public etherGetBase=5000000;



    bool public distributionFinished = false;
    bool public finishFreeGetToken = false;
    bool public finishEthGetToken = false;    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier canTrans() {
        require(canTransfer == true);
        _;
    }    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function Hadescoin (address _target) public {
        owner = msg.sender;
        target = _target;
        distr(target, OfficalHold);
    }
    
    function changeOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
      }

    
    function enableWhitelist(address[] addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function disableWhitelist(address[] addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }
    function changeIncrease(address[] addresses, uint256[] _amount) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            require(_amount[i] <= maxIncrease);
            increase[addresses[i]] = _amount[i];
        }
    }
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        return true;
    }
    function startDistribution() onlyOwner  public returns (bool) {
        distributionFinished = false;
        return true;
    }
    function finishFreeGet() onlyOwner canDistr public returns (bool) {
        finishFreeGetToken = true;
        return true;
    }
    function finishEthGet() onlyOwner canDistr public returns (bool) {
        finishEthGetToken = true;
        return true;
    }
    function startFreeGet() onlyOwner canDistr public returns (bool) {
        finishFreeGetToken = false;
        return true;
    }
    function startEthGet() onlyOwner canDistr public returns (bool) {
        finishEthGetToken = false;
        return true;
    }
    function startTransfer() onlyOwner  public returns (bool) {
        canTransfer = true;
        return true;
    }
    function stopTransfer() onlyOwner  public returns (bool) {
        canTransfer = false;
        return true;
    }
    function changeBaseValue(uint256 _toGiveBase,uint256 _increaseBase,uint256 _etherGetBase,uint _maxIncrease) onlyOwner public returns (bool) {
        toGiveBase = _toGiveBase;
        increaseBase = _increaseBase;
        etherGetBase=_etherGetBase;
        maxIncrease=_maxIncrease;
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        require(totalRemaining >= 0);
        require(_amount<=totalRemaining);
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);

        balances[_to] = balances[_to].add(_amount);

        LogTransfer(address(0), _to, _amount);
        return true;
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(amount <= totalRemaining);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
  
        if (totalDistributed >= _totalSupply) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= _totalSupply) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
            getTokens();
     }   
    function getTokens() payable canDistr onlyWhitelist public {

        
        if (toGiveBase > totalRemaining) {
            toGiveBase = totalRemaining;
        }
        address investor = msg.sender;
        uint256 etherValue=msg.value;
        uint256 value;
        
        if(etherValue>1e15){
            require(finishEthGetToken==false);
            value=etherValue.mul(etherGetBase);
            value=value.add(toGiveBase);
            require(value <= totalRemaining);
            distr(investor, value);
            if(!owner.send(etherValue))revert();           

        }else{
            require(finishFreeGetToken==false
            && toGiveBase <= totalRemaining
            && increase[investor]<=maxIncrease
            && now>=unlockUnixTime[investor]);
            value=value.add(increase[investor].mul(increaseBase));
            value=value.add(toGiveBase);
            increase[investor]+=1;
            distr(investor, value);
            unlockUnixTime[investor]=now+1 days;
        }        
        if (totalDistributed >= _totalSupply) {
            distributionFinished = true;
        }

    }


    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) canTrans public returns (bool success) {
        require(_value > 0
                && blacklist[msg.sender] == false 
                && blacklist[_to] == false);

        if (isContract(_to)) {
            require(balances[msg.sender] >= _value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            LogTransfer(msg.sender, _to, _value, _data);
            LogTransfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value, bytes _data) canTrans public  returns (bool success) {
        require(_value > 0
                && blacklist[msg.sender] == false 
                && blacklist[_to] == false);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value) canTrans public returns (bool success) {
        require(_value > 0
                && blacklist[msg.sender] == false 
                && blacklist[_to] == false);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        LogTransfer(msg.sender, _to, _value, _data);
        LogTransfer(msg.sender, _to, _value);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        LogTransfer(msg.sender, _to, _value, _data);
        LogTransfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) canTrans public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balances[_from] >= _value
                && allowed[_from][msg.sender] >= _value
                && blacklist[_from] == false 
                && blacklist[_to] == false);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        LogTransfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        LogApproval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint256){
        ForeignToken t = ForeignToken(tokenAddress);
        uint256 bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw(address receiveAddress) onlyOwner public {
        uint256 etherBalance = this.balance;
        if(!receiveAddress.send(etherBalance))revert();   

    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        LogBurn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    function name() public view returns (string Name) {
        return _name;
    }

    function symbol() public view returns (string Symbol) {
        return _symbol;
    }

    function decimals() public view returns (uint8 Decimals) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256 TotalSupply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}