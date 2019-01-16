pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    constructor() public {
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


contract DBTBase {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 12;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event Approved(address indexed from,address spender, uint256 value);
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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
        emit Approved(msg.sender,_spender,_value);
        return true;
    }


    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
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
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract DBToken is owned, DBTBase {

    /* Lock allcoins */
    mapping (address => bool) public frozenAccount;
    /* Lock specified number of coins */
    mapping (address => uint256) public balancefrozen;
    /*Lock acccout with time and value */
    mapping (address => uint256[][]) public frozeTimeValue;
    /* Locked total with time and value*/
    mapping (address => uint256) public balancefrozenTime;


    bool public isPausedTransfer = false;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    event FronzeValue(address target,uint256 value);

    event FronzeTimeValue(address target,uint256 value);

    event PauseChanged(bool ispause);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) DBTBase(initialSupply, tokenName, tokenSymbol) public {
        
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!isPausedTransfer);
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from]>=_value);
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        //Check FronzenValue
        require(balanceOf[_from].sub(_value)>=balancefrozen[_from]);

        require(accountNoneFrozenAvailable(_from) >=_value);

        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    function pauseTransfer(bool ispause) onlyOwner public {
        isPausedTransfer = ispause;
        emit PauseChanged(ispause);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        uint256 newmint=mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[target] = balanceOf[target].add(newmint);
        totalSupply = totalSupply.add(newmint);
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
    
    function freezeAccountTimeAndValue(address target, uint256[] times, uint256[] values) onlyOwner public {
        require(times.length >=1 );
        require(times.length == values.length);
        require(times.length<=10);
        uint256[2][] memory timevalue=new uint256[2][](10);
        uint256 lockedtotal=0;
        for(uint i=0;i<times.length;i++)
        {
            uint256 value=values[i].mul(10 ** uint256(decimals));
            timevalue[i]=[times[i],value];
            lockedtotal=lockedtotal.add(value);
        }
        frozeTimeValue[target] = timevalue;
        balancefrozenTime[target]=lockedtotal;
        emit FronzeTimeValue(target,lockedtotal);
    }

    function unfreezeAccountTimeAndValue(address target) onlyOwner public {

        uint256[][] memory lockedTimeAndValue=frozeTimeValue[target];
        
        if(lockedTimeAndValue.length>0)
        {
           delete frozeTimeValue[target];
        }
        balancefrozenTime[target]=0;
    }

    function freezeByValue(address target,uint256 value) public onlyOwner {
       balancefrozen[target]=value.mul(10 ** uint256(decimals));
       emit FronzeValue(target,value);
    }

    function increaseFreezeValue(address target,uint256 value)  onlyOwner public {
       balancefrozen[target]= balancefrozen[target].add(value.mul(10 ** uint256(decimals)));
       emit FronzeValue(target,value);
    }

    function decreaseFreezeValue(address target,uint256 value) onlyOwner public {
            uint oldValue = balancefrozen[target];
            uint newvalue=value.mul(10 ** uint256(decimals));
            if (newvalue >= oldValue) {
                balancefrozen[target] = 0;
            } else {
                balancefrozen[target] = oldValue.sub(newvalue);
            }
            
        emit FronzeValue(target,value);      
    }

     function accountNoneFrozenAvailable(address target) public returns (uint256)  {
        
        uint256[][] memory lockedTimeAndValue=frozeTimeValue[target];

        uint256 avail=0;
       
        if(lockedTimeAndValue.length>0)
        {
           uint256 unlockedTotal=0;
           uint256 now1 = block.timestamp;
           uint256 lockedTotal=0;           
           for(uint i=0;i<lockedTimeAndValue.length;i++)
           {
               
               uint256 unlockTime = lockedTimeAndValue[i][0];
               uint256 unlockvalue=lockedTimeAndValue[i][1];
               
               if(now1>=unlockTime && unlockvalue>0)
               {
                  unlockedTotal=unlockedTotal.add(unlockvalue);
               }
               if(unlockvalue>0)
               {
                   lockedTotal=lockedTotal.add(unlockvalue);
               }
           }
           //checkunlockvalue

           if(lockedTotal > unlockedTotal)
           {
               balancefrozenTime[target]=lockedTotal.sub(unlockedTotal);
           }
           else 
           {
               balancefrozenTime[target]=0;
           }
           
           if(balancefrozenTime[target]==0)
           {
              delete frozeTimeValue[target];
           }
           if(balanceOf[target]>balancefrozenTime[target])
           {
               avail=balanceOf[target].sub(balancefrozenTime[target]);
           }
           else
           {
               avail=0;
           }
           
        }
        else
        {
            avail=balanceOf[target];
        }

        return avail ;
    }


}