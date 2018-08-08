// Project: BUZcoin.io (original)
// v11, 2018-04-17
// This code is the property of CryptoB2B.io
// Copying in whole or in part is prohibited.
// Authors: Ivan Fedorov and Dmitry Borodin
// Do you want the same TokenSale platform? www.cryptob2b.io

// *.sol in 1 file - https://cryptob2b.io/solidity/buzcoin/

pragma solidity ^0.4.21;

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);

    function deposit(address _beneficiary) external payable;
    function setup(address _beneficiary, uint256 _arg1, uint256 _arg2, uint8 _state) external;
    function calc(uint256 _allValue) external;
    function getBeneficiaryCash(address _beneficiary) external;
    function getPartnerCash(uint8 _user, bool _isAdmin, address _msgsender, bool _calc, uint256 _weiTotalRaised) external;
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

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

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract IToken{
    function setUnpausedWallet(address _wallet, bool mode) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function setPause(bool mode) public;
    function setMigrationAgent(address _migrationAgent) public;
    function migrateAll(address[] _holders) public;
    function burn(address _beneficiary, uint256 _value) public;
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount);
    function defrostDate(address _beneficiary) public view returns (uint256 Date);
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public;
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

contract ICreator{
    function createToken() external returns (IToken);
    function createFinancialStrategy() external returns(IFinancialStrategy);
}

contract BuzFinancialStrategy is IFinancialStrategy, Ownable{
    using SafeMath for uint256;

                             // Partner 0   Partner 1    Partner 2
    uint256[3] public percent = [20,        2,           3            ];
    uint256[3] public cap     = [200 ether, 1800 ether,  9999999 ether]; // QUINTILLIONS
    uint256[3] public debt1   = [0,0,0];
    uint256[3] public debt2   = [0,0,0];
    uint256[3] public total   = [0,0,0];                                 // QUINTILLIONS
    uint256[3] public took    = [0,0,0];
    uint256[3] public ready   = [0,0,0];

    address[3] public wallets= [
        0x356608b672fdB01C5077d1A2cb6a7b38fDdcd8A5,
        0xf1F3D1Dc1E5cEA08f127cad3B7Dbd29b299c88C8,
        0x55ecFbD0111ab365b6De98A01E9305EfD4a78FAA
    ];

    uint256 public benTook=0;
    uint256 public benReady=0;
    uint256 public newCash=0;
    uint256 public cashHistory=0;
    uint256 public prcSum=0;

    address public benWallet=0;

    function BuzFinancialStrategy() public {
        initialize();
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }

    function initialize() internal {
        for (uint8 i=0; i<percent.length; i++ ) prcSum+=percent[i];
    }
    
    function deposit(address _beneficiary) external onlyOwner payable {
        require(state == State.Active);
        newCash = newCash.add(msg.value);
        cashHistory += msg.value;
        emit Deposited(_beneficiary,msg.value);
    }


    // 0 - destruct
    // 1 - close
    // 2 - restart
    // 3 - refund
    // 4 - test
    // 5 - update Exchange                                                                      
    function setup(address _beneficiary, uint256 _arg1, uint256 _arg2, uint8 _state) external onlyOwner {

        if (_state == 0)  {
            
            // call from Crowdsale.distructVault(true) for exit
            // arg1 - nothing
            // arg2 - nothing
            selfdestruct(_beneficiary);

        }
        else if (_state == 1 || _state == 3) {
            // Call from Crowdsale.finalization()
            //   [1] - successfull round (goalReach)
            //   [3] - failed round (not enough money)
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
        
            require(state == State.Active);
            //internalCalc(_arg1);
            state = State.Closed;
            benWallet=_beneficiary;
        
        }
        else if (_state == 2) {
            // Call from Crowdsale.initialization()
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
            
            require(state == State.Closed);
            state = State.Active;
            benWallet=_beneficiary;
        
        }
        else if (_state == 4) {
            // call from Crowdsale.distructVault(false) for test
            // arg1 = nothing;
            // arg2 = nothing;
            benWallet=_beneficiary;
        
        }
        else if (_state == 5) {
            // arg1 = old ETH/USD (exchange)
            // arg2 = new ETH/USD (_ETHUSD)

            for (uint8 user=0; user<cap.length; user++) cap[user]=cap[user].mul(_arg1).div(_arg2);
            benWallet=_beneficiary;

        }

    }

    function calc(uint256 _allValue) external onlyOwner {
        internalCalc(_allValue);
    }

    function internalCalc(uint256 _allValue) internal {

        uint256 free=newCash+benReady;
        uint256 common1=0;
        uint256 common2=0;
        uint256 spent=0;
        uint256 plan=0;
        uint8   user=0;

        if (free==0) return;

        for (user=0; user<percent.length; user++) {

            plan=_allValue*percent[user]/100;
            if (total[user]>=plan || total[user]>=cap[user]) {
                debt1[user]=0;
                debt2[user]=0;
                continue;
            }

            debt1[user]=plan.minus(total[user]);
            if (debt1[user]+total[user] > cap[user]) debt1[user]=cap[user].minus(total[user]);

            common1+=debt1[user];

            plan=free.mul(percent[user]).div(prcSum);
            debt2[user]=plan;
            if (debt2[user]+total[user] > cap[user]) debt2[user]=cap[user].minus(total[user]);
            
            common2+=debt2[user];

        }

        if (common1>0 && common1<=free) {
    
            for (user=0; user<percent.length; user++) {

                if (debt1[user]==0) continue;
                
                plan=free.mul(debt1[user]).div(common1);
                
                if (plan>debt1[user]) plan=debt1[user];
                ready[user]+=plan;
                total[user]+=plan;
                spent+=plan;
            }
        } 

        if (common2>0 && common1>free) {
        
            for (user=0; user<percent.length; user++) {
                
                if (debt2[user]==0) continue;

                plan=free.mul(debt2[user]).div(common2);

                if (plan>debt1[user]) plan=debt1[user]; // debt1, not 2
                ready[user]+=plan;
                total[user]+=plan;
                spent+=plan;
            }
        }

        if (spent>newCash+benReady) benReady=0;
        else benReady=newCash.add(benReady).minus(spent);
        newCash=0;

    }

    // Call from Crowdsale:
    function getBeneficiaryCash(address _beneficiary) external onlyOwner {

        uint256 move=benReady;
        benWallet=_beneficiary;
        if (move == 0) return;

        emit Receive(_beneficiary, move);
        benReady = 0;
        benTook += move;
        
        _beneficiary.transfer(move);
    
    }


    // Call from Crowdsale:
    function getPartnerCash(uint8 _user, bool _isAdmin, address _msgsender, bool _calc, uint256 _weiTotalRaised) external onlyOwner {

        require(_user<percent.length && _user<wallets.length);

        if (!_isAdmin) {
            for (uint8 i=0; i<wallets.length; i++) {
                if (wallets[i]==_msgsender) break;
            }
            if (i>=wallets.length) {
                return;
            }
        }

        if (_calc) internalCalc(_weiTotalRaised);

        uint256 move=ready[_user];
        if (move==0) return;

        emit Receive(wallets[_user], move);
        ready[_user]=0;
        took[_user]+=move;

        wallets[_user].transfer(move);
    
    }
}

contract ICrowdsale {
    //              0             1         2        3        4        5      6       
    enum Roles {beneficiary, accountant, manager, observer, bounty, company, team}
    address[8] public wallets;
}

contract Crowdsale is ICrowdsale{
// (A1)
// The main contract for the sale and management of rounds.
// 0000000000000000000000000000000000000000000000000000000000000000

    uint256 constant USER_UNPAUSE_TOKEN_TIMEOUT =  90 days;
    uint256 constant FORCED_REFUND_TIMEOUT1     = 300 days;
    uint256 constant FORCED_REFUND_TIMEOUT2     = 400 days;
    uint256 constant ROUND_PROLONGATE           =  90 days;
    uint256 constant BURN_TOKENS_TIME           =  60 days;

    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}

    TokenSaleType public TokenSale = TokenSaleType.round1;

    ICreator public creator;
    bool isBegin=false;

    IToken public token;
    //Allocation public allocation;
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


    uint256 public startTime= 1524009600;
    uint256 public endTime  = 1526601599;
    uint256 public renewal;

    // How many tokens (excluding the bonus) are transferred to the investor in exchange for 1 ETH
    // **THOUSANDS** 10^18 for human, *10**18 for Solidity, 1e18 for MyEtherWallet (MEW).
    // Example: if 1ETH = 40.5 Token ==> use 40500 finney
    uint256 public rate = 5000 ether; // $0.1 (ETH/USD=$500)

    // ETH/USD rate in US$
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: ETH/USD=$1000 ==> use 1000*10**18 (Solidity) or 1000 ether or 1000e18 (MEW)
    uint256 public exchange  = 500 ether;

    // If the round does not attain this value before the closing date, the round is recognized as a
    // failure and investors take the money back (the founders will not interfere in any way).
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: softcap=15ETH ==> use 15*10**18 (Solidity) or 15e18 (MEW)
    uint256 public softCap = 0;

    // The maximum possible amount of income
    // **QUINTILLIONS** 10^18 / *10**18 / 1e18. Example: hardcap=123.45ETH ==> use 123450*10**15 (Solidity) or 12345e15 (MEW)
    uint256 public hardCap = 62000 ether; // $31M (ETH/USD=$500)

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
    uint256 public minPay = 20 finney;

    uint256 public maxAllProfit = 38; // max time bonus=30%, max value bonus=8%, maxAll=38%

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    uint256 public totalSaledToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function Crowdsale(ICreator _creator) public
    {
        creator=_creator;
        // Initially, all next 7+ roles/wallets are given to the Manager. The Manager is an employee of the company
        // with knowledge of IT, who publishes the contract and sets it up. However, money and tokens require
        // a Beneficiary and other roles (Accountant, Team, etc.). The Manager will not have the right
        // to receive them. To enable this, the Manager must either enter specific wallets here, or perform
        // this via method changeWallet. In the finalization methods it is written which wallet and
        // what percentage of tokens are received.
        wallets = [

        // Beneficiary
        // Receives all the money (when finalizing Round1 & Round2)
        0x55d36E21b7ee114dA69a9d79D37a894d80d8Ed09,

        // Accountant
        // Receives all the tokens for non-ETH investors (when finalizing Round1 & Round2)
        0xaebC3c0a722A30981F8d19BDA33eFA51a89E4C6C,

        // Manager
        // All rights except the rights to receive tokens or money. Has the right to change any other
        // wallets (Beneficiary, Accountant, ...), but only if the round has not started. Once the
        // round is initialized, the Manager has lost all rights to change the wallets.
        // If the TokenSale is conducted by one person, then nothing needs to be changed. Permit all 7 roles
        // point to a single wallet.
        msg.sender,

        // Observer
        // Has only the right to call paymentsInOtherCurrency (please read the document)
        0x8a91aC199440Da0B45B2E278f3fE616b1bCcC494,

        // Bounty - 2% tokens
        0x1f85AE08D0e1313C95D6D63e9A95c4eEeaC9D9a3,

        // Company - 10% tokens
        0x8A6d301742133C89f08153BC9F52B585F824A18b,

        // Team - 13% tokens, no freeze
        0xE9B02195F38938f1462c59D7c1c2F15350ad1543

        ];
    }

    function onlyAdmin(bool forObserver) internal view {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender ||
        forObserver==true && wallets[uint8(Roles.observer)] == msg.sender);
    }

    // Setting the current rate ETH/USD         
    function changeExchange(uint256 _ETHUSD) public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.observer)] == msg.sender);
        require(_ETHUSD >= 1 ether);

        softCap=softCap.mul(exchange).div(_ETHUSD);             // QUINTILLIONS
        hardCap=hardCap.mul(exchange).div(_ETHUSD);             // QUINTILLIONS
        minPay=minPay.mul(exchange).div(_ETHUSD);               // QUINTILLIONS

        rate=rate.mul(_ETHUSD).div(exchange);                   // QUINTILLIONS

        for (uint16 i = 0; i < bonuses.length; i++) {
            bonuses[i].value=bonuses[i].value.mul(exchange).div(_ETHUSD);   // QUINTILLIONS
        }

        financialStrategy.setup(wallets[uint8(Roles.beneficiary)], exchange, _ETHUSD, 5);

        exchange=_ETHUSD;

    }

    // Setting of basic parameters, analog of class constructor
    // @ Do I have to use the function      see your scenario
    // @ When it is possible to call        before Round 1/2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function begin() public
    {
        onlyAdmin(true);
        if (isBegin) return;
        isBegin=true;

        token = creator.createToken();

        financialStrategy = creator.createFinancialStrategy();

        token.setUnpausedWallet(wallets[uint8(Roles.accountant)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.manager)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.bounty)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.company)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.observer)], true);

        bonuses.push(Bonus(20 ether, 2,0));
        bonuses.push(Bonus(100 ether, 5,0));
        bonuses.push(Bonus(400 ether, 8,0));

        profits.push(Profit(30,900 days));
    }



    // Issue of tokens for the zero round, it is usually called: private pre-sale (Round 0)
    // @ Do I have to use the function      may be
    // @ When it is possible to call        before Round 1/2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function firstMintRound0(uint256 _amount /* QUINTILLIONS! */) public {
        onlyAdmin(false);
        require(canFirstMint);
        begin();
        token.mint(wallets[uint8(Roles.manager)],_amount);
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
    function forwardFunds() internal {
        financialStrategy.deposit.value(msg.value)(msg.sender);
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
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isPausedCrowdsale;
    }

    // Check for the ability to finalize the round. Constant.
    function hasEnded() public view returns (bool) {

        bool timeReached = now > endTime.add(renewal);

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }

    // Finalize. Only available to the Manager and the Beneficiary. If the round failed, then
    // anyone can call the finalization to unlock the return of funds to investors
    // You must call a function to finalize each round (after the Round1 & after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        after end of Round1 & Round2
    // @ When it is launched automatically  no
    // @ Who can call the function          admins or anybody (if round is failed)
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender || !goalReached());
        require(!isFinalized);
        require(hasEnded() || ((wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender) && goalReached()));

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

        // If the goal of the achievement
        if (goalReached()) {

            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 1);//Р”Р&#187;СЏ РєРѕРЅС‚СЂР&#176;РєС‚Р&#176; Buz РґР&#181;РЅСЊРіРё РЅР&#181; РІРѕР&#183;РІСЂР&#176;С‰Р&#176;Р&#181;С‚.

            // if there is anything to give
            if (tokenReserved > 0) {

                token.mint(wallets[uint8(Roles.accountant)],tokenReserved);

                // Reset the counter
                tokenReserved = 0;
            }

            // If the finalization is Round 1
            if (TokenSale == TokenSaleType.round1) {

                // Reset settings
                isInitialized = false;
                isFinalized = false;

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

                totalSaledToken = token.totalSupply();
                //partners = true;

            }

        }
        else // If they failed round
        {
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 3);
        }
    }

    // The Manager freezes the tokens for the Team.
    // You must call a function to finalize Round 2 (only after the Round2)
    // @ Do I have to use the function      yes
    // @ When it is possible to call        Round2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function finalize2() public {

        onlyAdmin(false);
        require(chargeBonuses);
        chargeBonuses = false;

        //allocation = creator.createAllocation(token, now + 1 years /* stage N1 */, now + 2 years /* stage N2 */);
        //token.setUnpausedWallet(allocation, true);
        // Team = %, Founders = %, Fund = %    TOTAL = %
        //allocation.addShare(wallets[uint8(Roles.team)],       6,  50); // only 50% - first year, stage N1  (and +50 for stage N2)
        //allocation.addShare(wallets[uint8(Roles.founders)],  10,  50); // only 50% - first year, stage N1  (and +50 for stage N2)

        // 2% - bounty wallet
        token.mint(wallets[uint8(Roles.bounty)], totalSaledToken.mul(2).div(75));

        // 10% - company
        token.mint(wallets[uint8(Roles.company)], totalSaledToken.mul(10).div(75));

        // 13% - team
        token.mint(wallets[uint8(Roles.team)], totalSaledToken.mul(13).div(75));


    }

    function changeCrowdsale(address _newCrowdsale) external {
        //onlyAdmin(false);
        require(wallets[uint8(Roles.manager)] == msg.sender);
        Ownable(token).transferOwnership(_newCrowdsale);
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

        onlyAdmin(false);
        // If not yet initialized
        require(!isInitialized);
        begin();


        // And the specified start time has not yet come
        // If initialization return an error, check the start date!
        require(now <= startTime);

        initialization();

        emit Initialized();

        renewal = 0;

        isInitialized = true;

        canFirstMint = false;
    }

    function initialization() internal {
        if (financialStrategy.state() != IFinancialStrategy.State.Active){
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 2);
        }
    }

    // 
    // @ Do I have to use the function      
    // @ When it is possible to call        
    // @ When it is launched automatically  
    // @ Who can call the function          
    function getPartnerCash(uint8 _user, bool _calc) external {
        bool isAdmin=false;
        for (uint8 i=0; i<wallets.length; i++) {
            if (wallets[i]==msg.sender) {
                isAdmin=true;
                break;
            }
        }
        financialStrategy.getPartnerCash(_user, isAdmin, msg.sender, _calc, weiTotalRaised());
    }

    function getBeneficiaryCash() external {
        onlyAdmin(false);
        // financialStrategy.calc(weiTotalRaised());
        financialStrategy.getBeneficiaryCash(wallets[uint8(Roles.beneficiary)]);
    }

    function calcFin() external {
        onlyAdmin(true);
        financialStrategy.calc(weiTotalRaised());
    }

    function calcAndGet() public {
        onlyAdmin(true);
        
        financialStrategy.calc(weiTotalRaised());
        financialStrategy.getBeneficiaryCash(wallets[uint8(Roles.beneficiary)]);
        
        for (uint8 i=0; i<3; i++) { // <-- TODO check financialStrategy.wallets.length
            financialStrategy.getPartnerCash(i, true, msg.sender, false, weiTotalRaised());
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

        onlyAdmin(false);
        require(!isInitialized);

        begin();

        // Date and time are correct
        require(now <= _startTime);
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

    // The ability to quickly check Round1 (only for Round1, only 1 time). Completes the Round1 by
    // transferring the specified number of tokens to the Accountant&#39;s wallet. Available to the Manager.
    // Use only if this is provided by the script and white paper. In the normal scenario, it
    // does not call and the funds are raised normally. We recommend that you delete this
    // function entirely, so as not to confuse the auditors. Initialize & Finalize not needed.
    // ** QUINTILIONS **  10^18 / 1**18 / 1e18
    // @ Do I have to use the function      no, see your scenario
    // @ When it is possible to call        after Round0 and before Round2
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    //    function fastTokenSale(uint256 _totalSupply) external {
    //      onlyAdmin(false);
    //        require(TokenSale == TokenSaleType.round1 && !isInitialized);
    //        token.mint(wallets[uint8(Roles.accountant)], _totalSupply);
    //        TokenSale = TokenSaleType.round2;
    //    }


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

        require(wallets[uint8(Roles.manager)] == msg.sender
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
        onlyAdmin(false);
        require(!isFinalized);
        token.setPause(true);
    }

    // Pause of sale. Available to the manager.
    // @ Do I have to use the function      no
    // @ When it is possible to call        during active rounds
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function setCrowdsalePause(bool mode) public {
        onlyAdmin(false);
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
        onlyAdmin(false);
        token.setMigrationAgent(_migrationAgent);
    }

    // @ Do I have to use the function      no
    // @ When it is possible to call        only after ICO!
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function migrateAll(address[] _holders) public {
        onlyAdmin(false);
        token.migrateAll(_holders);
    }

    // Change the address for the specified role.
    // Available to any wallet owner except the observer.
    // Available to the manager until the round is initialized.
    // The Observer&#39;s wallet or his own manager can change at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        depend...
    // @ When it is launched automatically  -
    // @ Who can call the function          staff (all 7+ roles)
    function changeWallet(Roles _role, address _wallet) external
    {
        require(
            (msg.sender == wallets[uint8(_role)] /*&& _role != Roles.observer*/)
            ||
            (msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer))
        );

        wallets[uint8(_role)] = _wallet;
    }


    // The beneficiary at any time can take rights in all roles and prescribe his wallet in all the
    // rollers. Thus, he will become the recipient of tokens for the role of Accountant,
    // Team, etc. Works at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          only Beneficiary
//    function resetAllWallets() external{
//        address _beneficiary = wallets[uint8(Roles.beneficiary)];
//        require(msg.sender == _beneficiary);
//        for(uint8 i = 0; i < wallets.length; i++){
//            wallets[i] = _beneficiary;
//        }
//        token.setUnpausedWallet(_beneficiary, true);
//    }


    // Burn the investor tokens, if provided by the ICO scenario. Limited time available - BURN_TOKENS_TIME
    // For people who ignore the KYC/AML procedure during 30 days after payment: money back and burning tokens.
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        any time
    // @ When it is launched automatically  -
    // @ Who can call the function          admin
    function massBurnTokens(address[] _beneficiary, uint256[] _value) external {
        onlyAdmin(false);
        require(endTime.add(renewal).add(BURN_TOKENS_TIME) > now);
        require(_beneficiary.length == _value.length);
        for(uint16 i; i<_beneficiary.length; i++) {
            token.burn(_beneficiary[i],_value[i]);
        }
    }

    // Extend the round time, if provided by the script. Extend the round only for
    // a limited number of days - ROUND_PROLONGATE
    // ***CHECK***SCENARIO***
    // @ Do I have to use the function      no
    // @ When it is possible to call        during active round
    // @ When it is launched automatically  -
    // @ Who can call the function          admins
    function prolongate(uint256 _duration) external {
        onlyAdmin(false);
        require(now > startTime && now < endTime.add(renewal) && isInitialized);
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
    function distructVault(bool mode) public {
        if(mode){
            if (wallets[uint8(Roles.beneficiary)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT1))) {
                financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 0);
            }
            if (wallets[uint8(Roles.manager)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT2))) {
                financialStrategy.setup(wallets[uint8(Roles.manager)], weiRaised(), 0, 0);
            }
        } else {
            onlyAdmin(false);
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], 0, 0, 4);
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

        // For audit:
        // BTC  13vL9G4Gt2BX58qQQfauf9JbFFjC5pEnQy
        // XRP  rHG2nJCKYEe326zhTtXWVEeDob81VKkK3q
        // DASH XcMZbRJzPghTcZPyScF21mL3eKhYAGo4Ab
        // LTC  LcKTi2ZduMvHo7WbXye2RhLy9xMZjdXWZS

        require(wallets[uint8(Roles.observer)] == msg.sender || wallets[uint8(Roles.manager)] == msg.sender);
        //onlyAdmin(true);
        bool withinPeriod = (now >= startTime && now <= endTime.add(renewal));

        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

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
    }


    // The function for obtaining smart contract funds in ETH. If all the checks are true, the token is
    // transferred to the buyer, taking into account the current bonus.
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
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

        lokedMint(beneficiary, tokens, curBonus.freezeTime);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // buyTokens alias
    function () public payable {
        buyTokens(msg.sender);
    }
}

contract MigratableToken is BasicToken,Ownable {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }


    function migrateInternal(address _holder) internal{
        require(migrationAgent != 0x0);

        uint256 value = balances[_holder];
        balances[_holder] = 0;

        totalSupply_ = totalSupply_.sub(value);
        totalMigrated = totalMigrated.add(value);

        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        emit Migrate(_holder,migrationAgent,value);
    }

    function migrateAll(address[] _holders) public onlyOwner {
        for(uint i = 0; i < _holders.length; i++){
            migrateInternal(_holders[i]);
        }
    }

    // Reissue your tokens.
    function migrate() public
    {
        require(balances[msg.sender] > 0);
        migrateInternal(msg.sender);
    }

}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _beneficiary, uint256 _value) public onlyOwner {
        require(_value <= balances[_beneficiary]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_beneficiary, _value);
        emit Transfer(_beneficiary, address(0), _value);
    }
}

contract Pausable is Ownable {

    mapping (address => bool) public unpausedWallet;

    event Pause();
    event Unpause();

    bool public paused = true;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address _to) {
        require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        _;
    }

    function onlyAdmin() internal view {
        require(owner == msg.sender || msg.sender == ICrowdsale(owner).wallets(uint8(ICrowdsale.Roles.manager)));
    }

    // Add a wallet ignoring the "Exchange pause". Available to the owner of the contract.
    function setUnpausedWallet(address _wallet, bool mode) public {
        onlyAdmin();
        unpausedWallet[_wallet] = mode;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function setPause(bool mode) onlyOwner public {

        if (!paused && mode) {
            paused = true;
            emit Pause();
        }
        if (paused && !mode) {
            paused = false;
            emit Unpause();
        }
    }

}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract FreezingToken is PausableToken {
    struct freeze {
    uint256 amount;
    uint256 when;
    }


    mapping (address => freeze) freezedTokens;

    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }

    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public {
        onlyAdmin();
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function masFreezedTokens(address[] _beneficiary, uint256[] _amount, uint256[] _when) public {
        onlyAdmin();
        require(_beneficiary.length == _amount.length && _beneficiary.length == _when.length);
        for(uint16 i = 0; i < _beneficiary.length; i++){
            freeze storage _freeze = freezedTokens[_beneficiary[i]];
            _freeze.amount = _amount[i];
            _freeze.when = _when[i];
        }
    }


    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(unpausedWallet[msg.sender]);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_to];
            _freeze.amount = _freeze.amount.add(_value);
            _freeze.when = (_freeze.when > _when)? _freeze.when: _when;
        }
        transfer(_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        return super.transferFrom( _from,_to,_value);
    }



}

contract Token is IToken, FreezingToken, MintableToken, MigratableToken, BurnableToken{
    string public constant name = "BUZcoin";
    string public constant symbol = "BUZ";
    uint8 public constant decimals = 18;
}

contract Creator is ICreator{
    IToken public token = new Token();
    IFinancialStrategy public financialStrategy = new BuzFinancialStrategy();

    function createToken() external returns (IToken) {
        Token(token).transferOwnership(msg.sender);
        return token;
    }

    function createFinancialStrategy() external returns(IFinancialStrategy) {
        BuzFinancialStrategy(financialStrategy).transferOwnership(msg.sender);
        return financialStrategy;
    }
}