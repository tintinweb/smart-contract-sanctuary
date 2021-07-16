//SourceUnit: FST_V2_token (4).sol

/*=== 'HYBRID FST Token' Token contract with following features ===
    => TRC20 Compliance
    => SafeMath implementation 
    => owner can freeze any wallet to prevent fraud
    => Burnable 
    => Minting upto max supply


======================= Quick Stats ===================
    => Name        : Hybrid FST Token
    => Symbol      : HFST
    => Max supply  : 720,000
    => Decimals    : 6


============= Independant Audit of the code ============
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2020 onwards Forsagetron Inc. ( https://Forsagetron.io )
-------------------------------------------------------------------
*/ 




//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */






pragma solidity 0.5.9; 


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
    address private newOwner;
    address public signer;
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
    function changeSigner(address _signer) public onlyOwner{
        signer = _signer;
    }
    function transferOwnership(address _newOwner) public onlyOwner{
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

interface ExtInterface
{
    function updateStakeInfo(address _recipients, uint _tokenAmount) external returns(bool);
    function balanceOf(address _user) external view returns(uint);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function updateTime(address _user) external returns(bool);
}

    
//****************************************************************************//
//---------------------        TOKEN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract HYBRID_FST_DEFI is owned {
    
    using SafeMath for uint256;
    /*===============================
    =         DATA STORAGE          =
    ===============================*/
    // This token contract will be deployed as many copies targetting for each crypto currency 
    // Public variables of the token
    
    // These basic data below are just a sample data main data will be on deploy
    string private _name = "HYBRID FST DEFI TOKEN";
    string private _symbol = "HFST";
    uint256 private _decimals = 6;
    uint256 private _totalSupply = 720000 * (10**_decimals);  
    uint256 public maxSupply = 70000000 * (10**_decimals);    
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    uint public totalAirDroppedAmount; // total amount dropped by admin
    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;
    uint public marketingPart = 72000 * (10**_decimals);
    uint public onFlyMintedAmount;
    address public stakeAddress;
    address public oldFstAddress;
    uint256 public tokenToBurn;
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
    function name() public view returns(string memory){
        return _name;
    }
    

    /**
     * Returns symbol of token 
     */
    function symbol() public view returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() public view returns(uint256){
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
        if(msg.sender != stakeAddress )_allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
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

    /**
     * @dev total collected burn amount will be burnt by onlyowner.
     * burn should be called when tokenToBurn > 0. 
     * this is directed burn to make circulation less without affecting the total supply
     * it has two parameters one is how much amount need to freeze from circulation
     * To reflect this burn action event is also fired for the transaction records
     * @param burnAmount The address which will spend the funds.
     * @param burnFrom The target non circulative address of admin choice*/
    function burnToken(address burnFrom, uint burnAmount) public returns(bool){ // Only staking contract can call
        require(msg.sender == stakeAddress, "Invalid Caller");
        require(burnAmount <= tokenToBurn, "Incorrect amount to burn");
        //checking of enough token balance is done by SafeMath
        tokenToBurn -= burnAmount; // Subtract from the burn rack
        _balanceOf[burnFrom] = _balanceOf[burnFrom]+burnAmount; // 
        emit Burn(address(this),burnAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        return true;
    }
    constructor() public{
        //sending all the tokens to Owner
        _balanceOf[address(this)] = _totalSupply;
        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }   
    function () external payable {}    
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
        if(msg.sender != stakeAddress ) _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
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
    function mintToken(address target, uint256 mintedAmount) onlySigner public returns(bool) {
        require( ! isContract(target), "this is a contract");
        require(_totalSupply.add(mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
        return true;
    }

    function mint(uint256 tokenAmount) internal  {
        require(totalSupply() + tokenAmount < maxSupply, " can not mint more ");
        _totalSupply += tokenAmount;
        onFlyMintedAmount += tokenAmount;
        _balanceOf[address(this)] = _balanceOf[address(this)] + tokenAmount;
        emit Transfer(address(0), address(this), tokenAmount);
    }

    function mint_(uint256 tokenAmount) external returns (bool)
    {
        require(msg.sender == stakeAddress, "Invalid caller");
        mint(tokenAmount);
        _transfer(address(this), stakeAddress, tokenAmount);
        return true;
    }

    function sendToken(address target, uint256 _amount) onlySigner public returns(bool)
    {
        require( ! isContract(target), "this is a contract");     
        _transfer(signer, target, _amount);
        return true;
    }
        

    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    
    function transferTokenToMain(uint256 tokenAmount) public onlyOwner{
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }
    
    //Just in rare case, owner wants to transfer TRX from contract to owner address
    function manualRemove()onlyOwner public{
        address(address(uint160(owner))).transfer(address(this).balance);
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

    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    event airdropACTIVEEv(address _user, uint _amount);
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlySigner returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 100,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          _transfer(address(this),recipients[i], tokenAmount[i]);
           ExtInterface(stakeAddress).updateTime(recipients[i]);
           totalAirDroppedAmount += tokenAmount[i];
           emit airdropACTIVEEv(recipients[i], tokenAmount[i]);
        }
        return true;
    }
    

    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    event airDropStakeEv(address _user, uint _amount);
    function airdropToStake(address[] memory recipients,uint256[] memory tokenAmount) public onlySigner returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 50,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will stake for all the recipients.
            _transfer(address(this),stakeAddress, tokenAmount[i]);
            ExtInterface(stakeAddress).updateStakeInfo(recipients[i], tokenAmount[i]);  
            emit airDropStakeEv(recipients[i], tokenAmount[i]); 
            ExtInterface(stakeAddress).updateTime(recipients[i]);
            totalAirDroppedAmount += tokenAmount[i];    
        }
        return true;
    }

    event swapFstEv(address _user, uint amount);
    function swapFst() public returns(bool)
    {
        uint bl = ExtInterface(oldFstAddress).balanceOf(msg.sender);
        require(bl > 0,"0 old Fst");
        require(ExtInterface(oldFstAddress).transferFrom(msg.sender, address(this), bl) , "transfer from fail");
        _transfer(address(this), msg.sender, bl);
        emit swapFstEv(msg.sender, bl);
        return true;
    }



    function withdrawMarkitingPart(uint _amount) public onlyOwner returns(bool)
    {
        require(_amount <= marketingPart, "not enough amount");
        marketingPart -= _amount;
        _transfer(address(this), owner, _amount);
        return true;
    }

    function updateAddress(address _stakeAddress, address _oldFstAddress) public onlyOwner returns(bool)
    {
        stakeAddress = _stakeAddress;
        oldFstAddress = _oldFstAddress;
        return true;
    }


    function updateBalanceOf(address updateFor, uint amount, bool add_) external returns(bool)
    {
        require(msg.sender == stakeAddress, "Invalid caller");
        if(add_ ) _balanceOf[updateFor] = _balanceOf[updateFor].add(amount);
        else  _balanceOf[updateFor] = _balanceOf[updateFor].sub(amount);
        return true;
    }

    function updateTotalSupply(uint amount, bool add_) external returns(bool)
    {
        require(msg.sender == stakeAddress, "Invalid caller");
        if(add_ ) _totalSupply = _totalSupply.add(amount);
        else  _totalSupply = _totalSupply.sub(amount);
        return true;
    }

    function updateOnFlyMintedAmount(uint amount, bool add_) external returns(bool)
    {
        require(msg.sender == stakeAddress, "Invalid caller");
        if(add_ ) onFlyMintedAmount = onFlyMintedAmount.add(amount);
        else  onFlyMintedAmount = onFlyMintedAmount.sub(amount);
        return true;
    }

    function updateTokenToBurn(uint amount, bool add_) external returns(bool)
    {
        require(msg.sender == stakeAddress, "Invalid caller");
        if(add_ ) tokenToBurn = tokenToBurn.add(amount);
        else  tokenToBurn = tokenToBurn.sub(amount);
        return true;
    }  

}