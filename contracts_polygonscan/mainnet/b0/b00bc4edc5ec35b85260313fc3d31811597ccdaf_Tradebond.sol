/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


/** 
 ** TradeBond Contract
 **/
contract Tradebond {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/
    
    address payable public lockbox;
    address payable public creator;
    address payable public counterparty;
    uint public contractID = 0;

    string public answer;
    uint public lockbox_balance = 0;
    uint public lockbox_claimable = 0;
    bool public paused = false; 
    uint locked = 0; // guard;  
    uint j = 1; //contract creator count 
    
    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/
    enum State { Created, PartiallyFunded, In_progress, Completed, UnpaidSeller, UnpaidBuyer, Disputed, DisputeResolved } //
    enum AcceptReject { Unreviewed, Accepted, Rejected }
    enum WhoIs { Neither, SellerId, BuyerId }
    WhoIs public whois; 
    struct Agreement {
        address payable buyer;
        address payable seller;
        uint deal_amount;
        uint date_created;
        uint start_date;
        uint contract_duration;
        uint seller_protection_percent; //maximum is uint 100
        bool seller_funded;
        bool buyer_funded;
        State state;
        AcceptReject buyeracceptreject;
        AcceptReject selleracceptreject;

    }
    struct Dispute {
        address payable buyer;
        address payable seller;
        uint settlement_amount;
        AcceptReject sellerdecision;
        
    }
    struct History{
        address payable creator;
        uint contractid;
    }
    //disputes and agreements setup based on counterparty address -> contract number -> 
    mapping(address => mapping(uint => Agreement)) public myAgreements;
    mapping(address => mapping(uint => Dispute)) public myDisputes;        
    History[] public Agreements;

    /*///////////////////////////////////////////////////////////////
                EVENTS 
    //////////////////////////////////////////////////////////////*/
    event newAgreement(uint timeCreated, address payable buyer, address payable seller, uint ID, uint deal_amount, uint contract_duration);
    event depositMade(uint timeCreated, uint ID, State state, bool seller_funded, bool buyer_funded);
    event acceptORreject(uint timeCreated, uint ID, State state, AcceptReject buyeraccrej, AcceptReject selleraccrej);
    event proposal(uint timeCreated, address payable buyer, address payable seller, uint ID, uint deal_amount, uint contract_duration);
    event fundsTransferred(uint timeCreated, address payable buyer, address payable seller, uint ID, uint deal_amount);    
    

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        lockbox = payable(msg.sender);
        j = 1; //contract ID count

    }
    
    //////////////////////////////////////////////
    ///// Functions call by buyers/sellers  //////
    //////////////////////////////////////////////

    function createNewAgreement(address payable _buyer, address payable _seller, uint _deal_amount, uint _contract_duration, uint _seller_protection_percent, bool createNpay ) public payable {
        //Populate agreement information
        require(paused == false, "Contract is currently paused. No new contracts can be created.");
        require(_seller_protection_percent <= 100, "Maximum buyer coverage is 100%");
        //require(_contract_duration <= 2592000, "Contract duration cannot exceed 30 days. Issue new contract");        
        contractID = contractID + 1;
        bool _sellerfunded = false; 
        bool _buyerfunded = false; 
        
        myAgreements[msg.sender][contractID] = Agreement( payable(_buyer), payable(_seller), _deal_amount, block.timestamp, block.timestamp, _contract_duration, _seller_protection_percent, _buyerfunded, _sellerfunded, State.Created, AcceptReject.Unreviewed, AcceptReject.Unreviewed );
        
        if (createNpay){
            deposit(payable(msg.sender), contractID);
        }
        
        Agreements.push(History(payable(msg.sender), contractID));
        j++;
        
        emit newAgreement(block.timestamp, _buyer, _seller, contractID, _deal_amount, _contract_duration);
        
    }
 
    function deposit(address payable _creator, uint _contractID) public payable {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");
        require( (myAgreements[_creator][_contractID].state == State.PartiallyFunded || myAgreements[_creator][_contractID].state == State.Created) , "Contract has already been funded");
        
        
        //Check who is paying
        if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.SellerId) {
              //answer  = "this is the seller";
              require(msg.value == myAgreements[_creator][_contractID].deal_amount, "The deposit amount is not correct");
              //lockbox_balance += msg.value;
              myAgreements[_creator][_contractID].seller_funded = true;
        }
        
        else if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.BuyerId){
              //answer  = "this is the buyer";
              uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
              myAgreements[_creator][_contractID].buyer_funded = true;
              require((msg.value == (((100 + SPA))*myAgreements[_creator][_contractID].deal_amount/100)), "The deposit amount is not correct");
              
        }
        
        else {
              revert();
        }
        
        //Update state of contract
        if (myAgreements[_creator][_contractID].buyer_funded || myAgreements[_creator][_contractID].seller_funded) {
            myAgreements[_creator][_contractID].state = State.PartiallyFunded;
        } 

        if (myAgreements[_creator][_contractID].buyer_funded && myAgreements[_creator][_contractID].seller_funded) {
            myAgreements[_creator][_contractID].state = State.In_progress;
        }

        emit depositMade(block.timestamp, _contractID, myAgreements[_creator][_contractID].state, myAgreements[_creator][_contractID].seller_funded, myAgreements[_creator][_contractID].buyer_funded);

    }
    
    function accept(address payable _creator, uint _contractID) public {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");
        require(myAgreements[_creator][_contractID].state == State.In_progress);
        //Check who is accepting
        if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.SellerId) {
              myAgreements[_creator][_contractID].selleracceptreject = AcceptReject.Accepted;
        }
        
        else if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.BuyerId){
               myAgreements[_creator][_contractID].buyeracceptreject = AcceptReject.Accepted;
        }
        
        else {
              revert();
        }
        
        
        //Update state of contract
        if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Accepted) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Accepted)) {
            //Seller and buyer accept
            payout(_creator,_contractID);
        }
        
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Rejected) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Accepted)) {
            //Seller rejects, buyer accepts
            returnFunds(_creator,_contractID );
        }
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Rejected) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Rejected)) {
            //Seller rejects, buyer rejects
            returnFunds(_creator,_contractID);
        }
        
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Accepted) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Rejected)) {
            //Buyer rejects, seller accepts. Send it to the lockBox
            //fullsendlockbox(_creator,_contractID);
            myAgreements[_creator][_contractID].state = State.Disputed;
        } 
    
        emit acceptORreject(block.timestamp, _contractID, myAgreements[_creator][_contractID].state, myAgreements[_creator][_contractID].selleracceptreject, myAgreements[_creator][_contractID].buyeracceptreject);
    }
    
    function reject(address payable _creator, uint _contractID) public {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");
        require(myAgreements[_creator][_contractID].state == State.In_progress);
        //Check who is rejcting
        if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.SellerId) {
              myAgreements[_creator][_contractID].selleracceptreject = AcceptReject.Rejected;
        }
        
        else if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.BuyerId){
               myAgreements[_creator][_contractID].buyeracceptreject = AcceptReject.Rejected;
        }
        
        else {
              revert();
        }
        
        //Update state of contract
        if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Accepted) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Accepted)) {
            //Seller and buyer accept
            payout(_creator,_contractID);
        }
        
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Rejected) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Accepted)) {
            //Seller rejects, buyer accepts
            returnFunds(_creator,_contractID );
        }
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Rejected) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Rejected)) {
            //Seller rejects, buyer rejects
            returnFunds(_creator,_contractID);
        }
        
        else if ((myAgreements[_creator][_contractID].selleracceptreject == AcceptReject.Accepted) && (myAgreements[_creator][_contractID].buyeracceptreject == AcceptReject.Rejected)) {
            //Buyer rejects, seller accepts. Send it to the lockBox
            //fullsendlockbox(_creator,_contractID);
            myAgreements[_creator][_contractID].state = State.Disputed;
        } 
    
        emit acceptORreject(block.timestamp, _contractID, myAgreements[_creator][_contractID].state, myAgreements[_creator][_contractID].selleracceptreject, myAgreements[_creator][_contractID].buyeracceptreject);
    }
    
    function proposeSettlement(address payable _creator, uint _contractID, uint settlement) public{
        require(!checkExpiration(_creator, _contractID), "Contract is not active"); // make sure contract isn't expired
        require(checkIfBuyerSeller(_creator,_contractID) == WhoIs.BuyerId, "Buyer must make proposal"); //only buyer can execute 
        //require(myAgreements[_creator][_contractID].state == State.Disputed); //make sure the contract is funded by both sides
        
        myDisputes[_creator][_contractID] = Dispute( myAgreements[_creator][_contractID].buyer, myAgreements[_creator][_contractID].seller, settlement, AcceptReject.Unreviewed );
        myAgreements[_creator][_contractID].state = State.Disputed;
        
        emit proposal(block.timestamp, myAgreements[_creator][_contractID].buyer, myAgreements[_creator][_contractID].seller, _contractID, settlement, myAgreements[_creator][_contractID].contract_duration);
    }
    
    function respondSettlement(address payable _creator, uint _contractID, bool decision) public{
        require(!checkExpiration(_creator, _contractID), "Contract is not active"); // make sure contract isn't expired
        require(checkIfBuyerSeller(_creator,_contractID) == WhoIs.SellerId); //only seller can execute 
        require(myAgreements[_creator][_contractID].state == State.Disputed); //make sure the contract is funded by both sides
        
        //true if accepted
        if (decision){
            myDisputes[_creator][_contractID].sellerdecision = AcceptReject.Accepted;
            disputepayout(_creator, _contractID);
            myAgreements[_creator][_contractID].state == State.DisputeResolved;
            
        }
        
        //false if rejected
        else if (!decision){
            myDisputes[_creator][_contractID].sellerdecision = AcceptReject.Rejected; 
            myAgreements[_creator][_contractID].state == State.Completed;
            
        }
        
        emit acceptORreject(block.timestamp, _contractID, myAgreements[_creator][_contractID].state, myAgreements[_creator][_contractID].selleracceptreject, myAgreements[_creator][_contractID].buyeracceptreject);
    }

    function cancelContract(address payable _creator, uint _contractID) public {
        require( (myAgreements[_creator][_contractID].state == State.PartiallyFunded || myAgreements[_creator][_contractID].state == State.Created) , "Contract has already been funded or is expired");
    
            //Check who is paying
        if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.SellerId) {
            //answer  = "this is the seller";
            require(safePay(myAgreements[_creator][_contractID].seller, myAgreements[_creator][_contractID].deal_amount ), "Payment to one party failed");
            myAgreements[_creator][_contractID].state = State.Completed;
        }
        
        else if (checkIfBuyerSeller(_creator,_contractID) == WhoIs.BuyerId){
            //answer  = "this is the buyer";
            uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
            require(safePay(myAgreements[_creator][_contractID].buyer, ((SPA + 100)*myAgreements[_creator][_contractID].deal_amount)/100 ), "Payment to one party failed");
            myAgreements[_creator][_contractID].state = State.Completed;
        }
        
        else {
              revert();
        }
         
        
    }

    ///////////////////////////////////////
    ///// Functions called internally /////
    ///////////////////////////////////////
    
    
    function disputepayout(address payable _creator, uint _contractID) internal {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");
        require(myAgreements[_creator][_contractID].state == State.Disputed); //make sure the contract is funded by both sides
        uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
        uint fees = feesendlockbox(_creator, _contractID)/2;
        
        //check if buyer and seller were paid, if so flip contract state
        if (safePay(myAgreements[_creator][_contractID].buyer, (((100+SPA)*myAgreements[_creator][_contractID].deal_amount/100) - myDisputes[_creator][_contractID].settlement_amount - fees)) && safePay(myAgreements[_creator][_contractID].seller, (myAgreements[_creator][_contractID].deal_amount + myDisputes[_creator][_contractID].settlement_amount - fees))){
            myAgreements[_creator][_contractID].state = State.Completed;
            
        }         
        
        
    }
    
    function fullsendlockbox(address payable _creator, uint _contractID) internal {
        uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
        //myAgreements[_creator][_contractID].state = State.Disputed;
        lockbox_claimable = lockbox_claimable + ((200 +SPA)*myAgreements[_creator][_contractID].deal_amount/100);
        
    }
    
    function feesendlockbox(address payable _creator, uint _contractID) internal returns (uint feeamount){
        
        //code below takes 0.5% fee for successful transactions
        lockbox_claimable = lockbox_claimable  + (myAgreements[_creator][_contractID].deal_amount/200);
        
        return (myAgreements[_creator][_contractID].deal_amount/200);
    }

    function checkIfBuyerSeller(address payable _creator, uint _contractID) internal view returns (WhoIs validity){
        if ((payable(msg.sender) == (myAgreements[_creator][_contractID].seller))){
            validity = WhoIs.SellerId;     
        }
        else if (payable(msg.sender) == (myAgreements[_creator][_contractID].buyer)) {
            validity = WhoIs.BuyerId;
        }
        else {
            validity = WhoIs.Neither;
        }
        
        return validity; 
    }

    function returnFunds(address payable _creator, uint _contractID) internal {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");
        uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
        uint fees = feesendlockbox(_creator, _contractID)/2;
        
        if (myAgreements[_creator][_contractID].state == State.In_progress ){
            
            
            if (myAgreements[_creator][_contractID].seller_funded == true && myAgreements[_creator][_contractID].buyer_funded == true){
                myAgreements[_creator][_contractID].state = State.Completed;
                require((safePay(myAgreements[_creator][_contractID].seller, (myAgreements[_creator][_contractID].deal_amount - fees))) && (safePay(myAgreements[_creator][_contractID].buyer, ((SPA + 100)*myAgreements[_creator][_contractID].deal_amount/100)-fees)), "Payment to one party failed");
                
            }
                
            
        }
    }

    function payout(address payable _creator, uint _contractID) internal {
        require(!checkExpiration(_creator, _contractID), "Contract is not active");  
        uint SPA = myAgreements[_creator][_contractID].seller_protection_percent; //seller protection amaount
    
        if (myAgreements[_creator][_contractID].state == State.In_progress){
            
            uint fees = feesendlockbox(_creator, _contractID)/2;
            //check if buyer and seller were paid, if so flip contract state
            if (safePay(myAgreements[_creator][_contractID].buyer, ((SPA * myAgreements[_creator][_contractID].deal_amount)/100)-fees) && safePay(myAgreements[_creator][_contractID].seller, ((2*myAgreements[_creator][_contractID].deal_amount))-fees)){
                myAgreements[_creator][_contractID].state = State.Completed;
            } 
            
        

        }
    }

    function checkExpiration(address payable _creator, uint _contractID) internal returns (bool expired){
        //Check if contract left unfunded for more than 7 days
        if (myAgreements[_creator][_contractID].state == State.PartiallyFunded && (block.timestamp > (myAgreements[_creator][_contractID].start_date + (7*86400)))){
            //set contract to completed and return money
            myAgreements[_creator][_contractID].state = State.Completed;
            returnFunds(_creator,_contractID );
            expired = true;
        }
        
        //Check if contract has extended set lock time
        if (block.timestamp > (myAgreements[_creator][_contractID].start_date + myAgreements[_creator][_contractID].contract_duration)){
            //Set the state to Completed
            myAgreements[_creator][_contractID].state = State.Completed;
            expired = true;
        }
        return (expired);
    }
    
    
    function safePay(address payable payto, uint amount) internal returns (bool _sent){
        require(locked == 0, "Re-entrancy suspected");
        locked = 1; 
        //payment transactions
        (bool sent, ) = payto.call{value: amount}("");
        locked = 0; 
        return sent;
}
   
    ///////////////////////////////////////
    ///// Functions called by creator /////
    ///////////////////////////////////////

    function claimlockbox() public {
        require(msg.sender ==  lockbox, "Not authorized to claim lockbox");
        collectExpired();
        //require(lockbox_claimable != 0, "Claimable portion of lockbox is empty");
        payable(lockbox).transfer(lockbox_claimable); //only funds locked from expired contracts can be sent
        lockbox_claimable = 0;
    }
    
    function pauseContract(bool pauseUnpause) public {
        require(msg.sender ==  lockbox, "Not authorized to pause contract");

        paused = pauseUnpause;
    }
    
    function collectExpired() internal {
        for (uint i=0; i<Agreements.length; i++) {
            if ( (myAgreements[Agreements[i].creator][Agreements[i].contractid].state != State.PartiallyFunded) && block.timestamp > (myAgreements[Agreements[i].creator][Agreements[i].contractid].start_date + myAgreements[Agreements[i].creator][Agreements[i].contractid].contract_duration)){
                fullsendlockbox(Agreements[i].creator, Agreements[i].contractid);
                myAgreements[Agreements[i].creator][Agreements[i].contractid].state = State.Completed;
            }
        }

        }
     
}