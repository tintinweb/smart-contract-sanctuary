/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-21
*/

pragma solidity 0.4.25; 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address public owner;
    address public newOwner;
    address public  signer;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }
    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}  
    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract solidSwing is owned {
    

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "Swing Token";
    string constant private _symbol = "STK";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply ; 
    bool public safeguard; 

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => uint256) public _bonusBalance;
    mapping (address => uint256) public sellTime;
    mapping (address => uint256) public sellAmount;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;

    uint public benchMarkValue; // with 18 decimal values
    uint public reBaseFactor=100 * (10 ** _decimals); // with 18 decimal values in percent
    uint public currentPrice; // with 18 decimal values
    uint public lastSnapPrice; // with 18 decimal values
    uint public base = 100 * (10 ** _decimals);
    uint public snapTime;

    mapping (address => uint) public lastClaimTime;
    uint public claimTimeLimit = 86400;
    uint public dailyLimit = 1000000;
    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);



    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    /**
     * Returns name of token 
     */
    function name() public pure returns(string memory){
        return _name;
    }
    
    /**
     * Returns symbol of token 
     */
    function symbol() public pure returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() public pure returns(uint256){
        return _decimals;
    }
    
    /**
     * Returns totalSupply of token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply * reBaseFactor / base;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user] * reBaseFactor / base;
    }
    
    /**
     * Returns allowance of token 
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    /**
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }

    /**
        * Transfer tokens
        *
        * Send `_value` tokens to `_to` from your account
        *
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
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
        //checking of allowance and token value is done by SafeMath
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor(uint _benchMarkValue) public{
        benchMarkValue = _benchMarkValue;
        snapTime = now;
        birthTime = now;
    }
    
    function () external  {
      buyTokens();
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) internal returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
       
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function mintToken(address target, uint256 mintedAmount) internal {
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }
    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }
    
    //Just in rare case, owner wants to transfer Ether from contract to owner address
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    

    /**
     * This function checks if given address is contract address or normal wallet
     */
    function isContract(address _address) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    
  
    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyOwner returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }

    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropGroup(address[] memory recipients,uint256[] memory tokenAmount) public onlySigner returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(!safeguard, "safe gurard active");
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          //mintToken(recipients[i], tokenAmount[i]);
          _bonusBalance[recipients[i]] += tokenAmount[i];
        }
        return true;
    }

    event claimBonusAmountEv(address _user,uint amount);
    function claimBonusAmount(uint _amount) public returns(bool)
    {
        require(!safeguard, "safe gurard active");
        uint bB = _bonusBalance[msg.sender];
        require(bB >= _amount, "invalid amount");
        uint lt = lastClaimTime[msg.sender];
        require(now <= lt + claimTimeLimit, "please wait more");
        if(_amount > 1000 ) require(_amount <= bB * dailyLimit / 100000000, "daily limit crossed");
        lastClaimTime[msg.sender] = now;
        _bonusBalance[msg.sender] -= _amount;
        mintToken(msg.sender, _amount);
        emit claimBonusAmountEv(msg.sender, _amount);
        return true;
    }

    function setLimits(uint _claimTimeLimit, uint _dailyLimit) public onlyOwner returns(bool)
    {
        claimTimeLimit = _claimTimeLimit;
        dailyLimit = _dailyLimit;
        return true;
    }
    /*************************************/
    /*  Section for Buy/Sell of tokens   */
    /*************************************/
    

    bool public buySellActive;
    function setBuySaleActive(bool _buySaleActive) public onlyOwner returns(bool)
    {
        buySellActive = _buySaleActive;
        return true;
    }

    function updatePrice(uint _price) public onlySigner returns(bool)
    {
        currentPrice = _price;
        return true;
    }

    event buyTokensEv(address user, uint amount, uint price);   
    function buyTokens()  public payable {
        require(buySellActive, "sale not available");
        uint amount = (msg.value * 1000000 / currentPrice ) / 1000000;                 // calculates the amount
        mintToken(msg.sender, amount);       // makes the transfers
        emit buyTokensEv(msg.sender, amount, currentPrice);
    }

    /**
     * Sell `amount` tokens to contract
     * amount amount of tokens to be sold
     */
    event sellTokensEv(address user, uint amount, uint price);   
    function sellTokens(uint256 amount) public {
        require(buySellActive, "sale not available");
        uint256 etherAmount = amount * currentPrice/(10**_decimals);
        require(address(this).balance >= etherAmount);   // checks if the contract has enough ether to buy
        burn(amount);           // makes the transfers
        uint sT = sellTime[msg.sender];
        if(sT == 0 || sT < now - 86400)
        {
          sellTime[msg.sender] = now;
          sellAmount[msg.sender] = amount;
        }
        else if(sT >= now - 86400) 
        {
            sellAmount[msg.sender] += amount;
        }
        msg.sender.transfer(etherAmount);                // sends ether to the seller. It's important to do this last to avoid recursion attacks
        emit sellTokensEv(msg.sender, amount, currentPrice);
    }

    function snapShot() public onlySigner returns(bool)
    {
      require(!safeguard, "safe gurard active");
      if(currentPrice >= lastSnapPrice)
      {
        reBaseFactor = currentPrice * base / lastSnapPrice;
      }
      lastSnapPrice = currentPrice; 
      snapTime = now;
      return true;
    } 
    event getMyRebaseDipEv(address _user, uint amount);        
    function getMyRebaseDip() public returns (bool)
    {
        require(!safeguard, "safe gurard active");
        uint sA = sellAmount[msg.sender];
        if(currentPrice < benchMarkValue &&  sA > 0)
        {
            uint rB = benchMarkValue * base / currentPrice;
            mintToken(msg.sender, sA * rB / base);       // makes the transfers
            emit getMyRebaseDipEv(msg.sender, sA * rB / base);  
        }
        return true;
    }

    function viewMyRebaseDip() public view returns (uint)
    {
        uint sA = sellAmount[msg.sender];
        if(currentPrice < benchMarkValue &&  sA > 0)
        {
            uint rB = benchMarkValue * base / currentPrice;
            return sA * rB / base; 
        }
    }


    /*************************************/
    /*  Allocations Setup & Control   */
    /*************************************/
    struct alloc
    {
        bytes32 fundName;
        uint totalAmount;
        uint withdrawLimit;
        uint withdrawInterval;
        uint lastWithdrawTime;
        uint withdrawnAmount;
        address authorisedAddress;
    }

    alloc[] public allocation;
    uint public birthTime;
    function defineAllocations(bytes32 _fundName, uint _totalAmount, uint _withdrawLimit, uint _withdrawInterval, address _authorisedAddress) public onlyOwner returns(bool)
    {
        require(birthTime + 30 days > now, "time is over");
        alloc memory temp;
        temp.fundName = _fundName;
        temp.totalAmount = _totalAmount;
        temp.withdrawLimit = _withdrawLimit;
        temp.withdrawInterval = _withdrawInterval;
        temp.lastWithdrawTime = now;
        temp.authorisedAddress = _authorisedAddress;
        allocation.push(temp);
        return true;
    }

    event allocateFundEv(address _user, uint _amount);
    function allocateFund(uint allocationIndex) public returns (bool)
    {
        require(!safeguard, "safe gurard active");
        require(allocationIndex < allocation.length, "Invalid index");
        alloc memory temp = allocation[allocationIndex];
        require(msg.sender == temp.authorisedAddress, "Invalid caller" );
        require(temp.lastWithdrawTime + temp.withdrawInterval < now, "please wait more");
        uint remain = temp.totalAmount - temp.withdrawnAmount;
        require( remain <= temp.withdrawLimit, "no fund remains");
        if(remain > temp.withdrawLimit ) remain = temp.withdrawLimit;
        allocation[allocationIndex].withdrawnAmount -= remain;
        allocation[allocationIndex].lastWithdrawTime = now;
        mintToken(msg.sender, temp.withdrawLimit);
        emit allocateFundEv(msg.sender, remain);
        return true;
    }

}