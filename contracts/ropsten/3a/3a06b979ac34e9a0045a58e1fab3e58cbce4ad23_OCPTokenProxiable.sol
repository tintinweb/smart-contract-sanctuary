pragma solidity ^0.4.24;

// imported contracts/proposals/OCP-IP-4/Proxiable.sol
// imported contracts/access/roles/ProxyManagerRole.sol
// imported /home/jeichel/workspace/ocp/node_modules/openzeppelin-solidity/contracts/access/Roles.sol
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }
  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));
    role.bearer[account] = true;
  }
  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));
    role.bearer[account] = false;
  }
  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract ProxyManagerRole {
  using Roles for Roles.Role;
  event ProxyManagerAdded(address indexed account);
  event ProxyManagerRemoved(address indexed account);
  Roles.Role private proxyManagers;
  constructor() public {
    proxyManagers.add(msg.sender);
  }
  modifier onlyProxyManager() {
    require(isProxyManager(msg.sender));
    _;
  }
  function isProxyManager(address account) public view returns (bool) {
    return proxyManagers.has(account);
  }
  function addProxyManager(address account) public onlyProxyManager {
    proxyManagers.add(account);
    emit ProxyManagerAdded(account);
  }
  function renounceProxyManager() public {
    proxyManagers.remove(msg.sender);
  }
  function _removeProxyManager(address account) internal {
    proxyManagers.remove(account);
    emit ProxyManagerRemoved(account);
  }
}

// implementation from https://github.com/open-city-protocol/OCP-IPs/blob/master/OCP-IPs/ocp-ip-4.md
contract Proxiable is ProxyManagerRole {
  mapping(address => bool) private _globalProxies; // proxy -> valid
  mapping(address => mapping(address => bool)) private _senderProxies; // sender -> proxy -> valid
  event ProxyAdded(address indexed proxy, uint256 updatedAtUtcSec);
  event ProxyRemoved(address indexed proxy, uint256 updatedAtUtcSec);
  event ProxyForSenderAdded(address indexed proxy, address indexed sender, uint256 updatedAtUtcSec);
  event ProxyForSenderRemoved(address indexed proxy, address indexed sender, uint256 updatedAtUtcSec);
  modifier proxyOrSender(address claimedSender) {
    require(isProxyOrSender(claimedSender));
    _;
  }
  function isProxyOrSender(address claimedSender) public view returns (bool) {
    return msg.sender == claimedSender ||
    _globalProxies[msg.sender] ||
    _senderProxies[claimedSender][msg.sender];
  }
  function isProxy(address proxy) public view returns (bool) {
    return _globalProxies[proxy];
  }
  function isProxyForSender(address proxy, address sender) public view returns (bool) {
    return _senderProxies[sender][proxy];
  }
  function addProxy(address proxy) public onlyProxyManager {
    require(!_globalProxies[proxy]);
    _globalProxies[proxy] = true;
    emit ProxyAdded(proxy, now); // solhint-disable-line
  }
  function removeProxy(address proxy) public onlyProxyManager {
    require(_globalProxies[proxy]);
    delete _globalProxies[proxy];
    emit ProxyRemoved(proxy, now); // solhint-disable-line
  }
  function addProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(!_senderProxies[sender][proxy]);
    _senderProxies[sender][proxy] = true;
    emit ProxyForSenderAdded(proxy, sender, now); // solhint-disable-line
  }
  function removeProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(_senderProxies[sender][proxy]);
    delete _senderProxies[sender][proxy];
    emit ProxyForSenderRemoved(proxy, sender, now); // solhint-disable-line
  }
}

// imported contracts/proposals/OCP-IP-6/OCPToken.sol
// imported /home/jeichel/workspace/ocp/node_modules/@open-city-protocol/erc223/contracts/ERC223_Token.sol
// imported /home/jeichel/workspace/ocp/node_modules/@open-city-protocol/erc223/contracts/Receiver_Interface.sol
 /*
 * Contract that is working with ERC223 tokens
 */
contract ContractReceiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

// imported /home/jeichel/workspace/ocp/node_modules/@open-city-protocol/erc223/contracts/ERC223_Interface.sol
 /* New ERC223 contract interface */
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  // solhint-disable-next-line
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMathERC223 {
  uint256 constant public MAX_UINT256 =
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x > MAX_UINT256 - y) revert();
    return x + y;
  }
  function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x < y) revert();
    return x - y;
  }
  function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (y == 0) return 0;
    if (x > MAX_UINT256 / y) revert();
    return x * y;
  }
}
contract ERC223Token is ERC223, SafeMathERC223 {
  mapping(address => uint) public balances;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  // Function to access name of token .
  function name() public view returns (string _name) {
    return name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string _symbol) {
    return symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 _totalSupply) {
    return totalSupply;
  }
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContractCustom(msg.sender, _to, _value, _data, _custom_fallback);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, _data);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, empty);
    } else {
      return transferToAddress(msg.sender, _to, _value, empty);
    }
  }
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) internal view returns (bool is_contract) {
    uint length;
    assembly { // solhint-disable-line
          //retrieve the size of the code on target address, this needs assembly
          length := extcodesize(_addr)
    }
    return (length > 0);
  }
  //function that is called when transaction target is an address
  function transferToAddress(address _from, address _to, uint _value, bytes _data) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(_from, _to, _value, _data);
    return true;
  }
  //function that is called when transaction target is a contract
  function transferToContract(address _from, address _to, uint _value, bytes _data) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value, _data);
    return true;
  }
  //function that is called when transaction target is a contract
  function transferToContractCustom(address _from, address _to, uint _value, bytes _data, string _custom_fallback) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    // solhint-disable-next-line
    assert(_to.call.value(0)(abi.encodeWithSignature(_custom_fallback, _from, _value, _data)));
    emit Transfer(_from, _to, _value, _data);
    return true;
  }
}

contract OCPToken is ERC223Token {
  constructor() public {
    name = "Open City Token";
    symbol = "OCT"; // todo: ensure unique symbol
    decimals = 18;
    totalSupply = 0xc9f2c9cd04674edea40000000; // 1 trillion coins
    balances[msg.sender] = totalSupply;
  }
}

// imported contracts/proposals/OCP-IP-6/IOCPTokenProxiable.sol
contract IOCPTokenProxiable is ERC223 {
  function proxyTransfer(address from, address to, uint value) public returns (bool ok);
  function proxyTransfer(address from, address to, uint value, bytes data) public returns (bool ok);
  function proxyTransfer(address from, address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
}

contract OCPTokenProxiable is OCPToken, IOCPTokenProxiable, Proxiable {
  // Function that is called when a user or another contract wants to transfer funds .
  function proxyTransfer(
    address _from,
    address _to,
    uint _value,
    bytes _data,
    string _custom_fallback
  ) public proxyOrSender(_from) returns (bool success) {
    if (isContract(_to)) {
      return transferToContractCustom(_from, _to, _value, _data, _custom_fallback);
    } else {
      return transferToAddress(_from, _to, _value, _data);
    }
  }
  // Function that is called when a user or another contract wants to transfer funds .
  function proxyTransfer(
    address _from,
    address _to,
    uint _value,
    bytes _data
  ) public proxyOrSender(_from) returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(_from, _to, _value, _data);
    } else {
      return transferToAddress(_from, _to, _value, _data);
    }
  }
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function proxyTransfer(
    address _from,
    address _to,
    uint _value
  ) public proxyOrSender(_from) returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_from, _to, _value, empty);
    } else {
      return transferToAddress(_from, _to, _value, empty);
    }
  }
}