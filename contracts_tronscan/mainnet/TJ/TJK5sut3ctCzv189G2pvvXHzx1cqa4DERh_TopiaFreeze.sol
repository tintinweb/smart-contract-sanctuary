//SourceUnit: topiaFreezing.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_




████████╗ ██████╗ ██████╗ ██╗ █████╗     ███████╗██████╗ ███████╗███████╗███████╗███████╗
╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══███╔╝██╔════╝
   ██║   ██║   ██║██████╔╝██║███████║    █████╗  ██████╔╝█████╗  █████╗    ███╔╝ █████╗  
   ██║   ██║   ██║██╔═══╝ ██║██╔══██║    ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝   ███╔╝  ██╔══╝  
   ██║   ╚██████╔╝██║     ██║██║  ██║    ██║     ██║  ██║███████╗███████╗███████╗███████╗
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝
                                                                                         


                                                                             


=== 'Topia Freeze' Token contract with following features ===
    => Freezing Topia for different tier directly
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 


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
} 
    
//-----------------------------------------------------------------------------
// Trontopia token
//-----------------------------------------------------------------------------

interface interfaceTOKEN
{
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function burn(uint256 _value) external returns (bool success);
}





    
//***********************************************************************************//
//---------------------    TOPIA FREEZE MAIN CODE STARTS HERE   ---------------------//
//***********************************************************************************//
    
contract TopiaFreeze is owned 
{
    using SafeMath for uint256;

    uint256 public totalFrozenTopia;   // Total frozen Topia across all users, index 0 => In bronze, 1 => In Silver, 2 => In Gold
    address public topiaTokenContractAddress; // Address of Topia Token Contract
    address public dividendContractAddress;  // Address of Dividend Contract
    uint256 public durationFreezeTier0 = 7 days; // Required min freezing period for Silver
    uint256 public durationFreezeTier1 = 30 days; // Required min freezing period for Silver
    uint256 public durationFreezeTier2 = 60 days; // Required min freezing period for Gold. // For Bronze 24 Hr is hardcodded
    uint256 public releaseLock = 1 days;  // After unfreeze release will be possible after this period

      // If it is true for specific user can be checked in another contract and used for a decision like trading with frozen topia etc    
    mapping(address => bool ) public tradeWithFrozenTopiaAllowed;

    //this mapping tracks bronze,silver,gold individually
    mapping(uint256 => uint256 ) public totalFrozenTopiaIndividual;   //Freeze Tiers (0,1,2) => total frozen amount


    //If someone unfreezed before minimum required period his some % (as admin sets below variable ) will be burnt 
    uint256 public forceUnfreezeComission = 1000; //10% comission if unfreezed before lock period  

    //this will record the amount of freeze, time of freeze and tier of freeze, and unfreezed or not
    //user can unfreeze some part of his freezed amount also
    //thats why unfreezingTime,unFreezingAmount etc are being tracked seperately
    struct userFrozen
    {
        uint256 freezingTier;
        uint256 freezingAmount;
        bool unfreezed;
        uint256 unFreezingAmount;
        uint256 unFreezingTime;
        uint256 freezingTiming;
        bool preMatureUnFreezed;
    }

    mapping(address => userFrozen) public userFrozens;   //All frozen records of a  user => index 0 => In bronze, 1 => In Silver, 2 => In Gold

    //Admin can set this vaule to check which users are allowed to some specic feature 
    // ( like trading with frozen topia, should be tracked in relevent contract it will return true ar false for given user, when called from another contract)
    function setTradeWithFrozenTopiaAllowed(address user, bool _tradeWithFrozenTopiaAllowed ) public onlyOwner returns(bool)
    {
        tradeWithFrozenTopiaAllowed[user] = _tradeWithFrozenTopiaAllowed;
        return true;
    }

    // Admin can set how much % penalty will be charged for unfreezing before min tier periof
    function setForceUnfreezeComission(uint256 _forceUnfreezeComission ) public onlyOwner returns(bool)
    {
        forceUnfreezeComission = _forceUnfreezeComission;
        return true;
    }

    // Admin need to set the address of topia token contract address here to function this contract properly
    function setTopiaTokenContractAddress(address _topiaTokenContractAddress ) public onlyOwner returns(bool)
    {
        topiaTokenContractAddress = _topiaTokenContractAddress;
        return true;
    }


    // Admin need to set the address of Dividend Contract Address here to function this contract properly
    function updateDividendContract(address _newAddress) public onlyOwner returns(string){
        //we dont want to check input address against 0x0 as owner might decided to use address 0x0 to halt operation
        dividendContractAddress = _newAddress;
        return "Dividend contract address updated";
    }



    /**
        Function to change Freeze Tier Duration
    */
    // Admin can set min required period of freezing for silver (default 30 days ) and gold ( default 60 days ) 
    function changeFreezeTiersDuration(uint256 tier0, uint256 tier1, uint256 tier2, uint256 _releaseLock) public onlyOwner returns(string){
        
        durationFreezeTier0 = tier0;
        durationFreezeTier1 = tier1;
        durationFreezeTier2 = tier2;
        releaseLock = _releaseLock;
        
        return "Freeze Tier Duration Updated Successfully";
    }

    //Calculate percent and returns result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }      


    event freezeTopiaEv(uint256 thisTime,address caller,uint256 amountToFreeze,uint256 freezingTier,uint256 userFrozensRecordsCount );
    // freezingTier => 0=bronze, 1=silver, 2=gold
    function freezeTopia(uint256 amountToFreeze, uint256 freezingTier) public returns (bool)
    {
        require(freezingTier < 3 , "invalid freezing tier");
        address caller = msg.sender;
        //require(!userFrozens[caller].unfreezed, "one unfreezing is pending");
        //All amount transfers to this contract address which user want to freese and mapped relavent records below
        require(interfaceTOKEN(topiaTokenContractAddress).transferFrom(caller,address(this), amountToFreeze),"ERC20 'transferFrom' call failed");
        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        //we want this current call to complete if we return true from outstandingDivWithdrawFreeze, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawFreeze(caller), 'Outstanding div withdraw failed');
  
        uint256 curFreezeAmount = userFrozens[caller].freezingAmount; 
        if (curFreezeAmount > 0)
        {
            require(userFrozens[caller].freezingTier == freezingTier,"freezing amount > 0 , can not change current tier");
        }
        userFrozens[caller].freezingAmount = curFreezeAmount.add(amountToFreeze);
        // sets freezing time only when user is freezing for the first time or after he withdrawn everything before
        if (curFreezeAmount == 0)
        {
            userFrozens[caller].freezingTier = freezingTier;
            userFrozens[caller].freezingTiming = now;
        }
        //Global freezing amount by tier increased 
        totalFrozenTopia += amountToFreeze;
        totalFrozenTopiaIndividual[freezingTier] += amountToFreeze;     //tracking individually
        emit freezeTopiaEv(now, caller, amountToFreeze, freezingTier, userFrozens[caller].freezingAmount);
        return(true);
    }


    event unfreezeTopiaEv(uint256 thisTime,address caller,uint256 unFreezingAmount);
    // User will call this function to unfreezed his freezed amount
    // User can unfreeze partial freezed amount also
    // user can also unfreesed before min required period for a tier, but in that case penalty will be charge by burning some part
    function unfreezeTopia(uint256 amountToUnFreeze, bool forceUnfreeze) public returns (bool)
    {
        address caller = msg.sender;
        (uint256 timeRemains, ,uint256 freezingTier) = remainingTimeOfMyFreeze(caller);
        if(timeRemains==0)
        {
            forceUnfreeze = false;
        }
        //require( freezingTier < 3, "invalid freezing tier" );
        require(!userFrozens[caller].unfreezed,"already one unfreezing pending" );
        require(amountToUnFreeze <= userFrozens[caller].freezingAmount, "invalid amount to unfreeze" );
        //we want this current call to complete if we return true from outstandingDivWithdrawUnfreeze, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawUnfreeze(caller), 'Outstanding div withdraw failed');

        if (! forceUnfreeze)
        {
            uint256 freezingTime = userFrozens[caller].freezingTiming;
            if (freezingTier == 0 )
            {
                require(now - freezingTime >= durationFreezeTier0 , "can not unfreeze before time.");                
            }
            else if (freezingTier == 1)
            {
                require(now - freezingTime >= durationFreezeTier1 , "can not unfreeze before time");
            }
            else if (freezingTier == 2)
            {
                require(now - freezingTime >= durationFreezeTier2 , "can not unfreeze before time"); 
            }            
        }
        else
        {
            // prematured unfreesing is marked here so that penalty can be charged when user attempts to release
            userFrozens[caller].preMatureUnFreezed = true;  
        }

        totalFrozenTopia -= amountToUnFreeze;
        totalFrozenTopiaIndividual[freezingTier] -= amountToUnFreeze;     //tracking individually
        userFrozens[caller].freezingAmount = userFrozens[caller].freezingAmount.sub(amountToUnFreeze);
        userFrozens[caller].unFreezingAmount = userFrozens[caller].unFreezingAmount.add(amountToUnFreeze);
        userFrozens[caller].unfreezed = true;
        userFrozens[caller].unFreezingTime = now;
        emit unfreezeTopiaEv(now,caller,amountToUnFreeze);
        return true;
    }

    function remainingTimeOfMyFreeze(address user) public view returns(uint256 remainingTime, uint256 freezingAmount, uint256 thisTier)
    {
        address caller = user;
        thisTier = userFrozens[caller].freezingTier;
        remainingTime =  now.sub(userFrozens[caller].freezingTiming);
        freezingAmount = userFrozens[caller].freezingAmount;
        if (thisTier == 0 )
        {            
            if(remainingTime < durationFreezeTier0)
            {
                remainingTime = durationFreezeTier0 - remainingTime;
            }
            else
            {
                remainingTime = 0;
            }
        }
        else if (thisTier == 1)
        {
            if(remainingTime < durationFreezeTier1)
            {
                remainingTime = durationFreezeTier1 - remainingTime;
            }
            else
            {
                remainingTime = 0;
            }
        }
        else if (thisTier == 2)
        {
            if(remainingTime < durationFreezeTier2)
            {
                remainingTime = durationFreezeTier2 - remainingTime;
            }
            else
            {
                remainingTime = 0;
            }
        }
        return (remainingTime,freezingAmount, thisTier);
    }

    event releaseTopiaEv( uint256 curTime,address caller,uint256 amountToRelease,uint256 panelty);
    // user will call this function to release amount after 24 hr of unfreeaed
    // If unfreezed normal then OK else a penalty will be deducted and will be burned from the amount
    // after release processing all unfreesing marke will be reset to zero
    
    function viewReleaseTopia(address caller) public view returns (uint256 timeRemains, uint256 amount)
    {
        timeRemains = now.sub(userFrozens[caller].unFreezingTime);
        
        if(timeRemains < releaseLock)
        {
            timeRemains = releaseLock - timeRemains;
            amount = userFrozens[caller].unFreezingAmount;
        }
        else
        {
            timeRemains = 0;
            amount = userFrozens[caller].unFreezingAmount.add(userFrozens[caller].freezingAmount);
        }


        return(timeRemains,amount);
    }

    function releaseTopia() public returns (bool)
    {
        address caller = msg.sender;
        (uint256 timeRemains,,) = remainingTimeOfMyFreeze(caller);
        if (timeRemains > 0 )
        {
            require(now - userFrozens[caller].unFreezingTime >= releaseLock , "can not release before time.");
        }
        else
        {
            uint256 frzAmount = userFrozens[caller].freezingAmount;
            if (frzAmount > 0)
            {
                unfreezeTopia(frzAmount, false);
            }
        }
        require(userFrozens[caller].unfreezed,"nothing unfreezed" );
        uint256 amountToRelease = userFrozens[caller].unFreezingAmount;
        uint256 panelty;
        if(userFrozens[caller].preMatureUnFreezed)
        {
            panelty = calculatePercentage(amountToRelease, forceUnfreezeComission);
            require(interfaceTOKEN(topiaTokenContractAddress).burn(panelty),"burning failed");
            require(interfaceTOKEN(topiaTokenContractAddress).transfer(caller,(amountToRelease.sub(panelty))),"transfer fail");
        }
        else
        {
            require(interfaceTOKEN(topiaTokenContractAddress).transfer(caller,amountToRelease),"transfer fail");
        }
        userFrozens[caller].unfreezed = false;
        userFrozens[caller].unFreezingAmount = 0;
        userFrozens[caller].unFreezingTime = 0;
        emit releaseTopiaEv( now, caller, amountToRelease, panelty);
        return true;
    }



}