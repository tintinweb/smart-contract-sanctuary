pragma solidity ^0.4.24;

contract owned{
  address public owner;

  constructor(){
    owner = msg.sender;
  }

  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner{
    owner = newOwner;
  }
}

contract heart is owned{
  uint256 issuedTokens;
  uint8 decimalSpaces;
  string abbriveration;
  string tokenName;

  uint256 minimumCalimValue;

  mapping (address => uint256) balances;

  mapping (address => HeartData) heartDB;

  mapping (bytes32 => LocationData) locationDB;

  mapping (address => mapping (uint256 => bytes32)) holdDB;

  mapping (address => mapping (address => bool)) allowanceApproval;

  struct HeartData{
    bytes32 graphicHash;
    bool claimed;
    string message;
  }

  struct LocationData{
    address originalOwner;
    address currentHolder;
  }

  /*
   *  Modifiers
   */

  modifier notClaimed{
    require(!heartDB[msg.sender].claimed);
    _;
  }

  /*
   *  Constructor
   */

  constructor(uint256 _initialTokenMint, string _symbol, string _tokenName, uint256 _minimumCalimValue) public{
    issuedTokens = _initialTokenMint;
    balances[msg.sender] = _initialTokenMint;
    decimalSpaces = 0;
    abbriveration = _symbol;
    tokenName = _tokenName;
    minimumCalimValue = _minimumCalimValue;
  }

  /*
   *  Events
   */

  event Transfer(address indexed _from, address indexed _to, string _message);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Generation(address indexed _recipient, bytes32 _graphicHash);

  /*
   *  View functions
   */

  function name() view public returns (string _name){
    return tokenName;
  }

  function symbol() view public returns (string _symbol){
    return abbriveration;
  }

  function decimals() view public returns (uint8 _decimals){
    return decimalSpaces;
  }

  function totalSupply() view public returns (uint256 _totalSupply){
    return issuedTokens;
  }

  function balanceOf(address _owner) view public returns (uint256 _balance){
    return balances[_owner];
  }

  function minimumDonation() view public returns (uint256 _minimumDonationValue){
    return minimumCalimValue;
  }

  function heldTokens(address _holder, uint256 _tokenNumber) view public returns (bytes32 _graphicHash, address _originalOwner){
    return (holdDB[_holder][_tokenNumber], locationDB[holdDB[_holder][_tokenNumber]].originalOwner);
  }

  /*
   *  Operational functions
   */

  function claimToken() public payable notClaimed returns(bool success){
    require(msg.value >= minimumCalimValue);
    if(generate(msg.sender)){
      return true;
    }
    else{
      revert();
    }
  }

  function generate(address _beneficiary) internal returns(bool success){
    require(!heartDB[_beneficiary].claimed);
    issuedTokens += 1;
    balances[_beneficiary] += 1;
    heartDB[_beneficiary].graphicHash = keccak256(_beneficiary, now ,issuedTokens);
    heartDB[_beneficiary].claimed = true;
    locationDB[heartDB[_beneficiary].graphicHash].originalOwner = _beneficiary;
    locationDB[heartDB[_beneficiary].graphicHash].currentHolder = _beneficiary;
    holdDB[_beneficiary][balances[_beneficiary]-1] = heartDB[_beneficiary].graphicHash;
    emit Generation(_beneficiary, heartDB[_beneficiary].graphicHash);
    return true;
  }

  function setMinimumClaimValue(uint256 _minimumCalimValue) public onlyOwner{
    minimumCalimValue = _minimumCalimValue;
  }

  function transfer(address _to, string _message) public returns (bool succes){
    require(msg.sender == locationDB[heartDB[msg.sender].graphicHash].originalOwner);
    locationDB[heartDB[msg.sender].graphicHash].currentHolder = _to;
    heartDB[msg.sender].message = _message;
    holdDB[_to][balances[_to]-1] = heartDB[msg.sender].graphicHash;
    uint256 heartSent;
    for(uint256 i = 0; i < balances[msg.sender]; i++){
      if(holdDB[msg.sender][i] == heartDB[msg.sender].graphicHash){
        heartSent = i;
      }
    }
    for(uint256 j = heartSent; j < balances[msg.sender]; j++){
      holdDB[msg.sender][j] = holdDB[msg.sender][j];
    }
    balances[msg.sender] -= 1;
    balances[_to] += 1;
    emit Transfer(msg.sender, _to, _message);
    return true;
  }

  function returnHrt(address _to, string _message) public returns(bool success){
      require(msg.sender == locationDB[heartDB[_to].graphicHash].currentHolder);
      heartDB[_to].message = _message;
      locationDB[heartDB[_to].graphicHash].currentHolder = locationDB[heartDB[_to].graphicHash].originalOwner;
      balances[msg.sender] -= 1;
      balances[_to] += 1;
      emit Transfer(msg.sender, _to, _message);
      return true;
  }

  function retreiveHrt(string _message) public returns(bool success){
    require(msg.sender != locationDB[heartDB[msg.sender].graphicHash].currentHolder);
    heartDB[msg.sender].message  = _message;
    balances[locationDB[heartDB[msg.sender].graphicHash].currentHolder] -= 1;
    balances[msg.sender] += 1;
    locationDB[heartDB[msg.sender].graphicHash].currentHolder = locationDB[heartDB[msg.sender].graphicHash].originalOwner;
    emit Transfer(locationDB[heartDB[msg.sender].graphicHash].currentHolder, msg.sender, _message);
    return true;
  }
}