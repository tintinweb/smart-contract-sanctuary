/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

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

// Dex Factory contract interface
interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
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

contract JokerCoinV2 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;
    mapping(address => bool) public _isSniper;

    string private _name = "Joker-Coin-V2";
    string private _symbol = "JOKER";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1 * 1e11 * 1e9;

    IDexRouter public dexRouter;
    address public dexPair;
    address payable public jokerSpinWallet;
    address payable public nftStakingWallet;
    address payable public marketWallet;
    address payable public devWallet;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public maxTxAmount = _totalSupply.mul(2).div(100); // should be 0.2% percent per transaction
    uint256 public minTokenToSwap = 100000 * 1e9; // 100K amount will trigger swap and distribute
    uint256 public percentDivider = 1000;
    uint256 public _launchTime; // can be set only once
    uint256 public antiSnipingTime = 60 seconds;

    bool public distributeAndLiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public spinFeeOnBuying = 20; // 2% will be added to the joker spin address
    uint256 public nftFeeOnBuying = 20; // 2% will be added to the NFT staking address
    uint256 public marketFeeOnBuying = 20; // 2% will be added to the market address
    uint256 public liquidityFeeOnBuying = 20; // 2% will be added to the liquidity

    uint256 public spinFeeOnSelling = 20; // 2% will be added to the buyback address
    uint256 public marketFeeOnSelling = 20; // 2% will be added to the market address
    uint256 public devFeeOnSelling = 20; // 2% will be added to the development address
    uint256 public liquidityFeeOnSelling = 20; // 2% will be added to the liquidity

    uint256 liquidityFeeCounter = 0; 
    uint256 marketFeeCounter = 0;
    uint256 devFeeCounter = 0;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address payable _jokerSpinWallet,
        address payable _nftStakingWallet,
        address payable _marketWallet,
        address payable _devWallet
    ) {
        _balances[owner()] = _totalSupply;

        jokerSpinWallet = _jokerSpinWallet;
        nftStakingWallet = _nftStakingWallet;
        marketWallet = _marketWallet;
        devWallet = _devWallet;

        IDexRouter _pancakeRouter = IDexRouter(
            // // miannet >> 
            // 0x10ED43C718714eb63d5aA57B78B54704E256024E
            // testnet >>
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new Joker
        dexPair = IPancakeFactory(_pancakeRouter.factory()).createPair(
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
        _isExcludedFromMaxTx[deadAddress] = true;

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
                "JOKER: transfer amount exceeds allowance"
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
                "JOKER: decreased allowance below zero"
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

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setBuyFeePercent(
        uint256 _spinFee,
        uint256 _nftFee,
        uint256 _marketFee,
        uint256 _lpFee
    ) external onlyOwner {
        spinFeeOnBuying = _spinFee;
        nftFeeOnBuying = _nftFee;
        marketFeeOnBuying = _marketFee;
        liquidityFeeOnBuying = _lpFee;
    }

    function setSellFeePercent(
        uint256 _spinFee,
        uint256 _marketFee,
        uint256 _devFee,
        uint256 _lpFee
    ) external onlyOwner {
        spinFeeOnSelling = _spinFee;
        marketFeeOnSelling = _marketFee;
        devFeeOnSelling = _devFee;
        liquidityFeeOnSelling = _lpFee;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        distributeAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _jokerSpinWallet,
        address payable _nftStakingWallet,
        address payable _marketWallet,
        address payable _devWallet
    ) external onlyOwner {
        jokerSpinWallet = _jokerSpinWallet;
        nftStakingWallet = _nftStakingWallet;
        marketWallet = _marketWallet;
        devWallet = _devWallet;
    }

    function setPancakeRouter(IDexRouter _router, address _pair)
        external
        onlyOwner
    {
        dexRouter = _router;
        dexPair = _pair;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "JOKER: Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        distributeAndLiquifyStatus = true;
    }

    function setTimeForSniping(uint256 _time) external onlyOwner {
        antiSnipingTime = _time;
    }

    function addSniperInList(address _account) external onlyOwner {
        require(
            _account != address(dexRouter),
            "JOKER: We can not blacklist dexRouter"
        );
        require(!_isSniper[_account], "JOKER: sniper already exist");
        _isSniper[_account] = true;
    }

    function removeSniperFromList(address _account) external onlyOwner {
        require(_isSniper[_account], "JOKER: Not a sniper");
        _isSniper[_account] = false;
    }

    function removeStuckBnb(address payable _account, uint256 _amount)
        external
        onlyOwner
    {
        _account.transfer(_amount);
    }

    function removeStuckToken(
        IBEP20 _token,
        address _account,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_account, _amount);
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                nftFeeOnBuying.add(spinFeeOnBuying).add(marketFeeOnBuying).add(
                    liquidityFeeOnBuying
                )
            )
            .div(percentDivider);
        return fee;
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                spinFeeOnSelling
                    .add(devFeeOnSelling)
                    .add(marketFeeOnSelling)
                    .add(liquidityFeeOnSelling)
            )
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "JOKER: approve from the zero address");
        require(spender != address(0), "JOKER: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "JOKER: transfer from the zero address");
        require(to != address(0), "JOKER: transfer to the zero address");
        require(amount > 0, "JOKER: Amount must be greater than zero");
        require(!_isSniper[to], "JOKER: Sniper detected");
        require(!_isSniper[from], "JOKER: Sniper detected");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(amount <= maxTxAmount, "JOKER: amount exceeded max limit");

            if (!_tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "JOKER: Trading is not enabled yet"
                );
            }

            if (
                block.timestamp < _launchTime + antiSnipingTime &&
                from != address(dexRouter)
            ) {
                if (from == dexPair) {
                    _isSniper[to] = true;
                } else if (to == dexPair) {
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
        if (sender == dexPair && takeFee) {
            uint256 allFee = totalBuyFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeJokerSpinFeeOnBuying(sender, amount);
            _takeNftStakingFeeOnBuying(sender, amount);
            _takeReaminingFeeOnBuying(sender, amount);
        } else if (recipient == dexPair && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeJokerSpinFeeOnSelling(sender, amount);
            _takeRemainingFeeOnSelling(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeJokerSpinFeeOnBuying(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(spinFeeOnBuying).div(percentDivider);
        _balances[jokerSpinWallet] = _balances[jokerSpinWallet].add(fee);

        emit Transfer(sender, jokerSpinWallet, fee);
    }

    function _takeNftStakingFeeOnBuying(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(nftFeeOnBuying).div(percentDivider);
        _balances[nftStakingWallet] = _balances[nftStakingWallet].add(fee);

        emit Transfer(sender, nftStakingWallet, fee);
    }

    function _takeReaminingFeeOnBuying(address sender, uint256 amount) internal {
        uint256 _lpFee = amount.mul(liquidityFeeOnBuying).div(percentDivider);
        liquidityFeeCounter = liquidityFeeCounter.add(_lpFee);
        uint256 _marketFee = amount.mul(marketFeeOnBuying).div(percentDivider);
        marketFeeCounter = marketFeeCounter.add(_marketFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee).add(_marketFee);

        emit Transfer(sender, address(this), _lpFee.add(_marketFee));
    }

    function _takeJokerSpinFeeOnSelling(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(spinFeeOnSelling).div(percentDivider);
        _balances[jokerSpinWallet] = _balances[jokerSpinWallet].add(fee);

        emit Transfer(sender, jokerSpinWallet, fee);
    }

    function _takeRemainingFeeOnSelling(address sender, uint256 amount) internal {
        uint256 _lpFee = amount.mul(liquidityFeeOnSelling).div(percentDivider);
        liquidityFeeCounter = liquidityFeeCounter.add(_lpFee);
        uint256 _marketFee = amount.mul(marketFeeOnSelling).div(percentDivider);
        marketFeeCounter = marketFeeCounter.add(_marketFee);
        uint256 _devFee = amount.mul(devFeeOnSelling).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee).add(_marketFee).add(_devFee);

        emit Transfer(sender, address(this), _lpFee.add(_marketFee).add(_devFee));
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

            uint256 halfLiquidity = liquidityFeeCounter.div(2);
            uint256 otherHalfLiquidity = liquidityFeeCounter.sub(halfLiquidity);

            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherHalfLiquidity
            );

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 deltaBalance = address(this).balance;
            uint256 bnbToBeAddedToLiquidity = deltaBalance.mul(halfLiquidity).div(tokenAmountToBeSwapped);
            uint256 bnbFormarket = deltaBalance.mul(marketFeeCounter).div(tokenAmountToBeSwapped);
            uint256 bnbForDev = deltaBalance.sub(bnbToBeAddedToLiquidity).sub(bnbFormarket);

            // sending bnb to market wallet
            if(bnbFormarket > 0)
                marketWallet.transfer(bnbFormarket);

            // sending bnb to development wallet
            if(bnbForDev > 0)
                devWallet.transfer(bnbForDev);

            // add liquidity to Dex
            if(bnbToBeAddedToLiquidity > 0){
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
            liquidityFeeCounter = 0;
            marketFeeCounter = 0;
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