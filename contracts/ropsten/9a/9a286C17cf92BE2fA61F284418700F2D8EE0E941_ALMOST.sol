/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier:MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Factory contract interface
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface uniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract  ALMOST is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;
    mapping(address => bool) public _isSniper;

    string private _name = "Almost";
    string private _symbol = "Almost";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 500000 * 1e9 * 1e9;

    uniswapRouter public UniSwapRouter;
    address public UniSwapPair;
    address payable public marketWallet;
    address payable public devWallet;
    address payable public liqWallet;
  

    uint256 public maxTxAmount = _totalSupply.mul(1).div(100); // should be 1% percent per transaction
    uint256 public minTokenToSwap = 100000 * 1e9; // 1 lacs amount will trigger swap and distribute
   
    uint256 public _launchTime; // can be set only once
    uint256 public antiSnipingTime = 35 seconds;

    bool public LiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.
 
    uint256 public marketFee = 4; // 4% will be added to the market address
    uint256 public liquidityFee = 2; // 2% will be added to the liquidity
    uint256 public devFee = 4; // 4% will be added to the development address
    uint256 public maxHoldingLimit = _totalSupply.mul(1).div(100);
   

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address payable _marketWallet,
        address payable _devWallet,
	address payable _liqWallet
    ) {
        _balances[owner()] = _totalSupply;
        marketWallet = _marketWallet;
        devWallet = _devWallet;
	liqWallet = _liqWallet;

        uniswapRouter _uniSwapRouter = uniswapRouter(
             
         0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //uniswap router address
        );
        // Create a pancake pair for this new Joker
        UniSwapPair = IUniswapV2Factory(_uniSwapRouter.factory()).createPair(
            address(this),
            _uniSwapRouter.WETH()
        );

        // set the rest of the contract variables
        UniSwapRouter = _uniSwapRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
         
     
        emit Transfer(address(0), owner(), _totalSupply);
    }

    
    receive() external payable {}

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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "POIS: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "POIS: decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTx(address _address, bool value)
        external
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTxAmount = _amount;
    }

      // for 1% input 100
    function setMaxHoldingPercent(uint256 value) public onlyOwner {
        maxHoldingLimit = _totalSupply.mul(value).div(100);
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setFeePercent(
        uint256 _devFee,
        uint256 _marketFee,
        uint256 _liquidityFee
     
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketFee = _marketFee;
        devFee = _devFee;
  
    } 

    function setSwapAndLiquify(bool _value) public onlyOwner {
        LiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function UpdateMarketWalle(address payable _marketWallet) external onlyOwner {
             marketWallet = _marketWallet;
    }

    function UpdateDevWalle(address payable _devWallet)external onlyOwner{
            devWallet = _devWallet; 
    }
    
    function UpdateLiqWalle(address payable _liqWallet)external onlyOwner{
            liqWallet = _liqWallet; 
    }
  
      
    function setRouterAddress(uniswapRouter _router, address _pair)
        external
        onlyOwner
    {
        UniSwapRouter = _router;
        UniSwapPair = _pair;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "POIS: Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        LiquifyStatus = true;
    }

    function setTimeForSniping(uint256 _time) external onlyOwner {
        antiSnipingTime = _time;
    }

    function addSniperInList(address _account) external onlyOwner {
        require(
            _account != address(UniSwapRouter),
            "POIS: We can not blacklist UniSwapRouter"
        );
        require(!_isSniper[_account], "POIS: sniper already exist");
        _isSniper[_account] = true;
    }

    function removeSniperFromList(address _account) external onlyOwner {
        require(_isSniper[_account], "POIS: Not a sniper");
        _isSniper[_account] = false;
    }

    function removeStuckEth(address payable _account, uint256 _amount)
        external
        onlyOwner
    {
        _account.transfer(_amount);
    }
 
    function totalFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                liquidityFee.add(marketFee).add(devFee) 
            )
            .div(1e2);
        return fee;
    }
 

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "POIS: approve from the zero address");
        require(spender != address(0), "POIS: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "POIS: transfer from the zero address");
        require(to != address(0), "POIS: transfer to the zero address");
        require(amount > 0, "POIS: Amount must be greater than zero");
        require(!_isSniper[to], "POIS: Sniper detected");
        require(!_isSniper[from], "POIS: Sniper detected");
        if(from == UniSwapPair && to != owner()){
            require(balanceOf(to).add(amount) <= maxHoldingLimit," POIS: Max Holding limit reached");
        }
        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(amount <= maxTxAmount, "POIS: amount exceeded max limit");
           

            if (!_tradingOpen) {
                require(
                    from != UniSwapPair && to != UniSwapPair,
                    "POIS: Trading is not enabled yet"
                );
            }

            if (
                block.timestamp < _launchTime + antiSnipingTime &&
                from != address(UniSwapRouter)
            ) {
                if (from == UniSwapPair) {
                    _isSniper[to] = true;
                } else if (to == UniSwapPair) {
                    _isSniper[from] = true;
                }
            }
        }

        // swap and liquify
        distributeAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            !feesStatus
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if ((sender == UniSwapPair || recipient == UniSwapPair) && takeFee) {
            uint256 allFee = totalFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeLiquidityFee(sender,amount);
            _takeMarketFee(sender,amount);
            _takeDevFee(sender,amount);
        }  
        else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
             
            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeLiquidityFee(address sender,uint256 amount) internal {
        uint256 fee = amount.mul(liquidityFee).div(1e2);
        _balances[address(liqWallet)] = _balances[address(liqWallet)].add(fee);

        emit Transfer(sender, address(liqWallet), fee);
    }

    function _takeMarketFee(address sender,uint256 amount) internal {
        uint256 fee = amount.mul(marketFee).div(1e2);
        _balances[address(marketWallet)] = _balances[address(marketWallet)].add(fee);

        emit Transfer(sender, address(marketWallet), fee);
    }
    function _takeDevFee(address sender,uint256 amount) internal {
        uint256 fee = amount.mul(devFee).div(1e2);
        _balances[address(devWallet)] = _balances[address(devWallet)].add(fee);

        emit Transfer(sender, address(devWallet), fee);
    }
 

    function distributeAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is Dex pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap;

        if (
            shouldSell &&
            from != UniSwapPair &&
            LiquifyStatus &&
            !(from == address(this) && to == address(UniSwapPair)) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(UniSwapRouter), contractTokenBalance);

            uint256 otherPiece = contractTokenBalance.div(2);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(otherPiece);
            
            uint256 initialBalance = address(this).balance;

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(UniSwapRouter), tokenAmountToBeSwapped);

            uint256 ethToBeAddedToLiquidity = address(this).balance.sub(initialBalance);

            // add liquidity to uniswap
            Utils.addLiquidity(address(UniSwapRouter), owner(), otherPiece, ethToBeAddedToLiquidity);
            
            emit SwapAndLiquify(tokenAmountToBeSwapped, ethToBeAddedToLiquidity, otherPiece);
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        uniswapRouter UniSwapRouter = uniswapRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniSwapRouter.WETH();

        // make the swap
        UniSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        uniswapRouter UniSwapRouter = uniswapRouter(routerAddress);

        // add the liquidity
        UniSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}