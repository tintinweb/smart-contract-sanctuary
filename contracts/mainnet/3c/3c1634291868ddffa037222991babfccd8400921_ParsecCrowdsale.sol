pragma solidity 0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract ParsecTokenERC20 {
    // Public variables of the token
    string public constant name = "Parsec Credits";
    string public constant symbol = "PRSC";
    uint8 public decimals = 6;
    uint256 public initialSupply = 30856775800;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function ParsecTokenERC20() public {
        // Update total supply with the decimal amount
        totalSupply = initialSupply * 10 ** uint256(decimals);

        // Give the creator all initial tokens
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);

        // Check if the sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);

        // Subtract from the sender
        balanceOf[msg.sender] -= _value;

        // Updates totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(msg.sender, _value);

        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Check if the targeted balance is enough
        require(balanceOf[_from] >= _value);

        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        // Subtract from the targeted balance
        balanceOf[_from] -= _value;

        // Subtract from the sender&#39;s allowance
        allowance[_from][msg.sender] -= _value;

        // Update totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(_from, _value);

        return true;
    }
}


contract ParsecCrowdsale is owned {
    /// @notice Use OpenZeppelin&#39;s SafeMath
    using SafeMath for uint256;

    /// @notice Define KYC states
    enum KycState {
        Undefined,  // 0
        Pending,    // 1
        Accepted,   // 2
        Declined    // 3
    }

    // -------------------------
    // --- General constants ---
    // -------------------------

    /// @notice Minimum ETH amount per transaction
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 0.1 ether;

    /// @notice Base rate of parsec credits per 1 ETH
    uint256 public constant PARSECS_PER_ETHER_BASE = 1300000000000;      // 1,300,000.000000 PRSC

    /// @notice Crowdsale hard cap in Parsecs
    uint256 public constant PARSECS_TOTAL_AMOUNT = 16103862002000000;    // 16,103,862,002.000000 PRSC

    // ----------------------------
    // --- Bonus tier constants ---
    // ----------------------------
    
    uint256 public constant BONUS_TIER_1_LIMIT = 715 ether;     // 30.0 % bonus Parsecs
    uint256 public constant BONUS_TIER_2_LIMIT = 1443 ether;    // 27.5 % bonus Parsecs
    uint256 public constant BONUS_TIER_3_LIMIT = 2434 ether;    // 25.0 % bonus Parsecs
    uint256 public constant BONUS_TIER_4_LIMIT = 3446 ether;    // 22.5 % bonus Parsecs
    uint256 public constant BONUS_TIER_5_LIMIT = 4478 ether;    // 20.0 % bonus Parsecs
    uint256 public constant BONUS_TIER_6_LIMIT = 5532 ether;    // 17.5 % bonus Parsecs
    uint256 public constant BONUS_TIER_7_LIMIT = 6609 ether;    // 15.0 % bonus Parsecs
    uint256 public constant BONUS_TIER_8_LIMIT = 7735 ether;    // 10.0 % bonus Parsecs
    uint256 public constant BONUS_TIER_9_LIMIT = 9210 ether;    // 5.00 % bonus Parsecs

    // ------------------------
    // --- Input parameters ---
    // ------------------------

    /// @notice Parsec ERC20 token address (from previously deployed contract)
    ParsecTokenERC20 private parsecToken;

    // @notice Multisig account address to collect accepted ETH
    address public multisigAddress;

    // @notice Auditor account address to perform KYC accepts and declines
    address public auditorAddress;

    // ---------------------------
    // --- Power-up parameters ---
    // ---------------------------

    /// @notice Keep track if contract is powered up (has enough Parsecs)
    bool public contractPoweredUp = false;

    /// @notice Keep track if contract has enough ETH to perform refunds
    bool public refundPoweredUp = false;

    // ---------------------------
    // --- State parameters ---
    // ---------------------------

    /// @notice Keep track if contract is started (permanently, works if contract is powered up) 
    bool public contractStarted = false;

    /// @notice Keep track if contract is finished (permanently, works if contract is started) 
    bool public contractFinished = false;

    /// @notice Keep track if contract is paused (transiently, works if contract started and not finished) 
    bool public contractPaused = false;

    /// @notice Keep track if contract is failed (permanently, works if contract started and not finished) 
    bool public contractFailed = false;

    /// @notice Keep track if contract refund is started
    bool public contractRefundStarted = false;

    /// @notice Keep track if contract refund is finished
    bool public contractRefundFinished = false;

    // ------------------------
    // --- Funding tracking ---
    // ------------------------

    /// @notice Keep track of total amount of funding raised and passed KYC
    uint256 public raisedFunding;
       
    /// @notice Keep track of funding amount pending KYC check
    uint256 public pendingFunding;

    /// @notice Keep track of refunded funding
    uint256 public refundedFunding;

    // ------------------------
    // --- Parsecs tracking ---
    // ------------------------

    /// @notice Keep track of spent Parsecs amount (transferred to participants)
    uint256 public spentParsecs;
    
    /// @notice Keep track of pending Parsecs amount (participant pending KYC)
    uint256 public pendingParsecs;

    // ----------------
    // --- Balances ---
    // ----------------

    /// @notice Keep track of all contributions per account passed KYC
    mapping (address => uint256) public contributionOf;

    /// @notice Keep track of all Parsecs granted to participants after they passed KYC
    mapping (address => uint256) public parsecsOf;

    /// @notice Keep track of all contributions pending KYC
    mapping (address => uint256) public pendingContributionOf;

    /// @notice Keep track of all Parsecs&#39; rewards pending KYC
    mapping (address => uint256) public pendingParsecsOf;

    /// @notice Keep track of all refunds per account
    mapping (address => uint256) public refundOf;

    // -----------------------------------------
    // --- KYC (Know-Your-Customer) tracking ---
    // -----------------------------------------

    /// @notice Keep track of participants&#39; KYC status
    mapping (address => KycState) public kycStatus;

    // --------------
    // --- Events ---
    // --------------

    /// @notice Log an event for each KYC accept
    event LogKycAccept(address indexed sender, uint256 value, uint256 timestamp);

    /// @notice Log an event for each KYC decline
    event LogKycDecline(address indexed sender, uint256 value, uint256 timestamp);

    /// @notice Log an event for each contributed amount passed KYC
    event LogContribution(address indexed sender, uint256 ethValue, uint256 parsecValue, uint256 timestamp);

    /**
     * Constructor function
     *
     * Initializes smart contract
     *
     * @param _tokenAddress The address of the previously deployed ParsecTokenERC20 contract
     * @param _multisigAddress The address of the Multisig wallet to redirect payments to
     * @param _auditorAddress The address of the Auditor account which will accept or decline investors&#39; KYC
     */
    function ParsecCrowdsale (address _tokenAddress, address _multisigAddress, address _auditorAddress) public {
        // Get Parsec ERC20 token instance
        parsecToken = ParsecTokenERC20(_tokenAddress);

        // Store Multisig wallet and Auditor addresses
        multisigAddress = _multisigAddress;
        auditorAddress = _auditorAddress;
    }

    /// @notice Allows only contract owner or Multisig to proceed
    modifier onlyOwnerOrMultisig {
        require(msg.sender == owner || msg.sender == multisigAddress);
        _;
    }

    /// @notice Allows only contract owner or Auditor to proceed
    modifier onlyOwnerOrAuditor {
        require(msg.sender == owner || msg.sender == auditorAddress);
        _;
    }

    /// @notice A participant sends a contribution to the contract&#39;s address
    ///         when contract is active, not failed and not paused 
    /// @notice Only contributions above the MINIMUM_PARTICIPATION_AMOUNT are
    ///         accepted. Otherwise the transaction is rejected and contributed
    ///         amount is returned to the participant&#39;s account
    /// @notice A participant&#39;s contribution will be rejected if it exceeds
    ///         the hard cap
    /// @notice A participant&#39;s contribution will be rejected if the hard
    ///         cap is reached
    function () public payable {
        // Contract should be powered up
        require(contractPoweredUp);

        // Сontract should BE started
        require(contractStarted);

        // Сontract should NOT BE finished
        require(!contractFinished);

        // Сontract should NOT BE paused
        require(!contractPaused);

        // Сontract should NOT BE failed
        require(!contractFailed);

        // A participant cannot send less than the minimum amount
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);

        // Calculate amount of Parsecs to reward
        uint256 parsecValue = calculateReward(msg.value);

        // Calculate maximum amount of Parsecs smart contract can provide
        uint256 maxAcceptableParsecs = PARSECS_TOTAL_AMOUNT.sub(spentParsecs);
        maxAcceptableParsecs = maxAcceptableParsecs.sub(pendingParsecs);

        // A participant cannot receive more Parsecs than contract has to offer
        require(parsecValue <= maxAcceptableParsecs);

        // Check if participant&#39;s KYC state is Undefined and set it to Pending
        if (kycStatus[msg.sender] == KycState.Undefined) {
            kycStatus[msg.sender] = KycState.Pending;
        }

        if (kycStatus[msg.sender] == KycState.Pending) {
            // KYC is Pending: register pending contribution
            addPendingContribution(msg.sender, msg.value, parsecValue);
        } else if (kycStatus[msg.sender] == KycState.Accepted) {
            // KYC is Accepted: register accepted contribution
            addAcceptedContribution(msg.sender, msg.value, parsecValue);
        } else {
            // KYC is Declined: revert transaction
            revert();
        }
    }

    /// @notice Contract owner or Multisig can withdraw Parsecs anytime in case of emergency
    function emergencyWithdrawParsecs(uint256 value) external onlyOwnerOrMultisig {
        // Amount of Parsecs to withdraw should not exceed current balance
        require(value > 0);
        require(value <= parsecToken.balanceOf(this));

        // Transfer parsecs
        parsecToken.transfer(msg.sender, value);
    }

    /// @notice Contract owner or Multisig can refund contract with ETH in case of failed Crowdsale
    function emergencyRefundContract() external payable onlyOwnerOrMultisig {
        // Contract should be failed previously
        require(contractFailed);
        
        // Amount of ETH should be positive
        require(msg.value > 0);
    }

    /// @notice Contract owner or Multisig can clawback ether after refund period is finished
    function emergencyClawbackEther(uint256 value) external onlyOwnerOrMultisig {
        // Contract should be failed previously
        require(contractFailed);

        // Contract refund should be started and finished previously
        require(contractRefundStarted);
        require(contractRefundFinished);
        
        // Amount of ETH should be positive and not exceed current contract balance
        require(value > 0);
        require(value <= address(this).balance);

        // Transfer ETH to Multisig
        msg.sender.transfer(value);
    }

    /// @notice Set Auditor account address to a new value
    function ownerSetAuditor(address _auditorAddress) external onlyOwner {
        // Auditor address cannot be zero
        require(_auditorAddress != 0x0);

        // Change Auditor account address
        auditorAddress = _auditorAddress;
    }

    /// @notice Check if contract has enough Parsecs to cover hard cap
    function ownerPowerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractPoweredUp);

        // Contract should have enough Parsec credits
        require(parsecToken.balanceOf(this) >= PARSECS_TOTAL_AMOUNT);

        // Raise contract power-up flag
        contractPoweredUp = true;
    }

    /// @notice Start contract (permanently)
    function ownerStartContract() external onlyOwner {
        // Contract should be powered up previously
        require(contractPoweredUp);

        // Contract should not be started previously
        require(!contractStarted);

        // Raise contract started flag
        contractStarted = true;
    }

    /// @notice Finish contract (permanently)
    function ownerFinishContract() external onlyOwner {
        // Contract should be started previously
        require(contractStarted);

        // Contract should not be finished previously
        require(!contractFinished);

        // Raise contract finished flag
        contractFinished = true;
    }

    /// @notice Pause contract (transiently)
    function ownerPauseContract() external onlyOwner {
        // Contract should be started previously
        require(contractStarted);

        // Contract should not be finished previously
        require(!contractFinished);

        // Contract should not be paused previously
        require(!contractPaused);

        // Raise contract paused flag
        contractPaused = true;
    }

    /// @notice Resume contract (transiently)
    function ownerResumeContract() external onlyOwner {
        // Contract should be paused previously
        require(contractPaused);

        // Unset contract paused flag
        contractPaused = false;
    }

    /// @notice Declare Crowdsale failure (no more ETH are accepted from participants)
    function ownerDeclareFailure() external onlyOwner {
        // Contract should NOT BE failed previously
        require(!contractFailed);

        // Raise contract failed flag
        contractFailed = true;
    }

    /// @notice Declare Crowdsale refund start
    function ownerDeclareRefundStart() external onlyOwner {
        // Contract should BE failed previously
        require(contractFailed);

        // Contract refund should NOT BE started previously
        require(!contractRefundStarted);

        // Contract should NOT have any pending KYC requests
        require(pendingFunding == 0x0);

        // Contract should have enough ETH to perform refunds
        require(address(this).balance >= raisedFunding);

        // Raise contract refund started flag
        contractRefundStarted = true;
    }

    /// @notice Declare Crowdsale refund finish
    function ownerDeclareRefundFinish() external onlyOwner {
        // Contract should BE failed previously
        require(contractFailed);

        // Contract refund should BE started previously
        require(contractRefundStarted);

        // Contract refund should NOT BE finished previously
        require(!contractRefundFinished);

        // Raise contract refund finished flag
        contractRefundFinished = true;
    }

    /// @notice Owner can withdraw Parsecs only after contract is finished
    function ownerWithdrawParsecs(uint256 value) external onlyOwner {
        // Contract should be finished before any Parsecs could be withdrawn
        require(contractFinished);

        // Get smart contract balance in Parsecs
        uint256 parsecBalance = parsecToken.balanceOf(this);

        // Calculate maximal amount to withdraw
        uint256 maxAmountToWithdraw = parsecBalance.sub(pendingParsecs);

        // Maximal amount to withdraw should be greater than zero and not greater than total balance
        require(maxAmountToWithdraw > 0);
        require(maxAmountToWithdraw <= parsecBalance);

        // Amount of Parsecs to withdraw should not exceed maxAmountToWithdraw
        require(value > 0);
        require(value <= maxAmountToWithdraw);

        // Transfer parsecs
        parsecToken.transfer(owner, value);
    }
 
    /// @dev Accept participant&#39;s KYC
    function acceptKyc(address participant) external onlyOwnerOrAuditor {
        // Set participant&#39;s KYC status to Accepted
        kycStatus[participant] = KycState.Accepted;

        // Get pending amounts in ETH and Parsecs
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

        // Log an event of the participant&#39;s KYC accept
        LogKycAccept(participant, pendingAmountOfEth, now);

        if (pendingAmountOfEth > 0 || pendingAmountOfParsecs > 0) {
            // Reset pending contribution
            resetPendingContribution(participant);

            // Add accepted contribution
            addAcceptedContribution(participant, pendingAmountOfEth, pendingAmountOfParsecs);
        }
    }

    /// @dev Decline participant&#39;s KYC
    function declineKyc(address participant) external onlyOwnerOrAuditor {
        // Set participant&#39;s KYC status to Declined
        kycStatus[participant] = KycState.Declined;

        // Log an event of the participant&#39;s KYC decline
        LogKycDecline(participant, pendingAmountOfEth, now);

        // Get pending ETH amount
        uint256 pendingAmountOfEth = pendingContributionOf[participant];

        if (pendingAmountOfEth > 0) {
            // Reset pending contribution
            resetPendingContribution(participant);

            // Transfer ETH back to participant
            participant.transfer(pendingAmountOfEth);
        }
    }

    /// @dev Allow participants to clawback ETH in case of Crowdsale failure
    function participantClawbackEther(uint256 value) external {
        // Participant cannot withdraw ETH if refund is not started or after it is finished
        require(contractRefundStarted);
        require(!contractRefundFinished);

        // Get total contribution of participant
        uint256 totalContribution = contributionOf[msg.sender];

        // Get already refunded amount
        uint256 alreadyRefunded = refundOf[msg.sender];

        // Calculate maximal withdrawal amount
        uint256 maxWithdrawalAmount = totalContribution.sub(alreadyRefunded);

        // Maximal withdrawal amount should not be zero
        require(maxWithdrawalAmount > 0);

        // Requested value should not exceed maximal withdrawal amount
        require(value > 0);
        require(value <= maxWithdrawalAmount);

        // Participant&#39;s refundOf is increased by the claimed amount
        refundOf[msg.sender] = alreadyRefunded.add(value);

        // Total refound amount is increased
        refundedFunding = refundedFunding.add(value);

        // Send ethers back to the participant&#39;s account
        msg.sender.transfer(value);
    }

    /// @dev Register pending contribution
    function addPendingContribution(address participant, uint256 ethValue, uint256 parsecValue) private {
        // Participant&#39;s pending contribution is increased by ethValue
        pendingContributionOf[participant] = pendingContributionOf[participant].add(ethValue);

        // Parsecs pending to participant increased by parsecValue
        pendingParsecsOf[participant] = pendingParsecsOf[participant].add(parsecValue);

        // Increase pending funding by ethValue
        pendingFunding = pendingFunding.add(ethValue);

        // Increase pending Parsecs by parsecValue
        pendingParsecs = pendingParsecs.add(parsecValue);
    }

    /// @dev Register accepted contribution
    function addAcceptedContribution(address participant, uint256 ethValue, uint256 parsecValue) private {
        // Participant&#39;s contribution is increased by ethValue
        contributionOf[participant] = contributionOf[participant].add(ethValue);

        // Parsecs rewarded to participant increased by parsecValue
        parsecsOf[participant] = parsecsOf[participant].add(parsecValue);

        // Increase total raised funding by ethValue
        raisedFunding = raisedFunding.add(ethValue);

        // Increase spent Parsecs by parsecValue
        spentParsecs = spentParsecs.add(parsecValue);

        // Log an event of the participant&#39;s contribution
        LogContribution(participant, ethValue, parsecValue, now);

        // Transfer ETH to Multisig
        multisigAddress.transfer(ethValue);

        // Transfer Parsecs to participant
        parsecToken.transfer(participant, parsecValue);
    }

    /// @dev Reset pending contribution
    function resetPendingContribution(address participant) private {
        // Get amounts of pending ETH and Parsecs
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

        // Decrease pending contribution by pendingAmountOfEth
        pendingContributionOf[participant] = pendingContributionOf[participant].sub(pendingAmountOfEth);

        // Decrease pending Parsecs reward by pendingAmountOfParsecs
        pendingParsecsOf[participant] = pendingParsecsOf[participant].sub(pendingAmountOfParsecs);

        // Decrease pendingFunding by pendingAmountOfEth
        pendingFunding = pendingFunding.sub(pendingAmountOfEth);

        // Decrease pendingParsecs by pendingAmountOfParsecs
        pendingParsecs = pendingParsecs.sub(pendingAmountOfParsecs);
    }

    /// @dev Calculate amount of Parsecs to grant for ETH contribution
    function calculateReward(uint256 ethValue) private view returns (uint256 amount) {
        // Define base quotient
        uint256 baseQuotient = 1000;

        // Calculate actual quotient according to current bonus tier
        uint256 actualQuotient = baseQuotient.add(calculateBonusTierQuotient());

        // Calculate reward amount
        uint256 reward = ethValue.mul(PARSECS_PER_ETHER_BASE);
        reward = reward.mul(actualQuotient);
        reward = reward.div(baseQuotient);
        return reward.div(1 ether);
    }

    /// @dev Calculate current bonus tier quotient
    function calculateBonusTierQuotient() private view returns (uint256 quotient) {
        uint256 funding = raisedFunding.add(pendingFunding);

        if (funding < BONUS_TIER_1_LIMIT) {
            return 300;     // 30.0 % bonus Parsecs
        } else if (funding < BONUS_TIER_2_LIMIT) {
            return 275;     // 27.5 % bonus Parsecs
        } else if (funding < BONUS_TIER_3_LIMIT) {
            return 250;     // 25.0 % bonus Parsecs
        } else if (funding < BONUS_TIER_4_LIMIT) {
            return 225;     // 22.5 % bonus Parsecs
        } else if (funding < BONUS_TIER_5_LIMIT) {
            return 200;     // 20.0 % bonus Parsecs
        } else if (funding < BONUS_TIER_6_LIMIT) {
            return 175;     // 17.5 % bonus Parsecs
        } else if (funding < BONUS_TIER_7_LIMIT) {
            return 150;     // 15.0 % bonus Parsecs
        } else if (funding < BONUS_TIER_8_LIMIT) {
            return 100;     // 10.0 % bonus Parsecs
        } else if (funding < BONUS_TIER_9_LIMIT) {
            return 50;      // 5.00 % bonus Parsecs
        } else {
            return 0;       // 0.00 % bonus Parsecs
        }
    }
}