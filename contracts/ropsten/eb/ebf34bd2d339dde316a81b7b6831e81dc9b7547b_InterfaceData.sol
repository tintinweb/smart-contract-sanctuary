pragma solidity ^0.4.18;

/************************************************** */
/* WhenHub InterfaceData Smart Contract                */
/* Author: Nik Kalyani  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="49272022093e212c27213c2b672a2624">[email&#160;protected]</a>             */
/* Copyright (c) 2018 CalendarTree, Inc.            */
/* https://interface.whenhub.com                    */
/************************************************** */

contract InterfaceData {
    using SafeMath for uint256;

    // This contract does not accept any Ether
    function() public {
        revert();
    }

    string public name = "InterfaceData";

    enum InterfaceState { Created, Started, Finished }
    enum CallerType { Expert, Panelist, Consumer }
    enum ParticipationState { Registered, Settled, Voided }

    // Interface participant; can be Expert, Panelist or Consumer
    struct Caller {
        bool isCaller;
        CallerType callerType;
        ParticipationState participationState;
        uint256 escrowJiffys;
        uint256 estimatedParticipationSeconds;
        uint256 billableSeconds;
        address referrer;
        uint256 referralFeeBasisPoints;
    }

    // All data for a single Interface
    struct Interface {
        bool isCreated;
        address creator;
        address expert;
        InterfaceState state;
        uint256 perSecondRateJiffys;
        uint256 minimumParticipationSeconds;
        uint256 createTimestamp;
        uint256 startTimestamp;
        uint256 finishTimestamp;
        uint256 registeredCallerCount;
        uint256 settledCallerCount;
        uint256 voidedCallerCount;
        mapping(address => Caller) callers;
    }

    // Controlling WHENToken contract (cannot be changed)
    WHENToken whenContract;

    // All active or scheduled Interface calls
    mapping(address => Interface) interfaces;                                                                    

    /**
    * @dev Constructor
    */
    function InterfaceData
                                (
                                    address whenTokenContract
                                ) 
                                public 
    {
        whenContract = WHENToken(whenTokenContract);
    }

    modifier requireIsOperational() 
    {
        require(whenContract.isOperational());
        _;
    }

    modifier requireIsCallingContractAuthorized() 
    {
        require(whenContract.isContractAuthorized(msg.sender));
        _;
    }


    function create
                            (
                                address id,
                                address expert,
                                uint256 perSecondRateJiffys,
                                uint256 minimumParticipationSeconds,
                                uint256 escrowJiffys,
                                uint256 startTimestamp                                    
                            ) 
                            public 
                            requireIsOperational
                            requireIsCallingContractAuthorized
                     
                            returns (
                                        address,
                                        uint256
                                    )
    {
        address interfaceId = id;
        if (interfaceId == address(0)) {
            interfaceId = getUniqueId();
        }

        require(!interfaces[interfaceId].isCreated);

        // Data range validation
        require(perSecondRateJiffys >= 0);                    
        require(minimumParticipationSeconds > 0); 
        require(escrowJiffys >= 0);
        require(whenContract.isUserRegistered(expert));


        // Create the Interface 
        interfaces[interfaceId] = Interface({ 
                                                isCreated: true, 
                                                creator: msg.sender,
                                                expert: expert,
                                                state: startTimestamp <= now ? InterfaceState.Started : InterfaceState.Created, 
                                                perSecondRateJiffys: perSecondRateJiffys, 
                                                minimumParticipationSeconds: minimumParticipationSeconds, 
                                                createTimestamp: now, 
                                                startTimestamp: startTimestamp == 0 ? now : startTimestamp,
                                                finishTimestamp: 0,
                                                registeredCallerCount: 1,
                                                settledCallerCount: 0,
                                                voidedCallerCount: 0
                                            });  

        interfaces[interfaceId].callers[expert] = Caller({
                                                            isCaller: true, 
                                                            callerType: CallerType.Expert,
                                                            participationState: ParticipationState.Registered,
                                                            escrowJiffys: escrowJiffys, 
                                                            estimatedParticipationSeconds: 0,
                                                            billableSeconds: 0,
                                                            referrer: address(0),
                                                            referralFeeBasisPoints: 0
                                                        });    

        // depositEscrow will require() the caller to have enough spendableBalance
        // This is good because we don&#39;t want the call to start if either party has
        // fewer funds than required for depositing into escrow

        if (escrowJiffys > 0) {
            whenContract.depositEscrow(expert, escrowJiffys);  
        }

        return (
                    interfaceId,
                    interfaces[interfaceId].createTimestamp
                );  
    }


  /**
    * @dev Generate a unique ID that looks like an Ethereum address
    *
    * Sample: 0xf4a8f74879182ff2a07468508bec89e1e7464027		          
    */  
    function getUniqueId() internal view returns (address) 
    {

        bytes20 b = bytes20(keccak256(msg.sender, now));
        uint addr = 0;
        for (uint index = b.length-1; index+1 > 0; index--) {
            addr += uint(b[index]) * ( 16 ** ((b.length - index - 1) * 2));
        }

        return address(addr);
    }

    function settleCaller
                                (
                                    address interfaceId, 
                                    address caller, 
                                    uint256 billableSeconds
                                ) 
                                external
                                requireIsOperational
                                requireIsCallingContractAuthorized
                                returns (uint256, uint256, uint256)
                        
    {

        require(interfaces[interfaceId].state == InterfaceState.Started);                
        require(whenContract.isUserRegistered(caller));
        require(interfaces[interfaceId].callers[caller].isCaller);                 
        require(interfaces[interfaceId].callers[caller].participationState == ParticipationState.Registered);
        require((interfaces[interfaceId].settledCallerCount + interfaces[interfaceId].voidedCallerCount) < interfaces[interfaceId].registeredCallerCount);

        Caller memory callerInfo = interfaces[interfaceId].callers[caller];

        if (callerInfo.callerType == CallerType.Consumer) {
            require(billableSeconds <= callerInfo.estimatedParticipationSeconds);
            require(billableSeconds >= interfaces[interfaceId].minimumParticipationSeconds);
        } else {
            require(billableSeconds >= 0);
        }

        uint256 billableJiffys = billableSeconds.mul(interfaces[interfaceId].perSecondRateJiffys);
        if (billableSeconds > 0) {
            // Limit amount to what was in Escrow
            require(billableJiffys <= callerInfo.escrowJiffys);
        }

        // Change state to prevent double spend
        interfaces[interfaceId].callers[caller].participationState = ParticipationState.Settled;
        interfaces[interfaceId].callers[caller].billableSeconds = billableSeconds;

        address payee;
        address referrer;

        if (callerInfo.callerType == CallerType.Consumer) {

            payee = interfaces[interfaceId].expert;
            referrer = callerInfo.referrer;

        } else if (callerInfo.callerType == CallerType.Expert) {

            // This is a Surety being forfeited if billableJiffys > 0, otherwise it&#39;s an escrow refund
            // Expert pays Support, then Support handles disbursing funds to appropriate parties.
            // Since the rules for forfeiture can get very complex, they are best handled off-contract
            payee = whenContract.getSupportManager();
            referrer = address(0);
        }

        whenContract.pay(
                            caller, 
                            payee, 
                            referrer, 
                            callerInfo.referralFeeBasisPoints, 
                            billableJiffys,
                            callerInfo.escrowJiffys
                        );
        interfaces[interfaceId].settledCallerCount = interfaces[interfaceId].settledCallerCount.add(1);  

        return (callerInfo.escrowJiffys, billableJiffys, tryFinishInterface(interfaceId));
    } 


    function voidCaller
                                (
                                    address interfaceId, 
                                    address caller
                                ) 
                                external 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                                returns(uint256, uint256)
    {
        require(interfaceId != address(0));

        // Must be a Caller previously added/subscribed
        require(interfaces[interfaceId].callers[caller].isCaller); 

        // Only callers who have not been settled can be voided          
        require(interfaces[interfaceId].callers[caller].participationState == ParticipationState.Registered);
        require((interfaces[interfaceId].settledCallerCount + interfaces[interfaceId].voidedCallerCount) < interfaces[interfaceId].registeredCallerCount);

        interfaces[interfaceId].callers[caller].participationState = ParticipationState.Voided;

        uint256 refundEscrowJiffys = interfaces[interfaceId].callers[caller].escrowJiffys;
        if (refundEscrowJiffys > 0) {
            interfaces[interfaceId].callers[caller].escrowJiffys = 0;
            whenContract.refundEscrow(caller, refundEscrowJiffys);
        }

        interfaces[interfaceId].voidedCallerCount = interfaces[interfaceId].voidedCallerCount.add(1);

        uint256 finishTimestamp = tryFinishInterface(interfaceId);

        return (refundEscrowJiffys, finishTimestamp);

    }

    function tryFinishInterface
                                (
                                    address interfaceId
                                ) 
                                private 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                                returns(uint256)
                        
    {

        if ((interfaces[interfaceId].settledCallerCount + interfaces[interfaceId].voidedCallerCount) == interfaces[interfaceId].registeredCallerCount) {

            interfaces[interfaceId].state = InterfaceState.Finished;                
            interfaces[interfaceId].finishTimestamp = now;             

            return interfaces[interfaceId].finishTimestamp;
        }

        return 0;
    }

    /**
    * @dev Add an Interface Panelist
    *
    * @param interfaceId Unique identifier (address) of transaction
    * @param panelist Address of Panelist joining the Interface
    */    
    function addPanelist
                                (
                                    address interfaceId, 
                                    address panelist
                                ) 
                                public 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                         
    {
        require(interfaceId != address(0));

        // Only New or Created Interfaces can have panelists added
        require(interfaces[interfaceId].state == InterfaceState.Created);
        require(whenContract.isUserRegistered(panelist));

        require(!interfaces[interfaceId].callers[panelist].isCaller);   // Can&#39;t add the same Panelist twice

        // Add Panelist to Interface
        interfaces[interfaceId].callers[panelist] = Caller({
                                                                isCaller: true, 
                                                                callerType: CallerType.Panelist,
                                                                participationState: ParticipationState.Registered,
                                                                escrowJiffys: 0, 
                                                                estimatedParticipationSeconds: 0,
                                                                referrer: address(0),
                                                                referralFeeBasisPoints: 0,
                                                                billableSeconds: 0
                                                            });            
        interfaces[interfaceId].registeredCallerCount = interfaces[interfaceId].registeredCallerCount.add(1);

    }

   function removePanelist
                                (
                                    address interfaceId, 
                                    address panelist
                                ) 
                                public 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                         
    {
        require(interfaceId != address(0));

        require(interfaces[interfaceId].state == InterfaceState.Created);       // Only New calls can have Panelists removed
        require(whenContract.isUserRegistered(panelist));

        require(interfaces[interfaceId].callers[panelist].callerType == CallerType.Panelist);

        delete interfaces[interfaceId].callers[panelist];
        interfaces[interfaceId].registeredCallerCount = interfaces[interfaceId].registeredCallerCount.sub(1);
    }


   /**
    * @dev Subscribe an Interface Caller
    *
    * @param interfaceId Unique identifier (address) of transaction 
    * @param caller Address of Caller joining the Interface
    * @param estimatedParticipationSeconds Duration for which the Caller may participate on call in seconds
    * @param referrer Referring WhenSense source
    * @param referralFeeBasisPoints Referral fee in basis points
    */    
    function subscribeCaller
                                (
                                    address interfaceId,
                                    address caller,
                                    uint256 estimatedParticipationSeconds,
                                    address referrer,
                                    uint256 referralFeeBasisPoints
                                ) 
                                public 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                         
                                returns(uint256)
    {
        require(interfaceId != address(0));

        // Only Created Interfaces can have callers subscribed
        require((interfaces[interfaceId].state == InterfaceState.Created) || (interfaces[interfaceId].state == InterfaceState.Started));
        require(whenContract.isUserRegistered(caller));

        require(!interfaces[interfaceId].callers[caller].isCaller);         // Can&#39;t add the same Caller twice

        require(estimatedParticipationSeconds >= interfaces[interfaceId].minimumParticipationSeconds);

        if (referrer != address(0)) {
            require(whenContract.isUserRegistered(referrer));
            require(referralFeeBasisPoints >= 0);
        }

        uint256 depositEscrowJiffys = 0;
        if (interfaces[interfaceId].perSecondRateJiffys > 0) {
            depositEscrowJiffys = interfaces[interfaceId].perSecondRateJiffys * estimatedParticipationSeconds;
            whenContract.depositEscrow(caller, depositEscrowJiffys);   // Checks if spendable balance is >= escrow Jiffys
        }

        // Add Caller to Interface
        interfaces[interfaceId].callers[caller] = Caller({
                                                            isCaller: true, 
                                                            callerType: CallerType.Consumer,
                                                            participationState: ParticipationState.Registered,
                                                            escrowJiffys: depositEscrowJiffys, 
                                                            estimatedParticipationSeconds: estimatedParticipationSeconds,
                                                            billableSeconds: 0,
                                                            referrer: referrer, 
                                                            referralFeeBasisPoints: referralFeeBasisPoints
                                                        });
        interfaces[interfaceId].registeredCallerCount = interfaces[interfaceId].registeredCallerCount.add(1);

        return depositEscrowJiffys;  
    }

   /**
    * @dev Unsubscribe an Interface Caller
    *
    * @param interfaceId Unique identifier (address) of transaction 
    * @param caller Address of Caller joining the Interface
    */    
    function unsubscribeCaller
                                (
                                    address interfaceId, 
                                    address caller
                                ) 
                                public 
                                requireIsOperational
                                requireIsCallingContractAuthorized
                                returns(uint256)
                         
    {
        require(interfaceId != address(0));

        // Only Created Interfaces can have callers unsubscribed
        require(interfaces[interfaceId].state == InterfaceState.Created);
        require(whenContract.isUserRegistered(caller));


        uint256 refundEscrowJiffys = 0;
        if (interfaces[interfaceId].callers[caller].escrowJiffys > 0) {

            refundEscrowJiffys = interfaces[interfaceId].callers[caller].escrowJiffys;
            whenContract.refundEscrow(caller, refundEscrowJiffys);            
        }
        delete interfaces[interfaceId].callers[caller];
        interfaces[interfaceId].registeredCallerCount = interfaces[interfaceId].registeredCallerCount.sub(1);

        return refundEscrowJiffys;
    }


   /**
    * @dev Extends a Callers time on an Interface
    *
    * @param interfaceId Unique identifier (address) of transaction 
    * @param caller Address of Caller extending the Interface
    * @param additionalParticipationSeconds Additional duration for which the Caller may participate on call in seconds
    */ 
    function extendCaller
                            (
                                address interfaceId,
                                address caller,
                                uint256 additionalParticipationSeconds
                            )
                            public
                            requireIsOperational
                            requireIsCallingContractAuthorized

                            returns(uint256)
    {
        require(interfaceId != address(0));

        // Only Created Interfaces can have callers subscribed
        require((interfaces[interfaceId].state == InterfaceState.Created) || (interfaces[interfaceId].state == InterfaceState.Started));
        require(interfaces[interfaceId].callers[caller].isCaller); 
        require(additionalParticipationSeconds > 0);


        uint256 depositEscrowJiffys = 0;
        if (interfaces[interfaceId].perSecondRateJiffys > 0) {
            depositEscrowJiffys = interfaces[interfaceId].perSecondRateJiffys * additionalParticipationSeconds;
            whenContract.depositEscrow(caller, depositEscrowJiffys);   // Checks if spendable balance is >= escrow Jiffys
            interfaces[interfaceId].callers[caller].escrowJiffys = interfaces[interfaceId].callers[caller].escrowJiffys.add(depositEscrowJiffys);
        }

        interfaces[interfaceId].callers[caller].estimatedParticipationSeconds = interfaces[interfaceId].callers[caller].estimatedParticipationSeconds.add(additionalParticipationSeconds);
        
        return depositEscrowJiffys;  
        
    }


}

contract WHENToken {

    function isUserRegistered(address account) public view returns(bool);
    function isOperational() public view returns(bool);
    function isContractAuthorized(address account) public view returns(bool);
    function depositEscrow(address account, uint256 jiffys) external;
    function refundEscrow(address account, uint256 jiffys) external;
    function pay(address payer, address payee, address referrer, uint256 referralFeeBasisPoints, uint256 billableJiffys, uint256 escrowJiffys) external returns(uint256, uint256);
    function getSupportManager() external returns(address);
}


/*
LICENSE FOR SafeMath

The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library SafeMath {
/* Copyright (c) 2016 Smart Contract Solutions, Inc. */
/* See License at end of file                        */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}