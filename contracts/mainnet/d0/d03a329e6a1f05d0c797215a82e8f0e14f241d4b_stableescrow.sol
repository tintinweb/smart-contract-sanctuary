pragma solidity ^0.6.12;

import "./owned.sol";
import "./mathlib.sol";
import "./interfaces.sol";

enum escrowstatus {CANCELLED, ACTIVATED, SETTLED}

contract EscrowFactory is owned
{
    /*
            1) The Escrow Factory contract to create and manage Escrows
	        2) Only the Escrow Factory is owned by the manager
	        3) The manager has no control over each Escrow or the cumulative payment locked in the Factory contract
    */
    
    address constant private dai_ = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    DaiErc20 constant private daiToken = DaiErc20(dai_);

    //Escrow Fee in wad payed to the manager to create a Escrow
    uint public escrowfee;
    
    //Switch that controls whether the factory is active
    bool public factorycontractactive;
    
    uint private escrowid;
    
    uint constant private maxuint = 2**256-1;
    
    struct Escrow 
    {
        address escrowpayer;
        address escrowpayee;
        uint escrowamount;
        uint escrowsettlementamount;
        escrowstatus estatus;
        address escrowmoderator;
        uint escrowmoderatorfee;
    }
    
    mapping (bytes32 => Escrow) public Escrows;
    
    
    /** Events **/

    //Event for new Escrow Contract
    event NewEscrowEvent(bytes32 esid, address indexed escrowpayer, address indexed escrowpayee, uint escrowamount, uint eventtime);
    
    //Event overload with moderator
    event NewEscrowEvent(bytes32 esid, address indexed escrowpayer, address indexed escrowpayee, uint escrowamount, address indexed escrowmoderator, 
    uint escrowmoderatorfee,  uint eventtime);
    
    //The Escrowid is indexed
    event NewEscrowEventById(bytes32 indexed esid, address escrowpayer, address escrowpayee, uint escrowamount, uint eventtime);
    
    //The Escrowid is indexed overload for moderator
    event NewEscrowEventById(bytes32 indexed esid, address escrowpayer, address escrowpayee,  uint escrowamount, address escrowmoderator, 
    uint escrowmoderatorfee, uint eventtime);
    
    //Escrow Status Change Event
    event EscrowStatusEvent(bytes32 indexed esid, escrowstatus estatus, uint escrowsettlementamount, uint eventtime);
    
    constructor() public 
	{
		escrowid = 0;
	    escrowfee = 1000000000000000000; //1 DAI
		factorycontractactive = true;
	}


    function setEscrowFee(uint newfee) external onlyManager
    {
        /*
            	1) Changes the Escrow fee that is paid to the manager
            	2) The Escrow fee at launch of contract is set to 1 DAI
	            3) The escrowfee is a public variable and can always queried	
        */
        
        require(newfee > 0);
        
        escrowfee = newfee;
    }
    

    function setFactoryContractSwitch() external onlyManager
    {
        /*
            	1) Switch that controls whether the contract is active
	            2) If the contract is paused new Escrows can not be created, but existing Escrows can still be Settled.
        */
        
        factorycontractactive = factorycontractactive == true ? false : true;
    }
    
  
    //create new escrow
    function createNewEscrow(address escrowpayee, uint escrowamount) external 
    {
        
        require(factorycontractactive, "Factory Contract should be Active");
        require(escrowid < maxuint, "Maximum escrowid reached");
        require(msg.sender != escrowpayee,"The Payer, payee should be different");
        require(escrowpayee != address(0),"The Escrow Payee can not be address(0)");
        require(escrowamount > 0,"Escrow amount has to be greater than 0");
        
        require(daiToken.allowance(msg.sender,address(this)) >= mathlib.add(escrowamount, escrowfee), "daiToken allowance exceeded");
        
        bytes32 esid = keccak256(abi.encodePacked(escrowid));
        
        Escrows[esid] = Escrow({escrowpayer:msg.sender, escrowpayee:escrowpayee, escrowamount:escrowamount,
            escrowsettlementamount:escrowamount, estatus:escrowstatus.ACTIVATED,escrowmoderator:address(0),escrowmoderatorfee:0});
        
        escrowid = mathlib.add(escrowid,1);
        
        //The Esrow Amount gets transferred to factory contract
        daiToken.transferFrom(msg.sender, address(this), escrowamount);
        
        //Transfer the escrow fee to factory manager
        daiToken.transferFrom(msg.sender, manager, escrowfee);
        
        emit NewEscrowEvent(esid, msg.sender, escrowpayee, escrowamount, now);
        
        emit NewEscrowEventById(esid, msg.sender, escrowpayee, escrowamount, now);
        
    }
    
     //create new escrow overload
    function createNewEscrow(address escrowpayee, uint escrowamount, address escrowmoderator, uint escrowmoderatorfee) external 
    {
        
        require(factorycontractactive, "Factory Contract should be Active");
        require(escrowid < maxuint, "Maximum escrowid reached");
        require(msg.sender != escrowpayee && msg.sender != escrowmoderator && escrowpayee != escrowmoderator,"The Payer, payee & moderator should be different");
        require(escrowpayee != address(0) && escrowmoderator!=address(0),"Escrow Payee or moderator can not be address(0)");
        require(escrowamount > 0,"Escrow amount has to be greater than 0");
    
        uint dailockedinnewescrow = mathlib.add(escrowamount,escrowmoderatorfee);
  
        require(daiToken.allowance(msg.sender,address(this)) >= mathlib.add(dailockedinnewescrow, escrowfee), "daiToken allowance exceeded");
        
        bytes32 esid = keccak256(abi.encodePacked(escrowid));
        
        Escrows[esid] = Escrows[esid] = Escrow({escrowpayer:msg.sender, escrowpayee:escrowpayee, escrowamount:escrowamount,
            escrowsettlementamount:escrowamount, estatus:escrowstatus.ACTIVATED,escrowmoderator:escrowmoderator,escrowmoderatorfee:escrowmoderatorfee});
        
        escrowid = mathlib.add(escrowid,1);
        
        //The Esrow Amount and Moderator fee gets transferred to factory contract
        daiToken.transferFrom(msg.sender, address(this), dailockedinnewescrow);
        
        //Transfer the escrow fee to factory manager
        daiToken.transferFrom(msg.sender, manager, escrowfee);
        
        emit NewEscrowEvent(esid, msg.sender, escrowpayee, escrowamount, escrowmoderator, escrowmoderatorfee ,now);
        
        emit NewEscrowEventById(esid, msg.sender, escrowpayee, escrowamount, escrowmoderator, escrowmoderatorfee, now);
        
    }
    
    modifier onlyPayerOrModerator(bytes32 esid)
    {
        require(msg.sender == Escrows[esid].escrowpayer || msg.sender == Escrows[esid].escrowmoderator, "Only Payer or Moderator");
        _;
    }
    
    modifier onlyPayeeOrModerator(bytes32 esid)
    {
        require(msg.sender == Escrows[esid].escrowpayee || msg.sender == Escrows[esid].escrowmoderator, "Only Payee or Moderator");
        _;
    }
    
    function getEscrowDetails(bytes32 esid) external view returns (escrowstatus, uint)
    {
        /*
            Gets the changing variables of a escrow based on escrowid
        */
        
        Escrow memory thisescrow = Escrows[esid];
        
        require(thisescrow.escrowpayee !=address(0),"Escrow does not exist");
        
        return(thisescrow.estatus, thisescrow.escrowsettlementamount);
    }
    
 
     function setEscrowSettlementAmount(bytes32 esid, uint esettlementamount) external onlyPayeeOrModerator(esid)
    {
        /*
            Only the escrow Payee or Moderator can change the escrow settlement amount to less than or equal to the original escrowamount
        */
        
        Escrow storage thisescrow = Escrows[esid];
        
        require(thisescrow.estatus == escrowstatus.ACTIVATED,"Escrow should be Activated");
        require(esettlementamount > 0 && esettlementamount <= thisescrow.escrowamount ,"escrow settlementamount is incorrect");
        
        thisescrow.escrowsettlementamount = esettlementamount;
        
        emit EscrowStatusEvent(esid, thisescrow.estatus, thisescrow.escrowsettlementamount,now);
    }
    
     function releaseFundsToPayee(bytes32 esid) external onlyPayerOrModerator(esid)
    {
        /*
            1) The payee gets paid the escrow settlement amount
            2) The moderator gets paid the moderation fee if exists
            3) Any remaining amount is transferred to the Payer
        */
        
        Escrow storage thisescrow = Escrows[esid];
        
        require(thisescrow.estatus == escrowstatus.ACTIVATED, "Escrow Should be activated");
        
        require(thisescrow.escrowsettlementamount > 0, "Escrow Settlement amount is 0");
    
        uint payeramt = thisescrow.escrowamount > thisescrow.escrowsettlementamount ? mathlib.sub(thisescrow.escrowamount,thisescrow.escrowsettlementamount) : 0;
        
        uint settlementamount = thisescrow.escrowsettlementamount;
        thisescrow.escrowsettlementamount = 0;
        thisescrow.estatus = escrowstatus.SETTLED;
        
        //Payee gets paid
        daiToken.transfer(thisescrow.escrowpayee,settlementamount);
        
        //Moderator gets paid if exists
        if (thisescrow.escrowmoderatorfee > 0)
        {
            daiToken.transfer(thisescrow.escrowmoderator,thisescrow.escrowmoderatorfee);
        }
        
        //Payer gets paid any remaining balance
        if (payeramt > 0)
        {
            daiToken.transfer(thisescrow.escrowpayer,payeramt);
        }
        
        emit EscrowStatusEvent(esid, thisescrow.estatus, thisescrow.escrowsettlementamount,now);
    
    }
    
    function cancelEscrow(bytes32 esid) external onlyPayeeOrModerator(esid)
    {
        /*
             1) The payer gets refunded the full escrow amount
             2) The moderator gets paid the moderation fee if exists
        */
        
        Escrow storage thisescrow = Escrows[esid];
        
        require(thisescrow.estatus == escrowstatus.ACTIVATED, "Escrow Should be activated");
        
        require(thisescrow.escrowamount == thisescrow.escrowsettlementamount,"Escrow amount and Escrow settlement amount should be equal");
        
        uint settlementamount = thisescrow.escrowsettlementamount;
        thisescrow.escrowsettlementamount = 0;
        thisescrow.estatus = escrowstatus.CANCELLED;
        
        //Moderator gets paid if exists
        if (thisescrow.escrowmoderatorfee > 0)
        {
            daiToken.transfer(thisescrow.escrowmoderator,thisescrow.escrowmoderatorfee);
        }
        
        //Payer gets full refund
        daiToken.transfer(thisescrow.escrowpayer,settlementamount);
        
        emit EscrowStatusEvent(esid, thisescrow.estatus, thisescrow.escrowsettlementamount,now);
    }
    
}





















