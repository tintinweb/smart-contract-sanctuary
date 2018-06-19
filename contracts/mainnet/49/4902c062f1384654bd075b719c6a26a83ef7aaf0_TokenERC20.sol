pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     address public owner; // current owner of the contract
     uint256 public feesA = 1; 
     uint256 public feesB = 1; 
     uint256 public feesC = 1; 
     uint256 public feesD = 1; 
     address public addressA = 0xC61994B01607Ed7351e1D4FEE93fb0e661ceE39c;
     address public addressB = 0x821D44F1d04936e8b95D2FFAE91DFDD6E6EA39F9;
     address public addressC = 0xf193c2EC62466fd338710afab04574E7Eeb6C0e2;
     address public addressD = 0x3105889390F894F8ee1d3f8f75E2c4dde57735bA;
     
function founder() private {  // contract&#39;s constructor function
        owner = msg.sender;
        }
function change_owner (address newOwner) public{
        require(owner == msg.sender);
        owner = newOwner;
        emit Changeownerlog(newOwner);
    }
    
function setfees (uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4) public {
      require(owner == msg.sender);
      if (_value1>0 && _value2>0 && _value3>0 &&_value4>0){
      feesA = _value1;
      feesB = _value2;
      feesC = _value3;
      feesD = _value4;
      emit Setfeeslog(_value1,_value2,_value3,_value4);
      }else {
          
      }
}
    
function setaddress (address _address1, address _address2, address _address3, address _address4) public {
   require(owner == msg.sender);
   addressA = _address1;
   addressB = _address2;
   addressC = _address3;
   addressD = _address4;
   emit Setfeeaddrlog(_address1,_address2,_address3,_address4);
   }

    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Fee1(address indexed from, address indexed to, uint256 value);
    event Fee2(address indexed from, address indexed to, uint256 value);
    event Fee3(address indexed from, address indexed to, uint256 value);
    event Fee4(address indexed from, address indexed to, uint256 value);
    // Reissue
    event Reissuelog(uint256 value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value); 
    //setfees
    event Setfeeslog(uint256 fee1,uint256 fee2,uint256 fee3,uint256 fee4);
    //setfeeaddress
    event Setfeeaddrlog(address,address,address,address);
    //changeowner
    event Changeownerlog(address);
        
     /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;                                 // Set contract owner
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
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
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
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
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public {
        uint256 fees1 = (feesA *_value)/10000;
        uint256 fees2 = (feesB *_value)/10000;
        uint256 fees3 = (feesC *_value)/10000;
        uint256 fees4 = (feesD *_value)/10000;
        _value -= (fees1+fees2+fees3+fees4);
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        _transfer(msg.sender, addressA, fees1);
        emit Fee1(msg.sender, addressA, fees1);
        _transfer(msg.sender, addressB, fees2);
        emit Fee2(msg.sender, addressB, fees2);
        _transfer(msg.sender, addressC, fees3);
        emit Fee3(msg.sender, addressC, fees3);
        _transfer(msg.sender, addressD, fees4);
        emit Fee4(msg.sender, addressD, fees4);
        }
            

    function Reissue(uint256 _value) public  {
        require(owner == msg.sender);
        balanceOf[msg.sender] += _value;            // Add to the sender
        totalSupply += _value;                      // Updates totalSupply
        emit Reissuelog(_value);
    }
    
}