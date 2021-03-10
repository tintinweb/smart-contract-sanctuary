pragma solidity 0.5.12;

import "./MToken.sol";
import "./MMath.sol";

interface IMFactory {
    function isWhiteList(address w) external view returns (bool);
    function getMining() external returns (address lpMiningAdr, address swapMiningAdr);
    function getFeeTo() external view returns (address);
}

interface IMining {
    // pair
    function addLiquidity(bool isGp, address _user, uint256 _amount) external;
    function removeLiquidity(bool isGp, address _user, uint256 _amount) external;
    function updateGPInfo(address[] calldata gps, uint256[] calldata amounts) external;
    // lp mining
    function onTransferLiquidity(address from, address to, uint256 lpAmount) external;
    function claimLiquidityShares(address user, address[] calldata tokens, uint256[] calldata balances, uint256[] calldata weights, uint256 amount, bool _add) external;
    // swap mining
    function claimSwapShare(address user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut) external;
}

interface IPairFactory {
    function newPair(address pool, uint256 perBlock, uint256 rate) external returns (IPairToken);
    function getPairToken(address pool) external view returns (address);
}

interface IPairToken {
    function setController(address _controller) external ;
}

contract MPool is MBronze, MToken, MMath {

    struct Record {
        bool bound;   // is token bound to pool
        uint index;   // private
        uint denorm;  // denormalized weight
        uint balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    IMFactory private _factory;    // MFactory address to push token exitFee to and check whitelist from factory
    IMining private _pair;
    address public controller;     // has CONTROL role

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    bool private _finalized;
    bool private _publicSwap;     // true if PUBLIC can call SWAP functions

    address[] private _tokens;
    mapping(address => Record) private  _records;
    uint private _totalWeight;

    constructor() public {
        controller = msg.sender;
        _factory = IMFactory(msg.sender);

        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap()
    external view
    returns (bool)
    {
        return _publicSwap;
    }

    function isFinalized()
    external view
    returns (bool)
    {
        return _finalized;
    }

    function isBound(address t)
    external view
    returns (bool)
    {
        return _records[t].bound;
    }

    function getNumTokens()
    external view
    returns (uint)
    {
        return _tokens.length;
    }

    function getCurrentTokens()
    external view _viewlock_
    returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getFinalTokens()
    external view
    _viewlock_
    returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
    external view
    _viewlock_
    returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
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

        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
    external view
    _viewlock_
    returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee()
    external view
    _viewlock_
    returns (uint)
    {
        return _swapFee;
    }

    function getPair()
    external view
    _viewlock_
    returns (address)
    {
        return address(_pair);
    }

    function setSwapFee(uint swapFee)
    external
    _logs_
    _lock_
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager)
    external
    _logs_
    _lock_
    {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        controller = manager;
    }

    function setPair(IMining pair)
    external
    _logs_
    _lock_
    {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        _setPair(pair);
    }

    function _setPair(IMining pair)
    internal
    {
        _pair = pair;
    }

    function finalize(address beneficiary, uint fixPoolSupply)
    external
    _logs_
    _lock_
    {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(!_finalized || totalSupply() == 0, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        uint256 supply = fixPoolSupply == 0 ? INIT_POOL_SUPPLY : fixPoolSupply;

        _mintPoolShare(supply);
        _pushPoolShare(beneficiary, supply);
        _lpChanging(true, beneficiary, supply);
    }


    function bind(address token, uint balance, uint denorm)
    external
    _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
        bound: true,
        index: _tokens.length,
        denorm: 0,    // balance and denorm will be validated
        balance: 0    // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(address token, uint balance, uint denorm)
    public
    _logs_
    _lock_
    {

        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized || totalSupply() == 0, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
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
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }

    function unbind(address token)
    external
    _logs_
    _lock_
    {

        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint tokenBalance = _records[token].balance;
        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
        bound: false,
        index: 0,
        denorm: 0,
        balance: 0
        });

        _pushUnderlying(token, msg.sender, tokenBalance);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
    external
    _logs_
    _lock_
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
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

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
    external view
    _viewlock_
    returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(address beneficiary, uint poolAmountOut)
    external
    _logs_
    _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(bsub(IERC20(_tokens[i]).balanceOf(address(this)), _records[t].balance) >= tokenAmountIn);
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(beneficiary, poolAmountOut);

        _lpChanging(true, beneficiary, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
    external
    _logs_
    _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }

        _lpChanging(false, msg.sender, poolAmountIn);
    }


    function swapExactAmountIn(
        address user,
        address tokenIn,
        address tokenOut,
        uint minAmountOut,
        address to,
        uint maxPrice
    )
    external
    _lock_
    returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        uint tokenAmountIn = bsub(IERC20(tokenIn).balanceOf(address(this)), inRecord.balance);
        require(tokenAmountIn > 0, "ERR_AMOUNTIN_NOT_IN_Pool");
        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint256 factoryFee = bmul(tokenAmountIn, bmul(bdiv(_swapFee, 6), 1));

        uint spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            _swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        uint inAfterFee = bsub(tokenAmountIn, factoryFee);
        inRecord.balance = badd(inRecord.balance, inAfterFee);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

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

        _pushUnderlying(tokenOut, to, tokenAmountOut);
        _pushUnderlying(tokenIn, _factory.getFeeTo(), factoryFee);

        _swapMining(user, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address user,
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        address to,
        uint maxPrice
    )
    external
    _lock_
    returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        uint spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            _swapFee
        );
        uint user_deposit_amount = bsub(IERC20(tokenIn).balanceOf(address(this)), inRecord.balance);
        require(tokenAmountIn == user_deposit_amount && user_deposit_amount <= maxAmountIn, "ERR_LIMIT_IN");

        uint256 factoryFee = bmul(tokenAmountIn, bmul(bdiv(_swapFee, 6), 1));

        inRecord.balance = badd(inRecord.balance, bsub(tokenAmountIn, factoryFee));
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

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

        _pushUnderlying(tokenOut, to, tokenAmountOut);
        _pushUnderlying(tokenIn, _factory.getFeeTo(), factoryFee);

        _swapMining(user, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        return (tokenAmountIn, spotPriceAfter);
    }

    function calcDesireByGivenAmount(address tokenIn, address tokenOut, uint256 inAmount, uint256 outAmount)
    external view
    returns (uint desireAmount)
    {
        require(inAmount != 0 || outAmount != 0, "ERR_AMOUNT_IS_ZERO");
        Record memory inRecord = _records[address(tokenIn)];
        Record memory outRecord = _records[address(tokenOut)];
        if (inAmount != 0) {
            desireAmount = calcOutGivenIn(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, inAmount, _swapFee);
        } else {
            desireAmount = calcInGivenOut(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, outAmount, _swapFee);
        }
    }
    function calcPoolSpotPrice(address tokenIn, address tokenOut, uint256 inAmount, uint256 outAmount)
    external view
    returns (uint256 price)
    {
        Record memory inRecord = _records[address(tokenIn)];
        Record memory outRecord = _records[address(tokenOut)];
        if (inAmount != 0 && outAmount != 0) {
            uint256 factoryFee = bmul(inAmount, bmul(bdiv(_swapFee, 6), 1));
            price = calcSpotPrice(
                badd(inRecord.balance, bsub(inAmount, factoryFee)),
                inRecord.denorm,
                bsub(outRecord.balance, outAmount),
                outRecord.denorm,
                _swapFee);
        } else {
            price = calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
        }
    }

    function updatePairGPInfo(address[] calldata gps, uint[] calldata shares)
    external
    {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        if (address(_pair) != address(0))
        {
            _pair.updateGPInfo(gps, shares);
        }
    }

    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint amount)
    internal
    {
        safeTransferFrom(erc20, from, address(this), amount);
    }

    function _pushUnderlying(address erc20, address to, uint amount)
    internal
    {
        safeTransfer(erc20, to, amount);
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

    function _lpChanging(bool add, address user, uint256 amount)
    internal
    {
        if (address(_pair) != address(0))
        {
            add == true ? _pair.addLiquidity(false, user, amount) : _pair.removeLiquidity(false, user, amount);
        }

        (address lpMiningAdr, ) = _factory.getMining();
        if (lpMiningAdr != address(0))
        {
            IMining mining = IMining(lpMiningAdr);
            uint256[] memory balances = new uint256[](_tokens.length);
            uint256[] memory weights = new uint256[](_tokens.length);
            for (uint i = 0; i < _tokens.length; i++) {
                balances[i] = _records[_tokens[i]].balance;
                weights[i] = bdiv(_records[_tokens[i]].denorm, _totalWeight);
            }

            mining.claimLiquidityShares(user, _tokens, balances, weights, amount, add);
        }

    }

    function _swapMining(address user, address tokenIn, address tokenOut, uint256 tokenAmountIn, uint256 tokenAmountOut)
    internal
    {
        ( ,address swapMiningAdr) = _factory.getMining();
        if (swapMiningAdr != address(0)){
            IMining mining = IMining(swapMiningAdr);
            mining.claimSwapShare(user, tokenIn, tokenAmountIn, tokenOut, tokenAmountOut);
        }
    }

    function _transferLiquidity(address src, address dst, uint amt) internal {
        (address lpMiningAdr, ) = _factory.getMining();
        if (lpMiningAdr != address(0)){
            IMining mining = IMining(lpMiningAdr);
            mining.onTransferLiquidity(src, dst, amt);
        }
    }

    function transfer(address dst, uint amt) external returns (bool) {
        require(_factory.isWhiteList(msg.sender) || _factory.isWhiteList(dst), "ERR_NOT_WHITELIST");
        _move(msg.sender, dst, amt);
        if(dst != address(this)){
            _transferLiquidity(msg.sender, dst, amt);
        }
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(_factory.isWhiteList(msg.sender) || _factory.isWhiteList(dst), "ERR_NOT_WHITELIST");
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        if(dst != address(this)){
            _transferLiquidity(src, dst, amt);
        }
        return true;
    }

    function bindPair(
        IPairFactory pairFactory,
        address[] calldata gps,
        uint[] calldata shares,
        uint gpRate
    ) external {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
        IPairToken pair = pairFactory.newPair(address(this), 4 * 10 ** 18, gpRate);
        _setPair(IMining(address(pair)));
        if (gpRate > 0 && gpRate <= 15 && gps.length != 0 && gps.length == shares.length) {
            _pair.updateGPInfo(gps, shares);
        }
        pair.setController(msg.sender);
    }
}