pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AbstractPaymentEscrow is Ownable {

    address public wallet;

    mapping (uint => uint) public deposits;

    event Payment(address indexed _customer, uint indexed _projectId, uint value);
    event Withdraw(address indexed _wallet, uint value);

    function withdrawFunds() public;

    /**
     * @dev Change the wallet
     * @param _wallet address of the wallet where fees will be transfered when spent
     */
    function changeWallet(address _wallet)
        public
        onlyOwner()
    {
        wallet = _wallet;
    }

    /**
     * @dev Get the amount deposited for the provided project, returns 0 if there&#39;s no deposit for that project or the amount in wei
     * @param _projectId The id of the project
     * @return 0 if there&#39;s either no deposit for _projectId, otherwise returns the deposited amount in wei
     */
    function getDeposit(uint _projectId)
        public
        constant
        returns (uint)
    {
        return deposits[_projectId];
    }
}

contract TokitRegistry is Ownable {

    struct ProjectContracts {
        address token;
        address fund;
        address campaign;
    }

    // registrar => true/false
    mapping (address => bool) public registrars;

    // customer => project_id => token/campaign
    mapping (address => mapping(uint => ProjectContracts)) public registry;
    // project_id => token/campaign
    mapping (uint => ProjectContracts) public project_registry;

    event RegisteredToken(address indexed _projectOwner, uint indexed _projectId, address _token, address _fund);
    event RegisteredCampaign(address indexed _projectOwner, uint indexed _projectId, address _campaign);

    modifier onlyRegistrars() {
        require(registrars[msg.sender]);
        _;
    }

    function TokitRegistry(address _owner) {
        setRegistrar(_owner, true);
        transferOwnership(_owner);
    }

    function register(address _customer, uint _projectId, address _token, address _fund)
        onlyRegistrars()
    {
        registry[_customer][_projectId].token = _token;
        registry[_customer][_projectId].fund = _fund;

        project_registry[_projectId].token = _token;
        project_registry[_projectId].fund = _fund;

        RegisteredToken(_customer, _projectId, _token, _fund);
    }

    function register(address _customer, uint _projectId, address _campaign)
        onlyRegistrars()
    {
        registry[_customer][_projectId].campaign = _campaign;

        project_registry[_projectId].campaign = _campaign;

        RegisteredCampaign(_customer, _projectId, _campaign);
    }

    function lookup(address _customer, uint _projectId)
        constant
        returns (address token, address fund, address campaign)
    {
        return (
            registry[_customer][_projectId].token,
            registry[_customer][_projectId].fund,
            registry[_customer][_projectId].campaign
        );
    }

    function lookupByProject(uint _projectId)
        constant
        returns (address token, address fund, address campaign)
    {
        return (
            project_registry[_projectId].token,
            project_registry[_projectId].fund,
            project_registry[_projectId].campaign
        );
    }

    function setRegistrar(address _registrar, bool enabled)
        onlyOwner()
    {
        registrars[_registrar] = enabled;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

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

/// @title Fund contract - Implements reward distribution.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ef9c9b8a898e81c1888a809d888aaf8c80819c8a819c969cc1818a9b">[email&#160;protected]</a>>
/// @author Milad Mostavi - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e28f8b8e8386cc8f8d919683948ba2818d8c91878c919b91cc8c8796">[email&#160;protected]</a>>
contract SingularDTVFund {
    string public version = "0.1.0";

    /*
     *  External contracts
     */
    AbstractSingularDTVToken public singularDTVToken;

    /*
     *  Storage
     */
    address public owner;
    uint public totalReward;

    // User&#39;s address => Reward at time of withdraw
    mapping (address => uint) public rewardAtTimeOfWithdraw;

    // User&#39;s address => Reward which can be withdrawn
    mapping (address => uint) public owed;

    modifier onlyOwner() {
        // Only guard is allowed to do this action.
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    /*
     *  Contract functions
     */
    /// @dev Deposits reward. Returns success.
    function depositReward()
        public
        payable
        returns (bool)
    {
        totalReward += msg.value;
        return true;
    }

    /// @dev Withdraws reward for user. Returns reward.
    /// @param forAddress user&#39;s address.
    function calcReward(address forAddress) private returns (uint) {
        return singularDTVToken.balanceOf(forAddress) * (totalReward - rewardAtTimeOfWithdraw[forAddress]) / singularDTVToken.totalSupply();
    }

    /// @dev Withdraws reward for user. Returns reward.
    function withdrawReward()
        public
        returns (uint)
    {
        uint value = calcReward(msg.sender) + owed[msg.sender];
        rewardAtTimeOfWithdraw[msg.sender] = totalReward;
        owed[msg.sender] = 0;
        if (value > 0 && !msg.sender.send(value)) {
            revert();
        }
        return value;
    }

    /// @dev Credits reward to owed balance.
    /// @param forAddress user&#39;s address.
    function softWithdrawRewardFor(address forAddress)
        external
        returns (uint)
    {
        uint value = calcReward(forAddress);
        rewardAtTimeOfWithdraw[forAddress] = totalReward;
        owed[forAddress] += value;
        return value;
    }

    /// @dev Setup function sets external token address.
    /// @param singularDTVTokenAddress Token address.
    function setup(address singularDTVTokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(singularDTVToken) == 0) {
            singularDTVToken = AbstractSingularDTVToken(singularDTVTokenAddress);
            return true;
        }
        return false;
    }

    /// @dev Contract constructor function sets guard address.
    function SingularDTVFund() {
        // Set owner address
        owner = msg.sender;
    }

    /// @dev Fallback function acts as depositReward()
    function ()
        public
        payable
    {
        if (msg.value == 0) {
            withdrawReward();
        } else {
            depositReward();
        }
    }
}

/// @title Token Creation contract - Implements token creation functionality.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f88b8c9d9e9996d69f9d978a9f9db89b97968b9d968b818bd6969d8c">[email&#160;protected]</a>>
/// @author Razvan Pop - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6b190a111d0a05451b041b2b080405180e0518121845050e1f">[email&#160;protected]</a>>
/// @author Milad Mostavi - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="87eaeeebe6e3a9eae8f4f3e6f1eec7e4e8e9f4e2e9f4fef4a9e9e2f3">[email&#160;protected]</a>>
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

contract AbstractSingularDTVFund {
    function softWithdrawRewardFor(address forAddress) returns (uint);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/// @title Token contract - Implements token issuance.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="97e4e3f2f1f6f9b9f0f2f8e5f0f2d7f4f8f9e4f2f9e4eee4b9f9f2e3">[email&#160;protected]</a>>
/// @author Milad Mostavi - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="026f6b6e63662c6f6d717663746b42616d6c71676c717b712c6c6776">[email&#160;protected]</a>>
contract SingularDTVToken is StandardToken {
    string public version = "0.1.0";

    /*
     *  External contracts
     */
    AbstractSingularDTVFund public singularDTVFund;

    /*
     *  Token meta data
     */
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param to Address of token receiver.
    /// @param value Number of tokens to transfer.
    function transfer(address to, uint256 value)
        returns (bool)
    {
        // Both parties withdraw their reward first
        singularDTVFund.softWithdrawRewardFor(msg.sender);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transfer(to, value);
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param from Address from where tokens are withdrawn.
    /// @param to Address to where tokens are sent.
    /// @param value Number of tokens to transfer.
    function transferFrom(address from, address to, uint256 value)
        returns (bool)
    {
        // Both parties withdraw their reward first
        singularDTVFund.softWithdrawRewardFor(from);
        singularDTVFund.softWithdrawRewardFor(to);
        return super.transferFrom(from, to, value);
    }

    function SingularDTVToken(address sDTVFundAddr, address _wallet, string _name, string _symbol, uint _totalSupply) {
        if(sDTVFundAddr == 0 || _wallet == 0) {
            // Fund and Wallet addresses should not be null.
            revert();
        }

        balances[_wallet] = _totalSupply;
        totalSupply = _totalSupply;

        name = _name;
        symbol = _symbol;

        singularDTVFund = AbstractSingularDTVFund(sDTVFundAddr);

        Transfer(this, _wallet, _totalSupply);
    }
}

contract TokitDeployer is Ownable {

    TokitRegistry public registry;

    // payment_type => payment_contract
    mapping (uint8 => AbstractPaymentEscrow) public paymentContracts;

    event DeployedToken(address indexed _customer, uint indexed _projectId, address _token, address _fund);
    event DeployedCampaign(address indexed _customer, uint indexed _projectId, address _campaign);


    function TokitDeployer(address _owner, address _registry) {
        transferOwnership(_owner);
        registry = TokitRegistry(_registry);
    }

    function deployToken(
        address _customer, uint _projectId, uint8 _payedWith, uint _amountNeeded,
        // SingularDTVToken
        address _wallet, string _name, string _symbol, uint _totalSupply
    )
        onlyOwner()
    {
        // payed for
        require(AbstractPaymentEscrow(paymentContracts[_payedWith]).getDeposit(_projectId) >= _amountNeeded);

        var (t,,) = registry.lookup(_customer, _projectId);
        // not deployed yet
        require(t == address(0));


        SingularDTVFund fund = new SingularDTVFund();
        SingularDTVToken token = new SingularDTVToken(fund, _wallet, _name, _symbol, _totalSupply);
        fund.setup(token);

        registry.register(_customer, _projectId, token, fund);

        DeployedToken(_customer, _projectId, token, fund);
    }

    function deployCampaign(
        address _customer, uint _projectId,
        // SingularDTVLaunch
        address _workshop, uint _total, uint _unitPrice, uint _duration, uint _threshold, uint _networkFee
    )
        onlyOwner()
    {
        var (t,f,c) = registry.lookup(_customer, _projectId);
        // not deployed yet
        require(c == address(0));

        // payed for, token & fund deployed
        require(t != address(0) && f != address(0));

        SingularDTVLaunch campaign = new SingularDTVLaunch(t, _workshop, _customer, _total, _unitPrice, _duration, _threshold, _networkFee);

        registry.register(_customer, _projectId, campaign);

        DeployedCampaign(_customer, _projectId, campaign);
    }

    function setRegistryContract(address _registry)
        onlyOwner()
    {
        registry = TokitRegistry(_registry);
    }

    function setPaymentContract(uint8 _paymentType, address _paymentContract)
        onlyOwner()
    {
        paymentContracts[_paymentType] = AbstractPaymentEscrow(_paymentContract);
    }

    function deletePaymentContract(uint8 _paymentType)
        onlyOwner()
    {
        delete paymentContracts[_paymentType];
    }
}