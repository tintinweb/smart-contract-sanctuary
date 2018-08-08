pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
// ================= ERC20 Token Contract start =========================
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool status);
  function transferFrom(address from, address to, uint value) public returns (bool status);
  function approve(address spender, uint value) public returns (bool status);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}








/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}








contract StandardToken is ERC20{
  
   /*Define SafeMath library here for uint256*/
   
   using SafeMath for uint256; 
       
  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint) accountBalances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32)  returns (bool success){
    accountBalances[msg.sender] = accountBalances[msg.sender].sub(_value);
    accountBalances[_to] = accountBalances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    accountBalances[_to] = accountBalances[_to].add(_value);
    accountBalances[_from] = accountBalances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return accountBalances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}



contract IcoToken is StandardToken, Pausable{
    /*define SafeMath library for uint256*/
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    string public version;
    uint public decimals;
    address public icoSaleDeposit;
    address public icoContract;
    
    constructor(string _name, string _symbol, uint256 _decimals, string _version) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        version = _version;
    }
    
    function transfer(address _to, uint _value) public whenNotPaused returns (bool success) {
        return super.transfer(_to,_value);
    }
    
    function approve(address _spender, uint _value) public whenNotPaused returns (bool success) {
        return super.approve(_spender,_value);
    }
    
    function balanceOf(address _owner) public view returns (uint balance){
        return super.balanceOf(_owner);
    }
    
    function setIcoContract(address _icoContract) public onlyOwner {
        if(_icoContract != address(0)){
            icoContract = _icoContract;           
        }
    }
    
    function sell(address _recipient, uint256 _value) public whenNotPaused returns (bool success){
        assert(_value > 0);
        require(msg.sender == icoContract);
        
        accountBalances[_recipient] = accountBalances[_recipient].add(_value);
        totalSupply = totalSupply.add(_value);
        
        emit Transfer(0x0,owner,_value);
        emit Transfer(owner,_recipient,_value);
        return true;
    }
    
}    

contract IcoContract is Pausable{
    /*define SafeMath library for uint256*/
    using SafeMath for uint256;
    IcoToken public ico ;
    uint256 public tokenCreationCap;
    uint256 public totalSupply;
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public minContribution;
    uint256 public tokenExchangeRate;
    
    address public ethFundDeposit;
    address public icoAddress;
    
    bool public isFinalized;
    
    event LogCreateICO(address from, address to, uint256 val);
    
    function CreateIco(address to, uint256 val) internal returns (bool success) {
        emit LogCreateICO(0x0,to,val);
        return ico.sell(to,val);/*call to IcoToken sell() method*/
    }
    
    constructor(address _ethFundDeposit,
                address _icoAddress,
                uint256 _tokenCreationCap,
                uint256 _tokenExchangeRate,
                uint256 _fundingStartTime,
                uint256 _fundingEndTime,
                uint256 _minContribution) public {
        ethFundDeposit = _ethFundDeposit;
        icoAddress = _icoAddress;
        tokenCreationCap = _tokenCreationCap;
        tokenExchangeRate = _tokenExchangeRate;
        fundingStartTime = _fundingStartTime;
        minContribution = _minContribution;
        fundingEndTime = _fundingEndTime;
        ico = IcoToken(icoAddress);
        isFinalized = false;
    }
    
    /*call fallback method*/
    function () public payable{
        createTokens(msg.sender,msg.value);
    }
    
    function createTokens(address _beneficiary,uint256 _value) internal whenNotPaused {
        require(tokenCreationCap > totalSupply);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minContribution);
        require(!isFinalized);
        
        uint256 tokens = _value.mul(tokenExchangeRate);
        uint256 checkSupply = totalSupply.add(tokens);
        
        if(tokenCreationCap < checkSupply){
            uint256 tokenToAllocate = tokenCreationCap.sub(totalSupply);
            uint256 tokenToRefund = tokens.sub(tokenToAllocate);
            uint256 etherToRefund = tokenToRefund / tokenExchangeRate;
            totalSupply = tokenCreationCap;
            
            require(CreateIco(_beneficiary,tokenToAllocate));
            msg.sender.transfer(etherToRefund);
            ethFundDeposit.transfer(address(this).balance);
            return;
        }
        
        totalSupply = checkSupply;
        require(CreateIco(_beneficiary,tokens));
        ethFundDeposit.transfer(address(this).balance);
    }
    
    function finalize() external onlyOwner{
        require(!isFinalized);
        isFinalized = true;
        ethFundDeposit.transfer(address(this).balance);
    }
}