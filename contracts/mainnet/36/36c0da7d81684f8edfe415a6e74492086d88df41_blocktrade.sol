pragma solidity ^0.4.21;

contract controlled{
  address public owner;
  uint256 public tokenFrozenUntilBlock;
  uint256 public tokenFrozenSinceBlock;
  uint256 public blockLock;

  mapping (address => bool) restrictedAddresses;

  // @dev Constructor function that sets freeze parameters so they don&#39;t unintentionally hinder operations.
  function Constructor() public{
    owner = 0x24bF9FeCA8894A78d231f525c054048F5932dc6B;
    tokenFrozenSinceBlock = (2 ** 256) - 1;
    tokenFrozenUntilBlock = 0;
    blockLock = 5571500;
  }

  /*
  * @dev Transfers ownership rights to current owner to the new owner.
  * @param newOwner address Address to become the new SC owner.
  */
  function transferOwnership (address newOwner) onlyOwner public{
    owner = newOwner;
  }

  /*
  * @dev Allows owner to restrict or reenable addresses to use the token.
  * @param _restrictedAddress address Address of the user whose state we are planning to modify.
  * @param _restrict bool Restricts uder from using token. true restricts the address while false enables it.
  */
  function editRestrictedAddress(address _restrictedAddress, bool _restrict) public onlyOwner{
    if(!restrictedAddresses[_restrictedAddress] && _restrict){
      restrictedAddresses[_restrictedAddress] = _restrict;
    }
    else if(restrictedAddresses[_restrictedAddress] && !_restrict){
      restrictedAddresses[_restrictedAddress] = _restrict;
    }
    else{
      revert();
    }
  }



  /************ Modifiers to restrict access to functions. ************/

  // @dev Modifier to make sure the owner&#39;s functions are only called by the owner.
  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }

  /*
  * @dev Modifier to check whether destination of sender aren&#39;t forbidden from using the token.
  * @param _to address Address of the transfer destination.
  */
  modifier instForbiddenAddress(address _to){
    require(_to != 0x0);
    require(_to != address(this));
    require(!restrictedAddresses[_to]);
    require(!restrictedAddresses[msg.sender]);
    _;
  }

  // @dev Modifier to check if the token is operational at the moment.
  modifier unfrozenToken{
    require(block.number >= blockLock || msg.sender == owner);
    require(block.number >= tokenFrozenUntilBlock);
    require(block.number <= tokenFrozenSinceBlock);
    _;
  }
}

contract blocktrade is controlled{
  string public name = "blocktrade";
  string public symbol = "BTT";
  uint8 public decimals = 18;
  uint256 public initialSupply = 57746762*(10**18);
  uint256 public supply;
  string public tokenFrozenUntilNotice;
  string public tokenFrozenSinceNotice;
  bool public airDropFinished;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event TokenFrozenUntil(uint256 _frozenUntilBlock, string _reason);
  event TokenFrozenSince(uint256 _frozenSinceBlock, string _reason);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Burn(address indexed from, uint256 value);

  /*
  * @dev Constructor function.
  */
  function Constructor() public{
    supply = 57746762*(10**18);
    airDropFinished = false;
    balances[owner] = 57746762*(10**18);
  }


  /************ Constant return functions ************/
  //@dev Returns the name of the token.
  function tokenName() constant public returns(string _tokenName){
    return name;
  }

  //@dev Returns the symbol of the token.
  function tokenSymbol() constant public returns(string _tokenSymbol){
    return symbol;
  }

  //@dev Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
  function tokenDecimals() constant public returns(uint8 _tokenDecimals){
    return decimals;
  }

  //@dev Returns the total supply of the token
  function totalSupply() constant public returns(uint256 _totalSupply){
    return supply;
  }

  /*
  * @dev Allows us to view the token balance of the account.
  * @param _tokenOwner address Address of the user whose token balance we are trying to view.
  */
  function balanceOf(address _tokenOwner) constant public returns(uint256 accountBalance){
    return balances[_tokenOwner];
  }

  /*
  * @dev Allows us to view the token balance of the account.
  * @param _owner address Address of the user whose token we are allowed to spend from sender address.
  * @param _spender address Address of the user allowed to spend owner&#39;s tokens.
  */
  function allowance(address _owner, address _spender) constant public returns(uint256 remaining) {
    return allowances[_owner][_spender];
  }

  // @dev Returns when will the token become operational again and why it was frozen.
  function getFreezeUntilDetails() constant public returns(uint256 frozenUntilBlock, string notice){
    return(tokenFrozenUntilBlock, tokenFrozenUntilNotice);
  }

  //@dev Returns when will the operations of token stop and why.
  function getFreezeSinceDetails() constant public returns(uint frozenSinceBlock, string notice){
    return(tokenFrozenSinceBlock, tokenFrozenSinceNotice);
  }

  /*
  * @dev Returns info whether address can use the token or not.
  * @param _queryAddress address Address of the account we want to check.
  */
  function isRestrictedAddress(address _queryAddress) constant public returns(bool answer){
    return restrictedAddresses[_queryAddress];
  }


  /************ Operational functions ************/
  /*
  * @dev Used for sending own tokens to other addresses. Keep in mind that you have to take decimals into account. Multiply the value in tokens with 10^tokenDecimals.
  * @param _to address Destination where we want to send the tokens to.
  * @param _value uint256 Amount of tokens we want to sender.
  */
  function transfer(address _to, uint256 _value) unfrozenToken instForbiddenAddress(_to) public returns(bool success){
    require(balances[msg.sender] >= _value);           // Check if the sender has enough
    require(balances[_to] + _value >= balances[_to]) ;  // Check for overflows

    balances[msg.sender] -= _value;                     // Subtract from the sender
    balances[_to] += _value;                            // Add the same to the recipient
    emit Transfer(msg.sender, _to, _value);                  // Notify anyone listening that this transfer took place
    return true;
  }

  /*
  * @dev Sets allowance to the spender from our address.
  * @param _spender address Address of the spender we are giving permissions to.
  * @param _value uint256 Amount of tokens the spender is allowed to spend from owner&#39;s accoun. Note the decimal spaces.
  */
  function approve(address _spender, uint256 _value) unfrozenToken public returns (bool success){
    allowances[msg.sender][_spender] = _value;          // Set allowance
    emit Approval(msg.sender, _spender, _value);             // Raise Approval event
    return true;
  }

  /*
  * @dev Used by spender to transfer some one else&#39;s tokens.
  * @param _form address Address of the owner of the tokens.
  * @param _to address Address where we want to transfer tokens to.
  * @param _value uint256 Amount of tokens we want to transfer. Note the decimal spaces.
  */
  function transferFrom(address _from, address _to, uint256 _value) unfrozenToken instForbiddenAddress(_to) public returns(bool success){
    require(balances[_from] >= _value);                // Check if the sender has enough
    require(balances[_to] + _value >= balances[_to]);  // Check for overflows
    require(_value <= allowances[_from][msg.sender]);  // Check allowance

    balances[_from] -= _value;                          // Subtract from the sender
    balances[_to] += _value;                            // Add the same to the recipient
    allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address
    emit Transfer(_from, _to, _value);                       // Notify anyone listening that this transfer took place
    return true;
  }

  /*
  * @dev Ireversibly destroy the specified amount of tokens.
  * @param _value uint256 Amount of tokens we want to destroy.
  */
  function burn(uint256 _value) onlyOwner public returns(bool success){
    require(balances[msg.sender] >= _value);                 // Check if the sender has enough
    balances[msg.sender] -= _value;                          // Subtract from the sender
    supply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  /*
  * @dev Freezes transfers untill the specified block. Afterwards all of the operations are carried on as normal.
  * @param _frozenUntilBlock uint256 Number of block untill which all of the transfers are frozen.
  * @param _freezeNotice string Reason fot the freeze of operations.
  */
  function freezeTransfersUntil(uint256 _frozenUntilBlock, string _freezeNotice) onlyOwner public returns(bool success){
    tokenFrozenUntilBlock = _frozenUntilBlock;
    tokenFrozenUntilNotice = _freezeNotice;
    emit TokenFrozenUntil(_frozenUntilBlock, _freezeNotice);
    return true;
  }

  /*
  * @dev Freezes all of the transfers after specified block.
  * @param _frozenSinceBlock uint256 Number of block after which all of the transfers are frozen.
  * @param _freezeNotice string Reason for the freeze.
  */
  function freezeTransfersSince(uint256 _frozenSinceBlock, string _freezeNotice) onlyOwner public returns(bool success){
    tokenFrozenSinceBlock = _frozenSinceBlock;
    tokenFrozenSinceNotice = _freezeNotice;
    emit TokenFrozenSince(_frozenSinceBlock, _freezeNotice);
    return true;
  }

  /*
  * @dev Reenables the operation before the specified block was reached.
  * @param _unfreezeNotice string Reason for the unfreeze or explanation of solution.
  */
  function unfreezeTransfersUntil(string _unfreezeNotice) onlyOwner public returns(bool success){
    tokenFrozenUntilBlock = 0;
    tokenFrozenUntilNotice = _unfreezeNotice;
    emit TokenFrozenUntil(0, _unfreezeNotice);
    return true;
  }

  /*
  * @dev Reenabling after the freeze since was initiated.
  * @param _unfreezeNotice string Reason for the unfreeze or the explanation of solution.
  */
  function unfreezeTransfersSince(string _unfreezeNotice) onlyOwner public returns(bool success){
    tokenFrozenSinceBlock = (2 ** 256) - 1;
    tokenFrozenSinceNotice = _unfreezeNotice;
    emit TokenFrozenSince((2 ** 256) - 1, _unfreezeNotice);
    return true;
  }



  /************ AirDrop part of the SC. ************/

  /*
  * @dev Allocates the specified amount of tokens to the address.
  * @param _beneficiary address Address of the ouser that receives the tokens.
  * @param _tokens uint256 Amount of tokens to allocate.
  */
  function airDrop(address _beneficiary, uint256 _tokens) onlyOwner public returns(bool success){
    require(!airDropFinished);
    balances[owner] -= _tokens;
    balances[_beneficiary] += _tokens;
    return true;
  }

  // @dev Function that irreversively disables airDrop and should be called right after airDrop is completed.
  function endAirDrop() onlyOwner public returns(bool success){
    require(!airDropFinished);
    airDropFinished = true;
    return true;
  }
}
//JA