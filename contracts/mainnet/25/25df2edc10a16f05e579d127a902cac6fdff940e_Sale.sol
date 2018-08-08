/*

The Sale contract manages a token sale.

The Sale contract primarily does the following:

	- allows individuals to buy tokens during a token sale
	- allows individuals to claim the tokens after a successful token sale
	- allows individuals to receive an ETH refund after a cancelled token sale
	- allows an admin to cancel a token sale, after which individuals can request refunds
	- allows an admin to certify a token sale, after which an admin can withdraw contributed ETH
	- allows an admin to complete a token sale, after which an individual (following a brief release period) can request their tokens
	- allows an admin to return contributed ETH to individuals
	- allows an admin to grant tokens to an individual
	- allows an admin to withdraw ETH from the token sale
	- allows an admin to add and remove individuals from a whitelist
	- allows an admin to pause or activate the token sale
	
The sale runs from a start timestamp to a finish timestamp.  After the release timestamp (assuming a successful sale), individuals can claim their tokens.  If the sale is cancelled, individuals can request a refund.  Furthermore, an admin may return ETH and negate purchases to respective individuals as deemed necessary.  Once the sale is certified or completed, ETH can be withdrawn by the company.

The contract creator appoints a delegate to perform most administrative tasks.

All events are logged for the purpose of transparency.

All math uses SafeMath.

ETH and tokens (often referred to as "value" and "tokens" in variable names) are really 1/10^18 of their respective parent units.  Basically, the values represent wei and the token equivalent thereof.

*/

pragma solidity ^0.4.18;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract SaleCallbackInterface {
    function handleSaleCompletionCallback(uint256 _tokens) external payable returns (bool);
    function handleSaleClaimCallback(address _recipient, uint256 _tokens) external returns (bool);  
}

contract Sale is SafeMath {
    
    address public creator;		    // address of the contract&#39;s creator
    address public delegate;		// address of an entity allowed to perform administrative functions on behalf of the creator
    
    address public marketplace;	    // address of another smart contract that manages the token and Smart Exchange
    
    uint256 public start;			// timestamp that the sale begins
    uint256 public finish;			// timestamp that the sale ends
    uint256 public release;			// timestamp that sale participants may "claim" their tokens (will be after the finish)
    
    uint256 public pricer;			// a multiplier (>= 1) used to determine how many tokens (or, really, 10^18 sub-units of that token) to give purchasers
    uint256 public size;			// maximum number of 10^18 sub-units of tokens that can be purchased/granted during the sale
    
    bool public restricted;		    // whether purchasers and recipients of tokens must be whitelisted manually prior to participating in the sale

    bool public active;			    // whether individuals are allowed to purchase tokens -- if false, they cannot.  if true, they can or cannot.  
    								// other factors, like start/finish, size, and others can restrict participation as well, even if active = true.
    								// this also can remain true indefinitely, even if the token sale has been cancelled or has completed.
    								
    
    int8 public progress;			// -1 = token sale cancelled, 0 = token sale ongoing, 1 = token sale certified (can withdraw ETH while sale is live), 2 = token sale completed
    
    uint256 public tokens;			// number of sub-tokens that have been purchased/granted during the sale.  purchases/grants can be reversed while progress = 0 || progress = 1 resulting in tokens going down
    uint256 public value;			// number of sub-ether (wei) that have been contributed during the sale.  purchases can be resversed while progress = 0 || progress = 1 resulting in value going down
    
    uint256 public withdrawls;		// the number of sub-ether (wei) that have been withdrawn by the contract owner
    uint256 public reserves;		// the number of sub-ether (wei) that have been sent to serve as reserve in the marketplace
    
    mapping(address => bool) public participants;			// mapping to record who has participated in the sale (purchased/granted)
    address[] public participantIndex;						// index of participants
    
    mapping(address => uint256) public participantTokens;	// sub-tokens purchased/granted to each participant
    mapping(address => uint256) public participantValues;	// sub-ether contributed by each participant
    
    mapping(address => bool) public participantRefunds;	    // mapping to record who has been awarded a refund after a cancelled sale
    mapping(address => bool) public participantClaims;		// mapping to record who has claimed their tokens after a completed sale
    
    mapping(address => bool) public whitelist;				// mapping to record who has been approved to participate in a "restricted" sale
    
    uint256[] public bonuses;								// stores bonus percentages, where even numbered elements store timestamps and odd numbered elements store bonus percentages
    
    bool public mutable;									// whether certain properties (like finish and release) of the sale can be updated to increase the liklihood of a successful token sale for all parties involved
    
    modifier ifCreator { require(msg.sender == creator); _; }		// if the caller created the contract...
    modifier ifDelegate { require(msg.sender == delegate); _; }		// if the caller is currently the appointed delegate...
    modifier ifMutable { require(mutable); _; }						// if the certain properties of the sale can be changed....
    
    event Created();																						// the contract was created
    event Bought(address indexed _buyer, address indexed _recipient, uint256 _tokens, uint256 _value);		// an individual bought tokens
    event Claimed(address indexed _recipient, uint256 _tokens);												// an individual claimed tokens after the completion of the sale and after tokens were scheduled for release
    event Refunded(address indexed _recipient, uint256 _value);												// an individual requested a refund of the ETH they contributed after a cancelled token sale
    event Reversed(address indexed _recipient, uint256 _tokens, uint256 _value);							// an individual was sent the ETH they contributed to the sale and will not receive tokens
    event Granted(address indexed _recipient, uint256 _tokens);												// an individual was granted tokens, without contributing ETH
    event Withdrew(address _recipient, uint256 _value);														// the contract creator withdrew ETH from the token sale
    event Completed(uint256 _tokens, uint256 _value, uint256 _reserves);									// the contract creator signaled that the sale completed successfuly
    event Certified(uint256 _tokens, uint256 _value);														// the contract creator certified the sale
    event Cancelled(uint256 _tokens, uint256 _value);														// the contract creator cancelled the sale
    event Listed(address _participant);																		// an individual was added to the whitelist
    event Delisted(address _participant);																	// an individual was removed from the whitelist
    event Paused();																							// the sale was paused (active = false)
    event Activated();    																					// the sale was activated (active = true)

    function Sale() {
        
        creator = msg.sender;
        delegate = msg.sender;
        
        start = 1;					            // contributions may be made as soon as the contract is published
        finish = 1535760000;				    // the sale continues through 09/01/2018 @ 00:00:00
        release = 1536969600;				    // tokens will be available to participants starting 09/15/2018 @ 00:00:00
        
        pricer = 100000;					    // each ETH is worth 100,000 tokens
        
        size = 10 ** 18 * pricer * 2000 * 2;	// 2,000 ETH, plus a 100% buffer to account for the possibility of a 50% decrease in ETH value during the sale

        restricted = false;                     // the sale accepts contributions from everyone.  
                                                // however, participants who do not submit formal KYC verification before the end of the token sale will have their contributions reverted
    
        bonuses = [1, 20];                      // the bonus during the pre-sale starts at 20%
        
        mutable = true;                         // certain attributes, such as token sale finish and release dates, may be updated to increase the liklihood of a successful token sale for all parties involved
        active = true;                          // the token sale is active from the point the contract is published in the form of a pre-sale         
        
        Created();
        Activated();
    }
    
    // returns the number of sub-tokens the calling account purchased/was granted
    
    function getMyTokenBalance() external constant returns (uint256) {
        return participantTokens[msg.sender];
    }
    
    // allows an individual to buy tokens (which will not be issued immediately)
    // individual instructs the tokens to be delivered to a specific account, which may be different than msg.sender
    
    function buy(address _recipient) public payable {
        
        // _recipient address must not be all 0&#39;s
        
        require(_recipient != address(0x0));

		// contributor must send more than 1/10 ETH
		
        require(msg.value >= 10 ** 17);

		// sale must be considered active
		
        require(active);

		// sale must be ongoing or certified

        require(progress == 0 || progress == 1);

		// current timestamp must be greater than or equal to the start of the token sale
		
        require(block.timestamp >= start);

		// current timestamp must be less than the end of the token sale
		
        require(block.timestamp < finish);
		
		// either the token sale isn&#39;t restricted, or the sender is on the whitelist

        require((! restricted) || whitelist[msg.sender]);
        
        // either the token sale isn&#39;t restricted, or the recipient is on the whitelist

        require((! restricted) || whitelist[_recipient]);
        
        // multiply sub-ether by the pricer (which will be a whole number >= 1) to get sub-tokens

        uint256 baseTokens = safeMul(msg.value, pricer);
        
        // determine how many bonus sub-tokens to award and add that to the base tokens
        
        uint256 totalTokens = safeAdd(baseTokens, safeDiv(safeMul(baseTokens, getBonusPercentage()), 100));

		// ensure the purchase does not cause the sale to exceed its maximum size
		
        require(safeAdd(tokens, totalTokens) <= size);
        
        // if the recipient is new, add them as a participant

        if (! participants[_recipient]) {
            participants[_recipient] = true;
            participantIndex.push(_recipient);
        }
        
        // increment the participant&#39;s sub-tokens and sub-ether

        participantTokens[_recipient] = safeAdd(participantTokens[_recipient], totalTokens);
        participantValues[_recipient] = safeAdd(participantValues[_recipient], msg.value);

		// increment sale sub-tokens and sub-ether

        tokens = safeAdd(tokens, totalTokens);
        value = safeAdd(value, msg.value);
        
        // log purchase event

        Bought(msg.sender, _recipient, totalTokens, msg.value);
    }
    
    // token sale participants call this to claim their tokens after the sale is completed and tokens are scheduled for release
    
    function claim() external {
	    
	    // sale must be completed
        
        require(progress == 2);
        
        // tokens must be scheduled for release
        
        require(block.timestamp >= release);
        
        // participant must have tokens to claim
        
        require(participantTokens[msg.sender] > 0);
        
        // participant must not have already claimed tokens
        
        require(! participantClaims[msg.sender]);
        
		// record that the participant claimed their tokens

        participantClaims[msg.sender] = true;
        
        // log the event
        
        Claimed(msg.sender, participantTokens[msg.sender]);
        
        // call the marketplace contract, which will actually issue the tokens to the participant
        
        SaleCallbackInterface(marketplace).handleSaleClaimCallback(msg.sender, participantTokens[msg.sender]);
    }
    
    // token sale participants call this to request a refund if the sale was cancelled
    
    function refund() external {
        
        // the sale must be cancelled
        
        require(progress == -1);
        
        // the participant must have contributed ETH
        
        require(participantValues[msg.sender] > 0);
        
        // the participant must not have already requested a refund
        
        require(! participantRefunds[msg.sender]);
        
		// record that the participant requested a refund
        
        participantRefunds[msg.sender] = true;
        
        // log the event
        
        Refunded(msg.sender, participantValues[msg.sender]);
        
        // transfer contributed ETH back to the participant
    
        address(msg.sender).transfer(participantValues[msg.sender]);
    }    
    
    // the contract creator calls this to withdraw contributed ETH to a specific address
    
    function withdraw(uint256 _sanity, address _recipient, uint256 _value) ifCreator external {
        
        // avoid unintended transaction calls
        
        require(_sanity == 100010001);
        
        // address must not be 0-value
        
        require(_recipient != address(0x0));
        
        // token sale must be certified or completed
        
        require(progress == 1 || progress == 2);
        
        // the amount of ETH in the contract must be greater than the amount the creator is attempting to withdraw
        
        require(this.balance >= _value);
        
        // increment the amount that&#39;s been withdrawn
        
        withdrawls = safeAdd(withdrawls, _value);
        
        // log the withdrawl
        
        Withdrew(_recipient, _value);
        
        // send the ETH to the recipient
        
        address(_recipient).transfer(_value);
    } 
    
    // the contract owner calls this to complete (finalize/wrap up, etc.) the sale
    
    function complete(uint256 _sanity, uint256 _value) ifCreator external {
        
        // avoid unintended transaction calls
        
        require(_sanity == 101010101);
	    
	    // the sale must be marked as ongoing or certified (aka, not cancelled -1)
        
        require(progress == 0 || progress == 1);
        
        // the sale can only be completed after the finish time
        
        require(block.timestamp >= finish);
        
        // ETH is withdrawn in the process and sent to the marketplace contract.  ensure the amount that is being withdrawn is greater than the balance in the smart contract.
        
        require(this.balance >= _value);
        
        // mark the sale as completed
        
        progress = 2;
        
        // the amount that is sent to the other contract is added to the ETH reserve.  denote this amount as reserves.
        
        reserves = safeAdd(reserves, _value);
        
        // log the completion of the sale, including the number of sub-tokens created by the sale, the amount of net sub-eth received during the sale, and the amount of sub-eth to be added to the reserve
        
        Completed(tokens, value, _value);
        
        // call the marketplace contract, sending the ETH for the reserve and including the number of sub-tokens 
        
        SaleCallbackInterface(marketplace).handleSaleCompletionCallback.value(_value)(tokens);
    }    
    
    // the creator can certify a sale, meaning it cannot be cancelled, and ETH can be withdrawn from the sale by the creator
    
    function certify(uint256 _sanity) ifCreator external {
        
        // avoid unintended transaction calls
        
        require(_sanity == 101011111);
	    
	    // the sale must be ongoing
	    
        require(progress == 0);
        
        // the sale must have started
        
        require(block.timestamp >= start);
        
        // record that the sale is certified
        
        progress = 1;
        
        // log the certification
        
        Certified(tokens, value);
    }
    
    // the creator can cancel a sale 
    
    function cancel(uint256 _sanity) ifCreator external {
        
        // avoid unintended transaction calls
        
        require(_sanity == 111110101);
	    
	    // the sale must be ongoing
	    
        require(progress == 0);
        
        // record that the sale is cancelled
        
        progress = -1;
        
        // log the cancellation
        
        Cancelled(tokens, value);
    }    
    
    // called by the delegate to reverse purchases/grants for a particular contributor
    
    function reverse(address _recipient) ifDelegate external {
        
        // the recipient address must not be all 0&#39;s
        
        require(_recipient != address(0x0));
        
        // the sale must be ongoing or certified
        
        require(progress == 0 || progress == 1);
        
        // the recipient must have contributed ETH and/or received tokens
        
        require(participantTokens[_recipient] > 0 || participantValues[_recipient] > 0);
        
        uint256 initialParticipantTokens = participantTokens[_recipient];
        uint256 initialParticipantValue = participantValues[_recipient];
        
        // subtract sub-tokens and sub-ether from sale totals
        
        tokens = safeSub(tokens, initialParticipantTokens);
        value = safeSub(value, initialParticipantValue);
        
        // reset participant sub-tokens and sub-ether
        
        participantTokens[_recipient] = 0;
        participantValues[_recipient] = 0;
        
        // log the reversal, including the initial sub-tokens and initial sub-ether
        
        Reversed(_recipient, initialParticipantTokens, initialParticipantValue);
        
        // if the participant previously sent ETH, return it
        
        if (initialParticipantValue > 0) {
            address(_recipient).transfer(initialParticipantValue);
        }
    }
    
    // called by the delegate to grant tokens to a recipient
    
    function grant(address _recipient, uint256 _tokens) ifDelegate external {
        
       	// the recipient&#39;s address cannot be 0-value
       
        require(_recipient != address(0x0));
		
		// the sale must be ongoing or certified
		
        require(progress == 0 || progress == 1);
        
        // if the recipient has not participated previously, add them as a participant
        
        if (! participants[_recipient]) {
            participants[_recipient] = true;
            participantIndex.push(_recipient);
        }
        
        // add sub-tokens to the recipient&#39;s balance
        
        participantTokens[_recipient] = safeAdd(participantTokens[_recipient], _tokens);
        
        // add sub-tokens to the sale&#39;s total
        
        tokens = safeAdd(tokens, _tokens);
        
        // log the grant
        
        Granted(_recipient, _tokens);
    }    
    
    // adds a set of addresses to the whitelist
    
    function list(address[] _addresses) ifDelegate external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
            Listed(_addresses[i]);
        }
    }
    
    // removes a set of addresses from the whitelist
    
    function delist(address[] _addresses) ifDelegate external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
            Delisted(_addresses[i]);
        }
    }  
    
	// pause the sale
    
    function pause() ifDelegate external {
        active = false;
        Paused();
    }
    
    // activate the sale

    function activate() ifDelegate external {
        active = true;
        Activated();
    }

    function setDelegate(address _delegate) ifCreator external {
        delegate = _delegate;
    }
    
    function setRestricted(bool _restricted) ifDelegate external {
        restricted = _restricted;
    }
    
    function setMarketplace(address _marketplace) ifCreator ifMutable external {
        marketplace = _marketplace;
    }
    
    function setBonuses(uint256[] _bonuses) ifDelegate ifMutable external {
        bonuses = _bonuses;
    }
    
    function setFinish(uint256 _finish) ifDelegate ifMutable external {
        finish = _finish;
    }

    function setRelease(uint256 _release) ifDelegate ifMutable external {
        release = _release;
    }     
    
    // get the current bonus percentage, as a whole number
    
    function getBonusPercentage() public constant returns (uint256) {
        
        uint256 finalBonus;
        
        uint256 iterativeTimestamp;
        uint256 iterativeBonus;
        
        // within bonuses, even numbered elements store timestamps and odd numbered elements store bonus percentages
        // timestamps are in order from oldest to newest
        // iterates over the elements and if the timestamp has been surpassed, the bonus percentage is denoted
        // the last bonus percentage that was denoted, if one was denoted at all, is the correct bonus percentage at this time
        
        for (uint256 i = 0; i < bonuses.length; i++) {
            if (i % 2 == 0) {
                iterativeTimestamp = bonuses[i];
            } else {
                iterativeBonus = bonuses[i];
                if (block.timestamp >= iterativeTimestamp) {
                    finalBonus = iterativeBonus;
                }
            }
        } 
        
        return finalBonus;
    }    
    
    function() public payable {
        buy(msg.sender);
    }
    
}