/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity ^0.4.26;




contract SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


}


contract TGBT is SafeMath {
      
    
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
  
    uint256 public totalSupply;

  
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);


    constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }
    
    
    /**
     * _transfer Moves tokens `_value` from `_from` to `_to`.
     *     
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_value`.
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_from != 0x0);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
       // no need  uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] = safeSub(balanceOf[_from],_value); // subtract from sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value); // add the same to the reciptient
        emit Transfer(_from, _to, _value);
      // no need   assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    
    
   /**
     * _approve Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != 0x0);
        require(spender != 0x0);

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /**
     *transfer
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - the caller must have a balance of at least `_value`.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * transferFrom
     *
     * Emits an {Approval} event indicating the updated allowance.
     * 
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_value`.
     * - the caller must have allowance for ``_from``'s tokens of at least
     * `_value`.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        _approve(_from, msg.sender, safeSub(allowance[_from][msg.sender],_value));
        _transfer(_from, _to, _value);
        return true;
    }
    
   /**
     * approve
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
    
   /**
     * increaseAllowance
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     */
     
    function increaseAllowance(address _spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, _spender, safeAdd(allowance[msg.sender][_spender],addedValue));
        return true;
    }

   /**
     * decreaseAllowance
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address _spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, _spender, safeSub(allowance[msg.sender][_spender],subtractedValue));
        return true;
    }

   /**
     * burn  
     * Destroys `_value` tokens from the caller.
     *
     */
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);                              // Check if the sender has enough
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);            // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                               // Updates totalSupply
        emit  Transfer(msg.sender, address(0), _value);
        return true;
    }

   /**
     * burnFrom
     * Destroys `_value` tokens from `_from`, deducting from the caller's
     * allowance.
     *
     *
     * Requirements:
     *
     * - the caller must have allowance for ``_from``'s tokens of at least
     * `_value`.
     */
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);                         // Check allowance
        require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
        
        uint256 decreasedAllowance = safeSub(allowance[_from][msg.sender],_value);
        _approve(_from, msg.sender,decreasedAllowance);
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                         // Subtract from the targeted balance
        totalSupply = safeSub(totalSupply,_value) ;                                  // Update totalSupply
        emit Transfer(_from, address(0), _value);
        return true;
    }
}