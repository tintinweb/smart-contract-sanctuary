pragma solidity ^0.4.13;

 /// @title Ownable contract - base contract with an owner
 /// @author <span class="__cf_email__" data-cfemail="a1c5c4d7e1d2ccc0d3d5c2cecfd5d3c0c2d5c4c0cc8fc2cecc">[email&#160;protected]</span>
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);  
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

/// @title Haltable contract - abstract contract that allows children to implement an emergency stop mechanism.
/// @author <span class="__cf_email__" data-cfemail="4723223107342a263533242829333526243322262a6924282a">[email&#160;protected]</span>
/// Originally envisioned in FirstBlood ICO contract.
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);       
    _;
  }

  /// called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  /// called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }
}



 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
 /// @author <span class="__cf_email__" data-cfemail="f89c9d8eb88b95998a8c9b97968c8a999b8c9d9995d69b9795">[email&#160;protected]</span>
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function mint(address receiver, uint amount);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 /// @title SafeMath contract - math operations with safety checks
 /// @author <span class="__cf_email__" data-cfemail="482c2d3e083b25293a3c2b27263c3a292b3c2d2925662b2725">[email&#160;protected]</span>
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    require(assertion);  
  }
}


/// @title SolarDaoToken contract - standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
/// @author <span class="__cf_email__" data-cfemail="4e2a2b380e3d232f3c3a2d21203a3c2f2d3a2b2f23602d2123">[email&#160;protected]</span>
contract SolarDaoToken is SafeMath, ERC20, Ownable {
 string public name = "Solar DAO Token";
 string public symbol = "SDAO";
 uint public decimals = 4;

 /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
 address public crowdsaleAgent;
 /// A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.
 bool public released = false;
 /// approve() allowances
 mapping (address => mapping (address => uint)) allowed;
 /// holder balances
 mapping(address => uint) balances;

 /// @dev Limit token transfer until the crowdsale is over.
 modifier canTransfer() {
   if(!released) {
       require(msg.sender == crowdsaleAgent);
   }
   _;
 }

 /// @dev The function can be called only before or after the tokens have been releasesd
 /// @param _released token transfer and mint state
 modifier inReleaseState(bool _released) {
   require(_released == released);
   _;
 }

 /// @dev The function can be called only by release agent.
 modifier onlyCrowdsaleAgent() {
   require(msg.sender == crowdsaleAgent);
   _;
 }

 /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
 /// @param size payload size
 modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
 }

 /// @dev Make sure we are not done yet.
 modifier canMint() {
    require(!released);
    _;
  }

 /// @dev Constructor
 function SolarDaoToken() {
   owner = msg.sender;
 }

 /// Fallback method will buyout tokens
 function() payable {
   revert();
 }

 /// @dev Create new tokens and allocate them to an address. Only callably by a crowdsale contract
 /// @param receiver Address of receiver
 /// @param amount  Number of tokens to issue.
 function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);
    Transfer(0, receiver, amount);
 }

 /// @dev Set the contract that can call release and make the token transferable.
 /// @param _crowdsaleAgent crowdsale contract address
 function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
   crowdsaleAgent = _crowdsaleAgent;
 }
 /// @dev One way function to release the tokens to the wild. Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
 function releaseTokenTransfer() public onlyCrowdsaleAgent {
   released = true;
 }
 /// @dev Tranfer tokens to address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
   balances[msg.sender] = safeSub(balances[msg.sender], _value);
   balances[_to] = safeAdd(balances[_to], _value);

   Transfer(msg.sender, _to, _value);
   return true;
 }

 /// @dev Tranfer tokens from one address to other
 /// @param _from source address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
   var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
 }
 /// @dev Tokens balance
 /// @param _owner holder address
 /// @return balance amount
 function balanceOf(address _owner) constant returns (uint balance) {
   return balances[_owner];
 }

 /// @dev Approve transfer
 /// @param _spender holder address
 /// @param _value tokens amount
 /// @return result
 function approve(address _spender, uint _value) returns (bool success) {
   // To change the approve amount you first have to reduce the addresses`
   //  allowance to zero by calling `approve(_spender, 0)` if it is not
   //  already 0 to mitigate the race condition described here:
   //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

   allowed[msg.sender][_spender] = _value;
   Approval(msg.sender, _spender, _value);
   return true;
 }

 /// @dev Token allowance
 /// @param _owner holder address
 /// @param _spender spender address
 /// @return remain amount
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
   return allowed[_owner][_spender];
 }
}