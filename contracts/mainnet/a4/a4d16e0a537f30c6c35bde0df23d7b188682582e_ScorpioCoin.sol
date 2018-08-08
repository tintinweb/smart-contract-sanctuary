pragma solidity ^0.4.20;
//http://scorpio.network/

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
    function balanceOf(address who) public view returns (uint);

    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);

    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
}


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
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}



contract ScorpioCoin is ERC223  {
    
    using SafeMath for uint256;
    using SafeMath for uint;
    address public owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;
    uint256 public etherGet=60000;
    uint256 internal EthLevel=1e18;
    uint256 internal EthValueBase=1e18;
    mapping (address => uint256) public lockTime;
    address public target;
    string internal Name= "ScorpioCoin";
    string internal Symbol = "SPC";
    uint8 internal Decimals= 18;
    uint256 internal Total= 2000000000e18;

    uint256 public officalHolding = Total.mul(50).div(100);
    uint256 public totalRemaining = Total;
    uint256 public totalDistributed = 0;
    bool public canTransfer = true;
    uint256 internal Proportion1=20;
    uint256 internal Proportion2=25;
    uint256 internal Proportion1EthBase=5;
    uint256 internal Proportion2EthBase=50;
    bool public endPreSale=false;
    bool public distributionFinished = false;
    bool public endEthGet = false;    
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
    modifier notLockTrans() {
        require(now>lockTime[msg.sender]);
        _;
    }    
    function ScorpioCoin (address _target) public {
        owner = msg.sender;
        target = _target;
        distr(target, officalHolding);
    }

    // Function to access name of token .
    function name() public view returns (string _name) {
      return Name;
    }
    // Function to access symbol of token .
    function symbol() public view returns (string _symbol) {
      return Symbol;
    }
    // Function to access decimals of token .
    function decimals() public view returns (uint8 _decimals) {
      return Decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint256 _totalSupply) {
      return Total;
    }


    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) canTrans notLockTrans public returns (bool success) {
      
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
    }


    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) canTrans notLockTrans public returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) canTrans notLockTrans public returns (bool success) {
      
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
    }


    function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
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

    function finishDistribution() onlyOwner  public returns (bool) {
        distributionFinished = true;
        return true;
    }
    function startDistribution() onlyOwner  public returns (bool) {
        distributionFinished = false;
        return true;
    }

    function endEthGetToken() onlyOwner  public returns (bool) {
        endEthGet = true;
        return true;
    }

    function startEthGetToken() onlyOwner  public returns (bool) {
        endEthGet = false;
        return true;
    }
    function EndPreSale() onlyOwner  public returns (bool) {
        endPreSale = true;
        return true;
    }

    function StartPreSale() onlyOwner  public returns (bool) {
        endPreSale = false;
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

    function changeBaseValue(uint256 EthLevel_,uint256 etherGet_,uint256 Proportion1_,uint256 Proportion2_,uint256 Proportion1EthBase_,uint256 Proportion2EthBase_) onlyOwner public returns (bool) {
        EthLevel=EthLevel_;
        etherGet=etherGet_;
        Proportion1=Proportion1_;
        Proportion2=Proportion2_;
        Proportion1EthBase=Proportion1EthBase_;
        Proportion2EthBase=Proportion2EthBase_;
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        require(totalRemaining >= 0);
        require(_amount<=totalRemaining);
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);

        balances[_to] = balances[_to].add(_amount);

        Transfer(address(0), _to, _amount);
        return true;
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(amount <= totalRemaining);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
  
        if (totalDistributed >= Total) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= Total) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
            getTokens();
     }   
    function getTokens() payable canDistr onlyWhitelist public {


        address sender = msg.sender;
        uint256 etherValue=msg.value;
        uint256 value;
        uint256 tempvalue;
        require(endEthGet==false);
        if(endPreSale==false){
            if(etherValue>=Proportion2EthBase.mul(EthValueBase)){
               value=etherValue.mul(etherGet);
               value=value+value.mul(Proportion2).div(100);  
            }else if(etherValue>=Proportion1EthBase.mul(EthValueBase)){
               value=etherValue.mul(etherGet);
               value=value+value.mul(Proportion1).div(100);
            }else{
                revert();
            }
        }else{
            require(etherValue>=EthLevel);
            value=etherValue.mul(etherGet);   
        }

         
          
        require(value <= totalRemaining);
        if(!owner.send(etherValue))revert();           
        distr(sender, value);
     
        if (totalDistributed >= Total) {
            endEthGet=true;
            distributionFinished = true;
        }

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
        Transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
        Total = Total.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}