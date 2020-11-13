/**
 *Submitted for verification at Etherscan.io on 2020-09-23
 * Initial Seed fund contract 
 * Fractionalization of "22hrs" convenience store chain and tokenizing it
 * https://22hrs.com, An initiative to bring the real-world assets into blockchain
*/
pragma solidity ^0.5.7;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
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
    uint256 c = a / b;
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

contract HRSToken{
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    uint256 internal _totalburnt;
    uint256 mintLimit;
    uint256 burnLimit;
    address public owner;
    address public newOwner;
    address central_account;
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address=>uint256) internal blocklist;
    bool stopped=false;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    
    
    constructor () public {
        _name = '22hrs';
        _symbol = '22hrs';
        _decimals = 18;
        _totalSupply = 0;
        _totalburnt = 0;
        mintLimit = 1000000;
        burnLimit = 1000000;
        
        owner = msg.sender;
  }
  
  
   modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

   function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
   }
   
   function isBlockList(address _ads) public view returns (bool){
       if(blocklist[_ads]>0)
        return true;
       else
        return false;
   }
   
   function mintStatus()public view returns (bool status){
       return !stopped;
   }
   
   function set_centralAccount(address central_Acccount) external onlyOwner
    {
        require(blocklist[central_Acccount]==0);
        central_account = central_Acccount;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     
  function approve(address _spender, uint256 _value) public returns (bool) {
     require(blocklist[_spender]==0 && blocklist[msg.sender]==0);
     require( _spender != address(0));
     
     allowed[msg.sender][_spender] = _value;
     emit Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public view returns (uint256) {
      require( _owner != address(0) && _spender !=address(0));
     return allowed[_owner][_spender];
   }

   function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
     require(blocklist[_spender]==0 && blocklist[msg.sender]==0);
     allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
     emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
     require(blocklist[_spender]==0 && blocklist[msg.sender]==0);
     uint oldValue = allowed[msg.sender][_spender];
     if (_subtractedValue > oldValue) {
       allowed[msg.sender][_spender] = 0;
     } else {
       allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
    }
     emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }
   
   // Transfer the balance from the owner's account to another account
   
    function transfer(address _to, uint256 _value) public returns(bool){
        
        require( balances[msg.sender]>= _value && _value > 0 );
        require(blocklist[_to]==0 && blocklist[msg.sender]==0);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender] , _value);
        balances[_to] = SafeMath.add(balances[_to] , _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /** Send _value amount of tokens from address _from to address _to
      * 
      * The transferFrom method is used for a withdraw workflow, allowing contracts to send
      * 
      * tokens on your behalf, for example, to "deposit" to a contract address and/or to charge
      * 
      * fees in sub-currencies; the command should fail unless the _from account has
      * 
      * deliberately authorized the sender of the message via some mechanism; we propose
      * 
      * these standardized APIs for approval:
      */
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(blocklist[_to]==0 && blocklist[msg.sender]==0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_value > 0 );

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
   }
   
   function transferby(address _from,address _to,uint256 _amount) external onlycentralAccount returns(bool success) {
        require( _to != address(0)); 
        require(blocklist[_from]==0 && blocklist[_to]==0);
        require (balances[_from] >= _amount && _amount > 0);
        
        balances[_from] = SafeMath.sub( balances[_from] , _amount);
        balances[_to] = SafeMath.add(balances[_to] , _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    /** @notice  Mint the specified value from the given address.
      *
      * @dev  ads balance is added by the value they mentioned.
      *
      * @param  value  The amount to mint.
      *
      * @param  ads     address of the user
      * 
      * @return  success true if the mint succeeded.
      */
   
   function mint(uint value , address ads) external onlycentralAccount returns (bool){
       
       require(!stopped);
       require(ads!=address(0) && value > 0 && value <= mintLimit);
       require(blocklist[ads]==0);
       
       _totalSupply = SafeMath.add(_totalSupply, value);
      balances[ads] = SafeMath.add(balances[ads], value);
      emit Transfer(address(0), ads, value);
      return true;
       
   }
   
   
   
    function batchMint(address[] calldata _tos, uint256[] calldata  _values) external onlycentralAccount returns (bool success) {
        require(_tos.length == _values.length);
        require(!stopped);

        uint256 totalTransfers = _tos.length;

        for (uint256 i = 0; i < totalTransfers; i++) {
           address to = _tos[i];
           uint256 value = _values[i];
           require(to!=address(0) && value > 0 && value <= mintLimit);
           require(blocklist[to]==0);

           _totalSupply = SafeMath.add(_totalSupply, value);
           balances[to] = SafeMath.add(balances[to], value);
           emit Transfer(address(0), to, value);
        }


        return true;
    }
   
   /** @notice  Burns the specified value from the given address.
      *
      * @dev  ads balance is subtracted by the value they mentioned.
      *
      * @param  value  The amount to burn.
      *
      * @param  ads     address of the user
      * 
      * @return  success true if the burn succeeded.
      */
   
   function burn(uint value ,  address ads) external onlycentralAccount returns (bool){
        
        require(ads!=address(0) && value > 0 && !stopped);
        require(blocklist[ads]==0);
        require(balances[ads]>=value && value <= burnLimit);
        
        balances[ads] = SafeMath.sub(balances[ads], value);
        _totalSupply = SafeMath.sub(_totalSupply, value);
        _totalburnt = SafeMath.add(_totalburnt,value);
        emit Transfer(ads, address(0), value);
        return true;
   }
   
    function increaseSupply(uint value, address to) external onlyOwner returns (bool) {
      
      require(to!= address(0) && value > 0);
      _totalSupply = SafeMath.add(_totalSupply, value);
      balances[to] = SafeMath.add(balances[to], value);
      emit Transfer(address(0), to, value);
      return true;
}



    function decreaseSupply(uint value, address from) external onlyOwner returns (bool) {
        
        require(from!=address(0) && value > 0);
        require(balances[from]>=value);
        balances[from] = SafeMath.sub(balances[from], value);
        _totalSupply = SafeMath.sub(_totalSupply, value);  
        _totalburnt = SafeMath.add(_totalburnt,value);
        emit Transfer(from, address(0), value);
        return true;
}

     // called by the owner, pause Mint & Burn
    function PauseMint() external onlyOwner{
        stopped = true;
       }
    
    // called by the owner, resume Mint & Burn
    function ResumeMint() external onlyOwner{
        stopped = false;
      }
    
    // called by the owner, set Mint Limit for the Central Account
    function SetMintLimit(uint256 _limit) external onlyOwner{
        mintLimit = _limit;
    }
    
    function getMintLimit() public view returns(uint256){
        return mintLimit;
    }
    
    // called by the owner, set Burn Limit for the Central Account
    function SetBurnLimit(uint256 _limit) external onlyOwner{
        burnLimit = _limit;
    }
    
    function getBurnLimit()public view returns(uint256){
        return burnLimit;
    }
      
     
    // called by the owner, to add particular address to the blocklist
    function addBlockLIst(address ads) external onlyOwner{
         require(ads != owner);
         blocklist[ads] = 1;
     }
     
    // called by the owner, to remove particular address from the blocklist
    function removeBlockList(address ads) external onlyOwner{
         blocklist[ads] = 0;
     }
     
     
      /** @notice This function transfers the balances of all the given addresses 
       
      * to the given destination.
      *
      * @dev The central account is the only authorized caller of
      * this function. This function accepts an array of addresses to have their
      * balances transferred for gas efficiency purposes.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _froms  The addresses to have their balances swept.
      * @param  _to  The destination address of all these transfers.
      */
     
      function sweep(address[] calldata _froms, address _to) external  onlycentralAccount returns(bool) {
        require(_to != address(0));
        uint256 lenFroms = _froms.length;
        uint256 sweptBalance = 0;

        for (uint256 i=0; i<lenFroms; ++i) {
            address from = _froms[i];

                uint256 fromBalance = balances[from];

                if (fromBalance > 0) {
                    sweptBalance += fromBalance;

                    balances[from] = 0;

                     emit Transfer(from, _to, fromBalance);
                }
        }

        if (sweptBalance > 0) {
            balances[_to] = SafeMath.add(balances[_to],sweptBalance);
            return true;
        }
    }
      
      
       /** @notice  A function for a sender to issue multiple transfers to multiple
      * different addresses at once. This function is implemented for gas
      * considerations when someone wishes to transfer, as one transaction is
      * cheaper than issuing several distinct individual `transfer` transactions.
      *
      * @dev  By specifying a set of destination addresses and values, the
      * sender can issue one transaction to transfer multiple amounts to
      * distinct addresses, rather than issuing each as a separate
      * transaction. The `_tos` and `_values` arrays must be equal length, and
      * an index in one array corresponds to the same index in the other array
      * (e.g. `_tos[0]` will receive `_values[0]`, `_tos[1]` will receive
      * `_values[1]`, and so on.)
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _tos  The destination addresses to receive the transfers.
      * @param  _values  The values for each destination address.
      * @return  success  If transfers succeeded.
      */
      
     function batchTransfer(address[] memory _tos, uint256[] memory  _values) public returns (bool success) {
        require(_tos.length == _values.length);

        uint256 totalTransfers = _tos.length;
        uint256 senderBalance = balances[msg.sender];

        for (uint256 i = 0; i < totalTransfers; i++) {
          address to = _tos[i];
          require(to != address(0));
          uint256 amount = _values[i];
          require(senderBalance >= amount);

          if (msg.sender != to) {
            senderBalance -= amount;
            SafeMath.add(balances[to], amount);
          }
          emit Transfer(msg.sender, to, amount);
        }

        balances[msg.sender] = senderBalance;

        return true;
    }

    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(blocklist[_newOwner]==0);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner && blocklist[msg.sender]==0);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
   function () external payable {
        revert();
    } 
}