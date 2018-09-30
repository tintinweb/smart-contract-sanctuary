pragma solidity ^0.4.24;
/**
* @notice Block Coin Bit Token Contract
* @dev ERC-223 Token Standar Compliant
* Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="731212011c1d04121f07160115011200160133141e121a1f5d101c1e">[email&#160;protected]</a>
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

  function mintToken(address _target, uint256 _mintedAmount) public returns (bool success);
  function burnToken(uint256 _burnedAmount) public returns (bool success);

  function transfer(address to, uint256 value) public returns (bool ok);
  function transfer(address to, uint256 value, bytes data) public returns (bool ok);
  function transfer(address to, uint256 value, bytes data, bytes custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
  event Burned(address indexed _target, uint256 _value);
}

 contract ContractReceiver {
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    bool public lockSupply; //Mint and Burn Lock flag

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() { //A modifier to lock mint and burn transactions
        require(lockSupply == false);
        _;
    }

   /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

   /**
    * @dev Function to set mint and burn locks
    * @param _set boolean flag (true | false)
    */
    function setSupplyLock(bool _set) onlyAdmin public { //Only the admin can set a lock on supply
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

    //All admin actions have a log for public review
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
 * @title ERC223 Token definition
 * @dev Code based on Dexaran&#39;s one on github as recommended on ERC223 discussion
 */

contract ERC223Token is admined,ERC223Interface {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

  string public name    = "Block Coin Bit";
  string public symbol  = "BLCB";
  uint8 public decimals = 8;
  uint256 public totalSupply;
  address initialOwner = 0x0D77002Affd96A22635bB46EC98F23EB99e12253;

  constructor() public
  {
    bytes memory empty;
    totalSupply = 12000000000 * (10 ** uint256(decimals));
    balances[initialOwner] = totalSupply;
    emit Transfer(0, this, totalSupply, empty);
    emit Transfer(this, initialOwner, balances[initialOwner], empty);
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

  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
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

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint256 _value, bytes _data, bytes _custom_fallback) public returns (bool success) {

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

  function mintToken(address _target, uint256 _mintedAmount) onlyAdmin supplyLock public returns (bool success) {
    bytes memory empty;
    balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
    totalSupply = SafeMath.add(totalSupply, _mintedAmount);
    emit Transfer(0, this, _mintedAmount,empty);
    emit Transfer(this, _target, _mintedAmount,empty);
    return true;
  }

  function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public returns (bool success) {
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
    totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
    emit Burned(msg.sender, _burnedAmount);
    return true;
  }

}