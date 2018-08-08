pragma solidity ^0.4.23;
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;
  
  constructor(){ 
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
  //transfer owner to another address
  function transferOwnership(address _newOwner) onlyOwner {
    if (_newOwner != address(0)) {
      owner = _newOwner;
    }
  }
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
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

contract StandardToken is Token ,SafeMath{

   /**
   *
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {   
     if(msg.data.length != size + 4) {
       revert();
     }
     _;
  }

  //transfer lock flag
  bool transferLock = true;
  //transfer modifier
  modifier canTransfer() {
    if (transferLock) {
      revert();
    }
    _;
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
    
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
  }

   function approve(address _spender, uint256 _value) canTransfer returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract PAIStandardToken is StandardToken,Ownable{

  /* Public variables of the token */

  string public name;                   // name: eg pchain
  uint256 public decimals;              //How many decimals to show.
  string public symbol;                 //An identifier: eg PAI
  address public wallet;                //ETH wallet address
  uint public start;                    //crowd sale start time
  uint public end;                      //Crowd sale first phase end time
  uint public deadline;                 // Crowd sale deadline time


  uint256 public teamShare = 25;        //Team share
  uint256 public foundationShare = 25;  //Foundation share
  uint256 public posShare = 15;         //POS share
  uint256 public saleShare = 35;     //Private share
  
  
  address internal saleAddr;                                 //private sale wallet address
  uint256 public crowdETHTotal = 0;                 //The ETH amount of current crowdsale
  mapping (address => uint256) public crowdETHs;    //record user&#39;s balance of crowdsale
  uint256 public crowdPrice = 10000;                //crowdsale price 1(ETH):10000(PAI)
  uint256 public crowdTarget = 5000 ether;          //The total ETH of crowdsale
  bool public reflectSwitch = false;                // Whether to allow user to reflect PAI
  bool public blacklistSwitch = true;               // Whether to allow owner to set blacklist
  mapping(address => string) public reflects;       // reflect token to PAI address
  

  event PurchaseSuccess(address indexed _addr, uint256 _weiAmount,uint256 _crowdsaleEth,uint256 _balance);
  event EthSweepSuccess(address indexed _addr, uint256 _value);
  event SetReflectSwitchEvent(bool _b);
  event ReflectEvent(address indexed _addr,string _paiAddr);
  event BlacklistEvent(address indexed _addr,uint256 _b);
  event SetTransferLockEvent(bool _b);
  event CloseBlacklistSwitchEvent(bool _b);

  constructor(
      address _wallet,
      uint _s,
      uint _e,
      uint _d,
      address _teamAddr,
      address _fundationAddr,
      address _saleAddr,
      address _posAddr
      ) {
      totalSupply = 2100000000000000000000000000;       // Update total supply
      name = "PCHAIN";                  // Set the name for display purposes
      decimals = 18;           // Amount of decimals for display purposes
      symbol = "PAI";              // Set the symbol for display purposes
      wallet = _wallet;                   // Set ETH wallet address
      start = _s;                         // Set start time for crowsale
      end = _e;                           // Set Crowd sale first phase end time
      deadline = _d;                      // Set Crowd sale deadline time
      saleAddr = _saleAddr; // Set sale account address

      balances[_teamAddr] = safeMul(safeDiv(totalSupply,100),teamShare); //Team balance
      balances[_fundationAddr] = safeMul(safeDiv(totalSupply,100),foundationShare); //Foundation balance
      balances[_posAddr] = safeMul(safeDiv(totalSupply,100),posShare); //POS balance
      balances[_saleAddr] = safeMul(safeDiv(totalSupply,100),saleShare) ; //Sale balance  
      Transfer(address(0), _teamAddr,  balances[_teamAddr]);
      Transfer(address(0), _fundationAddr,  balances[_fundationAddr]);
      Transfer(address(0), _posAddr,  balances[_posAddr]);
      Transfer(address(0), _saleAddr,  balances[_saleAddr]);
  }
  //set transfer lock
  function setTransferLock(bool _lock) onlyOwner{
      transferLock = _lock;
      SetTransferLockEvent(_lock);
  }
  //Permanently turn off the blacklist switch 
  function closeBlacklistSwitch() onlyOwner{
    blacklistSwitch = false;
    CloseBlacklistSwitchEvent(false);
  }
  //set blacklist
  function setBlacklist(address _addr) onlyOwner{
      require(blacklistSwitch);
      uint256 tokenAmount = balances[_addr];             //calculate user token amount
      balances[_addr] = 0;//clear user‘s PAI balance
      balances[saleAddr] = safeAdd(balances[saleAddr],tokenAmount);  //add PAI tokenAmount to Sale
      Transfer(_addr, saleAddr, tokenAmount);
      BlacklistEvent(_addr,tokenAmount);
  } 

  //set reflect switch
  function setReflectSwitch(bool _s) onlyOwner{
      reflectSwitch = _s;
      SetReflectSwitchEvent(_s);
  }
  function reflect(string _paiAddress){
      require(reflectSwitch);
      reflects[msg.sender] = _paiAddress;
      ReflectEvent(msg.sender,_paiAddress);
  }

  function purchase() payable{
      require(block.timestamp <= deadline);                                 //the timestamp must be less than the deadline time
      require(tx.gasprice <= 60000000000);
      require(block.timestamp >= start);                                //the timestamp must be greater than the start time
      uint256 weiAmount = msg.value;                                    // The amount purchased by the current user
      require(weiAmount >= 0.1 ether);
      crowdETHTotal = safeAdd(crowdETHTotal,weiAmount);                 // Calculate the total amount purchased by all users
      require(crowdETHTotal <= crowdTarget);                            // The total amount is less than or equal to the target amount
      uint256 userETHTotal = safeAdd(crowdETHs[msg.sender],weiAmount);  // Calculate the total amount purchased by the current user
      if(block.timestamp <= end){                                       // whether the current timestamp is in the first phase
        require(userETHTotal <= 0.4 ether);                             // whether the total amount purchased by the current user is less than 0.4ETH
      }else{
        require(userETHTotal <= 10 ether);                              // whether the total amount purchased by the current user is less than 10ETH
      }      
      
      crowdETHs[msg.sender] = userETHTotal;                             // Record the total amount purchased by the current user

      uint256 tokenAmount = safeMul(weiAmount,crowdPrice);             //calculate user token amount
      balances[msg.sender] = safeAdd(tokenAmount,balances[msg.sender]);//recharge user‘s PAI balance
      balances[saleAddr] = safeSub(balances[saleAddr],tokenAmount);  //sub PAI tokenAmount from  Sale
      wallet.transfer(weiAmount);
      Transfer(saleAddr, msg.sender, tokenAmount);
      PurchaseSuccess(msg.sender,weiAmount,crowdETHs[msg.sender],tokenAmount); 
  }

  function () payable{
      purchase();
  }
}