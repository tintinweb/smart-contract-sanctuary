/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

/**
 *Submitted for verification at Etherscan.io on 2019-01-22
*/

pragma solidity 0.4.24;


library SafeMath {

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


// source : https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract QuickxToken is ERC20 {
    using SafeMath for uint;


    // ------------------------------------------------------------------------
    //            EVENTS
    // ------------------------------------------------------------------------
    event LogBurn(address indexed from, uint256 amount);
    event LogFreezed(address targetAddress, bool frozen);
    event LogEmerygencyFreezed(bool emergencyFreezeStatus);

    // ------------------------------------------------------------------------
    //          STATE VARIABLES
    // ------------------------------------------------------------------------
    string public name = "QuickX Protocol";
    string public symbol = "QCX";
    uint8 public decimals = 8;
    address public owner;
    uint public totalSupply = 500000000 * (10 ** 8);
    uint public currentSupply = 250000000 * (10 ** 8); // 50% of total supply
    bool public emergencyFreeze = true;
  
    // ------------------------------------------------------------------------
    //              MAPPINNGS
    // ------------------------------------------------------------------------
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint) ) private  allowed;
    mapping (address => bool) private frozen;

    // ------------------------------------------------------------------------
    //              CONSTRUCTOR
    // ------------------------------------------------------------------------
    constructor () public {
        owner = address(0xda0cfbA981dBC502158D09B3090FCB366d362956);
    }

    // ------------------------------------------------------------------------
    //              MODIFIERS
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier unfreezed(address _account) { 
        require(!frozen[_account]);
        _;  
    }
    
    modifier noEmergencyFreeze() { 
        require(!emergencyFreeze);
        _; 
    }

    // ------------------------------------------------------------------------
    // Transfer Token
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _value)
    public
    unfreezed(_to) 
    unfreezed(msg.sender) 
    noEmergencyFreeze()  
    returns (bool success) {
        require(_to != 0x0);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Approve others to spend on your behalf
    //  RACE CONDITION HANDLED
    // ------------------------------------------------------------------------
    function approve(address _spender, uint _value)
        public 
        unfreezed(_spender) 
        unfreezed(msg.sender) 
        noEmergencyFreeze() 
        returns (bool success) {
            // To change the approve amount you first have to reduce the addresses`
            //  allowance to zero by calling `approve(_spender, 0)` if it is not
            //  already 0 to mitigate the race condition described here:
            //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
            require((_value == 0) || (allowed[msg.sender][_spender] == 0));
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }

    function increaseApproval(address _spender, uint _addedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success) {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success) {
            uint oldAllowance = allowed[msg.sender][_spender];
            if (_subtractedValue > oldAllowance) {
                allowed[msg.sender][_spender] = 0;
            } else {
                allowed[msg.sender][_spender] = oldAllowance.sub(_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }

    // ------------------------------------------------------------------------
    // Transferred approved amount from other's account
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _value)
        public 
        unfreezed(_to)
        unfreezed(_from) 
        noEmergencyFreeze() 
        returns (bool success) {
            require(_value <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }

    // ------------------------------------------------------------------------
    //               ONLYOWNER METHODS                             
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // Freeze account - onlyOwner
    // ------------------------------------------------------------------------
    function freezeAccount (address _target, bool _freeze) public onlyOwner {
        require(_target != 0x0);
        frozen[_target] = _freeze;
        emit LogFreezed(_target, _freeze);
    }

    // ------------------------------------------------------------------------
    // Emerygency freeze - onlyOwner
    // ------------------------------------------------------------------------
    function emergencyFreezeAllAccounts (bool _freeze) public onlyOwner {
        emergencyFreeze = _freeze;
        emit LogEmerygencyFreezed(_freeze);
    }

    // ------------------------------------------------------------------------
    // Burn (Destroy tokens)
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        currentSupply = currentSupply.sub(_value);
        emit LogBurn(msg.sender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    //               CONSTANT METHODS
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // Check Balance : Constant
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public view returns (uint) {
        return balances[_tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Total supply : Constant
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    // ------------------------------------------------------------------------
    // Check Allowance : Constant
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public view returns (uint) {
        return allowed[_tokenOwner][_spender];
    }

    // ------------------------------------------------------------------------
    // Get Freeze Status : Constant
    // ------------------------------------------------------------------------
    function isFreezed(address _targetAddress) public view returns (bool) {
        return frozen[_targetAddress]; 
    }

    function _transfer(address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        uint balBeforeTransfer = balances[from].add(balances[to]);
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        uint balAfterTransfer = balances[from].add(balances[to]);
        assert(balBeforeTransfer == balAfterTransfer);
        emit Transfer(from, to, amount);
    }
}


contract QuickxProtocol is QuickxToken {
    using SafeMath for uint;
    // ------------------------------------------------------------------------
    //          STATE VARIABLES  00000000
    // ------------------------------------------------------------------------
    // 50% of totail coins will be sold in ico
    uint public tokenSaleAllocation = 250000000 * (10 ** 8);
    // 2% of total supply goes for bounty 
    uint public bountyAllocation = 10000000 * (10 ** 8); 
    //13% of total tokens is reserved for founders and team
    uint public founderAllocation =  65000000 * (10 ** 8); 
    //5% of total tokens is reserved for partners
    uint public partnersAllocation = 25000000 * (10 ** 8); 
    // 15% of total tokens is for Liquidity reserve
    uint public liquidityReserveAllocation = 75000000 * (10 ** 8); 
    //5% of total tokens is reserved for advisors
    uint public advisoryAllocation = 25000000 * (10 ** 8); 
    //10% of total tokens in reserved for pre-seed Inverstors
    uint public preSeedInvestersAllocation = 50000000 * (10 ** 8); 
    
    uint[] public founderFunds = [
        1300000000000000,
        2600000000000000, 
        3900000000000000, 
        5200000000000000, 
        6500000000000000
    ]; // 8 decimals included

    uint[] public advisoryFunds = [
        500000000000000, 
        1000000000000000,
        1500000000000000, 
        2000000000000000, 
        2500000000000000
    ];

    uint public founderFundsWithdrawn = 0;
    uint public advisoryFundsWithdrawn = 0;
    // check allcatios
    bool public bountyAllocated;
    //bool public founderAllocated;
    bool public partnersAllocated;
    bool public liquidityReserveAllocated;
    bool public preSeedInvestersAllocated;
    
    uint public icoSuccessfulTime;
    bool public isIcoSuccessful;

    address public beneficiary;   // address of hard wallet of admin. 

    // ico state variables
    uint private totalRaised = 0;     // total wei raised by ICO
    uint private totalCoinsSold = 0;   // total coins sold in ICO
    uint private softCap;             // soft cap target in ether
    uint private hardCap;             // hard cap target in ether
    // rate is number of tokens (including decimals) per wei
    uint private rateNum;              // rate numerator (to avoid fractions) (rate = rateNum/rateDeno)
    uint private rateDeno;              // rate denominator (to avoid fractions) (rate = rateNum/rateDeno)
    uint public tokenSaleStart;       // time when token sale starts
    uint public tokenSaleEnds;        // time when token sale ends
    bool public icoPaused;            // ICO can be paused anytime

    // ------------------------------------------------------------------------
    //                EVENTS
    // ------------------------------------------------------------------------
    event LogBontyAllocated(
        address recepient, 
        uint amount);

    event LogPartnersAllocated(
        address recepient, 
        uint amount);

    event LogLiquidityreserveAllocated(
        address recepient, 
        uint amount);

    event LogPreSeedInverstorsAllocated(
        address recepient,
        uint amount);

    event LogAdvisorsAllocated(
        address recepient, 
        uint amount);

    event LogFoundersAllocated(
        address indexed recepient, 
        uint indexed amount);
    
    // ico events
    event LogFundingReceived(
        address indexed addr, 
        uint indexed weiRecieved, 
        uint indexed tokenTransferred, 
        uint currentTotal);

    event LogRateUpdated(
        uint rateNum, 
        uint rateDeno); 

    event LogPaidToOwner(
        address indexed beneficiary,
        uint indexed amountPaid);

    event LogWithdrawnRemaining(
        address _owner, 
        uint amountWithdrawan);

    event LogIcoEndDateUpdated(
        uint _oldEndDate, 
        uint _newEndDate);

    event LogIcoSuccessful();
    
    /* mappings */
    mapping (address => uint) public contributedAmount; // amount contributed by a user

    // ------------------------------------------------------------------------
    //               CONSTRUCTOR
    // ------------------------------------------------------------------------
    constructor () public {
        owner = address(0x2cf93Eed42d4D0C0121F99a4AbBF0d838A004F64);
        rateNum = 75;
        rateDeno = 100000000;
        softCap = 4000  ether;
        hardCap = 30005019135500000000000  wei;
        tokenSaleStart = now;
        tokenSaleEnds = now;
        balances[this] = currentSupply;
        isIcoSuccessful = true;
        icoSuccessfulTime = now;
        beneficiary = address(0x2cf93Eed42d4D0C0121F99a4AbBF0d838A004F64);
        emit LogIcoSuccessful();
        emit Transfer(0x0, address(this), currentSupply);
    }

    /* Fallback function */
    function () public payable {
        require(msg.data.length == 0);
        contribute();
    }

    modifier isFundRaising() { 
        require(
            totalRaised <= hardCap &&
            now >= tokenSaleStart &&
            now < tokenSaleEnds &&
            !icoPaused
            );
        _;
    }

    // ------------------------------------------------------------------------
    //                ONLY OWNER METHODS
    // ------------------------------------------------------------------------
    function allocateBountyTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!bountyAllocated); 
        balances[owner] = balances[owner].add(bountyAllocation);
        currentSupply = currentSupply.add(bountyAllocation);
        bountyAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogBontyAllocated(owner, bountyAllocation);
        emit Transfer(0x0, owner, bountyAllocation);
    }

    function allocatePartnersTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!partnersAllocated);
        balances[owner] = balances[owner].add(partnersAllocation);
        currentSupply = currentSupply.add(partnersAllocation);
        partnersAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogPartnersAllocated(owner, partnersAllocation);
        emit Transfer(0x0, owner, partnersAllocation);
    }

    function allocateLiquidityReserveTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!liquidityReserveAllocated);
        balances[owner] = balances[owner].add(liquidityReserveAllocation);
        currentSupply = currentSupply.add(liquidityReserveAllocation);
        liquidityReserveAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogLiquidityreserveAllocated(owner, liquidityReserveAllocation);
        emit Transfer(0x0, owner, liquidityReserveAllocation);
    }

    function allocatePreSeedInvesterTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        require(!preSeedInvestersAllocated);
        balances[owner] = balances[owner].add(preSeedInvestersAllocation);
        currentSupply = currentSupply.add(preSeedInvestersAllocation);
        preSeedInvestersAllocated = true;
        assert(currentSupply <= totalSupply);
        emit LogPreSeedInverstorsAllocated(owner, preSeedInvestersAllocation);
        emit Transfer(0x0, owner, preSeedInvestersAllocation);
    }

    function allocateFounderTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        uint calculatedFunds = calculateFoundersTokens();
        uint eligibleFunds = calculatedFunds.sub(founderFundsWithdrawn);
        require(eligibleFunds > 0);
        balances[owner] = balances[owner].add(eligibleFunds);
        currentSupply = currentSupply.add(eligibleFunds);
        founderFundsWithdrawn = founderFundsWithdrawn.add(eligibleFunds);
        assert(currentSupply <= totalSupply);
        emit LogFoundersAllocated(owner, eligibleFunds);
        emit Transfer(0x0, owner, eligibleFunds);
    }

    function allocateAdvisoryTokens() public onlyOwner {
        require(isIcoSuccessful && icoSuccessfulTime > 0);
        uint calculatedFunds = calculateAdvisoryTokens();
        uint eligibleFunds = calculatedFunds.sub(advisoryFundsWithdrawn);
        require(eligibleFunds > 0);
        balances[owner] = balances[owner].add(eligibleFunds);
        currentSupply = currentSupply.add(eligibleFunds);
        advisoryFundsWithdrawn = advisoryFundsWithdrawn.add(eligibleFunds);
        assert(currentSupply <= totalSupply);
        emit LogAdvisorsAllocated(owner, eligibleFunds);
        emit Transfer(0x0, owner, eligibleFunds);
    }

    // there is no explicit need of this function as funds are directly transferred to owner's hardware wallet.
    // but this is kept just to avoid any case when ETH is locked in contract
    function withdrawEth () public onlyOwner {
        owner.transfer(address(this).balance);
        emit LogPaidToOwner(owner, address(this).balance);
    }

    function updateRate (uint _rateNum, uint _rateDeno) public onlyOwner {
        rateNum = _rateNum;
        rateDeno = _rateDeno;
        emit LogRateUpdated(rateNum, rateDeno);
    }

    function updateIcoEndDate(uint _newDate) public onlyOwner {
        uint oldEndDate = tokenSaleEnds;
        tokenSaleEnds = _newDate;
        emit LogIcoEndDateUpdated (oldEndDate, _newDate);
    }

    // admin can withdraw token not sold in ICO
    function withdrawUnsold() public onlyOwner returns (bool) {
        require(now > tokenSaleEnds);
        uint unsold = (tokenSaleAllocation.sub(totalCoinsSold));
        balances[owner] = balances[owner].add(unsold);
        balances[address(this)] = balances[address(this)].sub(unsold);
        emit LogWithdrawnRemaining(owner, unsold);
        emit Transfer(address(this), owner, unsold);
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
        // this condition is to stop admin from withdrawing funds unless all funds of ICO are successfully settelled
        if (_tokenAddress == address(this)) {
            require(now > tokenSaleStart + 730 days); // expecting 2 years time, all vested funds will be released.
        }
        return ERC20(_tokenAddress).transfer(owner, _value);
    }

    function pauseICO(bool pauseStatus) public onlyOwner returns (bool status) {
        require(icoPaused != pauseStatus);
        icoPaused = pauseStatus;
        return true;
    }

    // ------------------------------------------------------------------------
    //               PUBLIC METHODS
    // ------------------------------------------------------------------------
    function contribute () public payable isFundRaising returns(bool) {
        uint calculatedTokens =  calculateTokens(msg.value);
        require(calculatedTokens > 0);
        require(totalCoinsSold.add(calculatedTokens) <= tokenSaleAllocation);
        contributedAmount[msg.sender] = contributedAmount[msg.sender].add(msg.value);
        totalRaised = totalRaised.add(msg.value);
        totalCoinsSold = totalCoinsSold.add(calculatedTokens);
        _transfer(address(this), msg.sender, calculatedTokens);
        beneficiary.transfer(msg.value);
        checkIfSoftCapReached();
        emit LogFundingReceived(msg.sender, msg.value, calculatedTokens, totalRaised);
        emit LogPaidToOwner(beneficiary, msg.value);
        return true;
    }

    // ------------------------------------------------------------------------
    //              CONSTANT METHODS
    // ------------------------------------------------------------------------
    function calculateTokens(uint weisToTransfer) public view returns(uint) {
        uint discount = calculateDiscount();
        uint coins = weisToTransfer.mul(rateNum).mul(discount).div(100 * rateDeno);
        return coins;
    }

    function getTotalWeiRaised () public view returns(uint totalEthRaised) {
        return totalRaised;
    }

    function getTotalCoinsSold() public view returns(uint _coinsSold) {
        return totalCoinsSold;
    }
      
    function getSoftCap () public view returns(uint _softCap) {
        return softCap;
    }

    function getHardCap () public view returns(uint _hardCap) {
        return hardCap;
    }

    function getContractOwner () public view returns(address contractOwner) {
        return owner;
    }

    function isContractAcceptingPayment() public view returns (bool) {
        if (totalRaised < hardCap && 
            now >= tokenSaleStart && 
            now < tokenSaleEnds && 
            totalCoinsSold < tokenSaleAllocation)
            return true;
        else
            return false;
    }

    // ------------------------------------------------------------------------
    //                INTERNAL METHODS
    // ------------------------------------------------------------------------
    function calculateFoundersTokens() internal view returns(uint) {
        uint timeAferIcoSuceess = now.sub(icoSuccessfulTime);
        uint timeSpendInMonths = timeAferIcoSuceess.div(30 days);
        if (timeSpendInMonths >= 3 && timeSpendInMonths < 6) {
            return founderFunds[0];
        } else  if (timeSpendInMonths >= 6 && timeSpendInMonths < 9) {
            return founderFunds[1];
        } else if (timeSpendInMonths >= 9 && timeSpendInMonths < 12) {
            return founderFunds[2];
        } else if (timeSpendInMonths >= 12 && timeSpendInMonths < 18) {
            return founderFunds[3];
        } else if (timeSpendInMonths >= 18) {
            return founderFunds[4];
        } else {
            revert();
        }
    } 

    function calculateAdvisoryTokens()internal view returns(uint) {
        uint timeSpentAfterIcoEnd = now.sub(icoSuccessfulTime);
        uint timeSpendInMonths = timeSpentAfterIcoEnd.div(30 days);
        if (timeSpendInMonths >= 0 && timeSpendInMonths < 3)
            return advisoryFunds[0];
        if (timeSpendInMonths < 6)
            return advisoryFunds[1];
        if (timeSpendInMonths < 9)
            return advisoryFunds[2];
        if (timeSpendInMonths < 12)
            return advisoryFunds[3];
        if (timeSpendInMonths >= 12)
            return advisoryFunds[4];
        revert();
    }

    function checkIfSoftCapReached() internal returns (bool) {
        if (totalRaised >= softCap && !isIcoSuccessful) {
            isIcoSuccessful = true;
            icoSuccessfulTime = now;
            emit LogIcoSuccessful();
        }
        return;
    }

    function calculateDiscount() internal view returns(uint) {
        if (totalCoinsSold < 12500000000000000) {
            return 115;   // 15 % discount
        } else if (totalCoinsSold < 18750000000000000) {
            return 110;   // 10 % discount
        } else if (totalCoinsSold < 25000000000000000) {
            return 105;   // 5 % discount
        } else {  // this case should never arise
            return 100;   // 0 % discount
        }
    }

}