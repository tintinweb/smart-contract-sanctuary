/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

/* 
 * 
 *                                                                           
 *                      ;'+:                                                                         
 *                       ''''''`                                                                     
 *                        ''''''';                                                                   
 *                         ''''''''+.                                                                
 *                          +''''''''',                                                              
 *                           '''''''''+'.                                                            
 *                            ''''''''''''                                                           
 *                             '''''''''''''                                                         
 *                             ,'''''''''''''.                                                       
 *                              '''''''''''''''                                                      
 *                               '''''''''''''''                                                     
 *                               :'''''''''''''''.                                                   
 *                                '''''''''''''''';                                                  
 *                                .'''''''''''''''''                                                 
 *                                 ''''''''''''''''''                                                
 *                                 ;''''''''''''''''''                                               
 *                                  '''''''''''''''''+'                                              
 *                                  ''''''''''''''''''''                                             
 *                                  '''''''''''''''''''',                                            
 *                                  ,''''''''''''''''''''                                            
 *                                   '''''''''''''''''''''                                           
 *                                   ''''''''''''''''''''':                                          
 *                                   ''''''''''''''''''''+'                                          
 *                                   `''''''''''''''''''''':                                         
 *                                    ''''''''''''''''''''''                                         
 *                                    .''''''''''''''''''''';                                        
 *                                    ''''''''''''''''''''''`                                       
 *                                     ''''''''''''''''''''''                                       
 *                                       ''''''''''''''''''''''                                      
 *                  :                     ''''''''''''''''''''''                                     
 *                  ,:                     ''''''''''''''''''''''                                    
 *                  :::.                    ''+''''''''''''''''''':                                  
 *                  ,:,,:`        .:::::::,. :''''''''''''''''''''''.                                
 *                   ,,,::::,.,::::::::,:::,::,''''''''''''''''''''''';                              
 *                   :::::::,::,::::::::,,,''''''''''''''''''''''''''''''`                           
 *                    :::::::::,::::::::;'''''''''''''''''''''''''''''''''+`                         
 *                    ,:,::::::::::::,;''''''''''''''''''''''''''''''''''''';                        
 *                     :,,:::::::::::'''''''''''''''''''''''''''''''''''''''''                       
 *                      ::::::::::,''''''''''''''''''''''''''''''''''''''''''''                      
 *                       :,,:,:,:''''''''''''''''''''''''''''''''''''''''''''''`                     
 *                        .;::;'''''''''''''''''''''''''''''''''''''''''''''''''                     
 *                            :'+'''''''''''''''''''''''''''''''''''''''''''''''                     
 *                                  ``.::;'''''''''''''';;:::,..`````,'''''''''',                    
 *                                                                       ''''''';                    
 *                                                                         ''''''                    
 *                           .''''''';       '''''''''''''       ''''''''   '''''                    
 *                          '''''''''''`     '''''''''''''     ;'''''''''';  ''';                    
 *                         '''       '''`    ''               ''',      ,'''  '':                    
 *                        '''         :      ''              `''          ''` :'`                    
 *                        ''                 ''              '':          :''  '                     
 *                        ''                 ''''''''''      ''            ''  '                     
 *                       `''     '''''''''   ''''''''''      ''            ''                        
 *                        ''     '''''''':   ''              ''            ''                        
 *                        ''           ''    ''              '''          '''                        
 *                        '''         '''    ''               '''        '''                         
 *                         '''.     .'''     ''                '''.    .'''                         
 *                          `''''''''''      '''''''''''''`    `''''''''''                          
 *                            '''''''        '''''''''''''`      .''''''.                            
 *                                                                                                    
*/

pragma solidity 0.8.4;

// ----------------------------------------------------------------------------------------------------------
// 'Parity Dollar A fully dencetralized and autonomous parity coin for USD liquidity and Merchant adaptation'
//
// Type        : Ethereum ERC20 Standard
// Symbol      : XDL
// Name        : Parity Dollar
// Total supply: Starting from zero. and minted as specified stable coins comes in, making 1:1 ratio
// Decimals    : 4
// Website     : https://paritydollar.xyz 
// SPDX-License-Identifier: Affero GPLv3 Licence. | https://ibbt.io
// (c) by A. Valamontes with Blockchain Ventures / iBlockchain Bank & Trust Tecnhnologies Co. 2020-2021. 
// ------------------------------------------------------------------------------------------------------------
//
//
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
//--------------------- ERC20 Token Interface -----------------------//
//*******************************************************************//

interface IERC20 {
    function decimals() external view returns(uint256);
    function transfer(address user, uint256 amount) external returns(bool);
    function transferFrom(address sender, address receiver, uint256 amount) external returns(bool);
}

//*******************************************************************//
//---------- Contract to Manage Parity Dollar Ownership ------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(0);
    }
}
 
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract ParityDollar is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "Parity Blockchain Dollar";
    string constant private _symbol = "XDL";
    uint256 constant private _decimals = 4;
    uint256 private _totalSupply = 0;         //as a stable coin, supply starts with 0 and will be minted as new fund comes in
    bool public safeguard;                    //putting safeguard on will halt all non-owner functions

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value, string  DARSA_UAC, string  DARSA_UTC);
    
    // This notifies clients about the amount minted
    event Mint(address indexed from, uint256 value, string  DARSA_UAC, string  DARSA_UTC);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    /**
     * Returns name of token 
     */
    function name() external pure returns(string memory){
        return _name;
    }
    
    /**
     * Returns symbol of token 
     */
    function symbol() external pure returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() external pure returns(uint256){
        return _decimals;
    }
    
    /**
     * Returns totalSupply of token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) external view returns(uint256){
        return _balanceOf[user];
    }
    
    /**
     * Returns allowance of token 
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    /**
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard);
        require (_to != address(0));                        // Prevent transfer to 0x0 address. Use burn() instead
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
    function transfer(address _to, uint256 _value) external returns (bool success) {
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
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
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
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(!safeguard);
        /* set an allowance of exactly the amount needed for transaction. This can avoid any future issues with the unlimited option on allowance
         *  Read article on Why Unlimited Allowance is Harmful - https://kalis.me/unlimited-erc20-allowances/
         *
         * AUDITOR NOTE:
         *
         * Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
         * On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
         * So following condition is kept in commented. It can be be kept that way or not based on client's consent.
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
    function increase_allowance(address spender, uint256 value) external returns (bool) {
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
    function decrease_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    mapping(address => bool) public StablecoinUnderCustody;
    uint256 public maxTransactionAmount = 10000 * (10**_decimals);    //maximun tokens can be issued/destroyed in one transaction.
    string public DARSA_UAC;
    string public DARSA_UTC;
    
    constructor(string memory darsa_uac, string memory darsa_utc) {
        DARSA_UAC = darsa_uac;
        DARSA_UTC = darsa_utc;
    }
    
    receive () external payable {  }

    /**
     * @dev generate new tokens and issue to users.
     * User has to provide payment token wallet, which would be deducted as 1:1 ratio
     * User has to approve this smart contract as spender before doing this transaction
     */
    function issueParityDollar(address StablecoinAddress, uint256 AmountOfParityDollars)  external returns(string memory) {
        
        //assign local variables
        address msgSender = msg.sender;
        
        //checking conditions
        require(!safeguard, 'Safeguard was Activated');
        require(AmountOfParityDollars <= maxTransactionAmount, 'max Transaction Amount');
		require(StablecoinUnderCustody[StablecoinAddress], 'Invalid Stablecoin Address');
        
        //first deduct the payment tokens. User has to approve this smart contract as spender to be able to do this.
        uint256 StablecoinDecimals = IERC20(StablecoinAddress).decimals();
        uint256 StablecoinAmount = AmountOfParityDollars * (10**StablecoinDecimals) / (10**_decimals);
        IERC20(StablecoinAddress).transferFrom(msgSender, address(this), StablecoinAmount);
        
        //issue DBC tokens
        _balanceOf[msgSender] = _balanceOf[msgSender].add(AmountOfParityDollars);
        _totalSupply = _totalSupply.add(AmountOfParityDollars);
        emit Transfer(address(0), msgSender, AmountOfParityDollars);
        emit Mint(msgSender, AmountOfParityDollars, DARSA_UAC, DARSA_UTC);
        
        return "Parity Dollar minted successfully";
    }
    
    /**
     * @dev destroy DBC tokens
     * This will swap other stable coins as 1:1 ratio
     * user need to put DBC token amount in 4 decimals
     * If this smart contract does not have enought receiving tokens, then user must change to the one available.
     */
    function destroyParityDollar(address StablecoinAddress, uint256 AmountOfParityDollars) external returns (string memory) {
        
        //assign local variables
        address msgSender = msg.sender;
        
        //checking conditions
        require(!safeguard, 'Safeguard was Activated');
        require(AmountOfParityDollars <= maxTransactionAmount, 'max Transaction Amount');
		require(StablecoinUnderCustody[StablecoinAddress], 'Invalid Stablecoin Address');
        
        //now destroy DBC tokens
        _balanceOf[msgSender] = _balanceOf[msgSender].sub(AmountOfParityDollars);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(AmountOfParityDollars);                      // Updates totalSupply
        emit Burn(msgSender, AmountOfParityDollars, DARSA_UAC, DARSA_UTC);
        emit Transfer(msgSender, address(0), AmountOfParityDollars);
        
        //send receiving tokens
        uint256 receivingStablecoinDecimals = IERC20(StablecoinAddress).decimals();
        uint256 receivingStablecoinAmount = AmountOfParityDollars * (10**receivingStablecoinDecimals) / (10**_decimals);
        IERC20(StablecoinAddress).transfer(msgSender, receivingStablecoinAmount);
        
        return "Parity Dollar Supply was destroyed successfully; Specified Balance as exchanged with Stablecoin  ";
    }
    
    
    /**
     * @dev owner can add stable coin contract address which can be used as custodial to receive DBC coins
     * These must be USD stable coins having the same value and their price must not fluctuate too much.
     * Owner only can add tokens and can not remove it. This is to increase trust as owner also can not remove any custodian tokens.
     * Owner must add ONLY reputable stable coins, and not any other tokens whose value can go down.. otherwise users will swap that low value tokens with other high value stable coins. 
     */
    function addCustodialStablecoin(address StablecoinContract) external onlyOwner returns(string memory){
        StablecoinUnderCustody[StablecoinContract] = true;
        return "Stablecoin contract was added to Custody Pool Successfully";
    }
    
    /**
     * @dev owner can change max transaction amount.
     */
    function changeMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner returns(string memory){
        require(_maxTransactionAmount != 0, "Transaction Amount can not be zero");
        maxTransactionAmount = _maxTransactionAmount;
        return "Max. Transaction Amount updated successfully";
    }
    
    /**
     * @dev owner can set DARSA UAC an UTC
     * ABOUT DARSA
     *
     * DARSA is a neutral, not-for-profit, global organization that develops and maintains the most widely-used digital assets and registry 
     * standards system in the world. DARSA Standards improve the efficiency, safety, and visibility of digital assets placed across the Blockchain(s). 
     * DARSA’s aim is to engage with communities of trading partners, industry organizations, governments, and technology providers to understand and 
     * respond to their business needs through the adoption and implementation of global standards.
     *
     * ABOUT DARSA North America (NA)
     *
     * DARSA NA, a member of DARSA Global, is a not-for-profit digital assets registry and standards organization that facilitates 
     * industry collaboration to improve supply chain visibility and efficiency through the use of DARSA Standards.
     *
     * To learn more visit https://darsa.org
     */

    function updateDarsa(string memory darsa_uac, string memory darsa_utc) external onlyOwner returns(string memory){
        
        DARSA_UAC = darsa_uac;
        DARSA_UTC = darsa_utc;
        
        return "DARSA UAC and UTC updated successfully";
    }

    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }

    /**
     * Just in rare case, owner wants to transfer Ether from contract to owner address
     * Incomeing ether is not expected.. and hence this function does not do any harm to tokenomics
     */
    function manualWithdrawEther()onlyOwner external{
        payable(owner).transfer(address(this).balance);
    }
    
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyOwner external{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }

}