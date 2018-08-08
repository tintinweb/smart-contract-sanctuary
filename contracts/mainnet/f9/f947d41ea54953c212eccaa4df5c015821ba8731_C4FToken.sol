pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;C4F&#39; Coins4Favors contracts
//
// contracts for C4FEscrow and C4FToken Crowdsale
//
// (c) C4F Ltd Hongkong 2018
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// &#39;C4F&#39; FavorEscrow contract
//
// Escrow contract for favor request
// allows to reserve tokens till a favor is completed, cancelled or arbitrated
// handles requester and provider interaction, payout, cancellation and
// arbitration if needed.
//
// (c) C4F Ltd Hongkong 2018
// ----------------------------------------------------------------------------

contract C4FEscrow {

    using SafeMath for uint;
    
    address public owner;
    address public requester;
    address public provider;

    uint256 public startTime;
    uint256 public closeTime;
    uint256 public deadline;
    
    uint256 public C4FID;
    uint8   public status;
    bool    public requesterLocked;
    bool    public providerLocked;
    bool    public providerCompleted;
    bool    public requesterDisputed;
    bool    public providerDisputed;
    uint8   public arbitrationCosts;

    event ownerChanged(address oldOwner, address newOwner);   
    event deadlineChanged(uint256 oldDeadline, uint256 newDeadline);
    event favorDisputed(address disputer);
    event favorUndisputed(address undisputer);
    event providerSet(address provider);
    event providerLockSet(bool lockstat);
    event providerCompletedSet(bool completed_status);
    event requesterLockSet(bool lockstat);
    event favorCompleted(address provider, uint256 tokenspaid);
    event favorCancelled(uint256 tokensreturned);
    event tokenOfferChanged(uint256 oldValue, uint256 newValue);
    event escrowArbitrated(address provider, uint256 coinsreturned, uint256 fee);

// ----------------------------------------------------------------------------
// modifiers used in this contract to restrict function calls
// ----------------------------------------------------------------------------

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }   

    modifier onlyRequester {
        require(msg.sender == requester);
        _;
    }   
    
    modifier onlyProvider {
        require(msg.sender == provider);
        _;
    }   

    modifier onlyOwnerOrRequester {
        require((msg.sender == owner) || (msg.sender == requester)) ;
        _;
    }   
    
    modifier onlyOwnerOrProvider {
        require((msg.sender == owner) || (msg.sender == provider)) ;
        _;        
    }
    
    modifier onlyProviderOrRequester {
        require((msg.sender == requester) || (msg.sender == provider)) ;
        _;        
    }

    // ----------------------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------------------
    function C4FEscrow(address newOwner, uint256 ID, address req, uint256 deadl, uint8 arbCostPercent) public {
        owner       = newOwner; // main contract
        C4FID       = ID;
        requester   = req;
        provider    = address(0);
        startTime   = now;
        deadline    = deadl;
        status      = 1;        // 1 = open, 2 = cancelled, 3=closed, 4=arbitrated
        arbitrationCosts    = arbCostPercent;
        requesterLocked     = false;
        providerLocked      = false;
        providerCompleted   = false;
        requesterDisputed   = false;
        providerDisputed    = false;
    }
    
    // ----------------------------------------------------------------------------
    // returns the owner of the Escrow contract. This is the main C4F Token contract
    // ----------------------------------------------------------------------------
    function getOwner() public view returns (address ownner) {
        return owner;
    } 
    
    function setOwner(address newOwner) public onlyOwner returns (bool success) {
        require(newOwner != address(0));
        ownerChanged(owner,newOwner);
        owner = newOwner;
        return true;
    }
    // ----------------------------------------------------------------------------
    // returns the Requester of the Escrow contract. This is the originator of the favor request
    // ----------------------------------------------------------------------------
    function getRequester() public view returns (address req) {
        return requester;
    }

    // ----------------------------------------------------------------------------
    // returns the Provider of the Escrow contract. This is the favor provider
    // ----------------------------------------------------------------------------
    function getProvider() public view returns (address prov) {
        return provider;
    }

    // ----------------------------------------------------------------------------
    // returns the startTime of the Escrow contract which is the time it was created
    // ----------------------------------------------------------------------------
    function getStartTime() public view returns (uint256 st) {
        return startTime;
    }    

    // ----------------------------------------------------------------------------
    // returns the Deadline of the Escrow contract by which completion is needed
    // Reqeuster can cancel the Escrow 12 hours after deadline expires if favor
    // is not marked as completed by provider
    // ----------------------------------------------------------------------------
    function getDeadline() public view returns (uint256 actDeadline) {
        actDeadline = deadline;
        return actDeadline;
    }
    
    // ----------------------------------------------------------------------------
    // adjusts the Deadline of the Escrow contract by which completion is needed
    // Reqeuster can only change this till a provider accepted (locked) the contract
    // ----------------------------------------------------------------------------
    function changeDeadline(uint newDeadline) public onlyRequester returns (bool success) {
        // deadline can only be changed if not locked by provider and not completed
        require ((!providerLocked) && (!providerDisputed) && (!providerCompleted) && (status==1));
        deadlineChanged(newDeadline, deadline);
        deadline = newDeadline;
        return true;
    }

    // ----------------------------------------------------------------------------
    // returns the status of the Escrow contract
    // ----------------------------------------------------------------------------
    function getStatus() public view returns (uint8 s) {
        return status;
    }

    // ----------------------------------------------------------------------------
    // Initiates dispute of the Escrow contract. Once requester or provider disputeFavor
    // because they cannot agree on completion, the C4F system can arbitrate the Escrow
    // based on the internal juror system.
    // ----------------------------------------------------------------------------
    function disputeFavor() public onlyProviderOrRequester returns (bool success) {
        if(msg.sender == requester) {
            requesterDisputed = true;
        }
        if(msg.sender == provider) {
            providerDisputed = true;
            providerLocked = true;
        }
        favorDisputed(msg.sender);
        return true;
    }
    // ----------------------------------------------------------------------------
    // Allows to take back a dispute on the Escrow if conflict has been resolved
    // ----------------------------------------------------------------------------
    function undisputeFavor() public onlyProviderOrRequester returns (bool success) {
        if(msg.sender == requester) {
            requesterDisputed = false;
        }
        if(msg.sender == provider) {
            providerDisputed = false;
        }
        favorUndisputed(msg.sender);
        return true;
    }
    
    // ----------------------------------------------------------------------------
    // allows to set the address of the provider for the Favor
    // this can be done by the requester or the C4F system
    // once the provider accepts, the providerLock flag disables changes to this
    // ----------------------------------------------------------------------------
    function setProvider(address newProvider) public onlyOwnerOrRequester returns (bool success) {
        // can only change provider if not locked by current provider
        require(!providerLocked);
        require(!requesterLocked);
        provider = newProvider;
        providerSet(provider);
        return true;
    }
    
    // ----------------------------------------------------------------------------
    // switches the ProviderLock on or off. Once provider lock is switched on, 
    // it means the provider has formally accepted the offer and changes are 
    // blocked
    // ----------------------------------------------------------------------------
    function setProviderLock(bool lock) public onlyOwnerOrProvider returns (bool res) {
        providerLocked = lock;
        providerLockSet(lock);
        return providerLocked;
    }

    // ----------------------------------------------------------------------------
    // allows to set Favor to completed from Provider view, indicating that 
    // provider sess Favor as delivered
    // ----------------------------------------------------------------------------
    function setProviderCompleted(bool c) public onlyOwnerOrProvider returns (bool res) {
        providerCompleted = c;
        providerCompletedSet(c);
        return c;
    }
    
    // ----------------------------------------------------------------------------
    // allows to set requester lock, indicating requester accepted favor provider
    // ----------------------------------------------------------------------------
    function setRequesterLock(bool lock) public onlyOwnerOrRequester returns (bool res) {
        requesterLocked = lock;
        requesterLockSet(lock);
        return requesterLocked;
    }
    

    function getRequesterLock() public onlyOwnerOrRequester view returns (bool res) {
        res = requesterLocked;
        return res;
    }


    // ----------------------------------------------------------------------------
    // allows the C4F system to change the status of an Escrow contract
    // ----------------------------------------------------------------------------
    function setStatus(uint8 newStatus) public onlyOwner returns (uint8 stat) {
        status = newStatus;    
        stat = status;
        return stat;
    }

    // ----------------------------------------------------------------------------
    // returns the current Token value of the escrow for competing the favor
    // this is the token balance of the escrow contract in the main contract
    // ----------------------------------------------------------------------------
    function getTokenValue() public view returns (uint256 tokens) {
        C4FToken C4F = C4FToken(owner);
        return C4F.balanceOf(address(this));
    }

    // ----------------------------------------------------------------------------
    // completes the favor Escrow and pays out the tokens minus the commission fee
    // ----------------------------------------------------------------------------
    function completeFavor() public onlyRequester returns (bool success) {
        // check if provider has been set
        require(provider != address(0));
        
        // payout tokens to provider with commission
        uint256 actTokenvalue = getTokenValue();
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transferWithCommission(provider, actTokenvalue)) revert();
        closeTime = now;
        status = 3;
        favorCompleted(provider,actTokenvalue);
        return true;
    }

    // ----------------------------------------------------------------------------
    // this function cancels a favor request on behalf of the requester
    // only possible as long as no provider accepted the contract or 12 hours
    // after the deadline if the provider did not indicate completion or disputed
    // ----------------------------------------------------------------------------
    function cancelFavor() public onlyRequester returns (bool success) {
        // cannot cancel if locked by provider unless deadline expired by 12 hours and not completed/disputed
        require((!providerLocked) || ((now > deadline.add(12*3600)) && (!providerCompleted) && (!providerDisputed)));
        // cannot cancel after completed or arbitrated
        require(status==1);
        // send tokens back to requester
        uint256 actTokenvalue = getTokenValue();
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transfer(requester,actTokenvalue)) revert();
        closeTime = now;
        status = 2;
        favorCancelled(actTokenvalue);
        return true;
    }
    
    // ----------------------------------------------------------------------------
    // allows the favor originator to reduce the token offer
    // This can only be done until a provider has accepted (locked) the favor request
    // ----------------------------------------------------------------------------
    function changeTokenOffer(uint256 newOffer) public onlyRequester returns (bool success) {
        // cannot change if locked by provider
        require((!providerLocked) && (!providerDisputed) && (!providerCompleted));
        // cannot change if cancelled, closed or arbitrated
        require(status==1);
        // only use for reducing tokens (to increase simply transfer tokens to contract)
        uint256 actTokenvalue = getTokenValue();
        require(newOffer < actTokenvalue);
        // cannot set to 0, use cancel to do that
        require(newOffer > 0);
        // pay back tokens to reach new offer level
        C4FToken C4F = C4FToken(owner);
        if(!C4F.transfer(requester, actTokenvalue.sub(newOffer))) revert();
        tokenOfferChanged(actTokenvalue,newOffer);
        return true;
    }
    
    // ----------------------------------------------------------------------------
    // arbitration can be done by the C4F system once requester or provider have
    // disputed the favor contract. An independent juror system on the platform 
    // will vote on the outcome and define a split of the tokens between the two
    // parties. The jurors get a percentage which is preset in the contratct for
    // the arbitration
    // ----------------------------------------------------------------------------
    function arbitrateC4FContract(uint8 percentReturned) public onlyOwner returns (bool success) {
        // can only arbitrate if one of the two parties has disputed 
        require((providerDisputed) || (requesterDisputed));
        // C4F System owner can arbitrate and provide a split of tokens between 0-100%
        uint256 actTokens = getTokenValue();
        
        // calc. arbitration fee based on percent costs
        uint256 arbitrationTokens = actTokens.mul(arbitrationCosts);
        arbitrationTokens = arbitrationTokens.div(100);
        // subtract these from the tokens to be distributed between requester and provider
        actTokens = actTokens.sub(arbitrationTokens);
        
        // now split the tokens up using provided percentage
        uint256 requesterTokens = actTokens.mul(percentReturned);
        requesterTokens = requesterTokens.div(100);
        // actTokens to hold what gets forwarded to provider
        actTokens = actTokens.sub(requesterTokens);
        
        // distribute the Tokens
        C4FToken C4F = C4FToken(owner);
        // arbitration tokens go to commissiontarget of master contract
        address commissionTarget = C4F.getCommissionTarget();
        // requester gets refunded his split
        if(!C4F.transfer(requester, requesterTokens)) revert();
        // provider gets his split of tokens
        if(!C4F.transfer(provider, actTokens)) revert();
        // arbitration fee to system for distribution
        if(!C4F.transfer(commissionTarget, arbitrationTokens)) revert();
        
        // set status & closeTime
        status = 4;
        closeTime = now;
        success = true;
        escrowArbitrated(provider,requesterTokens,arbitrationTokens);
        return success;
    }

}

// ----------------------------------------------------------------------------
// &#39;C4F&#39; &#39;Coins4Favors FavorCoin contract
//
// Symbol      : C4F
// Name        : FavorCoin
// Total supply: 100,000,000,000.000000000000000000
// Decimals    : 18
//
// includes the crowdsale price, PreICO bonus structure, limits on sellable tokens
// function to pause sale, commission fee transfer and favorcontract management
//
// (c) C4F Ltd Hongkong 2018
// ----------------------------------------------------------------------------

contract C4FToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint8 public _crowdsalePaused;
    uint public _totalSupply;
    uint public _salesprice;
    uint public _endOfICO;
    uint public _endOfPreICO;
    uint public _beginOfICO;
    uint public _bonusTime1;
    uint public _bonusTime2;
    uint public _bonusRatio1;
    uint public _bonusRatio2;
    uint public _percentSoldInPreICO;
    uint public _maxTokenSoldPreICO;
    uint public _percentSoldInICO;
    uint public _maxTokenSoldICO;
    uint public _total_sold;
    uint public _commission;
    uint8 public _arbitrationPercent;
    address public _commissionTarget;
    uint public _minimumContribution;
    address[]   EscrowAddresses;
    uint public _escrowIndex;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) whitelisted_amount;
    mapping(address => bool) C4FEscrowContracts;
    
    
    event newEscrowCreated(uint ID, address contractAddress, address requester);   
    event ICOStartSet(uint256 starttime);
    event ICOEndSet(uint256 endtime);
    event PreICOEndSet(uint256 endtime);
    event BonusTime1Set(uint256 bonustime);
    event BonusTime2Set(uint256 bonustime);
    event accountWhitelisted(address account, uint256 limit);
    event crowdsalePaused(bool paused);
    event crowdsaleResumed(bool resumed);
    event commissionSet(uint256 commission);
    event commissionTargetSet(address target);
    event arbitrationPctSet(uint8 arbpercent);
    event contractOwnerChanged(address escrowcontract, address newOwner);
    event contractProviderChanged(address C4Fcontract, address provider);
    event contractArbitrated(address C4Fcontract, uint8 percentSplit);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function C4FToken() public {
        symbol          = "C4F";
        name            = "C4F FavorCoins";
        decimals        = 18;
        
        _totalSupply    = 100000000000 * 10**uint(decimals);

        _salesprice     = 2000000;      // C4Fs per 1 Eth
        _minimumContribution = 0.05 * 10**18;    // minimum amount is 0.05 Ether
        
        _endOfICO       = 1532908800;   // end of ICO is 30.07.18
        _beginOfICO     = 1526342400;   // begin is 15.05.18
        _bonusRatio1    = 110;          // 10% Bonus in second week of PreICO
        _bonusRatio2    = 125;          // 25% Bonus in first week of PreICO
        _bonusTime1     = 1527638400;   // prior to 30.05.18 add bonusRatio1
        _bonusTime2     = 1526947200;   // prior to 22.05.18 add bonusRatio2
        _endOfPreICO    = 1527811200;   // Pre ICO ends 01.06.2018
        
        _percentSoldInPreICO = 10;      // we only offer 10% of total Supply during PreICO
        _maxTokenSoldPreICO = _totalSupply.mul(_percentSoldInPreICO);
        _maxTokenSoldPreICO = _maxTokenSoldPreICO.div(100);
        
        _percentSoldInICO   = 60;      // in addition to 10% sold in PreICO, 60% sold in ICO 
        _maxTokenSoldICO    = _totalSupply.mul(_percentSoldInPreICO.add(_percentSoldInICO));
        _maxTokenSoldICO    = _maxTokenSoldICO.div(100);
        
        _total_sold         = 0;            // total coins sold 
        
        _commission         = 0;            // no comission on transfers 
        _commissionTarget   = owner;        // default any commission goes to the owner of the contract
        _arbitrationPercent = 10;           // default costs for arbitration of an escrow contract
                                            // is transferred to escrow contract at time of creation and kept there
        
        _crowdsalePaused    = 0;

        balances[owner]     = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // notLocked: ensure no coins are moved by owners prior to end of ICO
    // ------------------------------------------------------------------------
    
    modifier notLocked {
        require((msg.sender == owner) || (now >= _endOfICO));
        _;
    }
    
    // ------------------------------------------------------------------------
    // onlyDuringICO: FavorCoins can only be bought via contract during ICO
    // ------------------------------------------------------------------------
    
    modifier onlyDuringICO {
        require((now >= _beginOfICO) && (now <= _endOfICO));
        _;
    }
    
    // ------------------------------------------------------------------------
    // notPaused: ability to stop crowdsale if problems occur
    // ------------------------------------------------------------------------
    
    modifier notPaused {
        require(_crowdsalePaused == 0);
        _;
    }
    
    // ------------------------------------------------------------------------
    // set ICO and PRE ICO Dates
    // ------------------------------------------------------------------------

    function setICOStart(uint ICOdate) public onlyOwner returns (bool success) {
        _beginOfICO  = ICOdate;
        ICOStartSet(_beginOfICO);
        return true;
    }
    
    function setICOEnd(uint ICOdate) public onlyOwner returns (bool success) {
        _endOfICO  = ICOdate;
        ICOEndSet(_endOfICO);
        return true;
    }
    
    function setPreICOEnd(uint ICOdate) public onlyOwner returns (bool success) {
        _endOfPreICO = ICOdate;
        PreICOEndSet(_endOfPreICO);
        return true;
    }
    
    function setBonusDate1(uint ICOdate) public onlyOwner returns (bool success) {
        _bonusTime1 = ICOdate;
        BonusTime1Set(_bonusTime1);
        return true;
    }

    function setBonusDate2(uint ICOdate) public onlyOwner returns (bool success) {
        _bonusTime2 = ICOdate;
        BonusTime2Set(_bonusTime2);
        return true;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Whitelist address up to maximum spending (AML and KYC)
    // ------------------------------------------------------------------------
    function whitelistAccount(address account, uint limit) public onlyOwner {
        whitelisted_amount[account] = limit*10**18;
        accountWhitelisted(account,limit);
    }
    
    // ------------------------------------------------------------------------
    // return maximum remaining whitelisted amount for account 
    // ------------------------------------------------------------------------
    function getWhitelistLimit(address account) public constant returns (uint limit) {
        return whitelisted_amount[account];
    }

    // ------------------------------------------------------------------------
    // Pause crowdsale in case of any problems
    // ------------------------------------------------------------------------
    function pauseCrowdsale() public onlyOwner returns (bool success) {
        _crowdsalePaused = 1;
        crowdsalePaused(true);
        return true;
    }

    function resumeCrowdsale() public onlyOwner returns (bool success) {
        _crowdsalePaused = 0;
        crowdsaleResumed(true);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Commission can be added later to a percentage of the transferred
    // C4F tokens for operating costs of the system. Percentage is capped at 2%
    // ------------------------------------------------------------------------
    function setCommission(uint comm) public onlyOwner returns (bool success) {
        require(comm < 200); // we allow a maximum of 2% commission
        _commission = comm;
        commissionSet(comm);
        return true;
    }

    function setArbitrationPercentage(uint8 arbitPct) public onlyOwner returns (bool success) {
        require(arbitPct <= 15); // we allow a maximum of 15% arbitration costs
        _arbitrationPercent = arbitPct;
        arbitrationPctSet(_arbitrationPercent);
        return true;
    }

    function setCommissionTarget(address ct) public onlyOwner returns (bool success) {
        _commissionTarget = ct;
        commissionTargetSet(_commissionTarget);
        return true;
    }
    
    function getCommissionTarget() public view returns (address ct) {
        ct = _commissionTarget;
        return ct;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // - users cannot transfer C4Fs prior to close of ICO
    // - only owner can transfer anytime to do airdrops, etc.
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public notLocked notPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // this function will be used by the C4F app to charge a Commission
    // on transfers later
    // ------------------------------------------------------------------------
    function transferWithCommission(address to, uint tokens) public notLocked notPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        // split tokens using commission Percentage
        uint comTokens = tokens.mul(_commission);
        comTokens = comTokens.div(10000);
        // adjust balances
        balances[to] = balances[to].add(tokens.sub(comTokens));
        balances[_commissionTarget] = balances[_commissionTarget].add(comTokens);
        // trigger events
        Transfer(msg.sender, to, tokens.sub(comTokens));
        Transfer(msg.sender, _commissionTarget, comTokens);
        return true;
    }

    
    // ------------------------------------------------------------------------
    // TransferInternal handles Transfer of Tokens from Owner during ICO and Pre-ICO
    // ------------------------------------------------------------------------
    function transferInternal(address to, uint tokens) private returns (bool success) {
        balances[owner] = balances[owner].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public notLocked notPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // not possivbe before end of ICO
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public notLocked notPaused returns (bool success) {
        // check allowance is high enough
        require(allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // startEscrow FavorContract
    // starts an escrow contract and transfers the tokens into the contract
    // ------------------------------------------------------------------------
    
    function startFavorEscrow(uint256 ID, uint256 deadl, uint tokens) public notLocked returns (address C4FFavorContractAddr) {
        // check if sufficient coins available
        require(balanceOf(msg.sender) >= tokens);
        // create contract
        address newFavor = new C4FEscrow(address(this), ID, msg.sender, deadl, _arbitrationPercent);
        // add to list of C4FEscrowContratcs
        EscrowAddresses.push(newFavor);
        C4FEscrowContracts[newFavor] = true;
        // transfer tokens to contract
        if(!transfer(newFavor, tokens)) revert();
        C4FFavorContractAddr = newFavor;
        newEscrowCreated(ID, newFavor, msg.sender);
        return C4FFavorContractAddr;
    }

    function isFavorEscrow(uint id, address c4fes) public view returns (bool res) {
        if(EscrowAddresses[id] == c4fes) {
                res = true;
            } else {
                res = false;
            }
        return res;
    }
    
    function getEscrowCount() public view returns (uint) {
        return EscrowAddresses.length;
    }
    
    function getEscrowAddress(uint ind) public view returns(address esa) {
        require (ind <= EscrowAddresses.length);
        esa = EscrowAddresses[ind];
        return esa;
    }
    
    
    // use this function to allow C4F System to adjust owner of C4FEscrows 
    function setC4FContractOwner(address C4Fcontract, address newOwner) public onlyOwner returns (bool success) {
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setProvider from there
        if(!c4fec.setOwner(newOwner)) revert();
        contractOwnerChanged(C4Fcontract,newOwner);
        return true;
    }
    
    // use this function to allow C4F System to adjust provider of C4F Favorcontract    
    function setC4FContractProvider(address C4Fcontract, address provider) public onlyOwner returns (bool success) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setProvider from there
        if(!c4fec.setProvider(provider)) revert();
        contractProviderChanged(C4Fcontract, provider);
        return true;
    }
    
    // use this function to allow C4F System to adjust providerLock 
    function setC4FContractProviderLock(address C4Fcontract, bool lock) public onlyOwner returns (bool res) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setProviderLock from there
        res = c4fec.setProviderLock(lock);
        return res;
    }
    
    // use this function to allow C4F System to adjust providerCompleted status
    function setC4FContractProviderCompleted(address C4Fcontract, bool completed) public onlyOwner returns (bool res) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setProviderCompleted from there
        res = c4fec.setProviderCompleted(completed);
        return res;
    }
    
        // use this function to allow C4F System to adjust providerLock 
    function setC4FContractRequesterLock(address C4Fcontract, bool lock) public onlyOwner returns (bool res) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setRequesterLock from there
        res = c4fec.setRequesterLock(lock);
        return res;
    }

    function setC4FContractStatus(address C4Fcontract, uint8 newStatus) public onlyOwner returns (uint8 s) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call setStatus from there
        s = c4fec.setStatus(newStatus);
        return s;
    }
    
    function arbitrateC4FContract(address C4Fcontract, uint8 percentSplit) public onlyOwner returns (bool success) {
        // ensure this is a C4FEscrowContract initiated by C4F system
        require(C4FEscrowContracts[C4Fcontract]);
        C4FEscrow c4fec = C4FEscrow(C4Fcontract);
        // call arbitration
        if(!c4fec.arbitrateC4FContract(percentSplit)) revert();
        contractArbitrated(C4Fcontract, percentSplit);
        return true;
    }

    
    // ------------------------------------------------------------------------
    // Convert to C4Fs using salesprice and bonus period and forward Eth to owner
    // ------------------------------------------------------------------------
    function () public onlyDuringICO notPaused payable  {
        // check bonus ratio
        uint bonusratio = 100;
        // check for second week bonus
        if(now <= _bonusTime1) {
            bonusratio = _bonusRatio1;    
        }
        // check for first week bonus
        if(now <= _bonusTime2) {
            bonusratio = _bonusRatio2;    
        }
        
        // minimum contribution met ?
        require (msg.value >= _minimumContribution);
        
        // send C4F tokens back to sender based on Ether received
        if (msg.value > 0) {
            
            // check if whitelisted and sufficient contribution left (AML & KYC)
            if(!(whitelisted_amount[msg.sender] >= msg.value)) revert();
            // reduce remaining contribution limit
            whitelisted_amount[msg.sender] = whitelisted_amount[msg.sender].sub(msg.value);
            
            // determine amount of C4Fs 
            uint256 token_amount = msg.value.mul(_salesprice);
            token_amount = token_amount.mul(bonusratio);
            token_amount = token_amount.div(100);
            
            uint256 new_total = _total_sold.add(token_amount);
            // check if PreICO volume sold off 
            if(now <= _endOfPreICO){
                // check if we are above the limit with this transfer, then bounce
                if(new_total > _maxTokenSoldPreICO) revert();
            }
            
            // check if exceeding total ICO sale tokens
            if(new_total > _maxTokenSoldICO) revert();
            
            // transfer tokens from owner account to sender
            if(!transferInternal(msg.sender, token_amount)) revert();
            _total_sold = new_total;
            // forward received ether to owner account
            if (!owner.send(msg.value)) revert(); // also reverts the transfer.
        }
    }
}