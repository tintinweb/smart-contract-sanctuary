/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Babyshibnobi is Context, IERC20, Ownable {
    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;

    address[] private _excluded;

    mapping (address => bool) public authorized;
    modifier onlyAuth() {
        require(authorized[msg.sender], "Only authorized users can call this function");
        _;
    }
    
    bool public swapEnabled;
    bool private swapping;
    bool public liquidityFilled;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 69000000000000000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    
    uint256 public swapTokensAtAmount = 37e20 * 10**_decimals;
    uint256 public maxTxAmount = 345e17 * 10**_decimals;
    uint256 public maxWalletAmount = 69e19 * 10**_decimals;
    
    // Anti Dump //
    bool public antiDumpEnabled = true;
    uint256 public maxSellAmountPerCycle = 69e18 * 10**_decimals;
    uint256 public antiDumpCycle = 24 hours;
    
    struct UserLastSell  {
        uint256 amountSoldInCycle;
        uint256 firstSellTime;
    }
    mapping(address => UserLastSell) public userLastSell;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public feeRecipient;

    string private constant _name = "BabyShibnobi";
    string private constant _symbol = "BABYSHINJA";


    struct Taxes {
      uint256 rfi;
      uint256 marketing;
      uint256 liquidity;
      uint256 burn;
    }
    Taxes public transferTaxes = Taxes(5,6,2,2);
    Taxes public buyTaxes = Taxes(5,6,2,0);
    Taxes public sellTaxes = Taxes(5,6,2,2);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 rBurn;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tMarketing;
      uint256 tLiquidity;
      uint256 tBurn;
    }

    event UpdatedRouter(address oldRouter, address newRouter);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address routerAddress, address _feeRecipient) {
        
        authorized[owner()] = true;
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        excludeFromReward(pair);
        excludeFromReward(deadAddress);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeRecipient]=true;
        _isExcludedFromFee[deadAddress] = true;

        feeRecipient = _feeRecipient;

        

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, 0);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, 0);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyAuth() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyAuth() {
        require(_isExcluded[account], "Account is not excluded");
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


    function excludeFromFee(address account) public onlyAuth {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyAuth {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setTransferTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _burn) public onlyAuth {
        transferTaxes = Taxes(_rfi, _marketing, _liquidity, _burn);
    }

    function setBuyTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _burn) public onlyAuth {
        buyTaxes = Taxes(_rfi, _marketing, _liquidity, _burn);
    }

    function setSellTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _burn) public onlyAuth {
        sellTaxes = Taxes(_rfi, _marketing, _liquidity, _burn);
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }
    
    function _takeBurn(uint256 rBurn, uint256 tBurn) private{
        totFeesPaid.burn +=tBurn;

        if(_isExcluded[deadAddress])
        {
            _tOwned[deadAddress]+=tBurn;
        }
        _rOwned[deadAddress] +=rBurn;
    }

    function _getValues(uint256 tAmount, bool takeFee, uint8 code) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, code);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rMarketing, to_return.rLiquidity, to_return.rBurn) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, uint8 code) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        Taxes memory temp;
        if(code == 0) temp = transferTaxes;
        else if(code == 1) temp = buyTaxes;
        else temp = sellTaxes;
        
        s.tRfi = tAmount*temp.rfi/100;
        s.tMarketing = tAmount*temp.marketing/100;
        s.tLiquidity = tAmount*temp.liquidity/100;
        s.tBurn = tAmount*temp.burn/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tMarketing-s.tLiquidity-s.tBurn;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rMarketing, uint256 rLiquidity, uint256 rBurn) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rBurn = s.rBurn*currentRate;
        rTransferAmount =  rAmount-rRfi-rMarketing-rLiquidity-rBurn;
        return (rAmount, rTransferAmount, rRfi,rMarketing,rLiquidity, rBurn);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(liquidityFilled ,"Liquidity has not been added yet");
            if(to != pair) require(balanceOf(to) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
        }
        if(antiDumpEnabled){
            if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping && from != pair){
                require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");

                bool newCycle = block.timestamp - userLastSell[from].firstSellTime >= antiDumpCycle;
                if(!newCycle){
                    require(userLastSell[from].amountSoldInCycle + amount <= maxSellAmountPerCycle, "You are exceeding maxSellAmountPerCycle");
                    userLastSell[from].amountSoldInCycle += amount;
                }
                else{
                    require(amount <= maxSellAmountPerCycle, "You are exceeding maxSellAmountPerCycle");
                    userLastSell[from].amountSoldInCycle = amount;
                    userLastSell[from].firstSellTime = block.timestamp;
                }
            }
        }
        

        if(balanceOf(from) - amount <= 10 *  10**decimals()) amount -= (10 * 10**decimals() + amount - balanceOf(from));
        
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }

        uint8 code = 0; 

        if(to == pair) code = 2;
        else if(from == pair) code = 1;

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]), code);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, uint8 code) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee, code);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0){
            _takeMarketing(s.rMarketing, s.tMarketing);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, deadAddress, s.tBurn);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity + s.tMarketing);
        
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
       // Split the contract balance into halves
        uint256 denominator = (sellTaxes.liquidity + sellTaxes.marketing ) * 2;
        uint256 tokensToAddLiquidityWith = tokens * sellTaxes.liquidity / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - sellTaxes.liquidity);
        uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.liquidity;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
        if(marketingAmt > 0){
            payable(feeRecipient).sendValue(marketingAmt);
        }

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function confirmLiquidityFilled() external onlyAuth{
        liquidityFilled = true;
    }

    function updateFeeRecipient(address newWallet) external onlyAuth{
        feeRecipient = newWallet;
        _isExcludedFromFee[feeRecipient];
    }

    function updateMaxTxAmount(uint256 amount) external onlyAuth{
        maxTxAmount = amount * 10**_decimals;
    }

    function updateMaxWalletBalance(uint256 amount) external onlyAuth{
        maxWalletAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyAuth{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyAuth{
        swapEnabled = _enabled;
    }

    function updateAntiDump(uint256 _maxSellAmountPerCycle, uint256 timeInMinutes, bool _enabled) external onlyAuth{
        antiDumpCycle = timeInMinutes * 1 minutes;
        maxSellAmountPerCycle = _maxSellAmountPerCycle * 10**_decimals;
        antiDumpEnabled = _enabled;
    }

    function updateAuthorized(address account, bool state) external onlyAuth{
        if(state == false) require(account != owner(), "Owner can't be removed");
        authorized[account] = state;
    }

    function setAntibot(address account, bool state) external onlyAuth{
        require(_isBot[account] != state, 'Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyAuth{
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyAuth{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    

    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyAuth{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out catecoin from this smart contract
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyAuth {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}