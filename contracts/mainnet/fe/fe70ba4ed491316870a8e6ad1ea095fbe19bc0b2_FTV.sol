pragma solidity ^0.4.11;

library Bonus {
    uint16 constant ORIGIN_YEAR = 1970;

    struct BonusData {
        uint cutoff0;
        uint cutoff1;
        uint cutoff2;
        uint cutoff3;
    }

    // use storage keyword so that we write this to persistent storage
    function initCutoffs(BonusData storage data)
    internal
    {
        data.cutoff0 = toTimestamp(2018, 5, 29);
        data.cutoff1 = toTimestamp(2018, 6, 11);
        data.cutoff2 = toTimestamp(2018, 6, 24);
        data.cutoff3 = toTimestamp(2018, 6, 31);
    }

    function get_FTVTOKEN_EURCENT(uint timestamp, BonusData storage data)
    internal view returns (uint256 FTVTOKEN_EURCENT)
    {
        require(data.cutoff0 > 0);

        if (timestamp < data.cutoff0) {
            return 18;
        } else if (timestamp < data.cutoff1) {
            return 20;
        } else if (timestamp < data.cutoff2) {
            return 22;
        } else if (timestamp < data.cutoff3) {
            return 24;
        }
        return 25;
    }

    // Timestamp functions based on
    // https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
    function toTimestamp(uint16 year, uint8 month, uint8 day)
    internal pure returns (uint timestamp) {
        uint16 i;

        // Year
        timestamp += (year - ORIGIN_YEAR) * 1 years;
        timestamp += (leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR)) * 1 days;

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += monthDayCounts[i - 1] * 1 days;
        }

        // Day
        timestamp += (day - 1) * 1 days;

        // Hour, Minute, and Second are assumed as 0 (we calculate in GMT)

        return timestamp;
    }

    function leapYearsBefore(uint year)
    internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isLeapYear(uint16 year)
    internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }
}
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
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

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
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
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
    function approve(address _spender, uint256 _value) public returns (bool) {
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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
contract FTV is StandardToken {

    // data structures
    enum States {
        Initial, // deployment time
        ValuationSet,
        Ico, // whitelist addresses, accept funds, update balances
        Underfunded, // ICO time finished and minimal amount not raised
        Operational, // production phase
        Paused         // for contract upgrades
    }

    mapping(address => uint256) public ethPossibleRefunds;

    uint256 public soldTokens;

    string public constant name = "FTV Coin Deluxe";

    string public constant symbol = "FTV";

    uint8 public constant decimals = 18;

    mapping(address => bool) public whitelist;

    mapping(address => address) public referral;

    address public reserves;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public tokenAssignmentControl;

    States public state;

    uint256 public endBlock;

    uint256 public ETH_EUR;

    uint256 constant pointMultiplier = 1e18; //100% = 1*10^18 points

    uint256 public constant maxTotalSupply = 1500000000 * pointMultiplier; //1.5B tokens

    uint256 public constant percentForSale = 25;

    Bonus.BonusData bonusData;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    //this creates the contract and stores the owner. it also passes in 3 addresses to be used later during the lifetime of the contract.
    function FTV(
        address _stateControl
    , address _whitelistControl
    , address _withdrawControl
    , address _tokenAssignmentControl
    , address _reserves
    ) public
    {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        endBlock = 0;
        ETH_EUR = 0;
        totalSupply = maxTotalSupply;
        soldTokens = 0;
        Bonus.initCutoffs(bonusData);
        reserves = _reserves;
        balances[reserves] = totalSupply;
        Mint(reserves, totalSupply);
        Transfer(0x0, reserves, totalSupply);
    }

    event Whitelisted(address addr);

    event Referred(address parent, address child);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl);
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl);
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl);
        _;
    }

    modifier onlyWithdraw() {
        require(msg.sender == withdrawControl);
        _;
    }

    modifier requireState(States _requiredState) {
        require(state == _requiredState);
        _;
    }

    /**
    BEGIN ICO functions
    */

    //this is the main funding function, it updates the balances of tokens during the ICO.
    //no particular incentive schemes have been implemented here
    //it is only accessible during the "ICO" phase.
    function() payable
    public
    requireState(States.Ico)
    {
        require(whitelist[msg.sender] == true);

        require(block.number < endBlock);

        uint256 soldToTuserWithBonus = calcTokens(msg.value);

        issueTokensWithReferral(msg.sender, soldToTuserWithBonus);
        ethPossibleRefunds[msg.sender] = ethPossibleRefunds[msg.sender].add(msg.value);
    }

    function issueTokensToUser(address beneficiary, uint256 amount)
    internal
    {
        uint256 soldTokensAfterInvestment = soldTokens.add(amount);
        require(soldTokensAfterInvestment <= maxTotalSupply.mul(percentForSale).div(100));

        balances[beneficiary] = balances[beneficiary].add(amount);
        balances[reserves] = balances[reserves].sub(amount);
        soldTokens = soldTokensAfterInvestment;
        Transfer(reserves, beneficiary, amount);
    }

    function issueTokensWithReferral(address beneficiary, uint256 amount)
    internal
    {
        issueTokensToUser(beneficiary, amount);
        if (referral[beneficiary] != 0x0) {
            // Send 5% referral bonus to the "parent".
            issueTokensToUser(referral[beneficiary], amount.mul(5).div(100));
        }
    }

    function calcTokens(uint256 weiAmount)
    constant
    public
    returns (uint256 resultingTokens)
    {
        return weiAmount.mul(ETH_EUR).mul(100).div(get_FTVTOKEN_EURCENT(now));
    }

    function get_FTVTOKEN_EURCENT(uint timestamp)
    public constant returns (uint256 FTVTOKEN_EURCENT)
    {
        return Bonus.get_FTVTOKEN_EURCENT(timestamp, bonusData);
    }

    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }
    // ICO contract configuration function
    // new_ETH_EUR is the new rate of ETH in EUR (from which to derive tokens per ETH)
    // newEndBlock is the absolute block number at which the ICO must stop. It must be set after now.
    function updateEthICOVariables(uint256 _new_ETH_EUR, uint256 _newEndBlock)
    public
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(block.number < _newEndBlock);
        require(_new_ETH_EUR > 0);
        ETH_EUR = _new_ETH_EUR;
        endBlock = _newEndBlock;
        // check pointMultiplier
        moveToState(States.ValuationSet);
    }

    function updateETHEUR(uint256 _new_ETH_EUR)
    public
    onlyTokenAssignmentControl
    requireState(States.Ico)
    {
        require(_new_ETH_EUR > 0);
        ETH_EUR = _new_ETH_EUR;
    }

    function startICO()
    public
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.number < endBlock);
        moveToState(States.Ico);
    }

    function addPresaleAmount(address beneficiary, uint256 amount)
    public
    onlyTokenAssignmentControl
    {
        require(state == States.ValuationSet || state == States.Ico);
        issueTokensWithReferral(beneficiary, amount);
    }


    function endICO()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        finishMinting();
        moveToState(States.Operational);
    }

    function anyoneEndICO()
    public
    requireState(States.Ico)
    {
        require(block.number > endBlock);
        finishMinting();
        moveToState(States.Operational);
    }

    function finishMinting()
    internal
    {
        mintingFinished = true;
        MintFinished();
    }

    function addToWhitelist(address _whitelisted)
    public
    onlyWhitelist
        //    requireState(States.Ico)
    {
        whitelist[_whitelisted] = true;
        Whitelisted(_whitelisted);
    }


    function addReferral(address _parent, address _child)
    public
    onlyWhitelist
        //    requireState(States.Ico)
    {
        require(_parent != _child);
        require(whitelist[_parent] == true && whitelist[_child] == true);
        require(referral[_child] == 0x0);
        referral[_child] = _parent;
        Referred(_parent, _child);
    }


    //emergency pause for the ICO
    function pause()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        moveToState(States.Paused);
    }

    //in case we want to completely abort
    function abort()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Underfunded);
    }

    //un-pause
    function resumeICO()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
    }

    //in case of a failed/aborted ICO every investor can get back their money
    function requestRefund()
    public
    requireState(States.Underfunded)
    {
        require(ethPossibleRefunds[msg.sender] > 0);
        //there is no need for updateAccount(msg.sender) since the token never became active.
        uint256 payout = ethPossibleRefunds[msg.sender];
        //reverse calculate the amount to pay out
        ethPossibleRefunds[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

    //after the ico has run its course, the withdraw account can drain funds bit-by-bit as needed.
    function requestPayout(uint _amount)
    public
    onlyWithdraw //very important!
    requireState(States.Operational)
    {
        msg.sender.transfer(_amount);
    }

    //if this contract gets a balance in some other ERC20 contract - or even iself - then we can rescue it.
    function rescueToken(ERC20Basic _foreignToken, address _to)
    public
    onlyTokenAssignmentControl
    requireState(States.Operational)
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }
    /**
    END ICO functions
    */

    /**
    BEGIN ERC20 functions
    */
    function transfer(address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    public
    constant
    returns (uint256 balance) {
        return balances[_account];
    }

    /**
    END ERC20 functions
    */
}