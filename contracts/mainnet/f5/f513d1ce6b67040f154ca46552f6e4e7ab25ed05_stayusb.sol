pragma solidity ^0.6.12;

import "./owned.sol";
import "./mathlib.sol";
import "./interfaces.sol";


enum reservationstatus {CANCELLED, ACTIVATED, COMPLETED}


contract ReservationFactory is owned
{
    /*
        1) The Reservation Factory contract to create and manage reservations
	    2) Only the Reservation Factory is owned by the manager
	    3) The manager has no control over each reservation or the cumulative advance payment locked in the Factory contract
    */
    
    address constant private dai_ = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    DaiErc20 constant private daiToken  = DaiErc20(dai_);

    //Reservation Fee in wad payed to the manager to create a reservation
    uint public reservationfee;
    
    uint constant private secondsinday = 86400;
    uint constant private secondsin21hrs = 75600;
    
    //Switch that controls whether the factory is active
    bool public factorycontractactive;
    
    uint private reservationid;
    
    uint constant private maxuint = 2**256-1;
    
    struct Reservation 
    {
        address guest;
        address host;
        uint reservationstart;
        uint reservationend;
        uint dailyprice;
        uint advancepayment;
        reservationstatus rstatus;
    }
    
    mapping (bytes32 => Reservation) public Reservations;
    
    //Event for new Reservation
    event NewReservationEvent(bytes32 indexed rsvid, address indexed guest, address indexed host, uint rstart, uint rend, uint dprice, uint advpay, bytes8 rstartformat, bytes8 rendformat, uint eventtime);
    
    //Reservation Status Change Event
    event ReservationStatusEvent(bytes32 indexed rsvid, reservationstatus rstatus, uint rbalance, uint eventtime);

    constructor() public 
	{
	    reservationid =0;
	    reservationfee = 1000000000000000000; //1 DAI
		factorycontractactive = true;
	}


    function setReservationFee(uint newfee) external onlyManager
    {
        /*
            1) Changes the Reservation fee that is paid to the manager
            2) The Reservation fee at launch of contract is set to 1 DAI
	        3) The reservationfee is a public variable and can always queried	
        */
        
        require(newfee > 0);
        
        reservationfee = newfee;
    }
    

    function setFactoryContractSwitch() external onlyManager
    {
        /*
            1) Switch that controls whether the contract is active
	        2) If the contract is paused new reservations can not be created, but existing reservations can still be completed.
        */
        
        factorycontractactive = factorycontractactive == true ? false : true;
    }
    

    function createnewReservation(address host, uint reservationstart, uint reservationend, uint dailyprice, uint advancepayment , bytes8 rstartformat, bytes8 rendformat) external 
    {
        /*
            Will Create a new reservation between guest and host
        */
        
        require(factorycontractactive, "Factory Contract should be Active");
        require(reservationid < maxuint, "Maximum reservationid reached");
        require(msg.sender != host,"Host and Guest can not be same");
        require(dailyprice > 0, "Daily Price should be > 0");
        
        require(now < mathlib.add(reservationstart,secondsin21hrs),"Too late to start this reservation");
        
        uint lengthofstay = mathlib.calculatereservationdays(reservationstart,reservationend);
        
        require(lengthofstay > 0,"Length of Stay should be > 0");
        
        uint totalreservationamount = mathlib.mul(dailyprice,lengthofstay);
        
        uint minadvpayment = lengthofstay > 5 ? mathlib.mul(dailyprice,2) : dailyprice;
        
        require(advancepayment >= minadvpayment && advancepayment <= totalreservationamount ,"Advance Payment should be >= minadvpayment and <= reservation amount ");
        
        //Check daitoken allowance for Factory contract
        require(daiToken.allowance(msg.sender,address(this)) >= mathlib.add(advancepayment, reservationfee), "daiToken allowance exceeded");
        
        bytes32 rsvid = keccak256(abi.encodePacked(reservationid));
        
        Reservations[rsvid] = Reservation(msg.sender, host, reservationstart, reservationend, dailyprice, advancepayment, reservationstatus.ACTIVATED);
        
        reservationid = mathlib.add(reservationid,1);
        
        //Transfer the advance payment to this contract
        daiToken.transferFrom(msg.sender, address(this), advancepayment);
        
        //Transfer the reservation fee to factory manager
        daiToken.transferFrom(msg.sender, manager, reservationfee);

        emit NewReservationEvent(rsvid, msg.sender, host, reservationstart, reservationend, dailyprice, advancepayment, rstartformat, rendformat, now);
        
    }
    
     modifier onlyGuest(bytes32 rsvid)
    {
        require(msg.sender == Reservations[rsvid].guest, "Only Guest");
        _;
    }
    
    modifier onlyHost(bytes32 rsvid)
    {
        require(msg.sender == Reservations[rsvid].host, "Only Host");
        _;
    }
    
     function getReservationDetails(bytes32 rsvid) external view returns (reservationstatus, uint)
    {
    	/*
    	   Will get the changing variables for each reservation based on reservation ID	
    	*/

        Reservation memory thisreservation = Reservations[rsvid];
        
        require(thisreservation.guest !=address(0),"Reservation does not exist");
        
        return(thisreservation.rstatus, thisreservation.advancepayment);
    }
    
   
    function setHostCancelsReservation(bytes32 rsvid) external onlyHost(rsvid)
    {
        /*
            1) Allows the host to cancel the reservation upto 21 Hrs after reservation start if ACTIVATED
            2) Guest gets a Full Refund Instantly, since the Host is cancelling
        */
        
        Reservation storage thisreservation = Reservations[rsvid];
        
        require(thisreservation.rstatus == reservationstatus.ACTIVATED,"Reservation must be ACTIVATED");
        
        uint reservationstart21Hrs = mathlib.add(thisreservation.reservationstart,secondsin21hrs);
        
        require(now < reservationstart21Hrs,"Reservation Can be CANCELLED upto 21 Hrs after reservation start");
        
        uint rsvbalance = thisreservation.advancepayment;
        
        thisreservation.advancepayment = 0;
        thisreservation.rstatus = reservationstatus.CANCELLED;
        
	    //Guest is refunded the entire advance payment balance
        daiToken.transfer(thisreservation.guest, rsvbalance);
        
        emit ReservationStatusEvent(rsvid, thisreservation.rstatus, thisreservation.advancepayment, now);
    }
    
     function setGuestCancelReservation(bytes32 rsvid) external onlyGuest(rsvid)
    {
        /*
            1) Guest can cancel the reservation upto 21 Hrs after reservation start if ACTIVATED
            2) If length of stay is 5 days or less, cancel upto 3 days before reservation start, otherwise a cancellation fee of dailyprice is applied
            3) If length of stay is greater than 5 days, cancel upto 5 days before reservation start, otherwise a cancellation fee of 2*dailyprice is applied
        */
        
        Reservation storage thisreservation = Reservations[rsvid];
        
        require(thisreservation.rstatus == reservationstatus.ACTIVATED,"Reservation must be ACTIVATED");
        
        uint reservationstart21Hrs = mathlib.add(thisreservation.reservationstart,secondsin21hrs);
            
        require(now < reservationstart21Hrs,"Guest can only cancel upto 21 Hrs after reservation start");
        
        uint lengthofstay = mathlib.calculatereservationdays(thisreservation.reservationstart,thisreservation.reservationend); 
            
        uint cancellationperiod = lengthofstay > 5 ? 5 : 3;
        
        uint rsvbalance = thisreservation.advancepayment;
        
        thisreservation.advancepayment = 0;
        thisreservation.rstatus = reservationstatus.CANCELLED;
            
            if (now < mathlib.sub(thisreservation.reservationstart,mathlib.mul(cancellationperiod,secondsinday)))
            {
                daiToken.transfer(thisreservation.guest,rsvbalance);
            }
            else
            {
                uint cancellationfee = lengthofstay > 5 ? mathlib.mul(thisreservation.dailyprice,2) : thisreservation.dailyprice;
                
                uint guestdue = mathlib.sub(rsvbalance,cancellationfee);
                
                //Host gets compensated for cancellation    
                 daiToken.transfer(thisreservation.host,cancellationfee);
                 
                 //Guest gets refunded the remaining balance
                 if (guestdue > 0)
                 {
                    daiToken.transfer(thisreservation.guest,guestdue);
                 }
            }
        
         emit ReservationStatusEvent(rsvid, thisreservation.rstatus, thisreservation.advancepayment, now);
    }
    
    
     function setHostClaimsRent(bytes32 rsvid) external onlyHost(rsvid)
    {
        /*
            Host can claim the rent 21 Hrs after reservation start
        */
        
        Reservation storage thisreservation = Reservations[rsvid];
        
        require(thisreservation.rstatus == reservationstatus.ACTIVATED,"Reservation must be ACTIVATED");
        
        uint reservationstart21Hrs = mathlib.add(thisreservation.reservationstart,secondsin21hrs);
            
        require(now >= reservationstart21Hrs,"Host can only claim the rent 21 Hrs after reservation start");
        
        uint rsvbalance = thisreservation.advancepayment;
        
        thisreservation.advancepayment = 0;
        thisreservation.rstatus = reservationstatus.COMPLETED;
        
        //Host claims the entire advance payment balance
         daiToken.transfer(thisreservation.host,rsvbalance);
         
        emit ReservationStatusEvent(rsvid, thisreservation.rstatus, thisreservation.advancepayment, now);
    }
    
    
     function setHostRefundsPartRent(bytes32 rsvid, uint refundamount) external onlyHost(rsvid)
    {
        /*
            1) Host can refund the Guest a part or full amount 21 Hrs after reservation start
            2) The remaining balance if any will be transferred to the Host. 
        */
        
        Reservation storage thisreservation = Reservations[rsvid];
        
        require(thisreservation.rstatus == reservationstatus.ACTIVATED, "Reservation has to be ACTIVATED");
        
        uint reservationstart21Hrs = mathlib.add(thisreservation.reservationstart,secondsin21hrs);
        
        require(now >= reservationstart21Hrs, "Host can refund part of contract balance 21 Hrs after Reservation Start");
        
        uint rsvbalance = thisreservation.advancepayment;
        
        require(refundamount > 0 && refundamount <= rsvbalance, "Refund amount should be > 0 && <= rsvbalance");
        
        uint hostdue = mathlib.sub(rsvbalance,refundamount);
        
        thisreservation.advancepayment = 0;
        thisreservation.rstatus = reservationstatus.COMPLETED;
        
        //The refund amount is transferred to the guest
        daiToken.transfer(thisreservation.guest,refundamount);
        
        //The remaining amount is transferred to the Host
        if (hostdue > 0)
        {
            daiToken.transfer(thisreservation.host,hostdue);
        }
        
        emit ReservationStatusEvent(rsvid, thisreservation.rstatus, thisreservation.advancepayment, now);
    }
    
}























