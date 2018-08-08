pragma solidity ^0.4.21;

// Project: alehub.io
// v11, 2018-07-17
// This code is the property of CryptoB2B.io
// Copying in whole or in part is prohibited.
// Authors: Ivan Fedorov and Dmitry Borodin
// Do you want the same TokenSale platform? www.cryptob2b.io

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function setManagerPowerful(bool _mode) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Started();
    event Closed();
    event RefundsEnabled();
    function freeCash() view public returns(uint256);
    function deposit(address _beneficiary) external payable;
    function refund(address _investor) external;
    function setup(uint8 _state, bytes32[] _params) external;
    function getBeneficiaryCash() external;
    function getPartnerCash(uint8 _user, address _msgsender) external;
}

contract ICreator{
    IRightAndRoles public rightAndRoles;
    function createAllocation(IToken _token, uint256 _unlockPart1, uint256 _unlockPart2) external returns (IAllocation);
    function createFinancialStrategy() external returns(IFinancialStrategy);
    function getRightAndRoles() external returns(IRightAndRoles);
}

contract IToken{
    function setUnpausedWallet(address _wallet, bool mode) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function setPause(bool mode) public;
    function setMigrationAgent(address _migrationAgent) public;
    function migrateAll(address[] _holders) public;
    function rejectTokens(address _beneficiary, uint256 _value) public;
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount);
    function defrostDate(address _beneficiary) public view returns (uint256 Date);
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public;
}

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
        uint256 c = a / b;
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
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b>=a) return 0;
        return a - b;
    }
}

contract GuidedByRoles {
    IRightAndRoles public rightAndRoles;
    function GuidedByRoles(IRightAndRoles _rightAndRoles) public {
        rightAndRoles = _rightAndRoles;
    }
}

contract ERC20Provider is GuidedByRoles {
    function transferTokens(ERC20Basic _token, address _to, uint256 _value) public returns (bool){
        require(rightAndRoles.onlyRoles(msg.sender,2));
        return _token.transfer(_to,_value);
    }
}

contract Crowdsale is GuidedByRoles, ERC20Provider{
// (A1)
// The main contract for the sale and management of rounds.
// 0000000000000000000000000000000000000000000000000000000000000000

    uint256 constant USER_UNPAUSE_TOKEN_TIMEOUT =  60 days;
    uint256 constant FORCED_REFUND_TIMEOUT1     = 400 days;
    uint256 constant FORCED_REFUND_TIMEOUT2     = 600 days;
    uint256 constant ROUND_PROLONGATE           =  60 days;
    uint256 constant KYC_PERIOD                 =  90 days;
    bool constant    GLOBAL_TOKEN_SYPPLY        =    false;

    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}
    TokenSaleType public TokenSale = TokenSaleType.round2;


    ICreator public creator;
    bool isBegin=false;

    IToken public token;
    IAllocation public allocation;
    IFinancialStrategy public financialStrategy;

    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;
    bool public chargeBonuses;
    bool public canFirstMint=true;

    struct Bonus {
        uint256 value;
        uint256 procent;
        uint256 freezeTime;
    }

    struct Profit {
        uint256 percent;
        uint256 duration;
    }

    struct Freezed {
        uint256 value;
        uint256 dateTo;
    }

    Bonus[] public bonuses;
    Profit[] public profits;


    uint256 public startTime= 1532476800;  //25.07.2018 0:00:00
    uint256 public endTime  = 1537833599;  //24.09.2018 23:59:59
    uint256 public renewal;

    // How many tokens (excluding the bonus) are transferred to the investor in exchange for 1 ETH
    // **THOUSANDS** 10^18 for human, *10**18 for Solidity, 1e18 for MyEtherWallet (MEW).
    // Example: if 1ETH = 40.5 Token ==> use 40500 finney
    uint256 public rate = 2333 ether; // $0.1 (ETH/USD=$500)

    // ETH/USD rate in US$
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: ETH/USD=$1000 ==> use 1000*10**18 (Solidity) or 1000 ether or 1000e18 (MEW)
    uint256 public exchange  = 700 ether;

    // If the round does not attain this value before the closing date, the round is recognized as a
    // failure and investors take the money back (the founders will not interfere in any way).
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: softcap=15ETH ==> use 15*10**18 (Solidity) or 15e18 (MEW)
    uint256 public softCap = 0;

    // The maximum possible amount of income
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: hardcap=123.45ETH ==> use 123450*10**15 (Solidity) or 12345e15 (MEW)
    uint256 public hardCap = 45413 ether; // $31M (ETH/USD=$500)

    // If the last payment is slightly higher than the hardcap, then the usual contracts do
    // not accept it, because it goes beyond the hardcap. However it is more reasonable to accept the
    // last payment, very slightly raising the hardcap. The value indicates by how many ETH the
    // last payment can exceed the hardcap to allow it to be paid. Immediately after this payment, the
    // round closes. The funders should write here a small number, not more than 1% of the CAP.
    // Can be equal to zero, to cancel.
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18
    uint256 public overLimit = 20 ether;

    // The minimum possible payment from an investor in ETH. Payments below this value will be rejected.
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: minPay=0.1ETH ==> use 100*10**15 (Solidity) or 100e15 (MEW)
    uint256 public minPay = 43 finney;

    uint256 public maxAllProfit = 30; // max time bonus=20%, max value bonus=10%, maxAll=10%+20%

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    uint256 public totalSaledToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    event PaymentedInOtherCurrency(uint256 token, uint256 value);
    event ExchangeChanged(uint256 indexed oldExchange, uint256 indexed newExchange);

    function Crowdsale(ICreator _creator,IToken _token) GuidedByRoles(_creator.getRightAndRoles()) public
    {
        creator=_creator;
        token = _token;
    }

    // Setting the current rate ETH/USD         
//    function changeExchange(uint256 _ETHUSD) public {
//        require(rightAndRoles.onlyRoles(msg.sender,18));
//        require(_ETHUSD >= 1 ether);
//        emit ExchangeChanged(exchange,_ETHUSD);
//        softCap=softCap.mul(exchange).div(_ETHUSD);             // QUINTILLIONS
//        hardCap=hardCap.mul(exchange).div(_ETHUSD);             // QUINTILLIONS
//        minPay=minPay.mul(exchange).div(_ETHUSD);               // QUINTILLIONS
//
//        rate=rate.mul(_ETHUSD).div(exchange);                   // QUINTILLIONS
//
//        for (uint16 i = 0; i < bonuses.length; i++) {
//            bonuses[i].value=bonuses[i].value.mul(exchange).div(_ETHUSD);   // QUINTILLIONS
//        }
//        bytes32[] memory params = new bytes32[](2);
//        params[0] = bytes32(exchange);
//        params[1] = bytes32(_ETHUSD);
//        financialStrategy.setup(5, params);
//
//        exchange=_ETHUSD;
//
//    }

    // Setting of basic parameters, analog of class constructor
    // @ Do I have to use the function      see your scenario
    // @ When it is possible to call        before Round 1/2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function begin() public
    {
        require(rightAndRoles.onlyRoles(msg.sender,22));
        if (isBegin) return;
        isBegin=true;

        financialStrategy = creator.createFinancialStrategy();

        if(GLOBAL_TOKEN_SYPPLY){
            totalSaledToken = token.totalSupply();
        }

        token.setUnpausedWallet(rightAndRoles.wallets(1,0), true);
        token.setUnpausedWallet(rightAndRoles.wallets(3,0), true);
        token.setUnpausedWallet(rightAndRoles.wallets(4,0), true);
        token.setUnpausedWallet(rightAndRoles.wallets(5,0), true);
        token.setUnpausedWallet(rightAndRoles.wallets(6,0), true);

        bonuses.push(Bonus(1429 finney, 2,0));
        bonuses.push(Bonus(14286 finney, 5,0));
        bonuses.push(Bonus(142857 finney, 10,0));

        profits.push(Profit(20,5 days));
        profits.push(Profit(15,5 days));
        profits.push(Profit(10,5 days));
        profits.push(Profit(5,5 days));
    }



    // Issue of tokens for the zero round, it is usually called: private pre-sale (Round 0)
    // @ Do I have to use the function      may be
    // @ When it is possible to call        before Round 1/2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function firstMintRound0(uint256 _amount /* QUINTILLIONS! */) public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(canFirstMint);
        begin();
        token.mint(rightAndRoles.wallets(3,0),_amount);
        totalSaledToken = totalSaledToken.add(_amount);
    }

    function firstMintRound0For(address[] _to, uint256[] _amount, bool[] _setAsUnpaused) public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(canFirstMint);
        begin();
        require(_to.length == _amount.length && _to.length == _setAsUnpaused.length);
        for(uint256 i = 0; i < _to.length; i++){
            token.mint(_to[i],_amount[i]);
            totalSaledToken = totalSaledToken.add(_amount[i]);
            if(_setAsUnpaused[i]){
                token.setUnpausedWallet(_to[i], true);
            }
        }
    }

    // info
    function totalSupply() external view returns (uint256){
        return token.totalSupply();
    }

    // Returns the name of the current round in plain text. Constant.
    function getTokenSaleType() external view returns(string){
        return (TokenSale == TokenSaleType.round1)?&#39;round1&#39;:&#39;round2&#39;;
    }

    // Transfers the funds of the investor to the contract of return of funds. Internal.
    function forwardFunds(address _beneficiary) internal {
        financialStrategy.deposit.value(msg.value)(_beneficiary);
    }

    // Check for the possibility of buying tokens. Inside. Constant.
    function validPurchase() internal view returns (bool) {

        // The round started and did not end
        bool withinPeriod = (now > startTime && now < endTime.add(renewal));

        // Rate is greater than or equal to the minimum
        bool nonZeroPurchase = msg.value >= minPay;

        // hardCap is not reached, and in the event of a transaction, it will not be exceeded by more than OverLimit
        bool withinCap = msg.value <= hardCap.sub(weiRaised()).add(overLimit);

        // round is initialized and no "Pause of trading" is set
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isFinalized && !isPausedCrowdsale;
    }

    // Check for the ability to finalize the round. Constant.
    function hasEnded() public view returns (bool) {
        bool isAdmin = rightAndRoles.onlyRoles(msg.sender,6);

        bool timeReached = now > endTime.add(renewal);

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached || (isAdmin && goalReached())) && isInitialized && !isFinalized;
    }

    // Finalize. Only available to the Manager and the Beneficiary. If the round failed, then
    // anyone can call the finalization to unlock the return of funds to investors
    // You must call a function to finalize each round (after the Round1 & after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        after end of Round1 & Round2
    // @ When it is launched automatically  no
    // @ Who can call the function          admins or anybody (if round is failed)
    function finalize() public {
        require(hasEnded());

        isFinalized = true;
        finalization();
        emit Finalized();
    }

    // The logic of finalization. Internal
    // @ Do I have to use the function      no
    // @ When it is possible to call        -
    // @ When it is launched automatically  after end of round
    // @ Who can call the function          -
    function finalization() internal {
        bytes32[] memory params = new bytes32[](0);
        // If the goal of the achievement
        if (goalReached()) {

            financialStrategy.setup(1,params);//Для контракта Buz деньги не возвращает.

            // if there is anything to give
            if (tokenReserved > 0) {

                token.mint(rightAndRoles.wallets(3,0),tokenReserved);
                totalSaledToken = totalSaledToken.add(tokenReserved);

                // Reset the counter
                tokenReserved = 0;
            }

            // If the finalization is Round 1
            if (TokenSale == TokenSaleType.round1) {

                // Reset settings
                isInitialized = false;
                isFinalized = false;
                if(financialStrategy.freeCash() == 0){
                    rightAndRoles.setManagerPowerful(true);
                }

                // Switch to the second round (to Round2)
                TokenSale = TokenSaleType.round2;

                // Reset the collection counter
                weiRound1 = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;



            }
            else // If the second round is finalized
            {

                // Permission to collect tokens to those who can pick them up
                chargeBonuses = true;

                //totalSaledToken = token.totalSupply();
                //partners = true;

            }

        }
        else // If they failed round
        {
            financialStrategy.setup(3,params);
        }
    }

    // The Manager freezes the tokens for the Team.
    // You must call a function to finalize Round 2 (only after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        Round2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function finalize2() public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(chargeBonuses);
        chargeBonuses = false;

        allocation = creator.createAllocation(token, now + 1 years /* stage N1 */,0/* not need*/);
        token.setUnpausedWallet(allocation, true);
        // Team = %, Founders = %, Fund = %    TOTAL = %
        allocation.addShare(rightAndRoles.wallets(7,0),100,100); // all 100% - first year

        // 2% - bounty wallet
        token.mint(rightAndRoles.wallets(5,0), totalSaledToken.mul(2).div(77));

        // 10% - company
        token.mint(rightAndRoles.wallets(6,0), totalSaledToken.mul(10).div(77));

        // 13% - team
        token.mint(allocation, totalSaledToken.mul(11).div(77));
    }



    // Initializing the round. Available to the manager. After calling the function,
    // the Manager loses all rights: Manager can not change the settings (setup), change
    // wallets, prevent the beginning of the round, etc. You must call a function after setup
    // for the initial round (before the Round1 and before the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        before each round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function initialize() public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        // If not yet initialized
        require(!isInitialized);
        begin();


        // And the specified start time has not yet come
        // If initialization return an error, check the start date!
        //require(now <= startTime);

        initialization();

        emit Initialized();

        renewal = 0;

        isInitialized = true;

        canFirstMint = false;
    }

    function initialization() internal {
        bytes32[] memory params = new bytes32[](0);
        rightAndRoles.setManagerPowerful(false);
        if (financialStrategy.state() != IFinancialStrategy.State.Active){
            financialStrategy.setup(2,params);
        }
    }

    // 
    // @ Do I have to use the function      
    // @ When it is possible to call        
    // @ When it is launched automatically  
    // @ Who can call the function          
    function getPartnerCash(uint8 _user, bool _calc) external {
        if(_calc)
            calcFin();
        financialStrategy.getPartnerCash(_user, msg.sender);
    }

    function getBeneficiaryCash(bool _calc) public {
        require(rightAndRoles.onlyRoles(msg.sender,22));
        if(_calc)
            calcFin();
        financialStrategy.getBeneficiaryCash();
        if(!isInitialized && financialStrategy.freeCash() == 0)
            rightAndRoles.setManagerPowerful(true);
    }

    function claimRefund() external{
        financialStrategy.refund(msg.sender);
    }

    function calcFin() public {
        bytes32[] memory params = new bytes32[](2);
        params[0] = bytes32(weiTotalRaised());
        params[1] = bytes32(msg.sender);
        financialStrategy.setup(4,params);
    }

    function calcAndGet() public {
        require(rightAndRoles.onlyRoles(msg.sender,22));
        getBeneficiaryCash(true);
        for (uint8 i=0; i<0; i++) {
            financialStrategy.getPartnerCash(i, msg.sender);
        }
    }

    // We check whether we collected the necessary minimum funds. Constant.
    function goalReached() public view returns (bool) {
        return weiRaised() >= softCap;
    }


    // Customize. The arguments are described in the constructor above.
    // @ Do I have to use the function      yes
    // @ When it is possible to call        before each rond
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function setup(uint256 _startTime, uint256 _endTime, uint256 _softCap, uint256 _hardCap,
        uint256 _rate, uint256 _exchange,
        uint256 _maxAllProfit, uint256 _overLimit, uint256 _minPay,
        uint256[] _durationTB , uint256[] _percentTB, uint256[] _valueVB, uint256[] _percentVB, uint256[] _freezeTimeVB) public
    {

        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(!isInitialized);

        begin();

        // Date and time are correct
        //require(now <= _startTime);
        require(_startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;

        // The parameters are correct
        require(_softCap <= _hardCap);

        softCap = _softCap;
        hardCap = _hardCap;

        require(_rate > 0);

        rate = _rate;

        overLimit = _overLimit;
        minPay = _minPay;
        exchange = _exchange;

        maxAllProfit = _maxAllProfit;

        require(_valueVB.length == _percentVB.length && _valueVB.length == _freezeTimeVB.length);
        bonuses.length = _valueVB.length;
        for(uint256 i = 0; i < _valueVB.length; i++){
            bonuses[i] = Bonus(_valueVB[i],_percentVB[i],_freezeTimeVB[i]);
        }

        require(_percentTB.length == _durationTB.length);
        profits.length = _percentTB.length;
        for( i = 0; i < _percentTB.length; i++){
            profits[i] = Profit(_percentTB[i],_durationTB[i]);
        }

    }

    // Collected funds for the current round. Constant.
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

    // Returns the amount of fees for both phases. Constant.
    function weiTotalRaised() public constant returns(uint256){
        return weiRound1.add(weiRaised());
    }

    // Returns the percentage of the bonus on the current date. Constant.
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }

    // Returns the percentage of the bonus on the given date. Constant.
    function getProfitPercentForData(uint256 _timeNow) public constant returns (uint256){
        uint256 allDuration;
        for(uint8 i = 0; i < profits.length; i++){
            allDuration = allDuration.add(profits[i].duration);
            if(_timeNow < startTime.add(allDuration)){
                return profits[i].percent;
            }
        }
        return 0;
    }

    function getBonuses(uint256 _value) public constant returns (uint256,uint256,uint256){
        if(bonuses.length == 0 || bonuses[0].value > _value){
            return (0,0,0);
        }
        uint16 i = 1;
        for(i; i < bonuses.length; i++){
            if(bonuses[i].value > _value){
                break;
            }
        }
        return (bonuses[i-1].value,bonuses[i-1].procent,bonuses[i-1].freezeTime);
    }


    // Remove the "Pause of exchange". Available to the manager at any time. If the
    // manager refuses to remove the pause, then 30-120 days after the successful
    // completion of the TokenSale, anyone can remove a pause and allow the exchange to continue.
    // The manager does not interfere and will not be able to delay the term.
    // He can only cancel the pause before the appointed time.
    // @ Do I have to use the function      YES YES YES
    // @ When it is possible to call        after end of ICO
    // @ When it is launched automatically  -
    // @ Who can call the function          admins or anybody
    function tokenUnpause() external {

        require(rightAndRoles.onlyRoles(msg.sender,2)
        || (now > endTime.add(renewal).add(USER_UNPAUSE_TOKEN_TIMEOUT) && TokenSale == TokenSaleType.round2 && isFinalized && goalReached()));
        token.setPause(false);
    }

    // Enable the "Pause of exchange". Available to the manager until the TokenSale is completed.
    // The manager cannot turn on the pause, for example, 3 years after the end of the TokenSale.
    // @ Do I have to use the function      no
    // @ When it is possible to call        while Round2 not ended
    // @ When it is launched automatically  before any rounds
    // @ Who can call the function          admins
    function tokenPause() public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(!isFinalized);
        token.setPause(true);
    }

    // Pause of sale. Available to the manager.
    // @ Do I have to use the function      no
    // @ When it is possible to call        during active rounds
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function setCrowdsalePause(bool mode) public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        isPausedCrowdsale = mode;
    }

    // For example - After 5 years of the project&#39;s existence, all of us suddenly decided collectively
    // (company + investors) that it would be more profitable for everyone to switch to another smart
    // contract responsible for tokens. The company then prepares a new token, investors
    // disassemble, study, discuss, etc. After a general agreement, the manager allows any investor:
    //      - to burn the tokens of the previous contract
    //      - generate new tokens for a new contract
    // It is understood that after a general solution through this function all investors
    // will collectively (and voluntarily) move to a new token.
    // @ Do I have to use the function      no
    // @ When it is possible to call        only after ICO!
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function moveTokens(address _migrationAgent) public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        token.setMigrationAgent(_migrationAgent);
    }

    // @ Do I have to use the function      no
    // @ When it is possible to call        only after ICO!
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function migrateAll(address[] _holders) public {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        token.migrateAll(_holders);
    }


    // For people who ignore the KYC/AML procedure during 30 days after payment (KYC_PERIOD): money back and zeroing tokens.
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          admin
    function invalidPayments(address[] _beneficiary, uint256[] _value) external {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(endTime.add(renewal).add(KYC_PERIOD) > now);
        require(_beneficiary.length == _value.length);
        for(uint16 i; i<_beneficiary.length; i++) {
            token.rejectTokens(_beneficiary[i],_value[i]);
        }
    }

    // Extend the round time, if provided by the script. Extend the round only for
    // a limited number of days - ROUND_PROLONGATE
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        during active round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function prolong(uint256 _duration) external {
        require(rightAndRoles.onlyRoles(msg.sender,6));
        require(now > startTime && now < endTime.add(renewal) && isInitialized && !isFinalized);
        renewal = renewal.add(_duration);
        require(renewal <= ROUND_PROLONGATE);

    }
    // If a little more than a year has elapsed (Round2 start date + 400 days), a smart contract
    // will allow you to send all the money to the Beneficiary, if any money is present. This is
    // possible if you mistakenly launch the Round2 for 30 years (not 30 days), investors will transfer
    // money there and you will not be able to pick them up within a reasonable time. It is also
    // possible that in our checked script someone will make unforeseen mistakes, spoiling the
    // finalization. Without finalization, money cannot be returned. This is a rescue option to
    // get around this problem, but available only after a year (400 days).

    // Another reason - the TokenSale was a failure, but not all ETH investors took their money during the year after.
    // Some investors may have lost a wallet key, for example.

    // The method works equally with the Round1 and Round2. When the Round1 starts, the time for unlocking
    // the distructVault begins. If the TokenSale is then started, then the term starts anew from the first day of the TokenSale.

    // Next, act independently, in accordance with obligations to investors.

    // Within 400 days (FORCED_REFUND_TIMEOUT1) of the start of the Round, if it fails only investors can take money. After
    // the deadline this can also include the company as well as investors, depending on who is the first to use the method.
    // @ Do I have to use the function      no
    // @ When it is possible to call        -
    // @ When it is launched automatically  -
    // @ Who can call the function          beneficiary & manager
    function distructVault() public {
        bytes32[] memory params = new bytes32[](1);
        params[0] = bytes32(msg.sender);
        if (rightAndRoles.onlyRoles(msg.sender,4) && (now > startTime.add(FORCED_REFUND_TIMEOUT1))) {

            financialStrategy.setup(0,params);
        }
        if (rightAndRoles.onlyRoles(msg.sender,2) && (now > startTime.add(FORCED_REFUND_TIMEOUT2))) {
            financialStrategy.setup(0,params);
        }
    }


    // We accept payments other than Ethereum (ETH) and other currencies, for example, Bitcoin (BTC).
    // Perhaps other types of cryptocurrency - see the original terms in the white paper and on the TokenSale website.

    // We release tokens on Ethereum. During the Round1 and Round2 with a smart contract, you directly transfer
    // the tokens there and immediately, with the same transaction, receive tokens in your wallet.

    // When paying in any other currency, for example in BTC, we accept your money via one common wallet.
    // Our manager fixes the amount received for the bitcoin wallet and calls the method of the smart
    // contract paymentsInOtherCurrency to inform him how much foreign currency has been received - on a daily basis.
    // The smart contract pins the number of accepted ETH directly and the number of BTC. Smart contract
    // monitors softcap and hardcap, so as not to go beyond this framework.

    // In theory, it is possible that when approaching hardcap, we will receive a transfer (one or several
    // transfers) to the wallet of BTC, that together with previously received money will exceed the hardcap in total.
    // In this case, we will refund all the amounts above, in order not to exceed the hardcap.

    // Collection of money in BTC will be carried out via one common wallet. The wallet&#39;s address will be published
    // everywhere (in a white paper, on the TokenSale website, on Telegram, on Bitcointalk, in this code, etc.)
    // Anyone interested can check that the administrator of the smart contract writes down exactly the amount
    // in ETH (in equivalent for BTC) there. In theory, the ability to bypass a smart contract to accept money in
    // BTC and not register them in ETH creates a possibility for manipulation by the company. Thanks to
    // paymentsInOtherCurrency however, this threat is leveled.

    // Any user can check the amounts in BTC and the variable of the smart contract that accounts for this
    // (paymentsInOtherCurrency method). Any user can easily check the incoming transactions in a smart contract
    // on a daily basis. Any hypothetical tricks on the part of the company can be exposed and panic during the TokenSale,
    // simply pointing out the incompatibility of paymentsInOtherCurrency (ie, the amount of ETH + BTC collection)
    // and the actual transactions in BTC. The company strictly adheres to the described principles of openness.

    // The company administrator is required to synchronize paymentsInOtherCurrency every working day (but you
    // cannot synchronize if there are no new BTC payments). In the case of unforeseen problems, such as
    // brakes on the Ethereum network, this operation may be difficult. You should only worry if the
    // administrator does not synchronize the amount for more than 96 hours in a row, and the BTC wallet
    // receives significant amounts.

    // This scenario ensures that for the sum of all fees in all currencies this value does not exceed hardcap.

    // ** QUINTILLIONS ** 10^18 / 1**18 / 1e18

    // @ Do I have to use the function      no
    // @ When it is possible to call        during active rounds
    // @ When it is launched automatically  every day from cryptob2b token software
    // @ Who can call the function          admins + observer
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {

        // **For audit**
        // BTC Wallet:             1D7qaRN6keGJKb5LracZYQEgCBaryZxVaE
        // BCH Wallet:             1CDRdTwvEyZD7qjiGUYxZQSf8n91q95xHU
        // DASH Wallet:            XnjajDvQq1C7z2o4EFevRhejc6kRmX1NUp
        // LTC Wallet:             LhHkiwVfoYEviYiLXP5pRK2S1QX5eGrotA
        require(rightAndRoles.onlyRoles(msg.sender,18));
        bool withinPeriod = (now >= startTime && now <= endTime.add(renewal));
        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized && !isFinalized);
        emit PaymentedInOtherCurrency(_token,_value);
        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }

    function lokedMint(address _beneficiary, uint256 _value, uint256 _freezeTime) internal {
        if(_freezeTime > 0){

            uint256 totalBloked = token.freezedTokenOf(_beneficiary).add(_value);
            uint256 pastDateUnfreeze = token.defrostDate(_beneficiary);
            uint256 newDateUnfreeze = _freezeTime.add(now);
            newDateUnfreeze = (pastDateUnfreeze > newDateUnfreeze ) ? pastDateUnfreeze : newDateUnfreeze;

            token.freezeTokens(_beneficiary,totalBloked,newDateUnfreeze);
        }
        token.mint(_beneficiary,_value);
        totalSaledToken = totalSaledToken.add(_value);
    }


    // The function for obtaining smart contract funds in ETH. If all the checks are true, the token is
    // transferred to the buyer, taking into account the current bonus.
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 ProfitProcent = getProfitPercent();

        uint256 value;
        uint256 percent;
        uint256 freezeTime;

        (value,
        percent,
        freezeTime) = getBonuses(weiAmount);

        Bonus memory curBonus = Bonus(value,percent,freezeTime);

        uint256 bonus = curBonus.procent;

        // --------------------------------------------------------------------------------------------
        // *** Scenario 1 - select max from all bonuses + check maxAllProfit
        //uint256 totalProfit = (ProfitProcent < bonus) ? bonus : ProfitProcent;
        // *** Scenario 2 - sum both bonuses + check maxAllProfit
        uint256 totalProfit = bonus.add(ProfitProcent);
        // --------------------------------------------------------------------------------------------
        totalProfit = (totalProfit > maxAllProfit) ? maxAllProfit : totalProfit;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate).mul(totalProfit.add(100)).div(100 ether);

        // update state
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        lokedMint(_beneficiary, tokens, curBonus.freezeTime);

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        forwardFunds(_beneficiary);//forwardFunds(msg.sender);
    }

    // buyTokens alias
    function () public payable {
        buyTokens(msg.sender);
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IAllocation {
    function addShare(address _beneficiary, uint256 _proportion, uint256 _percenForFirstPart) external;
}