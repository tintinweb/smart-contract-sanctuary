pragma solidity ^0.4.2;

//import "./SafeMathLib.sol";
/**
 * Safe unsigned safe math.
 *
 * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
 *
 * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMathLib.sol
 *
 * Maintained here until merged to mainline zeppelin-solidity.
 *
 */
library SafeMathLib {

  function times(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a);
    return c;
  }
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }

}

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public  returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
}



/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  //function assert(bool assertion) internal pure{
  //  require (assertion);
  //}
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
   event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public pure returns (bool weAre) {
    return true;
  }

  /**
   *
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
     //require(msg.data.length < size + 4);
     _;
  }

  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
    require(_value >= 0);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    //requre the alloced greater than _value
    require(_allowance >= _value);
    require(_value >= 0);

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value)public returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}



/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;
  mapping (address => bool) private admins;
  mapping (address => bool) private developers;
  mapping (address => bool) private founds;

  function Ownable()  internal{
    owner = msg.sender;
  }

  modifier onlyAdmins(){
    require(admins[msg.sender]);
    _;
  }

  modifier onlyOwner()  {
    require (msg.sender == owner);
    _;
  }

 function getOwner() view public returns (address){
     return owner;
  }

 function isDeveloper () view internal returns (bool) {
     return developers[msg.sender];
  }

 function isFounder () view internal returns (bool){
     return founds[msg.sender];
  }

  function addDeveloper (address _dev) onlyOwner() public {
    developers[_dev] = true;
  }

  function removeDeveloper (address _dev) onlyOwner() public {
    delete developers[_dev];
  }

    function addFound (address _found) onlyOwner() public {
    founds[_found] = true;
  }

  function removeFound (address _found) onlyOwner() public {
    delete founds[_found];
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

/**
 * Define interface for distrible the token 
 */
contract DistributeToken is StandardToken, Ownable{

  event AirDrop(address from, address to, uint amount);
  event CrowdDistribute(address from, address to, uint amount);

  using SafeMathLib for uint;

  /* The finalizer contract that allows Distribute token */
  address public distAgent;

  uint public maxAirDrop = 1000*10**18;//need below 1000 TTG

  uint public havedAirDrop = 0;
  uint public totalAirDrop = 0; //totalSupply * 5%

  bool public finishCrowdCoin = false;
  uint public havedCrowdCoin = 0;
  uint public totalCrowdCoin = 0; //totalSupply * 50%

  uint public havedDistDevCoin = 0;
  uint public totalDevCoin = 0;  //totalSupply * 20%

  uint public havedDistFoundCoin = 0;
  uint public totalFoundCoin = 0;  //totalSupply * 20%

  /**
   * 0：1：100000；1：1：50000 2：1：25000  3：1：12500  4：1：12500
   */
  uint private crowState = 0;//
  /**
   * .
   */
  function setDistributeAgent(address addr) onlyOwner  public {
     
     require(addr != address(0));

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    distAgent = addr;
  }


  /** The function can be called only by a whitelisted release agent. */
  modifier onlyDistributeAgent() {
    require(msg.sender == distAgent) ;
    _;
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the ETH which remained in the contract account when user call CrowdDistribute
  */
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }

 /**发token给基金会*/
 function distributeToFound(address receiver, uint amount) onlyOwner() public  returns (uint actual){ 
  
    require((amount+havedDistFoundCoin) < totalFoundCoin);
  
    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedDistFoundCoin = havedDistFoundCoin.plus(amount);

    addFound(receiver);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit Transfer(0, receiver, amount);
   
    return amount;
 }

 /**发token给开发者*/
 function  distributeToDev(address receiver, uint amount) onlyOwner()  public  returns (uint actual){

    require((amount+havedDistDevCoin) < totalDevCoin);

    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedDistDevCoin = havedDistDevCoin.plus(amount);

    addDeveloper(receiver);
    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit Transfer(0, receiver, amount);

    return amount;
 }

 /**空投总量及单次量由发行者来控制， agent不能修改，空投接口只能由授权的agent进行*/
 function airDrop(address transmitter, address receiver, uint amount) public  returns (uint actual){

    require(receiver != address(0));
    require(amount <= maxAirDrop);
    require((amount+havedAirDrop) < totalAirDrop);
    require(transmitter == distAgent);

    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    havedAirDrop = havedAirDrop.plus(amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit AirDrop(0, receiver, amount);

    return amount;
  }

 /**用户ICO众筹，由用户发固定的ETH，回馈用户固定的TTG，并添加ICO账户，控制交易规则*/
 function crowdDistribution() payable public  returns (uint actual) {
      
    require(msg.sender != address(0));
    require(!isContract(msg.sender));
    require(msg.value != 0);
    require(totalCrowdCoin > havedCrowdCoin);
    require(finishCrowdCoin == false);
    
    uint actualAmount = calculateCrowdAmount(msg.value);

    require(actualAmount != 0);

    havedCrowdCoin = havedCrowdCoin.plus(actualAmount);
    balances[owner] = balances[owner].sub(actualAmount);
    balances[msg.sender] = balances[msg.sender].plus(actualAmount);
    
    switchCrowdState();
    
    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit CrowdDistribute(0, msg.sender, actualAmount);

    return actualAmount;
  }

 function  switchCrowdState () internal{

    if (havedCrowdCoin < totalCrowdCoin.mul(10).div(100) ){
       crowState = 0;

    }else  if (havedCrowdCoin < totalCrowdCoin.mul(20).div(100) ){
       crowState = 1;
    
    } else if (havedCrowdCoin < totalCrowdCoin.mul(30).div(100) ){
       crowState = 2;

    } else if (havedCrowdCoin < totalCrowdCoin.mul(40).div(100) ){
       crowState = 3;

    } else if (havedCrowdCoin < totalCrowdCoin.mul(50).div(100) ){
       crowState = 4;
    }
      
    if (havedCrowdCoin >= totalCrowdCoin) {
       finishCrowdCoin = true;
  }
 }

function calculateCrowdAmount (uint _price) internal view returns (uint _crow) {
        
    if (crowState == 0) {
      return _price.mul(50000);
    }
    
     else if (crowState == 1) {
      return _price.mul(30000);
    
    } else if (crowState == 2) {
      return  _price.mul(20000);

    } else if (crowState == 3) {
     return  _price.mul(15000);

    } else if (crowState == 4) {
     return  _price.mul(10000);
    }

    return 0;
  }

}

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A TTG contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  uint private maxTransferForDev  = 40000000*10**18;
  uint private maxTransferFoFounds= 20000000*10**18;
  uint private maxTransfer = 0;//other user is not limited.

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender, uint _value) {

    //if owner can Transfer all the time
    if(_sender != owner){
      
      if(isDeveloper()){
        require(_value < maxTransferForDev);

      }else if(isFounder()){
        require(_value < maxTransferFoFounds);

      }else if(maxTransfer != 0){
        require(_value < maxTransfer);
      }

      if(!released) {
          require(transferAgents[_sender]);
      }
     }
    _;
  }


 function setMaxTranferLimit(uint dev, uint found, uint other) onlyOwner  public {

      require(dev < totalSupply);
      require(found < totalSupply);
      require(other < totalSupply);

      maxTransferForDev = dev;
      maxTransferFoFounds = found;
      maxTransfer = other;
  }


  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender,_value) returns (bool success)  {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from,_value) returns (bool success)  {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

contract RecycleToken is StandardToken, Ownable {

  using SafeMathLib for uint;

  /**
   * recycle user token to owner account
   * 
   */
  function recycle(address from, uint amount) onlyAdmins public {
  
    require(from != address(0));
    require(balances[from] >=  amount);

    balances[owner] = balances[owner].add(amount);
    balances[from]  = balances[from].sub(amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit Transfer(from, owner, amount);
  }

}


/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
contract MintableToken is StandardToken, Ownable {

  using SafeMathLib for uint;

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent). 
   */
  function mint(address receiver, uint amount) onlyMintAgent canMint public {

    //totalsupply is not changed, send amount TTG to receiver from owner account.
    balances[owner] = balances[owner].sub(amount);
    balances[receiver] = balances[receiver].plus(amount);
    
    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit Transfer(0, receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    _;
  }

  function enableMint() onlyOwner public {
    mintingFinished = false;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}



/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract TTGCoin is ReleasableToken, MintableToken , DistributeToken, RecycleToken{

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   */
  function TTGCoin() public {
    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    owner = msg.sender;

    addAdmin(owner);

    name  = "TotalGame Coin";
    symbol = "TGC";
    totalSupply = 2000000000*10**18;
    decimals = 18;

    // Create initially all balance on the team multisig
    balances[msg.sender] = totalSupply;

    //Mint feature is not allow  now
    mintingFinished = true;

    //Set the distribute totaltoken strategy
    totalAirDrop = totalSupply.mul(10).div(100);
    totalCrowdCoin = totalSupply.mul(50).div(100);
    totalDevCoin = totalSupply.mul(20).div(100);
    totalFoundCoin = totalSupply.mul(20).div(100);

    emit Minted(owner, totalSupply);
  }


  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    super.releaseTokenTransfer();
  }

  /**
   * Owner can update token information here.
   *
   * It is often useful to conceal the actual token association, until
   * the token operations, like central issuance or reissuance have been completed.
   *
   * This function allows the token owner to rename the token after the operations
   * have been completed and then point the audience to use the token contract.
   */
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    emit UpdatedTokenInformation(name, symbol);
  }

  function getTotalSupply() public view returns (uint) {
    return totalSupply;
  }

  function tokenName() public view returns (string _name) {
    return name;
  }
}