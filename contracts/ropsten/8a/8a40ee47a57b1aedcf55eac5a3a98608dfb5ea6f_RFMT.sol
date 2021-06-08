/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2017-11-19
*/

pragma solidity ^0.4.18;

contract Ownable {

  address public owner = msg.sender;
  address private newOwner = address(0);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));      
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender != address(0));
    require(msg.sender == newOwner);

    owner = newOwner;
    newOwner = address(0);
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

  /**
   * the total token supply.
   */
  uint256 public totalSupply;

  /**
   * @param _owner The address from which the balance will be retrieved
   * @return The balance
   */
  function balanceOf(address _owner) public constant returns (uint256 balance);

  /**
   * @notice send `_value` token to `_to` from `msg.sender`
   * @param _to The address of the recipient
   * @param _value The amount of token to be transferred
   * @return Whether the transfer was successful or not
   */
  function transfer(address _to, uint256 _value) public returns (bool success);

  /**
   * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value The amount of token to be transferred
   * @return Whether the transfer was successful or not
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /**
   * @notice `msg.sender` approves `_spender` to spend `_value` tokens
   * @param _spender The address of the account able to transfer the tokens
   * @param _value The amount of tokens to be approved for transfer
   * @return Whether the approval was successful or not
   */
  function approve(address _spender, uint256 _value) public returns (bool success);

  /**
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to transfer the tokens
   * @return Amount of remaining tokens allowed to spent
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  /**
   * MUST trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * MUST trigger on any successful call to approve(address _spender, uint256 _value)
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * @title Standard ERC20 token
 *
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol
 */
contract ERC20Token is ERC20 {

  using SafeMath for uint256;

  mapping (address => uint256) balances;
  
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] +=_value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0);

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    balances[_to] += _value;
    
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
 
}

contract RFMT is ERC20Token, Ownable {
    
  string public constant name = "Rescue Mission Finance Token";
  string public constant symbol = "RMFT";
  uint8 public constant decimals = 18;

  function RFMT() public {
    totalSupply = 200000000 *10 **18;
    balances[owner] = totalSupply;
    Transfer(address(0), owner, totalSupply);
  }
  
  function acceptOwnership() public {
    address oldOwner = owner;
    super.acceptOwnership();
    balances[owner] = balances[oldOwner];
    balances[oldOwner] = 0;
    Transfer(oldOwner, owner, balances[owner]);
  }
  
   function() external payable {
   
  }
    
    function extractEther() public onlyOwner {
      owner.transfer(address(this).balance);
   }
   
    function _mint(address account, uint256 amount) internal  {
       
        

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        Transfer(address(0), account, amount);
    }
    
    function mint(address account, uint256 amount) public onlyOwner  {
        _mint(account, amount);
    }
    
    function _burn(address account, uint256 amount) internal  {
        

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        Transfer(account, address(0), amount);
    }
    
    function burn(address account, uint256 amount) public onlyOwner{
        _burn(account, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  { }


}