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

    uint256 public totalFrozenTopiaInBronze;
    uint256 public totalFrozenTopiaInSilver;
    uint256 public totalFrozenTopiaInGold;
    address public topiaTokenContractAddress;
    address public dividendContractAddress;    
    uint256 public durationFreezeTier1 = 30 days;
    uint256 public durationFreezeTier2 = 60 days;

    mapping(address => bool ) public tradeWithFrozenTopiaAllowed;


    uint256 public forceUnfreezeComission = 1000; //10% comission if unfreezed before lock period  

    //this will record the amount of freeze, time of freeze and tier of freeze, and unfreezed or not
    struct userFrozen
    {
        uint256 freezingAmount;
        uint256 freezingTier;
        bool unfreezed;
        bool released;
        uint256 freezingTiming;
        bool preMatureUnFreezed;
    }

    mapping(address => userFrozen[]) public userFrozensRecords;   //All frozen records of a user

    function setTradeWithFrozenTopiaAllowed(address user, bool _tradeWithFrozenTopiaAllowed ) public onlyOwner returns(bool)
    {
        tradeWithFrozenTopiaAllowed[user] = _tradeWithFrozenTopiaAllowed;
        return true;
    }

    function setForceUnfreezeComission(uint256 _forceUnfreezeComission ) public onlyOwner returns(bool)
    {
        forceUnfreezeComission = _forceUnfreezeComission;
        return true;
    }


    function setTopiaTokenContractAddress(address _topiaTokenContractAddress ) public onlyOwner returns(bool)
    {
        topiaTokenContractAddress = _topiaTokenContractAddress;
        return true;
    }



    function updateDividendContract(address _newAddress) public onlyOwner returns(string){
        //we dont want to check input address against 0x0 as owner might decided to use address 0x0 to halt operation
        dividendContractAddress = _newAddress;
        return "Dividend contract address updated";
    }



    /**
        Function to change Freeze Tier Duration
    */
    function changeFreezeTiersDuration(uint256 tier1, uint256 tier2) public onlyOwner returns(string){
        
        durationFreezeTier1 = tier1;
        durationFreezeTier2 = tier2;
        
        return "Freeze Tier Duration Updated Successfully";
    }

    //Calculate percent and return result
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
        require(interfaceTOKEN(topiaTokenContractAddress).transferFrom(caller,address(this), amountToFreeze),"ERC20 'transferFrom' call failed");
        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        //we want this current call to complete if we return true from outstandingDivWithdrawFreeze, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawFreeze(caller), 'Outstanding div withdraw failed');
             
        userFrozen memory temp;
        temp.freezingAmount = amountToFreeze;
        temp.freezingTiming = now;
        temp.freezingTier = freezingTier;
        userFrozensRecords[caller].push(temp);
        if (freezingTier == 0)
        {    
            totalFrozenTopiaInBronze += amountToFreeze;
        }
        else if (freezingTier == 1)
        {
           totalFrozenTopiaInSilver += amountToFreeze; 
        }
        else if (freezingTier == 2)
        {
           totalFrozenTopiaInGold += amountToFreeze; 
        }
        emit freezeTopiaEv(now, caller, amountToFreeze, freezingTier, userFrozensRecords[caller].length - 1 );
        return(true);
    }


    event unfreezeTopiaEv(uint256 thisTime,address caller,uint256 freezingIndex);
    function unfreezeTopia(uint256 freezingIndex, bool forceUnfreeze) public returns (bool)
    {
        address caller = msg.sender;
        require( freezingIndex < userFrozensRecords[caller].length, "invalid freezing index" );
        require(!userFrozensRecords[caller][freezingIndex].unfreezed,"already unfreezed" );

        //we want this current call to complete if we return true from outstandingDivWithdrawUnfreeze, otherwise revert.
        require(InterfaceDIVIDEND(dividendContractAddress).outstandingDivWithdrawUnfreeze(caller), 'Outstanding div withdraw failed');

        uint256 freezingTier = userFrozensRecords[caller][freezingIndex].freezingTier;
        uint256 amountToUnFreeze = userFrozensRecords[caller][freezingIndex].freezingAmount;
        if (! forceUnfreeze)
        {
            if (freezingTier == 0 )
            {
                require(now - userFrozensRecords[caller][freezingIndex].freezingTiming >= 86400 , "can not unfreeze before 24 Hr.");
                totalFrozenTopiaInBronze -= amountToUnFreeze;
            }
            else if (freezingTier == 1)
            {
                require(now - userFrozensRecords[caller][freezingIndex].freezingTiming >= durationFreezeTier1 , "can not unfreeze before time");
            totalFrozenTopiaInSilver -= amountToUnFreeze; 
            }
            else if (freezingTier == 2)
            {
                require(now - userFrozensRecords[caller][freezingIndex].freezingTiming >= durationFreezeTier2 , "can not unfreeze before time");
                totalFrozenTopiaInGold -= amountToUnFreeze; 
            }
        }
        else
        {
            if (freezingTier == 0)
            {
                totalFrozenTopiaInBronze -= amountToUnFreeze;
                userFrozensRecords[caller][freezingIndex].preMatureUnFreezed = true;
            }
            else if (freezingTier == 1)
            {
                totalFrozenTopiaInSilver -= amountToUnFreeze;
                userFrozensRecords[caller][freezingIndex].preMatureUnFreezed = true;
            }
            else if (freezingTier == 2)
            {
                totalFrozenTopiaInGold -= amountToUnFreeze;
                userFrozensRecords[caller][freezingIndex].preMatureUnFreezed = true;
            }               
        }
        userFrozensRecords[caller][freezingIndex].freezingTiming = now;
        userFrozensRecords[caller][freezingIndex].unfreezed = true;
        emit unfreezeTopiaEv(now,caller,freezingIndex);
        return true;
    }

    event releaseTopiaEv( uint256 curTime,address caller,uint256 amountToRelease,uint256 panelty);
    function releaseTopia(uint256 freezingIndex) public returns (bool)
    {
        address caller = msg.sender;
        require( freezingIndex < userFrozensRecords[caller].length, "invalid freezing index" );
        require(userFrozensRecords[caller][freezingIndex].unfreezed,"not unfreezed" );
        require(!userFrozensRecords[caller][freezingIndex].released,"already released" );
        require(now - userFrozensRecords[caller][freezingIndex].freezingTiming >= 86400 , "can not release before 24 Hr.");
        uint256 amountToRelease = userFrozensRecords[caller][freezingIndex].freezingAmount;
        uint256 panelty;
        if(userFrozensRecords[caller][freezingIndex].preMatureUnFreezed)
        {
            panelty = calculatePercentage(amountToRelease, forceUnfreezeComission);
            require(interfaceTOKEN(topiaTokenContractAddress).burn(panelty),"burning failed");
            require(interfaceTOKEN(topiaTokenContractAddress).transfer(caller,(amountToRelease.sub(panelty))),"transfer fail");
        }
        else
        {
            require(interfaceTOKEN(topiaTokenContractAddress).transfer(caller,amountToRelease),"transfer fail");
        }
        emit releaseTopiaEv( now, caller, amountToRelease, panelty);
        return true;
    }

    /*event withdrawTopiaEv (uint256 curTime,uint256 amount);
    function withdrawTopia(uint256 amount) public onlyOwner returns(bool)
    {
        uint256 totalTopia = totalFrozenTopiaInBronze + totalFrozenTopiaInSilver + totalFrozenTopiaInGold ;
        require(interfaceTOKEN(topiaTokenContractAddress).balanceOf(address(this)) - totalTopia >= amount , "Not extra topia to withdraw");
        require(interfaceTOKEN(topiaTokenContractAddress).transfer(owner,amount),"transfer fail");
        emit withdrawTopiaEv(now, amount);
        return true;
    }*/



}