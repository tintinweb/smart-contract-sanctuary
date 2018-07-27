pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
        return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

library SafeERC20 {

    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

library Roles {

    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address addr) internal {
        role.bearer[addr] = true;
    }

    function remove(Role storage role, address addr) internal {
        role.bearer[addr] = false;
    }

    function check(Role storage role, address addr) view internal {
        require(has(role, addr));
    }

    function has(Role storage role, address addr) view internal returns (bool) {
        return role.bearer[addr];
    }
}

contract ERC20Basic {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;
    mapping(address => uint) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender)
    public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint)) internal allowed;

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

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {

    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() canMint public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract Crowdsale {

    using SafeMath for uint256;
    using SafeERC20 for MintableToken;
    MintableToken public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _rate, address _wallet, MintableToken _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _updatePurchasingState(_beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

contract CappedCrowdsale is Crowdsale {

    using SafeMath for uint256;
    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }
}

contract Escrow is Ownable {

    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    mapping(address => uint) private deposits;

    function depositsOf(address _payee) public view returns (uint256) {
        return deposits[_payee];
    }

    function deposit(address _payee) public onlyOwner payable {
        uint256 amount = msg.value;
        deposits[_payee] = deposits[_payee].add(amount);
        emit Deposited(_payee, amount);
    }

    function withdraw(address _payee) public onlyOwner {
        uint256 payment = deposits[_payee];
        assert(address(this).balance >= payment);
        deposits[_payee] = 0;
        _payee.transfer(payment);
        emit Withdrawn(_payee, payment);
    }
}

contract ConditionalEscrow is Escrow {

    function withdrawalAllowed(address _payee) public view returns (bool);

    function withdraw(address _payee) public {
        require(withdrawalAllowed(_payee));
        super.withdraw(_payee);
    }
}

contract RefundEscrow is Ownable, ConditionalEscrow {

    enum State { Active, Refunding, Closed }
    event Closed();
    event RefundsEnabled();
    State public state;
    address public beneficiary;

    constructor(address _beneficiary) public {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
        state = State.Active;
    }

    function deposit(address _refundee) public payable {
        require(state == State.Active);
        super.deposit(_refundee);
    }

    function close() public onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
    }

    function enableRefunds() public onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function beneficiaryWithdraw() public {
        require(state == State.Closed);
        beneficiary.transfer(address(this).balance);
    }

    function withdrawalAllowed(address _payee) public view returns (bool) {
        return state == State.Refunding;
    }
}

contract TimedCrowdsale is Crowdsale {

    using SafeMath for uint256;
    uint256 public launchTime;
    uint256 public completionTime;

    modifier onlyWhileOpen {
        require(block.timestamp >= launchTime && block.timestamp <= completionTime);
        _;
    }

    constructor(uint256 _launchTime, uint256 _completionTime) public {
        require(_launchTime >= block.timestamp);
        require(_completionTime >= _launchTime);
        launchTime = _launchTime;
        completionTime = _completionTime;
    }

    function Completed() public view returns (bool) {
        return block.timestamp > completionTime;
    }

    function Launched() public constant returns (bool) {
        return block.timestamp >= launchTime && block.timestamp <= completionTime;
    }

    function timeLeft() public view returns (uint256 TimeLeft) {
        return TimeLeft = SafeMath.sub(completionTime,block.timestamp);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

contract FinalizableCrowdsale is TimedCrowdsale, CappedCrowdsale, Ownable {

    using SafeMath for uint256;
    bool public isFinalized = false;
    event Finalized();

    function finalize() internal {
        require(!isFinalized);
        require(Completed());
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function finalizeCapReached() internal {
        require(!isFinalized);
        require(capReached());
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function finalization() internal {
    }
}

contract RefundableCrowdsale is FinalizableCrowdsale {

    using SafeMath for uint256;
    uint256 public goal;
    RefundEscrow private escrow;

    constructor(uint256 _goal) public {
        require(_goal > 0);
        escrow = new RefundEscrow(wallet);
        goal = _goal;
    }

    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        escrow.withdraw(msg.sender);
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    function finalization() internal {
        if (goalReached()) {
        escrow.close();
        escrow.beneficiaryWithdraw();
        } else {
        escrow.enableRefunds();
        }
        super.finalization();
    }

    function _forwardFunds() internal {
        escrow.deposit.value(msg.value)(msg.sender);
    }
}

contract FreezableToken is StandardToken {

    mapping (bytes32 => uint64) internal chains;
    mapping (bytes32 => uint) internal freezings;
    mapping (address => uint) internal freezingBalance;
    event Freeze(address indexed to, uint64 release, uint256 amount);
    event Released(address indexed owner, uint256 amount);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

    function numbOfFrozenAmCount(address _addr) public view returns (uint256 count) {
        uint64 release = chains[dbVal(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[dbVal(_addr, release)];
        }
    }

    function getFrozenAmData(address _addr, uint256 _index) public view returns (uint64 _releaseEpochStamp, uint256 _frozenBalance) {
        for (uint256 i = 0; i < _index + 1; i++) {
            _releaseEpochStamp = chains[dbVal(_addr, _releaseEpochStamp)];
            if (_releaseEpochStamp == 0) {
                return;
            }
        }
        _frozenBalance = freezings[dbVal(_addr, _releaseEpochStamp)];
    }

    function sendAndFreeze(address _to, uint256 _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        bytes32 actVal = dbVal(_to, _until);
        freezings[actVal] = freezings[actVal].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);
        freeze(_to, _until);
        emit Transfer(msg.sender, _to, _amount);
        emit Freeze(_to, _until, _amount);
    }

    function releaseSingleAm() public {
        bytes32 genVal = dbVal(msg.sender, 0);
        uint64 gen = chains[genVal];
        require(gen != 0);
        require(uint64(block.timestamp) > gen);
        bytes32 actVal = dbVal(msg.sender, gen);
        uint64 next = chains[actVal];
        uint256 amount = freezings[actVal];
        delete freezings[actVal];
        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);
        if (next == 0) {
            delete chains[genVal];
        } else {
            chains[genVal] = next;
            delete chains[actVal];
        }
        emit Released(msg.sender, amount);
    }

    function releaseAllatOnce() public returns (uint256 tokens) {
        uint256 release;
        uint256 balance;
        (release, balance) = getFrozenAmData(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseSingleAm();
            tokens += balance;
            (release, balance) = getFrozenAmData(msg.sender, 0);
        }
    }

    function dbVal(address _addr, uint256 _releaseEpochStamp) internal pure returns (bytes32 datebin) {
        datebin = 0x0103200900100000080120180100000101001110010010010100010101011000;
        assembly {
            datebin := or(datebin, mul(_addr, 0x10000000000000000))
            datebin := or(datebin, _releaseEpochStamp)
        }
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = dbVal(_to, _until);
        bytes32 parentKey = dbVal(_to, uint64(0));
        uint64 next = chains[parentKey];
        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }
        bytes32 nextKey = dbVal(_to, next);
        uint256 parent;
        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;
            next = chains[nextKey];
            nextKey = dbVal(_to, next);
        }
        if (_until == next) {
            return;
        }
        if (next != 0) {
            chains[key] = next;
        }
        chains[parentKey] = _until;
    }
}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract FreezableMintableToken is FreezableToken, MintableToken {

    function mintAndFreeze(address _to, uint256 _amount, uint64 _until) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        bytes32 actVal = dbVal(_to, _until);
        freezings[actVal] = freezings[actVal].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);
        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freeze(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}

contract ConstantValues {
    
    uint8 public constant decimals = 18;
    uint256 constant decimal_multiplier = 10 ** uint(decimals);
    string public constant name = &quot;AEXmock&quot;;
    string public constant symbol = &quot;AEXm&quot;;
}

contract AEXmockTest is ConstantValues, FreezableMintableToken, BurnableToken, Pausable {

    function token_name() public pure returns (string _tokenName) {
        return name;
    }

    function token_symbol() public pure returns (string _tokenSymbol) {
        return symbol;
    }

    function token_decimals() public pure returns (uint256 _tokenDecimals) {
        return decimals;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    }
}

contract RBAC is Ownable {

    using Roles for Roles.Role;
    mapping (string => Roles.Role) private roles;
    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    function checkRole(address _operator, string _role) view public {
        roles[_role].check(_operator);
    }

    function hasRole(address _operator, string _role) view public returns (bool) {
        return roles[_role].has(_operator);
    }

    function roleAdd(address _operator, string _role) public onlyOwner {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    function roleRemove(address _operator, string _role) public onlyOwner {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

    modifier onlyRole(string _role) {
        checkRole(msg.sender, _role);
        _;
    }
}

contract Whitelist is RBAC {

    string constant ROLE_WHITELISTED = &quot;whitelist&quot;;

    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    function addAddressToWhitelist(address _operator) public {
        roleAdd(_operator, ROLE_WHITELISTED);
    }

    function whitelist(address _operator) public view returns (bool) {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    function addAddressesToWhitelist(address[] _operators) public {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    function removeAddressFromWhitelist(address _operator) public {
        roleRemove(_operator, ROLE_WHITELISTED);
    }

    function removeAddressesFromWhitelist(address[] _operators) public {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }
}

contract Contactable is Ownable{

    string public contactInformation;

    function setContactInfo(string info) public onlyOwner {
        contactInformation = info;
    }
}

contract BonusScale is Crowdsale {

                    // Example rates increased in order to make the difference more visible and easier to count manually, if anyone of members prefer this way.

    using SafeMath for uint256;

    function getAmountBonusRate() internal constant returns (uint256) {
        uint256 amountBonus;
        
        if (msg.value >= 500 finney && msg.value < 1 ether) {
            return rate.div(1000).mul(200);
        } else
        if (msg.value >= 1 ether && msg.value < 2 ether) {
            return rate.div(1000).mul(300);
        } else
        if (msg.value >= 2 ether && msg.value < 3 ether) {
            return rate.div(1000).mul(400);
        } else
        if (msg.value >= 3 ether) {
            return rate.div(1000).mul(500);
        }
        return amountBonus;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentRate = rate.add(getAmountBonusRate());
        return currentRate.mul(_weiAmount);
    }
}

contract Checkable is Ownable{

    address private serviceAccount;
    bool private triggered = false;

    event Triggered(uint256 balance);
    event Checked(bool isAccident);

    constructor() public {
        serviceAccount = msg.sender;
    }

    function changeServiceAccount(address _account) public onlyOwner {
        assert(_account != 0);
        serviceAccount = _account;
    }

    function isServiceAccount() view public returns (bool) {
        return msg.sender == serviceAccount;
    }

    function checkStatus() onlyService notTriggered payable public {
        if (internalCheck()) {
            emit Triggered(address(this).balance);
            triggered = true;
            internalAction();
        }
    }

    function internalCheck() internal returns (bool);

    function internalAction() internal;

    modifier onlyService {
        require(msg.sender == serviceAccount);
        _;
    }

    modifier notTriggered() {
        require(!triggered);
        _;
    }
}

contract AEXmockPre is ConstantValues, RefundableCrowdsale, Whitelist, Contactable, BonusScale, Checkable, Pausable {

    using SafeMath for uint256;
    bool constant suspended = true;

    event Activated();
    event TimesMachine(uint256 launchTime, uint256 completionTime, uint256 oldLaunchTime, uint256 oldCompletionTime);
    bool public activated = false;
    uint256 public minEscrow;
    uint256 public maxEscrow;

    constructor(MintableToken _token, uint256 _minEscrow, uint256 _maxEscrow, string _contactInformation) public
        Crowdsale(5000, 0x5Df3752Af8d01a8A8A6edc106a7902C013A69feb, _token)
        CappedCrowdsale(15600000000000000000)
        TimedCrowdsale(block.timestamp.add(300), block.timestamp.add(3600))
        RefundableCrowdsale(10000000000000000000) {
            require(goal <= cap);
            require(_maxEscrow > 0);
            require(_minEscrow > 0);
            minEscrow = _minEscrow;
            maxEscrow = _maxEscrow;
            contactInformation = _contactInformation;
        }

    function Activate() public onlyOwner {
        require(!activated);
        activated = true;
        if (suspended) {
            AEXmockTest(token).pause();
        }
        emit Activated();
    }

    function setMinEscrow(uint256 _min) public onlyOwner {
        require(_min > 0);
        minEscrow = _min;
    }

    function setMaxEscrow(uint256 _max) public onlyOwner {
        require(_max > 0);
        maxEscrow = _max;
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(MintableToken(token).mint(_beneficiary, _tokenAmount));
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) onlyIfWhitelisted(_beneficiary) whenNotPaused internal {
        require(_weiAmount >= minEscrow);
        require(_weiAmount <= maxEscrow);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function setCompletionTime(uint256 _completionTime) public onlyOwner {
        require(block.timestamp < completionTime);
        require(block.timestamp < _completionTime);
        require(_completionTime > launchTime);
        emit TimesMachine(launchTime, _completionTime, launchTime, completionTime);
        completionTime = _completionTime;
    }

    function finalization() internal {
        super.finalization();
        if (suspended) {
            AEXmockTest(token).unpause();
        }
        token.transferOwnership(owner);
    }

    function internalCheck() internal returns (bool) {
        bool result = !isFinalized && (Completed() || capReached());
        emit Checked(result);
        return result;
    }

    function internalAction() internal {
        finalization();
        emit Finalized();
        isFinalized = true;
    }
}