pragma solidity ^0.4.24;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}



/**
*This is the basic wrapped Ether contract. 
*All money deposited is transformed into ERC20 tokens at the rate of 1 wei = 1 token
*/
contract Wrapped_Ether {

    using SafeMath for uint256;

    /*Variables*/

    //ERC20 fields
    string public name = "Wrapped Ether";
    uint public total_supply;
    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint)) internal allowed;

    /*Events*/
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event StateChanged(bool _success, string _message);

    /*Functions*/
    /**
    *@dev This function creates tokens equal in value to the amount sent to the contract
    */
    function createToken() public payable {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        total_supply = total_supply.add(msg.value);
    }

    /**
    *@dev This function &#39;unwraps&#39; an _amount of Ether in the sender&#39;s balance by transferring 
    *Ether to them
    *@param _value The amount of the token to unwrap
    */
    function withdraw(uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        total_supply = total_supply.sub(_value);
        msg.sender.transfer(_value);
    }

    /**
    *@param _owner is the owner address used to look up the balance
    *@return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public constant returns (uint bal) { 
        return balances[_owner]; 
    }

    /**
    *@dev Allows for a transfer of tokens to _to
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = balances[msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev Allows an address with sufficient spending allowance to send tokens on the behalf of _from
    *@param _from The address to send tokens from
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[_from] = balances[_from] - _amount;
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev This function approves a _spender an _amount of tokens to use
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@param _owner address
    *@param _spender address
    *@return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    *@dev Getter for the total_supply of wrapped ether
    *@return total supply
    */
    function totalSupply() public constant returns (uint) {
       return total_supply;
    }
}