/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

pragma solidity 0.5.10; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_





=== 'EtherAuthority' Token contract with following features ===
    => ERC20 Compliance
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Burnable and minting 
    => user whitelisting 
    => air drop (active and passive)
    => in-built buy/sell functions 


======================= Quick Stats ===================
    => Name        : EAT Token
    => Symbol      : EAT
    => Total supply: 800,000,000,000 (800 Million)
    => Decimals    : 18


============= Independant Audit of the code ============
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2020 onwards EtherAuthority Inc. ( https://EtherAuthority.io )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
*/ 




//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
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
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
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
    
contract EAToken is owned {
    

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "EA Token";
    string constant private _symbol = "EAT";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 800000000000 * (10**_decimals);         //800 million tokens
    uint256 constant public maxSupply = 80000000000000 * (10**_decimals);    //80000 million tokens
    bool public safeguard;  //putting safeguard on will halt all non-owner functions

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;


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
        return _totalSupply;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user];
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
    
    constructor() public{
        //sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;
        
        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function () external payable {
      buyTokens();
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
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
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        _totalSupply = _totalSupply.sub(_value);                                   // Update totalSupply
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
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
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(_totalSupply.add(mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
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
    

    
    /*************************************/
    /*    Section for User Air drop      */
    /*************************************/
    
    bool public passiveAirdropStatus;
    uint256 public passiveAirdropTokensAllocation;
    uint256 public airdropAmount;  //in wei
    uint256 public passiveAirdropTokensSold;
    mapping(uint256 => mapping(address => bool)) public airdropClaimed;
    uint256 internal airdropClaimedIndex;
    uint256 public airdropFee = 0.05 * (10**6);
    
    /**
     * This function to start a passive air drop by admin only
     * Admin have to put airdrop amount (in wei) and total toens allocated for it.
     * Admin must keep allocated tokens in the contract
     */
    function startNewPassiveAirDrop(uint256 passiveAirdropTokensAllocation_, uint256 airdropAmount_  ) public onlyOwner {
        passiveAirdropTokensAllocation = passiveAirdropTokensAllocation_;
        airdropAmount = airdropAmount_;
        passiveAirdropStatus = true;
    } 
    
    /**
     * This function will stop any ongoing passive airdrop
     */
    function stopPassiveAirDropCompletely() public onlyOwner{
        passiveAirdropTokensAllocation = 0;
        airdropAmount = 0;
        airdropClaimedIndex++;
        passiveAirdropStatus = false;
    }
    
    /**
     * This function called by user who want to claim passive air drop.
     * He can only claim air drop once, for current air drop. If admin stop an air drop and start fresh, then users can claim again (once only).
     */
    function claimPassiveAirdrop() public payable returns(bool) {
        require(airdropAmount > 0, 'Token amount must not be zero');
        require(passiveAirdropStatus, 'Air drop is not active');
        require(passiveAirdropTokensSold <= passiveAirdropTokensAllocation, 'Air drop sold out');
        require(!airdropClaimed[airdropClaimedIndex][msg.sender], 'user claimed air drop already');
        require(!isContract(msg.sender),  'No contract address allowed to claim air drop');
        require(msg.value >= airdropFee, 'Not enough ether to claim this airdrop');
        
        _transfer(address(this), msg.sender, airdropAmount);
        passiveAirdropTokensSold += airdropAmount;
        airdropClaimed[airdropClaimedIndex][msg.sender] = true; 
        return true;
    }
    
    
    /**
     * This function allows admin to change the amount users will be getting while claiming air drop
     */
    function changePassiveAirdropAmount(uint256 newAmount) public onlyOwner{
        airdropAmount = newAmount;
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
     * This function allows admin to update airdrop fee. He can put zero as well if no fee to be charged.
     */
    function updateAirdropFee(uint256 newFee) public onlyOwner{
        airdropFee = newFee;
    }
    
    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public returns(bool) {
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
    
    
    
    
    /*************************************/
    /*  Section for User whitelisting    */
    /*************************************/
    bool public whitelistingStatus;
    mapping (address => bool) public whitelisted;
    
    /**
     * Change whitelisting status on or off
     *
     * When whitelisting is true, then crowdsale will only accept investors who are whitelisted.
     */
    function changeWhitelistingStatus() onlyOwner public{
        if (whitelistingStatus == false){
            whitelistingStatus = true;
        }
        else{
            whitelistingStatus = false;    
        }
    }
    
    /**
     * Whitelist any user address - only Owner can do this
     *
     * It will add user address in whitelisted mapping
     */
    function whitelistUser(address userAddress) onlyOwner public{
        require(whitelistingStatus == true);
        require(userAddress != address(0));
        whitelisted[userAddress] = true;
    }
    
    /**
     * Whitelist Many user address at once - only Owner can do this
     * It will require maximum of 150 addresses to prevent block gas limit max-out and DoS attack
     * It will add user address in whitelisted mapping
     */
    function whitelistManyUsers(address[] memory userAddresses) onlyOwner public{
        require(whitelistingStatus == true);
        uint256 addressCount = userAddresses.length;
        require(addressCount <= 150,"Too many addresses");
        for(uint256 i = 0; i < addressCount; i++){
            whitelisted[userAddresses[i]] = true;
        }
    }
    
    
    /*************************************/
    /*  Section for Buy/Sell of tokens   */
    /*************************************/
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    /** 
     * Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
     * newSellPrice Price the users can sell to the contract
     * newBuyPrice Price users can buy from the contract
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;   //sellPrice is 1 Token = ?? WEI
        buyPrice = newBuyPrice;     //buyPrice is 1 ETH = ?? Tokens
    }

    /**
     * Buy tokens from contract by sending ether
     * buyPrice is 1 ETH = ?? Tokens
     */
    
    function buyTokens() payable public {
        uint amount = msg.value * buyPrice;                 // calculates the amount
        _transfer(address(this), msg.sender, amount);       // makes the transfers
    }

    /**
     * Sell `amount` tokens to contract
     * amount amount of tokens to be sold
     */
    function sellTokens(uint256 amount) public {
        uint256 etherAmount = amount * sellPrice/(10**_decimals);
        require(address(this).balance >= etherAmount);   // checks if the contract has enough ether to buy
        _transfer(msg.sender, address(this), amount);           // makes the transfers
        msg.sender.transfer(etherAmount);                // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    
    
    

}