pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IFactory.sol";
import "./IRouter.sol";

/**
 * $BSFM
 *
 * BabySafeMoon stands for transparent, high-quality and healthy financial plans
 * and collaboration. Integrity, transparency, and trust are what BSFM stands by.
 *
 * - Goal -> Reach a dollar with financially literate plans inspired by stock market economics.
 *
 * Community-driven token with multi-sigs for representatives across multiple projects and
 * most importantly, __The Community__.
 *
 * @dev (audit and anti-rug community) please check and verify the code to put the investors,
 * the community, and our astronauts. We want to ensure the highest standards only.
 *
 * @dev License should be: SPDX
 *
 * Off-chain Mechanics: Cruise Control (Dynamic Tax Protocol: V2)
 *
 * Please see whitepaper for the full picture (could require final updates before launch
 * to match the code due to rapid improvements, should match atleast 90%. If mismatches occur,
 * we will update them accordingly, please provide constructive feedback :thumbsup:).
 *
 * Gitbook Whitepaper: https://baby-safemoon.gitbook.io/babysafemoon/
 *
 *                    -- Godspeed --
 */

contract BabySafeMoon is Context, Ownable, IERC20 {
    using Address for address;
    using Address for address payable;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;
    
    mapping(address => bool) private _isBadActor;


    mapping (address => bool) private _isExcludedFromFee;


    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;


    string private _name = "BabySafeMoon";
    string private _symbol = "BSFM";
    uint8 private _decimals = 9;

    struct feeRatesStruct {
      uint256 taxFee;
      uint256 devFee;
      uint256 marketingFee;
      uint256 giveawaysFee;
      uint256 iBNBPoolFee;
      uint256 swapFee;
      uint256 totFees;
    }
    
    feeRatesStruct public buyFees = feeRatesStruct(
     {taxFee: 5000,
      devFee: 1337,
      marketingFee: 1000,
      giveawaysFee: 663,
      iBNBPoolFee: 2000,
      swapFee: 5000, // devFee+marketingFee+giveawaysFee+iBNBPoolFee
      totFees: 15
    });

    feeRatesStruct public sellFees = feeRatesStruct(
     {taxFee: 5000,
      devFee: 1337,
      marketingFee: 1000,
      giveawaysFee: 663,
      iBNBPoolFee: 2000,
      swapFee: 5000, // devFee+marketingFee+giveawaysFee+iBNBPoolFee
      totFees: 15
    });

    feeRatesStruct private appliedFees = buyFees; //default value
    feeRatesStruct private previousFees;

    struct antiwhale {
      uint256 selling_threshold;//this is value/1000 %
      uint256 extra_tax; //this is value %
    }

    antiwhale[3] public antiwhale_measures;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rFee;
      uint256 rSwap;
      uint256 tTransferAmount;
      uint256 tFee;
      uint256 tSwap;
    }

    
    uint256 public maxSellPerDay = _tTotal/1000;
    
    address payable public marketingWallet = payable(0x76FdF77F062A85eFd9AFc166A0f47c6CAf21F65B);
    address payable public devWallet = payable(0xd87F855A3F595cEAe2e5DA7CB51998b4Be90Ba35);
    address payable public giveawaysWallet = payable(0x6897f1bf2B854E7c0d3E3B7c757120Ef9A036BC0);
    address payable public iBNBPool = payable(0x830F7A104a3dF30879D526031D57DAa44BF85686);

    IRouter public pancakeRouter;
    address public pancakePair;
    
    bool inSwap;
    bool public swapEnabled = true;
    uint256 private minTokensToSwap = 50000 * 10**9;
    uint256 public maxTxAmount = _tTotal/100;


    event swapEnabledUpdated(bool enabled);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;
        

        IRouter _pancakeRouter = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        pancakePair = IFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[giveawaysWallet] = true;
        _isExcludedFromFee[iBNBPool] = true;
        _isExcludedFromFee[address(this)] = true;
        
        /* will be excluded after the airdrop
        _isExcluded[owner()] = true;
        _isExcluded[marketingWallet] = true;
        _isExcluded[devWallet] = true;
        _isExcluded[giveawaysWallet] = true;
        _isExcluded[iBNBPool] = true;
        _isExcluded[0x000000000000000000000000000000000000dEaD] = true;

        _excluded.push(owner());
        _excluded.push(marketingWallet);
        _excluded.push(devWallet);
        _excluded.push(giveawaysWallet);
        _excluded.push(iBNBPool);
        _excluded.push(0x000000000000000000000000000000000000dEaD); */

        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*25/100000, extra_tax: 1});//0.025% of initial supply
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*50/100000, extra_tax: 2});//0.05% of initial supply
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*75/100000, extra_tax: 3});//0.075% of initial supply

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }


    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }


    function totalFeesCharged() public view returns (uint256) {
        return _tFeeTotal;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory s = _getValues(tAmount, false);
        _rOwned[sender] -= s.rAmount;
        _rTotal -= s.rAmount;
        _tFeeTotal += tAmount;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            valuesFromGetValues memory s = _getValues(tAmount, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }


    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function excludeFromReward(address[] memory accounts) public onlyOwner() {
        uint256 length = accounts.length;
        for(uint256 i=0;i<length;i++)
        {
        require(!_isExcluded[accounts[i]], "Account is already excluded");
        if(_rOwned[accounts[i]] > 0) {
            _tOwned[accounts[i]] = tokenFromReflection(_rOwned[accounts[i]]);
        }
        _isExcluded[accounts[i]] = true;
        _excluded.push(accounts[i]);
        }
    }


    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
     //to recieve ETH from pancakeRouter when swaping
    receive() external payable {}


     function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal     = _rTotal-rFee;
        _tFeeTotal  = _tFeeTotal+tFee;
    }


    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rFee, to_return.rSwap) = _getRValues(to_return,tAmount, takeFee, _getRate());
        return to_return;
    }


    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tFee = tAmount*appliedFees.totFees*appliedFees.taxFee/1000000;
        s.tSwap = tAmount*appliedFees.totFees*appliedFees.swapFee/1000000;
        s.tTransferAmount = tAmount-s.tFee-s.tSwap;
        return s;
    }


    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount*currentRate;
        if(!takeFee)
        {
            return (rAmount,rAmount,0,0);
        }
        uint256 rFee = s.tFee*currentRate;
        uint256 rSwap = s.tSwap*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rSwap;
        return (rAmount, rTransferAmount, rFee, rSwap);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }


    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 length = _excluded.length;    
        for (uint256 i = 0; i < length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -=_rOwned[_excluded[i]];
            tSupply -=_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeSwapFees(uint256 rSwap, uint256 tSwap) private {

        _rOwned[address(this)] +=rSwap;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] +=tSwap;
    }
    
    
            //////////////////////////
           /// Setters functions  ///
          //////////////////////////
        
   function setMarketingWallet(address payable _address) external onlyOwner returns (bool){
        marketingWallet = _address;
        _isExcludedFromFee[marketingWallet] = true;
        return true;
    }
    function setDevWallet(address payable _address) external onlyOwner returns (bool){
        devWallet = _address;
        _isExcludedFromFee[devWallet] = true;
        return true;
    }
    function setGiveawaysWallet(address payable _address) external onlyOwner returns (bool){
        giveawaysWallet = _address;
        _isExcludedFromFee[giveawaysWallet] = true;
        return true;
    }
    function setIBNBPool(address payable _address) external onlyOwner returns (bool){
        iBNBPool = _address;
        _isExcludedFromFee[iBNBPool] = true;
        return true;
    }
    
    function setBuyFees(uint256 taxFee, uint256 devFee, uint256 marketingFee, uint256 giveawaysFee, uint256 iBNBPoolFee) external onlyOwner{
        buyFees.taxFee = taxFee;
        buyFees.devFee = devFee;
        buyFees.marketingFee = marketingFee;
        buyFees.giveawaysFee = giveawaysFee;
        buyFees.iBNBPoolFee = iBNBPoolFee;
        buyFees.swapFee = devFee+marketingFee+giveawaysFee+iBNBPoolFee;
        require(buyFees.swapFee+buyFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setSellFees(uint256 sellTaxFee, uint256 sellDevFee, uint256 sellMarketingFee, uint256 sellGiveawaysFee, uint256 sellIBNBPoolFee) external onlyOwner{
        sellFees.taxFee = sellTaxFee;
        sellFees.devFee = sellDevFee;
        sellFees.marketingFee = sellMarketingFee;
        sellFees.giveawaysFee = sellGiveawaysFee;
        sellFees.iBNBPoolFee = sellIBNBPoolFee;
        sellFees.swapFee = sellDevFee+sellMarketingFee+sellGiveawaysFee+sellIBNBPoolFee;
        require(sellFees.swapFee+sellFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setTotalBuyFees(uint256 _totFees) external onlyOwner{
        buyFees.totFees = _totFees;
    }
    
    function setTotalSellFees(uint256 _totSellFees) external onlyOwner{
        sellFees.totFees = _totSellFees;
    }
    
    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellPerDay = amount * 10**9;
    }
    
    function setAntiwhaleMeasure(uint256[3] memory selling_thresholds, uint256[3] memory extra_taxes ) external onlyOwner{
        //values of selling_threshold (are values in input)/1000 % of total supply , extra taxes are expressed in %
        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*selling_thresholds[0]/100000 , extra_tax: extra_taxes[0]});
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*selling_thresholds[1]/100000 , extra_tax: extra_taxes[1]});
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*selling_thresholds[2]/100000 , extra_tax: extra_taxes[2]});
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit swapEnabledUpdated(_enabled);
    }
    
    function setNumTokensTosSwap(uint256 amount) external onlyOwner{
        minTokensToSwap = amount * 10**9;
    }
    
    function setMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**9;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

        function getAntiwhaleFee(uint256 amount) internal view returns(uint256 sell_tax) {
    
        if(amount < antiwhale_measures[0].selling_threshold) {
          sell_tax=0;
        }
        else if(amount < antiwhale_measures[1].selling_threshold) {
          sell_tax = antiwhale_measures[0].extra_tax;
        }
        else if(amount < antiwhale_measures[2].selling_threshold) {
          sell_tax = antiwhale_measures[1].extra_tax;
        }
        else { sell_tax = antiwhale_measures[2].extra_tax; }

      return sell_tax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBadActor[from] && !_isBadActor[to], "Bots are not allowed");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(amount <= maxTxAmount, 'you are exceeding maxTxAmount');
        }
        
        if(!_isExcludedFromFee[from] && to == pancakePair){
            if(block.timestamp < _firstSell[from]+24 * 1 hours){
                require(_totSells[from]+amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _totSells[from] += amount;
            }
            else{
                require(amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[from] = block.timestamp;
                _totSells[from] = amount;
            }
                
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= minTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwap &&
            from != pancakePair &&
            swapEnabled
        ) {
            contractTokenBalance = minTokensToSwap;
            swapAndSendToFees(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        bool isSale = false;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else
        {
            if(to == pancakePair){
            isSale = true;
            }
        }
             
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee, isSale);
    }
    
    function swapAndSendToFees(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 transferBalance = address(this).balance-initialBalance;
        devWallet.sendValue(transferBalance*appliedFees.devFee/appliedFees.swapFee);
        giveawaysWallet.sendValue(transferBalance*appliedFees.giveawaysFee/appliedFees.swapFee);
        iBNBPool.sendValue(transferBalance*appliedFees.iBNBPoolFee/appliedFees.swapFee);
        marketingWallet.sendValue(address(this).balance);

    }


    function swapTokensForBNB(uint256 tokenAmount) private lockTheSwap {

        // generate the pancakeswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        if(allowance(address(this), address(pancakeRouter)) < tokenAmount) {
          _approve(address(this), address(pancakeRouter), ~uint256(0));
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }


    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSale) private {
        if(takeFee){
            if(isSale)
            {
            appliedFees = sellFees;
            appliedFees.totFees += getAntiwhaleFee(_totSells[sender]);
            }
            else
            {
            appliedFees = buyFees;
            }
        }
        
        valuesFromGetValues memory s = _getValues(amount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -=amount;
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }
        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] +=s.rTransferAmount;
        
        if(takeFee)
            {
             _takeSwapFees(s.rSwap,s.tSwap);
             _reflectFee(s.rFee, s.tFee);
             emit Transfer(sender, address(this), s.tSwap);
            }
        emit Transfer(sender, recipient, s.tTransferAmount);
    }
    
            //////////////////////////
           /// Emergency functions //
          //////////////////////////


    function rescueBNBFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
    
    function manualSwap() external onlyOwner{
        uint256 tokensToSwap = balanceOf(address(this));
        swapTokensForBNB(tokensToSwap);
    }
    
    function manualSend() external onlyOwner{
        swapAndSendToFees(balanceOf(address(this)));
    }


    // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool isBadActor) external onlyOwner{
        _isBadActor[account] = isBadActor;
    }
    
    function checkBadActor(address account) public view returns(bool){
        return _isBadActor[account];
    }
    
    function setRouterAddress(address newRouter) external onlyOwner {
        require(address(pancakeRouter) != newRouter, 'Router already set');
        //give the option to change the router down the line 
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        //checks if pair already exists
        if (get_pair == address(0)) {
            pancakePair = IFactory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pancakePair = get_pair;
        }
        pancakeRouter = _newRouter;
    }
    
}