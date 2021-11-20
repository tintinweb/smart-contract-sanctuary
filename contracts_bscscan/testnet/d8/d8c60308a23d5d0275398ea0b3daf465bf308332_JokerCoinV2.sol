/**
 *Submitted for verification at BscScan.com on 2021-11-19
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
interface IPancakeRouter02 {
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
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(
            block.timestamp > _lockTime,
            "Contract is locked until defined days"
        );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
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

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address payable public jokerSpinWallet;
    address payable public nftStakingWallet;
    address payable public marketWallet;
    address payable public devWallet;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public maxTxAmount = _totalSupply.mul(2).div(100); // should be 0.2% percent per transaction
    uint256 public minTokenToSwap = 1000000 * 1e9; // 1M amount will trigger swap and distribute
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

    uint256 liquidityFeeCounter; 
    uint256 marketFeeCounter;
    uint256 devFeeCounter;

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

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            // miannet >> 0x10ED43C718714eb63d5aA57B78B54704E256024E
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new Joker
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
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
        _isExcludedFromMaxTx[deadAddress] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive BNB from pancakeRouter when swapping
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

    function setPancakeRouter(IPancakeRouter02 _router, address _pair)
        external
        onlyOwner
    {
        pancakeRouter = _router;
        pancakePair = _pair;
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
            _account != address(pancakeRouter),
            "JOKER: We can not blacklist pancakeRouter"
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
                    from != pancakePair && to != pancakePair,
                    "JOKER: Trading is not enabled yet"
                );
            }

            if (
                block.timestamp < _launchTime + antiSnipingTime &&
                from != address(pancakeRouter)
            ) {
                if (from == pancakePair) {
                    _isSniper[to] = true;
                } else if (to == pancakePair) {
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
        if (sender == pancakePair && takeFee) {
            uint256 allFee = totalBuyFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(_msgSender(), recipient, tTransferAmount);

            _takeJokerSpinFeeOnBuying(amount);
            _takeNftStakingFeeOnBuying(amount);
            _takeReaminingFeeOnBuying(amount);
        } else if (recipient == pancakePair && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeJokerSpinFeeOnSelling(amount);
            _takeRemainingFeeOnSelling(amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(_msgSender(), recipient, amount);
        }
    }

    function _takeJokerSpinFeeOnBuying(uint256 amount) internal {
        uint256 fee = amount.mul(spinFeeOnBuying).div(percentDivider);
        _balances[jokerSpinWallet] = _balances[jokerSpinWallet].add(fee);

        emit Transfer(_msgSender(), jokerSpinWallet, fee);
    }

    function _takeNftStakingFeeOnBuying(uint256 amount) internal {
        uint256 fee = amount.mul(nftFeeOnBuying).div(percentDivider);
        _balances[nftStakingWallet] = _balances[nftStakingWallet].add(fee);

        emit Transfer(_msgSender(), nftStakingWallet, fee);
    }

    function _takeReaminingFeeOnBuying(uint256 amount) internal {
        uint256 _lpFee = amount.mul(liquidityFeeOnBuying).div(percentDivider);
        liquidityFeeCounter = liquidityFeeCounter.add(_lpFee);
        uint256 _marketFee = amount.mul(marketFeeOnBuying).div(percentDivider);
        marketFeeCounter = marketFeeCounter.add(_marketFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee).add(_marketFee);

        emit Transfer(_msgSender(), address(this), _lpFee.add(_marketFee));
    }

    function _takeJokerSpinFeeOnSelling(uint256 amount) internal {
        uint256 fee = amount.mul(spinFeeOnSelling).div(percentDivider);
        _balances[jokerSpinWallet] = _balances[jokerSpinWallet].add(fee);

        emit Transfer(_msgSender(), jokerSpinWallet, fee);
    }

    function _takeRemainingFeeOnSelling(uint256 amount) internal {
        uint256 _lpFee = amount.mul(liquidityFeeOnSelling).div(percentDivider);
        liquidityFeeCounter = liquidityFeeCounter.add(_lpFee);
        uint256 _marketFee = amount.mul(marketFeeOnSelling).div(percentDivider);
        marketFeeCounter = marketFeeCounter.add(_marketFee);
        uint256 _devFee = amount.mul(devFeeOnSelling).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee).add(_marketFee).add(_devFee);

        emit Transfer(_msgSender(), address(this), _lpFee.add(_marketFee).add(_devFee));
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
            from != pancakePair &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && to == address(pancakePair)) // swap 1 time
        ) {
            // only sell for minTokenToSwap
            contractTokenBalance = minTokenToSwap;
            // approve contract
            _approve(
                address(this),
                address(pancakeRouter),
                contractTokenBalance
            );

            // split the contract balance into 4 pieces
            uint256 totalPercent = liquidityFeeCounter
                .add(marketFeeCounter)
                .add(devFeeCounter);

            uint256 lpPercent = liquidityFeeCounter
                .mul(1e4)
                .div(totalPercent)
                .div(2);
            uint256 marketPercent = marketFeeCounter.mul(1e4).div(
                totalPercent
            );
            uint256 devPercent = devFeeCounter
                .mul(1e4)
                .div(totalPercent);

            uint256 otherPiece = contractTokenBalance.mul(lpPercent).div(1e4);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherPiece
            );

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(
                address(pancakeRouter),
                tokenAmountToBeSwapped
            );

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 deltaBalance = address(this).balance;

            totalPercent = lpPercent.add(marketPercent).add(
                devPercent
            );

            uint256 bnbToBeAddedToLiquidity = deltaBalance.mul(lpPercent).div(
                totalPercent
            );

            // add liquidity to Dex
            Utils.addLiquidity(
                address(pancakeRouter),
                owner(),
                otherPiece,
                bnbToBeAddedToLiquidity
            );

            // sending bnb to market wallet
            marketWallet.transfer(
                deltaBalance.mul(marketPercent).div(totalPercent)
            );

            // sending bnb to development wallet
            devWallet.transfer(
                deltaBalance.mul(devPercent).div(totalPercent)
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                deltaBalance,
                otherPiece
            );
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
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