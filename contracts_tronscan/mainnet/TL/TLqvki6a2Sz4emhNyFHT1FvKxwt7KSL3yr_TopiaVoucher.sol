//SourceUnit: voucher.sol

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
                                                                             


=== 'Voucher' contract with following features ===
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Burnable and minting 
    

======================= Quick Stats ===================
    => Name        : Topia Voucher
    => Symbol      : TVS
    => Max supply  : Unlimited (Minted only by game players only)
    => Decimals    : 6


============= Independant Audit of the code ============
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
//---------------------    GAMES CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceGAMES {
    function getAvailableVoucherRake() external returns (uint256);
    function requestVoucherRakePayment() external returns(bool);
} 

//**************************************************************************//
//---------------------    SHARES CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceSHARES {
    function mintShares (address user, uint256 shareMint)  external returns(bool);
}  

//**************************************************************************//
//----------------    DIAMOND VOUCHER CONTRACT INTERFACE    ----------------//
//**************************************************************************//

interface InterfaceDIAMONDS {
    function mintDiamonds (address user, uint256 diamondAmount)  external returns(bool);
} 


//**************************************************************************//
//------------------    TOPIA VAULT CONTRACT INTERFACE    ------------------//
//**************************************************************************//

interface InterfaceTOPIAVAULT {
    function incrementClock (uint256 voucherBurnAmount)  external returns(bool);
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

    

    
//****************************************************************************//
//---------------------   VOUCHER MAIN CODE STARTS HERE  ---------------------//
//****************************************************************************//
    
contract TopiaVoucher is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string public constant name = "Topia Voucher";
    string public constant symbol = "TVS";
    uint256 public constant decimals = 6; 
    uint256 public totalSupply;
    bool public safeguardTokenMovement;  //putting safeguard on will halt all non-owner functions
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!
    uint256 public totalMintedLifetime;
    uint256 public vouchersBurnedAllTime;
    uint256 public vouchersBurnedCurrentPeriod; //this holds total vouchers burned for current div distribution period. It emptied every div distribution
    uint256 public sideBetMintMultiplierSUN = 2 * 1e6; // 2x minting in sidebet compared to main bet
    address public sharesContractAddress;
    address public diamondVouchersContractAddress;
    uint256 public diamondExchangeRate = 1000;  //1000 voucher = 1 diamond 
    address public topiaVaultGameContract;

    uint256 public dividendAccumulated;
    uint256 public divPercentageSUN = 100000000;  //100% of dividend distributed 
    uint256 public dividendRemainder;
    uint256 public lastDividendPaidTime;

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    mapping (address => uint256) public mintingBasePrice;          //starting 100 trx to mint 1 voucher
    mapping (address => uint256) public mintingPriceIncrementer;
    
    
    mapping (address => uint256) public usersVoucherBurnedAmount;
    mapping (address => uint256) public divCounterWhenUserBurn;
    uint256[] public DivDistributedAllTime;  //It will store all the div distributions amount in order
    uint256[] public burnedVouchersWhileDivDistribution;    //total amount vouchers burned at time of dividend distribution
    


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address indexed target, bool frozen);
    
    // Owner Minting
    event OwnerMinting(address indexed ownerWallet, uint256 value);
    
    //user withdraw dividend
    event DividendWithdraw(address indexed user, uint256 indexed amount);
    
    //DividendPaid by admin
    event DividendPaid(uint256 indexed amount);



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



    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    /**
        Constructor function. nothing happens
    */
    constructor() public { }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    function mintVouchers(address _user, uint256 _mainBetSUN, uint256 _siteBetSUN)  public returns(bool) {

        //checking if the caller is whitelisted game contract
        require(whitelistCaller[msg.sender], 'Unauthorised caller');

        //globalHalt will affect this function, which ultimately revert the Roll functions in game contract
        require(!globalHalt, 'Global Halt is on');


        uint256 mainBetMint = _mainBetSUN / mintingBasePrice[msg.sender];
        uint256 sideBetMint = (_siteBetSUN / mintingBasePrice[msg.sender]) * sideBetMintMultiplierSUN / 1000000;  //side bet mint 2x of main bet
        uint256 totalVouchersToMint = mainBetMint + sideBetMint;
        totalMintedLifetime += totalVouchersToMint;
        
        balanceOf[_user] = balanceOf[_user].add(totalVouchersToMint);      
        totalSupply = totalSupply.add(totalVouchersToMint);
        
        //emitting Transfer event
        emit Transfer(address(0),_user,totalVouchersToMint);
        
    return true;
    }

    function mintVouchersOwnerOnly(address user, uint256 tokenAmountSUN) public onlySigner returns(string){
        
        totalMintedLifetime += tokenAmountSUN;
        
        balanceOf[user] = balanceOf[user].add(tokenAmountSUN);      
        totalSupply = totalSupply.add(tokenAmountSUN);
        
        //emitting Transfer event
        emit Transfer(address(0),user,tokenAmountSUN);

        return "Voucher minted and sent to receipient";
    }
    
    function updateSideBetMintMultiplierSUN(uint256 _sideBetMintMultiplierSUN) public onlyOwner returns(string){
        sideBetMintMultiplierSUN = _sideBetMintMultiplierSUN;
        return "done";
    }
    
    
    /**
        * Destroy vouchers to be eligible for dividend
        *
        * mintShareStatus:
            0 = 100% TRX dividend - 0% Shares minting
            1 = 50% TRX dividend - 50% Shares minting
            2 = 0% TRX dividend - 100% Shares minting
        */
    function burnVoucher(uint256 _value, uint8 mintShareStatus) public returns (bool success) {

        require(!safeguardTokenMovement, 'Safeguard is placed');
        require(_value > 0, 'Invalid amount');
        
        address user = msg.sender;

        //processing mint share status - If owner sets sharecontract address as 0x0, then nothing will happen and everythng will be back to as usual
        uint256 tempValue = _value;
        if(sharesContractAddress != address(0)){
            if(mintShareStatus == 1){
                tempValue = _value / 2;
                InterfaceSHARES(sharesContractAddress).mintShares(user, tempValue);
            }
            else if(mintShareStatus == 2){
                tempValue = 0;
                InterfaceSHARES(sharesContractAddress).mintShares(user, _value);
            }
            else{
                //tempValue = _value;
                //no shares minting if its 0 - by default
            }
        }
        
        /** BURN VOUCHERS LOGIC
        scenario 1: user burn the vouchers for very first time, then it will set the time from that point forward
        scenario 2: if users keep burning subsequently before div distribution, then it will just increment the burn amount
        scenario 3: when admin distributes divs, then user will get divs according to his share percent. 
                    and it will note that point of time. In another words, users burned vouchers will be reset. 
                    and they have to keep burning to get divs from subsequent distributions.
        */
        
        //case 1: first time burn or burn right after div withdrawal (in div withdrawal, we will zero this usersVoucherBurnedAmount variable)
        if(usersVoucherBurnedAmount[user] == 0){
            usersVoucherBurnedAmount[user] = tempValue;
            divCounterWhenUserBurn[user] = DivDistributedAllTime.length;
            
        }
        else{
            //case 2: user burns multiple times before any div distribution
            if(divCounterWhenUserBurn[user] == DivDistributedAllTime.length ){
                usersVoucherBurnedAmount[user] += tempValue;
            }
            
            //case 3: user burns again and many divs has been disributed and he has not withdrawn his previous divs.
            //in this case, we will first withdraw his previous divs and then start again from this point forward.
            else{
                
                //first withdraw any pending divs
                if(!withdrawDividend()){
                    
                    //this is rare case where users also have outstanding divs and can not be withdrawn,
                    //then just forget everything and start from this point forward
                    usersVoucherBurnedAmount[user] = tempValue;
                    divCounterWhenUserBurn[user] = DivDistributedAllTime.length;
                    
                }
                    
                //if div withdrawn, then just update usersVoucherBurnedAmount mapping
                usersVoucherBurnedAmount[user] = tempValue;
                //no need to update divCounterWhenUserBurn mapping as that is updated in withdrawDividend function

            }
        }
        
        
        //logic to mint diamond vouchers
        if(diamondVouchersContractAddress != address(0)){
            uint256 diamond = _value / diamondExchangeRate;
            InterfaceDIAMONDS(diamondVouchersContractAddress).mintDiamonds(user,diamond);
        }

        //trigger vault game contract
        if(topiaVaultGameContract != address(0)){
            InterfaceTOPIAVAULT(topiaVaultGameContract).incrementClock(_value);
        }
 
        //checking of enough token balance is done by SafeMath
        balanceOf[user] = balanceOf[user].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        
        //updating burn tracker global
        vouchersBurnedAllTime = vouchersBurnedAllTime.add(_value);
        vouchersBurnedCurrentPeriod = vouchersBurnedCurrentPeriod.add(_value);
        
        emit Transfer(user, address(0), _value);
        //althogh we can track all the "burn" from the Transfer function, we just kept it as it is. As that is no much harm
        emit Burn(user, _value);
        return true;
    }
    
    function withdrawDividend() public returns(bool){
        address user = msg.sender;
        uint256 availableDividend = getDividendConfirmed(user);
        if( availableDividend > 0){
            usersVoucherBurnedAmount[user] = 0;
            divCounterWhenUserBurn[user] = DivDistributedAllTime.length;
            
            user.transfer(availableDividend);
            
            emit DividendWithdraw(user, availableDividend);
            return true;
        }
        
        //by default it will return false
    }
    
    function getDividendConfirmed(address user) public view returns (uint256){
        
        uint256 divArrayIndex = divCounterWhenUserBurn[user];
        uint256 userBurnedVouchers = usersVoucherBurnedAmount[user];
        
        if( divArrayIndex < DivDistributedAllTime.length && userBurnedVouchers > 0){
            
            uint256 divPoolAmount = DivDistributedAllTime[divArrayIndex];
            
            //the reason to multiply with 1000000 is that it can hold small decimals, which will divided in next equasion 
            uint256 sharePercentage = userBurnedVouchers * 100 * 1000000 / burnedVouchersWhileDivDistribution[divArrayIndex];
            
            //now calculating final trx amount from ( available dividend pool * share percentage / 100) 
            if(divPoolAmount * sharePercentage > 0){
                
                //devide 1000000 because we multiplied above
                return divPoolAmount * sharePercentage / 100 / 1000000;
            }
            
        }
        
        //by default it will return zero
    }
    
    
    /**
        This function displays all the dividend of all the game contracts
    */
    function getDividendPotential() public view returns(uint256){
        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableVoucherRake();
            if(amount > 0){
                totalDividend += amount;
            }
        }

        if(totalDividend > 0){

            uint256 totalAmount = totalDividend + dividendAccumulated;
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            return (totalAmount * divPercentageSUN / 100 / 1000000);  
            
        }
        
        //by default it returns zero
        
    }
    
    
    function distributeMainDividend() public  returns(uint256){
        
        require(vouchersBurnedCurrentPeriod > 0, 'none has burned the vouchers');

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(lastDividendPaidTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }

        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        for(uint i=0; i < totalGameContracts; i++){
            address gameAddress = whitelistCallerArray[i];
            uint256 amount = InterfaceGAMES(gameAddress).getAvailableVoucherRake();
            mintingBasePrice[gameAddress] = mintingBasePrice[gameAddress] + mintingPriceIncrementer[gameAddress];
            if(amount > 0){
                //if status is true, which means particular game has positive dividend available
                totalDividend += amount;

                //we will request that dividend TRX from game contract to this token contract
                require(InterfaceGAMES(gameAddress).requestVoucherRakePayment(), 'could not transfer trx');
            }
        }

        lastDividendPaidTime = now;

        if(totalDividend > 0){
            
            //dividendAccumulated is the total fund we got from all game contracts, which will be emptied while this div distribution
            uint256 finalDividendAmount = totalDividend + dividendAccumulated;
            
            //admin can set % of dividend to be distributed.
            //reason for 1000000 is that divPercentageSUN was in SUN
            uint256 payableAmount =  finalDividendAmount * divPercentageSUN / 100 / 1000000; 
            
            //if dividend % is less than 100%, then track that remainder in another variable
            if(divPercentageSUN < 100000000){
                dividendRemainder +=  finalDividendAmount * (100000000 - divPercentageSUN) / 100 / 1000000;
            }

            //update variables
            dividendAccumulated = 0;
            DivDistributedAllTime.push(payableAmount);
            burnedVouchersWhileDivDistribution.push(vouchersBurnedCurrentPeriod);
            vouchersBurnedCurrentPeriod = 0;
            
            
            emit DividendPaid(finalDividendAmount);
            
            return finalDividendAmount;

        }
  
    }
    
    function updateMintingPriceData(address gameContractAddress, uint256 _mintingBasePrice, uint256 _mintingPriceIncrementer) public onlyOwner returns(string){
        
        mintingBasePrice[gameContractAddress] = _mintingBasePrice;
        mintingPriceIncrementer[gameContractAddress] = _mintingPriceIncrementer;
        
        return "done";
    }
    
    function updateDivPercentageSUN(uint256 newPercentSUN) public onlyOwner returns(string){
        require(divPercentageSUN <= 100000000, 'percentage cant be more than 100%');
        divPercentageSUN = newPercentSUN;
        return "done";
    }

    
    /**
     * This function also used to invest any TRX into dividend pool.
     * This is useful especially while diamond voucher presale.
     */
    function reInvestDividendRemainder() public payable onlyOwner returns(string){
        require(dividendRemainder > 0 || msg.value > 0, 'dividendRemainder cant be zero');
        dividendAccumulated = dividendRemainder + msg.value;
        dividendRemainder=0;
        return "dividendRemainder is sent to div pool";
    }
    
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
    


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistGameAddress(address _newAddress) public onlyOwner returns(string){
        
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        mintingBasePrice[_newAddress] = 100;          //starting 100 trx to mint 1 voucher
        mintingPriceIncrementer[_newAddress] = 1;

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

    function updateSharesContractAddress(address _newAddress) public onlyOwner returns(string){
        sharesContractAddress = _newAddress;
        return "Shares contract address updated successfully";
    }
    
    function updateDiamondVouchersDetails(address _newAddress, uint256 _newAmount) public onlyOwner returns(string){
        diamondVouchersContractAddress = _newAddress;
        diamondExchangeRate = _newAmount;
        return "Diamond voucher contract address updated successfully";
    }
    
    function updateTopiaVaultGameContract(address _newAddress) public onlyOwner returns(string){
        topiaVaultGameContract = _newAddress;
        return "Topia Vault Game contract address updated successfully";
    }
    
    
    
    


}