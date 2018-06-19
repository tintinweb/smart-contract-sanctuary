pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------------------------
// Moviecoin Token by Xender Limited.
// An ERC20 standard
//
// author: Xender Team
// Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="33405641455a5056734b565d5756411d505c5e">[email&#160;protected]</a>
// ----------------------------------------------------------------------------------------------

/*
    Standard Token interface
*/
contract ERC20Interface {
     // Get the total token name
    function name() public constant returns (string);

    // Get the total token symbol
    function symbol() public constant returns (string); 

    // Get the total token decimals
    function decimals() public constant returns (uint);

    // Get the total token supply
    function totalSupply() public constant returns (uint256);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256);
  
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256);
   
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
    owned manager
*/
contract Owned {

	// Owner of this contract
    address owner;
    
    // permit transaction
    bool isLock = true;
    
    // white list
    mapping(address => bool) whitelisted;
 
    
    function Owned() public {
        owner = msg.sender;
        whitelisted[owner] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier isUnlock () {
        if (isLock){
            require(whitelisted[msg.sender] == true);
        }
        _;
    }
	
	 /**
     * add new address to white list
     */
     function addWhitelist(address _white) public onlyOwner {
         whitelisted[_white] = true;
     }
     
    /**
     * remove address from white list
     */
    function removeWhitelist(address _white) public onlyOwner {
        whitelisted[_white] = false;
    }
      
    /**
     * check whether the address is in the white list
     */
    function checkWhitelist(address _addr) public view returns (bool) {
        return whitelisted[_addr];
    }
    
    /**
    * unlock token. Only after unlock can it be traded.
    */
    function unlockToken() public onlyOwner returns (bool) {
        isLock = false;
        return isLock;
    } 
}

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }
    
    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);
        return _x - _y;
    }
}

/*
    Moviecoin Token
*/
contract Moviecoin is ERC20Interface, Owned, Utils {
    string name_ = &#39;Dayibi&#39;;  
    string  symbol_ = &#39;DYB&#39;;
    uint8 decimals_ = 8; 
    uint256 totalSupply_ = 10 ** 18;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function Moviecoin() public {
        balances[msg.sender] = totalSupply_;
        Transfer(0x0, msg.sender, totalSupply_);
    }

  /**
  * @dev token&#39;s symbol
  */
  
  function name() public constant returns (string){
      return name_;
  }
  
  /**
   * @dev set token name
   */
   function setName(string _name) public onlyOwner {
       name_ = _name;
   }

  
  /**
  * @dev token&#39;s symbol
  */
  function symbol() public constant returns (string){
      return symbol_;
  }
  
   /**
   * @dev set token symbol
   */
   function setSymbol(string _symbol) public onlyOwner {
       symbol_ = _symbol;
   }
    
  /**
  * @dev token&#39;s decimals
  */
   function decimals() public constant returns (uint){
        return decimals_;
   }
 
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Get the account balance of another account with address _owner
  */
  function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
  }
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public isUnlock returns (bool) {
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public isUnlock returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public isUnlock validAddress(_spender) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  /**
   * @dev Don&#39;t accept ETH
   */
   function () public payable {
       revert();
   }
   
   /**
    * @dev Owner can transfer out any accidentally sent ERC20 tokens
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}