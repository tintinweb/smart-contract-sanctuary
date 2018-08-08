pragma solidity 0.4.21;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

/**
 * @title Insurance Contract
 * @dev Insurance Contract that is created by broker/client, functions mainly as permament record store
 */ 
contract Policy is Ownable, EmergencySafe, Upgradeable{

  struct InsuranceProduct {
    uint inceptionDate;
    string insuranceType;
  }

  struct PolicyInfo {
    uint blockNumber;
    uint numInsuranceProducts;
    string clientName;
    string ixlEnquiryId;
    string status;
  }

  InsuranceProduct[] public insuranceProducts;
  PolicyInfo public policyInfo;
  address private brokerEtherAddress;
  address private clientEtherAddress;
  mapping(address => bool) private cancellations;

  /**
   * @dev Throws if called by other account than broker or client
   */
  modifier participantOnly() {
    require(msg.sender == clientEtherAddress || msg.sender == brokerEtherAddress);
    _;
  }

  /**
   * @dev Throws if called by other account than broker or client,
   * core parameters kept as fields for future logic and for quick reference upon lookup
   */
  function Policy(string _clientName, address _brokerEtherAddress, address _clientEtherAddress, string _enquiryId) public {

    policyInfo = PolicyInfo({
      blockNumber: block.number,
      numInsuranceProducts: 0,
      clientName: _clientName,
      ixlEnquiryId: _enquiryId,
      status: &#39;In Force&#39;
    });

    clientEtherAddress =  _clientEtherAddress;
    brokerEtherAddress =  _brokerEtherAddress;

    allowedToUpgrade = false;
  }

  function addInsuranceProduct (uint _inceptionDate, string _insuranceType) public ownerOnly isNotPaused {

    insuranceProducts.push(InsuranceProduct({
      inceptionDate: _inceptionDate,
      insuranceType: _insuranceType
    }));

    policyInfo.numInsuranceProducts++;
  }


  /**
   * @dev Allows broker and client to cancel contract, when both have cancelled,
   * status is updated and contract becomes upgradeable
   */
  function revokeContract() public participantOnly {
    cancellations[msg.sender] = true;

    if (((cancellations[brokerEtherAddress] && (cancellations[clientEtherAddress] || cancellations[owner]))
        || (cancellations[clientEtherAddress] && cancellations[owner]))){
      policyInfo.status = "REVOKED";
      allowedToUpgrade = true;
    }
  }
}

/*
 * @title Policy Registry 
 * @dev Registry that is in charge of tracking and creating insurance contracts
 */ 
contract PolicyRegistry is Ownable, EmergencySafe, Upgradeable{

  event PolicyCreated(address at, address by);

  IXTPaymentContract public IXTPayment;

  mapping (address => address[]) private policiesByParticipant;
  address[] private policies;


  /**
   * @dev Creates Registry
   * @param paymentAddress The address of the payment contract used when creating insurance contracts
   */
  function PolicyRegistry(address paymentAddress) public {
    IXTPayment = IXTPaymentContract(paymentAddress);
  }

  /**
   * @dev Creates Policy, transfers ownership to msg.sender, registers address for all parties involved,
   * and transfers IXT 
   */
  function createContract(string _clientName, address _brokerEtherAddress, address _clientEtherAddress, string _enquiryId) public isNotPaused {

    Policy policy = new Policy(_clientName, _brokerEtherAddress, _clientEtherAddress, _enquiryId);
    policy.changeOwner(msg.sender);
    policiesByParticipant[_brokerEtherAddress].push(policy);

    if (_clientEtherAddress != _brokerEtherAddress) {
      policiesByParticipant[_clientEtherAddress].push(policy);
    }

    if (msg.sender != _clientEtherAddress && msg.sender != _brokerEtherAddress) {
      policiesByParticipant[msg.sender].push(policy);
    }

    policies.push(policy);

    IXTPayment.transferIXT(_clientEtherAddress, owner, "create_insurance");
    emit PolicyCreated(policy, msg.sender);
  }

  /**
   * @dev Retrieve all contracts that msg.sender is either broker, client or owner for
   */
  function getMyPolicies() public view returns (address[]) {
    return policiesByParticipant[msg.sender];
  }

  /**
   * @dev Retrieve all contracts ever created
   */
  function getAllPolicies() public view ownerOnly returns (address[]){
    return policies;
  }

  /**
   * @dev change address of payment contract
   * @param contractAddress Address of payment contract
   */
  function changePaymentContract(address contractAddress) public ownerOnly{
    IXTPayment = IXTPaymentContract(contractAddress);
  }
}