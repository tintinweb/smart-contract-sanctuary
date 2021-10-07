/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity 0.8.7;     
// SPDX-License-Identifier: UNLICENSED 

// FEGex  PRO  Pair  Deployer

contract FEGmath {

    function btoi(uint256 a)
        internal pure
        returns (uint256)
    {
        return a / 1e18;
    }

    function bfloor(uint256 a)
        internal pure
        returns (uint256)
    {
        return btoi(a) * 1e18;
    }

    function badd(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (1e18 / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / 1e18;
        return c2;
    }

    function bdiv(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * 1e18;
        require(a == 0 || c0 / a == 1e18, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function bpowi(uint256 a, uint256 n)
        internal pure
        returns (uint256)
    {
        uint256 z = n % 2 != 0 ? a : 1e18;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    function bpow(uint256 base, uint256 exp)
        internal pure
        returns (uint256)
    {
        require(base >= 1 wei, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= (2 * 1e18) - 1 wei, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole  = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, 1e18 / 1e10);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint256 base, uint256 exp, uint256 precision)
        internal pure
        returns (uint256)
    {
        uint256 a     = exp;
        (uint256 x, bool xneg)  = bsubSign(base, 1e18);
        uint256 term = 1e18;
        uint256 sum   = term;
        bool negative = false;


        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * 1e18;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, 1e18));
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

contract FMath is FEGmath {
    
        function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    )
        public pure
        returns (uint256 spotPrice)
    {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(10**18, bsub(10**18, swapFee));
        return  (spotPrice = bmul(ratio, scale));
    }


    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    )
        public pure
        returns (uint256 tokenAmountOut, uint256 tokenInFee)
    {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(10**18, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(1e18, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        tokenInFee = bsub(tokenAmountIn, adjustedIn);
        return (tokenAmountOut, tokenInFee);
    }

    function calcOutGivenIn1(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn
    )
        public pure
        returns (uint256 tokenAmountOut)
    {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(10**18, 0);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(1e18, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    )
        public pure
        returns (uint256 tokenAmountIn, uint256 tokenInFee)
    {
        uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint256 y = bdiv(tokenBalanceOut, diff);
        uint256 foo = bpow(y, weightRatio);
        foo = bsub(foo, 1e18);
        foo = bmul(tokenBalanceIn, foo);
        tokenAmountIn = bsub(1e18, swapFee);
        tokenAmountIn = bdiv(foo, tokenAmountIn);
        tokenInFee = bdiv(foo, 1e18);
        tokenInFee = bsub(tokenAmountIn, tokenInFee);
        return (tokenAmountIn, tokenInFee);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address whom) external view returns (uint256);
    function allowance(address src, address dst) external view returns (uint256);
    function approve(address dst, uint256 amt) external returns (bool);
    function transfer(address dst, uint256 amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint256 amt
    ) external returns (bool);
}

interface wrap {
    function deposit() external payable;
    function withdraw(uint256 amt) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface swap {
    function depositInternal(address asset, uint256 amt) external;
    function payMain(address payee, uint256 amount) external;
    function payToken(address payee, uint256 amount) external;
    function BUY(uint256 dot, address to, uint256 minAmountOut) external payable;
}

library TransferHelper {
    
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
         bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract LPTokenBase is FEGmath {

    mapping(address => uint256)                   internal _balance;
    mapping(address => mapping(address=>uint256)) internal _allowance;
    uint256 public totalSupply = 0;
    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);
    
    function _mint(uint256 amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        totalSupply = badd(totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _move(address src, address dst, uint256 amt) internal {
        require(_balance[src] >= amt);
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }
}

contract LPToken is LPTokenBase {

    string  public name     = "FEGex PRO";
    string  public symbol   = "LP Token";
    uint8   public decimals = 18;

    function allowance(address src, address dst) external view returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint256) {
        return _balance[whom];
    }

    function approve(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }
}


interface FEgexPair {
    function initialize(address, address, address, address, uint256) external; 
    function deploySwap(address, uint256) external;
    function userBalanceInternal(address _addr) external returns (uint256, uint256);
}

interface newDeployer {
    function createPair(address token, uint256 liqmain, uint256 liqtoken, address owner) external;
}

contract FEGexPRO is LPToken, FMath {
    using Address for address;
    struct Record {
        uint256 index;
        uint256 balance;
    }
    
    struct userLock {
        bool setLock; // true = lockedLiquidity, false = unlockedLiquidity
        uint256 unlockTime; // time liquidity can be released
    }
    
    function getUserLock(address usr) public view returns(bool lock){
        if(on == false){
            return false;
        }
        else{
        return (_userlock[usr].setLock);
        }
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

    event LOG_SMARTSWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         AmountIn,
        uint256         AmountOut
);

    uint256 private spec;
    address private _controller = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C; 
    address private _setter = 0x86882FA66aC57039b10D78e2D3205592A44664c0;
    address private fegp;
    address private FEG = 0xacFC95585D80Ab62f67A14C566C1b7a49Fe91167;
    uint256 private hold = IERC20(FEG).balanceOf(address(msg.sender));
    address private burn = 0x000000000000000000000000000000000000dEaD;
    address public _poolOwner;
    address public Main = 0x87b1AccE6a1958E522233A737313C086551a5c76;
    address private newDep;
    uint256 private worth = address(this).balance;
    address public Token;
    address public pairRewardPool;
    address private FEGstake;
    address public Bonus;
    uint256 public MAX_BUY_RATIO = 100e18;
    uint256 public MAX_SELL_RATIO;
    uint256 public PSS = 20; // pairRewardPool Share 0.2% default
    uint256 public RPF = 1000; // Smart Rising Price Floor Setting
    address[] private _tokens;
    uint256 public _totalSupply1;
    uint256 public _totalSupply2;
    uint256 public _totalSupply7;
    uint256 public _totalSupply8;
    uint256 public lockedLiquidity;
    uint256 public totalSentRebates;
    bool private live = false;
    bool private on = true;
    bool public open = false;
    mapping(address=>Record) private  _records;
    mapping(address=>userLock) private  _userlock;
    mapping(address=>userLock) public  _unlockTime;
    mapping(address=>bool) private whiteListContract;
    mapping(address => uint256) private _balances1;
    mapping(address => uint256) private _balances2;
    uint256 private constant MAX_RATIO  = 50; // Max ratio for all trades based on liquidity amount
    uint256 public tx1;
    uint256 public tx2 = 99;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
   
    function initialize( address _token1, address owner, address _made, address _fegp, uint256 ol) external{
        require(live == false, "Can only use once");
        Token = _token1;
        _poolOwner = owner;
        pairRewardPool = owner;
        spec = ol;
        fegp = _fegp;
        FEGstake = _made;
        MAX_SELL_RATIO = bmul(IERC20(Token).totalSupply(), bdiv(1, 20));
    }
    
    receive() external payable {
    }

    function userBalanceInternal(address _addr) public view returns(uint256, uint256) {
        uint256 main  = _balances2[_addr];
        uint256 token = _balances1[_addr];
        return (token, main);
    } 
    
    function isContract(address account) internal view returns(bool) {
        
        if(IsWhiteListContract(account)) {  return false; }
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    
    function addWhiteListContract(address _addy, bool boolean) public {
        require(msg.sender == _setter);
        whiteListContract[_addy] = boolean;
    }
    
    function IsWhiteListContract(address _addy) public view returns(bool){
        return whiteListContract[_addy];
    }
    
    modifier noContract() {
        require(isContract(msg.sender) == false, "Unapproved contracts are not allowed to interact with the swap");
        _;
    }
    
    function sync() public {  // updates the liquidity to current state
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;  
        uint256 al = (_totalSupply2 + _totalSupply7 + _totalSupply8);
        _records[Main].balance = IERC20(Main).balanceOf(address(this)) - al;
    }
    
    function setMaxBuySellRatio(uint256 sellmax, uint256 buymax) public {
        require(msg.sender == _poolOwner, "You do not have permission");
        uint256 tob = IERC20(Token).totalSupply();
        require (sellmax >= tob/1000 && sellmax <= tob, "min 0.1% of token supply, max 100% of token supply"); 
        require (buymax >= 1e18, "1 BNB minimum");
        MAX_SELL_RATIO = sellmax;
        MAX_BUY_RATIO = buymax;
    }
    
    function openit() public{ // Since only sets to true, trading can never be turned off
        require(msg.sender == _poolOwner);
        open = true;
    }
    
    function setBonus(address _bonus) public{ // For tokens that have a 3rd party token reflection
        require(msg.sender == _poolOwner && _bonus != Main  && _bonus != Token, "Not permitted");
        require(isContract(_bonus) == true);
        Bonus = _bonus;
    }
    
    function setStakePool(address _stake, address _fegp, address newd) public {
        require(msg.sender == _setter);
        FEGstake = _stake;
        fegp = _fegp;
        newDep = newd;
    }
    
    function setPRP(address prp, uint256 _tx) public {
        require(msg.sender == _setter);
        pairRewardPool = prp;
        tx1 = _tx;
    }
    
    function getBalance(address token)
        external view
        returns (uint256)
    {
        
        return _records[token].balance;
    }

    function setCont(address manager, address set, address ad)
        external
    {
        require(msg.sender == _controller);
        _controller = manager;
        _setter = set;
        _poolOwner = ad; // Incase pool owner wallet was compromised and needs new access
    }
    
    function setLockLiquidity() public { //
        address user;
        user = msg.sender;
        require(getUserLock(user) == false, "Liquidity already locked");
        uint256 total = IERC20(address(this)).balanceOf(user);
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 90 days; 
        lockedLiquidity += total;
    }
    
    function deploySwap (address _from, uint256 liqtoken)
        external
        {
        require(live == false, "Can only deploy once");
        uint256 much = IERC20(Token).balanceOf(address(this));
        uint256 much1 = IERC20(Main).balanceOf(address(this));
        _records[Token] = Record({
            index: _tokens.length,
            balance: much
        });
        
        _records[Main] = Record({
            index: _tokens.length,
            balance: much1
        });
        
        _tokens.push(Token);
        _tokens.push(Main);
        uint256 a = bdiv(_records[Token].balance, 1e9);
        uint256 b = bdiv(_records[Main].balance, 1e18);
        uint256 c = a + b;
        _mint(c);
        lockedLiquidity = badd(lockedLiquidity, c);
        _push(_from, c); 
        userLock storage ulock = _userlock[_from];
        userLock storage time = _unlockTime[_from];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 365 days; 
        live = true;
        tx1 = bmul(100, bdiv(much, liqtoken)); 
    }
   
    function getSpotPrice(address tokenIn, address tokenOut)
        public view
        returns (uint256 spotPrice)
    {
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];
        return calcSpotPrice(inRecord.balance, bmul(1e18, 25), outRecord.balance, bmul(1e18, 25), 2e15);
    }
        
    function depositInternal(address asset, uint256 amt) external {
        require(asset == Main || asset == Token, "Not supported");
        require(open == true, "Swap not opened");
        
        if(asset == Token){
        uint256 bef = _records[Token].balance;     
        _pullUnderlying(Token, msg.sender, amt);
        uint256 aft = bsub(IERC20(Token).balanceOf(address(this)), _totalSupply1);  
        uint256 finalAmount = bsub(aft, bef);  
        _totalSupply1 += finalAmount;
        _balances1[msg.sender] += finalAmount;
        }
        else{
        uint256 bef = _records[Main].balance;
        _pullUnderlying(Main, msg.sender, amt);
        uint256 aft = bsub(IERC20(Main).balanceOf(address(this)), badd(_totalSupply2, badd(_totalSupply7, _totalSupply8)));
        uint256 finalAmount = bsub(aft, bef);
        _totalSupply2  += finalAmount;
        _balances2[msg.sender] += finalAmount;
        }
    }

    function withdrawInternal(address asset, uint256 amt) external {
        require(asset == Main || asset == Token, "Not supported");
        
        if(asset == Token){
        require(_balances1[msg.sender] >= amt, "Not enough Token");
        _totalSupply1 -= amt;
        _balances1[msg.sender] -= amt;
        _pushUnderlying(Token, msg.sender, amt);
        }
        else{
        require(_balances2[msg.sender] >= amt, "Not enough Main");
        _totalSupply2 -= amt;
        _balances2[msg.sender] -= amt;
        _pushUnderlying(Main, msg.sender, amt);
        }
    }

    function swapToSwap(address path, address asset, address to, uint256 amt) external  nonReentrant {
        require(asset == Main || asset == Token, "Not supported");
        
        if(asset == Main){
        require(_balances2[msg.sender] >= amt, "Not enough Main");
        IERC20(address(Main)).approve(address(path), amt);   
        _totalSupply2 -= amt;
        _balances2[msg.sender] -= amt;
        swap(path).depositInternal(Main, amt);
        (uint256 tokens, uint256 mains) = FEgexPair(path).userBalanceInternal(address(this));
        swap(path).payMain(to, mains);
        tokens = 0;
        }
    
        else{
        require(_balances1[msg.sender] >= amt, "Not enough Token");
        IERC20(address(Token)).approve(address(path), amt);
        _totalSupply1 -= amt;
        _balances1[msg.sender] -= amt;
        swap(path).depositInternal(Token, amt);
        (uint256 tokens, uint256 mains) = FEgexPair(path).userBalanceInternal(address(this));
        swap(path).payToken(to, tokens);
        mains = 0;
        }
    }
    
    function transfer(address dst, uint256 amt) external returns(bool) {
        require(getUserLock(msg.sender) == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amt) external returns(bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
        require(getUserLock(msg.sender) == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != type(uint256).max) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
    
    function addBothLiquidity(uint256 poolAmountOut, uint[] calldata maxAmountsIn)
        external
    {
        
        uint256 poolTotal = totalSupply;
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0);
        
        if(getUserLock(msg.sender) == true){
        lockedLiquidity += poolAmountOut;    
        }
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            
            uint256 tokenAmountIn = bmul(ratio, bal); 
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            emit LOG_JOIN(msg.sender, t, tokenAmountIn, 0);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            _status = _NOT_ENTERED;
            
        }
        _mint(poolAmountOut);
        _push(msg.sender, poolAmountOut);
        sync();
    }
   
    function removeBothLiquidity(uint256 poolAmountIn, uint[] calldata minAmountsOut)
        external
    {
        
        require(getUserLock(msg.sender) == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        
        uint256 poolTotal = totalSupply;
        uint256 ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0);

        _balance[msg.sender] -= poolAmountIn;
        totalSupply -= poolAmountIn;
        emit Transfer(msg.sender, address(0), poolAmountIn);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "Minimum amount out not met");
            emit LOG_EXIT(msg.sender, t, tokenAmountOut, 0);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
            _status = _NOT_ENTERED;
        }
        
        uint256 tab = bmul(ratio, _balances2[burn]);
        _balances2[burn] -= tab;
        _balances2[msg.sender] += tab;
        sync();
        if(Bonus != address(0)){
        uint256 bal1 = bmul(ratio, IERC20(Bonus).balanceOf(address(this)));
        if(bal1 > 0){
        _pushUnderlying1(Bonus, msg.sender, bal1);
        }
        }
    }
    
    function sendRebate() internal {
        uint256 re = worth / 8;
        TransferHelper.safeTransferBNB(msg.sender, re);
        totalSentRebates += re;
    }
    
    function BUYSmart(
        uint256 tokenAmountIn,
        uint256 minAmountOut
    )  nonReentrant 
        external 
        returns(uint256 tokenAmountOut)
    {

        require(_balances2[msg.sender] >= tokenAmountIn, "Not enough Main, deposit more");
        if(worth > 0 && tokenAmountIn >= 2e17 && hold >= 2e19){
        sendRebate();
        }
        
        Record storage inRecord = _records[address(Main)];
        Record storage outRecord = _records[address(Token)];
        require(tokenAmountIn <= MAX_BUY_RATIO, "ERR_BUY_IN_RATIO");
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(tokenAmountIn, bdiv(999, 1000)),
                                            0
                                        );
        
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");                                
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");   
        _balances2[msg.sender] -= tokenAmountIn;
        _totalSupply2 -= tokenAmountIn;
        _balances1[msg.sender] += tokenAmountOut;
        _totalSupply1 += tokenAmountOut;
        _totalSupply8 += bmul(tokenAmountIn, bdiv(1, 1000));
        sync();
        emit LOG_SMARTSWAP(msg.sender, Main, Token, tokenAmountIn, tokenAmountOut);
        return(tokenAmountOut);
    }
    
    function BUY(
        uint256 dot,
        address to,
        uint256 minAmountOut
        )
        external payable
        returns(uint256 tokenAmountOut)
    {
        
        require(open == true, "Swap not opened");
        if(Address.isContract(msg.sender) == true){ 
        require(dot == spec, "Contracts are not allowed to interact with the Swap");
        }
        if(worth > 0 && msg.value >= 2e17 && hold >= 2e19){
        sendRebate();
        }
        
        wrap(Main).deposit{value: msg.value}();
        
        Record storage inRecord = _records[address(Main)];
        Record storage outRecord = _records[address(Token)];
        require(msg.value <= MAX_BUY_RATIO, "ERR_BUY_IN_RATIO");
        
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(msg.value, bdiv(999, 1000)),
                                            0
                                        );
        
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");
        uint256 oi = bmul(msg.value, bdiv(1, 1000));
        _totalSupply8 += bmul(oi, bdiv(99, 100));
        _pushUnderlying(Token, to, tokenAmountOut);
        sync();
        emit LOG_SWAP(msg.sender, Main, Token, msg.value, bmul(tokenAmountOut, bdiv(tx1, 100)));
        return(tokenAmountOut);
    }

    function SELL(
        uint256 dot,
        address to,
        uint256 tokenAmountIn,
        uint256 minAmountOut
    )   
        external
        returns(uint256 tokenAmountOut)
    {
        
        require(open == true, "Swap not opened");
        if(Address.isContract(msg.sender) == true){ 
        require(dot == spec, "Contracts are not allowed to interact with the Swap");
        }
        
        require(tokenAmountIn <= MAX_SELL_RATIO, "ERR_SELL_RATIO");
        address too = to;
        uint256 omm = _records[Token].balance;
        _pullUnderlying(Token, msg.sender, tokenAmountIn);
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            omm,
                                            bmul(1e18, 25),
                                            _records[Main].balance,
                                            bmul(1e18, 25),
                                            bmul((_records[Token].balance - omm), bdiv(998, 1000)),
                                            0
                                        );
                                        
        if(worth > 0 && tokenAmountOut <= 2e16 && hold >= 2e19){
        sendRebate();
        }
        
        require(tokenAmountOut <= bmul(_records[Main].balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");                                
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(toka, bdiv(15, 10000));
        uint256 tok = bmul(toka, bdiv(15, 10000));
        uint256 tokAmountI2 =  bmul(toka, bdiv(PSS, 10000));
        uint256 io = (toka - (tokAmountI + tok + tokAmountI2));
        uint256 tokAmountI1 = bmul(io, bdiv(999, 1000));
        uint256 ox = _balances2[address(this)];
        
        if(ox > 1e16){
        _totalSupply2 -= ox;
        _balances2[address(this)] = 0;
        }
        
        wrap(Main).withdraw(tokAmountI1 + ox + tokAmountI);
        TransferHelper.safeTransferBNB(too, bmul(tokAmountI1, bdiv(99, 100)));
        _totalSupply8 += bmul(io, bdiv(1, 1000));
        uint256 os = bmul(tokAmountI2, bdiv(90, 100));
        uint256 oss = bmul(tokAmountI2, bdiv(5, 100));
        _balances2[pairRewardPool] += os;
        _balances2[_controller] += oss;
        _balances2[burn] += oss;
        _totalSupply2 += tokAmountI2;
        _totalSupply7 += tok;
        payStake();
        burnFEG();
        sync();
        emit LOG_SWAP(msg.sender, Token, Main, bmul((_records[Token].balance - omm), bdiv(998, 1000)), bmul(tokAmountI1, bdiv(99, 100)));
        return tokAmountI1;
    }
    
     function SELLSmart(
        uint256 tokenAmountIn,
        uint256 minAmountOut
    )  nonReentrant 
        external
        returns(uint256 tokenAmountOut)
    {
        
        uint256 tai = tokenAmountIn;
        require(_balances1[msg.sender] >= tokenAmountIn, "Not enough Token");
        Record storage inRecord = _records[address(Token)];
        Record storage outRecord = _records[address(Main)];
        require(tokenAmountIn <= MAX_SELL_RATIO, "ERR_SELL_RATIO");

        tokenAmountOut = calcOutGivenIn1(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(tokenAmountIn, bdiv(998, 1000)) // 0.2% liquidity fee
                                        );
                                        
        if(worth > 0 && tokenAmountOut <= 2e16 && hold >= 2e19){
        sendRebate();
        }                                
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(toka, bdiv(15, 10000));
        uint256 tok = bmul(toka, bdiv(15, 10000));
        uint256 tokAmountI2 =  bmul(toka, bdiv(PSS, 10000));
        uint256 io = (toka - (tokAmountI + tok + tokAmountI2));
        uint256 tokAmountI1 = bmul(io, bdiv(999, 1000));
        _totalSupply8 += bmul(io, bdiv(1, 1000));
        require(tokAmountI1 >= minAmountOut, "Minimum amount out not met");
        _balances1[msg.sender] -= tokenAmountIn;
        _totalSupply1 -= tokenAmountIn;
        _balances2[msg.sender] += tokAmountI1;
        _balances2[address(this)] += tokAmountI;
        uint256 os = bmul(tokAmountI2, bdiv(90, 100));
        uint256 oss = bmul(tokAmountI2, bdiv(5, 100));
        _balances2[pairRewardPool] += os;
        _balances2[_controller] += oss;
        _balances2[burn] += oss;
        _totalSupply2 += (tokAmountI + tokAmountI2 + tokAmountI1);
        _totalSupply7 += tok;
        sync();
        burnFEG();
        emit LOG_SMARTSWAP(msg.sender, Token, Main, tai, tokAmountI1);
        return(tokAmountI1);
    }
        
    function setPSSRPF(uint256 _PSS, uint256 _RPF) external {
        
        uint256 tot = _records[Main].balance;
        require(msg.sender == _poolOwner && tot >= 20e18, "You do not have permission");
        
        if(tot < 100e18) {// Incentive for providing higher liquidity
        require(_RPF >= 990 && _RPF <= 1000 && _PSS <= 100 && _PSS != 0, "Cannot set over 1%"); 
        }
        
        if(tot >= 100e18) {// Incentive for providing higher liquidity
        require(_RPF >= 900 && _RPF <= 1000 && _PSS <= 500 && _PSS != 0, "Cannot set PSS over 5% or RPF over 10%"); 
        }
        
        RPF = _RPF;
        PSS = _PSS;
    }
    
    function releaseLiquidity() external nonReentrant{ // Allows removal of liquidity after the lock period is over
        address user = msg.sender;
        require(getUserLock(user) == true, "Liquidity not locked");
        uint256 total = IERC20(address(this)).balanceOf(user);
        lockedLiquidity -= total;
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        require (block.timestamp >= time.unlockTime, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        ulock.setLock = false; 
    }
    
    function Migrate() external nonReentrant{ //Incase we upgrade to PROv2 in the future
        require(msg.sender == _poolOwner && newDep != address(0), "Not ready");
        IERC20(Main).approve(newDep, 1e30);
        IERC20(Token).approve(newDep, 1e50);
        uint256 tot = _balance[_poolOwner];
        _balance[_poolOwner] -= tot;
        uint256 ts = totalSupply;
        uint256 amt = bmul(_records[Main].balance, bdiv(tot, ts));
        uint256 amt1 = bmul(_records[Token].balance, bdiv(tot, ts));
        totalSupply -= tot;
        on = false;
        lockedLiquidity = 0;
        newDeployer(newDep).createPair(Token, amt, amt1, _poolOwner);
        sync();
    }

    function _pullUnderlying(address erc20, address from, uint256 amount)
        internal nonReentrant
    {   
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer);
    }
    
    function _pushUnderlying(address erc20, address to, uint256 amount)
        internal nonReentrant
    {   
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer);
    }
    
    function _pushUnderlying1(address erc20, address to, uint256 amount)
        internal 
    {   
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer);
    }
    
    function burnFEG() internal {
        if(_totalSupply8 > 5e15){ 
        wrap(Main).withdraw(_totalSupply8);
        swap(fegp).BUY{value:bmul(_totalSupply8, bdiv(99, 100))}(1001, burn, 1);
        _totalSupply8 = 0;
        }
    }
    
    function payStake() internal {   
        if(_totalSupply7 > 26e14) {
        _pushUnderlying1(Main, FEGstake, _totalSupply7);
        _totalSupply7 = 0;
        }
    }
    
    function payMain(address payee, uint256 amount)
        external nonReentrant 
        
    {   
        require(_balances2[msg.sender] >= amount, "Not enough token");
        uint256 amt = bmul(amount, bdiv(997, 1000));
        _balances2[msg.sender] -= amount;
        _balances2[payee] += amt;
        _balances2[burn] += bsub(amount, amt);
    }
    
    function payToken(address payee, uint256 amount)
        external nonReentrant 
        
    {
        require(_balances1[msg.sender] >= amount, "Not enough token");
        _balances1[msg.sender] -= amount;
        _balances1[payee] += amount;
    }
}