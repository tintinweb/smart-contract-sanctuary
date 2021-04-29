/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.5.11; /*

    ___________________________________________________________________
      _      _                                        ______           
      |  |  /          /                                /              
    --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
      |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
    __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    
    
███████╗███╗░░░███╗░█████╗░██████╗░██╗░░██╗███████╗████████╗████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
██╔════╝████╗░████║██╔══██╗██╔══██╗██║░██╔╝██╔════╝╚══██╔══╝╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
█████╗░░██╔████╔██║███████║██████╔╝█████═╝░█████╗░░░░░██║░░░░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
██╔══╝░░██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗░██╔══╝░░░░░██║░░░░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
███████╗██║░╚═╝░██║██║░░██║██║░░██║██║░╚██╗███████╗░░░██║░░░░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝

                
// -------------------------------------------------------------------------------
// eMarket Token contract with following features:
//      => ERC20 Compliance;
//      => Higher degree of control by owner - safeguard functionality;
//      => SafeMath implementation;
//      => Burnable and minting;
//      => user whitelisting;
//      => air drop (active and passive);
//      => built-in buy/sell functions;
//      => Token swap functionality (implemented for future use).
//
// Name        : eMarket Token
// Symbol      : EFI
// Total supply: 1,000,000,000 (1 Billion)
// Decimals    : 18
//
// Special thanks to openzeppelin for inspiration: ( https://github.com/zeppelinos )
// ----------------------------------------------------------------------------------
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
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent accidental transfer of ownership
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
    
contract eMarketToken is owned {
    
    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant public name = "eMarket Token";
    string constant public symbol = "EFI";
    uint256 constant public decimals = 18;
    uint256 public totalSupply = 1000000000 * (10**decimals);   //1 billion tokens
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    bool public tokenSwap = false;  //when tokenSwap is on then all the token transfer to contract will trigger token swap

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
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

    // This is for token swap
    event TokenSwap(address indexed user, uint256 value);

    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, can only be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        
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
        
        //code for token swap
        if(tokenSwap && _to == address(this)){
            //fire tokenSwap event. This event can be listed by oracle and issue tokens of ethereum or another blockchain
            emit TokenSwap(msg.sender, _value);
        }
        
        return true;
    }

    /**
        * Transfer tokens from other address
        *
        * Send `_value` tokens to `_to` on behalf of `_from`
        *
        * @param _from The address of the sender
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        * Set allowance for other address
        *
        * Allows `_spender` to spend no more than `_value` tokens on your behalf
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor() public{
        //sending all the tokens to Owner
        balanceOf[owner] = totalSupply;
        
        //firing event which logs this transaction
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function () external payable {
        
        buyTokens();
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of tokens to burn
        */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /**
        * Destroy tokens from other account
        *
        * Remove `_value` tokens from the system irreversibly on behalf of `_from`
        *
        * @param _from the address of the sender
        * @param _value the amount of tokens to burn
        */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                   // Update totalSupply
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
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working!
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
        * When safeguard is false, then all the functions will resume working!
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
     * This function allows admins to start or stop token swaps
     */
    function changeTokenSwapStatus() public onlyOwner{
        if (tokenSwap == false){
            tokenSwap = true;
        }
        else{
            tokenSwap = false;    
        }
    }
    
    /*************************************/
    /*    Section for User Airdrop      */
    /*************************************/
    
    bool public passiveAirdropStatus;
    uint256 public passiveAirdropTokensAllocation;
    uint256 public airdropAmount;  //in wei
    uint256 public passiveAirdropTokensSold;
    mapping(uint256 => mapping(address => bool)) public airdropClaimed;
    uint256 internal airdropClaimedIndex;
    uint256 public airdropFee = 0.05 ether;
    
    /**
     * This function is to start a passive airdrop by admin only
     * Admin have to put airdrop amount (in wei) and total tokens allocated for it
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
     * This function called by user who want to claim passive airdrop
     * Users can only claim airdrop once, for current airdrop. If admin stops an airdrop and starts another, then users can claim again (once only).
     */
    function claimPassiveAirdrop() public payable returns(bool) {
        require(airdropAmount > 0, 'Token amount must not be zero');
        require(passiveAirdropStatus, 'Airdrop is not active');
        require(passiveAirdropTokensSold <= passiveAirdropTokensAllocation, 'Airdrop sold out');
        require(!airdropClaimed[airdropClaimedIndex][msg.sender], 'user claimed airdrop already');
        require(!isContract(msg.sender),  'No contract address allowed to claim airdrop');
        require(msg.value >= airdropFee, 'Not enough ether to claim this airdrop');
        
        _transfer(address(this), msg.sender, airdropAmount);
        passiveAirdropTokensSold += airdropAmount;
        airdropClaimed[airdropClaimedIndex][msg.sender] = true; 
        return true;
    }
    
    /**
     * This function allows admin to change the amount users will be getting while claiming airdrop
     */
    function changePassiveAirdropAmount(uint256 newAmount) public onlyOwner{
        airdropAmount = newAmount;
    }
    
    /**
     * This function checks if given address is a contract address or normal wallet
     */
    function isContract(address _address) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    
    /**
     * This function allows admin to update airdrop fee. He can put zero as well if no fee to be charged
     */
    function updateAirdropFee(uint256 newFee) public onlyOwner{
        airdropFee = newFee;
    }
    
    /**
     * Run an ACTIVE Airdrop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients,uint256 tokenAmount) public onlyOwner {
        require(recipients.length <= 150);
        uint256 totalAddresses = recipients.length;
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas
          _transfer(address(this), recipients[i], tokenAmount);
        }
    }
    
    /*************************************/
    /*  Section for User whitelisting    */
    /*************************************/
    bool public whitelistingStatus;
    mapping (address => bool) public whitelisted;
    
    /**
     * Change whitelisting status on or off
     *
     * When whitelisting is true, then crowdsale will only accept investors who are whitelisted
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
        require(addressCount <= 150);
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
     * amount of tokens to be sold
     */
    function sellTokens(uint256 amount) public {
        uint256 etherAmount = amount * sellPrice/(10**decimals);
        require(address(this).balance >= etherAmount);   // checks if the contract has enough ether to buy
        _transfer(msg.sender, address(this), amount);           // makes the transfers
        msg.sender.transfer(etherAmount);                // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}