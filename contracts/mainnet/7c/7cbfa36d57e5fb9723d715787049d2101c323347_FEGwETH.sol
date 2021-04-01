/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.7.6;     

// SPDX-License-Identifier: UNLICENSED 
/*
* Must wrap your ETH for fETH to use FEGex DEX

Built for fETH - FEG Wapped ETH - Built in 1% frictionless rewards of ETH!  Stake ETH with fETHand earn rewards!
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
    uint public constant EXIT_FEE          = BASE / 200;
    uint public constant DEFAULT_RESERVES_RATIO = 0;

    uint public constant MIN_WEIGHT        = BASE;
    uint public constant MAX_WEIGHT        = BASE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BASE * 50;
    uint public constant MIN_BALANCE       = BASE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BASE * 100;
    
    uint public  SM = 10;
    uint public  M1 = 10;
    address public FEGstake = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C;

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
        uint swapFee,
        uint reservesRatio
    )
        public pure
        returns (uint poolAmountOut, uint reserves)
    {

        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
         uint zaz = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BASE, zaz));

        reserves = calcReserves(tokenAmountIn, tokenAmountInAfterFee, reservesRatio);
        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

 
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return (poolAmountOut, reserves);
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
        uint swapFee,
        uint reservesRatio
    )
        public pure
        returns (uint poolAmountIn, uint reserves)
    {


        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        uint zar = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BASE, zar));
        reserves = calcReserves(tokenAmountOutBeforeSwapFee, tokenAmountOut, reservesRatio);

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);


        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);


        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BASE, EXIT_FEE));
        return (poolAmountIn, reserves);
    }

    function calcReserves(uint amountWithFee, uint amountWithoutFee, uint reservesRatio)
        internal pure
        returns (uint reserves)
    {
        require(amountWithFee >= amountWithoutFee, "ERR_MATH_APPROX");
        require(reservesRatio <= BASE, "ERR_INVALID_RESERVE");
        uint swapFeeAndReserves = bsub(amountWithFee, amountWithoutFee);
        reserves = bmul(swapFeeAndReserves, reservesRatio);
        require(swapFeeAndReserves >= reserves, "ERR_MATH_APPROX");
    }

    function calcReservesFromFee(uint fee, uint reservesRatio)
        internal pure
        returns (uint reserves)
    {
        require(reservesRatio <= BASE, "ERR_INVALID_RESERVE");
        reserves = bmul(fee, reservesRatio);
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
    mapping(address => mapping(address=>uint)) internal _allowance;
    uint internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

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
        require(_balance[src] >= amt);
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

    string  private _name     = "FEGwETHpair";
    string  private _symbol   = "FEGwETHLP";
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

    function transfer(address dst, uint amt) external returns (bool) {
        FEGwETH ulock;
        bool getlock = ulock.getUserLock(msg.sender);
        
        require(getlock == true, 'Liquidity is locked, you cannot removed liquidity until after lock time.');
        
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
        FEGwETH ulock;
        bool getlock = ulock.getUserLock(msg.sender);
        
        require(getlock == true, 'Transfer is Locked ');
        
        
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

contract FEGwETH is FSilver, ReentrancyGuard, FToken, FMath {

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
        uint256         tokenAmountOut,
        uint256         reservesAmount
);

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn,
        uint256         reservesAmount
);

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut,
        uint256         reservesAmount
    );

    event LOG_CLAIM_RESERVES(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LOG_ADD_RESERVES(
        address indexed token,
        uint256         reservesAmount
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


    address private _factory = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C;    // BFactory address to push token exitFee to
    address private _controller = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C; // has CONTROL role 
    address private _poolOwner;
    address public fETH = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public FEG = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public pairRewardPool = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C;
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `Launch' require CONTROL
    // `Launch` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    uint private _reservesRatio;
    bool private _launched;

    address[] private _tokens;
    mapping(address=>Record) private  _records;
    mapping(address=>userLock) public  _userlock;
    mapping(address=>uint) public totalReserves;
    mapping(address=>bool) public whiteListContract;
    
    uint private _totalWeight;

    constructor() {
        _poolOwner = msg.sender;
        _swapFee = MIN_FEE;
        _reservesRatio = DEFAULT_RESERVES_RATIO;
        _publicSwap = false;
        _launched = false;
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
    
    function setStakePool(address _addy) public {
        require(msg.sender == _controller);
    FEGstake = _addy;
    }
    
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

    function getFinalTokens()
        external view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_launched);
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external view
        _viewlock_
        returns (uint)
    {
        return _totalWeight;
    }

    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        uint denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound);
        return _records[token].balance;
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
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
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
            //locktime: block.timestamp
        });
        _tokens.push(token);
        rebind(token, balance * 98/100, denorm);
    }
    
    function AddfETHInitial(address token, uint balance, uint denorm)
        external
        _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
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
            //locktime: block.timestamp
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
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
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
            emit LOG_JOIN(msg.sender, t, tokenAmountIn, 0);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
            _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
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
            emit LOG_EXIT(msg.sender, t, tokenAmountOut, 0);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
            _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
            _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
        }

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
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

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
                                            tokenAmountIn * 99/100,
                                            _swapFee * 0
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        uint reserves = calcReservesFromFee(tokenInFee, _reservesRatio);

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

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn * 99/100, tokenAmountOut, reserves);

        totalReserves[address(tokenIn)] = badd(totalReserves[address(tokenIn)], reserves);
        emit LOG_ADD_RESERVES(address(tokenIn), reserves);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
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
        
        require(tokenIn == FEG, "Can only sell FEG");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
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
                                            tokenAmountIn * 98/100,
                                            _swapFee
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        uint reserves = calcReservesFromFee(tokenInFee, _reservesRatio);

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

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn * 98/100, tokenAmountOut, reserves);

        totalReserves[address(tokenIn)] = badd(totalReserves[address(tokenIn)], reserves);
        emit LOG_ADD_RESERVES(address(tokenIn), reserves);
        
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint256 tokAmountI  = bmul(tokenAmountOut, bdiv(25, 10000));
        //uint256 tokAmountI2 =  bmul(tokenAmountOut, bdiv(10, 10000));
        //uint256 tokAmountI1 = bsub(tokenAmountOut, badd(tokAmountI, tokAmountI2));
        uint256 tokAmountI1 = bsub(tokenAmountOut, tokAmountI);
        _pushUnderlying(tokenOut, msg.sender, tokAmountI1);
        _pushUnderlying1(tokenOut, tokAmountI);
        //_pushUnderlying2(tokenOut, tokAmountI2);
        
        _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
        return (tokenAmountOut, spotPriceAfter);
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
        external
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {
        require(tokenIn == fETH, "Can only add fETH");
        require(_launched, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_1_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        uint reserves;
        (poolAmountOut, reserves) = calcPoolOutGivenSingleIn(
                            inRecord.balance,
                            inRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountIn,
                            _swapFee,
                            _reservesRatio
                        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        //inRecord.balance = bsub(badd(inRecord.balance, reserves);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn, reserves);

        totalReserves[address(tokenIn)] = badd(totalReserves[address(tokenIn)], reserves);
        emit LOG_ADD_RESERVES(address(tokenIn), reserves);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
        return poolAmountOut;
    }

    function addLiquidityFEG(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {
        require(tokenIn == FEG, "Can only add FEG");
        require(_launched, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_1_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        uint reserves;
        (poolAmountOut, reserves) = calcPoolOutGivenSingleIn(
                            inRecord.balance,
                            inRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountIn,
                            _swapFee,
                            _reservesRatio
                        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

       // inRecord.balance = bsub(badd(inRecord.balance, tokenAmountIn * 98/100), reserves);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn, reserves);

        totalReserves[address(tokenIn)] = badd(totalReserves[address(tokenIn)], reserves);
        emit LOG_ADD_RESERVES(address(tokenIn), reserves);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    
        return poolAmountOut;
    }

    function RemoveLiquidityPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut)
    {
        require(_launched, "ERR_NOT_LAUNCHED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        
        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot removed liquidity until after lock time.");
        }

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            poolAmountIn,
                            _swapFee
                        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_1_RATIO), "ERR_MAX_OUT_RATIO");

        uint tokenAmountOutZeroFee = calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            0
        );
        uint reserves = calcReserves(
            tokenAmountOutZeroFee,
            tokenAmountOut,
            _reservesRatio
        );

        //outRecord.balance = bsub(bsub(outRecord.balance, tokenAmountOut), reserves);

        uint exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut, reserves);

        totalReserves[address(tokenOut)] = badd(totalReserves[address(tokenOut)], reserves);
        emit LOG_ADD_RESERVES(address(tokenOut), reserves);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
        return tokenAmountOut;
    }

    function RemoveLiquidityExtactAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external
        _logs_
        _lock_
        returns (uint poolAmountIn)
    {
        require(_launched, "ERR_NOT_LAUNCHED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_1_RATIO), "ERR_MAX_OUT_RATIO");

        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot removed liquidity until after lock time.");
        }
        
        
        Record storage outRecord = _records[tokenOut];

        uint reserves;
        (poolAmountIn, reserves) = calcPoolInGivenSingleOut(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountOut,
                            _swapFee,
                            _reservesRatio
                        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance = bsub(bsub(outRecord.balance, tokenAmountOut), reserves);

        uint exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut, reserves);

        totalReserves[address(tokenOut)] = badd(totalReserves[address(tokenOut)], reserves);
        emit LOG_ADD_RESERVES(address(tokenOut), reserves);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        _records[FEG].balance = IERC20(FEG).balanceOf(address(this));
        _records[fETH].balance = IERC20(fETH).balanceOf(address(this));
        return poolAmountIn;
    }

    function claimTotalReserves(address reservesAddress)
        external
        _logs_
        _lock_
    {
        require(msg.sender == _factory);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint tokenAmountOut = totalReserves[t];
            totalReserves[t] = 0;
            emit LOG_CLAIM_RESERVES(reservesAddress, t, tokenAmountOut);
            _pushUnderlying(t, reservesAddress, tokenAmountOut);
        }
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying1(address erc20, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(FEGstake, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying2(address erc20, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(pairRewardPool, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint amount)
        internal
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount)
        internal
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount)
        internal
    {
        _mint(amount);
    }

    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }

}