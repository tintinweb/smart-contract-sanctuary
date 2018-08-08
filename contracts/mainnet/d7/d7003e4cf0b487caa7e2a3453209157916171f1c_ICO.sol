pragma solidity ^0.4.20;

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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ShortAddressProtection {

    modifier onlyPayloadSize(uint256 numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, ShortAddressProtection {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        //require user to set to zero before resetting to nonzero
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title MintableToken token
 */
contract MintableToken is Ownable, StandardToken {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    address public saleAgent;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    function setSaleAgent(address _saleAgent) onlyOwner public {
        require(_saleAgent != address(0));
        saleAgent = _saleAgent;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlySaleAgent canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlySaleAgent canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract Token is MintableToken {
    string public constant name = "TOKPIE";
    string public constant symbol = "TKP";
    uint8 public constant decimals = 18;
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Ownable {

    mapping(address => bool) public whitelist;

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }
}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Pausable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal;
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}

    mapping(address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /**
     * @param _wallet Vault address
     */
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    /**
     * @param investor Investor address
     */
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    /**
     * @param investor Investor address
     */
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract preICO is FinalizableCrowdsale, WhitelistedCrowdsale {
    Token public token;

    // May 01, 2018 @ UTC 0:01
    uint256 public startDate;

    // May 14, 2018 @ UTC 23:59
    uint256 public endDate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // how many token units a buyer gets per wei
    uint256 public constant rate = 1920;

    uint256 public constant softCap = 500 * (1 ether);

    uint256 public constant hardCap = 1000 * (1 ether);

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev _wallet where collect funds during crowdsale
     * @dev _startDate should be 1525132860
     * @dev _endDate should be 1526342340
     * @dev _maxEtherPerInvestor should be 10 ether
     */
    function preICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate) public {
        require(_token != address(0) && _wallet != address(0));
        require(_endDate > _startDate);
        startDate = _startDate;
        endDate = _endDate;
        token = Token(_token);
        vault = new RefundVault(_wallet);
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    function goalReached() public view returns (bool) {
        return weiRaised >= softCap;
    }

    /**
     * @dev vault finalization task, called when owner calls finalize()
     */
    function finalization() internal {
        require(hasEnded());
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(!hasEnded());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // Minimum contribution level in TKP tokens for each investor = 100 TKP
        require(tokens >= 100 * (10 ** 18));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        return !isFinalized && now >= startDate && msg.value != 0;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return (now > endDate || weiRaised >= hardCap);
    }
}

contract ICO is Pausable, WhitelistedCrowdsale {
    using SafeMath for uint256;

    Token public token;

    // June 01, 2018 @ UTC 0:01
    uint256 public startDate;

    // July 05, 2018 on UTC 23:59
    uint256 public endDate;

    uint256 public hardCap;

    // amount of raised money in wei
    uint256 public weiRaised;

    address public wallet;

    mapping(address => uint256) public deposited;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev _wallet where collect funds during crowdsale
     * @dev _startDate should be 1527811260
     * @dev _endDate should be 1530835140
     * @dev _maxEtherPerInvestor should be 10 ether
     * @dev _hardCap should be 8700 ether
     */
    function ICO(address _token, address _wallet, uint256 _startDate, uint256 _endDate, uint256 _hardCap) public {
        require(_token != address(0) && _wallet != address(0));
        require(_endDate > _startDate);
        require(_hardCap > 0);
        startDate = _startDate;
        endDate = _endDate;
        hardCap = _hardCap;
        token = Token(_token);
        wallet = _wallet;
    }

    function claimFunds() onlyOwner public {
        require(hasEnded());
        wallet.transfer(this.balance);
    }

    function getRate() public view returns (uint256) {
        if (now < startDate || hasEnded()) return 0;

        // Period: from June 01, 2018 @ UTC 0:01 to June 7, 2018 @ UTC 23:59; Price: 1 ETH = 1840 TKP
        if (now >= startDate && now < startDate + 604680) return 1840;
        // Period: from June 08, 2018 @ UTC 0:00 to June 14, 2018 @ UTC 23:59; Price: 1 ETH = 1760 TKP
        if (now >= startDate + 604680 && now < startDate + 1209480) return 1760;
        // Period: from June 15, 2018 @ UTC 0:00 to June 21, 2018 @ UTC 23:59; Price: 1 ETH = 1680 TKP
        if (now >= startDate + 1209480 && now < startDate + 1814280) return 1680;
        // Period: from June 22, 2018 @ UTC 0:00 to June 28, 2018 @ UTC 23:59; Price: 1 ETH = 1648 TKP
        if (now >= startDate + 1814280 && now < startDate + 2419080) return 1648;
        // Period: from June 29, 2018 @ UTC 0:00 to July 5, 2018 @ UTC 23:59; Price: 1 ETH = 1600 TKP
        if (now >= startDate + 2419080) return 1600;
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) whenNotPaused isWhitelisted(beneficiary) isWhitelisted(msg.sender) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(!hasEnded());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // Minimum contribution level in TKP tokens for each investor = 100 TKP
        require(tokens >= 100 * (10 ** 18));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        return now >= startDate && msg.value != 0;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return (now > endDate || weiRaised >= hardCap);
    }
}

contract postICO is Ownable {
    using SafeMath for uint256;

    Token public token;

    address public walletE;
    address public walletB;
    address public walletC;
    address public walletF;
    address public walletG;

    // 05.07.18 @ UTC 23:59
    uint256 public endICODate;

    bool public finished = false;

    uint256 public FTST;

    // Save complete of transfers (due to schedule) to these wallets 
    mapping(uint8 => bool) completedE;
    mapping(uint8 => bool) completedBC;

    uint256 public paymentSizeE;
    uint256 public paymentSizeB;
    uint256 public paymentSizeC;

    /**
     * @dev _endICODate should be 1530835140
     */
    function postICO(
        address _token,
        address _walletE,
        address _walletB,
        address _walletC,
        address _walletF,
        address _walletG,
        uint256 _endICODate
    ) public {
        require(_token != address(0));
        require(_walletE != address(0));
        require(_walletB != address(0));
        require(_walletC != address(0));
        require(_walletF != address(0));
        require(_walletG != address(0));
        require(_endICODate >= now);

        token = Token(_token);
        endICODate = _endICODate;

        walletE = _walletE;
        walletB = _walletB;
        walletC = _walletC;
        walletF = _walletF;
        walletG = _walletG;
    }

    function finish() onlyOwner public {
        require(now > endICODate);
        require(!finished);
        require(token.saleAgent() == address(this));

        FTST = token.totalSupply().mul(100).div(65);

        // post ICO token allocation: 35% of final total supply of tokens (FTST) will be distributed to the wallets E, B, C, F, G due to the schedule described below. Where FTST = the number of tokens sold during crowdsale x 100 / 65.
        // Growth reserve: 21% (4-years lock). Distribute 2.625% of the final total supply of tokens (FTST*2625/100000) 8 (eight) times every half a year during 4 (four) years after the endICODate to the wallet [E].
        // hold this tokens on postICO contract
        paymentSizeE = FTST.mul(2625).div(100000);
        uint256 tokensE = paymentSizeE.mul(8);
        token.mint(this, tokensE);

        // Team: 9.6% (2-years lock).
        // Distribute 0.25% of final total supply of tokens (FTST*25/10000) 4 (four) times every half a year during 2 (two) years after endICODate to the wallet [B].
        // hold this tokens on postICO contract
        paymentSizeB = FTST.mul(25).div(10000);
        uint256 tokensB = paymentSizeB.mul(4);
        token.mint(this, tokensB);

        // Distribute 2.15% of final total supply of tokens (FTST*215/10000) 4 (four) times every half a year during 2 (two) years after endICODate to the wallet [C]. 
        // hold this tokens on postICO contract
        paymentSizeC = FTST.mul(215).div(10000);
        uint256 tokensC = paymentSizeC.mul(4);
        token.mint(this, tokensC);

        // Angel investors: 2%. Distribute 2% of final total supply of tokens (FTST*2/100) after endICODate to the wallet [F].
        uint256 tokensF = FTST.mul(2).div(100);
        token.mint(walletF, tokensF);

        // Referral program 1,3% + Bounty program: 1,1%. Distribute 2,4% of final total supply of tokens (FTST*24/1000) after endICODate to the wallet [G]. 
        uint256 tokensG = FTST.mul(24).div(1000);
        token.mint(walletG, tokensG);

        token.finishMinting();
        finished = true;
    }

    function claimTokensE(uint8 order) onlyOwner public {
        require(finished);
        require(order >= 1 && order <= 8);
        require(!completedE[order]);

        // On January 03, 2019 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 1) {
            // Thursday, 3 January 2019 г., 23:59:00
            require(now >= endICODate + 15724800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On July 05, 2019 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 2) {
            // Friday, 5 July 2019 г., 23:59:00
            require(now >= endICODate + 31536000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On January 03, 2020 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 3) {
            // Friday, 3 January 2020 г., 23:59:00
            require(now >= endICODate + 47260800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On July 04, 2020 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 4) {
            // Saturday, 4 July 2020 г., 23:59:00
            require(now >= endICODate + 63072000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On January 02, 2021 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 5) {
            // Saturday, 2 January 2021 г., 23:59:00
            require(now >= endICODate + 78796800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On July 04, 2021 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 6) {
            // Sunday, 4 July 2021 г., 23:59:00
            require(now >= endICODate + 94608000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On January 02, 2022 @ UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 7) {
            // Sunday, 2 January 2022 г., 23:59:00
            require(now >= endICODate + 110332800);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
        // On July 04, <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7c4e4c4e4e3c">[email&#160;protected]</a> UTC 23:59 = FTST*2625/100000 (2.625% of final total supply of tokens) to the wallet [E].
        if (order == 8) {
            // Monday, 4 July 2022 г., 23:59:00
            require(now >= endICODate + 126144000);
            token.transfer(walletE, paymentSizeE);
            completedE[order] = true;
        }
    }

    function claimTokensBC(uint8 order) onlyOwner public {
        require(finished);
        require(order >= 1 && order <= 4);
        require(!completedBC[order]);

        // On January 03, 2019 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        if (order == 1) {
            // Thursday, 3 January 2019 г., 23:59:00
            require(now >= endICODate + 15724800);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
        // On July 05, 2019 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        if (order == 2) {
            // Friday, 5 July 2019 г., 23:59:00
            require(now >= endICODate + 31536000);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
        // On January 03, 2020 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        if (order == 3) {
            // Friday, 3 January 2020 г., 23:59:00
            require(now >= endICODate + 47260800);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
        // On July 04, 2020 @ UTC 23:59 = FTST*25/10000 (0.25% of final total supply of tokens) to the wallet [B] and FTST*215/10000 (2.15% of final total supply of tokens) to the wallet [C].
        if (order == 4) {
            // Saturday, 4 July 2020 г., 23:59:00
            require(now >= endICODate + 63072000);
            token.transfer(walletB, paymentSizeB);
            token.transfer(walletC, paymentSizeC);
            completedBC[order] = true;
        }
    }
}

contract Controller is Ownable {
    Token public token;
    preICO public pre;
    ICO public ico;
    postICO public post;

    enum State {NONE, PRE_ICO, ICO, POST}

    State public state;

    function Controller(address _token, address _preICO, address _ico, address _postICO) public {
        require(_token != address(0x0));
        token = Token(_token);
        pre = preICO(_preICO);
        ico = ICO(_ico);
        post = postICO(_postICO);

        require(post.endICODate() == ico.endDate());

        require(pre.weiRaised() == 0);
        require(ico.weiRaised() == 0);

        require(token.totalSupply() == 0);
        state = State.NONE;
    }

    function startPreICO() onlyOwner public {
        require(state == State.NONE);
        require(token.owner() == address(this));
        token.setSaleAgent(pre);
        state = State.PRE_ICO;
    }

    function startICO() onlyOwner public {
        require(now > pre.endDate());
        require(state == State.PRE_ICO);
        require(token.owner() == address(this));
        token.setSaleAgent(ico);
        state = State.ICO;
    }

    function startPostICO() onlyOwner public {
        require(now > ico.endDate());
        require(state == State.ICO);
        require(token.owner() == address(this));
        token.setSaleAgent(post);
        state = State.POST;
    }
}