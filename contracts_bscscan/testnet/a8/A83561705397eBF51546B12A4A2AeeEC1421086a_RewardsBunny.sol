/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/*
The Contract is Owned By: https://rewardsbunny.com/
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // R e w a r d s B u n n y 
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

contract RewardsBunny is Context, IBEP20, Ownable, ReentrancyGuard {
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool)    private _isExcludedFromFee;
    mapping (address => bool)    private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public _nextAvailableClaimDate;
    mapping (address => bool)    public _isExcludedFromClaim;

    address[] private _excluded;
    address public _marketingWallet;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string public constant name     = "RewardsBunny";
    string public constant symbol   = "RBunny";
    uint8  public constant decimals = 18;
    
    // transfer fee
    uint256 public _taxFeeTransfer       = 0;   
    uint256 public _liquidityFeeTransfer = 200; 
    uint256 public _percentageOfLiquidityForBnbReward = 40;
    uint256 public _percentageOfLiquidityForMarketing = 40;
    
    // reinvest fee
    uint256 public _taxFeeReinvest       = 0; 
    uint256 public _liquidityFeeReinvest = 200;
    
    // buy fee
    uint256 public _taxFeeBuy       = 0; 
    uint256 public _liquidityFeeBuy = 1600;

    // sell fee
    uint256 public _taxFeeSell       = 0; 
    uint256 public _liquidityFeeSell = 3000;

    uint256 public _maxTxAmount      = _tTotal / 2;
    uint256 public _minTokenBalance  = _tTotal / 2000;
    uint256 public _balanceThreshold = _tTotal / 3500;
    
    // Function EVENTS
    event excludeFromRewardTX(address TheFollowingAddressIsExcludedFromRewards);
    event includeInRewardTX(address TheFollowingAddressIsIncludedInRewards);
    
    // auto liquidity
    bool public  _swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;
    IUniswapV2Router02 public _uniswapV2Router;
    address            public _uniswapV2Pair;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 tokensForLiquidity,
        uint256 bnbForLiquidity,
        uint256 bnbForRewardPool,
        uint256 bnbForMarketing
    );

    // bnb reward
    bool public _isBnbRewardEnabled = true;
    uint256 public _rewardCycle = 1 days;
    event bnbRewardClaimed(
        address recipient,
        uint256 bnbReceived,
        uint256 nextAvailableClaimDate
    );
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    constructor (address cOwner, address marketingWallet) Ownable(cOwner) {
        _marketingWallet = marketingWallet;

        _rOwned[cOwner] = _rTotal;
        
        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // exclude system addresses from fee
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;

        // exclude addresses from rewards
        _isExcluded[_uniswapV2Pair]            = true;
        _isExcluded[address(_uniswapV2Router)] = true;
        _excluded.push(_uniswapV2Pair);
        _excluded.push(address(_uniswapV2Router));

        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    // BEP20
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    // REFLECTION
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

            return rAmount;

        } else {
            (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit excludeFromRewardTX(account);
    }
    function includeInReward(address account) external onlyOwner {
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
        
        emit includeInRewardTX(account);
    }

    // STATE
    function setMarketingWallet(address marketingWallet) external onlyOwner {
        _marketingWallet = marketingWallet;
    }
    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }
    function setTransferFee(uint256 taxFee, uint256 liquidityFee) external onlyOwner {
        _taxFeeTransfer       = taxFee;
        _liquidityFeeTransfer = liquidityFee;
    }
    function setBuyFee(uint256 taxFee, uint256 liquidityFee) external onlyOwner {
        _taxFeeBuy       = taxFee;
        _liquidityFeeBuy = liquidityFee;
    }
    function setSellFee(uint256 taxFee, uint256 liquidityFee) external onlyOwner {
        _taxFeeSell       = taxFee;
        _liquidityFeeSell = liquidityFee;
    }
    function setReinvestFee(uint256 taxFeeReinvest, uint256 liquidityFeeReinvest) external onlyOwner {
        _taxFeeReinvest       = taxFeeReinvest;
        _liquidityFeeReinvest = liquidityFeeReinvest;
    }
    function setPercentageOfLiquidityForBnbReward(uint256 percentageOfLiquidityForBnbReward) external onlyOwner {
        _percentageOfLiquidityForBnbReward = percentageOfLiquidityForBnbReward;
    }
    function setPercentageOfLiquidityForMarketing(uint256 percentageOfLiquidityForMarketing) external onlyOwner {
        _percentageOfLiquidityForMarketing = percentageOfLiquidityForMarketing;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal * maxTxPercent / 100;
    }
    function setMinTokenBalance(uint256 minTokenBalance) external onlyOwner {
        _minTokenBalance = minTokenBalance;
    }
    function setBalanceThreshold(uint256 b) external onlyOwner {
        _balanceThreshold = b;
    }
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function collectBnb(address account, uint256 amount) external onlyOwner {
        (bool sent,) = account.call{value : amount}("");
        require(sent, "Unexpected error occured");
    }
    function setExcludedFromClaim(address account, bool b) external onlyOwner {
        _isExcludedFromClaim[account] = b;
    }
    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
        IBEP20(tokenAddress).transfer(owner(), amount);
    }
    function setBnbRewardEnabled(bool e) external onlyOwner {
        _isBnbRewardEnabled = e;
    }
    function setRewardCycle(uint256 r) external onlyOwner {
        _rewardCycle = r;
    }

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        bool isOverMinTokenBalance = contractTokenBalance >= _minTokenBalance;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            from != _uniswapV2Pair &&
            _swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _minTokenBalance;
            swapAndLiquify(contractTokenBalance);
        }
        // R e w a r d s B u n n y 
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        bool shouldAddLiquidity = (_percentageOfLiquidityForBnbReward + _percentageOfLiquidityForMarketing) < 100;

        // swap tokens for BNB
        uint256 tokensSwapped = contractTokenBalance;
        if (shouldAddLiquidity) {
            tokensSwapped = half;
        }
        swapTokensForBnb(tokensSwapped);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance - initialBalance;
        uint256 bnbForRewardPool = newBalance * _percentageOfLiquidityForBnbReward / 100;
        uint256 bnbForMarketing  = newBalance * _percentageOfLiquidityForMarketing / 100;
        uint256 bnbForLiquidity  = newBalance - bnbForRewardPool - bnbForMarketing;

        // send BNB to marketing
        if (bnbForMarketing > 0) {
            payable(_marketingWallet).transfer(bnbForMarketing);
        }

        // add liquidity to uniswap
        uint256 tokensForLiquidity;
        if (bnbForLiquidity > 0 && shouldAddLiquidity) {
            tokensForLiquidity = otherHalf;
            addLiquidity(tokensForLiquidity, bnbForLiquidity);
        }
        
        emit SwapAndLiquify(
            tokensSwapped, 
            tokensForLiquidity,
            bnbForLiquidity, 
            bnbForRewardPool,
            bnbForMarketing
        );
    }
    function swapBnbForTokens(uint256 amount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _msgSender(),
            block.timestamp + 300
        );
    }
    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // BNB REWARD
    function reinvestBnbReward() isHuman nonReentrant public {
        require(_isBnbRewardEnabled, "Reward feature is currently paused");
        require(_nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: claim not available yet');
        require(!_isExcludedFromClaim[msg.sender], "Address is excluded from claim");
        require(balanceOf(msg.sender) > 0, 'Error: token balance insufficient');

        uint256 bnbReward = calculateBnbReward(msg.sender);

        // update reward cycle
        _nextAvailableClaimDate[msg.sender] = block.timestamp + _rewardCycle;
        emit bnbRewardClaimed(msg.sender, bnbReward, _nextAvailableClaimDate[msg.sender]);

        uint256 previousTaxFee       = _taxFeeTransfer;
        uint256 previousLiquidityTransferFee = _liquidityFeeTransfer;
        uint256 previousLiquidityBuyFee = _liquidityFeeBuy;
        uint256 previousBuyTaxFee = _taxFeeBuy;

        _taxFeeTransfer       = 0;
        _taxFeeBuy            = _taxFeeReinvest;
        _liquidityFeeTransfer = 0;
        _liquidityFeeBuy      = _liquidityFeeReinvest;
        swapBnbForTokens(bnbReward);

        _taxFeeTransfer       = previousTaxFee;
        _liquidityFeeTransfer = previousLiquidityTransferFee;
        _liquidityFeeBuy      = previousLiquidityBuyFee;
        _taxFeeBuy            = previousBuyTaxFee;
    }
    function claimBnbReward() isHuman nonReentrant public {
        require(_isBnbRewardEnabled, "Reward feature is currently paused");
        require(_nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: claim not available yet');
        require(!_isExcludedFromClaim[msg.sender], "Address is excluded from claim");
        require(balanceOf(msg.sender) > 0, 'Error: token balance insufficient');

        uint256 bnbReward = calculateBnbReward(msg.sender);

        // update reward cycle
        _nextAvailableClaimDate[msg.sender] = block.timestamp + _rewardCycle;
        emit bnbRewardClaimed(msg.sender, bnbReward, _nextAvailableClaimDate[msg.sender]);

        (bool sent,) = address(msg.sender).call{value : bnbReward}("");
        require(sent, 'Error: Unexpected error encountered while sending bnb reward');
    }
    function calculateBnbReward(address recipient) public view returns (uint256) {
        uint256 circulatingSupply = _tTotal - balanceOf(address(0)) - balanceOf(0x000000000000000000000000000000000000dEaD) - balanceOf(_uniswapV2Pair);

        uint256 bnbRewardPool = address(this).balance;
        uint256 bnbReward = bnbRewardPool * balanceOf(recipient) / circulatingSupply;

        return bnbReward;
    }
    function updateClaimCycle(address recipient, uint256 amount) private {
        uint256 recipientBalance = balanceOf(recipient);
        uint256 addedCycle = 0;

        if (recipientBalance <= _balanceThreshold) {
            addedCycle = block.timestamp + _rewardCycle;

        } else {
            uint256 rate = amount * 100 / recipientBalance;
            uint256 minRate = 2; // 2 percent

            if (rate >= minRate) {
                addedCycle = _rewardCycle * rate / 100;
                if (addedCycle >= _rewardCycle) {
                    addedCycle = _rewardCycle;
                }
            }
        }

        // update next available claim date
        _nextAvailableClaimDate[recipient] = _nextAvailableClaimDate[recipient] + addedCycle;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 previousTaxFee       = _taxFeeTransfer;
        uint256 previousLiquidityFee = _liquidityFeeTransfer;

        bool isBuy  = sender == _uniswapV2Pair && recipient != address(_uniswapV2Router);
        bool isSell = recipient == _uniswapV2Pair;
        
        if (!takeFee) {
            _taxFeeTransfer       = 0;
            _liquidityFeeTransfer = 0;

        } else if (isBuy) { 
            _taxFeeTransfer       = _taxFeeBuy;
            _liquidityFeeTransfer = _liquidityFeeBuy;

        } else if (isSell) { 
            _taxFeeTransfer       = _taxFeeSell;
            _liquidityFeeTransfer = _liquidityFeeSell;
        }

        // update claim cycle
        updateClaimCycle(recipient, amount);
        
        _transferStandard(sender, recipient, amount);
        // R e w a r d s B u n n y 
        if (!takeFee || isBuy || isSell) {
            _taxFeeTransfer       = previousTaxFee;
            _liquidityFeeTransfer = previousLiquidityFee;
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _rOwned[sender] = _rOwned[sender] - rAmount;
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        }

        takeTransactionFee(address(this), tLiquidity, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee       = tAmount * _taxFeeTransfer / 10000;
        uint256 tLiquidity = tAmount * _liquidityFeeTransfer / 10000;
        uint256 tTransferAmount = tAmount - tFee;
        tTransferAmount = tTransferAmount - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount     = tAmount * currentRate;
        uint256 rFee        = tFee * currentRate;
        uint256 rLiquidity  = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        rTransferAmount = rTransferAmount - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] = _rOwned[to] + rAmount;
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + tAmount;
        }
    }
}