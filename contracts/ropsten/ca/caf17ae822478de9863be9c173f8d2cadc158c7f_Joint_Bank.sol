/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

/* */
struct Account
{
    address accountAddress;
    uint accountBalance;
    bool hasVotedCurrentRound;
}

/* The Joint Bank is created by a Bank Owner. The Owner adds a set number of 
 * addresses that become registered accounts. Accounts may propose payments to 
 * other registered accounts, but the payment will not go through until the 
 * majority (not counting the Owner) either approve or deny it. */
contract Joint_Bank
{
    // Public 
    uint256 constant public MAX_NUM_OF_JOINT_ACCOUNTS = 3;
    uint256 constant public STARTING_ACCOUNT_BALANCE = 500;

    address public bankOwner;
    
    // Private
    uint private numberOfAccounts;
    Account[] private accountArray;
    mapping(address => uint256) private accountId;
    
    bool votingIsInSession;
    uint numberOfApproveVotes;
    uint numberOfDenyVotes;
    uint currentProposedAmountToPay;
    uint currentDestinationId;
    uint currentProposerAccountId;
    
    uint majorityVal;
    
    uint totalNumOfProposals;
    bool lastProposalWasApproved;
    
    /* */
    modifier onlyOwnerMod
    {
        require(msg.sender == bankOwner, "Only the bank owner can call this function.");
        _;
    }
    
    /* */
    modifier hasRegisteredAccountMod
    {
        require( accountId[msg.sender] > 0, "Your account must be registered to call this function.");
        _;
    }
    
    /* */
    modifier bankHasSufficientRegisteredAccountsMod
    {
        require(numberOfAccounts >= MAX_NUM_OF_JOINT_ACCOUNTS, "The bank does not have enough registered accounts.");
        _;
    }
    
    /* */
    modifier votingUnderwayMod
    {
        require(votingIsInSession, "Voting must be underway to call this function.");
        _;
    }
    
    /* PUBLIC FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    /* The caller of the constructor is automatically set as the Bank Owner. */
    constructor()
    {
        bankOwner = msg.sender;
        
        // Set vars 
        numberOfAccounts = 0;
        accountArray.push();
        totalNumOfProposals = 0;
        lastProposalWasApproved = false;
        
        // Set all vote-related vars to their defaults
        resetVotingState();
        
        // Since majorityVal is an int, it automatically truncates the decimal
        majorityVal = (MAX_NUM_OF_JOINT_ACCOUNTS / 2) + 1;
    }
    
    /* Only the bank owner can create a new account.
     * New accounts start out with a beginning balance. */
    function createNewAccount(address newUserAddr) onlyOwnerMod public 
    {
        // Ensures we do not exceed the account limit 
        require(numberOfAccounts < MAX_NUM_OF_JOINT_ACCOUNTS, "No more accounts can be created.");
        
        // Ensures the same user doesn't make more than one account 
        require(accountId[newUserAddr] == 0, "The entered address is already tied to an existing account.");
        
        // Update
        numberOfAccounts++;
        accountId[newUserAddr] = numberOfAccounts;
        
        // Actually add the new user to our array
        accountArray.push();
        accountArray[numberOfAccounts].accountAddress = newUserAddr;
        accountArray[numberOfAccounts].accountBalance = STARTING_ACCOUNT_BALANCE;
        accountArray[numberOfAccounts].hasVotedCurrentRound = false;
    }
    
    /* Transitions the bank state to voting if it is not already in that state
     * (if a vote is already in session, the newly proposed payment will 
     *  automatically be rejected).*/
    function proposeNewPayment(uint payment, address addr) bankHasSufficientRegisteredAccountsMod hasRegisteredAccountMod public 
    {
        require(!votingIsInSession, "A vote is already underway.  It must complete first before a new payment can be proposed.");
        require(accountId[addr] != 0, "You can only propose payments to accounts that are registered with the bank.");
        require(addr != msg.sender, "You cannot propose a payment to your own account.");
        require(accountArray[accountId[msg.sender]].accountBalance >= payment, "You cannot propose a payment that is more than your current balance.");
        
        // Set proper vars
        currentProposedAmountToPay = payment;
        currentDestinationId = accountId[addr];
        currentProposerAccountId = accountId[msg.sender];
        votingIsInSession = true;
        
        // The payment proposer is obviously in agreement
        accountArray[accountId[msg.sender]].hasVotedCurrentRound = true;
        numberOfApproveVotes++;
    }
    
    /* Allows registered accounts to cast their vote once. Votes cannot be changed
     * after they are received. */
    function castVote(bool inApproval) votingUnderwayMod hasRegisteredAccountMod public returns (string memory)
    {
        // Ensure we have not already voted this round 
        if (accountArray[accountId[msg.sender]].hasVotedCurrentRound)
            return "You have already voted this round.";
        
        // Update our appropriate counter 
        if (inApproval)
            numberOfApproveVotes++;
        else
            numberOfDenyVotes++;
        
        // Make sure we set our account var 
        accountArray[accountId[msg.sender]].hasVotedCurrentRound = true;
        
        /* Check if we have sufficient information to approve/disapprove the proposal */
        if (numberOfApproveVotes != numberOfDenyVotes)
        {
            if (numberOfApproveVotes >= majorityVal)
                sufficientVotesReceived(true);
            else if (numberOfDenyVotes >= majorityVal)
                sufficientVotesReceived(false);
        }
        /* Else addresses the edge case wherein a tie exists after everyone has voted*/
        else
        {
            // If there is a tie, the payment is automatically rejected
            if (numberOfApproveVotes + numberOfDenyVotes >= numberOfAccounts)
                sufficientVotesReceived(false);
        }
        
        return "Your vote has been received.";
    }
    
    /* PRIVATE FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    /* Carries out the payment if approved. Voting state is reset whether approved or denied. */
    function sufficientVotesReceived(bool isApproved) votingUnderwayMod private
    {
        if (isApproved)
        {
            // Subtract the proposed amount from the proposer's account...
            accountArray[currentProposerAccountId].accountBalance -= currentProposedAmountToPay;
            
            //... and add it to the destination address
            accountArray[currentDestinationId].accountBalance += currentProposedAmountToPay;
        }
        
        totalNumOfProposals++;
        lastProposalWasApproved = isApproved;
        
        // Make sure we reset all appropriate vars
        resetVotingState();
    }
    
    /* Resets variables such that a new vote can be proposed. */
    function resetVotingState() private
    {
        numberOfApproveVotes = 0;
        numberOfDenyVotes = 0;
        currentProposedAmountToPay = 0;
        currentDestinationId = 0;
        currentProposerAccountId = 0;
        
        // Iterate through each account and reset their voting status
        for(uint i=1; i <= numberOfAccounts; i++)
        {
            accountArray[i].hasVotedCurrentRound = false;
        }
        
        votingIsInSession = false;
    }
    
    /* GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    /* */
    function getVotingIsInSession() hasRegisteredAccountMod public view returns (bool)
    {
        return votingIsInSession;
    }
    
    /* */
    function getProposedAmount() hasRegisteredAccountMod votingUnderwayMod public view returns (uint)
    {
        return currentProposedAmountToPay;
    }
    
    /* */
    function getProposedDestinationAccountAddress() hasRegisteredAccountMod votingUnderwayMod public view returns (address)
    {
        return accountArray[currentDestinationId].accountAddress;
    }
    
    /* */
    function getAccountAddressOfProposer() hasRegisteredAccountMod votingUnderwayMod public view returns (address)
    {
        return accountArray[currentProposerAccountId].accountAddress;
    }
    
    /* */
    function getIfIVotedCurrentRound() hasRegisteredAccountMod public view returns (bool)
    {
        return accountArray[accountId[msg.sender]].hasVotedCurrentRound;
    }
    
    /* */
    function getDecisionOfLastProposal() hasRegisteredAccountMod public view returns (string memory)
    {
        if (totalNumOfProposals > 0)
        {
            if (lastProposalWasApproved)
                return "The last proposal was APPROVED.";
            else
                return "The last proposal was DENIED.";
        }
        
        return "Currently, NO VOTES have been finalized.";
    }
    
    /* */
    function getMyCurrentBalance() hasRegisteredAccountMod public view returns (uint)
    {
        return accountArray[accountId[msg.sender]].accountBalance;
    }

    
}