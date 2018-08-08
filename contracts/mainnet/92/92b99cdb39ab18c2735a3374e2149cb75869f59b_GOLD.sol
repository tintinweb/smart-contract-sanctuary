pragma solidity ^0.4.4;

contract SafeMath {
     function safeMul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
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

     function assert(bool assertion) internal {
          if (!assertion) throw;
     }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
contract Token is SafeMath {
     // Functions:
     /// @return total amount of tokens
     function totalSupply() constant returns (uint256 supply) {}

     /// @param _owner The address from which the balance will be retrieved
     /// @return The balance
     function balanceOf(address _owner) constant returns (uint256 balance) {}

     /// @notice send `_value` token to `_to` from `msg.sender`
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     function transfer(address _to, uint256 _value) {}

     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return Whether the transfer was successful or not
     function transferFrom(address _from, address _to, uint256 _value){}

     /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @param _value The amount of wei to be approved for transfer
     /// @return Whether the approval was successful or not
     function approve(address _spender, uint256 _value) returns (bool success) {}

     /// @param _owner The address of the account owning tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @return Amount of remaining tokens allowed to spent
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

     // Events:
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StdToken is Token {
     // Fields:
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public totalSupply = 0;

     // Functions:
     function transfer(address _to, uint256 _value) {
          if((balances[msg.sender] < _value) || (balances[_to] + _value <= balances[_to])) {
               throw;
          }

          balances[msg.sender] -= _value;
          balances[_to] += _value;
          Transfer(msg.sender, _to, _value);
     }

     function transferFrom(address _from, address _to, uint256 _value) {
          if((balances[_from] < _value) || 
               (allowed[_from][msg.sender] < _value) || 
               (balances[_to] + _value <= balances[_to])) 
          {
               throw;
          }

          balances[_to] += _value;
          balances[_from] -= _value;
          allowed[_from][msg.sender] -= _value;

          Transfer(_from, _to, _value);
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

     modifier onlyPayloadSize(uint _size) {
          if(msg.data.length < _size + 4) {
               throw;
          }
          _;
     }
}

contract GOLD is StdToken {
/// Fields:
     string public constant name = "Goldmint GOLD Token";
     string public constant symbol = "GOLD";
     uint public constant decimals = 18;

     address public creator = 0x0;
     address public tokenManager = 0x0;

     // lock by default all methods
     bool public lock = true;

/// Modifiers:
     modifier onlyCreator() { if(msg.sender != creator) throw; _; }
     modifier onlyCreatorOrTokenManager() { if((msg.sender!=creator) && (msg.sender!=tokenManager)) throw; _; }

     function setCreator(address _creator) onlyCreator {
          creator = _creator;
     }

     function setTokenManager(address _manager) onlyCreator {
          tokenManager = _manager;
     }

     function lockContract(bool _lock) onlyCreator {
          lock = _lock;
     }

/// Functions:
     /// @dev Constructor
     function GOLD() {
          creator = msg.sender;
          tokenManager = msg.sender;
     }

     /// @dev Override
     function transfer(address _to, uint256 _value) public {
          if(lock && (msg.sender!=tokenManager)){
               throw;
          }

          super.transfer(_to,_value);
     }

     /// @dev Override
     function transferFrom(address _from, address _to, uint256 _value)public{
          if(lock && (msg.sender!=tokenManager)){
               throw;
          }

          super.transferFrom(_from,_to,_value);
     }

     /// @dev Override
     function approve(address _spender, uint256 _value) public returns (bool) {
          if(lock && (msg.sender!=tokenManager)){
               throw;
          }

          return super.approve(_spender,_value);
     }

     function issueTokens(address _who, uint _tokens) onlyCreatorOrTokenManager {
          if(lock && (msg.sender!=tokenManager)){
               throw;
          }

          balances[_who] += _tokens;
          totalSupply += _tokens;
     }

     function burnTokens(address _who, uint _tokens) onlyCreatorOrTokenManager {
          if(lock && (msg.sender!=tokenManager)){
               throw;
          }

          balances[_who] = safeSub(balances[_who], _tokens);
          totalSupply = safeSub(totalSupply, _tokens);
     }

     // Do not allow to send money directly to this contract
     function() {
          throw;
     }
}