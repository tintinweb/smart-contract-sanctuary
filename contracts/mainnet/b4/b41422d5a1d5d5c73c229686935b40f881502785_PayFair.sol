pragma solidity ^0.5.0;

 /// @title Ownable contract - base contract with an owner
contract Ownable {
  address public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowance(address owner, address spender) public view returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 /// @title SafeMath contract - math operations with safety checks
contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}


/// @title PayFair contract - standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
contract PayFair is SafeMath, ERC20, Ownable {
 string public name = "PayFair Token";
 string public symbol = "PFR";
 uint public constant decimals = 8;
 uint public constant FROZEN_TOKENS = 11e6;
 uint public constant MULTIPLIER = 10 ** decimals;
 ERC20 public oldToken;
 
 /// approve() allowances
 mapping (address => mapping (address => uint)) allowed;
 /// holder balances
 mapping(address => uint) balances;
 
 /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
 /// @param size payload size
 modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
 }

 /// @dev Constructor
 constructor (address oldTokenAdddress) public {
   owner = msg.sender;
   oldToken = ERC20(oldTokenAdddress);
   
   totalSupply = convertToDecimal(FROZEN_TOKENS);
   balances[owner] = convertToDecimal(FROZEN_TOKENS);
 }

 /// Fallback method will buyout tokens
 function() external payable {
   revert();
 }

 function upgradeTokens(uint amountToUpgrade) public {  
    require(amountToUpgrade <= convertToDecimal(oldToken.balanceOf(msg.sender)));
    require(amountToUpgrade <= convertToDecimal(oldToken.allowance(msg.sender, address(this))));   
    
    emit Transfer(address(0), msg.sender, amountToUpgrade);
    totalSupply = safeAdd(totalSupply, amountToUpgrade);
    balances[msg.sender] = safeAdd(balances[msg.sender], amountToUpgrade);
    oldToken.transferFrom(msg.sender, address(0x0), amountToUpgrade);
 }

 /// @dev Converts token value to value with decimal places
 /// @param amount Source token value
 function convertToDecimal(uint amount) private pure returns (uint) {
   return safeMul(amount, MULTIPLIER);
 }

 /// @dev Tranfer tokens to address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
   balances[msg.sender] = safeSub(balances[msg.sender], _value);
   balances[_to] = safeAdd(balances[_to], _value);

   emit Transfer(msg.sender, _to, _value);
   return true;
 }

 /// @dev Tranfer tokens from one address to other
 /// @param _from source address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
 }
 /// @dev Tokens balance
 /// @param _owner holder address
 /// @return balance amount
 function balanceOf(address _owner) public view returns (uint balance) {
   return balances[_owner];
 }

 /// @dev Approve transfer
 /// @param _spender holder address
 /// @param _value tokens amount
 /// @return result
 function approve(address _spender, uint _value) public returns (bool success) {
   // To change the approve amount you first have to reduce the addresses`
   //  allowance to zero by calling `approve(_spender, 0)` if it is not
   //  already 0 to mitigate the race condition described here:
   //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

   allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
   return true;
 }

 /// @dev Token allowance
 /// @param _owner holder address
 /// @param _spender spender address
 /// @return remain amount
 function allowance(address _owner, address _spender) public view returns (uint remaining) {
   return allowed[_owner][_spender];
 }
}