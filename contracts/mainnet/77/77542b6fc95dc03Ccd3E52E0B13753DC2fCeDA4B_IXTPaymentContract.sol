pragma solidity 0.4.21;
/**
 * @title Ownable Contract
 * @dev contract that has a user and can implement user access restrictions based on it
 */
contract Ownable {

  address public owner;

  /**
   * @dev sets owner of contract
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev changes owner of contract
   * @param newOwner New owner
   */
  function changeOwner(address newOwner) public ownerOnly {
    require(newOwner != address(0));
    owner = newOwner;
  }

  /**
   * @dev Throws if called by other account than owner
   */
  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title Emergency Safety contract
 * @dev Allows token and ether drain and pausing of contract
 */ 
contract EmergencySafe is Ownable{ 

  event PauseToggled(bool isPaused);

  bool public paused;


  /**
   * @dev Throws if contract is paused
   */
  modifier isNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Throws if contract is not paused
   */
  modifier isPaused() {
    require(paused);
    _; 
  }

  /**
   * @dev Initialises contract to non-paused
   */
  function EmergencySafe() public {
    paused = false;
  }

  /**
   * @dev Allows draining of tokens (to owner) that might accidentally be sent to this address
   * @param token Address of ERC20 token
   * @param amount Amount to drain
   */
  function emergencyERC20Drain(ERC20Interface token, uint amount) public ownerOnly{
    token.transfer(owner, amount);
  }

  /**
   * @dev Allows draining of Ether
   * @param amount Amount to drain
   */
  function emergencyEthDrain(uint amount) public ownerOnly returns (bool){
    return owner.send(amount);
  }

  /**
   * @dev Switches the contract from paused to non-paused or vice-versa
   */
  function togglePause() public ownerOnly {
    paused = !paused;
    emit PauseToggled(paused);
  }
}


/**
 * @title Upgradeable Conract
 * @dev contract that implements doubly linked list to keep track of old and new 
 * versions of this contract
 */ 
contract Upgradeable is Ownable{

  address public lastContract;
  address public nextContract;
  bool public isOldVersion;
  bool public allowedToUpgrade;

  /**
   * @dev makes contract upgradeable 
   */
  function Upgradeable() public {
    allowedToUpgrade = true;
  }

  /**
   * @dev signals that new upgrade is available, contract must be most recent 
   * upgrade and allowed to upgrade
   * @param newContract Address of upgraded contract 
   */
  function upgradeTo(Upgradeable newContract) public ownerOnly{
    require(allowedToUpgrade && !isOldVersion);
    nextContract = newContract;
    isOldVersion = true;
    newContract.confirmUpgrade();   
  }

  /**
   * @dev confirmation that this is indeed the next version,
   * called from previous version of contract. Anyone can call this function,
   * which basically makes this instance unusable if that happens. Once called,
   * this contract can not serve as upgrade to another contract. Not an ideal solution
   * but will work until we have a more sophisticated approach using a dispatcher or similar
   */
  function confirmUpgrade() public {
    require(lastContract == address(0));
    lastContract = msg.sender;
  }
}

/**
 * @title IXT payment contract in charge of administaring IXT payments 
 * @dev contract looks up price for appropriate tasks and sends transferFrom() for user,
 * user must approve this contract to spend IXT for them before being able to use it
 */ 
contract IXTPaymentContract is Ownable, EmergencySafe, Upgradeable{

  event IXTPayment(address indexed from, address indexed to, uint value, string indexed action);

  ERC20Interface public tokenContract;

  mapping(string => uint) private actionPrices;
  mapping(address => bool) private allowed;

  /**
   * @dev Throws if called by non-allowed contract
   */
  modifier allowedOnly() {
    require(allowed[msg.sender] || msg.sender == owner);
    _;
  }

  /**
   * @dev sets up token address of IXT token
   * adds owner to allowds, if owner is changed in the future, remember to remove old
   * owner if desired
   * @param tokenAddress IXT token address
   */
  function IXTPaymentContract(address tokenAddress) public {
    tokenContract = ERC20Interface(tokenAddress);
    allowed[owner] = true;
  }

  /**
   * @dev transfers IXT 
   * @param from User address
   * @param to Recipient
   * @param action Service the user is paying for 
   */
  function transferIXT(address from, address to, string action) public allowedOnly isNotPaused returns (bool) {
    if (isOldVersion) {
      IXTPaymentContract newContract = IXTPaymentContract(nextContract);
      return newContract.transferIXT(from, to, action);
    } else {
      uint price = actionPrices[action];

      if(price != 0 && !tokenContract.transferFrom(from, to, price)){
        return false;
      } else {
        emit IXTPayment(from, to, price, action);     
        return true;
      }
    }
  }

  /**
   * @dev sets new token address in case of update
   * @param erc20Token Token address
   */
  function setTokenAddress(address erc20Token) public ownerOnly isNotPaused {
    tokenContract = ERC20Interface(erc20Token);
  }

  /**
   * @dev creates/updates action
   * @param action Action to be paid for 
   * @param price Price (in units * 10 ^ (<decimal places of token>))
   */
  function setAction(string action, uint price) public ownerOnly isNotPaused {
    actionPrices[action] = price;
  }

  /**
   * @dev retrieves price for action
   * @param action Name of action, e.g. &#39;create_insurance_contract&#39;
   */
  function getActionPrice(string action) public view returns (uint) {
    return actionPrices[action];
  }


  /**
   * @dev add account to allow calling of transferIXT
   * @param allowedAddress Address of account 
   */
  function setAllowed(address allowedAddress) public ownerOnly {
    allowed[allowedAddress] = true;
  }

  /**
   * @dev remove account from allowed accounts
   * @param allowedAddress Address of account 
   */
  function removeAllowed(address allowedAddress) public ownerOnly {
    allowed[allowedAddress] = false;
  }
}

contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}