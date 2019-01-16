pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Opacity {
  // Public variables of OPQ
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  uint256 public funds;
  address public director;
  bool public directorLock;
  uint256 public claimAmount;
  uint256 public payAmount;
  uint256 public feeAmount;
  uint256 public epoch;
  uint256 public retentionMax;

  // Array definitions
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => bool) public buried;
  mapping (address => uint256) public claimed;

  // ERC20 event
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // ERC20 event
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // This notifies clients about the amount burnt
  event Burn(address indexed _from, uint256 _value);

  // This notifies clients about an address getting buried
  event Bury(address indexed _target, uint256 _value);

  // This notifies clients about a claim being made on a buried address
  event Claim(address indexed _target, address indexed _payout, address indexed _fee);

  /**
   * Constructor function
   *
   * Initializes contract
   */
  function Opacity() public payable {
    director = msg.sender;
    name = "Opacity";
    symbol = "OPQ";
    decimals = 18;
    directorLock = false;
    funds = 0;
    totalSupply = 130000000 * 10 ** uint256(decimals);

    // Assign reserved OPQ supply to the director
    balances[director] = totalSupply;

    // Define default values for Opacity functions
    claimAmount = 5 * 10 ** (uint256(decimals) - 1);
    payAmount = 4 * 10 ** (uint256(decimals) - 1);
    feeAmount = 1 * 10 ** (uint256(decimals) - 1);

    // Seconds in a year
    epoch = 31536000;

    // Maximum time for a sector to remain stored
    retentionMax = 40 * 10 ** uint256(decimals);
  }

  /**
   * ERC20 balance function
   */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  modifier onlyDirector {
    // Director can lock themselves out to complete decentralization of Opacity
    // An alternative is that another smart contract could become the decentralized director
    require(!directorLock);

    // Only the director is permitted
    require(msg.sender == director);
    _;
  }

  modifier onlyDirectorForce {
    // Only the director is permitted
    require(msg.sender == director);
    _;
  }

  /**
   * Transfers the director to a new address
   */
  function transferDirector(address newDirector) public onlyDirectorForce {
    director = newDirector;
  }

  /**
   * Withdraw funds from the contract
   */
  function withdrawFunds() public onlyDirectorForce {
    director.transfer(this.balance);
  }

  /**
   * Permanently lock out the director to decentralize Opacity
   * Invocation is discretionary because Opacity might be better suited to
   * transition to an artificially intelligent smart contract director
   */
  function selfLock() public payable onlyDirector {

    // Prevents accidental lockout
    require(msg.value == 10 ether);

    // Permanently lock out the director
    directorLock = true;
  }

  /**
   * Director can alter the storage-peg and broker fees
   */
  function amendClaim(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet, uint8 accuracy) public onlyDirector returns (bool success) {
    require(claimAmountSet == (payAmountSet + feeAmountSet));
    require(payAmountSet < claimAmountSet);
    require(feeAmountSet < claimAmountSet);
    require(claimAmountSet > 0);
    require(payAmountSet > 0);
    require(feeAmountSet > 0);

    claimAmount = claimAmountSet * 10 ** (uint256(decimals) - accuracy);
    payAmount = payAmountSet * 10 ** (uint256(decimals) - accuracy);
    feeAmount = feeAmountSet * 10 ** (uint256(decimals) - accuracy);
    return true;
  }

  /**
   * Director can alter the epoch time
   */
  function amendEpoch(uint256 epochSet) public onlyDirector returns (bool success) {
    // Set the epoch
    epoch = epochSet;
    return true;
  }

  /**
   * Director can alter the maximum time of storage retention
   */
  function amendRetention(uint8 retentionSet, uint8 accuracy) public onlyDirector returns (bool success) {
    // Set retentionMax
    retentionMax = retentionSet * 10 ** (uint256(decimals) - accuracy);
    return true;
  }

  /**
   * Bury an address
   *
   * When an address is buried; only claimAmount can be withdrawn once per epoch
   */
  function bury() public returns (bool success) {
    // The address must be previously unburied
    require(!buried[msg.sender]);

    // An address must have at least claimAmount to be buried
    require(balances[msg.sender] >= claimAmount);

    // Prevent addresses with large balances from getting buried
    require(balances[msg.sender] <= retentionMax);

    // Set buried state to true
    buried[msg.sender] = true;

    // Set the initial claim clock to 1
    claimed[msg.sender] = 1;

    // Execute an event reflecting the change
    Bury(msg.sender, balances[msg.sender]);
    return true;
  }

  /**
   * Claim OPQ from a buried address
   *
   * If a prior claim wasn&#39;t made during the current epoch, then claimAmount can be withdrawn
   *
   * @param _payout the address of the website owner
   * @param _fee the address of the broker node
   */
  function claim(address _payout, address _fee) public returns (bool success) {
    // The claimed address must have already been buried
    require(buried[msg.sender]);

    // The payout and fee addresses must be different
    require(_payout != _fee);

    // The claimed address cannot pay itself
    require(msg.sender != _payout);

    // The claimed address cannot pay itself
    require(msg.sender != _fee);

    // It must be either the first time this address is being claimed or atleast epoch in time has passed
    require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= epoch);

    // Check if the buried address has enough
    require(balances[msg.sender] >= claimAmount);

    // Reset the claim clock to the current block time
    claimed[msg.sender] = block.timestamp;

    // Save this for an assertion in the future
    uint256 previousBalances = balances[msg.sender] + balances[_payout] + balances[_fee];

    // Remove claimAmount from the buried address
    balances[msg.sender] -= claimAmount;

    // Pay the website owner that invoked the web node that found the OPQ seed key
    balances[_payout] += payAmount;

    // Pay the broker node that unlocked the OPQ
    balances[_fee] += feeAmount;

    // Execute events to reflect the changes
    Claim(msg.sender, _payout, _fee);
    Transfer(msg.sender, _payout, payAmount);
    Transfer(msg.sender, _fee, feeAmount);

    // Failsafe logic that should never be false
    assert(balances[msg.sender] + balances[_payout] + balances[_fee] == previousBalances);
    return true;
  }

  /**
   * Internal transfer, can be called by this contract only
   */
  function _transfer(address _from, address _to, uint _value) internal {
    // Sending addresses cannot be buried
    require(!buried[_from]);

    // If the receiving address is buried, it cannot exceed retentionMax
    if (buried[_to]) {
      require(balances[_to] + _value <= retentionMax);
    }

    // Prevent transfer to 0x0 address, use burn() instead
    require(_to != 0x0);

    // Check if the sender has enough
    require(balances[_from] >= _value);

    // Check for overflows
    require(balances[_to] + _value > balances[_to]);

    // Save this for an assertion in the future
    uint256 previousBalances = balances[_from] + balances[_to];

    // Subtract from the sender
    balances[_from] -= _value;

    // Add the same to the recipient
    balances[_to] += _value;
    Transfer(_from, _to, _value);

    // Failsafe logic that should never be false
    assert(balances[_from] + balances[_to] == previousBalances);
  }

  /**
   * Transfer tokens
   *
   * Send `_value` tokens to `_to` from your account
   *
   * @param _to the address of the recipient
   * @param _value the amount to send
   */
  function transfer(address _to, uint256 _value) public {
    _transfer(msg.sender, _to, _value);
  }

  /**
   * Transfer tokens from other address
   *
   * Send `_value` tokens to `_to` in behalf of `_from`
   *
   * @param _from the address of the sender
   * @param _to the address of the recipient
   * @param _value the amount to send
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    // Check allowance
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  /**
   * Set allowance for other address
   *
   * Allows `_spender` to spend no more than `_value` tokens on your behalf
   *
   * @param _spender the address authorized to spend
   * @param _value the max amount they can spend
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    // Buried addresses cannot be approved
    require(!buried[msg.sender]);

    allowance[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * Set allowance for other address and notify
   *
   * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
   *
   * @param _spender the address authorized to spend
   * @param _value the max amount they can spend
   * @param _extraData some extra information to send to the approved contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  /**
   * Destroy tokens
   *
   * Remove `_value` tokens from the system irreversibly
   *
   * @param _value the amount of money to burn
   */
  function burn(uint256 _value) public returns (bool success) {
    // Buried addresses cannot be burnt
    require(!buried[msg.sender]);

    // Check if the sender has enough
    require(balances[msg.sender] >= _value);

    // Subtract from the sender
    balances[msg.sender] -= _value;

    // Updates totalSupply
    totalSupply -= _value;
    Burn(msg.sender, _value);
    return true;
  }

  /**
   * Destroy tokens from other account
   *
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   *
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    // Buried addresses cannot be burnt
    require(!buried[_from]);

    // Check if the targeted balance is enough
    require(balances[_from] >= _value);

    // Check allowance
    require(_value <= allowance[_from][msg.sender]);

    // Subtract from the targeted balance
    balances[_from] -= _value;

    // Subtract from the sender&#39;s allowance
    allowance[_from][msg.sender] -= _value;

    // Update totalSupply
    totalSupply -= _value;
    Burn(_from, _value);
    return true;
  }
}