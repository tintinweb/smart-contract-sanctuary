pragma solidity 0.4.11;

contract ERC20TokenInterface {

    /// @return The total amount of tokens
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PowerLedger is ERC20TokenInterface {

  //// Constants ////
  string public constant name = &#39;PowerLedger&#39;;
  uint256 public constant decimals = 6;
  string public constant symbol = &#39;POWR&#39;;
  string public constant version = &#39;1.0&#39;;
  string public constant note = &#39;Democratization of Power&#39;;

  // One billion coins, each divided to up to 10^decimals units.
  uint256 private constant totalTokens = 1000000000 * (10 ** decimals);

  mapping (address => uint256) public balances; // (ERC20)
  // A mapping from an account owner to a map from approved spender to their allowances.
  // (see ERC20 for details about allowances).
  mapping (address => mapping (address => uint256)) public allowed; // (ERC20)

  //// Events ////
  event MigrationInfoSet(string newMigrationInfo);

  // This is to be used when migration to a new contract starts.
  // This string can be used for any authorative information re the migration
  // (e.g. address to use for migration, or URL to explain where to find more info)
  string public migrationInfo = "";

  // The only address that can set migrationContractAddress, a secure multisig.
  address public migrationInfoSetter;

  //// Modifiers ////
  modifier onlyFromMigrationInfoSetter {
    if (msg.sender != migrationInfoSetter) {
      throw;
    }
    _;
  }

  //// Public functions ////
  function PowerLedger(address _migrationInfoSetter) {
    if (_migrationInfoSetter == 0) throw;
    migrationInfoSetter = _migrationInfoSetter;
    // Upon creation, all tokens belong to the deployer.
    balances[msg.sender] = totalTokens;
  }

  // See ERC20
  function totalSupply() constant returns (uint256) {
    return totalTokens;
  }

  // See ERC20
  // WARNING: If you call this with the address of a contract, the contract will receive the
  // funds, but will have no idea where they came from. Furthermore, if the contract is
  // not aware of POWR, the tokens will remain locked away in the contract forever.
  // It is always recommended to call instead compareAndApprove() (or approve()) and have the
  // receiving contract withdraw the money using transferFrom().
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] >= _value) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    return false;
  }

  // See ERC20
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  // See ERC20
  function balanceOf(address _owner) constant public returns (uint256) {
    return balances[_owner];
  }

  // See ERC20
  // NOTE: this method is vulnerable and is placed here only to follow the ERC20 standard.
  // Before using, please take a look at the better compareAndApprove below.
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  // A vulernability of the approve method in the ERC20 standard was identified by
  // Mikhail Vladimirov and Dmitry Khovratovich here:
  // https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
  // It&#39;s better to use this method which is not susceptible to over-withdrawing by the approvee.
  /// @param _spender The address to approve
  /// @param _currentValue The previous value approved, which can be retrieved with allowance(msg.sender, _spender)
  /// @param _newValue The new value to approve, this will replace the _currentValue
  /// @return bool Whether the approval was a success (see ERC20&#39;s `approve`)
  function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue) public returns(bool) {
    if (allowed[msg.sender][_spender] != _currentValue) {
      return false;
    }
    return approve(_spender, _newValue);
  }

  // See ERC20
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Allows setting a descriptive string, which will aid any users in migrating their token
  // to a newer version of the contract. This field provides a kind of &#39;double-layer&#39; of
  // authentication for any migration announcement, as it can only be set by PowerLedger.
  /// @param _migrationInfo The information string to be stored on the contract
  function setMigrationInfo(string _migrationInfo) onlyFromMigrationInfoSetter public {
    migrationInfo = _migrationInfo;
    MigrationInfoSet(_migrationInfo);
  }

  // To be used if the migrationInfoSetter wishes to transfer the migrationInfoSetter
  // permission to a new account, e.g. because of change in personnel, a concern that account
  // may have been compromised etc.
  /// @param _newMigrationInfoSetter The address of the new Migration Info Setter
  function changeMigrationInfoSetter(address _newMigrationInfoSetter) onlyFromMigrationInfoSetter public {
    migrationInfoSetter = _newMigrationInfoSetter;
  }
}