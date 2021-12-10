pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new _account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    /**
     * @dev set the owner for the first time.
     * Can only be called by the contract or deployer.
     */
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router contract interface
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

// Protocol by team BloctechSolutions.com

contract MYFITOKEN is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;

    string private _name = "MyFi-Token";
    string private _symbol = "MyFi";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 50 * 1e9 * 1e9;

    IDexRouter public pancakeRouter;
    address public pancakePair;
    address payable public marketWallet;
    address payable public payoutWallet;

    uint256 public _maxTxAmount = _totalSupply.mul(1).div(1000); // should be 0.1% percent per transaction
    bool public swapAndLiquifyEnabled = false; // should be true to turn on to liquidate the pool
    bool public feeStatus = false;
    bool inSwapAndLiquify = false;

    uint256 public _liquidityFee = 20; // 2% will be added to the liquidity pool

    uint256 public _marketFee = 30; // 3% will be added to marketing wallet

    uint256 public _giveawayFee = 100; // 10% will be added to payout wallet

    uint256 _totalFeePerTx = 150; // 15% by default

    uint256 minTokenNumberToSell = _totalSupply.div(100000); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 coolDownMultiplier = 200; // tax fee will be 200% during cooldown
    uint256 coolDownTriggeredAt;
    uint256 coolDownDuration = 5 minutes;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address payable _marketWallet, address payable _payoutWallet) {
        _balances[owner()] = _totalSupply;
        marketWallet = _marketWallet;
        payoutWallet = _payoutWallet;

        IDexRouter _pancakeRouter = IDexRouter(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new token
        pancakePair = IDexFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        coolDownTriggeredAt = block.timestamp;

        emit Transfer(address(0), owner(), _totalSupply);
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
                "BEP20: transfer amount exceeds allowance"
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
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // for 1% input 100
    function setMaxTxPercent(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = _totalSupply.mul(maxTxAmount).div(10000);
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setFeePercent(
        uint256 liquidityFee,
        uint256 marketFee,
        uint256 giveawayFee
    ) external onlyOwner {
        _liquidityFee = liquidityFee;
        _marketFee = marketFee;
        _giveawayFee = giveawayFee;
        _totalFeePerTx = liquidityFee.add(marketFee).add(giveawayFee);
    }

    function setcoolDownMultiplier(uint256 _currentFeeMultiplierNumerator)
        external
        onlyOwner
    {
        coolDownMultiplier = _currentFeeMultiplierNumerator;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function clearBuybackMultiplier() external onlyOwner {
        coolDownTriggeredAt = 0;
    }

    function setReflectionFees(bool _state) external onlyOwner {
        feeStatus = _state;
    }

    function updateWallets(
        address payable _marketAddress,
        address payable _payoutAddress
    ) external onlyOwner {
        marketWallet = _marketAddress;
        payoutWallet = _payoutAddress;
    }

    function changeRoute(IDexRouter _router, address _pair) external onlyOwner {
        pancakeRouter = _router;
        pancakePair = _pair;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function getSellFee() public view returns (uint256) {
        uint256 remainingTime = coolDownTriggeredAt.add(coolDownDuration).sub(
            block.timestamp
        );
        uint256 feeIncrease = _totalFeePerTx
            .mul(coolDownMultiplier)
            .div(100)
            .sub(_totalFeePerTx);
        return
            _totalFeePerTx.add(
                feeIncrease.mul(remainingTime).div(coolDownDuration)
            );
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(
                amount <= _maxTxAmount,
                "BEP20: transfer amount exceeds the maxTxAmount."
            );
        }

        // swap and liquify on wallet to wallet transfer
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || feeStatus) {
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
        uint256 _fee;
        // selling handler
        if (recipient == pancakePair && takeFee) {
            if (coolDownTriggeredAt.add(coolDownDuration) > block.timestamp) {
                _fee = amount.mul(getSellFee()).div(1000);
                coolDownTriggeredAt = block.timestamp;
            } else {
                _fee = amount.mul(_totalFeePerTx).div(1000);
            }

            _balances[sender] = _balances[sender].add(amount);
            _balances[recipient] = _balances[recipient].add(amount.sub(_fee));

            emit Transfer(sender, recipient, amount.sub(_fee));

            _takeAllFee(sender, _fee);
        }
        // buying handler
        else if (sender == pancakePair && takeFee) {
            _fee = amount.mul(_totalFeePerTx).div(1000);
            _balances[sender] = _balances[sender].add(amount);
            _balances[recipient] = _balances[recipient].add(amount.sub(_fee));

            emit Transfer(sender, recipient, amount.sub(_fee));

            _takeAllFee(sender, _fee);
        }
        // wallet to wallet handler
        else if (
            sender != pancakePair && recipient != pancakePair && takeFee
        ) {
            _fee = amount.mul(900).div(1000);
            _balances[sender] = _balances[sender].add(amount);
            _balances[recipient] = _balances[recipient].add(amount.sub(_fee));

            emit Transfer(sender, recipient, amount.sub(_fee));

            _takeAllFee(sender, _fee);
        } 
        // excluded from fee handler
        else {
            _balances[sender] = _balances[sender].add(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeAllFee(address sender, uint256 fee) internal {
        _balances[address(this)] = _balances[address(this)].add(fee);

        emit Transfer(sender, address(this), fee);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            shouldSell &&
            from != pancakePair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(pancakePair)) // swap 1 time
        ) {
            // approve contract
            _approve(
                address(this),
                address(pancakeRouter),
                contractTokenBalance
            );

            uint256 liquidtyPercent = _liquidityFee.mul(1e4).div(_totalFeePerTx).div(
                2
            );
            uint256 marketPercent = _marketFee.mul(1e4).div(_totalFeePerTx);
            uint256 payoutPercent = _giveawayFee.mul(1e4).div(_totalFeePerTx);

            // add liquidity
            // split the contract balance into 2 pieces

            uint256 otherPiece = contractTokenBalance.mul(liquidtyPercent).div(1e4);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherPiece
            );

            // now is to lock into staking pool
            Utils.swapTokensForEth(
                address(pancakeRouter),
                tokenAmountToBeSwapped
            );

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract

            uint256 totalPercent = liquidtyPercent.add(marketPercent).add(payoutPercent);
            uint256 balanceBnb = address(this).balance;

            uint256 bnbToBeAddedToLiquidity = balanceBnb.mul(liquidtyPercent).div(
                totalPercent
            );

            // add liquidity to pancake
            Utils.addLiquidity(
                address(pancakeRouter),
                owner(),
                otherPiece,
                bnbToBeAddedToLiquidity
            );

            // add funds to marketing wallet & payout wallet
            payoutWallet.transfer(balanceBnb.mul(payoutPercent).div(totalPercent));
            marketWallet.transfer(balanceBnb);

            emit SwapAndLiquify(tokenAmountToBeSwapped, balanceBnb, otherPiece);
        }
    }
}

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter pancakeRouter = IDexRouter(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDexRouter pancakeRouter = IDexRouter(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
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