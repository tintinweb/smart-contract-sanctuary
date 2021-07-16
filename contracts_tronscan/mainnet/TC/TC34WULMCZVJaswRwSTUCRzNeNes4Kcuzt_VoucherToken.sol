//SourceUnit: voucherToken.sol

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

interface VoucherTokenInherit
{

    function  sharesContractAddress() external view returns(address);
    function  diamondVouchersContractAddress() external view returns(address);
    function  topiaVaultGameContract() external view returns(address);
    function  voucherDividendContract() external view returns(address);
    function  topiaDividendContractAddress() external view returns(address);
    function topiaTokenContractAddress() external view returns(address);
    function  frozenAccount(address _user) external view returns(bool);

    function  whitelistCallerArray(uint256 _addressNo) external view returns(address);

    function  lengthOfwhiteListCaller() external view returns(uint256);
    function  mintingBasePrice(address _contract) external view returns(uint256);
    function  mintingPriceIncrementer(address _contract) external view returns(uint256);
    function  vaultCredit(address _user) external view returns(uint256);  
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
//---------------- VOUCHER DIVIDEND CONTRACT INTERFACE    ------------------//
//**************************************************************************//

interface InterfaceVoucherDividend {
    function withdrawDividendsEverything() external returns(bool);
    function  lengthOfDivDistributedAllTime() external view returns(uint256 _lengthOfDDAT);
    function getDividendPotentialTRX() external view returns(uint256);
    function payToUserForBurnVoucherOption3(address user, uint256 amount, uint256 vouchersBurnedTotalInOption3) external returns(bool);
}


//**************************************************************************//
//-------------------    TOPIA CONTRACT INTERFACE       --------------------//
//**************************************************************************//
interface TRONtopiaInterface
{
    function transfer(address recipient, uint amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
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
    
contract VoucherToken is owned {

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
    uint256 public sideBetMintMultiplierSUN = 2 * 1e6; // 2x minting in sidebet compared to main bet
    address public sharesContractAddress;
    address public diamondVouchersContractAddress;
    uint256 public diamondExchangeRate = 1000;  //1000 voucher = 1 diamond 
    address public topiaVaultGameContract;
    address public voucherDividendContract;
    address public topiaDividendContractAddress;
    address public topiaTokenContractAddress;
    

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    mapping (address => uint256) public mintingBasePrice;          //starting 100 trx to mint 1 voucher
    mapping (address => uint256) public mintingPriceIncrementer;
    
    
    mapping (address => uint256[4]) public usersVoucherBurnedAmount;
    mapping (address => uint256) public divCounterWhenUserBurn;
    
    uint256[] public burnedVouchersWhileDivDistribution;    //total amount vouchers burned at time of dividend distribution
    uint256[3] public changeByPercent;  // for reducing while burning
    uint256[4] public totalBurnIn;  // total burn for 0,1,2 category
    mapping(address => uint256 ) public vaultCredit;

    bool public inheritLock;  // once inherit called then even admin can't call 
    bool public inheritVaultCredit;
    bool public inheritFrozenAccount;

    uint256 public option3TrxRewardTotal;
    uint256 public option3TrxRewardPercent=8000; //default 80% 
    mapping(address => uint256 ) public option3TrxReward;
    uint256 public option3TopiaMintPercent = 15000; //default 150.00 % 
    mapping(address => uint256 ) public valueToMintTopia;
    bool allowOption3Burn;

    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value, uint256 burnType);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address indexed target, bool frozen);
    
    // Owner Minting
    event OwnerMinting(address indexed ownerWallet, uint256 value);
    
    
    function setOption3TrxRewardPercent(uint256 _option3TrxRewardPercent) public onlyOwner returns(bool)
    {
        option3TrxRewardPercent = _option3TrxRewardPercent;
        return true;
    }

    function setOption3TopiaMintPercent(uint256 _option3TopiaMintPercent) public onlyOwner returns(bool)
    {
        option3TopiaMintPercent = _option3TopiaMintPercent;
        return true;
    }

    function setAllowOption3Burn ( bool _allowOption3Burn) public onlyOwner returns(bool)
    {
        allowOption3Burn = _allowOption3Burn;
        return true;
    }

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
    constructor() public { 

        changeByPercent[0] = 1;
        changeByPercent[1] = 1000000;
        changeByPercent[2] = 1;
    }

    function usersVoucherBurnedAmountView(address user,uint256 mintShareStatus) public view returns(uint256)
    {
        return usersVoucherBurnedAmount[user][mintShareStatus];
    }   

    function inheritFrom(address anyPrevVoucherContractAddress,bool _inheritVaultCredit, bool _inheritFrozenAccount) public onlyOwner returns (bool)
    {
        require(! inheritLock,"Inherit locked");
        sharesContractAddress = VoucherTokenInherit(anyPrevVoucherContractAddress).sharesContractAddress();
        diamondVouchersContractAddress = VoucherTokenInherit(anyPrevVoucherContractAddress).diamondVouchersContractAddress();
        topiaVaultGameContract = VoucherTokenInherit(anyPrevVoucherContractAddress).topiaVaultGameContract();
        voucherDividendContract = VoucherTokenInherit(anyPrevVoucherContractAddress).voucherDividendContract();
        topiaDividendContractAddress = VoucherTokenInherit(anyPrevVoucherContractAddress).topiaDividendContractAddress();
        topiaTokenContractAddress = VoucherTokenInherit(anyPrevVoucherContractAddress).topiaTokenContractAddress();
        inheritVaultCredit = _inheritVaultCredit;  // will check on first interaction by user
        inheritFrozenAccount = _inheritFrozenAccount; // will check on first interaction by user
        uint256 lengthOfWLC = VoucherTokenInherit(anyPrevVoucherContractAddress).lengthOfwhiteListCaller();
        uint256 i;
        address temp;
        for (i=0;i<lengthOfWLC;i++)
        {
            temp = VoucherTokenInherit(anyPrevVoucherContractAddress).whitelistCallerArray(i);
            whitelistCaller[temp] = true;
            whitelistCallerArray.push(temp);
            whitelistCallerArrayIndex[temp] = i;
            mintingBasePrice[temp] = VoucherTokenInherit(anyPrevVoucherContractAddress).mintingBasePrice(temp);
            mintingPriceIncrementer[temp] = VoucherTokenInherit(anyPrevVoucherContractAddress).mintingPriceIncrementer(temp);
        }
        inheritLock = true;
        return true;
    }



    function unlockInherit() public onlyOwner returns (bool)
    {
        require(inheritLock, "already unlocked");

        inheritVaultCredit = false;  
        inheritFrozenAccount = false; 
        uint256 lengthOfWLC = whitelistCallerArray.length;
        uint256 i;
        address temp;
        for (i=0;i<lengthOfWLC;i++)
        {
            temp = whitelistCallerArray[i];
            whitelistCaller[temp] = false;
            whitelistCallerArrayIndex[temp] = 0;
            mintingBasePrice[temp] = 0;
            mintingPriceIncrementer[temp] = 0;
        }        
        delete whitelistCallerArray;
        inheritLock = false;
        return true;
    }

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    function mintVouchers(address _user, uint256 _mainBetSUN, uint256 _siteBetSUN)  public returns(bool) {

        //checking if the caller is whitelisted game contract
        require(whitelistCaller[msg.sender] || msg.sender == topiaDividendContractAddress, 'Unauthorised caller');

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
    
    
    //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        //require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }
     

    function updateBurnControl(uint256 mintShareStatus, uint256 _changeByPercent) public onlyOwner returns (bool)
    {
        require(mintShareStatus<3,"invalid mintShareStatus");
        changeByPercent[mintShareStatus] = _changeByPercent;
        return true;
    }


    event option3BurnLog(uint256 timeNow, address user, uint256 reward, uint256 topiaMint);
    function burnVoucher(uint256 _value, uint8 mintShareStatus, address _user) public returns (bool success) {
        // some variables are used twice for other purpose, so do not interpret it always by name
        address caller = msg.sender;
        address user;
        if(whitelistCaller[caller])
        {
            user = _user;
        }
        else
        {
            user = caller;
        }
        

        
        require(!safeguardTokenMovement, 'Safeguard is placed');
        require(_value > 0, 'Invalid amount');
        require(mintShareStatus < 4 ,"invalid mintShareStatus");

        //processing mint share status - If owner sets sharecontract address as 0x0, then nothing will happen and everythng will be back to as usual
        uint256 toMint;
        if(sharesContractAddress != address(0) && mintShareStatus == 1 ){
            toMint = calculatePercentage(_value,changeByPercent[mintShareStatus]);
            InterfaceSHARES(sharesContractAddress).mintShares(user, toMint);
        }
        
      
        
        //logic to mint diamond vouchers
        if(diamondVouchersContractAddress != address(0)){
            toMint = _value / diamondExchangeRate;
            InterfaceDIAMONDS(diamondVouchersContractAddress).mintDiamonds(user,toMint);
        }


        //checking of enough token balance is done by SafeMath
        balanceOf[user] = balanceOf[user].sub(_value);  // Subtract from the sender
        totalBurnIn[mintShareStatus] += _value;

        //Instant trx credited to to user who burns under option 3
        if (mintShareStatus == 3)
        {
            require(allowOption3Burn == true,"burn for option 3 not allowed");
            uint256 totalGameContracts = whitelistCallerArray.length;
            uint256 totalDividend;
            uint256 i;
            for(i=0; i < totalGameContracts; i++){
                uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableVoucherRake();
                if(amount > 0){
                    totalDividend += amount;
                }
            }
            uint256 data1 = (totalDividend + option3TrxRewardTotal) * 1000000;
            uint256 data2 = usersVoucherBurnedAmount[user][0] + totalSupply + usersVoucherBurnedAmount[user][3];
            require(data2 > 0 , "divisor(totalsupply) is 0 ");
            require(data1 > 0 , "totalDividend output is 0");
            data2 = data1.div(data2);
            data2 = calculatePercentage(data2, option3TrxRewardPercent) * 1000000;
            require(InterfaceVoucherDividend(voucherDividendContract).payToUserForBurnVoucherOption3(user,data2, totalBurnIn[3]),"pay TRX faled");
            option3TrxReward[user] += data2;
            option3TrxRewardTotal += data2;
            // To mint topia
            // TRX calculation for minting  voucher
            data1 = calculatePercentage( ( _value * 1000 ) , option3TopiaMintPercent);
            valueToMintTopia[user] += data1;
            emit option3BurnLog(now, user, data2, data1);
        }
        else
        {
            mintMyPendingTopia();
            //withdraw any outstanding dividend user has in trx or in topia
            InterfaceVoucherDividend(voucherDividendContract).withdrawDividendsEverything();
        }

        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply 
        


        //updating burn tracker global
        vouchersBurnedAllTime = vouchersBurnedAllTime.add(_value);
        usersVoucherBurnedAmount[user][mintShareStatus] += _value;
        
        emit Transfer(user, address(0), _value);
        //althogh we can track all the "burn" from the Transfer function, we just kept it as it is. As that is no much harm
        emit Burn(user, _value, mintShareStatus);
        return true;
    }

    event mintMyPendingTopiaEv(uint256 timeNow, address user, uint256 value, address topiaAddress);
    function mintMyPendingTopia() public returns(bool)
    {
        uint256 toMint = valueToMintTopia[user];
        address user = msg.sender;
        if(topiaTokenContractAddress != address(0) && toMint > 0)
        {
            TRONtopiaInterface(topiaTokenContractAddress).mintToken(user,toMint);
            valueToMintTopia[user] = 0;
            emit mintMyPendingTopiaEv(now,user,toMint,topiaTokenContractAddress);
            return true;
        } 
        return false;
    }

    function viewCurrentTrxValueForOption3Burning() public view returns(uint256)
    {
        address user = msg.sender;
        if ( balanceOf[user] > 0)
        {
            uint256 totalGameContracts = whitelistCallerArray.length;
            uint256 totalDividend;
            uint256 i;
            for(i=0; i < totalGameContracts; i++){
                uint256 amount = InterfaceGAMES(whitelistCallerArray[i]).getAvailableVoucherRake();
                if(amount > 0){
                    totalDividend += amount;
                }
            }
            uint256 data1 = totalDividend + option3TrxRewardTotal * 1000000;
            uint256 data2 = usersVoucherBurnedAmount[user][0] + totalSupply + usersVoucherBurnedAmount[user][3];
            data2 = data1.div(data2);
            data2 = calculatePercentage(data2, option3TrxRewardPercent);  
            return data2 * 1000000;      
        }
        return 0;
    }
    
   
  
    
  
    
    function updateMintingPriceData(address gameContractAddress, uint256 _mintingBasePrice, uint256 _mintingPriceIncrementer) public onlyOwner returns(string){
        
        mintingBasePrice[gameContractAddress] = _mintingBasePrice;
        mintingPriceIncrementer[gameContractAddress] = _mintingPriceIncrementer;
        
        return "done";
    }
    
    //this function called by voucher dividend contract to update the mintingBasePrice
    function changeMintingBasePriceWhileDivDistro() public returns(bool){
        require(msg.sender == voucherDividendContract, 'Invalid caller');
        uint256 totalGameContracts = whitelistCallerArray.length;
        for(uint i=0; i < totalGameContracts; i++){
            mintingBasePrice[whitelistCallerArray[i]] +=  mintingPriceIncrementer[whitelistCallerArray[i]];
        }
        return true;
    }
    
    function lengthOfwhiteListCaller() public view returns (uint256 _lengthOfWLC)
    {
        _lengthOfWLC = whitelistCallerArray.length;
        return _lengthOfWLC;
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

    //Just in rare case, owner wants to transfer TRX from contract to owner address
    function manualWithdrawTRX(uint256 amount) onlyOwner public returns(bool) 
    {
        require(address(this).balance >= amount, "not enough balance to withdraw" );
        address(owner).transfer(address(this).balance);
        return true;
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


    function updateDiamondExchangeRate(uint256 diamondExchangeRate_) public onlyOwner returns(string){
        diamondExchangeRate = diamondExchangeRate_;
        return "diamondExchangeRate updated successfully";
    }
    

    
    function updateContracts(address sharesContract, address diamondContract, address vaultContract, address voucherDividendContract_, address topiaDividendContractAddress_, address _topiaTokenContractAddress) public onlyOwner returns(string){
        sharesContractAddress = sharesContract;
        diamondVouchersContractAddress = diamondContract;
        topiaVaultGameContract = vaultContract;
        voucherDividendContract = voucherDividendContract_;
        topiaDividendContractAddress = topiaDividendContractAddress_;
        topiaTokenContractAddress = _topiaTokenContractAddress;
        return "All contract addresses updated successfully";
    }
    
    
    
    


}