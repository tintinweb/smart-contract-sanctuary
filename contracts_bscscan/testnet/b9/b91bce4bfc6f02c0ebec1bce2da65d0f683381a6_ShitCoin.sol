/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;


interface IBEP20 {
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


interface IdexFacotry {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


interface IDexRouter {
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
        this; 
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

contract ShitCoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;

    string private _name = "ShibaMy";
    string private _symbol = "SMY";
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 21 * 1e6 * 1e8;

    IDexRouter public dexRouter;
    address public dexPair;
    address payable public stakingPool;
    address payable public devWallet;

    uint256 public minTokenToSwap = 100000 * 1e8; // 100K amount will trigger swap and distribute
    uint256 public maxBuy = _totalSupply.mul(5).div(1000); // 0.50 % max buy
    uint256 public maxSell = _totalSupply.mul(5).div(1000); // 0.50 % max sell
    uint256 public percentDivider = 1000;
    uint256 public _launchTime; // can be set only once

    bool public distributeAndLiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    //buying taxes
    uint256 public stakingFeeOnBuying = 10; // 1% will be added to the STC staking address
    uint256 public devFeeOnBuying = 10; // 1% will be added to the dev address
    uint256 public liquidityFeeOnBuying = 40; // 4% will be added to the liquidity

    //selling taxes
    uint256 public stakingFeeOnSelling = 20; // 2% will be added to the STC staking address
    uint256 public devFeeOnSelling = 10; // 1% will be added to the dev address
    uint256 public liquidityFeeOnSelling = 60; // 6% will be added to the liquidity

    uint256 lpFeeCounter = 0;
    uint256 devFeeCounter = 0;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;

        IDexRouter _pancakeRouter = IDexRouter(
            // miannet >>
             //0x10ED43C718714eb63d5aA57B78B54704E256024E
            // // testnet >>
             0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new STC
        dexPair = IdexFacotry(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive BNB from dexRouter when swapping
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
                "STC: transfer amount exceeds allowance"
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
                "STC: decreased allowance below zero"
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

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        distributeAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _stakingPool,
        address payable _devWallet
    ) external onlyOwner {
        // include in fee older address
        _isExcludedFromFee[stakingPool] = false;
        _isExcludedFromFee[devWallet] = false;

        stakingPool = _stakingPool;
        devWallet = _devWallet;

        // exclude from fee new address
        _isExcludedFromFee[stakingPool] = true;
        _isExcludedFromFee[devWallet] = true;
    }

    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "STC: Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        distributeAndLiquifyStatus = true;
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                stakingFeeOnBuying.add(devFeeOnBuying).add(liquidityFeeOnBuying)
            )
            .div(percentDivider);
        return fee;
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                stakingFeeOnSelling.add(devFeeOnSelling).add(
                    liquidityFeeOnSelling
                )
            )
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "STC: approve from the zero address");
        require(spender != address(0), "STC: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "STC: transfer from the zero address");
        require(to != address(0), "STC: transfer to the zero address");
        require(amount > 0, "STC: Amount must be greater than zero");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(
                balanceOf(from) > amount,
                "STC: Balance must be greater than Transfer amount"
            );

            if (!_tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "STC: Trading is not enabled yet"
                );
            }
        }

        // swap and liquify
        distributeAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax,stakingPool fee, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (sender == dexPair && takeFee) {
            uint256 allFee = totalBuyFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeStakingPoolFeeOnBuying(sender, amount);
            _takeDevFeeOnBuying(sender, amount);
            _takeliquidityFeeOnBuying(sender, amount);
        } else if (recipient == dexPair && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeStakingFeeOnSelling(sender, amount);
            _takeLiquidityFeeOnSelling(sender, amount);
            _takeDevFeeOnSelling(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeStakingPoolFeeOnBuying(address sender, uint256 amount)
        internal
    {
        uint256 fee = amount.mul(stakingFeeOnBuying).div(percentDivider);
        _balances[stakingPool] = _balances[stakingPool].add(fee);

        emit Transfer(sender, stakingPool, fee);
    }

    function _takeDevFeeOnBuying(address sender, uint256 amount) internal {
        uint256 _devFee = amount.mul(devFeeOnBuying).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_devFee);

        emit Transfer(sender, address(this), _devFee);
    }

    function _takeliquidityFeeOnBuying(address sender, uint256 amount)
        internal
    {
        uint256 _lpFee = amount.mul(liquidityFeeOnBuying).div(percentDivider);
        lpFeeCounter = lpFeeCounter.add(_lpFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee);

        emit Transfer(sender, address(this), _lpFee);
    }

    function _takeStakingFeeOnSelling(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(stakingFeeOnSelling).div(percentDivider);
        _balances[stakingPool] = _balances[stakingPool].add(fee);

        emit Transfer(sender, stakingPool, fee);
    }

    function _takeDevFeeOnSelling(address sender, uint256 amount) internal {
        uint256 _devFee = amount.mul(devFeeOnSelling).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_devFee);

        emit Transfer(sender, address(this), _devFee);
    }

    function _takeLiquidityFeeOnSelling(address sender, uint256 amount)
        internal
    {
        uint256 _lpFee = amount.mul(liquidityFeeOnSelling).div(percentDivider);
        lpFeeCounter = lpFeeCounter.add(_lpFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee);

        emit Transfer(sender, address(this), _lpFee);
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
            from != dexPair &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            uint256 halfLiquidity = lpFeeCounter.div(2);
            uint256 otherHalfLiquidity = lpFeeCounter.sub(halfLiquidity);

            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherHalfLiquidity
            );

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 deltaBalance = address(this).balance;
            uint256 bnbToBeAddedToLiquidity = deltaBalance
                .mul(halfLiquidity)
                .div(tokenAmountToBeSwapped);
            uint256 bnbForDev = deltaBalance.sub(bnbToBeAddedToLiquidity);

            // sending bnb to development wallet
            if (bnbForDev > 0) devWallet.transfer(bnbForDev);

            // add liquidity to Dex
            if (bnbToBeAddedToLiquidity > 0) {
                Utils.addLiquidity(
                    address(dexRouter),
                    owner(),
                    otherHalfLiquidity,
                    bnbToBeAddedToLiquidity
                );

                emit SwapAndLiquify(
                    halfLiquidity,
                    bnbToBeAddedToLiquidity,
                    otherHalfLiquidity
                );
            }

            // Reset all fee counters
            lpFeeCounter = 0;
            devFeeCounter = 0;
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
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
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
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