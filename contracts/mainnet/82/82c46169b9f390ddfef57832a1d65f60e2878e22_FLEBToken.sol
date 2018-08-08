pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract FLEBToken{
    
 address public owner;
 string public name = "FLEBToken"; //Token name
 string public symbol = "FLB";
 uint8 public decimals = 18;       //일반적으로 18로 많이 사용.
 uint256 public totalSupply = 0; 
 
 mapping(address => uint256) balances;
 mapping(address => mapping(address => uint256)) internal allowed; //누가 누구한테 얼마 만큼 허용 
 
 
 constructor() public{
     owner = msg.sender;
 } 
 
 
 function changeOwner(address _addr) public{
     
     require(owner == msg.sender);
     owner = _addr;
 }
  /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
 function transfer(address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     
     balances[msg.sender] = balances[msg.sender] - _value;
     balances[_to] = balances[_to] + _value;
     emit Transfer(msg.sender, _to, _value);
     
     return true;
}

function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
}

 /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
 */
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);
     
     balances[_from] = balances[_from] - _value;
     balances[_to] = balances[_to] + _value;
     
     allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
     emit Transfer(_from, _to, _value);
    
    return true;
}  

/**
 * Set allowance for other address
 *
 * Allows `_spender` to spend no more than `_value` tokens on your behalf
 *
 * @param _spender The address authorized to spend
 * @param _value the max amount they can spend
 */
function approve(address _spender, uint256 _value) public returns (bool) {
     allowed[msg.sender][_spender] = _value; //내가(누가)  누가 한테얼마를 허용 
     emit Approval(msg.sender, _spender, _value);
     
     return true;
}

function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
}

 /**
* Set allowance for other address and notify
*
* Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
*
* @param _spender The address authorized to spend
* @param _value the max amount they can spend
* @param _extraData some extra information to send to the approved contract
*/
 
function approveAndCall(address _spender, uint256 _value, bytes _extraData)  public returns (bool success) {
    
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
}
 
   /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
 function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
  }
  
   /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
 function burnFrom(address _from, uint256 _value) public returns (bool success) {
      require(balances[_from] >= _value);                // Check if the targeted balance is enough
      require(_value <= allowed[_from][msg.sender]);    // Check allowance
      balances[_from] -= _value;                         // Subtract from the targeted balance
      allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
      totalSupply -= _value;                            // Update totalSupply
      emit Burn(_from, _value);
      return true;
 }
 
 function mint(address _to, uint256 _amount) public returns (bool) {
 
     require(msg.sender == owner);
     
     totalSupply = totalSupply + _amount;
     balances[_to] = balances[_to] + _amount;
     
     emit Mint(_to, _amount);
     emit Transfer(address(0), _to, _amount);
     
     return true;
 }
 
 function mintSub(address _to,uint256 _amount) public returns (bool){
     
     require(msg.sender == owner);
     require(balances[msg.sender] >= _amount && balances[msg.sender] != 0 );
     
     totalSupply = totalSupply - _amount;
     balances[_to] = balances[_to] - _amount;
     
     emit Mint(_to,_amount);
     emit Transfer(address(0), _to,_amount);
     
     return true;
     
 }
 
 function close() public {
     
     require(msg.sender == owner);
     selfdestruct(owner);
 }
 
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Mint(address indexed to, uint256 amount); 
 // This notifies clients about the amount burnt
 event Burn(address indexed from, uint256 value);
 
}