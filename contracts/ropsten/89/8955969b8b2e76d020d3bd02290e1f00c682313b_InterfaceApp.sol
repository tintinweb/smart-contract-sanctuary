pragma solidity ^0.4.18;

/************************************************** */
/* WhenHub InterfaceApp Smart Contract                */
/* Author: Nik Kalyani  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dbb5b2b09bacb3beb5b3aeb9f5b8b4b6">[email&#160;protected]</a>             */
/* Copyright (c) 2018 CalendarTree, Inc.            */
/* https://interface.whenhub.com                    */
/************************************************** */

contract InterfaceApp {

    // This contract does not accept any Ether
    function() public {
        revert();
    }

    string public name = "InterfaceApp";

    // Controlling WHENToken contract (cannot be changed)
    WHENToken whenContract;

    // Interface Data contract (cannot be changed)
    InterfaceData interfaceData;

    // Fired when Instant Interface is Created
    event InterfaceStartInstant
                                (
                                    address indexed interfaceId, 
                                    address indexed expert, 
                                    uint256 perSecondRateJiffys, 
                                    uint256 minimumParticipationSeconds, 
                                    uint256 expertSuretyJiffys, 
                                    address indexed caller, 
                                    uint256 estimatedParticipationSeconds, 
                                    uint256 callerEscrowJiffys, 
                                    address referrer,
                                    uint256 referralFeeBasisPoints
                                );                                                   
    
    // Fired when Scheduled Interface is Created
    event InterfaceCreateScheduled
                                (
                                    address indexed interfaceId, 
                                    uint256 timestamp
                                );                      
    
    // Fired when Scheduled Interface is Created
    event InterfaceCreateBroadcast
                                (
                                    address indexed interfaceId, 
                                    uint256 timestamp
                                );                            


    // Fired when a new Interface is created
    event InterfaceCreate
                                (
                                    address indexed interfaceId, 
                                    uint256 timestamp, 
                                    address indexed expert, 
                                    uint256 perSecondRateJiffys, 
                                    uint256 minimumParticipationSeconds, 
                                    uint256 expertSuretyJiffys
                                );     

    // Fired when a caller is subscribed to the Interface
    event InterfaceSubscribeCaller
                                (
                                    address indexed interfaceId, 
                                    address indexed caller, 
                                    uint256 estimatedParticipationSeconds,
                                    uint256 callerEscrowJiffys, 
                                    address referrer,
                                    uint256 referralFeeBasisPoints 
                                );      

    // Fired when participant leaves Interface
    event InterfaceSettle
                                (
                                    address indexed interfaceId, 
                                    address caller, 
                                    uint256 refundJiffys,
                                    uint256 billableJiffys
                                );         

    // Fired when Instant Interface is Created                                                 
    event InterfaceFinish
                                (
                                    address indexed interfaceId, 
                                    uint256 timestamp
                                );      

    
    // Fired when a panelist is added to the Interface
    event InterfaceAddPanelist
                                (
                                    address indexed interfaceId, 
                                    address indexed panelist
                                );     

    // Fired when a panelist is removed from the Interface
    event InterfaceRemovePanelist
                                (
                                    address indexed interfaceId, 
                                    address indexed panelist
                                );                                

    // Fired when a caller is unsubscribed to the Interface     
    event InterfaceUnsubscribeCaller
                                (
                                    address indexed interfaceId, 
                                    address indexed caller, 
                                    uint256 refundEscrowJiffys
                                );                               
  
    // Fired when a caller is extending on an Interface     
    event InterfaceExtendCaller
                                (
                                    address indexed interfaceId, 
                                    address indexed caller, 
                                    uint256 additionalParticipationSeconds,
                                    uint256 callerEscrowJiffys
                                );                               

    // Fired when Interface is Canceled
    event InterfaceVoid     
                                (
                                    address indexed interfaceId, 
                                    address indexed caller, 
                                    uint256 refundEscrowJiffys
                                );         
                                             
   
    /**
    * @dev Constructor
    */
    function InterfaceApp
                                (
                                    address whenTokenContract,
                                    address interfaceDataContract
                                ) 
                                public
    {
        whenContract = WHENToken(whenTokenContract);
        interfaceData = InterfaceData(interfaceDataContract);
    }

    modifier requireIsOperational() 
    {
        require(whenContract.isOperational());
        _;
    }

    modifier requireIsPlatformManager()
    {
        require(whenContract.isPlatformManager(msg.sender));
        _;
    }

    modifier requireIsPlatformOrSupportManager() 
    {
        require(whenContract.isPlatformOrSupportManager(msg.sender));
        _;
    }

    function initialize
                                (
                                    address whenTokenContract,
                                    address interfaceDataContract
                                ) 
                                public
                                requireIsPlatformManager 
    {
        require(whenTokenContract != address(0));
        require(interfaceDataContract != address(0));

        whenContract = WHENToken(whenTokenContract);
        interfaceData = InterfaceData(interfaceDataContract);
    }

    /**
    * @dev Create an Instant Interface
    *
    * @param interfaceId Unique identifier (address) of transaction 
    * @param expert Address of Expert hosting the Interface
    * @param perSecondRateJiffys Expert&#39;s per second rate in Jiffys
    * @param minimumParticipationSeconds Minimum contract duration in seconds
    * @param expertSuretyJiffys Surety that will be put in escrow
    * @param caller Address of optional Caller joining the Interface
    * @param estimatedParticipationSeconds Duration for which the Caller has approved the Interface in seconds
    * @param referrer Referring WhenSense source
    * @param referralFeeBasisPoints Referral fee in basis points
    */    
    function startInstantInterface
                                (
                                    address interfaceId,
                                    address expert,
                                    uint256 perSecondRateJiffys,
                                    uint256 minimumParticipationSeconds,
                                    uint256 expertSuretyJiffys,
                                    address caller,
                                    uint256 estimatedParticipationSeconds,
                                    address referrer,
                                    uint256 referralFeeBasisPoints
                                ) 
                                external 
                                requireIsOperational
                                requireIsPlatformManager 
    {
        
        address id;
        uint256 createTimestamp;
        (id, createTimestamp) = interfaceData.create(
                                                        interfaceId,
                                                        expert,
                                                        perSecondRateJiffys,
                                                        minimumParticipationSeconds,
                                                        expertSuretyJiffys,
                                                        0
                                                    );

        InterfaceCreate(
                                id, 
                                createTimestamp, 
                                expert, 
                                perSecondRateJiffys, 
                                minimumParticipationSeconds, 
                                expertSuretyJiffys
                            );

        uint256 callerEscrowJiffys = interfaceData.subscribeCaller(
                                                                        interfaceId,
                                                                        caller,
                                                                        estimatedParticipationSeconds,
                                                                        referrer,
                                                                        referralFeeBasisPoints
                                                                    ); 


        // Fire event for subscribing caller to Interface
        InterfaceSubscribeCaller(
                                        id, 
                                        caller, 
                                        estimatedParticipationSeconds,
                                        callerEscrowJiffys, 
                                        referrer,
                                        referralFeeBasisPoints
                                    );      

        //Fire event for Interface creation
        InterfaceStartInstant(
                                        id, 
                                        expert, 
                                        perSecondRateJiffys, 
                                        minimumParticipationSeconds, 
                                        expertSuretyJiffys, 
                                        caller, 
                                        estimatedParticipationSeconds, 
                                        callerEscrowJiffys, 
                                        referrer,
                                        referralFeeBasisPoints
                                ); 

    }

  
    function extendCaller
                                (
                                    address interfaceId, 
                                    address caller, 
                                    uint256 additionalParticipationSeconds
                                ) 
                                external
                                requireIsOperational
                                requireIsPlatformOrSupportManager 
    {
        uint256 callerEscrowJiffys = interfaceData.extendCaller(interfaceId, caller, additionalParticipationSeconds);

        // Fire event for extending caller on Interface
        InterfaceExtendCaller(
                                        interfaceId, 
                                        caller, 
                                        additionalParticipationSeconds,
                                        callerEscrowJiffys
                                    );      

    }

    function settleCaller
                                (
                                    address interfaceId, 
                                    address caller, 
                                    uint256 billableSeconds
                                ) 
                                external
                                requireIsOperational
                                requireIsPlatformOrSupportManager 
    {

        uint256 refundJiffys;
        uint256 billedJiffys;
        uint256 finishTimestamp;
        (refundJiffys, billedJiffys, finishTimestamp) = interfaceData.settleCaller(interfaceId, caller, billableSeconds);

        InterfaceSettle(
                                interfaceId, 
                                caller, 
                                refundJiffys,
                                billedJiffys
                            );         

        if (finishTimestamp > 0) { // finishTimestamp
            InterfaceFinish(
                                    interfaceId,
                                    finishTimestamp
                                );
        }
    } 


    function voidCaller
                                (
                                    address interfaceId, 
                                    address caller
                                ) 
                                external 
                                requireIsOperational
                                requireIsPlatformOrSupportManager 
    {
       
        uint256 refundEscrowJiffys;
        uint256 finishTimestamp;
        (refundEscrowJiffys, finishTimestamp) = interfaceData.voidCaller(interfaceId, caller);

        InterfaceVoid(
                        interfaceId, 
                        caller, 
                        refundEscrowJiffys
                    );         

        if (finishTimestamp > 0) {
            InterfaceFinish(
                                    interfaceId,
                                    finishTimestamp
                                );
        }

    }

}

contract WHENToken {

    function isOperational() public view returns(bool);
    function isPlatformManager(address) public view returns(bool);
    function isPlatformOrSupportManager(address) public view returns(bool);
    
}

contract InterfaceData {

    function create(address interfaceId, address expert, uint256 perSecondRateJiffys, uint256 minimumParticipationSeconds, uint256 escrowJiffys, uint256 startTimestamp) external returns (address, uint256); 
    function subscribeCaller(address interfaceId, address caller, uint256 estimatedParticipationSeconds, address referrer, uint256 referralFeeBasisPoints) external returns(uint256);
    function extendCaller(address interfaceId, address caller, uint256 additionalParticipationSeconds) external returns(uint256);
    function settleCaller(address interfaceId, address caller, uint256 billableSeconds) external returns(uint256, uint256, uint256);
    function voidCaller(address interfaceId, address caller) external returns(uint256, uint256);

}