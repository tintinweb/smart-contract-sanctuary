pragma solidity ^0.4.13;

contract ERC20 {
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//Safe math
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool Yes) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _address) constant returns (uint balance) {
    return balances[_address];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract RBRToken is StandardToken {

    string public name = "Rebero Token";
    string public symbol = "RBR";
    uint8 public decimals = 18;
    uint public totalSupply = 500000000 * (10 ** uint(decimals));//Crowdsale supply
    uint public poolEcosystem = 50000000 * (10 ** uint(decimals));//Ecosystem pool
    uint public poolTeam = 25000000 * (10 ** uint(decimals));//Team pool
    uint public poolBounty = 50000000 * (10 ** uint(decimals));//Bounty pool
    uint public poolSale = 375000000 * (10 ** uint(decimals));//Sale pool
	uint public ownerInitialBalance = 125000000 * (10 ** uint(decimals));//Add reserved pool tokens to the owner address
	uint public sellPrice = 1000000000000000 wei;//Tokens are sold for this manual price, rather than predefined price.
    
    //Addresses that are allowed to transfer tokens
    mapping (address => bool) public allowedTransfer;
	
    //Bonuses for selected addresses
    mapping (address => uint) public specialBonus;
    
	//Technical variables to store states
	bool public TransferAllowed = true;//Token transfers are blocked
    bool public CrowdsalePaused = false; //Whether the Crowdsale is now suspended (true or false)
    uint public currentBonus = 0;//Current bonus to tokens purchases
	
    //Technical variables to store statistical data
	uint public StatsEthereumRaised = 0 wei;//Total Ethereum raised
	uint public StatsSold = 0;//Sold tokens amount
	uint public StatsMinted = 0;//Minted tokens amount
	uint public StatsReserved = 0;//Reserved tokens amount
	uint public StatsTotal = 0;//Overall tokens amount

    //Event logs
    event Buy(address indexed sender, uint eth, uint tokens, uint bonus);//Tokens purchased
    event Mint(address indexed from, uint tokens);// This notifies clients about the amount minted
    event Burn(address indexed from, uint tokens);// This notifies clients about the amount burnt
    event PriceChanged(string _text, uint _tokenPrice);//Manual token price
    event BonusChanged(string _text, uint _percent);//Crowdsale bonus percent for each purchase
    
    address public owner = 0x0;//Admin actions
    address public minter = 0x0;//Minter tokens
    address public wallet = 0x0;//Wallet to receive ETH
 
function RBRToken() payable {
    
      address owner = 0xB61E51D10C09b91b1Ff12eFAa1baF4B149fF87d6;
      address minter = 0x39c98ce5F3e9a3960C1Bc1BaF258f4E160210d21;
      address wallet = 0xD9E5F5d2595068E8865454A370Fa79A6eE122e6b;
    
      balances[owner] = 0;
      balances[minter] = 0;
      balances[wallet] = 0;
    
      //Add reserved pool tokens to the owner address
      balances[owner] = safeAdd(balances[owner], ownerInitialBalance);
      StatsReserved = safeAdd(StatsReserved, ownerInitialBalance);//Update number of tokens reserved
      StatsTotal = safeAdd(StatsTotal, ownerInitialBalance);//Update total number of tokens
      Transfer(0, this, ownerInitialBalance);
      Transfer(this, owner, ownerInitialBalance);
    
      allowedTransfer[owner] = true;
      allowedTransfer[minter] = true;
      allowedTransfer[wallet] = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    //Transaction received - run the purchase function
    function() payable {
        buy();
    }
    
    //See the current token price in wei (https://etherconverter.online to convert to other units, such as ETH)
    function price() constant returns (uint) {
        return sellPrice;
    }
    
    //Manually set the token price (in wei - https://etherconverter.online)
    function setTokenPrice(uint _tokenPrice) external {
        require(msg.sender == owner || msg.sender == minter);
        sellPrice = _tokenPrice;
        PriceChanged("New price is ", _tokenPrice);
    }
    
    //Set the crowdsale bonus percent for each purchase
    function setBonus(uint _percent) external {
        require(msg.sender == owner || msg.sender == minter);
        require(_percent >=0);
        currentBonus = safeAdd(100,_percent);
        BonusChanged("New crowdsale bonus is ", _percent);
    }
    
    //Set the bonus percent for selected address
    function setSpecialBonus(address _target, uint _percent) external {
        require(msg.sender == owner || msg.sender == minter);
        require(_percent >=0);
        specialBonus[_target] = safeAdd(100,_percent);
    }
     
    //Allow or prohibit token transfers
    function setTransferAllowance(bool _allowance) external onlyOwner {
        TransferAllowed = _allowance;
    }
    
    //Temporarily suspend token sale
    function eventPause(bool _pause) external onlyOwner {
        CrowdsalePaused = _pause;
    }
    
    // Send `_amount` of tokens to `_target`
    function mintTokens(address _target, uint _amount) external returns (bool) {
        require(msg.sender == owner || msg.sender == minter);
        require(_amount > 0);//Number of tokens must be greater than 0
        uint amount=_amount * (10 ** uint256(decimals));
        require(safeAdd(StatsTotal, amount) <= totalSupply);//The amount of tokens cannot be greater than Total supply
        balances[_target] = safeAdd(balances[_target], amount);
        StatsMinted = safeAdd(StatsMinted, amount);//Update number of tokens minted
        StatsTotal = safeAdd(StatsTotal, amount);//Update total number of tokens
        Transfer(0, this, amount);
        Transfer(this, _target, amount);
        Mint(_target, amount);
        return true;
    }
    
    // Decrease user balance
    function decreaseTokens(address _target, uint _amount) external returns (bool) {
        require(msg.sender == owner || msg.sender == minter);
        require(_amount > 0);//Number of tokens must be greater than 0
        uint amount=_amount * (10 ** uint256(decimals));
        balances[_target] = safeSub(balances[_target], amount);
        StatsMinted = safeSub(StatsMinted, amount);//Update number of tokens minted
        StatsTotal = safeSub(StatsTotal, amount);//Update total number of tokens
        Transfer(_target, 0, amount);
        Burn(_target, amount);
        return true;
    }
    
    // Allow `_target` make token tranfers
    function allowTransfer(address _target, bool _allow) external onlyOwner {
        allowedTransfer[_target] = _allow;
    }

    //The function of buying tokens on Crowdsale
    function buy() public payable returns(bool) {

        require(msg.sender != owner);//The founder cannot buy tokens
        require(msg.sender != minter);//The minter cannot buy tokens
        require(msg.sender != wallet);//The wallet address cannot buy tokens
        require(!CrowdsalePaused);//Purchase permitted if Crowdsale is paused
        require(msg.value >= price());//The amount received in wei must be greater than the cost of 1 token

        uint tokens = msg.value/price();//Number of tokens to be received by the buyer
        require(tokens > 0);//Number of tokens must be greater than 0
        
        //Add bonus tokens
        if(currentBonus > 0){
        uint bonus = safeMul(tokens, currentBonus);
        bonus = safeDiv(bonus, 100);
        tokens = safeAdd(bonus, tokens);
        }
        
        //Add bonus tokens if this buyer have special bonus
        if(specialBonus[msg.sender] > 0){
        uint addressBonus = safeMul(tokens, specialBonus[msg.sender]);
        addressBonus = safeDiv(addressBonus, 100);
        tokens = safeAdd(addressBonus, tokens);
        }
        
        uint tokensToAdd=tokens * (10 ** uint256(decimals));
        
        require(safeAdd(StatsSold, tokensToAdd) <= poolSale);//The amount of sold tokens cannot be greater than the Sale supply
        
        wallet.transfer(msg.value);//Send received ETH to the fundraising purse
        
        //Crediting of tokens to the buyer
        balances[msg.sender] = safeAdd(balances[msg.sender], tokensToAdd);
        StatsSold = safeAdd(StatsSold, tokensToAdd);//Update number of tokens sold
        StatsTotal = safeAdd(StatsTotal, tokensToAdd);//Update total number of tokens
        Transfer(0, this, tokensToAdd);
        Transfer(this, msg.sender, tokensToAdd);
        
        StatsEthereumRaised = safeAdd(StatsEthereumRaised, msg.value);//Update total ETH collected
        
        //Record event logs to the blockchain
        Buy(msg.sender, msg.value, tokensToAdd, currentBonus);

        return true;
    }
    
    function transfer(address _to, uint _value) returns (bool success) {
        
        //Forbid token transfers
        if(!TransferAllowed){
            require(allowedTransfer[msg.sender]);
        }
        
    return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        
        //Forbid token transfers
        if(!TransferAllowed){
            require(allowedTransfer[msg.sender]);
        }
        
        return super.transferFrom(_from, _to, _value);
    }

    //Change owner
    function changeOwner(address _to) external onlyOwner() {
        balances[_to] = balances[owner];
        balances[owner] = 0;
        owner = _to;
    }

    //Change minter
    function changeMinter(address _to) external onlyOwner() {
        balances[_to] = balances[minter];
        balances[minter] = 0;
        minter = _to;
    }

    //Change wallet
    function changeWallet(address _to) external onlyOwner() {
        balances[_to] = balances[wallet];
        balances[wallet] = 0;
        wallet = _to;
    }
}