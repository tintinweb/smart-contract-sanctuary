//SourceUnit: Generic_USDF.sol

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
 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function balanceOf(address _user) external view returns(uint);
    function mintToken(address target, uint256 mintedAmount) external returns(bool);
    function viewCurrentPrice(uint a) external view returns(uint);
    
 }   
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//   
contract Generic_USDF is owned {
    /*===============================
    =         DATA STORAGE          =
    ===============================*/
    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "USDF Token";
    string constant private _symbol = "USDF";
    uint256 constant private _decimals = 6;
    uint256 private _totalSupply = 0;         //will mint and burn as per target use case;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;
    address public fstTokenAddress;
    address public minerAddress;
    mapping(address => bool) public authorisedContract;
    uint public usdfToFstPercent = 200000;
    uint public trxToUsdfPercent = 200000;   
    bool public blockTRXOutMode;
    bool public blockTRXInMode;
    uint public tokenToBurn;
    uint public lockDays = 100; // change it to '100 days' in production
    uint public dailyLimit = 1000000; // = 1%
    mapping(address => uint) public lastWithdrawnTime;

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
        if(!authorisedContract[msg.sender]) _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
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

    }    
    function () external payable {

    }
    function setFstTokenAddress(address _fstTokenAddress, address _minerAddress) public onlyOwner returns(bool)
    {
        fstTokenAddress = _fstTokenAddress;
        minerAddress = _minerAddress;
        return true;
    }
    function setauthorisedContract(address _authorisedContract, bool _allow) public onlyOwner returns(bool)
    {
        authorisedContract[_authorisedContract] = _allow;
        return true;
    }
    function setTrxToUsdfPercent(uint _trxToUsdfPercent) public onlySigner returns(bool)
    {
        trxToUsdfPercent = _trxToUsdfPercent;
        return true;
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    /**
     * @dev total collected burn amount will be burnt by onlyowner.
     * burn should be called when tokenToBurn > 0. 
     * this is directed burn to make circulation less without affecting the total supply
     * it has two parameters one is how much amount need to freeze from circulation
     * To reflect this burn action event is also fired for the transaction records
     * @param burnAmount The address which will spend the funds.
     * @param burnFrom The target non circulative address of admin choice*/
    function burnToken(address burnFrom, uint burnAmount) public returns(bool){ // Only staking contract can call
        require(authorisedContract[msg.sender] || msg.sender == signer, "Invalid Caller");
        // checking value before subtraction to avoid underflow
        require(burnAmount <= tokenToBurn, "Incorrect amount to burn"); 
        tokenToBurn -= burnAmount; // Subtract from the burn rack
        _balanceOf[burnFrom] -= burnAmount; // 
        emit Burn(address(this),burnAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        return true;
    }
    function sendToBurn(address _user, uint _value) internal returns(bool)
    {
        _balanceOf[_user] = _balanceOf[_user].sub(_value);
        tokenToBurn += _value;
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
    function mintToken(address target, uint256 mintedAmount)  internal {
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
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
           mintToken(recipients[i], tokenAmount[i]);
           emit airdropACTIVEEv(recipients[i], tokenAmount[i]);
        }
        return true;
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
    function manualWithdrawTrx(uint amount)onlyOwner public{
        owner.transfer(amount);
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
     * This code checks all 3 method to check if the given address is contract or 
     * not, 1 checks code size, 2 checks if origin caller and current caller is 
     * same or not, 3 checks the hash of caller also to assure if it is a contract
     */
    function isContract(address _address) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return ( size > 0 || msg.sender != tx.origin );
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
    // currency conversion codes
    function getUsdfByTrx() payable public returns(uint) {
        require(!blockTRXInMode, "purchasng by trx blocked");
        uint amount = trxToUsdfValue(msg.value);                 // calculates the amount
        mintToken(tx.origin, amount);       // mint tokens
        return amount;
    }
    function getTrxByUsdf(uint usdfAmount)  public returns(uint) {
        require(!blockTRXOutMode, "selling for trx blocked");
        uint lwT = lastWithdrawnTime[msg.sender];
        uint bO = balanceOf(msg.sender);
        require(usdfAmount <= (bO * dailyLimit / 100000000) || usdfAmount <= 100, "wait please");
        require(lwT + lockDays <= now || lwT == 0, "please wait little more");
        require(balanceOf(msg.sender) >= usdfAmount, "Insufficient token Amount");
        sendToBurn(msg.sender,usdfAmount);
        lastWithdrawnTime[msg.sender] = now;
        usdfAmount = usdfToTrxValue(usdfAmount);                // calculates the amount
        msg.sender.transfer(usdfAmount);       // mint tokens
        return usdfAmount;
    }
    function getUsdfByFst(uint fstAmount)  public  returns(uint){
        require(tokenInterface(fstTokenAddress).transferFrom(msg.sender,address(this), fstAmount) ,"token transfer fail");
        getCurrentPrice();
        fstAmount = fstToUsdfValue(fstAmount);           // calculates the amount
        mintToken(msg.sender, fstAmount);       // mint tokens
        return fstAmount;
    }
    function getfstByUsdf(uint usdfAmount)  public returns(uint){
        require(balanceOf(msg.sender) >= usdfAmount, "Insufficient token Amount");
        require(sendToBurn(msg.sender, usdfAmount),"usdf burn failed");
        getCurrentPrice();
        usdfAmount = usdfToFstValue(usdfAmount);   
        tokenInterface(fstTokenAddress).mintToken(msg.sender, usdfAmount);
        return usdfAmount;
    }
    function getUsdfByFstOnlySystem(address _user, uint fstAmount)  public  returns(bool){
        require(authorisedContract[msg.sender], "Invalid caller");
        require(tokenInterface(fstTokenAddress).transferFrom(_user,address(this), fstAmount) ,"token transfer fail");
        getCurrentPrice();
        fstAmount = fstToUsdfValue(fstAmount);           // calculates the amount
        mintToken(msg.sender, fstAmount);       // mint tokens
        return true;
    } 
    function getCurrentPrice() internal returns(bool)
    {
        uint cP = tokenInterface(minerAddress).viewCurrentPrice(0); // trx in 1 fst
        uint uP = 100000000 / trxToUsdfPercent; // trx in 1 usdf
        usdfToFstPercent = (uP * 100000000 / cP) * 1000000;
        return true;
    }       
    function setblockTRXOutMode(bool _blockTRXOutMode, bool _bockTRXInMode) public onlyOwner returns(bool)
    {
        blockTRXOutMode = _blockTRXOutMode;
        blockTRXInMode = _bockTRXInMode;
        return true;
    }
    function setDaysFactor(uint _noOfDaysToLockInSecond) public onlyOwner returns(bool)
    {
        lockDays = _noOfDaysToLockInSecond;
        return true;
    } 
    // use 1000000 for 1% ( one digit will be taken as decimal )
    function setdailyROILimitPercent(uint _dailyLimit) public  onlyOwner returns(bool)
    {
        dailyLimit = _dailyLimit;
        return true;
    }       
    function usdfToFstValue(uint _usdfAmount) public view returns(uint)
    {
        return _usdfAmount * usdfToFstPercent / 100000000;
    }
    function fstToUsdfValue(uint _fstAmount) public view returns(uint)
    {
        return _fstAmount * 100000000 / usdfToFstPercent;
    }
    function trxToUsdfValue(uint _trxAmount) public view returns(uint)
    {
        return _trxAmount * trxToUsdfPercent / 100000000;
    }

    function usdfToTrxValue(uint _usdfAmount) public view returns(uint)
    {
        return _usdfAmount * 100000000 / trxToUsdfPercent;
    }
}