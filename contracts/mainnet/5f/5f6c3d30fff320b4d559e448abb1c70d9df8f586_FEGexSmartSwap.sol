/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-14
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.3;     


/*
* Must wrap your BNB for fETH to use FEGex DEX

Built for fETH - FEG Wapped BNB - Built in 1% frictionless rewards of BNB!  Stake BNB with fETH and earn rewards!
*/


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface stakeContract {
    function DisributeTxFunds() external;
    function ADDFUNDS(uint256 tokens) external;
}

contract FSilver  {
     function getColor()
        external pure
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}


contract FConst is FSilver, ReentrancyGuard {
    uint public constant BASE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_FEE           = 2000000000000000; 
    uint public constant MAX_FEE           = 2000000000000000; // FREE BUYS
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BASE;
    uint public constant MAX_WEIGHT        = BASE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BASE * 50;
    uint public constant MIN_BALANCE       = BASE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BASE * 100;
    
    uint public  SM = 10;
    uint public  M1 = 10;
    address public FEGstake = 0x04788562Ab11eA3a5201d579e2b3Ee7A3F74F1fA;
    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BASE) - 1 wei;
    uint public constant BPOW_PRECISION    = BASE / 10**10;

    uint public constant MAX_IN_RATIO      = BASE / 2;
    uint public constant MAX_OUT_RATIO     = (BASE / 3) + 1 wei;
    uint public MAX_SELL_RATIO             = BASE / SM;
    uint public MAX_1_RATIO             = BASE / M1;
}


contract FNum is ReentrancyGuard, FConst {

    function btoi(uint a)
        internal pure
        returns (uint)
    {
        return a / BASE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BASE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BASE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BASE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BASE;
        require(a == 0 || c0 / a == BASE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BASE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BASE);
        uint term = BASE;
        uint sum   = term;
        bool negative = false;


        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BASE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BASE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

contract FMath is FSilver, FConst, FNum {
    
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    )
        public pure
        returns (uint spotPrice)
    {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BASE, bsub(BASE, swapFee));
        return  (spotPrice = bmul(ratio, scale));
    }
    
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut, uint tokenInFee)
    {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BASE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BASE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        tokenInFee = bsub(tokenAmountIn, adjustedIn);
        return (tokenAmountOut, tokenInFee);
    }


    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountIn, uint tokenInFee)
    {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BASE);
        foo = bmul(tokenBalanceIn, foo);
        tokenAmountIn = bsub(BASE, swapFee);
        tokenAmountIn = bdiv(foo, tokenAmountIn);
        tokenInFee = bdiv(foo, BASE);
        tokenInFee = bsub(tokenAmountIn, tokenInFee);
        return (tokenAmountIn, tokenInFee);
    }


    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint poolAmountOut)
    {

        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
         uint zaz = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BASE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

 
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return (poolAmountOut);
    }

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);

        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BASE, EXIT_FEE));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);


        uint tokenOutRatio = bpow(poolRatio, bdiv(BASE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);
        uint zaz = bmul(bsub(BASE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BASE, zaz));
        return tokenAmountOut;
    }


    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint poolAmountIn)
    {


        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        uint zar = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BASE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);


        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);


        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BASE, EXIT_FEE));
        return (poolAmountIn);
    }
}
// Highly opinionated token implementation

interface IERC20 {

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

contract FTokenBase is ReentrancyGuard, FNum {

    mapping(address => uint)                   internal _balance;
    mapping(address => uint)                   internal _balance1;
    mapping(address => uint)                   internal _balance2;
    mapping(address => mapping(address=>uint)) internal _allowance;
    uint internal _totalSupply;
    

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);
    //event DepositFEG(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt);
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "error: Low Balance");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract FToken is ReentrancyGuard, FTokenBase {

    string  private _name     = " TRYfETH";
    string  private _symbol   = "fETHTRYeLP";
    uint8   private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }
}

contract FEGexSmartSwap is FSilver, ReentrancyGuard, FToken, FMath {

    struct Record {
        bool bound;   // is token bound to pool
        uint index;   // private
        uint denorm;  // denormalized weight
        uint balance;
    }
    
    struct userLock {
        bool setLock; // true = locked, false=unlocked
        uint unlockTime;
    }
    
    function getUserLock(address usr) public view returns(bool lock){
        return _userlock[usr].setLock;
    }
    
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
);

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
);

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex);
        _mutex = true;
        _;
        _mutex = false;
    } 

    modifier _viewlock_() {
        require(!_mutex);
        _;
    }

    bool private _mutex;


    address private _factory = 0xf6A12645453990bC2Fe2f39C5B662e16B7f1f430;    // BFactory address to push token exitFee to
    address private _controller =0x3B30Bac3c331168e40FC6338BA2295A2F3adDe52; // has CONTROL role 
    address private _poolOwner = 0x76EFf89CDe6ff68103E76dD492e8b25a058fcB2B;
    address public fETH = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public TRY = 0xc12eCeE46ed65D970EE5C899FCC7AE133AfF9b03;
    address public pairRewardPool = 0x88aD06b773350c113093E5F9852e1FC57424A301;
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    uint private _swapFee;
    bool private _launched;
    uint public FSS = 25;
    uint public PSS = 500; // TRY has a 5% Sell Fee

    address[] private _tokens;
    uint256 public _totalSupply1;
    uint256 public _totalSupply2;
    mapping(address=>Record) private  _records;
    mapping(address=>userLock) public  _userlock;
    mapping(address=>bool) public whiteListContract;
    mapping(address => uint256) private _balances1;
    mapping(address => uint256) private _balances2;
    
    uint private _totalWeight;

    constructor() {
        _poolOwner = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _launched = false;
        
    }
    
    function userBalanceOfTRY(address account) public view returns (uint256) {
        return _balances1[account]; 
    }
    
    function userBalanceOffETH(address account) public view returns (uint256) {
        return _balances2[account]; 
    }
    
    function transfer(address dst, uint amt) external returns (bool) {
        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot removed liquidity until after lock time.");
        }
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot removed liquidity until after lock time.");
        }
        
        _move(src, dst, amt);
        
        if (msg.sender != src && _allowance[src][msg.sender] > 0) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
       return true;
    }
    
    function isContract(address account) internal view returns (bool) {
        
        if(IsWhiteListContract(account)) {  return false; }
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    
    function addWhiteListContract(address _addy, bool boolean) public {
        require(msg.sender == _controller);
        require(_addy != address(0), "setting 0 address;;");
        
        whiteListContract[_addy] = boolean;
    }
    
    function IsWhiteListContract(address _addy) public view returns(bool){
        require(_addy != address(0), "setting 0 address;;");
        
        return whiteListContract[_addy];
    }
    
    modifier noContract() {
        require(isContract(msg.sender) == false, 'Unapproved contracts are not allowed to interact with the swap');
        _;
    }
    
    function setMaxSellRatio(uint256 _amount) public {
        require(msg.sender == _poolOwner, "You do not have permission");
        require (_amount > 0, "cannot turn off");
        require (_amount <= 100, "cannot set under 1%");
        SM = _amount;
    }
    
    function setMax1SideLiquidityRatio(uint256 _amount) public {
        require(msg.sender == _poolOwner, "You do not have permission");
        require (_amount > 10, "cannot set over 10%");
        require (_amount <= 200, "cannot set under 0.5%");
        M1 = _amount;
    }
    
    /*function setStakePool(address _addy) public {
        require(msg.sender == _controller);
    TRYstake = _addy;
    }*/
    
    function setPairRewardPool(address _addy) public {
        require(msg.sender == _controller);
    pairRewardPool = _addy;
    }
    
    function isPublicSwap()
        external view
        returns (bool)
    {
        return _publicSwap;
        
    }    
    
    function isBound(address t)
        external view
        returns (bool)
    {
        return _records[t].bound;
    }

    /*function getFinalTokens()
        external view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_launched);
        return _tokens;
    }*/

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].denorm;
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].balance;
    }
    
    function getTotalBalanceTRY(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].balance + _totalSupply1;
    }
    
    function getTotalBalancefETH(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].balance + _totalSupply2;
    }

    function getSwapFee()
        external view
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }

    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    function setController(address manager)
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller);
        _controller = manager;
    }


    function Launch()
        external
        _logs_
        _lock_
    {
        require(msg.sender == _poolOwner);
        require(!_launched);
        require(_tokens.length >= MIN_BOUND_TOKENS);

        _launched = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }


    function AddTokenInitial(address token, uint balance, uint denorm)
        external
        _logs_
    {
        require(msg.sender == _poolOwner);
        require(!_records[token].bound);
        require(!_launched);

        require(_tokens.length < MAX_BOUND_TOKENS);

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,    // balance and denorm will be validated
            balance: 0  // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance * 98/100, denorm);
    }
    
    function AddfETHInitial(address token, uint balance, uint denorm)
        external
        _logs_
    {
        require(token == fETH);
        require(msg.sender == _poolOwner);
        require(!_records[token].bound);
        require(!_launched);

        require(_tokens.length < MAX_BOUND_TOKENS);

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,    // balance and denorm will be validated
            balance: 0  // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance * 99/100, denorm);
    }

    function rebind(address token, uint balance, uint denorm)
        public
        _logs_
        _lock_
    {

        require(msg.sender == _poolOwner);
        require(_records[token].bound);
        require(!_launched);

        require(denorm >= MIN_WEIGHT);
        require(denorm <= MAX_WEIGHT);
        require(balance >= MIN_BALANCE);

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT);
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE if enabled
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            uint tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            _pushUnderlying(token, _factory, tokenExitFee);
        }
    }
   
    function saveLostTokens(address token, uint amount)
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller);
        require(!_records[token].bound);

        uint bal = IERC20(token).balanceOf(address(this));
        require(amount <= bal);

        _pushUnderlying(token, msg.sender, amount);
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function addBothLiquidity(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        _logs_
        _lock_
    {
        require(_launched, "ERR_NOT_LAUNCHED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
            _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        
    }
   
    function removeBothLiquidity(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        _logs_
        _lock_
    {
        require(_launched, "ERR_NOT_LAUNCHED");
        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot removed liquidity until after lock time.");
        }

        uint poolTotal = totalSupply();
        uint exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
        _burnPoolShare(pAiAfterExitFee);
        
        
        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
            _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
            _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        }

    }

    function DepositTRY(address tokenIn, uint256 amount) external  {
        //require(amount > 0, "Cannot deposit nothing");
        require(tokenIn == TRY, "Only TRY allowed"); 
        uint256 _txfee = amount * 98/100;
        _pullUnderlying(tokenIn, msg.sender, amount);
        
       
        uint256 finalAmount = amount - _txfee;
        _totalSupply1 = _totalSupply1 + finalAmount;
        _balances1[msg.sender] = _balances1[msg.sender] + finalAmount;
        
       // emit Transfer(tokenIn, msg.sender, finalAmount);
    }
    
    function DepositfETH(address tokenIn, uint256 amount) external  {
        require(tokenIn == fETH, "Only fETH allowed"); 
        //uint256 _txfee = 99/100;
        _pullUnderlying(tokenIn, msg.sender, amount);
        
       
        uint256 finalAmount = amount * 99/100;
        _totalSupply2 = _totalSupply2 + finalAmount;
        _balances2[msg.sender] = _balances2[msg.sender] + finalAmount;
        
       // emit Transfer(tokenIn, msg.sender, finalAmount);
    }
    
    function WithdrawTRY(address tokenIn, uint256 amount) external  {
        //require(amount > 0, "Cannot deposit nothing");
        require(_balances1[msg.sender] >= amount, "Not enough TRY");
        require(tokenIn == TRY, "Only TRY allowed");
        
        _totalSupply1 = _totalSupply1 - amount;
        _balances1[msg.sender] = _balances1[msg.sender] - amount;
        
        _pushUnderlying(tokenIn, msg.sender, amount);
        //emit Transfer(tokenIn, msg.sender, amount);
        
        
    }
    
    function WithdrawfETH(address tokenIn, uint256 amount) external  {
        require(tokenIn == fETH, "Only fETH allowed"); 
        require(_balances2[msg.sender] >= amount, "Not enough fETH");
        
        _totalSupply2 = _totalSupply2 - amount;
        _balances2[msg.sender] = _balances2[msg.sender] - amount;
        
        _pushUnderlying(tokenIn, msg.sender, amount);
        //emit Transfer(tokenIn, msg.sender, amount);
       
        
    }

    function BUYSmart(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) noContract
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        require(tokenIn == fETH, "Can only buy with fETH");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");
        require(_balances2[msg.sender] >= tokenAmountIn, "Not enough fETH, deposit more");
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee * 0
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            inRecord.denorm,
                                            outRecord.balance,
                                            outRecord.denorm,
                                            tokenAmountIn,
                                            _swapFee * 0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee * 0
                            );
                            
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

         _balances2[msg.sender] = _balances2[msg.sender] - tokenAmountIn;
        _balances1[msg.sender] = _balances1[msg.sender] + tokenAmountOut;
        _totalSupply2 = _totalSupply2 - tokenAmountIn;
        _totalSupply1 = _totalSupply1 + tokenAmountOut;
        _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        return (tokenAmountOut, spotPriceAfter);
    }
    
    function BUY(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) noContract
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        require(tokenIn == fETH, "Can only buy with fETH");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee * 0
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            inRecord.denorm,
                                            outRecord.balance,
                                            outRecord.denorm,
                                            tokenAmountIn * 99/100,
                                            _swapFee * 0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
                            
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn * 99/100, tokenAmountOut * 98/100);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        return (tokenAmountOut, spotPriceAfter);
    }

    function SELL(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) noContract
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        require(tokenIn == TRY, "Can only sell TRY");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_SELL_RATIO), "ERR_SELL_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            inRecord.denorm,
                                            outRecord.balance,
                                            outRecord.denorm,
                                            tokenAmountIn,
                                            _swapFee
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn * 98/100, tokenAmountOut * 99/100);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint256 tokAmountI  = bmul(tokenAmountOut, bdiv(FSS, 10000));
        uint256 tokAmountI2 =  bmul(tokenAmountOut, bdiv(PSS, 10000));
        uint256 tokAmountI1 = bsub(tokenAmountOut, badd(tokAmountI, tokAmountI2));
        
        _pushUnderlying(tokenOut, msg.sender, tokAmountI1);
        _pushUnderlying1(tokenOut, tokAmountI);
        _pushUnderlying2(tokenOut, tokAmountI2);
        
        _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        return (tokenAmountOut, spotPriceAfter);
    }
    
     function SELLSmart(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) noContract
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        require(tokenIn == TRY, "Can only sell TRY");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");
        require(_balances1[msg.sender] >= tokenAmountIn, "Not enough TRY");
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_SELL_RATIO), "ERR_SELL_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            inRecord.denorm,
                                            outRecord.balance,
                                            outRecord.denorm,
                                            tokenAmountIn,
                                            _swapFee
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        uint256 tokAmountI  = bmul(tokenAmountOut, bdiv(FSS, 10000));
        uint256 tokAmountI2 =  bmul(tokenAmountOut, bdiv(PSS, 10000));
        uint256 tokAmountI1 = bsub(tokenAmountOut, badd(tokAmountI, tokAmountI2));
        _balances1[msg.sender] = _balances1[msg.sender] - tokenAmountIn;
        
        _balances2[msg.sender] = _balances2[msg.sender] + tokAmountI1;
        _totalSupply2 = _totalSupply2 + tokAmountI1;
        _totalSupply1 = _totalSupply1 - tokenAmountIn;
        
        _pushUnderlying1(tokenOut, tokAmountI);
        _pushUnderlying2(tokenOut, tokAmountI2);
        
        _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        
        return (tokenAmountOut, spotPriceAfter);
    }
    
    function setFSS(uint _FSS ) external {
        require(msg.sender == _controller);
        FSS = _FSS;
    }
    
    function setPSS(uint _PSS ) external {
        require(msg.sender == _controller);
        PSS = _PSS;
    }

    function setLockLiquidity() external {
        address user = msg.sender;
        userLock storage ulock = _userlock[user];
        
        ulock.setLock = true;
        ulock.unlockTime = block.timestamp + 90 days ; 
    }
    
    function emergencyLockOverride(address user, bool _bool) external {
        require(msg.sender == _controller);
        //address user = msg.sender;
        userLock storage ulock = _userlock[user];
        ulock.setLock = _bool;
    }
    
    function addLiquidityfETH(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external noContract
        _logs_
        _lock_
        returns (uint poolAmountOut)
        
    {
        require(tokenIn == fETH, "Can only add fETH");
        require(_launched, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_1_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
        
        inRecord.balance = bsub(inRecord.balance, tokenAmountIn * 99/100);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _records[TRY].balance = IERC20(TRY).balanceOf(address(this)) - _totalSupply1;
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this)) - _totalSupply2;
        return poolAmountOut;
    }

    function addLiquidityTRY(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {
        require(tokenIn == TRY, "Can only add TRY");
        require(_launched, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_1_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = bsub(inRecord.balance, tokenAmountIn * 98/100);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    
        return poolAmountOut;
    }

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
        nonReentrant
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying(address erc20, address to, uint amount)
        internal
        nonReentrant
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying1(address erc20, uint amount)
        internal
        nonReentrant
    {
        bool xfer = IERC20(erc20).transfer(FEGstake, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying2(address erc20, uint amount)
        internal
        nonReentrant
    {
        bool xfer = IERC20(erc20).transfer(pairRewardPool, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint amount)
        internal
        nonReentrant
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount)
        internal
        nonReentrant
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount)
        internal
        nonReentrant
    {
        _mint(amount);
    }

    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }
}