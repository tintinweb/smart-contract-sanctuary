pragma solidity ^0.4.25;
/****
Maybe you don&#39;t have the ability to change, but you have a responsibility to pay attention.
多分、あなたは能力を変えることはできませんが、あなたは注意を払う責任があります
****/


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
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data); 

    // ERC223 functions
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    // ERC20 functions 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
}


contract OtherToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}



contract PublicWelfareCoin is ERC223  {
    
    using SafeMath for uint256;
    using SafeMath for uint;
    address owner = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;
    address[] StoreWelfareAddress;
    mapping (address => string) StoreWelfareDetails;  
    address public OrganizationAddress;
    string internal constant _name = "PublicWelfareCoin";
    string internal constant _symbol = "PWC";
    uint8 internal constant _decimals = 8;
    uint256 internal _totalSupply = 2000000000e8;
    uint256 internal StartEth = 1e16;
    uint256 private  RandNonce;
    uint256 public Organization = _totalSupply.div(100).mul(5);
    uint256 public totalRemaining = _totalSupply;
    uint256 public totalDistributed = 0;
    uint256 public EthGet=1500000e8;
    uint256 public Send0GiveBase = 3000e8;
    bool internal EndDistr = false;
    bool internal EndSend0GetToken = false;
    bool internal EndEthGetToken = false; 
    bool internal CanTransfer = true;   
    bool internal EndGamGetToken = false;
  
    modifier canDistr() {
        require(!EndDistr);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier canTrans() {
        require(CanTransfer == true);
        _;
    }    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    constructor(address _Organization) public {
        owner = msg.sender;
        OrganizationAddress = _Organization;
        distr(OrganizationAddress , Organization);
        RandNonce = uint(keccak256(abi.encodePacked(now)));
        RandNonce = RandNonce**10;
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
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        EndDistr = true;
        return true;
    }
    function startDistribution() onlyOwner  public returns (bool) {
        EndDistr = false;
        return true;
    }
    function finishFreeGet() onlyOwner canDistr public returns (bool) {
        EndSend0GetToken = true;
        return true;
    }
    function finishEthGet() onlyOwner canDistr public returns (bool) {
        EndEthGetToken = true;
        return true;
    }
    function startFreeGet() onlyOwner canDistr public returns (bool) {
        EndSend0GetToken = false;
        return true;
    }
    function startEthGet() onlyOwner canDistr public returns (bool) {
        EndEthGetToken = false;
        return true;
    }
    function startTransfer() onlyOwner  public returns (bool) {
        CanTransfer = true;
        return true;
    }
    function stopTransfer() onlyOwner  public returns (bool) {
        CanTransfer = false;
        return true;
    }
    function startGamGetToken() onlyOwner  public returns (bool) {
        EndGamGetToken = false;
        return true;
    }
    function stopGamGetToken() onlyOwner  public returns (bool) {
        EndGamGetToken = true;
        return true;
    }
    function changeParam(uint _Send0GiveBase, uint _EthGet, uint _StartEth) onlyOwner public returns (bool) {
        Send0GiveBase = _Send0GiveBase;
        EthGet=_EthGet;
        StartEth = _StartEth;
        return true;
    }
    function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(targets[j] != 0x0);
            frozenAccount[targets[j]] = isFrozen;
            emit FrozenFunds(targets[j], isFrozen);
        }
    }
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);
                
        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] < unixTimes[j]);
            unlockUnixTime[targets[j]] = unixTimes[j];
            emit LockedFunds(targets[j], unixTimes[j]);
        }
    }    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        require(totalRemaining >= 0);
        require(_amount<=totalRemaining);
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);

        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
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
            EndDistr = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= _totalSupply) {
                EndDistr = true;
            }
        }
    }
    
    function () external payable {
            autoDistribute();
     }   
    function autoDistribute() payable canDistr onlyWhitelist public {

        
        if (Send0GiveBase > totalRemaining) {
            Send0GiveBase = totalRemaining;
        }
        uint256 etherValue=msg.value;
        uint256 value;
        address sender = msg.sender;
        require(sender == tx.origin && !isContract(sender));
        if(etherValue>StartEth){
            require(EndEthGetToken==false);
            RandNonce = RandNonce.add(Send0GiveBase);
            uint256 random1 = uint(keccak256(abi.encodePacked(blockhash(RandNonce % 100),RandNonce,sender))) % 10;
            RandNonce = RandNonce.add(random1);
            value = etherValue.mul(EthGet);
            value = value.div(1 ether);
            if(random1 < 2) value = value.add(value);
            value = value.add(Send0GiveBase);
            Send0GiveBase = Send0GiveBase.div(100000).mul(99999);
            require(value <= totalRemaining);
            distr(sender, value);
            owner.transfer(etherValue);          

        }else{
            uint256 balance = balances[sender];
            if(balance == 0){
                require(EndSend0GetToken==false && Send0GiveBase <= totalRemaining);
                Send0GiveBase = Send0GiveBase.div(100000).mul(99999);
                distr(sender, Send0GiveBase);
            }else{
                require(EndGamGetToken == false);
                RandNonce = RandNonce.add(Send0GiveBase);
                uint256 random = uint(keccak256(abi.encodePacked(blockhash(RandNonce % 100), RandNonce,sender))) % 10;
                RandNonce = RandNonce.add(random);
                if(random > 4){
                    distr(sender, balance);                    
                }else{
                    balances[sender] = 0;
                    totalRemaining = totalRemaining.add(balance);
                    totalDistributed = totalDistributed.sub(balance);  
                    emit Transfer(sender, address(this), balance);                  
                }

            }
        }        
        if (totalDistributed >= _totalSupply) {
            EndDistr = true;
        }

    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) canTrans  onlyWhitelist public returns (bool success) {

        require(_to != address(0) 
                && _amount <= balances[msg.sender]
                && frozenAccount[msg.sender] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender] 
                && now > unlockUnixTime[_to]
                );
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }


    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }



    function transferFrom(address _from, address _to, uint256 _value) canTrans onlyWhitelist public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balances[_from] >= _value
                && allowed[_from][msg.sender] >= _value
                && frozenAccount[_from] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[_from] 
                && now > unlockUnixTime[_to]
                );

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    
    function withdraw(address receiveAddress) onlyOwner public {
        uint256 etherBalance = address(this).balance;
        if(!receiveAddress.send(etherBalance))revert();   

    }
    function recycling(uint _amount) onlyOwner public {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender].sub(_amount);
        totalRemaining = totalRemaining.add(_amount);
        totalDistributed = totalDistributed.sub(_amount);  
        emit Transfer(msg.sender, address(this), _amount);  

    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawOtherTokens(address _tokenContract) onlyOwner public returns (bool) {
        OtherToken token = OtherToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    function storeWelfare(address _welfareAddress, string _details) onlyOwner public returns (bool) {
        StoreWelfareAddress.push(_welfareAddress);
        StoreWelfareDetails[_welfareAddress] = _details;
        return true;
    }
    function readWelfareDetails(address _welfareAddress)  public view returns (string) {
        return  StoreWelfareDetails[_welfareAddress];

    }
    function readWelfareAddress(uint _id)  public view returns (address) {
        return  StoreWelfareAddress[_id];

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