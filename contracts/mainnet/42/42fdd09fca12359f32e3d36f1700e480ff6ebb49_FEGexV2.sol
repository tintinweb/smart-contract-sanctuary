/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity 0.7.6;     

// SPDX-License-Identifier: UNLICENSED 


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
    uint public constant MAX_BOUND_TOKENS  = 2;

    uint public constant MIN_FEE           = 2000000000000000; 
    uint public constant MAX_FEE           = 2000000000000000; // FREE BUYS and sells pay 0.2% to liquidity providers
    uint public constant EXIT_FEE          = BASE / 100;
    uint public constant DEFAULT_RESERVES_RATIO = 0;

    uint public constant MIN_WEIGHT        = BASE;
    uint public constant MAX_WEIGHT        = BASE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BASE * 50;
    uint public constant MIN_BALANCE       = BASE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BASE * 100;
    
    uint public  SM = 10;
    address public FEGstake = 0x04788562Ab11eA3a5201d579e2b3Ee7A3F74F1fA;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BASE) - 1 wei;
    uint public constant BPOW_PRECISION    = BASE / 10**10;

    uint public constant MAX_IN_RATIO      = BASE / 2;
    uint public constant MAX_OUT_RATIO     = (BASE / 3) + 1 wei;
    uint public MAX_SELL_RATIO             = BASE / SM;
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

interface wrap {
    function deposit() external payable;
    function withdraw(uint amt) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
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

    string  private _name     = "FEGexV2";
    string  private _symbol   = "$INUfETH";
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
        FEGexV2 ulock;
        bool getlock = ulock.getUserLock(msg.sender);
        
        require(getlock == true, 'Liquidity is locked, you cannot remove liquidity until after lock time.');
        
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
        FEGexV2 ulock;
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

contract FEGexV2 is FSilver, ReentrancyGuard, FToken, FMath {

    struct Record {
        bool bound;   // is token bound to pool
        uint denorm;  // denormalized weight will always be even
        uint index;
        uint balance;
    }
    
    struct userLock {
        bool setLock; // true = locked, false = unlocked
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

    wrap wrapp;
    address private _factory = 0x1Eb421973d639C3422904c65Cccc2972b37a17e8;    
    address private _controller = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C; 
    address private _poolOwner = 0x28A782553C4B3f78991B41Cb47Ab4D78716Ef738;
    address public Wrap = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public Token = 0x00F29171D7bCDC464a0758cF3217fE83173772b9;
    address public pairRewardPool = 0x28A782553C4B3f78991B41Cb47Ab4D78716Ef738;
    address public burn = 0x000000000000000000000000000000000000dEaD;
    uint public FSS = 25; // FEGstake Share
    uint public PSS = 100; // pairRewardPool Share 
    uint public RPF = 990; //Smart Rising Price Floor Setting
    uint public SHR = 995; //p2p fee Token
    uint public SHR1 = 997; //p2p fee Wrap
    uint private _swapFee;
    address[] private _tokens;
    uint256 public _totalSupply1;
    uint256 public _totalSupply2;
    bool public live = false;
    mapping(address=>Record) private  _records;
    mapping(address=>userLock) public  _userlock;
    mapping(address=>userLock) public  _unlockTime;
    mapping(address=>bool) public whiteListContract;
    mapping(address => uint256) private _balances1;
    mapping(address => uint256) private _balances2;
    
    uint private _totalWeight;

    constructor() {
        wrapp = wrap(Wrap);
        _poolOwner = msg.sender;
        //pairRewardPool = msg.sender;
        _swapFee = MIN_FEE;
    }
    
    receive() external payable {
    }

    function userBalanceInternal(address _addr) public view returns (uint256 token, uint256 fwrap) {
        return (_balances1[_addr], _balances2[_addr]);
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
    
    function setStakePool(address _addy) public {
        require(msg.sender == _controller);
    FEGstake = _addy;
    }
    
    function setPairRewardPool(address _addy) public {
        require(msg.sender == _controller);
    pairRewardPool = _addy;
    }
    
    function setupWrap() public {
        IERC20(address(this)).approve(address(Wrap), 100000000000000000e18);        
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
        
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
    {

        require(_records[token].bound);
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
        return _totalWeight;
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
        
    {
        require(msg.sender == _controller);
        _controller = manager;
    }
    
    function setPoolOwner(address manager)
        external
        
    {
        require(msg.sender == _controller);
        _poolOwner = manager;
    }

    function deploySwap (uint256 amtoftoken, uint256 amtofwrap)
        external
        {
        require(msg.sender == _poolOwner);
        require(live == false);
        address tokenIn = Token;
        address tokenIn1 = Wrap;
        
        _records[Token] = Record({
            bound: true,
            denorm: BASE * 25,
            index: _tokens.length,
            balance: (amtoftoken * 99/100)
            
        });
        
        _records[Wrap] = Record({
            bound: true,
            denorm: BASE * 25,
            index: _tokens.length,
            balance: (amtofwrap * 99/100)
        });
        live = true;
        _tokens.push(Token);
        _tokens.push(Wrap);
        _pullUnderlying(tokenIn, msg.sender, amtoftoken);
        _pullUnderlying(tokenIn1, msg.sender, amtofwrap);
        _mint(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY); 
        address user = msg.sender;
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 365 days ; 
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
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];
        return calcSpotPrice(inRecord.balance, BASE * 25, outRecord.balance, BASE * 25, _swapFee);}
        

    function depositToken(uint256 amt)  external noContract nonReentrant {
        address tokenIn = Token;
        _pullUnderlying(tokenIn, msg.sender, amt);
        
       
        uint256 finalAmount = amt * 99/100;
        _totalSupply1 = _totalSupply1 + finalAmount;
        _balances1[msg.sender] = _balances1[msg.sender] + finalAmount;
    }
    
    function depositWrap(uint256 amt)  external noContract nonReentrant {
        address tokenIn = Wrap;
        _pullUnderlying(tokenIn, msg.sender, amt);
        
       
        uint256 finalAmount = amt * 99/100;
        _totalSupply2  = _totalSupply2 + finalAmount;
        _balances2[msg.sender] = _balances2[msg.sender] + finalAmount;
    }
    
    function withdrawToken(uint256 amt) external noContract nonReentrant {
        address tokenIn = Token;
        require(_balances1[msg.sender] >= amt, "Not enough token");
        
        _totalSupply1 = _totalSupply1 - amt;
        _balances1[msg.sender] = _balances1[msg.sender] - amt;
        
        _pushUnderlying(tokenIn, msg.sender, amt);
        
    }
    
    function withdrawWrap(uint256 amt) external noContract nonReentrant{
        address tokenIn = Wrap;
        require(_balances2[msg.sender] >= amt, "Not enough Wrap");
        
        _totalSupply2 = _totalSupply2 - amt;
        _balances2[msg.sender] = _balances2[msg.sender] - amt;
        
        _pushUnderlying(tokenIn, msg.sender, amt);
    }

    function addBothLiquidity(uint poolAmountOut, uint[] calldata maxAmountsIn)
    noContract nonReentrant
        external
        _logs_
        _lock_
    {
        

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            emit LOG_JOIN(msg.sender, t, tokenAmountIn * 99/100, 0);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
            _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        
    }
   
    function removeBothLiquidity(uint poolAmountIn, uint[] calldata minAmountsOut)
    noContract nonReentrant
        external
        _logs_
        _lock_
    {
        
        userLock storage ulock = _userlock[msg.sender];
        
        if(ulock.setLock == true) {
            require(ulock.unlockTime <= block.timestamp, "Liquidity is locked, you cannot remove liquidity until after lock time.");
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
            _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
            _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
        }

    }


    function BUYSmart(
        uint tokenAmountIn,
        uint minAmountOut
    ) noContract nonReentrant
        external 
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        address tokenIn = Wrap;
        address tokenOut = Token;
        require(_balances2[msg.sender] >= tokenAmountIn, "Not enough Wrap, deposit more");
        
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");
        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance ,
                                    BASE * 25,
                                    outRecord.balance,
                                    BASE * 25,
                                    _swapFee * 0
                                );
                                
        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            tokenAmountIn * 99/100,
                                            _swapFee * 0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");                     
        _balances2[msg.sender] = _balances2[msg.sender] - tokenAmountIn;
        _balances1[msg.sender] = _balances1[msg.sender] + tokenAmountOut;
        _totalSupply2 = _totalSupply2 - tokenAmountIn;
        _totalSupply1 = _totalSupply1 + tokenAmountOut;
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
        _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
        
        spotPriceAfter = calcSpotPrice(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            _swapFee * 0
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        return (tokenAmountOut, spotPriceAfter);
    }
    
    function BUY(
        address to,
        uint minAmountOut
    ) noContract nonReentrant
        external payable
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        address tokenIn = Wrap;
        address tokenOut = Token;
        
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(msg.value <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance ,
                                    BASE * 25,
                                    outRecord.balance,
                                    BASE * 25,
                                    _swapFee * 0
                                );

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            msg.value * 99/100,
                                            _swapFee * 0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(spotPriceBefore <= bdiv(msg.value * 99/100, tokenAmountOut), "ERR_MATH_APPROX");
        wrap(Wrap).deposit{value: msg.value}();
        _pushUnderlying(tokenOut, to, tokenAmountOut);
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
        _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
        
        spotPriceAfter = calcSpotPrice(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            _swapFee * 0
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        
        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, msg.value * 99/100, tokenAmountOut * 99/100);
        return (tokenAmountOut, spotPriceAfter);
    }

    function SELL(
    address to,
        uint tokenAmountIn,
        uint minAmountOut
    ) noContract nonReentrant 
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        address tokenIn = Token;
        address tokenOut = Wrap;
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_SELL_RATIO), "ERR_SELL_RATIO");
                                               
        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            tokenAmountIn * 99/100,
                                            _swapFee
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        
        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn * 99/100, tokenAmountOut * 99/100);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(tokenAmountOut, bdiv(FSS, 10000));
        uint256 tokAmountI2 =  bmul(tokenAmountOut, bdiv(PSS, 10000));
        uint256 tokAmountI1 = bsub(toka, badd(tokAmountI, tokAmountI2));
        uint256 out1 = tokAmountI1;
        wrap(Wrap).withdraw(out1); 
        TransferHelper.safeTransferETH(to, (out1 * 99/100)); 
        _pushUnderlying1(tokenOut, tokAmountI);
        _balances2[pairRewardPool] = _balances2[pairRewardPool] + tokAmountI2;
        _totalSupply2 = _totalSupply2 + tokAmountI2;
        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    BASE * 25,
                                    outRecord.balance,
                                    BASE * 25,
                                    _swapFee
                                );
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");                        
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
        _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
        
        spotPriceAfter = calcSpotPrice(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        
        
        return (tokenAmountOut, spotPriceAfter);
    }
    
     function SELLSmart(
        uint tokenAmountIn,
        uint minAmountOut
    ) noContract nonReentrant
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        
        address tokenIn = Token;
        address tokenOut = Wrap;
        
        require(_balances1[msg.sender] >= tokenAmountIn, "Not enough Token");
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_SELL_RATIO), "ERR_SELL_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    BASE * 25,
                                    outRecord.balance,
                                    BASE * 25,
                                    _swapFee
                                );

        uint tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            tokenAmountIn * 99/100,
                                            _swapFee
                                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(tokenAmountOut, bdiv(FSS, 10000));
        uint256 tokAmountI2 =  bmul(tokenAmountOut, bdiv(PSS, 10000));
        uint256 tokAmountI1 = bsub(toka, badd(tokAmountI, tokAmountI2));
        uint256 tok2 = badd(tokAmountI1, tokAmountI2);
        _balances1[msg.sender] = _balances1[msg.sender] - tokenAmountIn;
        _balances2[msg.sender] = _balances2[msg.sender] + tokAmountI1;
        _totalSupply2 = _totalSupply2 + tok2;
        _totalSupply1 = _totalSupply1 - tokenAmountIn;
        _pushUnderlying1(tokenOut, tokAmountI);
        _balances2[pairRewardPool] = _balances2[pairRewardPool] + tokAmountI2;
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
        _records[Wrap].balance = IERC20(Wrap).balanceOf(address(this)) - _totalSupply2;
                          
        spotPriceAfter = calcSpotPrice(
                                            inRecord.balance,
                                            BASE * 25,
                                            outRecord.balance,
                                            BASE * 25,
                                            _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        
        return (tokenAmountOut, spotPriceAfter);
    }
    
    function setFSS(uint _FSS ) external {
        require(msg.sender == _controller);
        require(_FSS <= 100, " Cannot set over 1%");
        require(_FSS > 0, " Cannot set to 0");
        FSS = _FSS;
    }
    
    function setPSS(uint _PSS ) external {
        require(msg.sender == _poolOwner);
         require(_PSS <= 100, " Cannot set over 1%"); 
         require(_PSS > 0, " Cannot set to 0");
        PSS = _PSS;
    }

    function setRPF(uint _RPF ) external {
        require(msg.sender == _poolOwner);
         require(_RPF >= 800, " Cannot set over 20%"); 
         require(_RPF > 0, " Cannot set to 0");
        RPF = _RPF;
    }
    
    function setSHR(uint _SHR, uint _SHR1 ) external {
        require(msg.sender == _controller);
         require(_SHR <= 100 && _SHR1 <=100, " Cannot set over 10%"); 
         require(_SHR > 0 && _SHR1 > 0, " Cannot set to 0"); 
        SHR = _SHR;
        SHR1 = _SHR1;
    }
    
    function setLockLiquidity() external { //
        address user = msg.sender;
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 365 days ; 
        }
    
    function releaseLiquidity() external { // Allows removal of liquidity after the lock period is over
        address user = msg.sender;
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        require (block.timestamp >= time.unlockTime, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        ulock.setLock = false; 
    }
    
    function emergencyLockOverride(address user, bool _bool, uint _time) external {
        require(msg.sender == _controller);
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        ulock.setLock = _bool;
        time.unlockTime = _time;
    }

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {   
        //require(amount > 0, "Cannot deposit nothing");
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {   
        //require(amount > 0, "Cannot withdraw nothing");
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function _pushUnderlying1(address erc20, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(FEGstake, amount);
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

    function PayWrap(address payee, uint amount)
        external noContract nonReentrant 
        
    {   
        require(_balances2[msg.sender] >= amount, "Not enough token");
        uint256 amt = amount * SHR1/1000;
        uint256 amt1 = amount - amt;
        _balances2[msg.sender] = _balances2[msg.sender] - amount;
        _balances2[payee] = _balances2[payee] + amt;
        _balances2[_factory] = _balances2[_factory] + amt1;
    }
    
    function PayToken(address payee, uint amount)
        external noContract nonReentrant 
        
    {
        require(_balances1[msg.sender] >= amount, "Not enough token");
        uint256 amt = amount * SHR/1000;
        uint256 amt1 = amount - amt;
        _balances1[msg.sender] = _balances1[msg.sender] - amount;
        _balances1[payee] = _balances1[payee] + amt;
        _pushUnderlying(Token, pairRewardPool, amt1);
        _totalSupply1 = _totalSupply1 - amt1;
    }
}