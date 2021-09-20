/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity 0.8.7;     
// SPDX-License-Identifier: UNLICENSED 

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

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt);
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        totalSupply = bsub(totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
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

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract LPToken is LPTokenBase {

    string  public name     = "FEXex PRO";
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
    function deploySwap (address, uint256, uint256) external;
    function userBalanceInternal(address _addr) external returns (uint256, uint256);
}

contract FEGexPRO is LPToken, FMath {
    using Address for address;
    struct Record {
        uint256 index;
        uint256 balance;
    }
    
    struct userLock {
        bool setLock; // true = lockedLiquidity, false = unlockedLiquidity
        uint256 unlockTime;
    }
    
    function getUserLock(address usr) public view returns(bool lock){
        return (_userlock[usr].setLock);
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

    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    uint256 private spec;
    address private _controller = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C; 
    address private _setter = 0x86882FA66aC57039b10D78e2D3205592A44664c0;
    address private FEG = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public _poolOwner = 0x4c9BC793716e8dC05d1F48D8cA8f84318Ec3043C;
    address public Main = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public Token = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public pairRewardPool = 0x94D4Ac11689C6EbbA91cDC1430fc7dfa9a858753;
    address public FEGstake = 0x0f8bAA9bf4e0Ebaa9111F07F8125DF66166A1D9E;
    address public Bonus;
    uint256 public MAX_BUY_RATIO;
    uint256 public MAX_SELL_RATIO;
    uint256 public PSS = 20; // pairRewardPool Share 0.2% default
    uint256 public RPF = 1000; // Smart Rising Price Floor Setting
    address[] private _tokens;
    uint256 public _totalSupply1 = 0;
    uint256 public _totalSupply2 = 0;
    uint256 public _totalSupply7 = 0;
    uint256 public _totalSupply8 = 0;
    uint256 public totalSentRebates = 0;
    uint256 public lockedLiquidity = 0;
    bool public live = false;
    bool public open = false;
    mapping(address=>Record) private  _records;
    mapping(address=>userLock) private  _userlock;
    mapping(address=>userLock) public  _unlockTime;
    mapping(address=>bool) private whiteListContract;
    mapping(address => uint256) private _balances1;
    mapping(address => uint256) private _balances2;
    uint256 public constant MAX_RATIO  = 50; // Max ratio for all trades based on liquidity amount
    uint256 public tx1;
    uint256 public tx2;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;
    event rebate(address indexed user, uint256 amount);

    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    
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
        require(msg.sender == _setter, "You do not have permission");
        whiteListContract[_addy] = boolean;
    }
    
    function IsWhiteListContract(address _addy) public view returns(bool){
        return whiteListContract[_addy];
    }
    
    modifier noContract() {
        require(isContract(msg.sender) == false, "Unapproved contracts are not allowed to interact with the swap");
        _;
    }
    
    function setMaxBuySellRatio(uint256 sellmax, uint256 buymax) public {
        require(msg.sender == _poolOwner, "You do not have permission");
        uint256 tib = _records[Token].balance;
        uint256 tob = _records[Main].balance;
        require (sellmax >= 1e23 && sellmax <= tib, "min 10 T FEG, max 100% of liquidity"); 
        require (buymax >= 100e18 && buymax <= tob, "min 100 ETH, max 100% of liquidity");
        MAX_SELL_RATIO = sellmax;
        MAX_BUY_RATIO = buymax;
    }
    
    function openit() public{ // Since only sets to true, trading can never be turned off
        require(msg.sender == _poolOwner);
        open = true;
    }
    
    function setBonus(address _bonus) public{ // For tokens that have a 3rd party token reflection
        require(msg.sender == _poolOwner && _bonus != Main  && _bonus != Token, "Not permitted");
        Bonus = _bonus;
    }
    
    function setStakePool(address _stake) public {
        require(msg.sender == _setter && _stake != address(0), "You do not have permission");
        FEGstake = _stake;
    }
    
    function setPairRewardPool(address _addy) public { // Gives ability to move rewards to future staking protocols 
        require(msg.sender == _setter, "You do not have permission");
        pairRewardPool = _addy;
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
        require(msg.sender == _controller, "You do not have permission");
        require(manager != address(0) && set != address(0), "Cannot set 0 address");
        _controller = manager;
        _setter = set;
        _poolOwner = ad; // Incase pool owner wallet was compromised and needs new access
    }
    
    function setLockLiquidity() nonReentrant public { //
        address user;
        user = msg.sender;
        bool loc = getUserLock(user);
        require(loc == false, "Liquidity already locked");
        uint256 total = IERC20(address(this)).balanceOf(user);
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 90 days; 
        lockedLiquidity += total;
    }
    
    function deploySwap (uint256 liqmain, uint256 liqtoken, uint256 ol)
        external
        {
        require(live == false, "Can only use once");
        require(msg.sender == _poolOwner, "No permissions");
        address _from = msg.sender;
        spec = ol;
        _pullUnderlying(Main, msg.sender, liqmain);
        _pullUnderlying(Token, msg.sender, liqtoken);
        MAX_SELL_RATIO = 5000000000000e9;
        MAX_BUY_RATIO = 300e18;
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
        _mint(badd(a, b));
        lockedLiquidity = badd(lockedLiquidity, badd(a, b));
        _push(_from, badd(a, b)); 
        userLock storage ulock = _userlock[_from];
        userLock storage time = _unlockTime[_from];
        ulock.setLock = true;
        time.unlockTime = block.timestamp + 365 days; 
        live = true;
        PSS = 30;
        tx1 = bmul(100, bdiv(much, liqtoken)); 
        tx2 = bmul(100, bdiv(much1, liqmain)); 
    }
   
    function getSpotPrice(address tokenIn, address tokenOut)
        public view
        returns (uint256 spotPrice)
    {
        
        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];
        return calcSpotPrice(inRecord.balance, bmul(1e18, 25), outRecord.balance, bmul(1e18, 25), 2e15);
        
    }
        
    function depositInternal(address asset, uint256 amt)  external nonReentrant {
        require(asset == Main || asset == Token);
        require(open == true, "Swap not opened");
        
        if(asset == Token){
        uint256 bef = _records[Token].balance;     
        _pullUnderlying(Token, msg.sender, amt);
        uint256 aft = bsub(IERC20(Token).balanceOf(address(this)), _totalSupply1);  
        uint256 finalAmount = bsub(aft, bef);  
        _totalSupply1 = badd(_totalSupply1, finalAmount);
        _balances1[msg.sender] = badd(_balances1[msg.sender], finalAmount);
        }
        else{
        uint256 bef = _records[Main].balance;
        _pullUnderlying(Main, msg.sender, amt);
        uint256 aft = bsub(IERC20(Main).balanceOf(address(this)), badd(_totalSupply2, badd(_totalSupply7, _totalSupply8)));
        uint256 finalAmount = bsub(aft, bef);
        _totalSupply2 = badd(_totalSupply2, finalAmount);
        _balances2[msg.sender] = badd(_balances2[msg.sender], finalAmount);
        }
        payStake();
    }

    function withdrawInternal(address asset, uint256 amt) external nonReentrant {
        require(asset == Main || asset == Token);
        
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
        payStake();
    }

    function swapToSwap(address path, address asset, address to, uint256 amt) external nonReentrant {
        require(asset == Main || asset == Token);
        
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
        payStake();
    }
    
    function transfer(address dst, uint256 amt) external returns(bool) {
        bool loc = getUserLock(msg.sender);
        require(loc == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amt) external returns(bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
        bool loc = getUserLock(msg.sender);
        require(loc == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != type(uint256).max) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
    
    function addBothLiquidity(uint256 poolAmountOut, uint[] calldata maxAmountsIn)
    nonReentrant
        external
    {
        sync();
        uint256 poolTotal = totalSupply;
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        
        
        bool loc = getUserLock(msg.sender);
        if(loc == true){
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
        }
        payStake();
        sync();
        _mint(poolAmountOut);
        _push(msg.sender, poolAmountOut);
    }
   
    function removeBothLiquidity(uint256 poolAmountIn, uint[] calldata minAmountsOut)
    nonReentrant
        external
    {
        bool loc = getUserLock(msg.sender);
        require(loc == false, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        sync();
        uint256 poolTotal = totalSupply;
        uint256 ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pull(msg.sender, poolAmountIn);
        _burn(poolAmountIn);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "Minimum amount out not met");
            emit LOG_EXIT(msg.sender, t, tokenAmountOut, 0);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
        sync();
        
        if(Bonus != address(0)){
        uint256 bal1 = bmul(ratio, IERC20(Bonus).balanceOf(address(this)));
        if(bal1 > 0){
        _pushUnderlying(Bonus, msg.sender, bal1);
        }
        }
    }
    
    function sendRebate() internal {
        uint256 re = address(this).balance / 8;
        TransferHelper.safeTransferETH(msg.sender, re);
        totalSentRebates += re;
        emit rebate(msg.sender, re);
    }
    
    function BUYSmart(
        uint256 tokenAmountIn,
        uint256 minAmountOut
    )  nonReentrant
        external 
        returns(uint256 tokenAmountOut)
    {

        require(_balances2[msg.sender] >= tokenAmountIn, "Not enough Main, deposit more");
        
        uint256 hold = IERC20(FEG).balanceOf(address(msg.sender));
        uint256 io = address(this).balance;
        
        if(io > 0 && tokenAmountIn >= 5e16 && hold >= 2e19){
        sendRebate();
        }
        
        Record storage inRecord = _records[address(Main)];
        Record storage outRecord = _records[address(Token)];

        require(tokenAmountIn <= MAX_BUY_RATIO, "ERR_BUY_IN_RATIO");
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");
        
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(tokenAmountIn, bdiv(999, 1000)),
                                            0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");   
        emit LOG_SMARTSWAP(msg.sender, Main, Token, tokenAmountIn, tokenAmountOut);
        _balances2[msg.sender] -= tokenAmountIn;
        _totalSupply2 -= tokenAmountIn;
        _balances1[msg.sender] += tokenAmountOut;
        _totalSupply1 += tokenAmountOut;
        _totalSupply8 += bmul(tokenAmountIn, bdiv(1, 1000));
        sync();
        
        return(tokenAmountOut);
    }
    
    function BUY(
        uint256 dot,
        address to,
        uint256 minAmountOut
    ) nonReentrant 
        external payable
        returns(uint256 tokenAmountOut)
    {
        
        require(open == true, "Swap not opened");
        wrap(Main).deposit{value: msg.value}();
        if(Address.isContract(msg.sender) == true){ 
        require(dot == spec, "Contracts are not allowed to interact with the Swap");
        }
        
        uint256 hold = IERC20(FEG).balanceOf(address(msg.sender));
        uint256 io = address(this).balance;
        
        if(io > 0 && msg.value >= 5e16 && hold >= 2e19){
        sendRebate();
        }
        
        Record storage inRecord = _records[address(Main)];
        Record storage outRecord = _records[address(Token)];
        
        require(msg.value <= MAX_BUY_RATIO, "ERR_BUY_IN_RATIO");
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");
        
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(msg.value, bdiv(999, 1000)),
                                            0
                                        );
                                        
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");
        uint256 oi = bmul(msg.value, bdiv(1, 1000));
        _totalSupply8 += bmul(oi, bdiv(tx2, 100));
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
    )  nonReentrant 
        external
        returns(uint256 tokenAmountOut)
    {
        
        require(open == true, "Swap not opened");
        if(Address.isContract(msg.sender) == true){ 
        require(dot == spec, "Contracts are not allowed to interact with the Swap");
        }
        
        uint256 hold = IERC20(FEG).balanceOf(address(msg.sender));
        if(address(this).balance > 0 && hold >= 2e19 && tokenAmountOut <= 1e18){
        sendRebate();
        }
        
        uint256 omm = _records[Token].balance;
        _pullUnderlying(Token, msg.sender, tokenAmountIn);
        setTokenBalance();
        uint256 trueamount = bmul((_records[Token].balance - omm), bdiv(998, 1000));
        require(tokenAmountIn <= MAX_SELL_RATIO, "ERR_SELL_RATIO");
        require(tokenAmountOut <= bmul(_records[Main].balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO"); 
        
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            omm,
                                            bmul(1e18, 25),
                                            _records[Main].balance,
                                            bmul(1e18, 25),
                                            trueamount,
                                            2e15
                                        );
                                         
        require(tokenAmountOut >= minAmountOut, "Minimum amount out not met");
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(toka, bdiv(15, 10000));
        uint256 tok = bmul(toka, bdiv(15, 10000));
        uint256 tokAmountI2 =  bmul(toka, bdiv(PSS, 10000));
        uint256 io = (toka - (tokAmountI + tok + tokAmountI2));
        uint256 tokAmountI1 = bmul(io, bdiv(999, 1000));
        uint256 ox = _balances2[address(this)];
        if(ox > 1e15){
        _totalSupply2 -= ox;
        _balances2[address(this)] = 0;
        }
        
        wrap(Main).withdraw(tokAmountI1 + ox + tokAmountI);
        TransferHelper.safeTransferETH(to, bmul(tokAmountI1, bdiv(99, 100)));
        _totalSupply8 += bmul(io, bdiv(1, 1000));
        _balances2[pairRewardPool] += tokAmountI2;
        _totalSupply2 += tokAmountI2;
        _totalSupply7 += tok;
        addRebate();
        setMainBalance(); 
        emit LOG_SWAP(msg.sender, Token, Main, trueamount, bmul(tokAmountI1, bdiv(tx2, 100)));
        return tokenAmountOut;
    }
    
     function SELLSmart(
        uint256 tokenAmountIn,
        uint256 minAmountOut
    )  nonReentrant
        external
        returns(uint256 tokenAmountOut)
    {
        uint256 hold = IERC20(FEG).balanceOf(address(msg.sender));
        if(address(this).balance > 0 && hold >= 2e19 && tokenAmountOut <= 1e18){
        sendRebate();
        }
        
        uint256 tai = tokenAmountIn;
        require(_balances1[msg.sender] >= tai, "Not enough Token");
        Record storage inRecord = _records[address(Token)];
        Record storage outRecord = _records[address(Main)];
        require(tai <= MAX_SELL_RATIO, "ERR_SELL_RATIO");
        require(tokenAmountOut <= bmul(outRecord.balance, bdiv(MAX_RATIO, 100)), "Over MAX_OUT_RATIO");
        
        uint256 tokenInFee;
        (tokenAmountOut, tokenInFee) = calcOutGivenIn(
                                            inRecord.balance,
                                            bmul(1e18, 25),
                                            outRecord.balance,
                                            bmul(1e18, 25),
                                            bmul(tai, bdiv(998, 1000)),
                                            2e15
                                        );
        
        uint256 toka = bmul(tokenAmountOut, bdiv(RPF, 1000));
        uint256 tokAmountI  = bmul(toka, bdiv(15, 10000));
        uint256 tok = bmul(toka, bdiv(15, 10000));
        uint256 tokAmountI2 =  bmul(toka, bdiv(PSS, 10000));
        uint256 io = (toka - (tokAmountI + tok + tokAmountI2));
        uint256 tokAmountI1 = bmul(io, bdiv(999, 1000));
        emit LOG_SMARTSWAP(msg.sender, Token, Main, tai, tokAmountI1);
        _totalSupply8 += bmul(io, bdiv(1, 1000));
        require(tokAmountI1 >= minAmountOut, "Minimum amount out not met");
        _balances1[msg.sender] -= tai;
        _totalSupply1 -= tai;
        _balances2[msg.sender] += tokAmountI1;
        _balances2[address(this)] += tokAmountI;
        _balances2[pairRewardPool] += tokAmountI2;
        _totalSupply2 += (tokAmountI + tokAmountI2 + tokAmountI1);
        _totalSupply7 += tok;
        sync();
        addRebate();
        return(tokenAmountOut);
    }
    
    function sync() public {  // updates the liquidity to current state
    setTokenBalance();
    setMainBalance();
    }
    
    function setTokenBalance() internal {
        _records[Token].balance = IERC20(Token).balanceOf(address(this)) - _totalSupply1;  
    }
        
    function setMainBalance() internal {
        uint256 al = (_totalSupply2 +_totalSupply7 + _totalSupply8);
        _records[Main].balance = IERC20(Main).balanceOf(address(this)) - al;
    }
        
    function setRPF(uint256 _PSS, uint256 _RPF ) external {
        require(msg.sender == _poolOwner, "You do not have permission");
        require(_PSS <= 50 && _PSS != 0, " Cannot set over 0.5%"); 
        require(_RPF >= 990 && _RPF <= 1000, " Cannot set over 1%"); 
        RPF = _RPF;
        PSS = _PSS;
    }
    
    function releaseLiquidity() nonReentrant external { // Allows removal of liquidity after the lock period is over
        address user = msg.sender;
        bool loc = getUserLock(user);
        require(loc == true, "Liquidity not locked");
        uint256 total = IERC20(address(this)).balanceOf(user);
        lockedLiquidity -= total;
        userLock storage ulock = _userlock[user];
        userLock storage time = _unlockTime[user];
        require (block.timestamp >= time.unlockTime, "Liquidity is locked, you cannot remove liquidity until after lock time.");
        ulock.setLock = false; 
    }
    
    function initializeMigrate(address user) external { //Incase we upgrade to v3 in the future, will offer a 48 hour time delay to allow releasing liquidity for migration to new pools.
        require(msg.sender == _controller, "You do not have permission");
        bool loc = getUserLock(user);
        require(loc == true, "Liquidity not locked");
        userLock storage time = _unlockTime[user];
        time.unlockTime = block.timestamp + 2 days; 
    }

    function _pullUnderlying(address erc20, address from, uint256 amount)
        internal
    {   
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(address erc20, address to, uint256 amount)
        internal
    {   
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function payStake() internal {
        if(_totalSupply7 > 5e15) {
        bool xfer = IERC20(Main).transfer(FEGstake, _totalSupply7);
        require(xfer, "ERR_ERC20_FALSE");
        _totalSupply7 = 0;
        }
    }
    
    function addRebate()
        internal
    {   
        if(_totalSupply8 > 5e15){
        wrap(Main).withdraw(_totalSupply8);
        _totalSupply8 = 0;
        }
    }
    
    function payMain(address payee, uint256 amount)
        external nonReentrant 
        
    {   
        require(_balances2[msg.sender] >= amount, "Not enough token");
        uint256 amt = bmul(amount, bdiv(997, 1000));
        uint256 amt1 = bsub(amount, amt);
        _balances2[msg.sender] -= amount;
        _balances2[payee] += amt;
        _balances2[_controller] += amt1;
    }
    
    function payToken(address payee, uint256 amount)
        external nonReentrant 
        
    {
        require(_balances1[msg.sender] >= amount, "Not enough token");
        uint256 amt = bmul(amount, bdiv(997, 1000));
        uint256 amt1 = bsub(amount, amt);
        _balances1[msg.sender] -= amount;
        _balances1[payee] += amt;
        _balances1[_controller] += amt1;
    }
}