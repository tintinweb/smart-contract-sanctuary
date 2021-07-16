//SourceUnit: shares.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_ 




████████╗ ██████╗ ██████╗ ██╗ █████╗     ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
   ██║   ██║   ██║██████╔╝██║███████║    ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
   ██║   ██║   ██║██╔═══╝ ██║██╔══██║    ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
   ██║   ╚██████╔╝██║     ██║██║  ██║    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
                                                                                                       


=== 'Shares' contract with following features ===
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => freeze shares for dividends payments in TRX as well as TRC20 and TRC10 tokens
    => unfreeze anytime.. no unfreeze cooldown time
    

======================= Quick Stats ===================
    => Name        : Topia Share
    => Symbol      : TSHARE
    => Max supply  : 1,000,000,000 (1 Billion)
    => Decimals    : 6


============= Independant Audit of the code ============
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2019 onwards Topia Network Inc. ( https://topia.network )
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




//**************************************************************************//
//-------------------    DIVIDEND CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceSharesDividend {
    function withdrawDividendsEverything() external returns(bool);
    function outstandingDivWithdrawUnFreeze() external returns(bool);
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address internal owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.
        Signer calls following four functions:
            => request fund from game contract
    */
    address internal signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'caller must be owner');
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

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner, 'caller must be new owner');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

    

    
//****************************************************************************//
//---------------------    SHARES MAIN CODE STARTS HERE  ---------------------//
//****************************************************************************//
    
contract TopiaShares is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string public constant name = "Topia Share";
    string public constant symbol = "TSHARE";
    uint256 public constant decimals = 6; 
    uint256 public constant maxSupply = 1000000000 * (10**decimals);    //1 Billion max supply
    uint256 public totalSupply;
    
    address public voucherContractAddress;
    address public topiaContractAddress;
    address public sharesDividendContract;
    bool public safeguardTokenMovement;  //putting safeguard on will halt all non-owner functions
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!
    uint256 public totalMintedLifetime;
    uint256 public frozenSharesGlobal;
    

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public usersShareFrozen;
    
      

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    // This trackes approvals
    event Approval(address indexed owner, address indexed spender, uint256 value );
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address indexed target, bool frozen);
    
   

    /*======================================
    =       STANDARD TRC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguardTokenMovement);
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
        
        //require(_value <= allowance[_from][msg.sender]);     // no need for this condition as it is already checked by SafeMath below
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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

        require(!safeguardTokenMovement);
        require(balanceOf[msg.sender] >= _value, 'Not enough balance');
        
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }




    /*=====================================
    =       CUSTOM SHARES FUNCTIONS       =
    ======================================*/

    /**
        Constructor function. nothing happens
    */
    constructor() public {}

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    function mintShares (address user, uint256 shareMint)  public returns(bool) {
        
        //if total supply become more than max supply, then it will just return.
        //so function calling this function in voucher contract will work without minting anymore shares. 
        if( totalSupply > maxSupply){ return true; }

        //checking if the caller is whitelisted voucher contract
        require(msg.sender==voucherContractAddress || msg.sender==owner, 'Unauthorised caller');

        //globalHalt will affect this function, which ultimately revert the Roll functions in game contract
        require(!globalHalt, 'Global Halt is on');

        totalMintedLifetime += shareMint;
        
        balanceOf[user] = balanceOf[user].add(shareMint);      
        totalSupply = totalSupply.add(shareMint);
        
        //emitting Transfer event
        emit Transfer(address(0),user,shareMint);
        
        return true;
    }
    

     /**
        Function to freeze the shares
    */
    function freezeShares(uint256 _value) public returns(bool){

        //we want this tx.origin because user can call this directly or via any other contracts
        address callingUser = tx.origin;

        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        //we want this current call to complete if we return true from withdrawDividendsEverything, otherwise revert.
        require(InterfaceSharesDividend(sharesDividendContract).withdrawDividendsEverything(), 'Outstanding div withdraw failed');
        

        //to freeze topia, we just take topia from his account and transfer to contract address, 
        //and track that with frozenTopia mapping variable
        _transfer(callingUser, address(this), _value);

        //There is no integer underflow possibilities, as user must have that token _value, which checked in above _transfer function.
        frozenSharesGlobal += _value;
        usersShareFrozen[callingUser] += _value;
        
        
        return true;
    }

    function unfreezeShares() public returns(bool){

        //we want this tx.origin because user can call this directly or via any other contracts
        address callingUser = tx.origin;

        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS, ALL TOKENS AND TRX
        //It will not update dividend tracker, just withdraw them. when user will freeze shares again, then automatically those trackers will be updated
        require(InterfaceSharesDividend(sharesDividendContract).outstandingDivWithdrawUnFreeze(), 'Outstanding div withdraw failed');
        
 
        uint256 _value = usersShareFrozen[callingUser];

        require(_value > 0 , 'Insufficient Frozen Tokens');
        
        //update variables
        usersShareFrozen[callingUser] = 0; 
        frozenSharesGlobal -= _value;

        _transfer(address(this), callingUser, _value);

        return true;

    }
    


    /*=====================================
    =          HELPER FUNCTIONS           =
    ======================================*/


    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner public returns (string) {

        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
        return "Wallet updated successfully";

    }
    
    
    function updateContractAddresses(address voucherContract, address topiaContract, address sharesDividend) public onlyOwner returns(string){
        voucherContractAddress = voucherContract;
        topiaContractAddress = topiaContract;
        sharesDividendContract = sharesDividend;
        return "voucher, topia, share dividend conracts updated successfully";
    }

   
        
    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawShares(uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }



    function manualWithdrawTRC10Tokens(uint256 tokenID, uint256 tokenAmount) public onlyOwner returns(string){
        owner.transferToken(tokenAmount, tokenID);
        return "Tokens withdrawn to owner wallet";
    }


    function manualWithdrawTRX(uint256 amount) public onlyOwner returns(string){
        owner.transfer(amount);
        return "TRX withdrawn to owner wallet";
    }

    
    
  
    /**
        * Change safeguardTokenMovement status on or off
        *
        * When safeguardTokenMovement is true, then all the non-owner functions will stop working.
        * When safeguardTokenMovement is false, then all the functions will resume working back again!
        */
    function changeSafeguardTokenMovement() onlyOwner public returns(string) {
        if (safeguardTokenMovement == false){
            safeguardTokenMovement = true;
        }
        else{
            safeguardTokenMovement = false;    
        }
        return "safeguardTokenMovement status changed";
    }


    /**
        * If global halt is off, then this funtion will on it. And vice versa
        * This also change safeguard for token movement status
    */
    function changeGlobalHalt() onlyOwner public returns(string) {
        if (globalHalt == false){
            globalHalt = true;
            safeguardTokenMovement = true;
        }
        else{
            globalHalt = false;  
            safeguardTokenMovement = false;  
        }
        return "globalHalt status changed";
    }

    

    /**
        * Function to check TRX balance in this contract
    */
    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }
    
    
    
    /*********************************/
    /*    Code for the Air drop      */
    /*********************************/
    
    /**
        * Run an Air-Drop
        *
        * It requires an array of all the addresses and amount of tokens to distribute
        * It will only process first 150 recipients. That limit is fixed to prevent gas limit
        */
    function airdrop(address[] recipients, uint[] tokenAmount) public onlySigner returns(string, uint256, address) {
        uint256 addressCount = recipients.length;
        require(addressCount == tokenAmount.length, 'both arrays must have equal length');
        for(uint i = 0; i < addressCount; i++)
        {
        
        if (gasleft() < 100000)
            {
                break;
            }
            
                //This will loop through all the recipients and send them the specified tokens
                _transfer(this, recipients[i], tokenAmount[i]);
        }

        return ("successful entries processed upto: ", i, recipients[i]);
    }





}