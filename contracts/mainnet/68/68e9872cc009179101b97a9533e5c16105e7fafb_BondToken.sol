// Bond Film Platform Token smart contract.
// Developed by Phenom.Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7b12151d143b0b131e151416550f1e1a16">[email&#160;protected]</a>>
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
 *   @title BondToken
 *   @dev Bond Film Platform token contract
 */
contract BondToken is ERC20 {
    using SafeMath for uint;
    string public name = "Bond Film Platform";
    string public symbol = "BFP";
    uint public decimals = 18;

    // Ico contract address
    address public owner;
    address public controller;
    address public airDropManager;
    
    event LogBuyForInvestor(address indexed investor, uint value, string txHash);
    event Burn(address indexed from, uint value);
    event Mint(address indexed to, uint value);
    
    // Tokens transfer ability status
    bool public tokensAreFrozen = true;

    // Allows execution by the owner only
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }

    // Allows execution by the controller only
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    // Allows execution by the air drop manager only
    modifier onlyAirDropManager { 
        require(msg.sender == airDropManager); 
        _; 
    }

   /**
    *   @dev Contract constructor function sets Ico address
    *   @param _owner        owner address
    *   @param _controller   controller address
    *   @param _airDropManager  air drop manager address
    */
    function BondToken(address _owner, address _controller, address _airDropManager) public {
       owner = _owner;
       controller = _controller;
       airDropManager = _airDropManager; 
    }

   /**
    *   @dev Function to mint tokens
    *   @param _holder       beneficiary address the tokens will be issued to
    *   @param _value        number of tokens to issue
    */
    function mint(address _holder, uint _value) 
        private
        returns (bool) {
        require(_value > 0);
        balances[_holder] = balances[_holder].add(_value);
        totalSupply = totalSupply.add(_value);
        Transfer(address(0), _holder, _value);
        return true;
    }


   /**
    *   @dev Function for handle token issues
    *   @param _holder       beneficiary address the tokens will be issued to
    *   @param _value        number of tokens to issue
    */
    function mintTokens(
        address _holder, 
        uint _value) 
        external 
        onlyOwner {
        require(mint(_holder, _value));
        Mint(_holder, _value);
    }

   /**
    *   @dev Function to issues tokens for investors
    *   @param _holder     address the tokens will be issued to
    *   @param _value        number of BFP tokens
    *   @param _txHash       transaction hash of investor&#39;s payment
    */
    function buyForInvestor(
        address _holder, 
        uint _value, 
        string _txHash
    ) 
        external 
        onlyController {
        require(mint(_holder, _value));
        LogBuyForInvestor(_holder, _value, _txHash);
    }



    /**
     * @dev Function to batch mint tokens
     * @param _to An array of addresses that will receive the minted tokens.
     * @param _amount An array with the amounts of tokens each address will get minted.
     * @return A boolean that indicates whether the operation was successful.
     */
    function batchDrop(
        address[] _to, 
        uint[] _amount) 
        external
        onlyAirDropManager {
        require(_to.length == _amount.length);
        for (uint i = 0; i < _to.length; i++) {
            require(_to[i] != address(0));
            require(mint(_to[i], _amount[i]));
        }
    }


   /**
    *   @dev Function to enable token transfers
    */
    function unfreeze() external onlyOwner {
       tokensAreFrozen = false;
    }


   /**
    *   @dev Function to enable token transfers
    */
    function freeze() external onlyOwner {
       tokensAreFrozen = true;
    }

   /**
    *   @dev Burn Tokens
    *   @param _holder       token holder address which the tokens will be burnt
    *   @param _value        number of tokens to burn
    */
    function burnTokens(address _holder, uint _value) external onlyOwner {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
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
    *   @dev Allows owner to transfer out any accidentally sent ERC20 tokens
    *
    *   @param tokenAddress  token address
    *   @param tokens        transfer amount
    *
    *
    */
    function transferAnyTokens(address tokenAddress, uint tokens) 
        public
        onlyOwner 
        returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}