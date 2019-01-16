pragma solidity ^0.4.25;

contract Ownable {
  address public owner;
  address public admin;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    admin = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(msg.sender == owner||msg.sender == admin);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    //emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
    /**
    * @dev prevents contracts from interacting with others
    */
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
}

contract TokenBankEvents{
    
        
 }

contract TokenBankSimple is Ownable,TokenBankEvents{
    using SafeMath for uint;
    using inArrayExt for address[];
    using intArrayExt for uint[];
    
    bool public status=true;

    struct ReserverdTokens{
        uint index;
        address ctAddr;
        address userAddr;
        uint value;
    }

    struct LockedRecords{
        uint lastLockedTime;
        uint lastLockValue;
    }
    
    /* System */
    address[] public acceptTokens;
    address[] allowDAppContracts;
    
    mapping(address=>uint) sysBalances;          //player address=>token contract => available amount
    uint totalLocked;
    uint lockedUint=7000;
    
    
    mapping(address=>address) tokenAdmin;
    mapping(address=>uint) balancesReserved;    //player address=>token contract => reserved amount
    
    ReserverdTokens[] reserveTokens;
    
    uint tokenCount=0;
    
    /* User */
    mapping(address=>uint) balances;          //player address=>token contract => available amount
    mapping(address=>uint) balancesLocked;    //player address=>token contract => locked amount
    mapping(address=>LockedRecords) UserlockedRecords;
    mapping(address=>uint) lockSubtotal;                        //contract address=> total locked amount;

    /*
    ===========================================
    CONSTRUCTOR
    ===========================================
    */
    constructor() public{

    
    }
    
    function balance(address tokenContract)public view returns(uint){
        /* return 0:balance,1:balance locked */
        StandardToken token=StandardToken(tokenContract);
        
        return token.balanceOf(this);
    }
    
    function balanceOf(address addr) public view returns(uint){
        /* return 0:balance,1:balance locked */
        return(balances[addr]);
    }

    function addTokenAdmin(address contractAddress,address admin) public onlyAdmin returns(bool){
        tokenAdmin[contractAddress]=admin;
    }
    
    /* Allowed DAPP Contract */
    
    function addDAppContract(address dappContract) public onlyAdmin returns(bool){
        if(!allowDAppContracts.contain(dappContract)){
            allowDAppContracts.push(dappContract);
            return true;
        }
        return false;
    }

    /* ************ Enable/Disable ERC20  *****************    */
    function lockTokens(address addr,uint value,bool isLock) internal{
        if(isLock){
            if(value <= balances[msg.sender]){revert();}
        }else{
            if(value <= balancesLocked[msg.sender]){revert();}
        }
        
        
        if(isLock){
            balances[addr]=balances[addr].sub(value);
            balancesLocked[addr]=balancesLocked[addr].add(value);
        }else{
            balancesLocked[addr]=balancesLocked[addr].sub(value);
            balancesReserved[addr]=balancesReserved[addr].add(value);
        }
    }
    
    
    function updateBalances() public{
        /* for user dividend */
        
        /*
        balances[msg.sender]=
        
        LockedTokens
        uint lastLockedTime;
        uint lastLockValue;
        */
    }

    
    function withdraw(address ctAddr,address _from,address _to,uint amount) public onlyAdmin returns(bool){
        require(balances[msg.sender] - amount >= 0);
        
        StandardToken token=StandardToken(ctAddr);
        token.transfer(_to,amount);
    }

    /* ************ ERC20  *****************    */
    function addERC20Token(address ctAddr) public onlyAdmin{
        if(!acceptTokens.contain(ctAddr)){
            acceptTokens.push(ctAddr);
            tokenCount = tokenCount.add(1);    
        }
    }

    function distribute(uint _p) public onlyOwner isHuman(){
        
    }

    
    /*************** Interact with token *********************/
    function transferToken(address _from,address _to, uint _value) public onlyOwner{
        require(acceptTokens.contain(msg.sender));
        require(balances[_from].sub(_value)>=0);
        
        StandardToken token=StandardToken(msg.sender);
        token.transfer(_to,_value);    

    }

    function tokenFallback(address _from, uint _value, bytes _data)public returns(bool){
        sysBalances[msg.sender] = sysBalances[msg.sender].add(_value);
        balances[_from] = balances[_from].add(_value);
        return true;
    }
    
    function() payable isHuman() public {
        
    }
    
}

contract StandardToken{
    function balanceOf(address who) public view returns (uint);
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value)  public returns(bool ok);
}



/*
=====================================================
Library
=====================================================
*/


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

library inArrayExt{
    function contain(address[] _arr,address _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}

library intArrayExt{
    function contain(uint[] _arr,uint _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}