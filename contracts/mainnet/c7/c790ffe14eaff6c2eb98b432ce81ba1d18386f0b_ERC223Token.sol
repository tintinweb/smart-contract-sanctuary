pragma solidity ^0.4.20;
/**
* @notice TOKEN CONTRACT
* @dev ERC-223 Token Standar Compliant
* @author Fares A. Akel C. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="aec880cfc0dac1c0c7c180cfc5cbc2eec9c3cfc7c280cdc1c3">[email&#160;protected]</a>
*/
 
/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a / b;
      return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

/**
 * @title ERC223 Token interface
 * @dev Code based on Dexaran&#39;s one on github as recommended on ERC223 discussion
 */

contract ERC223Interface {
    
  function balanceOf(address who) constant public returns (uint256);
  
  function name() constant public returns (string _name);
  function symbol() constant public returns (string _symbol);
  function decimals() constant public returns (uint8 _decimals);
  function totalSupply() constant public returns (uint256 _supply);
  function transfer(address to, uint256 value) public returns (bool ok);
  function transfer(address to, uint256 value, bytes data) public returns (bool ok);
  function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
  event Burned(address indexed _target, uint256 _value);
  event FrozenStatus(address _target,bool _flag);
}

 contract ContractReceiver {
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

/**
 * @title ERC223 Token definition
 * @dev Code based on Dexaran&#39;s one on github as recommended on ERC223 discussion
 */
 
contract ERC223Token is ERC223Interface {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

  string public name    = "Billionaire Maker";
  string public symbol  = "BMX";
  uint8 public decimals = 9;
  uint256 public totalSupply;
  
  function ERC223Token() public
  {
    bytes memory empty;
    totalSupply = 1000000000 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply;
    emit Transfer(0, this, totalSupply, empty);
    emit Transfer(this, msg.sender, totalSupply, empty);
  }
  
  
  // Function to access name of token .
  function name() constant public returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant public returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant public returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant public returns (uint256 _totalSupply) {
      return totalSupply;
  }  
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {

    if(isContract(_to)) {
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint256 _value) public returns (bool success) {

    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
      uint256 length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}