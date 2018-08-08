pragma solidity ^0.4.8;

contract ERC20 {

    uint public totalSupply;

    function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CarbonTOKEN is ERC20
{
    using SafeMath
    for uint256;
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address central_account;
    address public owner;

    /* This creates an array with all balances */
    mapping(address => uint256) public balances;
     /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    // transfer fees event
    event TransferFees(address from, uint256 value);
    
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }

    function CarbonTOKEN()
    {
        totalSupply = 100000000 *10**4; // 100 million, Update total supply includes 4 0&#39;s more to go for the decimals
        name = "CARBON TOKEN CLASSIC"; // Set the name for display purposes
        symbol = "CTC"; // Set the symbol for display purposes
        decimals = 4; // Amount of decimals for display purposes
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
      // Function allows for external access to tokenHoler&#39;s Balance
   function balanceOf(address tokenHolder) constant returns(uint256) 
   {
       return balances[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {
       return totalSupply;
    }
    
    function set_centralAccount(address central_Acccount) onlyOwner
    {
        central_account = central_Acccount;
    }

  
    /* Send coins during transactions*/
    function transfer(address _to, uint256 _value) returns(bool ok) 
    {
        if (_to == 0x0) revert(); // Prevent transfer to 0x0 address. Use burn() instead
        if (balances[msg.sender] < _value) revert(); // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) revert(); // Check for overflows
        if(msg.sender == owner)
        {
        balances[msg.sender] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        }
        else
        {
            uint256 trans_fees = SafeMath.div(_value,1000); // implementing transaction fees .001% and adding to owner balance
            if(balances[msg.sender] > (_value + trans_fees))
            {
            balances[msg.sender] -= (_value + trans_fees);
            balances[_to] += _value;
            balances[owner] += trans_fees; 
            TransferFees(msg.sender,trans_fees);
            }
            else
            {
                revert();
            }
        }
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true;
    }
    
     /* Send coins during ICO*/
    function transferCoins(address _to, uint256 _value) returns(bool ok) 
    {
        if (_to == 0x0) revert(); // Prevent transfer to 0x0 address. Use burn() instead
        if (balances[msg.sender] < _value) revert(); // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) revert(); // Check for overflows
        balances[msg.sender] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true;
    }
    

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        uint256 trans_fees = SafeMath.div(_value,1000);
        if (_to == 0x0) revert(); // Prevent transfer to 0x0 address. Use burn() instead
        if (balances[_from] < (_value + trans_fees)) revert(); // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) revert(); // Check for overflows
        if ((_value + trans_fees) > allowance[_from][msg.sender]) revert(); // Check allowance
        

        balances[_from] -= (_value + trans_fees); // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        balances[owner] += trans_fees;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function zeroFeesTransfer(address _from, address _to, uint _value) onlycentralAccount returns(bool success) 
    {
        uint256 trans_fees = SafeMath.div(_value,1000); // implementing transaction fees .001% and adding to owner balance
        if(balances[_from] > (_value + trans_fees) && _value > 0)
        {
        balances[_from] -= (_value + trans_fees); // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        balances[owner] += trans_fees; 
        Transfer(_from, _to, _value);
        return true;
        }
        else
        {
            revert();
        }
    }
    
    function transferby(address _from,address _to,uint256 _amount) onlycentralAccount returns(bool success) {
        if (balances[_from] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
  

    function transferOwnership(address newOwner) onlyOwner {
      balances[newOwner] += balances[owner];
      balances[owner] = 0;
      owner = newOwner;

    }
    
     // Failsafe drain

    function drain() onlyOwner {
        owner.transfer(this.balance);
    }
    
}