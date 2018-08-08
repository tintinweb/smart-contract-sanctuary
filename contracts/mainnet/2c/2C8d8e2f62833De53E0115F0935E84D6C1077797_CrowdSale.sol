pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);  
        owner = newOwner;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract EyeToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct Frozen {
        bool frozen;
        uint until;
    }

    string public name = "EYE Token";
    string public symbol = "EYE";
    uint8 public decimals = 18;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => Frozen) public frozenAccounts;
    uint256 internal totalSupplyTokens;
    bool internal isICO;
    address public wallet;

    function EyeToken() public Ownable() {
        wallet = msg.sender;
        isICO = true;
        totalSupplyTokens = 10000000000 * 10 ** uint256(decimals);
        balances[wallet] = totalSupplyTokens;
    }

    /**
     * @dev Finalize ICO
     */
    function finalizeICO() public onlyOwner {
        isICO = false;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupplyTokens;
    }

    /**
     * @dev Freeze account, make transfers from this account unavailable
     * @param _account Given account
     */
    function freeze(address _account) public onlyOwner {
        freeze(_account, 0);
    }

    /**
     * @dev  Temporary freeze account, make transfers from this account unavailable for a time
     * @param _account Given account
     * @param _until Time until
     */
    function freeze(address _account, uint _until) public onlyOwner {
        if (_until == 0 || (_until != 0 && _until > now)) {
            frozenAccounts[_account] = Frozen(true, _until);
        }
    }

    /**
     * @dev Unfreeze account, make transfers from this account available
     * @param _account Given account
     */
    function unfreeze(address _account) public onlyOwner {
        if (frozenAccounts[_account].frozen) {
            delete frozenAccounts[_account];
        }
    }

    /**
     * @dev allow transfer tokens or not
     * @param _from The address to transfer from.
     */
    modifier allowTransfer(address _from) {
        require(!isICO, "ICO phase");
        if (frozenAccounts[_from].frozen) {
            require(frozenAccounts[_from].until != 0 && frozenAccounts[_from].until < now, "Frozen account");
            delete frozenAccounts[_from];
        }
        _;
    }

    /**
    * @dev transfer tokens for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result = _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value); 
        return result;
    }

    /**
    * @dev transfer tokens for a specified address in ICO mode
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferICO(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(isICO, "Not ICO phase");
        require(_to != address(0), "Zero address &#39;To&#39;");
        require(_value <= balances[wallet], "Not enought balance");
        balances[wallet] = balances[wallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(wallet, _to, _value);  
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public allowTransfer(_from) returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Not enought allowance");
        bool result = _transfer(_from, _to, _value);
        if (result) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);  
        }
        return result;
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

    /**
     * @dev transfer token for a specified address
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _transfer(address _from, address _to, uint256 _value) internal allowTransfer(_from) returns (bool) {
        require(_to != address(0), "Zero address &#39;To&#39;");
        require(_from != address(0), "Zero address &#39;From&#39;");
        require(_value <= balances[_from], "Not enought balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }
}


/**
 * @title Crowd-sale
 *
 * @dev Crowd-sale contract for tokens
 */
contract CrowdSale is Ownable {
    using SafeMath for uint256;

    event Payment(
        address wallet,
        uint date,
        uint256 amountEth,
        uint256 amountCoin,
        uint8 bonusPercent
    );

    uint constant internal MIN_TOKEN_AMOUNT = 5000;
    uint constant internal SECONDS_IN_DAY = 86400; // 24 * 60 * 60
    uint constant internal SECONDS_IN_YEAR = 31557600; // ( 365 * 24 + 6 ) * 60 * 60
    int8 constant internal PHASE_NOT_STARTED = -5;
    int8 constant internal PHASE_BEFORE_PRESALE = -4;
    int8 constant internal PHASE_BETWEEN_PRESALE_ICO = -3;
    int8 constant internal PHASE_ICO_FINISHED = -2;
    int8 constant internal PHASE_FINISHED = -1;
    int8 constant internal PHASE_PRESALE = 0;
    int8 constant internal PHASE_ICO_1 = 1;
    int8 constant internal PHASE_ICO_2 = 2;
    int8 constant internal PHASE_ICO_3 = 3;
    int8 constant internal PHASE_ICO_4 = 4;
    int8 constant internal PHASE_ICO_5 = 5;

    address internal manager;

    EyeToken internal token;
    address internal base_wallet;
    uint256 internal dec_mul;
    address internal vest_1;
    address internal vest_2;
    address internal vest_3;
    address internal vest_4;

    int8 internal phase_i; // see PHASE_XXX

    uint internal presale_start = 1533020400; // 2018-07-31 07:00 UTC
    uint internal presale_end = 1534316400; // 2018-08-15 07:00 UTC
    uint internal ico_start = 1537254000; // 2018-09-18 07:00 UTC
    uint internal ico_phase_1_days = 7;
    uint internal ico_phase_2_days = 7;
    uint internal ico_phase_3_days = 7;
    uint internal ico_phase_4_days = 7;
    uint internal ico_phase_5_days = 7;
    uint internal ico_phase_1_end;
    uint internal ico_phase_2_end;
    uint internal ico_phase_3_end;
    uint internal ico_phase_4_end;
    uint internal ico_phase_5_end;
    uint8[6] public bonus_percents = [50, 40, 30, 20, 10, 0];
    uint internal finish_date;
    uint public exchange_rate;  //  tokens in one ethereum * 1000
    uint256 public lastPayerOverflow = 0;

    /**
     * @dev Crowd-sale constructor
     */
    function CrowdSale() Ownable() public {
        phase_i = PHASE_NOT_STARTED;
        manager = address(0);
    }

    /**
     * @dev Allow only for owner or manager
     */
    modifier onlyOwnerOrManager(){
        require(msg.sender == owner || (msg.sender == manager && manager != address(0)), "Invalid owner or manager");
        _;
    }

    /**
     * @dev Returns current manager
     */
    function getManager() public view onlyOwnerOrManager returns (address) {
        return manager;
    }

    /**
     * @dev Sets new manager
     * @param _manager New manager
     */
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    /**
     * @dev Set exchange rate
     * @param _rate New exchange rate
     *
     * executed by CRM
     */
    function setRate(uint _rate) public onlyOwnerOrManager {
        require(_rate > 0, "Invalid exchange rate");
        exchange_rate = _rate;
    }

    function _addPayment(address wallet, uint256 amountEth, uint256 amountCoin, uint8 bonusPercent) internal {
        emit Payment(wallet, now, amountEth, amountCoin, bonusPercent);
    }

    /**
     * @dev Start crowd-sale
     * @param _token Coin&#39;s contract
     * @param _rate current exchange rate
     */
    function start(address _token, uint256 _rate) public onlyOwnerOrManager {
        require(_rate > 0, "Invalid exchange rate");
        require(phase_i == PHASE_NOT_STARTED, "Bad phase");

        token = EyeToken(_token);
        base_wallet = token.wallet();
        dec_mul = 10 ** uint256(token.decimals());

        // Organizasional expenses
        address org_exp = 0xeb967ECF00e86F58F6EB8019d003c48186679A96;
        // Early birds
        address ear_brd = 0x469A97b357C2056B927fF4CA097513BD927db99E;
        // Community development
        address com_dev = 0x877D6a4865478f50219a20870Bdd16E6f7aa954F;
        // Special coins
        address special = 0x5D2C58e6aCC5BcC1aaA9b54B007e0c9c3E091adE;
        // Team lock
        vest_1 = 0x47997109aE9bEd21efbBBA362957F1b20F435BF3;
        vest_2 = 0xd031B38d0520aa10450046Dc0328447C3FF59147;
        vest_3 = 0x32FcE00BfE1fEC48A45DC543224748f280a5c69E;
        vest_4 = 0x07B489712235197736E207836f3B71ffaC6b1220;

        token.transferICO(org_exp, 600000000 * dec_mul);
        token.transferICO(ear_brd, 1000000000 * dec_mul);
        token.transferICO(com_dev, 1000000000 * dec_mul);
        token.transferICO(special, 800000000 * dec_mul);
        token.transferICO(vest_1, 500000000 * dec_mul);
        token.transferICO(vest_2, 500000000 * dec_mul);
        token.transferICO(vest_3, 500000000 * dec_mul);
        token.transferICO(vest_4, 500000000 * dec_mul);

        exchange_rate = _rate;

        phase_i = PHASE_BEFORE_PRESALE;
        _updatePhaseTimes();
    }

    /**
     * @dev Finalize ICO
     */
    function _finalizeICO() internal {
        require(phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED, "Bad phase");
        phase_i = PHASE_ICO_FINISHED;
        uint curr_date = now;
        finish_date = (curr_date < ico_phase_5_end ? ico_phase_5_end : curr_date).add(SECONDS_IN_DAY * 10);
    }

    /**
     * @dev Finalize crowd-sale
     */
    function _finalize() internal {
        require(phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED, "Bad phase");

        uint date = now.add(SECONDS_IN_YEAR);
        token.freeze(vest_1, date);
        date = date.add(SECONDS_IN_YEAR);
        token.freeze(vest_2, date);
        date = date.add(SECONDS_IN_YEAR);
        token.freeze(vest_3, date);
        date = date.add(SECONDS_IN_YEAR);
        token.freeze(vest_4, date);

        token.finalizeICO();
        token.transferOwnership(base_wallet);

        phase_i = PHASE_FINISHED;
    }

    /**
     * @dev Finalize crowd-sale
     */
    function finalize() public onlyOwner {
        _finalize();
    }

    function _calcPhase() internal view returns (int8) {
        if (phase_i == PHASE_FINISHED || phase_i == PHASE_NOT_STARTED)
            return phase_i;
        uint curr_date = now;
        if (curr_date >= ico_phase_5_end || token.balanceOf(base_wallet) == 0)
            return PHASE_ICO_FINISHED;
        if (curr_date < presale_start)
            return PHASE_BEFORE_PRESALE;
        if (curr_date <= presale_end)
            return PHASE_PRESALE;
        if (curr_date < ico_start)
            return PHASE_BETWEEN_PRESALE_ICO;
        if (curr_date < ico_phase_1_end)
            return PHASE_ICO_1;
        if (curr_date < ico_phase_2_end)
            return PHASE_ICO_2;
        if (curr_date < ico_phase_3_end)
            return PHASE_ICO_3;
        if (curr_date < ico_phase_4_end)
            return PHASE_ICO_4;
        return PHASE_ICO_5;
    }

    function phase() public view returns (int8) {
        return _calcPhase();
    }

    /**
     * @dev Recalculate phase
     */
    function _updatePhase(bool check_can_sale) internal {
        uint curr_date = now;
        if (phase_i == PHASE_ICO_FINISHED) {
            if (curr_date >= finish_date)
                _finalize();
        }
        else
            if (phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED) {
                int8 new_phase = _calcPhase();
                if (new_phase == PHASE_ICO_FINISHED && phase_i != PHASE_ICO_FINISHED)
                    _finalizeICO();
                else
                    phase_i = new_phase;
            }
        if (check_can_sale)
            require(phase_i >= 0, "Bad phase");
    }

    /**
     * @dev Update phase end times
     */
    function _updatePhaseTimes() internal {
        require(phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED, "Bad phase");
        if (phase_i < PHASE_ICO_1)
            ico_phase_1_end = ico_start.add(SECONDS_IN_DAY.mul(ico_phase_1_days));
        if (phase_i < PHASE_ICO_2)
            ico_phase_2_end = ico_phase_1_end.add(SECONDS_IN_DAY.mul(ico_phase_2_days));
        if (phase_i < PHASE_ICO_3)
            ico_phase_3_end = ico_phase_2_end.add(SECONDS_IN_DAY.mul(ico_phase_3_days));
        if (phase_i < PHASE_ICO_4)
            ico_phase_4_end = ico_phase_3_end.add(SECONDS_IN_DAY.mul(ico_phase_4_days));
        if (phase_i < PHASE_ICO_5)
            ico_phase_5_end = ico_phase_4_end.add(SECONDS_IN_DAY.mul(ico_phase_5_days));
        if (phase_i != PHASE_ICO_FINISHED)
            finish_date = ico_phase_5_end.add(SECONDS_IN_DAY.mul(10));
        _updatePhase(false);
    }

    /**
     * @dev Send tokens to the specified address
     *
     * @param _to Address sent to
     * @param _amount_coin Amount of tockens
     * @return excess coins
     *
     * executed by CRM
     */
    function transferICO(address _to, uint256 _amount_coin) public onlyOwnerOrManager {
        _updatePhase(true);
        uint256 remainedCoin = token.balanceOf(base_wallet);
        require(remainedCoin >= _amount_coin, "Not enough coins");
        token.transferICO(_to, _amount_coin);
        if (remainedCoin == _amount_coin)
            _finalizeICO();
    }

    /**
     * @dev Default contract function. Buy tokens by sending ethereums
     */
    function() public payable {
        _updatePhase(true);
        address sender = msg.sender;
        uint256 amountEth = msg.value;
        uint256 remainedCoin = token.balanceOf(base_wallet);
        if (remainedCoin == 0) {
            sender.transfer(amountEth);
            _finalizeICO();
        } else {
            uint8 percent = bonus_percents[uint256(phase_i)];
            uint256 amountCoin = calcTokensFromEth(amountEth);
            assert(amountCoin >= MIN_TOKEN_AMOUNT);
            if (amountCoin > remainedCoin) {
                lastPayerOverflow = amountCoin.sub(remainedCoin);
                amountCoin = remainedCoin;
            }
            base_wallet.transfer(amountEth);
            token.transferICO(sender, amountCoin);
            _addPayment(sender, amountEth, amountCoin, percent);
            if (amountCoin == remainedCoin)
                _finalizeICO();
        }
    }

    function calcTokensFromEth(uint256 ethAmount) internal view returns (uint256) {
        uint8 percent = bonus_percents[uint256(phase_i)];
        uint256 bonusRate = uint256(percent).add(100);
        uint256 totalCoins = ethAmount.mul(exchange_rate).div(1000);
        uint256 totalFullCoins = (totalCoins.add(dec_mul.div(2))).div(dec_mul);
        uint256 tokensWithBonusX100 = bonusRate.mul(totalFullCoins);
        uint256 fullCoins = (tokensWithBonusX100.add(50)).div(100);
        return fullCoins.mul(dec_mul);
    }

    /**
     * @dev Freeze the account
     * @param _accounts Given accounts
     *
     * executed by CRM
     */
    function freeze(address[] _accounts) public onlyOwnerOrManager {
        require(phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED, "Bad phase");
        uint i;
        for (i = 0; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "Zero address");
            require(_accounts[i] != base_wallet, "Freeze self");
        }
        for (i = 0; i < _accounts.length; i++) {
            token.freeze(_accounts[i]);
        }
    }

    /**
     * @dev Unfreeze the account
     * @param _accounts Given accounts
     */
    function unfreeze(address[] _accounts) public onlyOwnerOrManager {
        require(phase_i != PHASE_NOT_STARTED && phase_i != PHASE_FINISHED, "Bad phase");
        uint i;
        for (i = 0; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "Zero address");
            require(_accounts[i] != base_wallet, "Freeze self");
        }
        for (i = 0; i < _accounts.length; i++) {
            token.unfreeze(_accounts[i]);
        }
    }

    /**
     * @dev get ICO times
     * @return presale_start, presale_end, ico_start, ico_phase_1_end, ico_phase_2_end, ico_phase_3_end, ico_phase_4_end, ico_phase_5_end
     */
    function getTimes() public view returns (uint, uint, uint, uint, uint, uint, uint, uint) {
        return (presale_start, presale_end, ico_start, ico_phase_1_end, ico_phase_2_end, ico_phase_3_end, ico_phase_4_end, ico_phase_5_end);
    }

    /**
     * @dev Sets start and end dates for pre-sale phase_i
     * @param _presale_start Pre-sale sart date
     * @param _presale_end Pre-sale end date
     */
    function setPresaleDates(uint _presale_start, uint _presale_end) public onlyOwnerOrManager {
        _updatePhase(false);
        require(phase_i == PHASE_BEFORE_PRESALE, "Bad phase");
        // require(_presale_start >= now);
        require(_presale_start < _presale_end, "Invalid presale dates");
        require(_presale_end < ico_start, "Invalid dates");
        presale_start = _presale_start;
        presale_end = _presale_end;
    }

    /**
     * @dev Sets start date for ICO phases
     * @param _ico_start ICO start date
     * @param _ico_1_days Days of ICO phase 1
     * @param _ico_2_days Days of ICO phase 2
     * @param _ico_3_days Days of ICO phase 3
     * @param _ico_4_days Days of ICO phase 4
     * @param _ico_5_days Days of ICO phase 5
     */
    function setICODates(uint _ico_start, uint _ico_1_days, uint _ico_2_days, uint _ico_3_days, uint _ico_4_days, uint _ico_5_days) public onlyOwnerOrManager {
        _updatePhase(false);
        require(phase_i != PHASE_FINISHED && phase_i != PHASE_ICO_FINISHED && phase_i < PHASE_ICO_1, "Bad phase");
        require(presale_end < _ico_start, "Invalid dates");
        ico_start = _ico_start;
        ico_phase_1_days = _ico_1_days;
        ico_phase_2_days = _ico_2_days;
        ico_phase_3_days = _ico_3_days;
        ico_phase_4_days = _ico_4_days;
        ico_phase_5_days = _ico_5_days;
        _updatePhaseTimes();
    }
}