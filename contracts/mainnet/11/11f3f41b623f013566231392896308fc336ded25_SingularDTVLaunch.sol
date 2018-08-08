pragma solidity ^0.4.15;


contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract AbstractSingularDTVToken is Token {

}


/// @title Token Creation contract - Implements token creation functionality.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f6858293909798d8919399849193b6959998859398858f85d8989382">[email&#160;protected]</a>>
/// @author Razvan Pop - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1c6e7d666a7d72326c736c5c7f73726f79726f656f32727968">[email&#160;protected]</a>>
/// @author Milad Mostavi - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4a9ada8a5a0eaa9abb7b0a5b2ad84a7abaab7a1aab7bdb7eaaaa1b0">[email&#160;protected]</a>>
contract SingularDTVLaunch {
    string public version = "0.1.0";

    event Contributed(address indexed contributor, uint contribution, uint tokens);

    /*
     *  External contracts
     */
    AbstractSingularDTVToken public singularDTVToken;
    address public workshop;
    address public SingularDTVWorkshop = 0xc78310231aA53bD3D0FEA2F8c705C67730929D8f;
    uint public SingularDTVWorkshopFee;

    /*
     *  Constants
     */
    uint public CAP; // in wei scale of tokens
    uint public DURATION; // in seconds
    uint public TOKEN_TARGET; // Goal threshold in wei scale of tokens

    /*
     *  Enums
     */
    enum Stages {
        Deployed,
        GoingAndGoalNotReached,
        EndedAndGoalNotReached,
        GoingAndGoalReached,
        EndedAndGoalReached
    }

    /*
     *  Storage
     */
    address public owner;
    uint public startDate;
    uint public fundBalance;
    uint public valuePerToken; //in wei
    uint public tokensSent;

    // participant address => value in Wei
    mapping (address => uint) public contributions;

    // participant address => token amount in wei scale
    mapping (address => uint) public sentTokens;

    // Initialize stage
    Stages public stage = Stages.Deployed;

    modifier onlyOwner() {
        // Only owner is allowed to do this action.
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            revert();
        }
        _;
    }

    modifier atStageOR(Stages _stage1, Stages _stage2) {
        if (stage != _stage1 && stage != _stage2) {
            revert();
        }
        _;
    }

    modifier timedTransitions() {
        uint timeElapsed = now - startDate;

        if (timeElapsed >= DURATION) {
            if (stage == Stages.GoingAndGoalNotReached) {
                stage = Stages.EndedAndGoalNotReached;
            } else if (stage == Stages.GoingAndGoalReached) {
                stage = Stages.EndedAndGoalReached;
            }
        }
        _;
    }

    /*
     *  Contract functions
     */
    /// dev Validates invariants.
    function checkInvariants() constant internal {
        if (fundBalance > this.balance) {
            revert();
        }
    }

    /// @dev Can be triggered if an invariant fails.
    function emergencyCall()
        public
        returns (bool)
    {
        if (fundBalance > this.balance) {
            if (this.balance > 0 && !SingularDTVWorkshop.send(this.balance)) {
                revert();
            }
            return true;
        }
        return false;
    }

    /// @dev Allows user to create tokens if token creation is still going and cap not reached. Returns token count.
    function fund()
        public
        timedTransitions
        atStageOR(Stages.GoingAndGoalNotReached, Stages.GoingAndGoalReached)
        payable
        returns (uint)
    {
        uint tokenCount = (msg.value * (10**18)) / valuePerToken; // Token count in wei is rounded down. Sent ETH should be multiples of valuePerToken.
        require(tokenCount > 0);
        if (tokensSent + tokenCount > CAP) {
            // User wants to create more tokens than available. Set tokens to possible maximum.
            tokenCount = CAP - tokensSent;
        }
        tokensSent += tokenCount;

        uint contribution = (tokenCount * valuePerToken) / (10**18); // Ether spent by user.
        // Send change back to user.
        if (msg.value > contribution && !msg.sender.send(msg.value - contribution)) {
            revert();
        }
        // Update fund and user&#39;s balance and total supply of tokens.
        fundBalance += contribution;
        contributions[msg.sender] += contribution;
        sentTokens[msg.sender] += tokenCount;
        if (!singularDTVToken.transfer(msg.sender, tokenCount)) {
            // Tokens could not be issued.
            revert();
        }
        // Update stage
        if (stage == Stages.GoingAndGoalNotReached) {
            if (tokensSent >= TOKEN_TARGET) {
                stage = Stages.GoingAndGoalReached;
            }
        }
        // not an else clause for the edge case that the CAP and TOKEN_TARGET are reached in one call
        if (stage == Stages.GoingAndGoalReached) {
            if (tokensSent == CAP) {
                stage = Stages.EndedAndGoalReached;
            }
        }
        checkInvariants();

        Contributed(msg.sender, contribution, tokenCount);

        return tokenCount;
    }

    /// @dev Allows user to withdraw ETH if token creation period ended and target was not reached. Returns contribution.
    function withdrawContribution()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalNotReached)
        returns (uint)
    {
        // We get back the tokens from the contributor before giving back his contribution
        uint tokensReceived = sentTokens[msg.sender];
        sentTokens[msg.sender] = 0;
        if (!singularDTVToken.transferFrom(msg.sender, owner, tokensReceived)) {
            revert();
        }

        // Update fund&#39;s and user&#39;s balance and total supply of tokens.
        uint contribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        fundBalance -= contribution;
        // Send ETH back to user.
        if (contribution > 0) {
            msg.sender.transfer(contribution);
        }
        checkInvariants();
        return contribution;
    }

    /// @dev Withdraws ETH to workshop address. Returns success.
    function withdrawForWorkshop()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalReached)
        returns (bool)
    {
        uint value = fundBalance;
        fundBalance = 0;

        require(value > 0);

        uint networkFee = value * SingularDTVWorkshopFee / 100;
        workshop.transfer(value - networkFee);
        SingularDTVWorkshop.transfer(networkFee);

        uint remainingTokens = CAP - tokensSent;
        if (remainingTokens > 0 && !singularDTVToken.transfer(owner, remainingTokens)) {
            revert();
        }

        checkInvariants();
        return true;
    }

    /// @dev Allows owner to get back unsent tokens in case of launch failure (EndedAndGoalNotReached).
    function withdrawUnsentTokensForOwner()
        public
        timedTransitions
        atStage(Stages.EndedAndGoalNotReached)
        returns (uint)
    {
        uint remainingTokens = CAP - tokensSent;
        if (remainingTokens > 0 && !singularDTVToken.transfer(owner, remainingTokens)) {
            revert();
        }

        checkInvariants();
        return remainingTokens;
    }

    /// @dev Sets token value in Wei.
    /// @param valueInWei New value.
    function changeValuePerToken(uint valueInWei)
        public
        onlyOwner
        atStage(Stages.Deployed)
        returns (bool)
    {
        valuePerToken = valueInWei;
        return true;
    }

    // updateStage allows calls to receive correct stage. It can be used for transactions but is not part of the regular token creation routine.
    // It is not marked as constant because timedTransitions modifier is altering state and constant is not yet enforced by solc.
    /// @dev returns correct stage, even if a function with timedTransitions modifier has not yet been called successfully.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    function start()
        public
        onlyOwner
        atStage(Stages.Deployed)
        returns (uint)
    {
        if (!singularDTVToken.transferFrom(msg.sender, this, CAP)) {
            revert();
        }

        startDate = now;
        stage = Stages.GoingAndGoalNotReached;

        checkInvariants();
        return startDate;
    }

    /// @dev Contract constructor function sets owner and start date.
    function SingularDTVLaunch(
        address singularDTVTokenAddress,
        address _workshop,
        address _owner,
        uint _total,
        uint _unit_price,
        uint _duration,
        uint _threshold,
        uint _singulardtvwoskhop_fee
        ) {
        singularDTVToken = AbstractSingularDTVToken(singularDTVTokenAddress);
        workshop = _workshop;
        owner = _owner;
        CAP = _total; // Total number of tokens (wei scale)
        valuePerToken = _unit_price; // wei per token
        DURATION = _duration; // in seconds
        TOKEN_TARGET = _threshold; // Goal threshold
        SingularDTVWorkshopFee = _singulardtvwoskhop_fee;
    }

    /// @dev Fallback function acts as fund() when stage GoingAndGoalNotReached
    /// or GoingAndGoalReached. And act as withdrawFunding() when EndedAndGoalNotReached.
    /// otherwise throw.
    function ()
        public
        payable
    {
        if (stage == Stages.GoingAndGoalNotReached || stage == Stages.GoingAndGoalReached)
            fund();
        else if (stage == Stages.EndedAndGoalNotReached)
            withdrawContribution();
        else
            revert();
    }
}