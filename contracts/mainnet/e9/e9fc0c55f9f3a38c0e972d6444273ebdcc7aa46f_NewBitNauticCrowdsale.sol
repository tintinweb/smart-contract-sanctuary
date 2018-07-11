pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Math
 * @dev Math operations with safety checks that throw on error
 */
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

contract Ownable {
    address internal owner;

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
    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        require(newOwner != address(0x0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

        return true;
    }
}

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
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Unlocked }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state != State.Refunding);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function unlock() onlyOwner public {
        require(state == State.Active);
        state = State.Unlocked;
    }

    function withdraw(address beneficiary, uint256 amount) onlyOwner public {
        require(beneficiary != 0x0);
        require(state == State.Unlocked);

        beneficiary.transfer(amount);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}

interface MintableToken {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferOwnership(address newOwner) external returns (bool);
}

/**
    This contract will handle the KYC contribution caps and the AML whitelist.
    The crowdsale contract checks this whitelist everytime someone tries to buy tokens.
*/
contract BitNauticWhitelist is Ownable {
    using SafeMath for uint256;

    uint256 public usdPerEth;

    function BitNauticWhitelist(uint256 _usdPerEth) public {
        usdPerEth = _usdPerEth;
    }

    mapping(address => bool) public AMLWhitelisted;
    mapping(address => uint256) public contributionCap;

    /**
     * @dev sets the KYC contribution cap for one address
     * @param addr address
     * @param level uint8
     * @return true if the operation was successful
     */
    function setKYCLevel(address addr, uint8 level) onlyOwner public returns (bool) {
        if (level >= 3) {
            contributionCap[addr] = 50000 ether; // crowdsale hard cap
        } else if (level == 2) {
            contributionCap[addr] = SafeMath.div(500000 * 10 ** 18, usdPerEth); // KYC Tier 2 - 500k USD
        } else if (level == 1) {
            contributionCap[addr] = SafeMath.div(3000 * 10 ** 18, usdPerEth); // KYC Tier 1 - 3k USD
        } else {
            contributionCap[addr] = 0;
        }

        return true;
    }

    function setKYCLevelsBulk(address[] addrs, uint8[] levels) onlyOwner external returns (bool success) {
        require(addrs.length == levels.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setKYCLevel(addrs[i], levels[i]));
        }

        return true;
    }

    /**
     * @dev adds the specified address to the AML whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function setAMLWhitelisted(address addr, bool whitelisted) onlyOwner public returns (bool) {
        AMLWhitelisted[addr] = whitelisted;

        return true;
    }

    function setAMLWhitelistedBulk(address[] addrs, bool[] whitelisted) onlyOwner external returns (bool) {
        require(addrs.length == whitelisted.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setAMLWhitelisted(addrs[i], whitelisted[i]));
        }

        return true;
    }
}

contract NewBitNauticCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    uint256 public ICOStartTime = 1531267200; // 11 Jul 2018 00:00 GMT
    uint256 public ICOEndTime = 1537056000; // 16 Sep 2018 00:00 GMT

    uint256 public constant tokenBaseRate = 500; // 1 ETH = 500 BTNT

    bool public manualBonusActive = false;
    uint256 public manualBonus = 0;

    uint256 public constant crowdsaleSupply = 35000000 * 10 ** 18;
    uint256 public tokensSold = 0;

    uint256 public constant softCap = 2500000 * 10 ** 18;

    uint256 public teamSupply =     3000000 * 10 ** 18; // 6% of token cap
    uint256 public bountySupply =   2500000 * 10 ** 18; // 5% of token cap
    uint256 public reserveSupply =  5000000 * 10 ** 18; // 10% of token cap
    uint256 public advisorSupply =  2500000 * 10 ** 18; // 5% of token cap
    uint256 public founderSupply =  2000000 * 10 ** 18; // 4% of token cap

    // amount of tokens each address will receive at the end of the crowdsale
    mapping (address => uint256) public creditOf;

    // amount of ether invested by each address
    mapping (address => uint256) public weiInvestedBy;

    // refund vault used to hold funds while crowdsale is running
    RefundVault private vault;

    MintableToken public token;
    BitNauticWhitelist public whitelist;

    constructor(MintableToken _token, BitNauticWhitelist _whitelist, address _beneficiary) public {
        token = _token;
        whitelist = _whitelist;
        vault = new RefundVault(_beneficiary);
    }

    function() public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        // checks if the ether amount invested by the buyer is lower than his contribution cap
        require(SafeMath.add(weiInvestedBy[msg.sender], msg.value) <= whitelist.contributionCap(msg.sender));

        // compute the amount of tokens given the baseRate
        uint256 tokens = SafeMath.mul(msg.value, tokenBaseRate);
        // add the bonus tokens depending on current time
        tokens = tokens.add(SafeMath.mul(tokens, getCurrentBonus()).div(1000));

        // check hardcap
        require(SafeMath.add(tokensSold, tokens) <= crowdsaleSupply);

        // update total token sold counter
        tokensSold = SafeMath.add(tokensSold, tokens);

        // keep track of the token credit and ether invested by the buyer
        creditOf[beneficiary] = creditOf[beneficiary].add(tokens);
        weiInvestedBy[msg.sender] = SafeMath.add(weiInvestedBy[msg.sender], msg.value);

        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

        vault.deposit.value(msg.value)(msg.sender);
    }

    function privateSale(address beneficiary, uint256 tokenAmount) onlyOwner public {
        require(beneficiary != 0x0);
        require(SafeMath.add(tokensSold, tokenAmount) <= crowdsaleSupply); // check hardcap

        tokensSold = SafeMath.add(tokensSold, tokenAmount);

        assert(token.mint(beneficiary, tokenAmount));
    }

    // for payments in other currencies
    function offchainSale(address beneficiary, uint256 tokenAmount) onlyOwner public {
        require(beneficiary != 0x0);
        require(SafeMath.add(tokensSold, tokenAmount) <= crowdsaleSupply); // check hardcap

        tokensSold = SafeMath.add(tokensSold, tokenAmount);

        // keep track of the token credit of the buyer
        creditOf[beneficiary] = creditOf[beneficiary].add(tokenAmount);

        emit TokenPurchase(beneficiary, beneficiary, 0, tokenAmount);
    }

    // this function can be called by the contributor to claim his BTNT tokens at the end of the ICO
    function claimBitNauticTokens() public returns (bool) {
        return grantContributorTokens(msg.sender);
    }

    // if the ICO is finished and the goal has been reached, this function will be used to mint and transfer BTNT tokens to each contributor
    function grantContributorTokens(address contributor) public returns (bool) {
        require(creditOf[contributor] > 0);
        require(whitelist.AMLWhitelisted(contributor));
        require(now > ICOEndTime && tokensSold >= softCap);

        assert(token.mint(contributor, creditOf[contributor]));
        creditOf[contributor] = 0;

        return true;
    }

    // returns the token sale bonus permille depending on the current time
    function getCurrentBonus() public view returns (uint256) {
        if (manualBonusActive) return manualBonus;

        return Math.min(340, Math.max(100, (340 - (now - ICOStartTime) / (60 * 60 * 24) * 4)));
    }

    function setManualBonus(uint256 newBonus, bool isActive) onlyOwner public returns (bool) {
        manualBonus = newBonus;
        manualBonusActive = isActive;

        return true;
    }

    function setICOEndTime(uint256 newEndTime) onlyOwner public returns (bool) {
        ICOEndTime = newEndTime;

        return true;
    }

    function validPurchase() internal view returns (bool) {
        bool duringICO = ICOStartTime <= now && now <= ICOEndTime;
        bool minimumContribution = msg.value >= 0.05 ether;
        return duringICO && minimumContribution;
    }

    function hasEnded() public view returns (bool) {
        return now > ICOEndTime;
    }

    function unlockVault() onlyOwner public {
        if (tokensSold >= softCap) {
            vault.unlock();
        }
    }

    function withdraw(address beneficiary, uint256 amount) onlyOwner public {
        vault.withdraw(beneficiary, amount);
    }

    bool isFinalized = false;
    function finalizeCrowdsale() onlyOwner public {
        require(!isFinalized);
        require(now > ICOEndTime);

        if (tokensSold < softCap) {
            vault.enableRefunds();
        }

        isFinalized = true;
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(tokensSold < softCap);

        vault.refund(msg.sender);
    }

    function transferTokenOwnership(address newTokenOwner) onlyOwner public returns (bool) {
        return token.transferOwnership(newTokenOwner);
    }

    function grantBountyTokens(address beneficiary) onlyOwner public {
        require(bountySupply > 0);

        token.mint(beneficiary, bountySupply);
        bountySupply = 0;
    }

    function grantReserveTokens(address beneficiary) onlyOwner public {
        require(reserveSupply > 0);

        token.mint(beneficiary, reserveSupply);
        reserveSupply = 0;
    }

    function grantAdvisorsTokens(address beneficiary) onlyOwner public {
        require(advisorSupply > 0);

        token.mint(beneficiary, advisorSupply);
        advisorSupply = 0;
    }

    function grantFoundersTokens(address beneficiary) onlyOwner public {
        require(founderSupply > 0);

        token.mint(beneficiary, founderSupply);
        founderSupply = 0;
    }

    function grantTeamTokens(address beneficiary) onlyOwner public {
        require(teamSupply > 0);

        token.mint(beneficiary, teamSupply);
        teamSupply = 0;
    }
}