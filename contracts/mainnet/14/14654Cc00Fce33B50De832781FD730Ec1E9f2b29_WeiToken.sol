pragma solidity ^0.4.18;


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract Admin is Ownable {
  mapping(address => bool) public adminlist;

  event AdminAddressAdded(address addr);
  event AdminAddressRemoved(address addr);

  function isAdmin() public view returns(bool) {
    if (owner == msg.sender) {
      return true;
    }
    return adminlist[msg.sender];
  }

  function isAdminAddress(address addr) view public returns(bool) {
    return adminlist[addr];
  }

  function addAddressToAdminlist(address addr) onlyOwner public returns(bool success) {
    if (!adminlist[addr]) {
      adminlist[addr] = true;
      AdminAddressAdded(addr);
      success = true;
    }
  }

  function removeAddressFromAdminlist(address addr) onlyOwner public returns(bool success) {
    if (adminlist[addr]) {
      adminlist[addr] = false;
      AdminAddressRemoved(addr);
      success = true;
    }
  }

}


contract Pausable is Ownable, Admin {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused || isAdmin());
    _;
  }

  modifier whenPaused() {
    require(paused || isAdmin());
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



contract ERC20 {

  function totalSupply() public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract SafeMath {

  function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x + y;
    assert((z >= x) && (z >= y));
    return z;
  }

  function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
    assert(x >= y);
    uint256 z = x - y;
    return z;
  }

  function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x * y;
    assert((x == 0)||(z/x == y));
    return z;
  }

  function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 z = x / y;
    return z;
  }
}


contract StandardToken is ERC20, SafeMath {
  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool){
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSubtract(balances[_from], _value);
    allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint) {
    return allowed[_owner][_spender];
  }

}

contract WeiToken is StandardToken, Pausable {
  string public constant name = "WeiToken";
  string public constant symbol = "YOUNG";
  uint256 public constant decimals = 18;
  string public version = "1.0";

  uint256 public constant total = 65 * (10**8) * 10**decimals;   // 20 *10^8 HNC total

  function WeiToken() public {
    balances[msg.sender] = total;
    Transfer(0x0, msg.sender, total);
  }

  function totalSupply() public view returns (uint256) {
    return total;
  }

  function transfer(address _to, uint _value) whenNotPaused public returns (bool success) {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) whenNotPaused public returns (bool success) {
    return super.approve(_spender,_value);
  }

  function airdropToAddresses(address[] addrs, uint256 amount) public {
    for (uint256 i = 0; i < addrs.length; i++) {
      transfer(addrs[i], amount);
    }
  }
}