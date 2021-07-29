/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: none
pragma solidity 0.8.4; 

contract Owned {
    
    /// Modifier for owner only function call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    address public owner;
   
    /// Function to transfer ownership 
    /// Only owner can call this function
    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}

contract BEP20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address=>uint256) internal balances;
    mapping (address=>mapping (address=>uint256)) internal allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /// Returns the token balance of the address which is passed in parameter
    function balanceOf(address _owner) view public  returns (uint256 balance) {return balances[_owner];}
    
    /**
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        
        require(_to != address(0), "Transfer to zero address");
        require (balances[msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
     /**
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
      
        require(_from != address(0), "Sender cannot be zero address");
        require(_to != address(0), "Recipient cannot be zero address");
        require (balances[_from]>=_amount && allowed[_from][msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    /**
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Approval for zero address");
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     *  Returns allowance for an address approved for contract
     */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */ 
    function _burn(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract qaure  is Owned, BEP20 {
    
    /**
     * @dev Sets symbol, name, decimals and totalSupply of the token
     * 
     * - Sets msg.sender as the owner of the contract
     * - Transfers totalSupply to owner
     */ 
    constructor()   {
        symbol = "QRE";
        name = "qaure";
        decimals = 18;                                    
        totalSupply = 1000000000 * 10**18;           
       
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    /**
     * @dev Calls mint function from BEP20 contract
     * 
     * Requirements:
     * 
     * - only owner can call this function
     * - 'to' address cannot be zero address
     */
    function mint(address to, uint amount) external {
        require(msg.sender == owner, "only admin");
        require(to != address(0), "No mint to zero address");
        _mint(to, amount);
    }
    
    /**
     * @dev Calls burn function from BEP20 contract
     * 
     * Requirements:
     * 
     * - only owner can call this function
     * - 'from' address cannot be zero address
     */
    function burn(address from, uint amount) external {
        require(msg.sender == owner, "only admin");
        require(from != address(0), "No burn from zero address");
        _burn(from, amount);
    }
    
    
   
}