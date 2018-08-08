pragma solidity ^0.4.17;
contract tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData); }
contract JaxBox
  { 
     /* Variables  */
    string  public name;         // name  of contract
    string  public symbol;       // symbol of contract
    uint8   public decimals;     // how many decimals to keep , 18 is best 
    uint256 public totalSupply; // how many tokens to create
    uint256 public remaining;   // how many tokens has left
    uint256 public ethRate;     // current rate of ether
    address public owner;       // contract creator
    uint256 public amountCollected; // how much funds has been collected
    uint8   public icoStatus;
    uint8   public icoTokenPrice;
    address public benAddress;
    
     /* Array  */
    mapping (address => uint256) public balanceOf; // array of all balances
    mapping (address => uint256) public investors;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    /* Events  */
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex); // only for ico sales
    

     /* Initializes contract with initial supply tokens to the creator of the contract */
    function JaxBox() 
    {
      totalSupply = 10000000000000000000000000000; // as the decimals are 18 we add 18 zero after total supply, as all values are stored in wei
      owner =  msg.sender;                      // Set owner of contract
      balanceOf[owner] = totalSupply;           // Give the creator all initial tokens
      totalSupply = totalSupply;                // Update total supply
      name = "JaxBox";                     // Set the name for display purposes
      symbol = "JBC";                       // Set the symbol for display purposes
      decimals = 18;                            // Amount of decimals for display purposes
      remaining = totalSupply;
      ethRate = 300;
      icoStatus = 1;
      icoTokenPrice = 10; // values are in cents
      benAddress = 0x57D1aED65eE1921CC7D2F3702C8A28E5Dd317913;
    }

   modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function ()  payable// called when ether is send
    {
        if (remaining > 0 && icoStatus == 1 )
        {
            uint  finalTokens =  ((msg.value / 10 ** 16) * ((ethRate * 10 ** 2) / icoTokenPrice)) / 10 ** 2;
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    amountCollected = amountCollected + (msg.value / 10 ** 18);
                    _transfer(owner,msg.sender, finalTokens); 
                    TransferSell(owner, msg.sender, finalTokens,&#39;Online&#39;);
                }
            else
                {
                    throw;
                }
        }
        else
        {
            throw;
        }
    }    
    
    function sellOffline(address rec_address,uint256 token_amount) onlyOwner 
    {
        if (remaining > 0)
        {
            uint finalTokens =  (token_amount  * (10 ** 18)); //  we sell each token for $0.10 so multiply by 10
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    _transfer(owner,rec_address, finalTokens);    
                    TransferSell(owner, rec_address, finalTokens,&#39;Offline&#39;);
                }
            else
                {
                    throw;
                }
        }
        else
        {
            throw;
        }        
    }
    
    function getEthRate() onlyOwner constant returns  (uint) // Get current rate of ether 
    {
        return ethRate;
    }
    
    function setEthRate (uint newEthRate)   onlyOwner // Set ether price
    {
        ethRate = newEthRate;
    } 


    function getTokenPrice() onlyOwner constant returns  (uint8) // Get current token price
    {
        return icoTokenPrice;
    }
    
    function setTokenPrice (uint8 newTokenRate)   onlyOwner // Set one token price
    {
        icoTokenPrice = newTokenRate;
    }     
    
    

    
    function changeIcoStatus (uint8 statx)   onlyOwner // Change ICO Status
    {
        icoStatus = statx;
    } 
    
    
    function withdraw(uint amountWith) onlyOwner // withdraw partical amount
        {
            if(msg.sender == owner)
            {
                if(amountWith > 0)
                    {
                        amountWith = (amountWith * 10 ** 18); // as input accept parameter in weis
                        benAddress.send(amountWith);
                    }
            }
            else
            {
                throw;
            }
        }

    function withdraw_all() onlyOwner // call when ICO is done
        {
            if(msg.sender == owner)
            {
                benAddress.send(this.balance);
                //suicide(msg.sender);
            }
            else
            {
                throw;
            }
        }

    function mintToken(uint256 tokensToMint) onlyOwner 
        {
            var totalTokenToMint = tokensToMint * (10 ** 18);
            balanceOf[owner] += totalTokenToMint;
            totalSupply += totalTokenToMint;
            Transfer(0, owner, totalTokenToMint);
        }

    function freezeAccount(address target, bool freeze) onlyOwner 
        {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
            

    function getCollectedAmount() constant returns (uint256 balance) 
        {
            return amountCollected;
        }        

    function balanceOf(address _owner) constant returns (uint256 balance) 
        {
            return balanceOf[_owner];
        }

    function totalSupply() constant returns (uint256 tsupply) 
        {
            tsupply = totalSupply;
        }    


    function transferOwnership(address newOwner) onlyOwner 
        { 
            balanceOf[owner] = 0;                        
            balanceOf[newOwner] = remaining;               
            owner = newOwner; 
        }        

  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _value) internal 
      {
          require(!frozenAccount[_from]);                     // Prevent transfer from frozenfunds
          require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
          require (balanceOf[_from] > _value);                // Check if the sender has enough
          require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
          balanceOf[_from] -= _value;                         // Subtract from the sender
          balanceOf[_to] += _value;                            // Add the same to the recipient
          Transfer(_from, _to, _value);
      }


  function transfer(address _to, uint256 _value) 
      {
          _transfer(msg.sender, _to, _value);
      }

  /// @notice Send `_value` tokens to `_to` in behalf of `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value the amount to send
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) 
      {
          require (_value < allowance[_from][msg.sender]);     // Check allowance
          allowance[_from][msg.sender] -= _value;
          _transfer(_from, _to, _value);
          return true;
      }

  /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
  /// @param _spender The address authorized to spend
  /// @param _value the max amount they can spend
  function approve(address _spender, uint256 _value) returns (bool success) 
      {
          allowance[msg.sender][_spender] = _value;
          return true;
      }

  /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
  /// @param _spender The address authorized to spend
  /// @param _value the max amount they can spend
  /// @param _extraData some extra information to send to the approved contract
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success)
      {
          tokenRecipient spender = tokenRecipient(_spender);
          if (approve(_spender, _value)) {
              spender.receiveApproval(msg.sender, _value, this, _extraData);
              return true;
          }
      }        

  /// @notice Remove `_value` tokens from the system irreversibly
  /// @param _value the amount of money to burn
  function burn(uint256 _value) returns (bool success) 
      {
          require (balanceOf[msg.sender] > _value);            // Check if the sender has enough
          balanceOf[msg.sender] -= _value;                      // Subtract from the sender
          totalSupply -= _value;                                // Updates totalSupply
          Burn(msg.sender, _value);
          return true;
      }

  function burnFrom(address _from, uint256 _value) returns (bool success) 
      {
          require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
          require(_value <= allowance[_from][msg.sender]);    // Check allowance
          balanceOf[_from] -= _value;                         // Subtract from the targeted balance
          allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
          totalSupply -= _value;                              // Update totalSupply
          Burn(_from, _value);
          return true;
      }
} // end of contract