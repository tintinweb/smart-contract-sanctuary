// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";
//import "./HeadShotFactory.sol";

interface IHeadShotFactory {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function addSalesInfo(uint256 category_, uint256 code_, string memory name_,
        string memory desc_, uint256 price_) external returns (bool);
    function getSalesCode(uint256 code_) external view returns (uint256);
    function getSalesPrice(uint256 code_) external view returns (uint256);
    function getTrackerSalesAddress(uint256 code_) external view returns (address);
    function addTrackerInfo(uint256 code_, address trackerAddress_) external returns (bool);
    function listSalesPart1(uint limit_, uint page_) external view returns (
        uint256[] memory,
        uint256[] memory,
        string[] memory
    );
    function listSalesPart2(uint limit_, uint page_) external view returns (
        uint256[] memory,
        string[] memory,
        uint256[] memory
    );
    function listSalesTracker(uint limit_, uint page_) external view returns (address[] memory);
}

contract HeadShot is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;
    /*
    struct SalesInfo {
        uint256 category;
        uint256 code;
        string name;
        string desc;
        uint256 price;
    }
    */
    string private constant _name = "HeadShot Token";
    string private constant _symbol = "HST";
    uint8  private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    /*
    mapping(uint256 => SalesInfo) private _salesMap;
    mapping(uint256 => address) private _trackerSalesMap;
    address[] private _trackerSalesList;
    SalesInfo[] private _salesList;
    */
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    address public _ecosystemWalletAddress;
    address public _salesWalletAddress;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000 * (10 ** 9) * (10 ** _decimals);
    uint256 public _maxTxAmount = 1 * (10 ** 9) * (10 ** _decimals);
    uint256 private constant numTokensSellToAddToLiquidity = 100 * (10 ** 9) * (10 ** _decimals);

    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _rewardFee = 2;
    uint256 public _ecosystemFee = 4;
    uint256 public _liquidityFee = 2;

    uint256 private _previousRewardFee = _rewardFee;
    uint256 private _previousEcosystemFee = _ecosystemFee;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IHeadShotFactory public headShotFactory;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public startTrading = false;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //NEW V2 ropsten
        address hsFactoryAddress = 0xB96ef3e8e341f829abFa200a39D543e61F7677b8; //NEW V2 ropsten
        //address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //NEW V2 mainnet

        _rOwned[owner()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        //headShotFactory = new HeadShotFactory();
        headShotFactory = IHeadShotFactory(hsFactoryAddress);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_ecosystemWalletAddress] = true;
        _isExcludedFromFee[_salesWalletAddress] = true;

        emit Transfer(address(0), owner(), _tTotal);
        /*
        addSales(1000, 100001, "Register Ticket", "Register Ticket", 20000);
        addSales(1000, 100002, "Verify Ticket", "Verify Ticket", 40000);
        addSales(1000, 100003, "Vote Ticket", "Vote Ticket", 1000);
        */
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

    function totalSupply() public pure override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    //It allows a non excluded account to airdrop to other users.
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    //Converts an amount of tokens to reflections using the current rate.
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns(uint256) {
        require(tAmount <= _tTotal, "You cannot own more tokens than the total token supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Cannot have a personal reflection amount larger than total reflection");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeEcosystem(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10 ** 2);
    }

    function setEcosystemAddress(address payable newWallet_) public virtual onlyOwner {
        _ecosystemWalletAddress = newWallet_;
    }

    function setSalesAddress(address payable newWallet_) public virtual onlyOwner {
        _salesWalletAddress = newWallet_;
    }

    //Function to enable trading, we can't disable the trade, just enable it.
    function enableTrading() external onlyOwner() {
        startTrading = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}

    //Updates the value of the total fees paid and reduces the reflection supply to reward all holders.
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateRewardFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tCharity = calculateEcosystemFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tCharity);
        return (tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rCharity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    //Stores the liquidity fee in the contract's address
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeEcosystem(uint256 tEcosystem) private {
        uint256 currentRate =  _getRate();
        uint256 rEcosystem = tEcosystem.mul(currentRate);
        _rOwned[_ecosystemWalletAddress] = _rOwned[_ecosystemWalletAddress].add(rEcosystem);
        if(_isExcluded[_ecosystemWalletAddress])
            _tOwned[_ecosystemWalletAddress] = _tOwned[_ecosystemWalletAddress].add(tEcosystem);
    }

    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10 ** 2);
    }

    function calculateEcosystemFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ecosystemFee).div(10 ** 2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10 ** 2);
    }

    //Removes all fees and saves them to be reinstated at a later date.
    function removeAllFee() private {
        if(_rewardFee == 0 && _liquidityFee == 0) return;

        _previousRewardFee = _rewardFee;
        _previousEcosystemFee = _ecosystemFee;
        _previousLiquidityFee = _liquidityFee;

        _rewardFee = 0;
        _ecosystemFee = 0;
        _liquidityFee = 0;
    }

    //Restores the fees to their previous values.
    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _ecosystemFee = _previousEcosystemFee;
        _liquidityFee = _previousLiquidityFee;
    }

    //Accounts which are excluded from paying txs fees. PUBLIC
    function isExcludedFromFee(address account) private view returns(bool) {
        return _isExcludedFromFee[account];
    }

    //Contains the allowances a parent account has provided to children accounts in reflections;
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: Sender cannot be the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(startTrading, "Not yet.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to the pool (Pancakeswap)
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
    *@dev buys ETH with tokens stored in this contract
    */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**
    *@dev Adds equal amount of eth and tokens to the ETH liquidity pool
    */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeEcosystem(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeEcosystem(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeEcosystem(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
    function uintToStr(uint256 value) internal pure returns (string memory str){
        if (value == 0) return "0";
        uint256 j = value;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bStr = new bytes(length);
        uint256 k = length;
        j = value;
        while (j != 0){
            bStr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bStr);
    }
    */
    function addSales(uint256 category_, uint256 code_, string memory name_,
        string memory desc_, uint256 price_) public returns (bool) {
        require(code_ != 0, "ERR");
        require(_salesWalletAddress != address(0), "ERR");
        require(headShotFactory.getSalesCode(code_) != code_, "ERR");
        address _creator = _msgSender();
        if (_creator == owner() || _creator == _ecosystemWalletAddress || _creator == _salesWalletAddress){
            /*
            SalesInfo memory salesInfo = SalesInfo(category_, code_, name_, desc_, price_.mul(10 ** _decimals));
            _salesMap[code_] = salesInfo;
            _salesList.push(salesInfo);
            */
            headShotFactory.addSalesInfo(category_, code_, name_, desc_, price_.mul(10 ** _decimals));
            //string memory codeString = uintToStr(code_);
            string memory codeString = ConvertString.toStr(code_);
            string memory trackerName = string(abi.encodePacked("HeadShotTracker_", codeString));
            string memory trackerSymbol = string(abi.encodePacked("HSTracker_", codeString));
            HeadShotTracker headShotTracker = new HeadShotTracker(trackerName, trackerSymbol);
            headShotTracker.setCode(code_);
            headShotTracker.setCategory(category_);
            headShotTracker.setTitle(name_);
            headShotTracker.setDescription(desc_);
            headShotTracker.setPrice(price_);
            address trackerAddress = address(headShotTracker);
            /*
            _trackerSalesMap[code_] = trackerAddress;
            _trackerSalesList.push(trackerAddress);
            */
            headShotFactory.addTrackerInfo(code_, trackerAddress);
            return true;
        }
        return false;
    }

    function buy(uint256 code_, uint256 count_) public returns (bool) {
        if (headShotFactory.getSalesCode(code_) == code_){
            address _buyer = _msgSender();
            uint256 _price = headShotFactory.getSalesPrice(code_);
            uint256 _totalPay = _price * count_;

            _transfer(_msgSender(), _salesWalletAddress, _totalPay);
            HeadShotTracker headShotTracker = HeadShotTracker(payable(headShotFactory.getTrackerSalesAddress(code_)));
            bool trx = headShotTracker.buy(_buyer, count_);
            return trx;
        }
        return false;
    }

    function sell(uint256 code_, uint256 count_) public returns (bool) {
        if (headShotFactory.getSalesCode(code_) == code_){
            address _buyer = _msgSender();
            uint256 _price = headShotFactory.getSalesPrice(code_);
            uint256 _totalPay = _price * count_;

            _transfer(_msgSender(), _salesWalletAddress, _totalPay);
            HeadShotTracker headShotTracker = HeadShotTracker(payable(headShotFactory.getTrackerSalesAddress(code_)));
            bool trx = headShotTracker.sell(_buyer, count_);
            return trx;
        }
        return false;
    }

    function listSalesPart1(uint limit_, uint page_) public view returns (
        uint256[] memory,
        uint256[] memory,
        string[] memory
    ) {
        return headShotFactory.listSalesPart1(limit_, page_);
    }

    function listSalesPart2(uint limit_, uint page_) public view returns (
        uint256[] memory,
        string[] memory,
        uint256[] memory
    ) {
        return headShotFactory.listSalesPart2(limit_, page_);
    }

    function listSalesTracker(uint limit_, uint page_) public view returns (
        address[] memory
    ) {
        return headShotFactory.listSalesTracker(limit_, page_);
    }

    function listSalesTrx(uint256 code_, uint limit_, uint page_) public view returns (
        uint256[] memory,
        address[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(headShotFactory.getTrackerSalesAddress(code_)));
        return headShotTracker.listTrx(limit_, page_);
    }
}