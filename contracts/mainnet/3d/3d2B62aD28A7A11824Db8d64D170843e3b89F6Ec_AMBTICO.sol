pragma solidity 0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract AMBToken {
    using SafeMath for uint256;

    string  public constant name     = "Ambit token";
    string  public constant symbol   = "AMBT";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    bool internal contractIsWorking = true;

    struct Investor {
        uint256 tokenBalance;
        uint256 icoInvest;
        bool    activated;
    }
    mapping(address => Investor) internal investors;
    mapping(address => mapping (address => uint256)) internal allowed;

    /*
            Dividend&#39;s Structures
    */
    uint256   internal dividendCandidate = 0;
    uint256[] internal dividends;

    enum ProfitStatus {Initial, StartFixed, EndFixed, Claimed}
    struct InvestorProfitData {
        uint256      start_balance;
        uint256      end_balance;
        ProfitStatus status;
    }

    mapping(address => mapping(uint32 => InvestorProfitData)) internal profits;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return investors[_owner].tokenBalance;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _approve(address _spender, uint256 _value) internal returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(investors[msg.sender].activated && contractIsWorking);
        return _approve(_spender, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= investors[_from].tokenBalance);

        fixDividendBalances(_to, false);

        investors[_from].tokenBalance = investors[_from].tokenBalance.sub(_value);
        investors[_to].tokenBalance = investors[_to].tokenBalance.add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(investors[msg.sender].activated && contractIsWorking);
        fixDividendBalances(msg.sender, false);
        return _transfer( msg.sender, _to,  _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(investors[msg.sender].activated && investors[_from].activated && contractIsWorking);
        require(_to != address(0));
        require(_value <= investors[_from].tokenBalance);
        require(_value <= allowed[_from][msg.sender]);

        fixDividendBalances(_from, false);
        fixDividendBalances(_to, false);

        investors[_from].tokenBalance = investors[_from].tokenBalance.sub(_value);
        investors[_to].tokenBalance   = investors[_to].tokenBalance.add(_value);
        allowed[_from][msg.sender]    = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /*
        Eligible token and balance helper function
     */
    function fixDividendBalances(address investor, bool revertIfClaimed) internal
        returns (InvestorProfitData storage current_profit, uint256 profit_per_token){

        uint32 next_id      = uint32(dividends.length);
        uint32 current_id   = next_id - 1;
        current_profit      = profits[investor][current_id];

        if (revertIfClaimed) require(current_profit.status != ProfitStatus.Claimed);
        InvestorProfitData storage next_profit      = profits[investor][next_id];

        if (current_profit.status == ProfitStatus.Initial) {

            current_profit.start_balance = investors[investor].tokenBalance;
            current_profit.end_balance   = investors[investor].tokenBalance;
            current_profit.status        = ProfitStatus.EndFixed;
            next_profit.start_balance = investors[investor].tokenBalance;
            next_profit.status        = ProfitStatus.StartFixed;

        } else if (current_profit.status == ProfitStatus.StartFixed) {

            current_profit.end_balance = investors[investor].tokenBalance;
            current_profit.status      = ProfitStatus.EndFixed;
            next_profit.start_balance = investors[investor].tokenBalance;
            next_profit.status        = ProfitStatus.StartFixed;
        }
        profit_per_token = dividends[current_id];
    }
}

contract AMBTICO is AMBToken {
    uint256 internal constant ONE_TOKEN           = 10 ** uint256(decimals);//just for convenience
    uint256 internal constant MILLION             = 1000000;                //just for convenience

    uint256 internal constant BOUNTY_QUANTITY     = 3120000;
    uint256 internal constant RESERV_QUANTITY     = 12480000;

    uint256 internal constant TOKEN_MAX_SUPPLY    = 104 * MILLION   * ONE_TOKEN;
    uint256 internal constant BOUNTY_TOKENS       = BOUNTY_QUANTITY * ONE_TOKEN;
    uint256 internal constant RESERV_TOKENS       = RESERV_QUANTITY * ONE_TOKEN;
    uint256 internal constant MIN_SOLD_TOKENS     = 200             * ONE_TOKEN;
    uint256 internal constant SOFTCAP             = BOUNTY_TOKENS + RESERV_TOKENS + 6 * MILLION * ONE_TOKEN;

    uint256 internal constant REFUND_PERIOD       = 60 days;
    uint256 internal constant KYC_REVIEW_PERIOD   = 60 days;

    address internal owner;
    address internal bountyManager;
    address internal dividendManager;
    address internal dApp;

    enum ContractMode {Initial, TokenSale, UnderSoftCap, DividendDistribution, Destroyed}
    ContractMode public mode = ContractMode.Initial;

    uint256 public icoFinishTime = 0;
    uint256 public tokenSold = 0;
    uint256 public etherCollected = 0;

    uint8   public currentSection = 0;
    uint[4] public saleSectionDiscounts = [ uint8(20), 10, 5];
    uint[4] public saleSectionPrice     = [ uint256(1000000000000000), 1125000000000000, 1187500000000000, 1250000000000000];//price: 0.40 0.45 0.475 0.50 cent | ETH/USD initial rate: 400
    uint[4] public saleSectionCount     = [ uint256(17 * MILLION), 20 * MILLION, 20 * MILLION, 47 * MILLION - (BOUNTY_QUANTITY+RESERV_QUANTITY)];
    uint[4] public saleSectionInvest    = [ uint256(saleSectionCount[0] * saleSectionPrice[0]),
                                                    saleSectionCount[1] * saleSectionPrice[1],
                                                    saleSectionCount[2] * saleSectionPrice[2],
                                                    saleSectionCount[3] * saleSectionPrice[3]];
    uint256 public buyBackPriceWei = 0 ether;

    event OwnershipTransferred          (address previousOwner, address newOwner);
    event BountyManagerAssigned         (address previousBountyManager, address newBountyManager);
    event DividendManagerAssigned       (address previousDividendManager, address newDividendManager);
    event DAppAssigned                  (address previousDApp, address newDApp);
    event ModeChanged                   (ContractMode  newMode, uint256 tokenBalance);
    event DividendDeclared              (uint32 indexed dividendID, uint256 profitPerToken);
    event DividendClaimed               (address indexed investor, uint256 amount);
    event BuyBack                       (address indexed requestor);
    event Refund                        (address indexed investor, uint256 amount);
    event Handbrake                     (ContractMode current_mode, bool functioning);
    event FundsAdded                    (address owner, uint256 amount);
    event FundsWithdrawal               (address owner, uint256 amount);
    event BountyTransfered              (address recipient, uint256 amount);
    event PriceChanged                  (uint256 newPrice);
    event BurnToken                     (uint256 amount);

    modifier grantOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier grantBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }

    modifier grantDividendManager() {
        require(msg.sender == dividendManager);
        _;
    }

    modifier grantDApp() {
        require(msg.sender == dApp);
        _;
    }
    function AMBTICO() public {
        owner = msg.sender;
        dividends.push(0);
    }

    function setTokenPrice(uint256 new_wei_price) public grantDApp {
        require(new_wei_price > 0);
        uint8 len = uint8(saleSectionPrice.length)-1;
        for (uint8 i=0; i<=len; i++) {
            uint256 prdsc = 100 - saleSectionDiscounts[i];
            saleSectionPrice[i]  = prdsc.mul(new_wei_price ).div(100);
            saleSectionInvest[i] = saleSectionPrice[i] * saleSectionCount[i];
        }
        emit PriceChanged(new_wei_price);
    }

    function startICO() public grantOwner {
        require(contractIsWorking);
        require(mode == ContractMode.Initial);
        require(bountyManager != 0x0);

        totalSupply = TOKEN_MAX_SUPPLY;

        investors[this].tokenBalance            = TOKEN_MAX_SUPPLY-(BOUNTY_TOKENS+RESERV_TOKENS);
        investors[bountyManager].tokenBalance   = BOUNTY_TOKENS;
        investors[owner].tokenBalance           = RESERV_TOKENS;

        tokenSold = investors[bountyManager].tokenBalance + investors[owner].tokenBalance;

        mode = ContractMode.TokenSale;
        emit ModeChanged(mode, investors[this].tokenBalance);
    }

    function getCurrentTokenPrice() public view returns(uint256) {
        require(currentSection < saleSectionCount.length);
        return saleSectionPrice[currentSection];
    }

    function () public payable {
        invest();
    }
    function invest() public payable {
       _invest(msg.sender,msg.value);
    }
    /* Used by ĐApp to accept Bitcoin transfers.*/
    function investWithBitcoin(address ethAddress, uint256 ethWEI) public grantDApp {
        _invest(ethAddress,ethWEI);
    }


    function _invest(address msg_sender, uint256 msg_value) internal {
        require(contractIsWorking);
        require(currentSection < saleSectionCount.length);
        require(mode == ContractMode.TokenSale);
        require(msg_sender != bountyManager);

        uint wei_value = msg_value;
        uint _tokens = 0;

        while (wei_value > 0 && (currentSection < saleSectionCount.length)) {
            if (saleSectionInvest[currentSection] >= wei_value) {
                _tokens += ONE_TOKEN.mul(wei_value).div(saleSectionPrice[currentSection]);
                saleSectionInvest[currentSection] -= wei_value;
                wei_value =0;
            } else {
                _tokens += ONE_TOKEN.mul(saleSectionInvest[currentSection]).div(saleSectionPrice[currentSection]);
                wei_value -= saleSectionInvest[currentSection];
                saleSectionInvest[currentSection] = 0;
            }
            if (saleSectionInvest[currentSection] <= 0) currentSection++;
        }

        require(_tokens >= MIN_SOLD_TOKENS);

        require(_transfer(this, msg_sender, _tokens));

        profits[msg_sender][1] = InvestorProfitData({
            start_balance:  investors[msg_sender].tokenBalance,
            end_balance:    investors[msg_sender].tokenBalance,
            status:         ProfitStatus.StartFixed
            });

        investors[msg_sender].icoInvest += (msg_value - wei_value);

        tokenSold      += _tokens;
        etherCollected += (msg_value - wei_value);

        if (saleSectionInvest[saleSectionInvest.length-1] == 0 ) {
            _finishICO();
        }

        if (wei_value > 0) {
            msg_sender.transfer(wei_value);
        }
    }

    function _finishICO() internal {
        require(contractIsWorking);
        require(mode == ContractMode.TokenSale);

        if (tokenSold >= SOFTCAP) {
            mode = ContractMode.DividendDistribution;
        } else {
            mode = ContractMode.UnderSoftCap;
        }

        investors[this].tokenBalance = 0;
        icoFinishTime                = now;
        totalSupply                  = tokenSold;

        emit ModeChanged(mode, investors[this].tokenBalance);
    }

    function finishICO() public grantOwner  {
        _finishICO();
    }

    function getInvestedAmount(address investor) public view returns(uint256) {
        return investors[investor].icoInvest;
    }

    function activateAddress(address investor, bool status) public grantDApp {
        require(contractIsWorking);
        require(mode == ContractMode.DividendDistribution);
        require((now - icoFinishTime) < KYC_REVIEW_PERIOD);
        investors[investor].activated = status;
    }

    function isAddressActivated(address investor) public view returns (bool) {
        return investors[investor].activated;
    }

    /*******
            Dividend Declaration Section
    *********/
    function declareDividend(uint256 profit_per_token) public grantDividendManager {
        dividendCandidate = profit_per_token;
    }

    function confirmDividend(uint256 profit_per_token) public grantOwner {
        require(contractIsWorking);
        require(dividendCandidate == profit_per_token);
        require(mode == ContractMode.DividendDistribution);

        dividends.push(dividendCandidate);
        emit DividendDeclared(uint32(dividends.length), dividendCandidate);
        dividendCandidate = 0;
    }

    function claimDividend() public {
        require(contractIsWorking);
        require(mode == ContractMode.DividendDistribution);
        require(investors[msg.sender].activated);

        InvestorProfitData storage current_profit;
        uint256 price_per_token;
        (current_profit, price_per_token) = fixDividendBalances(msg.sender, true);

        uint256 investorProfitWei =
                    (current_profit.start_balance < current_profit.end_balance ?
                     current_profit.start_balance : current_profit.end_balance ).div(ONE_TOKEN).mul(price_per_token);

        current_profit.status = ProfitStatus.Claimed;
        emit DividendClaimed(msg.sender, investorProfitWei);

        msg.sender.transfer(investorProfitWei);
    }

    function getDividendInfo() public view returns(uint256) {
        return dividends[dividends.length - 1];
    }

    /*******
                emit BuyBack
    ********/
    function setBuyBackPrice(uint256 token_buyback_price) public grantOwner {
        require(mode == ContractMode.DividendDistribution);
        buyBackPriceWei = token_buyback_price;
    }

    function buyback() public {
        require(contractIsWorking);
        require(mode == ContractMode.DividendDistribution);
        require(buyBackPriceWei > 0);

        uint256 token_amount = investors[msg.sender].tokenBalance;
        uint256 ether_amount = calcTokenToWei(token_amount);

        require(address(this).balance > ether_amount);

        if (transfer(this, token_amount)){
            emit BuyBack(msg.sender);
            msg.sender.transfer(ether_amount);
        }
    }

    /********
                Under SoftCap Section
    *********/
    function refund() public {
        require(contractIsWorking);
        require(mode == ContractMode.UnderSoftCap);
        require(investors[msg.sender].tokenBalance >0);
        require(investors[msg.sender].icoInvest>0);

        require (address(this).balance > investors[msg.sender].icoInvest);

        if (_transfer(msg.sender, this, investors[msg.sender].tokenBalance)){
            emit Refund(msg.sender, investors[msg.sender].icoInvest);
            msg.sender.transfer(investors[msg.sender].icoInvest);
        }
    }

    function destroyContract() public grantOwner {
        require(mode == ContractMode.UnderSoftCap);
        require((now - icoFinishTime) > REFUND_PERIOD);
        selfdestruct(owner);
    }
    /********
                Permission related
    ********/

    function transferOwnership(address new_owner) public grantOwner {
        require(contractIsWorking);
        require(new_owner != address(0));
        emit OwnershipTransferred(owner, new_owner);
        owner = new_owner;
    }

    function setBountyManager(address new_bounty_manager) public grantOwner {
        require(investors[new_bounty_manager].tokenBalance ==0);
        if (mode == ContractMode.Initial) {
            emit BountyManagerAssigned(bountyManager, new_bounty_manager);
            bountyManager = new_bounty_manager;
        } else if (mode == ContractMode.TokenSale) {
            emit BountyManagerAssigned(bountyManager, new_bounty_manager);
            address old_bounty_manager = bountyManager;
            bountyManager              = new_bounty_manager;
            require(_transfer(old_bounty_manager, new_bounty_manager, investors[old_bounty_manager].tokenBalance));
        } else {
            revert();
        }
    }

    function setDividendManager(address new_dividend_manager) public grantOwner {
        emit DividendManagerAssigned(dividendManager, new_dividend_manager);
        dividendManager = new_dividend_manager;
    }

    function setDApp(address new_dapp) public grantOwner {
        emit DAppAssigned(dApp, new_dapp);
        dApp = new_dapp;
    }



    /********
                Security and funds section
    ********/

    function transferBounty(address _to, uint256 _amount) public grantBountyManager {
        require(contractIsWorking);
        require(mode == ContractMode.DividendDistribution);
        if (_transfer(bountyManager, _to, _amount)) {
            emit BountyTransfered(_to, _amount);
        }
    }

    function burnTokens(uint256 tokenAmount) public grantOwner {
        require(contractIsWorking);
        require(mode == ContractMode.DividendDistribution);
        require(investors[msg.sender].tokenBalance > tokenAmount);

        investors[msg.sender].tokenBalance -= tokenAmount;
        totalSupply = totalSupply.sub(tokenAmount);
        emit BurnToken(tokenAmount);
    }

    function withdrawFunds(uint wei_value) grantOwner external {
        require(mode != ContractMode.UnderSoftCap);
        require(address(this).balance >= wei_value);

        emit FundsWithdrawal(msg.sender, wei_value);
        msg.sender.transfer(wei_value);
    }

    function addFunds() public payable grantOwner {
        require(contractIsWorking);
        emit FundsAdded(msg.sender, msg.value);
    }

    function pauseContract() public grantOwner {
        require(contractIsWorking);
        contractIsWorking = false;
        emit Handbrake(mode, contractIsWorking);
    }

    function restoreContract() public grantOwner {
        require(!contractIsWorking);
        contractIsWorking = true;
        emit Handbrake(mode, contractIsWorking);
    }

    /********
                Helper functions
    ********/
    function calcTokenToWei(uint256 token_amount) internal view returns (uint256) {
        return buyBackPriceWei.mul(token_amount).div(ONE_TOKEN);
    }
}