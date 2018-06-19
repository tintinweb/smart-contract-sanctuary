pragma solidity ^0.4.11;

library SafeMath {
    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
	
}

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) returns (bool success) ;
	function balanceOf(address _owner) constant returns (uint256 balance);
}

contract IQTCrowdsale is Owned{
    using SafeMath for uint256;
    using SafeMath for uint;
	
	struct ContributorData{
		bool isActive;
		bool isTokenDistributed;
		uint contributionAmount;	// ETH contribution
		uint tokensAmount;			// Exchanged IQT amount
	}
	
	mapping(address => ContributorData) public contributorList;
	mapping(uint => address) contributorIndexes;
	uint nextContributorIndex;
	uint contributorCount;
    
    address public beneficiary;
    uint public fundingLimit;
    uint public amountRaised;
	uint public remainAmount;
    uint public deadline;
    uint public exchangeTokenRate;
    token public tokenReward;
	uint256 public tokenBalance;
    bool public crowdsaleClosed = false;
    bool public isIQTDistributed = false;
    

    // ------------------------------------------------------------------------
    // Tranche 1 crowdsale start date and end date
    // Start - Monday, 25-Sep-17 12:00:00 UTC / 12pm GMT 25th September 2017
    // Tier1  - Sunday, 1-Oct-17 16:00:00 UTC / 16pm GMT 1st October 2017
    // Tier2  - Wednesday, 11-Oct-17 16:00:00 UTC / 16pm GMT 11th October 2017
    // Tier3  - Monday, 21-Oct-17 16:00:00 UTC / 16pm GMT 21th October 2017
    // End - Saturday, 25-Nov-17 12:00:00 UTC / 12pm GMT 25 November 2017 
    // ------------------------------------------------------------------------
    uint public constant START_TIME = 1506340800;
    uint public constant SECOND_TIER_SALE_START_TIME = 1506787200;
    uint public constant THIRD_TIER_SALE_START_TIME = 1507651200;
    uint public constant FOURTH_TIER_SALE_START_TIME = 1508515200;
    uint public constant END_TIME = 1511611200;
	
	
    
    // ------------------------------------------------------------------------
    // crowdsale exchange rate
    // ------------------------------------------------------------------------
    uint public START_RATE = 900;
    uint public SECOND_TIER_RATE = 850;
    uint public THIRD_TIER_RATE = 800;
    uint public FOURTH_RATE = 700;
    

    // ------------------------------------------------------------------------
    // Funding Goal
    //    - HARD CAP : 33000 ETH
    // ------------------------------------------------------------------------
    uint public constant FUNDING_ETH_HARD_CAP = 33000;
    
    // IQT token decimals
    uint8 public constant IQT_DECIMALS = 8;
    uint public constant IQT_DECIMALSFACTOR = 10**uint(IQT_DECIMALS);
    
    address public constant IQT_FUNDATION_ADDRESS = 0xB58d67ced1E480aC7FBAf70dc2b023e30140fBB4;
    address public constant IQT_CONTRACT_ADDRESS = 0x51ee82641Ac238BDe34B9859f98F5F311d6E4954;

    event GoalReached(address raisingAddress, uint amountRaised);
	event LimitReached(address raisingAddress, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
	event WithdrawFailed(address raisingAddress, uint amount, bool isContribution);
	event FundReturn(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function IQTCrowdsale(
    ) {
        beneficiary = IQT_FUNDATION_ADDRESS;
        fundingLimit = FUNDING_ETH_HARD_CAP * 1 ether;  // Funding limit 33000 ETH
		
        deadline = END_TIME;  // 2017-11-25 12:00:00 UTC
        exchangeTokenRate = FOURTH_RATE * IQT_DECIMALSFACTOR;
        tokenReward = token(IQT_CONTRACT_ADDRESS);
		contributorCount = 0;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
		
        require(!crowdsaleClosed);
        require(now >= START_TIME && now < END_TIME);
        
		processTransaction(msg.sender, msg.value);
    }
	
	/**
	 * Process transaction
	 */
	function processTransaction(address _contributor, uint _amount) internal{	
		uint contributionEthAmount = _amount;
			
        amountRaised += contributionEthAmount;                    // add newly received ETH
		remainAmount += contributionEthAmount;
        
		// calcualte exchanged token based on exchange rate
        if (now >= START_TIME && now < SECOND_TIER_SALE_START_TIME){
			exchangeTokenRate = START_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= SECOND_TIER_SALE_START_TIME && now < THIRD_TIER_SALE_START_TIME){
            exchangeTokenRate = SECOND_TIER_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= THIRD_TIER_SALE_START_TIME && now < FOURTH_TIER_SALE_START_TIME){
            exchangeTokenRate = THIRD_TIER_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= FOURTH_TIER_SALE_START_TIME && now < END_TIME){
            exchangeTokenRate = FOURTH_RATE * IQT_DECIMALSFACTOR;
        }
        uint amountIqtToken = _amount * exchangeTokenRate / 1 ether;
		
		if (contributorList[_contributor].isActive == false){                  // Check if contributor has already contributed
			contributorList[_contributor].isActive = true;                            // Set his activity to true
			contributorList[_contributor].contributionAmount = contributionEthAmount;    // Set his contribution
			contributorList[_contributor].tokensAmount = amountIqtToken;
			contributorList[_contributor].isTokenDistributed = false;
			contributorIndexes[nextContributorIndex] = _contributor;                  // Set contributors index
			nextContributorIndex++;
			contributorCount++;
		}
		else{
			contributorList[_contributor].contributionAmount += contributionEthAmount;   // Add contribution amount to existing contributor
			contributorList[_contributor].tokensAmount += amountIqtToken;             // log token amount`
		}
		
        FundTransfer(msg.sender, contributionEthAmount, true);
		
		if (amountRaised >= fundingLimit){
			// close crowdsale because the crowdsale limit is reached
			crowdsaleClosed = true;
		}		
		
	}

    modifier afterDeadline() { if (now >= deadline) _; }	
	modifier afterCrowdsaleClosed() { if (crowdsaleClosed == true || now >= deadline) _; }
	
	
	/**
     * close Crowdsale
     *
     */
	function closeCrowdSale(){
		require(beneficiary == msg.sender);
		if ( beneficiary == msg.sender) {
			crowdsaleClosed = true;
		}
	}
	
    /**
     * Check token balance
     *
     */
	function checkTokenBalance(){
		if ( beneficiary == msg.sender) {
			//check current token balance
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
    /**
     * Withdraw the all funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. 
     */
    function safeWithdrawalAll() {
        if ( beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
				remainAmount = remainAmount - amountRaised;
            } else {
				WithdrawFailed(beneficiary, amountRaised, false);
				//If we fail to send the funds to beneficiary
            }
        }
    }
	
	/**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. 
     */
    function safeWithdrawalAmount(uint256 withdrawAmount) {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(withdrawAmount)) {
                FundTransfer(beneficiary, withdrawAmount, false);
				remainAmount = remainAmount - withdrawAmount;
            } else {
				WithdrawFailed(beneficiary, withdrawAmount, false);
				//If we fail to send the funds to beneficiary
            }
        }
    }
	
	/**
	 * Withdraw IQT 
     * 
	 * If there are some remaining IQT in the contract 
	 * after all token are distributed the contributor,
	 * the beneficiary can withdraw the IQT in the contract
     *
     */
    function withdrawIQT(uint256 tokenAmount) afterCrowdsaleClosed {
		require(beneficiary == msg.sender);
        if (isIQTDistributed && beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, tokenAmount);
			// update token balance
			tokenBalance = tokenReward.balanceOf(address(this));
        }
    }
	

	/**
     * Distribute token
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * distribute token to contributor. 
     */
	function distributeIQTToken() {
		if (beneficiary == msg.sender) {  // only IQT_FUNDATION_ADDRESS can distribute the IQT
			address currentParticipantAddress;
			for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountIqtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountIqtToken);
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			// check if all IQT are distributed
			checkIfAllIQTDistributed();
			// get latest token balance
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	/**
     * Distribute token by batch
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * distribute token to contributor. 
     */
	function distributeIQTTokenBatch(uint batchUserCount) {
		if (beneficiary == msg.sender) {  // only IQT_FUNDATION_ADDRESS can distribute the IQT
			address currentParticipantAddress;
			uint transferedUserCount = 0;
			for (uint index = 0; index < contributorCount && transferedUserCount<batchUserCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountIqtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountIqtToken);
					transferedUserCount = transferedUserCount + 1;
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			// check if all IQT are distributed
			checkIfAllIQTDistributed();
			// get latest token balance
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	/**
	 * Check if all contributor&#39;s token are successfully distributed
	 */
	function checkIfAllIQTDistributed(){
	    address currentParticipantAddress;
		isIQTDistributed = true;
		for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
			if (false == contributorList[currentParticipantAddress].isTokenDistributed){
				isIQTDistributed = false;
				break;
			}
		}
	}
	
}