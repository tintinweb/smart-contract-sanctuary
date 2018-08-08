pragma solidity ^0.4.24;

/// @title Proxied - indicates that a contract will be proxied. Also defines storage requirements for Proxy.
/// @author Alan Lu - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7c1d101d123c1b12130f150f520c11">[email&#160;protected]</a>>
contract Proxied {
    address public masterCopy;
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c5b6b1a0a3a4ab85a2abaab6acb6ebb5a8">[email&#160;protected]</a>>
contract Proxy is Proxied {
    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != 0);
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md



/// @title Abstract token contract - Functions to be implemented by token contracts
contract Token {

    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}



/// @title Abstract oracle contract - Functions to be implemented by oracles
contract Oracle {

    function isOutcomeSet() public view returns (bool);
    function getOutcome() public view returns (int);
}







/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}







contract CentralizedBugOracleData {
  event OwnerReplacement(address indexed newOwner);
  event OutcomeAssignment(int outcome);

  /*
   *  Storage
   */
  address public owner;
  bytes public ipfsHash;
  bool public isSet;
  int public outcome;
  address public maker;
  address public taker;

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }
}

contract CentralizedBugOracleProxy is Proxy, CentralizedBugOracleData {

    /// @dev Constructor sets owner address and IPFS hash
    /// @param _ipfsHash Hash identifying off chain event description
    constructor(address proxied, address _owner, bytes _ipfsHash, address _maker, address _taker)
        public
        Proxy(proxied)
    {
        // Description hash cannot be null
        require(_ipfsHash.length == 46);
        owner = _owner;
        ipfsHash = _ipfsHash;
        maker = _maker;
        taker = _taker;
    }
}

contract CentralizedBugOracle is Proxied,Oracle, CentralizedBugOracleData{

  /// @dev Sets event outcome
  /// @param _outcome Event outcome
  function setOutcome(int _outcome)
      public
      isOwner
  {
      // Result is not set yet
      require(!isSet);
      _setOutcome(_outcome);
  }

  /// @dev Returns if winning outcome is set
  /// @return Is outcome set?
  function isOutcomeSet()
      public
      view
      returns (bool)
  {
      return isSet;
  }

  /// @dev Returns outcome
  /// @return Outcome
  function getOutcome()
      public
      view
      returns (int)
  {
      return outcome;
  }


  //@dev internal funcion to set the outcome sat
  function _setOutcome(int _outcome) internal {
    isSet = true;
    outcome = _outcome;
    emit OutcomeAssignment(_outcome);
  }


}


//Vending machine Logic goes in this contract
contract OracleVendingMachine {
  using SafeMath for *;

  /*
   *  events
   */

  event OracleProposed(address maker, address taker, uint256 index, bytes hash);
  event OracleAccepted(address maker, address taker, uint256 index, bytes hash);
  event OracleDeployed(address maker, address taker, uint256 index, bytes hash, address oracle);
  event OracleRevoked(address maker, address taker, uint256 index, bytes hash);

  event FeeUpdated(uint256 newFee);
  event OracleUpgraded(address newAddress);
  event PaymentTokenChanged(address newToken);
  event StatusChanged(bool newStatus);
  event OracleBoughtFor(address buyer, address maker, address taker, uint256 index, bytes ipfsHash, address oracle);

  /*
   *  Storage
   */
  address public owner;
  uint public fee;
  Oracle public oracleMasterCopy;
  Token public paymentToken;
  bool public open;


  mapping (address => uint256) public balances;
  mapping (address => bool) public balanceChecked;
  mapping (address => mapping (address => uint256)) public oracleIndexes;
  mapping (address => mapping (address => mapping (uint256 => proposal))) public oracleProposed;
  mapping (address => mapping (address => mapping (uint256 => address))) public oracleDeployed;

  struct proposal {
    bytes hash;
    address oracleMasterCopy;
    uint256 fee;
  }

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }

  modifier whenOpen() {
    //Only proceeds with operation if open is true
    require(open);
    _;
  }

  /**
    @dev Contructor to the vending Machine
    @param _fee The for using the vending Machine
    @param _token the Address of the token used for paymentToken
    @param _oracleMasterCopy The deployed version of the oracle which will be proxied to
  **/
  constructor(uint _fee, address _token, address _oracleMasterCopy) public {
    owner = msg.sender;
    fee = _fee;
    paymentToken = Token(_token);
    oracleMasterCopy = Oracle(_oracleMasterCopy);
    open = true;
  }

  /**
    @dev Change the fee
    @param _fee Te new vending machine fee
  **/
  function changeFee(uint _fee) public isOwner {
      fee = _fee;
      emit FeeUpdated(_fee);
  }

  /**
    @dev Change the master copy of the oracle
    @param _oracleMasterCopy The address of the deployed version of the oracle which will be proxied to
  **/
  function upgradeOracle(address _oracleMasterCopy) public isOwner {
    require(_oracleMasterCopy != 0x0);
    oracleMasterCopy = Oracle(_oracleMasterCopy);
    emit OracleUpgraded(_oracleMasterCopy);
  }

  /**
    @dev Change the payment token
    @param _paymentToken the Address of the token used for paymentToken
  **/
  function changePaymentToken(address _paymentToken) public isOwner {
    require(_paymentToken != 0x0);
    paymentToken = Token(_paymentToken);
    emit PaymentTokenChanged(_paymentToken);
  }

  /**
    @dev Contructor to the vending Machine
    @param status The new open status for the vending Machine
  **/
  function modifyOpenStatus(bool status) public isOwner {
    open = status;
    emit StatusChanged(status);
  }


  /**
    @dev Internal function to deploy and register a oracle
    @param _proposal A proposal struct containing the bug information
    @param maker the Address who proposed the oracle
    @param taker the Address who accepted the oracle
    @param index The index of the oracle to be deployed
    @return A deployed oracle contract
  **/
  function deployOracle(proposal _proposal, address maker, address taker, uint256 index) internal returns(Oracle oracle){
    require(oracleDeployed[maker][taker][index] == address(0));
    oracle = CentralizedBugOracle(new CentralizedBugOracleProxy(_proposal.oracleMasterCopy, owner, _proposal.hash, maker, taker));
    oracleDeployed[maker][taker][index] = oracle;
    emit OracleDeployed(maker, taker, index, _proposal.hash, oracle);
  }


  /**
    @dev Function called by he taker to confirm a proposed oracle
    @param maker the Address who proposed the oracle
    @param index The index of the oracle to be deployed
    @return A deployed oracle contract
  **/
  function confirmOracle(address maker, uint index) public returns(Oracle oracle) {
    require(oracleProposed[maker][msg.sender][index].fee > 0);

    if(!balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);

    oracle = deployOracle(oracleProposed[maker][msg.sender][index], maker, msg.sender, index);
    oracleIndexes[maker][msg.sender] += 1;
    emit OracleAccepted(maker, msg.sender, index, oracleProposed[maker][msg.sender][index].hash);
  }


  /**
    @dev Function to propose an oracle, calle by maker
    @param _ipfsHash The hash for the bug information(description, spurce code, etc)
    @param taker the Address who needs to accept the oracle
    @return index of the proposal
  **/
  function buyOracle(bytes _ipfsHash, address taker) public whenOpen returns (uint index){
    if(!balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    index = oracleIndexes[msg.sender][taker];
    oracleProposed[msg.sender][taker][index] = proposal(_ipfsHash, oracleMasterCopy, fee);
    emit OracleProposed(msg.sender, taker, index, _ipfsHash);
  }

  /**
    @dev Priviledged function to propose and deploy an oracle with one transaction. Called by Solidified Bug Bounty plataform
    @param _ipfsHash The hash for the bug information(description, spurce code, etc)
    @param maker the Address who proposed the oracle
    @param taker the Address who accepted the oracle
    @return A deployed oracle contract
  **/
  function buyOracleFor(bytes _ipfsHash, address maker, address taker) public whenOpen isOwner returns(Oracle oracle){
    if(!balanceChecked[maker]) checkBalance(maker);
    if(!balanceChecked[taker]) checkBalance(taker);

    balances[maker] = balances[maker].sub(fee);
    balances[taker] = balances[taker].sub(fee);

    uint256 index = oracleIndexes[maker][taker];
    proposal memory oracleProposal  = proposal(_ipfsHash, oracleMasterCopy, fee);

    oracleProposed[maker][taker][index] = oracleProposal;
    oracle = deployOracle(oracleProposal,maker,taker,index);
    oracleDeployed[maker][taker][oracleIndexes[maker][taker]] = oracle;
    oracleIndexes[maker][taker] += 1;
    emit OracleBoughtFor(msg.sender, maker, taker, index, _ipfsHash, oracle);
  }

  /**
    @dev  Function to cancel a proposed oracle, called by the maker
    @param taker the Address who accepted the oracle
    @param index The index of the proposed to be revoked
  **/
  function revokeOracle(address taker, uint256 index) public {
    require(oracleProposed[msg.sender][taker][index].fee >  0);
    require(oracleDeployed[msg.sender][taker][index] == address(0));
    proposal memory oracleProposal = oracleProposed[msg.sender][taker][index];
    oracleProposed[msg.sender][taker][index].hash = "";
    oracleProposed[msg.sender][taker][index].fee = 0;
    oracleProposed[msg.sender][taker][index].oracleMasterCopy = address(0);

    balances[msg.sender] = balances[msg.sender].add(oracleProposal.fee);
    emit OracleRevoked(msg.sender, taker, index, oracleProposal.hash);
  }

  /**
    @dev Function to check a users balance of SOLID and deposit as credit
    @param holder Address of the holder to be checked
  **/
  function checkBalance(address holder) public {
    require(!balanceChecked[holder]);
    balances[holder] = paymentToken.balanceOf(holder);
    balanceChecked[holder] = true;
  }

}