pragma solidity ^0.4.11;
contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract SafeMath {
    
    /*
    standard uint256 functions
     */
    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }
    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }
    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
    /*
    uint128 functions (h is for half)
     */
    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }
    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }
    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }
    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }
    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }
    /*
    int256 functions
     */
    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }
    /*
    WAD math
     */
    uint128 constant WAD = 10 ** 18;
    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }
    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }
    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }
    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }
    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }
    /*
    RAY math
     */
    uint128 constant RAY = 10 ** 27;
    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }
    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }
    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }
    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }
    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].
        z = n % 2 != 0 ? x : RAY;
        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);
            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }
    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
}
contract Owned {
    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }
    address public owner;
    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }
    address public newOwner;
    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}
contract StandardToken is ERC20Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value!=0) && (allowed[msg.sender][_spender] !=0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract ATMToken is StandardToken, Owned {
    // metadata
    string public constant name = "Attention Token of Media";
    string public constant symbol = "ATM";
    string public version = "1.0";
    uint256 public constant decimals = 8;
    bool public disabled;
    mapping(address => bool) public isATMHolder;
    address[] public ATMHolders;
    // constructor
    function ATMToken(uint256 _amount) {
        totalSupply = _amount; //设置当前ATM发行总量
        balances[msg.sender] = _amount;
    }
    function getATMTotalSupply() external constant returns(uint256) {
        return totalSupply;
    }
    function getATMHoldersNumber() external constant returns(uint256) {
        return ATMHolders.length;
    }
    //在数据迁移时,需要先停止ATM交易
    function setDisabled(bool flag) external onlyOwner {
        disabled = flag;
    }
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        if(isATMHolder[_to] == false){
            isATMHolder[_to] = true;
            ATMHolders.push(_to);
        }
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        if(isATMHolder[_to] == false){
            isATMHolder[_to] = true;
            ATMHolders.push(_to);
        }
        return super.transferFrom(_from, _to, _value);
    }
    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}
contract Contribution is SafeMath, Owned {
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_END_DAY = 7;
    uint256 public dayCycle = 24 hours;
    uint256 public fundingStartTime = 0;
    address public ethFundDeposit = 0;
    address public investorDeposit = 0;
    bool public isFinalize = false;
    bool public isPause = false;
    mapping (uint => uint) public dailyTotals; //total eth per day
    mapping (uint => mapping (address => uint)) public userBuys; // otal eth per day per user
    uint256 public totalContributedETH = 0; //total eth of 7 days
    // events
    event LogBuy (uint window, address user, uint amount);
    event LogCreate (address ethFundDeposit, address investorDeposit, uint fundingStartTime, uint dayCycle);
    event LogFinalize (uint finalizeTime);
    event LogPause (uint finalizeTime, bool pause);
    function Contribution (address _ethFundDeposit, address _investorDeposit, uint256 _fundingStartTime, uint256 _dayCycle)  {
        require( now < _fundingStartTime );
        require( _ethFundDeposit != address(0) );
        fundingStartTime = _fundingStartTime;
        dayCycle = _dayCycle;
        ethFundDeposit = _ethFundDeposit;
        investorDeposit = _investorDeposit;
        LogCreate(_ethFundDeposit, _investorDeposit, _fundingStartTime,_dayCycle);
    }
    //crawdsale entry
    function () payable {  
        require(!isPause);
        require(!isFinalize);
        require( msg.value >= MIN_FUND ); //eth >= 0.01 at least
        ethFundDeposit.transfer(msg.value);
        buy(today(), msg.sender, msg.value);
    }
    function importExchangeSale(uint256 day, address _exchangeAddr, uint _amount) onlyOwner {
        buy(day, _exchangeAddr, _amount);
    }
    function buy(uint256 day, address _addr, uint256 _amount) internal {
        require( day >= CRAWDSALE_START_DAY && day <= CRAWDSALE_END_DAY ); 
        //record user&#39;s buy amount
        userBuys[day][_addr] += _amount;
        dailyTotals[day] += _amount;
        totalContributedETH += _amount;
        LogBuy(day, _addr, _amount);
    }
    function kill() onlyOwner {
        selfdestruct(owner);
    }
    function pause(bool _isPause) onlyOwner {
        isPause = _isPause;
        LogPause(now,_isPause);
    }
    function finalize() onlyOwner {
        isFinalize = true;
        LogFinalize(now);
    }
    function today() constant returns (uint) {
        return sub(now, fundingStartTime) / dayCycle + 1;
    }
}
contract ATMint is SafeMath, Owned {
    ATMToken public atmToken; //ATM contract address
    Contribution public contribution; //crawdSale contract address
    uint128 public fundingStartTime = 0;
    uint256 public lockStartTime = 0;
    
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_EARLYBIRD_END_DAY = 3;
    uint256 public constant CRAWDSALE_END_DAY = 7;
    uint256 public constant THAW_CYCLE_USER = 6/*6*/;
    uint256 public constant THAW_CYCLE_FUNDER = 6/*60*/;
    uint256 public constant THAW_CYCLE_LENGTH = 30;
    uint256 public constant decimals = 8; //ATM token decimals
    uint256 public constant MILLION = (10**6 * 10**decimals);
    uint256 public constant tokenTotal = 10000 * MILLION;  // 100 billion
    uint256 public constant tokenToFounder = 800 * MILLION;  // 8 billion
    uint256 public constant tokenToReserve = 5000 * MILLION;  // 50 billion
    uint256 public constant tokenToContributor = 4000 * MILLION; // 40 billion
    uint256[] public tokenToReward = [0, (120 * MILLION), (50 * MILLION), (30 * MILLION), 0, 0, 0, 0]; // 1.2 billion, 0.5 billion, 0.3 billion
    bool doOnce = false;
    
    mapping (address => bool) public collected;
    mapping (address => uint) public contributedToken;
    mapping (address => uint) public unClaimedToken;
    // events
    event LogRegister (address contributionAddr, address ATMTokenAddr);
    event LogCollect (address user, uint spendETHAmount, uint getATMAmount);
    event LogMigrate (address user, uint balance);
    event LogClaim (address user, uint claimNumberNow, uint unclaimedTotal, uint totalContributed);
    event LogClaimReward (address user, uint claimNumber);
    /*
    ************************
    deploy ATM and start Freeze cycle
    ************************
    */
    function initialize (address _contribution) onlyOwner {
        require( _contribution != address(0) );
        contribution = Contribution(_contribution);
        atmToken = new ATMToken(tokenTotal);
        //Start thawing process
        setLockStartTime(now);
        // alloc reserve token to fund account (50 billion)
        lockToken(contribution.ethFundDeposit(), tokenToReserve);
        lockToken(contribution.investorDeposit(), tokenToFounder);
        //help founder&fund to claim first 1/6 ATMs
        claimUserToken(contribution.investorDeposit());
        claimFoundationToken();
        
        LogRegister(_contribution, atmToken);
    }
    /*
    ************************
    calc ATM by eth per user
    ************************
    */
    function collect(address _user) {
        require(!collected[_user]);
        
        uint128 dailyContributedETH = 0;
        uint128 userContributedETH = 0;
        uint128 userTotalContributedETH = 0;
        uint128 reward = 0;
        uint128 rate = 0;
        uint128 totalATMToken = 0;
        uint128 rewardRate = 0;
        collected[_user] = true;
        for (uint day = CRAWDSALE_START_DAY; day <= CRAWDSALE_END_DAY; day++) {
            dailyContributedETH = cast( contribution.dailyTotals(day) );
            userContributedETH = cast( contribution.userBuys(day,_user) );
            if (dailyContributedETH > 0 && userContributedETH > 0) {
                //Calculate user rewards
                rewardRate = wdiv(cast(tokenToReward[day]), dailyContributedETH);
                reward += wmul(userContributedETH, rewardRate);
                //Cumulative user purchase total
                userTotalContributedETH += userContributedETH;
            }
        }
        rate = wdiv(cast(tokenToContributor), cast(contribution.totalContributedETH()));
        totalATMToken = wmul(rate, userTotalContributedETH);
        totalATMToken += reward;
        //Freeze all ATMs purchased
        lockToken(_user, totalATMToken);
        //help user to claim first 1/6 ATMs
        claimUserToken(_user);
        LogCollect(_user, userTotalContributedETH, totalATMToken);
    }
    function lockToken(
        address _user,
        uint256 _amount
    ) internal {
        require(_user != address(0));
        contributedToken[_user] += _amount;
        unClaimedToken[_user] += _amount;
    }
    function setLockStartTime(uint256 _time) internal {
        lockStartTime = _time;
    }
    function cast(uint256 _x) constant internal returns (uint128 z) {
        require((z = uint128(_x)) == _x);
    }
    /*
    ************************
    Claim ATM
    ************************
    */
    function claimReward(address _founder) onlyOwner {
        require(_founder != address(0));
        require(lockStartTime != 0);
        require(doOnce == false);
        uint256 rewards = 0;
        for (uint day = CRAWDSALE_START_DAY; day <= CRAWDSALE_EARLYBIRD_END_DAY; day++) {
            if(contribution.dailyTotals(day) == 0){
                rewards += tokenToReward[day];
            }
        }
        atmToken.transfer(_founder, rewards);
        doOnce = true;
        LogClaimReward(_founder, rewards);
    }
    
    function claimFoundationToken() {
        require(msg.sender == owner || msg.sender == contribution.ethFundDeposit());
        claimToken(contribution.ethFundDeposit(),THAW_CYCLE_FUNDER);
    }
    function claimUserToken(address _user) {
        claimToken(_user,THAW_CYCLE_USER);
    }
    function claimToken(address _user, uint256 _stages) internal {
        if (unClaimedToken[_user] == 0) {
            return;
        }
        uint256 currentStage = sub(now, lockStartTime) / (60*60 /*contribution.dayCycle() * THAW_CYCLE_LENGTH*/) +1;
        if (currentStage == 0) {
            return;
        } else if (currentStage > _stages) {
            currentStage = _stages;
        }
        uint256 lockStages = _stages - currentStage;
        uint256 unClaimed = (contributedToken[_user] * lockStages) / _stages;
        if (unClaimedToken[_user] <= unClaimed) {
            return;
        }
        uint256 tmp = unClaimedToken[_user] - unClaimed;
        unClaimedToken[_user] = unClaimed;
        atmToken.transfer(_user, tmp);
        LogClaim(_user, tmp, unClaimed,contributedToken[_user]);
    }
    /*
    ************************
    migrate user data and suiside
    ************************
    */
    function disableATMExchange() onlyOwner {
        atmToken.setDisabled(true);
    }
    function enableATMExchange() onlyOwner {
        atmToken.setDisabled(false);
    }
    function migrateUserData() onlyOwner {
        for (var i=0; i< atmToken.getATMHoldersNumber(); i++){
            LogMigrate(atmToken.ATMHolders(i), atmToken.balances(atmToken.ATMHolders(i)));
        }
    }
    function kill() onlyOwner {
        atmToken.kill();
        selfdestruct(owner);
    }
}