/*
This file is part of WeiFund.
*/

/*
A generic issued EC20 standard token, that can be issued by an issuer which the owner
of the contract sets. The issuer can only be set once if the onlyOnce option is true.
There is a freezePeriod option on transfers, if need be. There is also an date of
last issuance setting, if set, no more tokens can be issued past that time.

The token uses the a standard token API as much as possible, and overrides the transfer
and transferFrom methods. This way, we dont need special API&#39;s to issue this token.
We can retain the original StandardToken api, but add additional features.

Upon construction, initial token holders can be specified with their values.
Two arrays must be used. One with the token holer addresses, the other with the token
holder balances. They must be aligned by array index.
*/

pragma solidity ^0.4.4;
/*
This file is part of WeiFund.
*/

/*
A common Owned contract that contains properties for contract ownership.
*/



/// @title A single owned campaign contract for instantiating ownership properties.
/// @author Nick Dodson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d5bbbcb6befbb1bab1a6babb95b6babba6b0bba6aca6fbbbb0a1">[email&#160;protected]</a>>
contract Owned {
  // only the owner can use this method
  modifier onlyowner() {
    if (msg.sender != owner) {
      throw;
    }

    _;
  }

  // the owner property
  address public owner;
}

/*
This file is part of WeiFund.
*/


/*
This implements ONLY the standard functions and NOTHING else.
For a token like you would want to deploy in something like Mist, see HumanStandardToken.sol.

If you deploy this, you won&#39;t have anything useful.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/
/*
This file is part of WeiFund.
*/


contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


/*
This file is part of WeiFund.
*/

/*
Used for contracts that have an issuer.
*/



/// @title Issued - interface used for build issued asset contracts
/// @author Nick Dodson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="56383f353d7832393225393816353938253338252f2578383322">[email&#160;protected]</a>>
contract Issued {
  /// @notice will set the asset issuer address
  /// @param _issuer The address of the issuer
  function setIssuer(address _issuer) public {}
}



/// @title Issued token contract allows new tokens to be issued by an issuer.
/// @author Nick Dodson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c9a7a0aaa2e7ada6adbaa6a789aaa6a7baaca7bab0bae7a7acbd">[email&#160;protected]</a>>
contract IssuedToken is Owned, Issued, StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) {
    // if the issuer is attempting transfer
    // then mint new coins to address of transfer
    // by using transfer, we dont need to switch StandardToken API method
    if (msg.sender == issuer && (lastIssuance == 0 || block.number < lastIssuance)) {
      // increase the balance of user by transfer amount
      balances[_to] += _value;

      // increase total supply by balance
      totalSupply += _value;

      // return required true value for transfer
      return true;
    } else {
      if (freezePeriod == 0 || block.number > freezePeriod) {
        // continue with a normal transfer
        return super.transfer(_to, _value);
      }
    }
  }

  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
    // if we are passed the free period, then transferFrom
    if (freezePeriod == 0 || block.number > freezePeriod) {
      // return transferFrom
      return super.transferFrom(_from, _to, _value);
    }
  }

  function setIssuer(address _issuer) public onlyowner() {
    // set the issuer
    if (issuer == address(0)) {
      issuer = _issuer;
    } else {
      throw;
    }
  }

  function IssuedToken(
    address[] _addrs,
    uint256[] _amounts,
    uint256 _freezePeriod,
    uint256 _lastIssuance,
    address _owner,
    string _name,
    uint8 _decimals,
    string _symbol) {
    // issue the initial tokens, if any
    for (uint256 i = 0; i < _addrs.length; i ++) {
      // increase balance of that address
      balances[_addrs[i]] += _amounts[i];

      // increase token supply of that address
      totalSupply += _amounts[i];
    }

    // set the transfer freeze period, if any
    freezePeriod = _freezePeriod;

    // set the token owner, who can set the issuer
    owner = _owner;

    // set the blocknumber of last issuance, if any
    lastIssuance = _lastIssuance;

    // set token name
    name = _name;

    // set decimals
    decimals = _decimals;

    // set sumbol
    symbol = _symbol;
  }

  // the transfer freeze period
  uint256 public freezePeriod;

  // the block number of last issuance (set to zero, if none)
  uint256 public lastIssuance;

  // the token issuer address, if any
  address public issuer;

  // token name
  string public name;

  // token decimals
  uint8 public decimals;

  // symbol
  string public symbol;

  // verison
  string public version = "WFIT1.0";
}


/// @title Private Service Registry - used to register generated service contracts.
/// @author Nick Dodson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0c62656f67226863687f63624c6f63627f69627f757f22626978">[email&#160;protected]</a>>
contract PrivateServiceRegistryInterface {
  /// @notice register the service &#39;_service&#39; with the private service registry
  /// @param _service the service contract to be registered
  /// @return the service ID &#39;serviceId&#39;
  function register(address _service) internal returns (uint256 serviceId) {}

  /// @notice is the service in question &#39;_service&#39; a registered service with this registry
  /// @param _service the service contract address
  /// @return either yes (true) the service is registered or no (false) the service is not
  function isService(address _service) public constant returns (bool) {}

  /// @notice helps to get service address
  /// @param _serviceId the service ID
  /// @return returns the service address of service ID
  function services(uint256 _serviceId) public constant returns (address _service) {}

  /// @notice returns the id of a service address, if any
  /// @param _service the service contract address
  /// @return the service id of a service
  function ids(address _service) public constant returns (uint256 serviceId) {}

  event ServiceRegistered(address _sender, address _service);
}

contract PrivateServiceRegistry is PrivateServiceRegistryInterface {

  modifier isRegisteredService(address _service) {
    // does the service exist in the registry, is the service address not empty
    if (services.length > 0) {
      if (services[ids[_service]] == _service && _service != address(0)) {
        _;
      }
    }
  }

  modifier isNotRegisteredService(address _service) {
    // if the service &#39;_service&#39; is not a registered service
    if (!isService(_service)) {
      _;
    }
  }

  function register(address _service)
    internal
    isNotRegisteredService(_service)
    returns (uint serviceId) {
    // create service ID by increasing services length
    serviceId = services.length++;

    // set the new service ID to the &#39;_service&#39; address
    services[serviceId] = _service;

    // set the ids store to link to the &#39;serviceId&#39; created
    ids[_service] = serviceId;

    // fire the &#39;ServiceRegistered&#39; event
    ServiceRegistered(msg.sender, _service);
  }

  function isService(address _service)
    public
    constant
    isRegisteredService(_service)
    returns (bool) {
    return true;
  }

  address[] public services;
  mapping(address => uint256) public ids;
}

/// @title Issued Token Factory - used to generate and register IssuedToken contracts
/// @author Nick Dodson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="93fdfaf0f8bdf7fcf7e0fcfdd3f0fcfde0f6fde0eae0bdfdf6e7">[email&#160;protected]</a>>
contract IssuedTokenFactory is PrivateServiceRegistry {
  function createIssuedToken(
    address[] _addrs,
    uint256[] _amounts,
    uint256 _freezePeriod,
    uint256 _lastIssuance,
    string _name,
    uint8 _decimals,
    string _symbol)
  public
  returns (address tokenAddress) {
    // create a new multi sig wallet
    tokenAddress = address(new IssuedToken(
      _addrs,
      _amounts,
      _freezePeriod,
      _lastIssuance,
      msg.sender,
      _name,
      _decimals,
      _symbol));

    // register that multisig wallet address as service
    register(tokenAddress);
  }
}