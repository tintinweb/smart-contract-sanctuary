pragma solidity ^0.4.16;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;
   
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public 
        returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
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
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
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


        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);


        emit Transfer(_from, _to, _value);
    } 
}

contract WEKUToken is Owned, TokenERC20 {
    
    string public constant TOKEN_SYMBOL  = "WEKU"; 
    string public constant TOKEN_NAME    = "WEKU Token";  
    uint public constant INITIAL_SUPPLLY = 4 * 10 ** 8; 

    uint256 deployedTime;   // the time this constract is deployed.
    address team;           // team account
    uint256 teamTotal;      // total amount of token assigned to team.    
    uint256 teamWithdrawed; // total withdrawed of team account

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function WEKUToken(
        address _team
    ) TokenERC20(INITIAL_SUPPLLY, TOKEN_NAME, TOKEN_SYMBOL) public {
        deployedTime = now;
        team = _team; 
        teamTotal = (INITIAL_SUPPLLY * 10 ** 18) / 5; 
        // assign 20% to team team once and only once.         
        _transfer(owner, team, teamTotal);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);

        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);
    }

    /// @notice batch assign tokens to users registered in airdrops
    /// @param earlyBirds address[] format in wallet: ["address1", "address2", ...]
    /// @param amount without decimal amount: 10**18
    function assignToEarlyBirds(address[] earlyBirds, uint256 amount) onlyOwner public {
        require(amount > 0);

        for (uint i = 0; i < earlyBirds.length; i++)
            _transfer(msg.sender, earlyBirds[i], amount * 10 ** 18);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal { 
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen

        // make sure founders can only withdraw 25% each year after first year    
        if(_from == team){
            bool flag = _limitTeamWithdraw(_value, teamTotal, teamWithdrawed, deployedTime, now);
            if(!flag)
                revert();
        }          
             
        balanceOf[_from] = balanceOf[_from].sub(_value);                  // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                      // Add the same to the recipient

        if(_from == team) teamWithdrawed = teamWithdrawed.add(_value);    // record how many team withdrawed

        emit Transfer(_from, _to, _value);
    }

    // setperate this function is for unit testing.
    // limited withdraw: 
    // after deployed:  40%
    // after one year:  30% 
    // after two years: 30%
    function _limitTeamWithdraw(uint _amount, uint _teamTotal, uint _teamWithrawed, uint _deployedTime, uint _currentTime) internal pure returns(bool){
        
        bool flag  = true;

        uint _tenPercent = _teamTotal / 10;    
        if(_currentTime <= _deployedTime + 1 days && _amount + _teamWithrawed >= _tenPercent * 4) 
            flag = false;
        else if(_currentTime <= _deployedTime + 365 days && _amount + _teamWithrawed >= _tenPercent * 7) 
            flag = false; 

        return flag;

    }
}