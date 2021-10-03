/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.7.6;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }


        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



contract NPCTOKEN is IBEP20, Auth {
    using SafeMath for uint256;

	struct FeeSet {
		uint256 reflectionFee;
		uint256 marketingFee;
		uint256 liquidityFee;
		uint256 burnFee;
		uint256 totalFee;
	}


    uint256 _prerrate;
    uint256 _saleTokenTotal;
    uint256 _saleBnbTotal;
    uint256 _softBnbTotal;
    uint256 _hardBnbTotal;
    uint256 _minLimit;
    uint256 _maxLimit;

    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "NPC";
    string constant _symbol = "NPC";
    uint8 constant _decimals = 18;

    uint256 public _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100; //1% of total supply
    uint256 public _maxSellTxAmountRate =5;
    uint256 public _maxSellTxAmountL = 121 * (10 ** _decimals);
    uint256 public _maxWalletToken = (_totalSupply * 2) / 100; //2% of total supply

    uint256 timeBeforeFirstBuy = 6 seconds;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 private finalSupply =100000000 * (10 ** _decimals);

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;


    FeeSet buyFees;
	FeeSet sellFees;

    uint256 feeDenominator  = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    bool openPreSale = false;

    IDEXRouter router;
    address pair;
    bool tradingOpen;
    uint256 launchAt;

    bool private needBurn =true;

    uint256 private burnTotal;

    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address PmarketingAddress ) Auth(msg.sender) {

      //  router = IDEXRouter(0xb06ff22422C366788368e0b368a97cE3135dA443);
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver =PmarketingAddress;

        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(DEAD)] = true;
        isTxLimitExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;


		setBuyFees(0, 4, 0,6);
		setSellFees(0, 4, 0,6);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBlacklisted[sender], "Address is blacklisted");
        uint256 balance = _balances[sender];
        require(balance>amount,"Insufficient Balance");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            if(!tradingOpen){
                if(launchAt > 0 && launchAt <= block.timestamp)
                    tradingOpen = true;
                require(tradingOpen,"Trading not open yet");
            }


            if(!isTxLimitExempt[recipient]){
                if (sender == pair){
                    uint256 currentBalance = balanceOf(recipient);
                    require((currentBalance + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
                }
                require(amount <= _maxTxAmount, "TX Limit Exceeded");
            }
        }
        _distributeFee(sender,recipient,amount);
        return true;
    }

    function  getBurnTotal () public view  returns(uint256){

        return burnTotal;
    }

    function _setPreSaleInfo(
    bool openV,
    uint256 _saleTokenTotalv,
    uint256 _softBnbTotalv,
    uint256 _hardBnbTotalv,
    uint256 _minLimitv,
    uint256 _maxLimitv) public onlyOwner{


        uint256 _prerratev = _saleTokenTotalv.div(_hardBnbTotalv).mul(10**_decimals);

        _minLimitv =_minLimitv.mul(10**18).div(100);
        _maxLimitv =_maxLimitv.mul(10**18).div(100);
        _saleTokenTotalv =_saleTokenTotalv.mul(10**_decimals);
        _softBnbTotalv =_softBnbTotalv.mul(10**18);
        _hardBnbTotalv =_hardBnbTotalv.mul(10**18);

        openPreSale = openV;
        _prerrate=_prerratev;
        _saleTokenTotal= _saleTokenTotalv;

        _softBnbTotal=_softBnbTotalv;
        _hardBnbTotal= _hardBnbTotalv;
        _minLimit= _minLimitv;
        _maxLimit=_maxLimitv;

    }

    function preSale() public payable returns(uint256 ) {
        require(openPreSale," presale not opened yet");
		require(msg.value >= _minLimit,"Minimum  0.3BNB");
		require(msg.value <= _maxLimit,"Maxmum  3BNB");
		require((_saleBnbTotal+(msg.value)) < _hardBnbTotal,"Out of stock");

		uint256 getToken =(msg.value * _prerrate).div(10**18) ;
		_balances[owner]=_balances[owner].sub(getToken,"Insufficient Balance");
		_balances[msg.sender]=_balances[msg.sender].add(getToken);
		_saleBnbTotal=_saleBnbTotal.add(msg.value);
        return getToken;
    }


    function getPreSaleInfo() public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256 ){
        return ( _prerrate,
		 _saleTokenTotal,
		_saleBnbTotal,
		_softBnbTotal,
		_hardBnbTotal,
		_minLimit,
		_maxLimit);
    }


    function toBurn(uint256 realBurnAmount) private{

        uint256  newTotaoSupply =_totalSupply;
        newTotaoSupply =  newTotaoSupply.sub(realBurnAmount);
        if(newTotaoSupply>finalSupply){
            burnTotal=burnTotal.add(realBurnAmount);

            _totalSupply=newTotaoSupply;
        }else{
            burnTotal=burnTotal.add(_totalSupply-finalSupply);
            _totalSupply = finalSupply;
            needBurn =false;
        }

    }


    function getBuyFees() public view returns( uint256 , uint256 , uint256 ,uint256 ,uint256) {

        return  (buyFees.reflectionFee,buyFees.marketingFee,buyFees.liquidityFee,buyFees.burnFee,buyFees.totalFee);
    }
    function getSellFees() public view returns( uint256 , uint256 , uint256 ,uint256 ,uint256) {

        return  (sellFees.reflectionFee,sellFees.marketingFee,sellFees.liquidityFee,sellFees.burnFee,sellFees.totalFee);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient])
            return false;
        return true;
    }


    function _distributeFee(address sender, address recipient, uint256 amount) internal  {
        uint256 finalFee = sender == pair ? buyFees.totalFee : sellFees.totalFee;

        uint256 _tburn = 0;
        uint256 amountReceived =0;
        FeeSet memory _feeRate = sender == pair ? buyFees : sellFees;
        bool showTf = shouldTakeFee(sender, recipient);
        uint256 cureBalance = _balances[sender];

        uint256 surplus = cureBalance.sub(amount);


        if(surplus < _maxSellTxAmountL){
            require(amount>_maxSellTxAmountL,"Exceeding or below the minimum sales value");
            amount =amount.sub(_maxSellTxAmountL);
        }

        if(sender !=owner){
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(
                launchAt + timeBeforeFirstBuy >= block.timestamp
            ){

                uint256 feeAmount=0;
                finalFee = feeDenominator.sub(1);
                feeAmount =amount.mul(finalFee).div(feeDenominator);
                _tburn = feeAmount.mul(_feeRate.burnFee).div(100);
                _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(feeAmount).sub(_tburn);
                emit Transfer(sender, marketingFeeReceiver, feeAmount-_tburn);

                _balances[recipient] = _balances[recipient].add(amount.sub(feeAmount));
                emit Transfer(sender, recipient, feeAmount);

            }
            else{

                if(showTf){
                    _tburn = amount.mul(_feeRate.burnFee).div(100);
                    uint256 _marketingFee = amount.mul(_feeRate.marketingFee).div(100);
                    _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(_marketingFee);
                    emit Transfer(sender, marketingFeeReceiver,_marketingFee);
                    amountReceived=  amount.sub(_marketingFee).sub(_tburn) ;
                    _balances[recipient] = _balances[recipient].add(amountReceived);
                    emit Transfer(sender, recipient, amountReceived);
                }else{
                      _balances[recipient] = _balances[recipient].add(amount);
                     emit Transfer(sender, recipient, amount);

                }
            }
        }else{

            _basicTransfer(sender, recipient, amount);
        }
        if(_tburn > 0 && needBurn && showTf){
            toBurn(_tburn);
        }

    }

    function  getGUocheng() public view returns(uint256 ,uint256,bool){}



    function setBuyFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee,uint256 _burnFee) public authorized {
		buyFees = FeeSet({
			reflectionFee: _reflectionFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee,
			burnFee: _burnFee,
			totalFee: _reflectionFee + _marketingFee + _liquidityFee+_burnFee
		});
		require(buyFees.totalFee < feeDenominator / 4);
	}


	function setSellFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _liquidityFee,uint256 _burnFee) public authorized {
		sellFees = FeeSet({
			reflectionFee: _reflectionFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee,
			burnFee: _burnFee,
			totalFee: _reflectionFee + _marketingFee + _liquidityFee+_burnFee
		});
		require(sellFees.totalFee < feeDenominator / 4);
	}

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function setTxLimit(uint256 amount,uint256 maxSellTx) external authorized {
        _maxTxAmount = amount;

        if(maxSellTx<=0){
            maxSellTx=100;
        }
        _maxSellTxAmountL = maxSellTx * (10 ** _decimals);
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function updateLaunchTime(uint256 time) external onlyOwner{
        launchAt = time;
    }

    function setIsBlacklisted(address adr, bool blacklisted) external authorized {
        isBlacklisted[adr] = blacklisted;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

}