pragma solidity ^0.4.18;

contract ERC20Token{
    //ERC20 base standard
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// From https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable{
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// Put the additional safe module here, safe math and pausable
// From https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/lifecycle/Pausable.sol
// And https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract Safe is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
    
    // Check if it is safe to add two numbers
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // Check if it is safe to subtract two numbers
    function safeSubtract(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }
    // Check if it is safe to multiply two numbers
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

    // reject any ether
    function () public payable {
        require(msg.value == 0);
    }
}

// Adapted from zeppelin-solidity&#39;s BasicToken, StandardToken and BurnableToken contracts
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/BasicToken.sol
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/BurnableToken.sol
contract imaxChainToken is Safe, ERC20Token {
    string public constant name = &#39;Inverstment Management Asset Exchange&#39;;              // Set the token name for display
    string public constant symbol = &#39;IMAX&#39;;                                  // Set the token symbol for display
    uint8 public constant decimals = 18;                                     // Set the number of decimals for display
    uint256 public constant INITIAL_SUPPLY = 1e9 * 10**uint256(decimals);
    uint256 public totalSupply;
    string public version = &#39;1&#39;;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) freeze;

    event Burn(address indexed burner, uint256 value);
    
    modifier whenNotFreeze() {
        require(freeze[msg.sender]==0);
        _;
    }
    
    function imaxChainToken() public {
        totalSupply = INITIAL_SUPPLY;                              // Set the total supply
        balances[msg.sender] = INITIAL_SUPPLY;                     // Creator address is assigned all
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer(address _to, uint256 _value)  whenNotPaused whenNotFreeze public returns (bool success) {
        require(_to != address(this));
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused whenNotFreeze public returns (bool success) {
        require(_to != address(this));
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = safeSubtract(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }
    

    function approve(address _spender, uint256 _value) whenNotFreeze public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */

    function increaseApproval(address _spender, uint _addedValue) whenNotFreeze public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender],_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotFreeze public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = safeSubtract(oldValue,_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function updateFreeze(address account) onlyOwner public returns(bool success){
        if (freeze[account]==0){
          freeze[account]=1;
        }else{
          freeze[account]=0;
        }
        return true;
    }

    function freezeOf(address account) public view returns (uint256 status) {
        return freeze[account];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function burn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
      address burner = msg.sender;
      balances[burner] = safeSubtract(balances[burner],_value);
      totalSupply = safeSubtract(totalSupply, _value);
      Burn(burner, _value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }


}