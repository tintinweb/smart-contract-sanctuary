pragma solidity ^0.4.18;

contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() public{
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract tokenRecipient { 
  function receiveApproval (address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token {

    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant  returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DASABI_IO_Contract is ERC20Token, Owned{

    /* Public variables of the token */
    string  public constant name = "dasabi.io DSBC";
    string  public constant symbol = "DSBC";
    uint256 public constant decimals = 18;
    uint256 private constant etherChange = 10**18;
    
    /* Variables of the token */
    uint256 public totalSupply;
    uint256 public totalRemainSupply;
    uint256 public ExchangeRate;
    
    uint256 public CandyRate;
    
    bool    public crowdsaleIsOpen;
    bool    public CandyDropIsOpen;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) public blacklist;
    
    address public multisigAddress;
    /* Events */
    event mintToken(address indexed _to, uint256 _value);
    event burnToken(address indexed _from, uint256 _value);
    
    function () payable public {
        require (crowdsaleIsOpen == true);
              
        
        if (msg.value > 0) {
        	mintDSBCToken(msg.sender, (msg.value * ExchangeRate * 10**decimals) / etherChange);
        }
        
        if(CandyDropIsOpen){
	        if(!blacklist[msg.sender]){
		        mintDSBCToken(msg.sender, CandyRate * 10**decimals);
		        blacklist[msg.sender] = true;
		    }
	    }
    }
    /* Initializes contract and  sets restricted addresses */
    function DASABI_IO_Contract() public {
        owner = msg.sender;
        totalSupply = 1000000000 * 10**decimals;
        ExchangeRate = 50000;
        CandyRate = 50;
        totalRemainSupply = totalSupply;
        crowdsaleIsOpen = true;
        CandyDropIsOpen = true;
    }
    
    function setExchangeRate(uint256 _ExchangeRate) public onlyOwner {
        ExchangeRate = _ExchangeRate;
    }
    
    function crowdsaleOpen(bool _crowdsaleIsOpen) public onlyOwner{
        crowdsaleIsOpen = _crowdsaleIsOpen;
    }
    
    function CandyDropOpen(bool _CandyDropIsOpen) public onlyOwner{
        CandyDropIsOpen = _CandyDropIsOpen;
    }
    
    /* Returns total supply of issued tokens */
    function totalDistributed() public constant returns (uint256)  {   
        return totalSupply - totalRemainSupply ;
    }

    /* Returns balance of address */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (balances[msg.sender] >= _value);            // Throw if sender has insufficient balance
        require (balances[_to] + _value > balances[_to]);   // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers blaance 
        Transfer(msg.sender, _to, _value);                  // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;          // Set allowance         
        Approval(msg.sender, _spender, _value);             // Raise Approval event         
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */ 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {            
        tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract         
        approve(_spender, _value);                                      // Set approval to contract for _value         
        spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract         
        return true;     
    }     

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {      
        require (balances[_from] > _value);                // Throw if sender does not have enough balance     
        require (balances[_to] + _value > balances[_to]);  // Throw if overflow detected    
        require (_value <= allowances[_from][msg.sender]);  // Throw if you do not have allowance       
        balances[_from] -= _value;                          // Deduct senders balance    
        balances[_to] += _value;                            // Add recipient blaance         
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address         
        Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;     
    }         

    /* Get the amount of allowed tokens to spend */     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {         
        return allowances[_owner][_spender];
    }     
        
    /*withdraw Ether to a multisig address*/
    function withdraw(address _multisigAddress) public onlyOwner {    
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
        multisigAddress.transfer(this.balance);
    }  
    
    /* Issue new tokens */     
    function mintDSBCToken(address _to, uint256 _amount) internal { 
        require (balances[_to] + _amount > balances[_to]);      // Check for overflows
        require (totalRemainSupply > _amount);
        totalRemainSupply -= _amount;                           // Update total supply
        balances[_to] += _amount;                               // Set minted coins to target
        mintToken(_to, _amount);                                // Create Mint event       
        Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
    }  
    
    function mintTokens(address _sendTo, uint256 _sendAmount)public onlyOwner {
        mintDSBCToken(_sendTo, _sendAmount);
    }
    
    /* Destroy tokens from owners account */
    function burnTokens(uint256 _amount)public onlyOwner {
        require (balances[msg.sender] > _amount);               // Throw if you do not have enough balance
        totalRemainSupply += _amount;                           // Deduct totalSupply
        balances[msg.sender] -= _amount;                             // Destroy coins on senders wallet
        burnToken(msg.sender, _amount);                              // Raise Burn event
    }
}