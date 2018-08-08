pragma solidity ^0.4.11;

contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() {
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract safeMath {
    function add(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c >= a || c >= b);
        return c;
    }
    
    function sub(uint a, uint b) returns (uint) {
        assert( b <= a);
        return a - b;
    }
}

contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
} 

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MCTContractToken is ERC20Token, Owned{

    /* Public variables of the token */
    string  public standard = "Mammoth Casino Contract Token";
    string  public name = "Mammoth Casino Token";
    string  public symbol = "MCT";
    uint8   public decimals = 0;
    address public icoContractAddress;
    uint256 public tokenFrozenUntilTime;
    uint256 public blackListFreezeTime;
    struct frozen {
        bool accountFreeze;
        uint256 freezeUntilTime;
    }
    
    /* Variables of the token */
    uint256 public totalSupply;
    uint256 public totalRemainSupply;
    uint256 public foundingTeamSupply;
    uint256 public gameDeveloperSupply;
    uint256 public communitySupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => frozen) blackListFreezeTokenAccounts;
    /* Events */
    event mintToken(address indexed _to, uint256 _value);
    event burnToken(address indexed _from, uint256 _value);
    event frozenToken(uint256 _frozenUntilBlock, string _reason);
    
    /* Initializes contract and  sets restricted addresses */
    function MCTContractToken(uint256 _totalSupply, address _icoAddress) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        totalRemainSupply = totalSupply;
        foundingTeamSupply = totalSupply * 2 / 10;
        gameDeveloperSupply = totalSupply * 1 / 10;
        communitySupply = totalSupply * 1 / 10;
        icoContractAddress = _icoAddress;
        blackListFreezeTime = 12 hours;
    }

    /* Returns total supply of issued tokens */
    function mctTotalSupply() returns (uint256) {   
        return totalSupply - totalRemainSupply;
    }

    /* Returns balance of address */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) returns (bool success) {
        require (now > tokenFrozenUntilTime);    // Throw if token is frozen
        require (now > blackListFreezeTokenAccounts[msg.sender].freezeUntilTime);             // Throw if recipient is frozen address
        require (now > blackListFreezeTokenAccounts[_to].freezeUntilTime);                    // Throw if recipient is frozen address
        require (balances[msg.sender] > _value);           // Throw if sender has insufficient balance
        require (balances[_to] + _value > balances[_to]);  // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers blaance 
        Transfer(msg.sender, _to, _value);                  // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) returns (bool success) {
        require (now > tokenFrozenUntilTime);               // Throw if token is frozen        
        allowances[msg.sender][_spender] = _value;          // Set allowance         
        Approval(msg.sender, _spender, _value);             // Raise Approval event         
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */ 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {            
        tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract         
        approve(_spender, _value);                                      // Set approval to contract for _value         
        spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract         
        return true;     
    }     

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {      
        require (now > tokenFrozenUntilTime);    // Throw if token is frozen
        require (now > blackListFreezeTokenAccounts[_to].freezeUntilTime);                    // Throw if recipient is restricted address  
        require (balances[_from] > _value);                // Throw if sender does not have enough balance     
        require (balances[_to] + _value > balances[_to]);  // Throw if overflow detected    
        require (_value > allowances[_from][msg.sender]);  // Throw if you do not have allowance       
        balances[_from] -= _value;                          // Deduct senders balance    
        balances[_to] += _value;                            // Add recipient blaance         
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address         
        Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;     
    }         

    /* Get the amount of allowed tokens to spend */     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {         
        return allowances[_owner][_spender];
    }         

    /* Issue new tokens */     
    function mintTokens(address _to, uint256 _amount) {         
        require (msg.sender == icoContractAddress);             // Only ICO address can mint tokens        
        require (now > blackListFreezeTokenAccounts[_to].freezeUntilTime);                        // Throw if user wants to send to restricted address       
        require (balances[_to] + _amount > balances[_to]);      // Check for overflows
        require (totalRemainSupply > _amount);
        totalRemainSupply -= _amount;                           // Update total supply
        balances[_to] += _amount;                               // Set minted coins to target
        mintToken(_to, _amount);                                // Create Mint event       
        Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
    }     
  
    /* Destroy tokens from owners account */
    function burnTokens(address _addr, uint256 _amount) onlyOwner {
        require (balances[msg.sender] < _amount);               // Throw if you do not have enough balance
        totalRemainSupply += _amount;                           // Deduct totalSupply
        balances[_addr] -= _amount;                             // Destroy coins on senders wallet
        burnToken(_addr, _amount);                              // Raise Burn event
        Transfer(_addr, 0x0, _amount);                          // Raise transfer to 0x0
    }
    
    /* Destroy tokens if MCT not sold out */
    function burnLeftTokens() onlyOwner {
        require (totalRemainSupply > 0);
        totalRemainSupply = 0;
    }
    
    /* Stops all token transfers in case of emergency */
    function freezeTransfersUntil(uint256 _frozenUntilTime, string _freezeReason) onlyOwner {      
        tokenFrozenUntilTime = _frozenUntilTime;
        frozenToken(_frozenUntilTime, _freezeReason);
    }
    
    /*Freeze player accounts for "blackListFreezeTime" */
    function freezeAccounts(address _freezeAddress, bool _freeze) onlyOwner {
        blackListFreezeTokenAccounts[_freezeAddress].accountFreeze = _freeze;
        blackListFreezeTokenAccounts[_freezeAddress].freezeUntilTime = now + blackListFreezeTime;
    }
    
    /*mint ICO Left Token*/
    function mintUnICOLeftToken(address _foundingTeamAddr, address _gameDeveloperAddr, address _communityAddr) onlyOwner {
        balances[_foundingTeamAddr] += foundingTeamSupply;           // Give balance to _foundingTeamAddr;
        balances[_gameDeveloperAddr] += gameDeveloperSupply;         // Give balance to _gameDeveloperAddr;
        balances[_communityAddr] += communitySupply;                 // Give balance to _communityAddr;
        totalRemainSupply -= (foundingTeamSupply + gameDeveloperSupply + communitySupply);
        mintToken(_foundingTeamAddr, foundingTeamSupply);            // Create Mint event       
        mintToken(_gameDeveloperAddr, gameDeveloperSupply);          // Create Mint event 
        mintToken(_communityAddr, communitySupply);                  // Create Mint event 
    }
    
}

contract MCTContract {
  function mintTokens(address _to, uint256 _amount);
}

contract MCTCrowdsale is Owned, safeMath {
    uint256 public tokenSupportLimit = 30000 ether;              
    uint256 public tokenSupportSoftLimit = 20000 ether;          
    uint256 constant etherChange = 10**18;                       
    uint256 public crowdsaleTokenSupply;                         
    uint256 public crowdsaleTokenMint;                                      
    uint256 public crowdsaleStartDate;
    uint256 public crowdsaleStopDate;
    address public MCTTokenAddress;
    address public multisigAddress;
    uint256 private totalCrowdsaleEther;
    uint256 public nextParticipantIndex;
    bool    public crowdsaleContinue;
    bool    public crowdsaleSuccess;
    struct infoUsersBuy{
        uint256 value;
        uint256 token;
    }
    mapping (address => infoUsersBuy) public tokenUsersSave;
    mapping (uint256 => address) public participantIndex;
    MCTContract mctTokenContract;
    
    /*Get Ether while anyone send Ether to ico contract address*/
    function () payable crowdsaleOpen {
        // Throw if the value = 0 
        require (msg.value != 0);
        // Check if the sender is a new user 
        if (tokenUsersSave[msg.sender].token == 0){          
            // Add a new user to the participant index   
            participantIndex[nextParticipantIndex] = msg.sender;             
            nextParticipantIndex += 1;
        }
        uint256 priceAtNow = 0;
        uint256 priceAtNowLimit = 0;
        (priceAtNow, priceAtNowLimit) = priceAt(now);
        require(msg.value >= priceAtNowLimit);
        buyMCTTokenProxy(msg.sender, msg.value, priceAtNow);

    }
    
    /*Require crowdsale open*/
    modifier crowdsaleOpen() {
        require(crowdsaleContinue == true);
        require(now >= crowdsaleStartDate);
        require(now <= crowdsaleStopDate);
        _;
    }
    
    /*Initial MCT Crowdsale*/
    function MCTCrowdsale(uint256 _crowdsaleStartDate,
        uint256 _crowdsaleStopDate,
        uint256 _totalTokenSupply
        ) {
            owner = msg.sender;
            crowdsaleStartDate = _crowdsaleStartDate;
            crowdsaleStopDate = _crowdsaleStopDate;
            require(_totalTokenSupply != 0);
            crowdsaleTokenSupply = _totalTokenSupply;
            crowdsaleContinue=true;
    }
    
    /*Get the  price according to the present time*/
    function priceAt(uint256 _atTime) internal returns(uint256, uint256) {
        if(_atTime < crowdsaleStartDate) {
            return (0, 0);
        }
        else if(_atTime < (crowdsaleStartDate + 7 days)) {
            return (30000, 20*10**18);
        }
        else if(_atTime < (crowdsaleStartDate + 16 days)) {
            return (24000, 1*10**17);
        }
        else if(_atTime < (crowdsaleStartDate + 31 days)) {
            return (20000, 1*10**17);
        }
        else {
            return (0, 0);
        }
   }
   
    /*Buy MCT Token*/        
    function buyMCTTokenProxy(address _msgSender, uint256 _msgValue, 
        uint256 _priceAtNow)  internal crowdsaleOpen returns (bool) {
        require(_msgSender != 0x0);
        require(crowdsaleTokenMint <= crowdsaleTokenSupply);                    // Require token not sold out
        uint256 tokenBuy = _msgValue * _priceAtNow / etherChange;               // Calculate the token  
        if(tokenBuy > (crowdsaleTokenSupply - crowdsaleTokenMint)){             // Require tokenBuy less than crowdsale token left 
            uint256 needRetreat = (tokenBuy - crowdsaleTokenSupply + crowdsaleTokenMint) * etherChange / _priceAtNow;
            _msgSender.transfer(needRetreat);
            _msgValue -= needRetreat;
            tokenBuy = _msgValue * _priceAtNow / etherChange;
        }
        if(buyMCT(_msgSender, tokenBuy)) {                                      // Buy MCT Token
            totalCrowdsaleEther += _msgValue;
            tokenUsersSave[_msgSender].value += _msgValue;                      // Store each person&#39;s Ether
            return true;
        }
        return false;
    }
    
    /*Buy MCT Token*/
    function buyMCT(address _sender, uint256 _tokenBuy) internal returns (bool) {
        tokenUsersSave[_sender].token += _tokenBuy;
        mctTokenContract.mintTokens(_sender, _tokenBuy);
        crowdsaleTokenMint += _tokenBuy;
        return true;
    }
    
    /*Set final period of MCT crowdsale*/
    function setFinalICOPeriod() onlyOwner {
        require(now > crowdsaleStopDate);
        crowdsaleContinue = false;
        if(this.balance >= tokenSupportSoftLimit * 4 / 10){                     // if crowdsale ether more than 8000Ether, MCT crowdsale will be Success
            crowdsaleSuccess = true;
        }
    }
    
    /* Set token contract where mints will be done (tokens will be issued)*/  
    function setTokenContract(address _MCTContractAddress) onlyOwner {     
        mctTokenContract = MCTContract(_MCTContractAddress);
        MCTTokenAddress  = _MCTContractAddress;
    }
    
    /*withdraw Ether to a multisig address*/
    function withdraw(address _multisigAddress, uint256 _balance) onlyOwner {    
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
        multisigAddress.transfer(_balance);
    }  
    
    function crowdsaleEther() returns(uint256) {
        return totalCrowdsaleEther;
    }
}