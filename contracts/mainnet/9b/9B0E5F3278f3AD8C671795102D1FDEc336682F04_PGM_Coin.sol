pragma solidity ^0.4.19;
contract tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData) public; }
contract PGM_Coin
  { 
     /* Variables  */
    string  public name;                                                        // name  of contract
    string  public symbol;                                                      // symbol of contract
    uint8   public decimals;                                                    // how many decimals to keep , 18 is best 
    uint256 public totalSupply;                                                 // how many tokens to create
    uint256 public remaining;                                                   // how many tokens has left
    uint    public ethRate;                                                     // current rate of ether
    address public owner;                                                       // contract creator
    uint256 public amountCollected;                                             // how much funds has been collected
    uint    public icoStatus;                                                   // allow / disallow online purchase
    uint    public icoTokenPrice;                                               // token price, start with 10 cents
    address public benAddress;                                                  // funds withdraw address
    address public bkaddress;                                                   
    uint    public allowTransferToken;                                          // allow / disallow token transfer for members
    
     /* Array  */
    mapping (address => uint256) public balanceOf;                              // array of all balances
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    /* Events  */
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex); // only for ico sales
    

     /* Initializes contract with initial supply tokens to the creator of the contract */
    function PGM_Coin() public
    {
      totalSupply = 1000000000000000000000000000;                                 // as the decimals are 18, we add 18 zero after total supply, as all values are stored in wei
      owner =  msg.sender;                                                      // Set owner of contract
      balanceOf[owner] = totalSupply;                                           // Give the creator all initial tokens
       name = "PGM Coin";                                                     // Set the name for display purposes
      symbol = "PGM";                                                          // Set the symbol for display purposes
      decimals = 18;                                                            // Amount of decimals for display purposes
      remaining = totalSupply;                                                  // How many tokens are left
      ethRate = 1100;                                                            // default token price
      icoStatus = 1;                                                            // default ico status
      icoTokenPrice = 50;                                                       // values are in cents
      benAddress = 0x4532828EC057e6cFa04a42b153d74B345084C4C2;                  // funds withdraw address
      bkaddress  = 0x1D38b496176bDaB78D430cebf25B2Fe413d3BF84;                   
      allowTransferToken = 0;                                                   // default set to disable, it will be enable after ICO is over
    }

   modifier onlyOwner()
    {
        require((msg.sender == owner) || (msg.sender ==  bkaddress));
        _;
    }


    function () public payable                                                  // called when ether is send to contract
    {
    }    
    
    function sellOffline(address rec_address,uint256 token_amount) public onlyOwner 
    {
        if (remaining > 0)
        {
            uint finalTokens =  (token_amount  * (10 ** 18));              
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    _transfer(owner,rec_address, finalTokens);    
                    TransferSell(owner, rec_address, finalTokens,&#39;Offline&#39;);
                }
            else
                {
                    revert();
                }
        }
        else
        {
            revert();
        }        
    }
    
    function getEthRate() onlyOwner public constant returns  (uint)            // Get current rate of ether 
    {
        return ethRate;
    }

    
    function getConBal() onlyOwner public constant returns  (uint)            // Get  Balance 
    {
        return this.balance;
    }    
    
    function setEthRate (uint newEthRate) public  onlyOwner                    // Set ether price
    {
        ethRate = newEthRate;
    } 


    function getTokenPrice() onlyOwner public constant returns  (uint)         // Get current token price
    {
        return icoTokenPrice;
    }
    
    function setTokenPrice (uint newTokenRate) public  onlyOwner               // Set one token price
    {
        icoTokenPrice = newTokenRate;
    }     
    
    
    function setTransferStatus (uint status) public  onlyOwner                 // Set transfer status
    {
        allowTransferToken = status;
    }   
    
    function changeIcoStatus (uint8 statx)  public onlyOwner                   // Change ICO Status
    {
        icoStatus = statx;
    } 
    

    function withdraw(uint amountWith) public onlyOwner                        // withdraw partical amount
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress))
            {
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }

    function withdraw_all() public onlyOwner                                   // call to withdraw all available balance
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress) )
            {
                var amountWith = this.balance - 10000000000000000;
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }

    function mintToken(uint256 tokensToMint) public onlyOwner 
        {
            if(tokensToMint > 0)
            {
                var totalTokenToMint = tokensToMint * (10 ** 18);
                balanceOf[owner] += totalTokenToMint;
                totalSupply += totalTokenToMint;
                Transfer(0, owner, totalTokenToMint);
            }
        }
		

	 /* Admin Trasfer  */
	 function adm_trasfer(address _from,address _to, uint256 _value)  public onlyOwner
		  {
			  _transfer(_from, _to, _value);
		  }
		

    function freezeAccount(address target, bool freeze) public onlyOwner 
        {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
            

    function getCollectedAmount() onlyOwner public constant returns (uint256 balance) 
        {
            return amountCollected;
        }        

    function balanceOf(address _owner) public constant returns (uint256 balance) 
        {
            return balanceOf[_owner];
        }

    function totalSupply() private constant returns (uint256 tsupply) 
        {
            tsupply = totalSupply;
        }    


    function transferOwnership(address newOwner) public onlyOwner 
        { 
            balanceOf[owner] = 0;                        
            balanceOf[newOwner] = remaining;               
            owner = newOwner; 
        }        

  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _value) internal 
      {
          if(allowTransferToken == 1 || _from == owner )
          {
              require(!frozenAccount[_from]);                                   // Prevent transfer from frozenfunds
              require (_to != 0x0);                                             // Prevent transfer to 0x0 address. Use burn() instead
              require (balanceOf[_from] > _value);                              // Check if the sender has enough
              require (balanceOf[_to] + _value > balanceOf[_to]);               // Check for overflows
              balanceOf[_from] -= _value;                                       // Subtract from the sender
              balanceOf[_to] += _value;                                         // Add to the recipient
              Transfer(_from, _to, _value);                                     // raise event
          }
          else
          {
               revert();
          }
      }

  function transfer(address _to, uint256 _value)  public
      {
          _transfer(msg.sender, _to, _value);
      }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
      {
          require (_value < allowance[_from][msg.sender]);                      // Check allowance
          allowance[_from][msg.sender] -= _value;
          _transfer(_from, _to, _value);
          return true;
      }

  function approve(address _spender, uint256 _value) public returns (bool success) 
      {
          allowance[msg.sender][_spender] = _value;
          return true;
      }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
      {
          tokenRecipient spender = tokenRecipient(_spender);
          if (approve(_spender, _value)) {
              spender.receiveApproval(msg.sender, _value, this, _extraData);
              return true;
          }
      }        

  function burn(uint256 _value) public returns (bool success) 
      {
          require (balanceOf[msg.sender] > _value);                             // Check if the sender has enough
          balanceOf[msg.sender] -= _value;                                      // Subtract from the sender
          totalSupply -= _value;                                                // Updates totalSupply
          Burn(msg.sender, _value);
          return true;
      }

  function burnFrom(address _from, uint256 _value) public returns (bool success) 
      {
          require(balanceOf[_from] >= _value);                                  // Check if the targeted balance is enough
          require(_value <= allowance[_from][msg.sender]);                      // Check allowance
          balanceOf[_from] -= _value;                                           // Subtract from the targeted balance
          allowance[_from][msg.sender] -= _value;                               // Subtract from the sender&#39;s allowance
          totalSupply -= _value;                                                // Update totalSupply
          Burn(_from, _value);
          return true;
      }
} // end of contract