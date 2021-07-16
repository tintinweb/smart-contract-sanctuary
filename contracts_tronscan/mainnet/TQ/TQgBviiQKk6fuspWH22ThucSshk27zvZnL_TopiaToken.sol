//SourceUnit: token.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



████████╗██████╗  ██████╗ ███╗   ██╗    ████████╗ ██████╗ ██████╗ ██╗ █████╗ 
╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
   ██║   ██████╔╝██║   ██║██╔██╗ ██║       ██║   ██║   ██║██████╔╝██║███████║
   ██║   ██╔══██╗██║   ██║██║╚██╗██║       ██║   ██║   ██║██╔═══╝ ██║██╔══██║
   ██║   ██║  ██║╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝██║     ██║██║  ██║
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
                                                                             


=== 'Topia' Token contract with following features ===
    => TRC20 Compliance
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Burnable and minting (only by game players as they play the games)


======================= Quick Stats ===================
    => Name        : Topia
    => Symbol      : TOPIA
    => Total supply: 0 (Minted only by game players only)
    => Decimals    : 8


============= Independant Audit of the code ============
    => https://hacken.io
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority ( https://EtherAuthority.io )
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
    require(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
    }
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
            => claimOwnerTokens
            => distributeMainDividend
            => distributeLeaders1
            => distributeLeaders2
    */
    address internal signer;

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
        require(msg.sender == signer);
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
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//**************************************************************************//
//-------------------    DIVIDEND CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceDIVIDEND {
    function outstandingDivWithdrawFreeze(address user) external returns(bool);
    function outstandingDivWithdrawUnfreeze(address user) external returns(bool);
    function outstandingDivWithdrawUpgrade(address user) external returns(bool);  
} 
    

    
//****************************************************************************//
//---------------------    TOPIA MAIN CODE STARTS HERE   ---------------------//
//****************************************************************************//
    
contract TopiaToken is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string public constant name = "Topia";
    string public constant symbol = "TOPIA";
    uint256 public constant decimals = 8; 
    uint256 public totalSupply;
    uint256 public burnTracker;     //mainly used in mintToken function..
    uint256[] private mintingRates;
    address private mainContractAddress = address(this);
    address public dividendContractAddress;
    uint256 public withdrawnOwnerTokens;
    bool public tokenSwap;  //when tokenSwap will be on then all the token transfer to contract will trigger token swap
    bool public safeguardTokenMovement;  //putting safeguard on will halt all non-owner functions
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!
    uint256 public durationFreezeTier1 = 30 days;
    uint256 public durationFreezeTier2 = 60 days;
    
    uint256 public bronzeTopiaAllUsers; //this tracker will keep track of all the topia frozen in bronze tier
    uint256 public silverTopiaAllUsers; //this tracker will keep track of all the topia frozen in silver tier
    uint256 public goldTopiaAllUsers;   //this tracker will keep track of all the topia frozen in gold tier
    bool public freezeTierStatus = true;

    

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    mapping(address => uint256) public freezeTierTime;
    mapping(address => uint256) public frozenTopiaReleaseAmount;
    mapping(address => uint256) public frozenTopiaReleaseTime;
    
    mapping(address => uint256) public bronzeTopiaUser;
    mapping(address => uint256) public silverTopiaUser;
    mapping(address => uint256) public goldTopiaUser;
    
    


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenFunds(address indexed target, bool frozen);

    // This trackes approvals
    event Approval(address indexed owner, address indexed spender, uint256 value );

    // This is for token swap
    event TokenSwap(address indexed user, uint256 value);


    /*======================================
    =       STANDARD TRC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguardTokenMovement);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
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

        //code for token swap.
        if(tokenSwap && _to == address(this)){
            //fire tokenSwap event. This event can be listened by oracle and issue tokens of ethereum or another blockchain
            emit TokenSwap(msg.sender, _value);
        }
        
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
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    /**
        Constructor function
    */
    constructor() public {
        //It pre-mines exact topia of previous contract total supply
        uint256 preMint = 11783337326682;   //this amount was the total supply of the previous contract
        
        //assigning variables
        totalSupply = preMint;
        balanceOf[mainContractAddress] = preMint * 60 / 100;
        balanceOf[owner] = preMint * 40 / 100;

        //emit event
        emit Transfer(address(0), mainContractAddress, (preMint * 60 / 100) );
        emit Transfer(address(0), owner, (preMint * 40 / 100) );
        
    }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {

        require(!safeguardTokenMovement);
        
        //checking of enough token balance is done by SafeMath
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        burnTracker = burnTracker.add(_value);
        
        emit Transfer(msg.sender, address(0), _value);
        //althogh we can track all the "burn" from the Transfer function, we just kept it as it is. As that is no much harm
        emit Burn(msg.sender, _value);
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

        require(!safeguardTokenMovement);
        
        //checking of allowance and token value is done by SafeMath
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                   // Update totalSupply
        burnTracker = burnTracker.add(_value);
        
        emit Transfer(_from, address(0), _value);
        emit  Burn(_from, _value);
        return true;
    }
        
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner public returns (string) {

        frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
        return "Wallet updated successfully";

    }
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param _user Address to receive the tokens
        * @param _tronAmount the amount of tokens it will receive
        */
    function mintToken(address _user, uint256 _tronAmount)  public returns(bool) {

        //checking if the caller is whitelisted game contract
        require(whitelistCaller[msg.sender], 'Unauthorised caller');

        //globalHalt will affect this function, which ultimately revert the Roll functions in game contract
        require(!globalHalt, 'Global Halt is on');

        //this is to add wager amount in referrer mapping for the referrer tier consideration
        //if user does not have up-line referrer, then it will not do any process
        //if(referrers[_user] != address(0)) referralsWageredAllTime[referrers[_user]] += _tronAmount;

        // mintingRates index 0 means stage 1, index 1 means stage 2, and so on. 
        // stop minting after 100 million tokens
        // reason for mintTracker is that it will consider tokens which were burned and removed from totalSupply
        uint256 stage = (totalSupply + burnTracker).div(100000000000000); //divide total supply with 1 million tokens
        if( stage < 100){
        
        //tokens to mint = input TRX amount / 833 * exchange rate
        uint256 tokenTotal = _tronAmount.mul(mintingRates[stage]).div(833).div(1000000); //1 million is the number to divide exchange rate to get the true exchange rate    
        
        balanceOf[_user] = balanceOf[_user].add(tokenTotal * 60 / 100);                   // 60% goes to player
        
        /* 40% of those goes to owner. That got distributed as per below logic (thanks to @eggy-eth for logic idea):
            (1) Calculate the actual token supply (totalSupply + burnTracker)
            (2) 40% of this goes to owner. 
            (3) Create a storage slot which stores "withdrawnOwnerTokens". 
            (4) Subtract this amount from the 40% and transfer this amount to owner if he calls this special function. 
            (5) The transferred amount gets added to this withdrawnOwnerTokens slot so owner cannot withdraw twice.
        */
        
        totalSupply = totalSupply.add(tokenTotal);
        //emitting Transfer event
        emit Transfer(address(0),_user,tokenTotal * 60 / 100);
        }
    return true;
    }

    /**
        Owner can claim their un-claimed tokens
    */
    function claimOwnerTokens() public onlySigner returns (string){

        // If people burn their tokens, then totalSupply goes down. But burnTracker will allow owner to calculate total share for owner
        uint256 actualTotalSupply = totalSupply + burnTracker;

        // 40% of entire token minting should be paid to owner
        uint256 ownerTotalShare = actualTotalSupply * 40 / 100;

        if( ownerTotalShare > withdrawnOwnerTokens){
            uint256 tokens = ownerTotalShare - withdrawnOwnerTokens;
            withdrawnOwnerTokens += tokens;
            balanceOf[owner] = balanceOf[owner].add(tokens); 
            emit Transfer(address(0), owner, tokens);
            return "Tokens claimed";
        }
        return "Nothing to claim";
    }

    /**
        This function displays total tokens owner can claim
    */
    function displayTokensToClaim() public view returns(uint256){
        // If people burn their tokens, then totalSupply goes down. But burnTracker will allow owner to calculate total share for owner
        uint256 actualTotalSupply = totalSupply + burnTracker;

        // 40% of entire token minting should be paid to owner
        uint256 ownerTotalShare = actualTotalSupply * 40 / 100;

         if( ownerTotalShare > withdrawnOwnerTokens){
             return ownerTotalShare - withdrawnOwnerTokens;
         }
    }


    function updateDividendContract(address _newAddress) public onlyOwner returns(string){
        //we dont want to check input address against 0x0 as owner might decided to use address 0x0 to halt operation
        dividendContractAddress = _newAddress;
        return "Dividend contract address updated";
    }


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistGameAddress(address _newAddress) public onlyOwner returns(string){
        
        require(isContract(_newAddress), 'Only Contract Address can be whitelisted');
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        return "Whitelisting Address added";
    }

    /**
        * To remove any whilisted address
    */
    function removeWhitelistGameAddress(address _address) public onlyOwner returns(string){
        
        require(_address != address(0), 'Invalid Address');
        require(whitelistCaller[_address], 'This Address does not exist');

        whitelistCaller[_address] = false;
        uint256 arrayIndex = whitelistCallerArrayIndex[_address];
        address lastElement = whitelistCallerArray[whitelistCallerArray.length - 1];
        whitelistCallerArray[arrayIndex] = lastElement;
        whitelistCallerArrayIndex[lastElement] = arrayIndex;
        whitelistCallerArray.length--;

        return "Whitelisting Address removed";
    }

    /**
        * Function to check if given address is contract address or not.
        * We are aware that this function will not work if calls made from constructor.
        * But we believe that is fine in our use case because the function using this function is called by owner only..
    */
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
        
    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
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
    function changeGlobalHalt() onlySigner public returns(string) {
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


    /* FOLLOWING AMOUNT NEED TO DIVIDED BY 100000000 (1e8) TO GET THE ACTUAL RATE OF TOKEN FOR 1 TRX

[
166666667,
138833333,
136111111,
133493590,
130974843,
128549383,
126212121,
123958333,
121783626,
119683908,
117655367,
115694444,
113797814,
111962366,
110185185,
108463542,
106794872,
105176768,
103606965,
102083333,
100603865,
99166667,
97769953,
96412037,
95091324,
93806306,
92555556,
91337719,
90151515,
88995726,
87869198,
86770833,
85699588,
84654472,
83634538,
82638889,
81666667,
80717054,
79789272,
78882576,
77996255,
77129630,
76282051,
75452899,
74641577,
73847518,
73070175,
72309028,
71563574,
70833333,
70117845,
69416667,
68729373,
68055556,
67394822,
66746795,
66111111,
65487421,
64875389,
64274691,
63685015,
63106061,
62537538,
61979167,
61430678,
60891813,
60362319,
59841954,
59330484,
58827684,
58333333,
57847222,
57369146,
56898907,
56436314,
55981183,
55533333,
55092593,
54658793,
54231771,
53811370,
53397436,
52989822,
52588384,
52192982,
51803483,
51419753,
51041667,
50669100,
50301932,
49940048,
49583333,
49231678,
48884977,
48543124,
48206019,
47873563,
47545662,
47222222,
46903153
]

    */
    function updateMintingRates(uint256[] ratesArray) public onlyOwner returns(string) {
        require(ratesArray.length <= 110, 'Array too large');
        mintingRates = ratesArray;
        return "Minting Rates Updated";
    }

    

    /**
        * Function to check TRX balance in this contract
    */
    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }


    

    


    


    /**
        Function to freeze the topia
    */
    function freezeTopia(uint256 _value) public returns(bool){

        address callingUser = msg.sender;

        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        //we want this current call to complete if we return true from outstandingDivWithdrawFreeze, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawFreeze(callingUser), 'Outstanding div withdraw failed');
        

        //to freeze topia, we just take topia from his account and transfer to contract address, 
        //and track that with frozenTopia mapping variable
        _transfer(callingUser, address(this), _value);

        
        /** FREEZE TIERS LOGIC
        case 1: user freeze the tokens for very first time, then it will set the time from that point forward
        case 2: when user did not unfreeze and keep freezing subsequently, then it will not do anything
        case 3: when user freeze tokens after unfreezing, then it will start timer from that point forward again. 
                Because unfreeze will set the timer to zero.
        */
        if(freezeTierTime[callingUser] == 0){
            
            //this value can be zero when either user freezing for very first time, or freezing right after unfreeze!
            //so we will update thier bronzeTopiaAllUsers
            bronzeTopiaAllUsers += _value;
            bronzeTopiaUser[callingUser] = _value;

            //since this is initial freeze, so freezeTierTime is being set
            //this will be only set if freezeTierTime is zero
            freezeTierTime[callingUser] = now;
        }
        else if(freezeTierTime[callingUser] <= now){
            //this condition run when user freezes subsequently

            //fist we will determine his current tier
            uint256 freezeDuration = now - freezeTierTime[callingUser];
            uint256 bronzeTopia = bronzeTopiaUser[callingUser];

            //this is silver tier (or tier 1)
            if(freezeDuration >= durationFreezeTier1 && freezeDuration < durationFreezeTier2){
                //first we will check if user have any frozen topia in bronze level. 
                //if so then we will upgrade to silver. 
                if(bronzeTopia > 0){
                    //this will only run when user is first transitioned from bronze to silver
                    //we will first add that into silver trackers
                    silverTopiaAllUsers += bronzeTopia + _value;
                    silverTopiaUser[callingUser] = bronzeTopia + _value;

                    //we will then remove that from bronze trackers
                    bronzeTopiaAllUsers = bronzeTopiaAllUsers.sub(bronzeTopia);
                    bronzeTopiaUser[callingUser] = 0;
  
                }
                else{
                    //this is subsquent freeze while user in silver level
                    silverTopiaAllUsers +=  _value;
                    silverTopiaUser[callingUser] += _value;
                }

            }

            //this is gold tier (or tier 2)
            else if( freezeDuration >= durationFreezeTier2 ){
                
                uint256 silverTopia = silverTopiaUser[callingUser];
                //following condition will be for first transition from either bronze or silver To Gold.
                if(silverTopia > 0 || bronzeTopia > 0){
                    //this will only run when user is first transitioned from bronze or silver to Gold
                    //we will first add that into gold trackers
                    goldTopiaAllUsers += bronzeTopia + silverTopia + _value;
                    goldTopiaUser[callingUser] = bronzeTopia + silverTopia + _value;

                    //we will then remove that from bronze - silver trackers
                    if(silverTopia > 0){
                        silverTopiaAllUsers = silverTopiaAllUsers.sub(silverTopia);
                        silverTopiaUser[callingUser] = 0;
                    }
                    if(bronzeTopia > 0){
                        bronzeTopiaAllUsers = bronzeTopiaAllUsers.sub(bronzeTopia);
                        bronzeTopiaUser[callingUser] = 0;
                    }
                }
                else{
                    //this is subsquent freeze while user in gold level
                    goldTopiaAllUsers +=  _value;
                    goldTopiaUser[callingUser] += _value;
                }

            }
            else{
                //this is bronze tier (or tier 0) - default
                bronzeTopiaAllUsers += _value;
                bronzeTopiaUser[callingUser] += _value;
            }

        }

        
        return true;
    }

    /**
        Function to unfreeze the topia
    */
    function unfreezeTopia() public returns(bool){

        address callingUser = msg.sender;

        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawUnfreeze(callingUser), 'Outstanding div withdraw failed');
        

        //_value would be any one of three tiers. 
        uint256 _value; 
        if(bronzeTopiaUser[callingUser] > 0){
            
            _value = bronzeTopiaUser[callingUser];

            bronzeTopiaAllUsers = bronzeTopiaAllUsers.sub(_value);
            bronzeTopiaUser[callingUser] = 0;
        }
        else if(silverTopiaUser[callingUser] > 0){

            _value = silverTopiaUser[callingUser];

            silverTopiaAllUsers = silverTopiaAllUsers.sub(_value);
            silverTopiaUser[callingUser] = 0;
        }
        else {

            _value = goldTopiaUser[callingUser];
            
            goldTopiaAllUsers = goldTopiaAllUsers.sub(_value);
            goldTopiaUser[callingUser] = 0;
        }

        require(_value > 0 , 'Insufficient Frozen Tokens');

        frozenTopiaReleaseAmount[callingUser] += _value;
        frozenTopiaReleaseTime[callingUser] = now + 86400;

        //Unfreeze will reset the freezeTier timer to zero. so from next freeze will have timer starting from that point forward.
        freezeTierTime[callingUser] = 0;


        return true;

    }

     /**
        Function displays display Available to Withdraw TOPIA for any user
    */
    function displayAvailabletoWithdrawTOPIA() public view returns(uint256){
        if(frozenTopiaReleaseTime[msg.sender] < now){
            return frozenTopiaReleaseAmount[msg.sender];
        }
        else{
            return 0;
        }
    }

    /**
        This function will withdraw all the available topia after unfreeze
        This function can be called directly by user or can be called from dividend contract.
    */
    function withdrawUnfrozenTopia() public returns(bool){
        address user = tx.origin;   //we will consider original call maker, even through other contracts
        uint256 tokenAmount = frozenTopiaReleaseAmount[user];
        //The condition, 'frozenTopiaReleaseTime[user] < now' seems failing, as 'now' is keep increasing. 
        //but every unfreeze attempt will increase that time, so this condition will work in all cases!
        if(tokenAmount > 0 && frozenTopiaReleaseTime[user] < now){
            frozenTopiaReleaseAmount[user] = 0;
            _transfer(address(this), user, tokenAmount);
            return true;
        }

    }


    /**
        Function to find Freeze Tier Percentage
    */
    function findFreezeTierPercentage() public view returns(uint256){

        //if this freeze tiers were disabled then it will just return 100 percentage
        if(!freezeTierStatus) return 100;

        uint256 userFreezeTime = freezeTierTime[msg.sender];
        //userFreezeTime variable has only one of two values. Either past of 'now' or zero
        if(userFreezeTime > 0){
            uint256 freezeDuration = now - userFreezeTime;
            if(freezeDuration >= durationFreezeTier1 && freezeDuration < durationFreezeTier2 ){
                return 85;      //tier 1 => 85% of users div share => unfreeze in 30 days
            }
            else if( freezeDuration >= durationFreezeTier2 ){
                return 100;     //tier 2 => 100% of users div share => unfreeze in more than 60 days
            }
        }

        return 75;              //tier 0 => 75% of the users div share => default

    }

    /**
        Function to change Freeze Tier Duration
    */
    function changeFreezeTiersDuration(uint256 tier1, uint256 tier2) public onlyOwner returns(string){
        
        durationFreezeTier1 = tier1;
        durationFreezeTier2 = tier2;
        
        return "Freeze Tier Duration Updated Successfully";
    }

    /**
        Function called by users to upgrade thier topia freeze level
    */
    function upgradeTopia() public returns(string){

        address callingUser = msg.sender;

        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        //we want this current call to complete if we return true from outstandingDivWithdrawUpgrade, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawUpgrade(callingUser), 'Outstanding div withdraw failed');
        

        uint256 freezeDuration = now - freezeTierTime[callingUser];
        
        //Initial freeze must be minimum 30 days, as well as user must not be already gold.
        require(freezeTierTime[callingUser] > 0 && freezeDuration >= durationFreezeTier1, 'Invalid Freeze Time' );

        //Checking if user to upgrade from bronze to silver
        uint256 bronzeTopia = bronzeTopiaUser[callingUser];
        uint256 silverTopia = silverTopiaUser[callingUser];
        if( bronzeTopia > 0 && freezeDuration < durationFreezeTier2 ){
            //we will first add that into silver trackers
            silverTopiaAllUsers += bronzeTopia;
            silverTopiaUser[callingUser] = bronzeTopia;

            //we will then remove that from bronze trackers
            bronzeTopiaAllUsers = bronzeTopiaAllUsers.sub(bronzeTopia);
            bronzeTopiaUser[callingUser] = 0;

            return "User account upgraded from Bronze to Silver";
        }

        //in case where user have longer duration than gold threshold, but he is still in bronze.
        //in that case, upgrade user from bronze to gold
        else if( bronzeTopia > 0 && freezeDuration >= durationFreezeTier2 ){
            //we will first add that into gold trackers
            goldTopiaAllUsers += bronzeTopia;
            goldTopiaUser[callingUser] = bronzeTopia;

            //we will then remove that from bronze trackers
            bronzeTopiaAllUsers = bronzeTopiaAllUsers.sub(bronzeTopia);
            bronzeTopiaUser[callingUser] = 0;

            return "User account upgraded from Bronze to Gold";
        }

        //silver to gold transition. we dont want to put this in 'else' breakets, but we specifically want to specify its condition!
        else if( silverTopia > 0 && freezeDuration >= durationFreezeTier2 ){
            //we will first add that into gold trackers
            goldTopiaAllUsers += silverTopia;
            goldTopiaUser[callingUser] = silverTopia;

            //we will then remove that from bronze trackers
            silverTopiaAllUsers = silverTopiaAllUsers.sub(silverTopia);
            silverTopiaUser[msg.sender] = 0;

            return "User account upgraded from Silver to Gold";
        }
    }

    

    /**
        Function returns all topia frozen in bronze, silver and gold tiers of given user
    */
    function frozenTopia(address _user) public view returns(uint256){
        return bronzeTopiaUser[_user] + silverTopiaUser[msg.sender] + goldTopiaUser[msg.sender];
    }


    /**
        Function will output entire topia frozen accross the contract - ENTIRELY
    */
    function frozenTopiaGlobal() public view returns(uint256){
        return bronzeTopiaAllUsers + silverTopiaAllUsers + goldTopiaAllUsers;
    }

    /**
        Function will output entire topia frozen accross the contract - ENTIRELY
    */
    function totalFrozenTopiaIndividual() public view returns(uint256,uint256,uint256){
        return (bronzeTopiaAllUsers, silverTopiaAllUsers, goldTopiaAllUsers);
    }

    /**
        This function returns users current freeze level as well as freeze amount
        0 = Bronze
        1 = silver
        2 = gold
    */
    function userFreezeTierAndAmount(address user) public view returns(uint256, uint256){
        //user can only have one level at  time
        if(silverTopiaUser[user] > 0){
            return (1, silverTopiaUser[user] );
        }
        else if(goldTopiaUser[user] > 0){
            return (2, goldTopiaUser[user] );
        }
        else{
            return (0, bronzeTopiaUser[user]);
        }
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
    function airdrop(address[] recipients, uint[] tokenAmount) public onlyOwner {
        uint256 addressCount = recipients.length;
        require(addressCount <= 150);
        for(uint i = 0; i < addressCount; i++)
        {
                //This will loop through all the recipients and send them the specified tokens
                _transfer(this, recipients[i], tokenAmount[i]);
        }
    }


}