// Bubble token air drop smart contract.
// Developed by Phenom.Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7f161119103f0f171a111012510b1a1e12">[email&#160;protected]</a>>
pragma solidity ^0.4.18;

/**
 *   @title SafeMath
 *   @dev Math operations with safety checks that throw on error
 */

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns(uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal constant returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 *   @title ERC20
 *   @dev Standart ERC20 token interface
 */

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

/**
 *   @title BubbleToneToken
 *   @dev Universal Bonus Token contract
 */
contract BubbleToneToken is ERC20 {
    using SafeMath for uint;
    string public name = "Universal Bonus Token | t.me/bubbletonebot";
    string public symbol = "UBT";
    uint public decimals = 18;  

    // Smart-contract owner address
    address public owner;
    
    //events
    event Burn(address indexed _from, uint _value);
    event Mint(address indexed _to, uint _value);
    event ManagerAdded(address _manager);
    event ManagerRemoved(address _manager);
    event Defrosted(uint timestamp);
    event Frosted(uint timestamp);

    // Tokens transfer ability status
    bool public tokensAreFrozen = true;

    // mapping of user permissions
    mapping(address => bool) public isManager;


    // Allows execution by the owner only
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }

    // Allows execution by the managers only
    modifier onlyManagers { 
        require(isManager[msg.sender]); 
        _; 
    }


   /**
    *   @dev Contract constructor function sets owner address
    *   @param _owner        owner address
    */
    function BubbleToneToken(address _owner) public {
       owner = _owner;
       isManager[_owner] = true;
    }

   /**
    *   @dev Get balance of tokens holder
    *   @param _holder        holder&#39;s address
    *   @return               balance of investor
    */
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

   /**
    *   @dev Send coins
    *   throws on any error rather then return a false flag to minimize
    *   user errors
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        require(_to != address(0) && _to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

   /**
    *   @dev An account/contract attempts to get the coins
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   @param _from         source address
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


   /**
    *   @dev Allows another account/contract to spend some tokens on its behalf
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _amount       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

   /**
    *   @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    *   @param _owner        the address which owns the funds
    *   @param _spender      the address which will spend the funds
    *
    *   @return              the amount of tokens still avaible for the spender
    */
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }



  /**
   * @dev Function to add an address to the managers
   * @param _manager         an address that will be added to managers list
   */
    function addManager(address _manager) onlyOwner external {
        require(!isManager[_manager]);
        isManager[_manager] = true;
        ManagerAdded(_manager);
    }

  /**
   * @dev Function to remove an address to the managers
   * @param _manager         an address that will be removed from managers list
   */
    function removeManager(address _manager) onlyOwner external {
        require(isManager[_manager]);
        isManager[_manager] = false;
        ManagerRemoved(_manager);
    }

   /**
    *   @dev Function to enable token transfers
    */
    function unfreeze() external onlyOwner {
       tokensAreFrozen = false;
       Defrosted(now);
    }


   /**
    *   @dev Function to enable token transfers
    */
    function freeze() external onlyOwner {
       tokensAreFrozen = true;
       Frosted(now);
    }



    /**
     * @dev Function to batch mint tokens
     * @param                _holders an array of addresses that will receive the promo tokens.
     * @param                _amount an array with the amounts of tokens each address will get minted.
     */
    function batchMint(
        address[] _holders, 
        uint[] _amount) 
        external
        onlyManagers {
        require(_holders.length == _amount.length);
        for (uint i = 0; i < _holders.length; i++) {
            require(_mint(_holders[i], _amount[i]));
        }
    }

   /**
    *   @dev Function to burn Tokens
    *   @param _holder       token holder address which the tokens will be burnt
    *   @param _value        number of tokens to burn
    */
    function burnTokens(address _holder, uint _value) external onlyManagers {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
    }



    /** 
    *   @dev Allows owner to transfer out any accidentally sent ERC20 tokens
    *
    *   @param _token        token address
    *   @param _amount       transfer amount
    *
    *
    */
    function withdraw(address _token, uint _amount) 
        external
        onlyOwner 
        returns (bool success) {
        return ERC20(_token).transfer(owner, _amount);
    }

   /**
    *   @dev Function to mint tokens
    *   @param _holder       beneficiary address the tokens will be issued to
    *   @param _value        amount of tokens to issue
    */
    function _mint(address _holder, uint _value) private returns (bool) {
        require(_value > 0);
        require(_holder != address(0) && _holder != address(this));
        balances[_holder] = balances[_holder].add(_value);
        totalSupply = totalSupply.add(_value);
        Transfer(address(0), _holder, _value);
        return true;
    }

}