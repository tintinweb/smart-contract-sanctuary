/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

pragma solidity ^0.5.4;

interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract XSwap {
	using SafeMath for uint256;
 	address payable internal owner;
    address payable internal voiddev;
    address payable internal t2xdev;
    address internal tokenA ;

    uint256 internal constant HOURGLASS_FEE = 10;
    uint256 constant internal MAGNITUDE = 2 ** 64;
    uint32 constant private DAILY_RATE = 2880000;

 	mapping(address => mapping(address => Pair)) private pairs;

    struct Token {
        address token;
        uint256 profitPerShare;
        uint256 pool;
        uint256 LP_Supply;
        mapping(address => uint256) balanceLedger;
        mapping(address => int256) payoutsTo;
        mapping(address => uint256) claimedOf;
        uint256 reserve;
        uint256 lastDripTime;
        uint256 hourlyRemovedLiquidity;
        uint256 hourlyAddedLiquidity;
        uint256 LPHourlyTimer;
        uint256 minimumLock;
    }

    struct Pair {
        Token tokenA;
        Token tokenB;
        uint256 launch_time;
        uint256 trading_time;
        uint256 LP_FEE;
        uint256 TRON_FEE;
        uint256 VOID_FEE;
    }

    struct Asset {
        uint8 decimals;
        bool  added ;
    }

	event onPairCreated(
        address  tokenA,
        address  tokenB
    );

    event onAddLiquidity(
		address provider,
		address tokenA,
        address tokenB,
        address to,
        uint256 amount
	);

    event onRemoveLiquidity(
		address provider,
		address tokenA,
        address tokenB,
        address from,
        uint256 amount
	);

    event onSwap(
		address indexed sender,
        address tokenB,
		address tokenFrom,
        address tokenTo,
        uint256 amountIn,
        uint256 amountOut
	);

    modifier onlyOwner() {
      require(msg.sender == owner,"NO_AUTH");
    _;
    }

	constructor(address t2x_token , address payable  _voiddev , address payable _t2xdev) public {
		owner = msg.sender;
        tokenA = t2x_token;
        voiddev = _voiddev;
        t2xdev = _t2xdev;
    }


    modifier hasDripped(address tokenB,address from){
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];

        if(from == pair.tokenA.token && pair.tokenA.pool > 0){
          uint256 secondsPassed = SafeMath.sub(now,pair.tokenA.lastDripTime);
          uint256 dividends = secondsPassed.mul(pair.tokenA.pool).div(DAILY_RATE);

          if (dividends > pair.tokenA.pool) {
            dividends = pair.tokenA.pool; 
          }

          pair.tokenA.profitPerShare = SafeMath.add(pair.tokenA.profitPerShare, (dividends * MAGNITUDE) / pair.tokenA.LP_Supply);
          pair.tokenA.pool = pair.tokenA.pool.sub(dividends);
          pair.tokenA.lastDripTime = now;
        }else if(from == pair.tokenB.token && pair.tokenB.pool > 0){
          uint256 secondsPassed = SafeMath.sub(now,pair.tokenB.lastDripTime);
          uint256 dividends = secondsPassed.mul(pair.tokenB.pool).div(DAILY_RATE);

          if (dividends > pair.tokenB.pool) {
            dividends = pair.tokenB.pool;
          }

          pair.tokenB.profitPerShare = SafeMath.add(pair.tokenB.profitPerShare, (dividends * MAGNITUDE) / pair.tokenB.LP_Supply);
          pair.tokenB.pool = pair.tokenB.pool.sub(dividends);
          pair.tokenB.lastDripTime = now;
        }
        _;
    }

    function  _checkHourlyLPLimit(bool isAdd , uint256 _value ,Pair storage pair, address selected) internal{
        require(pair.launch_time > 0, 'PAIR_NOT_EXISTS');
        Token storage selectedToken = pair.tokenA;

        if(pair.tokenB.token == selected){
            selectedToken = pair.tokenB;
        }
        if(selectedToken.reserve > 0 && pair.trading_time < now){
            //1 - Reset Liquidity Volume if + 1 hour
            if(now - selectedToken.LPHourlyTimer >= 1 hours ){
                selectedToken.hourlyRemovedLiquidity = 0;
                selectedToken.hourlyAddedLiquidity = 0;
                selectedToken.LPHourlyTimer = now;
            }
            uint256 value = _value;
            if(selected == address(0) && isAdd){
                value = msg.value;
            }

            //2.5% of current liquidity;
            uint256 currentVariance = SafeMath.div(SafeMath.mul(selectedToken.reserve, 5),100);
            uint256 added = selectedToken.hourlyAddedLiquidity;
            uint256 removed = selectedToken.hourlyRemovedLiquidity;

           if(isAdd){
                added += value;              
            }else{
                removed += value;
            }

            //Added liquidity cannot exceed the hourly limite of 2.5 of the total dex liquidity
            uint256 average = 0;
            if(added > removed){
                average = added - removed;
            }else{
                average = removed - added;
            }

           require( average < (currentVariance + selectedToken.minimumLock ) , "Hourly LP Limit Reached");
        }
	}

    function changeOwnership(address payable _newowner) external onlyOwner returns (bool) {
        owner = _newowner;
    }

    function updateFees(address tokenB,uint256 _LPfee , uint256 _TronFee, uint256 _VoidFee) external onlyOwner returns (bool) {
        Pair storage pair = pairs[tokenA][tokenB];
        
        require(pair.launch_time > 0, 'PAIR_NOT_EXISTS');

        pair.LP_FEE = _LPfee;
        pair.TRON_FEE = _TronFee;
        pair.VOID_FEE = _VoidFee;

        return true;
    }


	function createPair(address tokenB,uint256 minA , uint256 minB) external onlyOwner returns (bool) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        require(minA > 0 && minB > 0 , 'MINIMUM_LOCK_LIMIT');
        require(pairs[tokenA][tokenB].launch_time == 0, 'PAIR_EXISTS');
        require(pairs[tokenB][tokenA].launch_time == 0, 'PAIR_EXISTS');

        Token memory tokenA_obj = Token({
            token : tokenA,
            profitPerShare : 0,
            pool:0,
            LP_Supply:0,
            reserve : 0,
            lastDripTime:now,
            hourlyRemovedLiquidity:0,
            hourlyAddedLiquidity:0,
            LPHourlyTimer:now,
            minimumLock : minA
        });

        Token memory tokenB_obj = Token({
            token : tokenB,
            profitPerShare : 0,
            pool:0,
            LP_Supply:0,
            reserve : 0,
            lastDripTime:now,
            hourlyRemovedLiquidity:0,
            hourlyAddedLiquidity:0,
            LPHourlyTimer:now,
            minimumLock : minB
        });

        Pair memory pair = Pair({
            tokenA : tokenA_obj,
            tokenB : tokenB_obj,
            launch_time : now + 24 hours,
            trading_time : now + 48 hours,
            LP_FEE : 9,
            TRON_FEE : 10,
            VOID_FEE : 1
        });

        pairs[tokenA][tokenB] = pair;

        emit onPairCreated(tokenA, tokenB);

        return true;
    }

    function _trasnferFrom(address token , uint256 amount) internal returns (uint256) {
        require(amount > 0 && token != address(0) ,'NO_VALUE');
        uint256 currentBalance = ITRC20(token).balanceOf(address(this));
        ITRC20(token).transferFrom(msg.sender, address(this), amount);
        return ITRC20(token).balanceOf(address(this)) - currentBalance;
    }

    function _doAddLiquidity(Token storage selectedToken ,uint256 _amount , Pair memory pair) internal{

        uint256 value = 0;

        if(selectedToken.token == address(0)){
            require(msg.value > 0, 'NO_VALUE');
            value = msg.value;
        }else {
           value = _trasnferFrom(selectedToken.token,_amount);
        }

       // MANAGE HOURGLASS
		uint256 _dividens = (value * HOURGLASS_FEE) / 100;

        if(selectedToken.reserve > 0 && pair.trading_time < now) selectedToken.hourlyAddedLiquidity += SafeMath.sub(value,_dividens);
        selectedToken.pool = selectedToken.pool.add(_dividens);
        selectedToken.LP_Supply = SafeMath.add(selectedToken.LP_Supply,SafeMath.sub(value,_dividens));
        selectedToken.balanceLedger[msg.sender] = SafeMath.add(selectedToken.balanceLedger[msg.sender], SafeMath.sub(value,_dividens));
        selectedToken.payoutsTo[msg.sender] += (int256) (selectedToken.profitPerShare * SafeMath.sub(value,_dividens));
        selectedToken.reserve += SafeMath.sub(value,_dividens);
        

       emit onAddLiquidity(msg.sender, pair.tokenA.token,pair.tokenB.token,selectedToken.token, value);

    }

    function addLiquidity(address tokenB, address _addTo , uint256 _amount) hasDripped(tokenB,_addTo) public payable {
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        require(pairs[tokenA][tokenB].launch_time < now , 'NOT_LAUNCHED');

        _checkHourlyLPLimit(true,_amount , pairs[tokenA][tokenB] , _addTo) ;

        Token storage selectedToken = pairs[tokenA][tokenB].tokenA;

        if(_addTo == pairs[tokenA][tokenB].tokenB.token){
            selectedToken = pairs[tokenA][tokenB].tokenB;
        }

        _doAddLiquidity(selectedToken,_amount,pairs[tokenA][tokenB]);
    }

    function removeLiquidity(address tokenB, address _removeFrom ,uint256 _amount)  hasDripped(tokenB,_removeFrom) public payable {
        require(_amount > 0, "VALUE_NOT_ZERO");
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        Pair storage pair = pairs[tokenA][tokenB];
        _checkHourlyLPLimit(false,_amount,pairs[tokenA][tokenB],_removeFrom);
        // MANAGE HOURGLASS
		uint256 _dividens = (_amount * HOURGLASS_FEE) / 100;
        Token storage selectedToken = pair.tokenA;

        if(_removeFrom == pair.tokenB.token){
            selectedToken = pair.tokenB;
        }

        require((_amount <= selectedToken.balanceLedger[msg.sender]), "NO_BALANCE");
        selectedToken.LP_Supply = SafeMath.sub(selectedToken.LP_Supply,_amount);
        selectedToken.balanceLedger[msg.sender] = SafeMath.sub(selectedToken.balanceLedger[msg.sender], _amount);
        selectedToken.payoutsTo[msg.sender] -= (int256) (selectedToken.profitPerShare *  _amount);
        selectedToken.reserve = SafeMath.sub(selectedToken.reserve,_amount);
        if(pair.trading_time < now) selectedToken.hourlyRemovedLiquidity += _amount;
        selectedToken.pool = selectedToken.pool.add(_dividens);

        _transfer(_removeFrom,SafeMath.sub(_amount,_dividens),msg.sender);

        emit onRemoveLiquidity(msg.sender, pair.tokenA.token,pair.tokenB.token,_removeFrom, _amount);
    }

    function _transfer(address token , uint256 amount ,address payable to) internal {
         if(token == address(0)){
            address(to).transfer(amount);
        }else{
            ITRC20(token).transfer(to,amount);
        }
    }

    function swap(address tokenB ,address from ,uint256 _amount) public payable {

        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];
        require(pair.trading_time < now , 'TRADING_CLOSED');
        require(pair.tokenA.reserve > 0 && pair.tokenB.reserve > 0 , 'INSUFFICIENT_LIQUIDITY');
        uint256 value = 0;
        uint256 outputReserve = 0;
        uint256 inputReserve = 0;

        if(from == address(0)){
            value = msg.value;
        }else{
            ITRC20 trc20 = ITRC20(from);
            uint256 currentBalance = ITRC20(from).balanceOf(address(this));
            trc20.transferFrom(msg.sender, address(this), _amount);
            uint256 diff = trc20.balanceOf(address(this)) - currentBalance;
            value = diff;
        }

        require(value > 0,'VALUE_NOT_ZERO');
        uint256 dividens = (value * pair.LP_FEE) / 100;
        uint256 voidFee = 0;
        uint256 tronFee = 0;

        if(from == address(0)){
            voidFee = (value * pair.VOID_FEE ) / 100;
            tronFee = (value * pair.TRON_FEE ) / 100;
            if(tronFee > 0) t2xdev.transfer(tronFee);
            if(voidFee > 0) voiddev.transfer(voidFee);
        }
        if(pair.tokenA.token == from){
            inputReserve = pair.tokenA.reserve;
            outputReserve = pair.tokenB.reserve;
            pair.tokenA.pool += dividens;
        }else{
            inputReserve = pair.tokenB.reserve;
            outputReserve = pair.tokenA.reserve;
            pair.tokenB.pool += dividens;
        }

        uint256 taxedValue = SafeMath.sub(value,dividens + voidFee + tronFee);

		uint256 numerator = SafeMath.mul(taxedValue,outputReserve);
		uint256 denominator = SafeMath.add(inputReserve,taxedValue);

		uint256 result = SafeMath.div(numerator,denominator);

        if(pair.tokenA.token == from){
            pair.tokenA.reserve += taxedValue;
            pair.tokenB.reserve -= result;
            if(pair.tokenB.token == address(0)){
                voidFee = (result * pair.VOID_FEE ) / 100;
                tronFee = (result * pair.TRON_FEE ) / 100;
                if(tronFee > 0) t2xdev.transfer(tronFee);
                if(voidFee > 0) voiddev.transfer(voidFee);
                address(msg.sender).transfer(SafeMath.sub(result,voidFee + tronFee));
            }else{
                ITRC20 trc20 = ITRC20(pair.tokenB.token);
                trc20.transfer(msg.sender, result); 
            }
            emit onSwap(msg.sender,pair.tokenB.token, from,pair.tokenB.token,value,result);
        }else{
            pair.tokenB.reserve += taxedValue;
            pair.tokenA.reserve -= result;
            if(pair.tokenA.token == address(0)){            
                voidFee = (result * pair.VOID_FEE ) / 100;
                tronFee = (result * pair.TRON_FEE ) / 100;
                if(tronFee > 0) t2xdev.transfer(tronFee);
                if(voidFee > 0) voiddev.transfer(voidFee);
                address(msg.sender).transfer(SafeMath.sub(result,voidFee + tronFee));
            }else{
                ITRC20 trc20 = ITRC20(pair.tokenA.token);
                trc20.transfer(msg.sender, result);
            }

            emit onSwap(msg.sender,pair.tokenB.token, from,pair.tokenA.token,value,result);
        }  
    }

	function claimEarning(address tokenB,address from) hasDripped(tokenB,from) public {
        
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];
        
        (uint256 divA,uint256 divB) = dividendsOf(msg.sender,tokenB);

        if(from == pair.tokenA.token){
            require(divA > 0 , "NO_DIV");
            pair.tokenA.payoutsTo[msg.sender] += (int256) (divA * MAGNITUDE);
		    pair.tokenA.claimedOf[msg.sender] += divA;
            _transfer(from,divA,msg.sender);
        }else{
            require(divB > 0 , "NO_DIV");
            pair.tokenB.payoutsTo[msg.sender] += (int256) (divB * MAGNITUDE);
		    pair.tokenB.claimedOf[msg.sender] += divB;
            _transfer(from,divB,msg.sender);
        }
    }

    function getPairInfo(address tokenB) public view returns (uint256 ,uint256 ,uint256,uint256,uint256,uint256){
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        Pair memory pair = pairs[tokenA][tokenB];
        return (pair.tokenA.reserve,pair.tokenB.reserve,pair.launch_time,pair.trading_time,pair.tokenA.LP_Supply,pair.tokenB.LP_Supply);
    }

    function getPairFees(address tokenB) public view returns (uint256 ,uint256 ,uint256){
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        Pair memory pair = pairs[tokenA][tokenB];
        return (pair.LP_FEE,pair.TRON_FEE,pair.VOID_FEE);
    }


    function getPairLiquidityInfo(address tokenB) public view returns (uint256 ,uint256 ,uint256,uint256,uint256,uint256,uint256,uint256){
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        Pair memory pair = pairs[tokenA][tokenB];

        if(now - pair.tokenA.LPHourlyTimer >= 1 hours){
            pair.tokenA.hourlyRemovedLiquidity = 0;
            pair.tokenA.hourlyAddedLiquidity = 0;
        }

        if(now - pair.tokenB.LPHourlyTimer >= 1 hours){
            pair.tokenB.hourlyRemovedLiquidity = 0;
            pair.tokenB.hourlyAddedLiquidity = 0;
        }

        return (pair.tokenA.hourlyAddedLiquidity,pair.tokenB.hourlyAddedLiquidity,pair.tokenA.hourlyRemovedLiquidity,pair.tokenB.hourlyRemovedLiquidity,pair.tokenA.LPHourlyTimer,pair.tokenB.LPHourlyTimer,pair.tokenA.minimumLock,pair.tokenB.minimumLock);
    }
    
    function getPairPools(address tokenB) public view returns (uint256 ,uint256){
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');
        Pair memory pair = pairs[tokenA][tokenB];
        return (pair.tokenA.pool,pair.tokenB.pool);
    }

    function estimateDividendsOf(address _customerAddress,address tokenB) public view returns (uint256,uint256) {
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];

        uint256 divA = 0;
        uint256 divB = 0;

        if(pair.tokenA.pool > 0){
            uint256 _profitPerShare = pair.tokenA.profitPerShare;
            uint256 secondsPassed = SafeMath.sub(now,pair.tokenA.lastDripTime);
            uint256 dividends = secondsPassed.mul(pair.tokenA.pool).div(DAILY_RATE);

            if (dividends > pair.tokenA.pool) {
                dividends = pair.tokenA.pool;
            }

            _profitPerShare = SafeMath.add(pair.tokenA.profitPerShare, (dividends * MAGNITUDE) / pair.tokenA.LP_Supply);

            divA =  (uint256) ((int256) (_profitPerShare * pair.tokenA.balanceLedger[_customerAddress]) - pair.tokenA.payoutsTo[_customerAddress]) / MAGNITUDE;
        }
        
        if(pair.tokenB.pool > 0){
            uint256 _profitPerShare = pair.tokenB.profitPerShare;
            uint256 secondsPassed = SafeMath.sub(now,pair.tokenB.lastDripTime);
            uint256 dividends = secondsPassed.mul(pair.tokenB.pool).div(DAILY_RATE);

            if (dividends > pair.tokenB.pool) {
                dividends = pair.tokenB.pool;
            }

            _profitPerShare = SafeMath.add(pair.tokenB.profitPerShare, (dividends * MAGNITUDE) / pair.tokenB.LP_Supply);

            divB =  (uint256) ((int256) (_profitPerShare * pair.tokenB.balanceLedger[_customerAddress]) - pair.tokenB.payoutsTo[_customerAddress]) / MAGNITUDE;
        }

        return (divA , divB);
    }


    function balanceOf(address _customerAddress,address tokenB) public view returns (uint256 , uint256) {
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];

        return (pair.tokenA.balanceLedger[_customerAddress],pair.tokenB.balanceLedger[_customerAddress]);
    }

    function claimedOf(address _customerAddress,address tokenB) public view returns (uint256 , uint256) {
        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];

        return (pair.tokenA.claimedOf[_customerAddress],pair.tokenB.claimedOf[_customerAddress]);
    }

    function dividendsOf(address _customerAddress,address tokenB) public view returns (uint256 , uint256) {

        require(pairs[tokenA][tokenB].launch_time > 0, 'PAIR_NOT_EXISTS');

        Pair storage pair = pairs[tokenA][tokenB];

        return ((uint256) ((int256) (pair.tokenA.profitPerShare * pair.tokenA.balanceLedger[_customerAddress]) - pair.tokenA.payoutsTo[_customerAddress]) / MAGNITUDE ,(uint256) ((int256) (pair.tokenB.profitPerShare * pair.tokenB.balanceLedger[_customerAddress]) - pair.tokenB.payoutsTo[_customerAddress]) / MAGNITUDE);
        
    }
}